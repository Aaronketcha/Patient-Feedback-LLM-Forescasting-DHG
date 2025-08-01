from fastapi import FastAPI
from fastapi.responses import JSONResponse
import pandas as pd
from sqlalchemy import create_engine, text
from pmdarima import auto_arima
from statsmodels.tsa.seasonal import STL
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error
from sklearn.model_selection import train_test_split, GridSearchCV, TimeSeriesSplit
from xgboost import XGBRegressor
from sklearn.preprocessing import RobustScaler
from sklearn.impute import KNNImputer
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, LSTM
from tensorflow.keras.callbacks import EarlyStopping
from tensorflow.keras.losses import Huber
import numpy as np
import logging

# Configurer la journalisation
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Vérifier la disponibilité du GPU
gpus = tf.config.list_physical_devices('GPU')
if gpus:
    logger.info(f"GPU détecté : {gpus}")
    try:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        logger.info("Mémoire GPU configurée pour une croissance dynamique")
    except RuntimeError as e:
        logger.error(f"Erreur lors de la configuration du GPU : {e}")
else:
    logger.warning("Aucun GPU détecté, utilisation du CPU")

app = FastAPI()

# Connexion à PostgreSQL via SQLAlchemy
engine = create_engine('postgresql+psycopg2://aaron:Datathon25@34.67.192.222:5432/clinical_db')

# Créer les tables stocks et forecasts
create_tables_sql = """
CREATE TABLE IF NOT EXISTS stocks (
    record_id VARCHAR(50),
    donor_id VARCHAR(50),
    donor_age INT,
    donor_gender VARCHAR(10),
    blood_type VARCHAR(10),
    collection_site VARCHAR(50),
    donation_date DATE,
    expiry_date DATE,
    collection_volume_ml FLOAT,
    hemoglobin_g_dl FLOAT
);

CREATE TABLE IF NOT EXISTS forecasts (
    blood_type VARCHAR(10) NOT NULL,
    forecast_date DATE NOT NULL,
    arima INTEGER,
    random_forest INTEGER,
    xgboost INTEGER,
    neural_network INTEGER,
    avg_forecast INTEGER,
    PRIMARY KEY (blood_type, forecast_date)
);
"""

# Vérifier la connexion et créer les tables
try:
    with engine.connect() as conn:
        with conn.begin():
            conn.execute(text(create_tables_sql))
        logger.info("Tables stocks et forecasts créées ou déjà existantes")
except Exception as e:
    logger.error(f"Erreur lors de la création des tables : {e}")
    exit(1)

# Définir les jours fériés au Cameroun pour 2025
public_holidays = [
    '2025-01-01',  # Jour de l'An
    '2025-02-11',  # Fête de la Jeunesse
    '2025-03-31',  # Aïd el-Fitr (prévisionnel)
    '2025-04-18',  # Vendredi Saint
    '2025-05-01',  # Fête du Travail
    '2025-05-20',  # Fête Nationale
    '2025-05-29',  # Ascension
    '2025-06-06',  # Aïd al-Adha (prévisionnel)
    '2025-08-15',  # Assomption
    '2025-12-25',  # Noël
]

# Charger et prétraiter les données
try:
    df = pd.read_csv('blood_bank_records.csv')
    # Filtrer les outliers extrêmes (> 3 écarts-types)
    mean_vol = df['collection_volume_ml'].mean()
    std_vol = df['collection_volume_ml'].std()
    df = df[df['collection_volume_ml'].between(mean_vol - 3 * std_vol, mean_vol + 3 * std_vol)]
    df = df[df['collection_volume_ml'].between(100, 500)]
    # Imputation KNN pour donor_age
    imputer = KNNImputer(n_neighbors=5)
    df['donor_age'] = imputer.fit_transform(df[['donor_age']])
    df['donation_date'] = pd.to_datetime(df['donation_date'], errors='coerce')
    df['expiry_date'] = pd.to_datetime(df['expiry_date'], errors='coerce')
    df = df.dropna(subset=['blood_type'])
    df['donor_id'] = df['donor_id'].fillna('unknown_' + df.index.astype(str))
    df['donation_count'] = df.groupby('donor_id')['record_id'].transform('count')
    df.to_sql('stocks', engine, if_exists='replace', index=False)
    logger.info("Données de blood_bank_records.csv chargées dans la table stocks")
    logger.info(f"Types de sang disponibles : {df['blood_type'].unique()}")
    logger.info(f"Jours de données par type de sang : \n{df.groupby('blood_type')['donation_date'].nunique()}")
