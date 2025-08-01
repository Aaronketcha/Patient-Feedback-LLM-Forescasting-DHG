import pandas as pd
import numpy as np
from sqlalchemy import create_engine
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
import os
import sys

# Forcer l'encodage UTF-8
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

# Paramètres de connexion PostgreSQL
db_params = {
    'host': os.getenv('DB_HOST', '34.67.192.222'),  # IP publique de votre instance Cloud SQL
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'clinical_db'),
    'user': os.getenv('DB_USER', 'aaron'),
    'password': os.getenv('DB_PASSWORD', 'Datathon25')
}

# Déboguer les paramètres
print(f"Paramètres de connexion : {db_params}")

# Tester la connexion
def test_connection():
    try:
        engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
        with engine.connect() as conn:
            print("Connexion à la base de données réussie")
        return True
    except Exception as e:
        print(f"Erreur de connexion : {str(e)}")
        return False

# Fonction pour nettoyer les données
def clean_data(df):
    df['summary_text'] = df['summary_text'].fillna('')
    df['patient_id'] = df['patient_id'].fillna('Unknown')
    df['patient_age'] = df['patient_age'].apply(lambda x: np.nan if pd.isna(x) or x < 0 or x > 120 else x)
    df['patient_gender'] = df['patient_gender'].fillna('Unknown')
    df['diagnosis'] = df['diagnosis'].fillna('Unknown')
    df['body_temp_c'] = df['body_temp_c'].fillna(np.nan)
    df['blood_pressure_systolic'] = df['blood_pressure_systolic'].fillna(np.nan)
    df['heart_rate'] = df['heart_rate'].fillna(np.nan)
    df['date_recorded'] = df['date_recorded'].fillna('Unknown')
    df['combined_text'] = df.apply(
        lambda row: (
            f"Patient ID: {row['patient_id']}, "
            f"Age: {row['patient_age'] if pd.notna(row['patient_age']) else 'Unknown'}, "
            f"Gender: {row['patient_gender']}, "
            f"Diagnosis: {row['diagnosis']}, "
            f"Temperature: {row['body_temp_c'] if pd.notna(row['body_temp_c']) else 'Unknown'}°C, "
            f"Blood Pressure: {row['blood_pressure_systolic'] if pd.notna(row['blood_pressure_systolic']) else 'Unknown'}, "
            f"Heart Rate: {row['heart_rate'] if pd.notna(row['heart_rate']) else 'Unknown'}, "
            f"Summary: {row['summary_text']}, "
            f"Date: {row['date_recorded']}"
        ),
        axis=1
    )
    return df

# Créer les tables dans PostgreSQL
def create_tables():
    engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
    with engine.connect() as conn:
        conn.execute("""
        CREATE TABLE IF NOT EXISTS clinical_summaries (
            summary_id VARCHAR(50),
            patient_id VARCHAR(50),
            patient_age INTEGER,
            patient_gender VARCHAR(10),
            diagnosis VARCHAR(50),
            body_temp_c FLOAT,
            blood_pressure_systolic FLOAT,
            heart_rate FLOAT,
            summary_text TEXT,
            date_recorded VARCHAR(50),
            combined_text TEXT
        );
        """)
        conn.execute("""
        CREATE TABLE IF NOT EXISTS patient_auth (
            patient_id VARCHAR(50) PRIMARY KEY,
            pin VARCHAR(4)
        );
        """)
        conn.execute("""
        CREATE TABLE IF NOT EXISTS conversation_history (
            id SERIAL PRIMARY KEY,
            patient_id VARCHAR(50),
            user_message TEXT,
            bot_response TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            language VARCHAR(10)
        );
        """)
    print("Tables créées dans PostgreSQL.")

# Charger les données dans PostgreSQL
def load_to_postgres(file_path, table_name='clinical_summaries'):
    try:
        df = pd.read_csv(file_path, encoding='utf-8')
    except UnicodeDecodeError:
        print("Échec de la lecture en UTF-8, tentative avec latin1")
        df = pd.read_csv(file_path, encoding='latin1')
    df = clean_data(df)
    engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
    with engine.connect() as conn:
        conn.execution_options(autocommit=True).execute("SELECT 1")  # Initialiser la connexion
        df.to_sql(table_name, conn, if_exists='replace', index=False)
        print(f"Données chargées dans la table {table_name}.")
        # Créer des PINs simples pour chaque patient
        auth_data = pd.DataFrame({
            'patient_id': df['patient_id'],
            'pin': [str(hash(pid) % 10000).zfill(4) for pid in df['patient_id']]
        })
        auth_data.to_sql('patient_auth', conn, if_exists='replace', index=False)
        print("Tableau patient_auth initialisé avec des PINs.")

# Créer le magasin vectoriel
def create_vector_store():
    engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
    with engine.connect() as conn:
        df = pd.read_sql("SELECT combined_text FROM clinical_summaries", conn)
    embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    batch_size = 100  # Taille du lot pour réduire la charge mémoire
    texts = df['combined_text'].tolist()
    metadatas = df.to_dict('records')
    vectorstore = None
    for i in range(0, len(texts), batch_size):
        batch_texts = texts[i:i + batch_size]
        batch_metadatas = metadatas[i:i + batch_size]
        if vectorstore is None:
            vectorstore = Chroma.from_texts(batch_texts, embeddings, metadatas=batch_metadatas, persist_directory="./chroma_db")
        else:
            vectorstore.add_texts(batch_texts, metadatas=batch_metadatas)
    print("Magasin vectoriel créé et sauvegardé dans ./chroma_db.")

if __name__ == "__main__":
    if test_connection():
        create_tables()
        load_to_postgres(r"C:\Users\pc\Documents\UCAC-ICAM\X4\Hackaton\chatbot backend\clinical_summaries.csv")
        create_vector_store()
    else:
        print("Échec de la connexion à la base de données. Veuillez vérifier les paramètres et la connectivité.")