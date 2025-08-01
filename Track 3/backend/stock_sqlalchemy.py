from pulp import *
import pandas as pd
from sqlalchemy import create_engine, text
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import logging

app = FastAPI()

# Configurer la journalisation
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Connexion à PostgreSQL
engine = create_engine('postgresql+psycopg2://aaron:Datathon25@YOUR_PUBLIC_IP:5432/clinical_db')

# Récupérer les données
try:
    stocks_query = "SELECT blood_type, SUM(collection_volume_ml) / 450 AS poches FROM stocks WHERE expiry_date > CURRENT_DATE GROUP BY blood_type"
    stocks_df = pd.read_sql(stocks_query, engine)
    stocks_df['poches'] = stocks_df['poches'].apply(int)
    forecast_query = "SELECT blood_type, AVG(avg_forecast) AS avg_forecast FROM forecasts GROUP BY blood_type"
    forecast_df = pd.read_sql(forecast_query, engine)
    forecast_df['avg_forecast'] = forecast_df['avg_forecast'].apply(int)
    expiry_query = "SELECT blood_type, SUM(collection_volume_ml) / 450 AS poches FROM stocks WHERE expiry_date <= CURRENT_DATE + INTERVAL '14 days' GROUP BY blood_type"
    expiry_df = pd.read_sql(expiry_query, engine)
    expiry_df['poches'] = expiry_df['poches'].apply(int)
    logger.info("Données récupérées pour l'optimisation")
except Exception as e:
    logger.error(f"Erreur lors de la récupération des données : {e}")
    exit(1)

# Paramètres
blood_types = ['A+', 'O+', 'B+', 'A-', 'O-', 'B-', 'AB+', 'AB-']
current_stock = {bt: stocks_df[stocks_df['blood_type'] == bt]['poches'].iloc[0] if bt in stocks_df['blood_type'].values else 0 for bt in blood_types}
forecast_demand = {bt: forecast_df[forecast_df['blood_type'] == bt]['avg_forecast'].iloc[0] if bt in forecast_df['blood_type'].values else 10 for bt in blood_types}
wastage = {bt: expiry_df[expiry_df['blood_type'] == bt]['poches'].iloc[0] * 0.05 if bt in expiry_df['blood_type'].values else 0 for bt in blood_types}
safety_stock = {bt: 10 for bt in blood_types}
normal_cost = 100
emergency_cost = 200
storage_capacity = 200

# Modèle PuLP
prob = LpProblem("Blood_Stock_Optimization", LpMinimize)
Q = {bt: LpVariable(f"Order_{bt}", lowBound=0, cat='Integer') for bt in blood_types}
E = {bt: LpVariable(f"Emergency_{bt}", lowBound=0, cat='Integer') for bt in blood_types}

# Objectif
prob += lpSum([normal_cost * Q[bt] + emergency_cost * E[bt] for bt in blood_types])

# Contraintes
for bt in blood_types:
    prob += current_stock[bt] + Q[bt] + E[bt] >= forecast_demand[bt] + safety_stock[bt]
    prob += Q[bt] <= forecast_demand[bt] - wastage.get(bt, 0)
prob += lpSum([current_stock[bt] + Q[bt] for bt in blood_types]) <= storage_capacity

@app.get("/recommendations")
async def get_recommendations():
    try:
        logger.info("Exécution de l'optimisation des stocks")
        prob.solve()
        recommendations = {bt: int(Q[bt].varValue) if Q[bt].varValue is not None else 0 for bt in blood_types}
        emergency = {bt: int(E[bt].varValue) if E[bt].varValue is not None else 0 for bt in blood_types}
        total_cost = sum(normal_cost * Q[bt].varValue + emergency_cost * E[bt].varValue for bt in blood_types if Q[bt].varValue is not None and E[bt].varValue is not None)
        logger.info("Optimisation terminée avec succès")
        return JSONResponse(content={
            "recommendations": recommendations,
            "emergency_orders": emergency,
            "total_cost": total_cost
        })
    except Exception as e:
        logger.error(f"Erreur lors de l'optimisation : {e}")
        return JSONResponse(content={"error": str(e)}, status_code=500)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)