except FileNotFoundError:
    logger.error("Erreur : blood_bank_records.csv introuvable")
    exit(1)
except Exception as e:
    logger.error(f"Erreur lors du chargement des données : {e}")
    exit(1)

# Ajout de features : jours fériés, vacances nationales, congés de Noël, lags, moyennes mobiles
df_features = df.groupby(['donation_date', 'blood_type']).agg({
    'collection_volume_ml': 'sum',
    'donor_age': 'mean',
    'donation_count': 'mean',
}).reset_index()
df_features['day_of_week'] = df_features['donation_date'].dt.dayofweek
df_features['is_holiday'] = df_features['donation_date'].dt.dayofweek.isin([5, 6]).astype(int)
df_features['month'] = df_features['donation_date'].dt.month
df_features['quarter'] = df_features['donation_date'].dt.quarter
df_features['is_public_holiday'] = df_features['donation_date'].dt.strftime('%Y-%m-%d').isin(public_holidays).astype(int)
df_features['is_national_holiday'] = ((df_features['donation_date'].dt.month >= 6) | 
                                     ((df_features['donation_date'].dt.month == 5) & (df_features['donation_date'].dt.day > 20))).astype(int)
df_features['is_christmas_break'] = (((df_features['donation_date'].dt.month == 12) & (df_features['donation_date'].dt.day >= 20)) | 
                                     ((df_features['donation_date'].dt.month == 1) & (df_features['donation_date'].dt.day <= 6))).astype(int)
df_features['rolling_mean_7'] = df_features.groupby('blood_type')['collection_volume_ml'].transform(lambda x: x.rolling(window=7, min_periods=1).mean())
df_features['rolling_mean_14'] = df_features.groupby('blood_type')['collection_volume_ml'].transform(lambda x: x.rolling(window=14, min_periods=1).mean())
for lag in range(1, 8):
    df_features[f'lag_{lag}'] = df_features.groupby('blood_type')['collection_volume_ml'].shift(lag)
df_features['target'] = df_features.groupby('blood_type')['collection_volume_ml'].shift(-1)
df_features.dropna(inplace=True)
X = df_features[['collection_volume_ml', 'donor_age', 'donation_count', 'day_of_week', 'is_holiday', 'month', 'quarter', 
                 'is_public_holiday', 'is_national_holiday', 'is_christmas_break', 'rolling_mean_7', 'rolling_mean_14'] + 
                 [f'lag_{lag}' for lag in range(1, 8)]]
y = df_features['target']

# Vérifier l'échelle des données et les NaN
logger.info(f"Statistiques de collection_volume_ml : \n{y.describe()}")
if X.isnull().any().any() or y.isnull().any():
    logger.error("NaN détectés dans X ou y après préparation des données")
    exit(1)

# Normalisation robuste
scaler_X = RobustScaler()
scaler_y = RobustScaler()
X_train, X_temp, y_train, y_temp = train_test_split(X, y, test_size=0.3, random_state=42)
X_val, X_test, y_val, y_test = train_test_split(X_temp, y_temp, test_size=0.5, random_state=42)
X_train_scaled = scaler_X.fit_transform(X_train)
X_val_scaled = scaler_X.transform(X_val)
X_test_scaled = scaler_X.transform(X_test)
y_train_scaled = scaler_y.fit_transform(y_train.values.reshape(-1, 1))
y_val_scaled = scaler_y.transform(y_val.values.reshape(-1, 1))
y_test_scaled = scaler_y.transform(y_test.values.reshape(-1, 1))

# Importance des features avec Random Forest
model_rf_temp = RandomForestRegressor(random_state=42)
model_rf_temp.fit(X_train, y_train)
feature_importance = pd.Series(model_rf_temp.feature_importances_, index=X.columns).sort_values(ascending=False)
logger.info(f"Importance des features : \n{feature_importance}")

# Entraîner Random Forest avec recherche par grille
param_grid_rf = {
    'n_estimators': [100, 200, 300, 500, 1000],
    'max_depth': [5, 10, 15, 20, None],
    'min_samples_split': [2, 5, 10, 20, 50],
    'min_samples_leaf': [1, 2, 4, 8, 16]
}
model_rf = RandomForestRegressor(random_state=42)
tscv = TimeSeriesSplit(n_splits=10)
grid_search_rf = GridSearchCV(model_rf, param_grid_rf, cv=tscv, scoring='neg_mean_squared_error', n_jobs=-1)
grid_search_rf.fit(X_train, y_train)
model_rf = grid_search_rf.best_estimator_
rf_pred = model_rf.predict(X_test)
rf_rmse = np.sqrt(mean_squared_error(y_test, rf_pred))
rf_mae = mean_absolute_error(y_test, rf_pred)
rf_rmse_pouches = rf_rmse / 450
rf_mae_pouches = rf_mae / 450
rf_norm_rmse = rf_rmse / y_test.mean() if y_test.mean() != 0 else float('inf')
rf_norm_mae = rf_mae / y_test.mean() if y_test.mean() != 0 else float('inf')
logger.info(f"Random Forest - Best params: {grid_search_rf.best_params_}")
logger.info(f"Random Forest - RMSE: {rf_rmse:.2f} ml ({rf_rmse_pouches:.2f} poches), MAE: {rf_mae:.2f} ml ({rf_mae_pouches:.2f} poches), RMSE normalisé: {rf_norm_rmse:.2f}, MAE normalisé: {rf_norm_mae:.2f}")

# Entraîner XGBoost avec recherche par grille et poids
param_grid_xgb = {
    'n_estimators': [100, 200, 300, 500, 1000],
    'max_depth': [3, 6, 10, 15, 20],
    'learning_rate': [0.01, 0.05, 0.1, 0.2, 0.3],
    'reg_alpha': [0, 0.1, 1, 10, 100],
    'reg_lambda': [0, 0.1, 1, 10, 100]
}
model_xgb = XGBRegressor(random_state=42)
grid_search_xgb = GridSearchCV(model_xgb, param_grid_xgb, cv=tscv, scoring='neg_mean_squared_error', n_jobs=-1)
weights = np.linspace(0.5, 1.5, len(X_train))
grid_search_xgb.fit(X_train, y_train, sample_weight=weights)
model_xgb = grid_search_xgb.best_estimator_
xgb_pred = model_xgb.predict(X_test)
xgb_rmse = np.sqrt(mean_squared_error(y_test, xgb_pred))
xgb_mae = mean_absolute_error(y_test, xgb_pred)
xgb_rmse_pouches = xgb_rmse / 450
xgb_mae_pouches = xgb_mae / 450
xgb_norm_rmse = xgb_rmse / y_test.mean() if y_test.mean() != 0 else float('inf')
xgb_norm_mae = xgb_mae / y_test.mean() if y_test.mean() != 0 else float('inf')
logger.info(f"XGBoost - Best params: {grid_search_xgb.best_params_}")
logger.info(f"XGBoost - RMSE: {xgb_rmse:.2f} ml ({xgb_rmse_pouches:.2f} poches), MAE: {xgb_mae:.2f} ml ({xgb_mae_pouches:.2f} poches), RMSE normalisé: {xgb_norm_rmse:.2f}, MAE normalisé: {xgb_norm_mae:.2f}")

# Entraîner LSTM avec GPU
with tf.device('/GPU:0'):
    X_train_lstm = X_train_scaled.reshape((X_train_scaled.shape[0], X_train_scaled.shape[1], 1))
    X_val_lstm = X_val_scaled.reshape((X_val_scaled.shape[0], X_val_scaled.shape[1], 1))
    X_test_lstm = X_test_scaled.reshape((X_test_scaled.shape[0], X_test_scaled.shape[1], 1))
    model_nn = Sequential([
        LSTM(128, activation='relu', input_shape=(X_train_lstm.shape[1], 1), return_sequences=True),
        Dropout(0.3),
        LSTM(64, activation='relu'),
        Dropout(0.3),
        Dense(32, activation='relu'),
        Dense(1)
    ])
    model_nn.compile(optimizer='adam', loss=Huber())
    model_nn.fit(X_train_lstm, y_train_scaled, epochs=200, batch_size=4, validation_data=(X_val_lstm, y_val_scaled), 
                 callbacks=[EarlyStopping(patience=20)], verbose=0)
    nn_pred_scaled = model_nn.predict(X_test_lstm, verbose=0)
nn_pred = scaler_y.inverse_transform(nn_pred_scaled).flatten()
nn_rmse = np.sqrt(mean_squared_error(y_test, nn_pred))
nn_mae = mean_absolute_error(y_test, nn_pred)
nn_rmse_pouches = nn_rmse / 450
nn_mae_pouches = nn_mae / 450
nn_norm_rmse = nn_rmse / y_test.mean() if y_test.mean() != 0 else float('inf')
nn_norm_mae = nn_mae / y_test.mean() if y_test.mean() != 0 else float('inf')
logger.info(f"LSTM - RMSE: {nn_rmse:.2f} ml ({nn_rmse_pouches:.2f} poches), MAE: {nn_mae:.2f} ml ({nn_mae_pouches:.2f} poches), RMSE normalisé: {nn_norm_rmse:.2f}, MAE normalisé: {nn_norm_mae:.2f}")

# Évaluation ARIMA/STL avec transformation logarithmique
arima_metrics = {}
for blood_type in df['blood_type'].unique():
    try:
        df_type = df[df['blood_type'] == blood_type][['donation_date', 'collection_volume_ml']]
        df_type = df_type.groupby('donation_date').sum().reset_index()
        df_type.set_index('donation_date', inplace=True)
        df_type = df_type.asfreq('D', fill_value=0)
        df_type['collection_volume_ml'] = df_type['collection_volume_ml'].replace(0, 0.1)
        df_type['log_collection_volume_ml'] = np.log(df_type['collection_volume_ml'])
        df_type['log_collection_volume_ml'] = df_type['log_collection_volume_ml'].rolling(window=7, min_periods=1).mean()
        if len(df_type) < 30:
            logger.warning(f"Données insuffisantes pour évaluer ARIMA pour {blood_type}")
            continue
        train_size = int(len(df_type) * 0.8)
        train, test = df_type[:train_size], df_type[train_size:]
        if len(test) < 1:
            logger.warning(f"Données de test insuffisantes pour {blood_type}")
            continue
        stl = STL(train['log_collection_volume_ml'], period=14)
        result = stl.fit()
        series = result.trend + result.resid
        model_arima = auto_arima(series, seasonal=True, m=14, suppress_warnings=True, max_p=5, max_d=2, max_q=5, stepwise=True)
        model_fit = model_arima.fit(series)
        arima_pred_log = np.maximum(model_fit.predict(n_periods=len(test)) + result.seasonal[-len(test):].mean(), 0)
        arima_pred = np.exp(arima_pred_log)
        arima_rmse = np.sqrt(mean_squared_error(test['collection_volume_ml'], arima_pred))
        arima_mae = mean_absolute_error(test['collection_volume_ml'], arima_pred)
        arima_rmse_pouches = arima_rmse / 450
        arima_mae_pouches = arima_mae / 450
        arima_norm_rmse = arima_rmse / test['collection_volume_ml'].mean() if test['collection_volume_ml'].mean() != 0 else float('inf')
        arima_norm_mae = arima_mae / test['collection_volume_ml'].mean() if test['collection_volume_ml'].mean() != 0 else float('inf')
        arima_metrics[blood_type] = {
            'RMSE': arima_rmse,
            'MAE': arima_mae,
            'RMSE_pouches': arima_rmse_pouches,
            'MAE_pouches': arima_mae_pouches,
            'RMSE_normalisé': arima_norm_rmse,
            'MAE_normalisé': arima_norm_mae
        }
        logger.info(f"ARIMA ({blood_type}) - RMSE: {arima_rmse:.2f} ml ({arima_rmse_pouches:.2f} poches), MAE: {arima_mae:.2f} ml ({arima_mae_pouches:.2f} poches), RMSE normalisé: {arima_norm_rmse:.2f}, MAE normalisé: {arima_norm_mae:.2f}")
    except Exception as e:
        logger.error(f"Erreur dans l'évaluation ARIMA pour {blood_type} : {e}")
        continue

# Calculer les poids pour la moyenne pondérée par type de sang
weights = {}
for blood_type in df['blood_type'].unique():
    arima_rmse_bt = arima_metrics.get(blood_type, {'RMSE': np.inf})['RMSE']
    total_rmse = rf_rmse + xgb_rmse + nn_rmse + arima_rmse_bt
    weights[blood_type] = {
        'rf': 0.0 if rf_rmse > 500 else (1 / rf_rmse) / total_rmse,
        'xgb': 0.0 if xgb_rmse > 500 else (1 / xgb_rmse) / total_rmse,
        'nn': 0.0 if nn_rmse > 500 else (1 / nn_rmse) / total_rmse,
        'arima': (1 / arima_rmse_bt) / total_rmse if arima_rmse_bt != np.inf else 0.0
    }

@app.get("/forecast/{blood_type}")
async def forecast(blood_type: str):
    try:
        logger.info(f"Tentative de prévision pour le type de sang {blood_type}")
        if blood_type not in df['blood_type'].unique():
            logger.warning(f"Type de sang {blood_type} non trouvé dans les données")
            return JSONResponse(content={"error": f"Type de sang {blood_type} non trouvé"}, status_code=404)

        # Prévisions ARIMA/STL
        df_type = df[df['blood_type'] == blood_type][['donation_date', 'collection_volume_ml']]
        df_type = df_type.groupby('donation_date').sum().reset_index()
        df_type.set_index('donation_date', inplace=True)
        df_type = df_type.asfreq('D', fill_value=0)
        df_type['collection_volume_ml'] = df_type['collection_volume_ml'].replace(0, 0.1)
        df_type['log_collection_volume_ml'] = np.log(df_type['collection_volume_ml'])
        df_type['log_collection_volume_ml'] = df_type['log_collection_volume_ml'].rolling(window=7, min_periods=1).mean()
        if len(df_type) < 30:
            logger.warning(f"Données insuffisantes pour {blood_type} : {len(df_type)} lignes")
            return JSONResponse(content={"error": f"Données insuffisantes pour {blood_type}"}, status_code=400)
        stl = STL(df_type['log_collection_volume_ml'], period=14)
        result = stl.fit()
        series = result.trend + result.resid
        model_arima = auto_arima(series, seasonal=True, m=14, suppress_warnings=True, max_p=5, max_d=2, max_q=5, stepwise=True)
        model_fit = model_arima.fit(series)
        forecast_arima_log = np.maximum(model_fit.predict(n_periods=30) + result.seasonal[-30:].mean(), 0)
        forecast_arima = np.exp(forecast_arima_log)

        # Prévisions ML
        df_ml = df_features[df_features['blood_type'] == blood_type]
        if df_ml.empty:
            logger.warning(f"Aucune donnée ML pour {blood_type}")
            return JSONResponse(content={"error": f"Aucune donnée ML pour {blood_type}"}, status_code=404)
        X_ml = df_ml[['collection_volume_ml', 'donor_age', 'donation_count', 'day_of_week', 'is_holiday', 'month', 'quarter', 
                      'is_public_holiday', 'is_national_holiday', 'is_christmas_break', 'rolling_mean_7', 'rolling_mean_14'] + 
                      [f'lag_{lag}' for lag in range(1, 8)]].tail(30)
        X_ml_scaled = scaler_X.transform(X_ml)
        X_ml_lstm = X_ml_scaled.reshape((X_ml_scaled.shape[0], X_ml_scaled.shape[1], 1))
        forecast_rf = model_rf.predict(X_ml)
        forecast_xgb = model_xgb.predict(X_ml)
        with tf.device('/GPU:0'):
            forecast_nn = model_nn.predict(X_ml_lstm, verbose=0)
        forecast_nn = scaler_y.inverse_transform(forecast_nn).flatten()

        # Moyenne pondérée par type de sang
        arima_weight = weights.get(blood_type, {'arima': 0.25})['arima']
        rf_weight = weights.get(blood_type, {'rf': 0.25})['rf']
        xgb_weight = weights.get(blood_type, {'xgb': 0.25})['xgb']
        nn_weight = weights.get(blood_type, {'nn': 0.25})['nn']
        forecasts = pd.DataFrame({
            'blood_type': [blood_type] * 30,
            'forecast_date': pd.date_range(start='2025-08-01', periods=30),
            'arima': [int(x / 450) for x in forecast_arima],
            'random_forest': [int(x / 450) for x in forecast_rf],
            'xgboost': [int(x / 450) for x in forecast_xgb],
            'neural_network': [int(x / 450) for x in forecast_nn],
            'avg_forecast': [int((a * arima_weight + b * rf_weight + c * xgb_weight + d * nn_weight) / 450) for a, b, c, d in zip(forecast_arima, forecast_rf, forecast_xgb, forecast_nn)]
        })

        forecasts['forecast_date'] = forecasts['forecast_date'].dt.strftime('%Y-%m-%d')
        forecasts.to_sql('forecasts', engine, if_exists='append', index=False)
        logger.info(f"Prévisions pour {blood_type} enregistrées dans la table forecasts")
        return JSONResponse(content=forecasts.to_dict(orient='records'))
    except Exception as e:
        logger.error(f"Erreur lors de la prévision pour {blood_type} : {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.get("/stocks/{blood_type}")
async def get_stocks(blood_type: str):
    try:
        logger.info(f"Récupération des stocks pour le type de sang {blood_type}")
        query = "SELECT * FROM stocks WHERE blood_type = %s AND expiry_date > CURRENT_DATE"
        stocks_df = pd.read_sql(query, engine, params=(blood_type,))
        if stocks_df.empty:
            logger.warning(f"Aucun stock pour {blood_type}")
            return JSONResponse(content={"error": f"Aucun stock pour {blood_type}"}, status_code=404)
        stocks_df['donation_date'] = stocks_df['donation_date'].astype(str)
        stocks_df['expiry_date'] = stocks_df['expiry_date'].astype(str)
        return JSONResponse(content=stocks_df.to_dict(orient='records'))
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des stocks pour {blood_type} : {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

@app.get("/model_performance")
async def get_model_performance():
    try:
        logger.info("Récupération des performances des modèles")
        performance = {
            "Random Forest": {
                "RMSE_ml": float(rf_rmse),
                "MAE_ml": float(rf_mae),
                "RMSE_pouches": float(rf_rmse_pouches),
                "MAE_pouches": float(rf_mae_pouches),
                "RMSE_normalisé": float(rf_norm_rmse),
                "MAE_normalisé": float(rf_norm_mae)
            },
            "XGBoost": {
                "RMSE_ml": float(xgb_rmse),
                "MAE_ml": float(xgb_mae),
                "RMSE_pouches": float(xgb_rmse_pouches),
                "MAE_pouches": float(xgb_mae_pouches),
                "RMSE_normalisé": float(xgb_norm_rmse),
                "MAE_normalisé": float(xgb_norm_mae)
            },
            "LSTM": {
                "RMSE_ml": float(nn_rmse),
                "MAE_ml": float(nn_mae),
                "RMSE_pouches": float(nn_rmse_pouches),
                "MAE_pouches": float(nn_mae_pouches),
                "RMSE_normalisé": float(nn_norm_rmse),
                "MAE_normalisé": float(nn_norm_mae)
            },
            "ARIMA": {
                bt: {
                    "RMSE_ml": float(metrics['RMSE']),
                    "MAE_ml": float(metrics['MAE']),
                    "RMSE_pouches": float(metrics['RMSE_pouches']),
                    "MAE_pouches": float(metrics['MAE_pouches']),
                    "RMSE_normalisé": float(metrics['RMSE_normalisé']),
                    "MAE_normalisé": float(metrics['MAE_normalisé'])
                } for bt, metrics in arima_metrics.items()
            },
            "Feature_Importance": feature_importance.to_dict()
        }
        return JSONResponse(content=performance)
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des performances : {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)