import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
import numpy as np
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from bertopic import BERTopic
from sklearn.feature_extraction.text import CountVectorizer
from tqdm import tqdm  # Pour afficher une barre de progression

# Vérifier la disponibilité du GPU
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# PostgreSQL connection
def get_db_connection():
    return psycopg2.connect(
        dbname="feedback_db",
        user="postgres",
        password="Pinnocio@2025",
        host="localhost",
        port="5432"
    )

# Create analysis table
try:
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS feedback_analysis (
                feedback_id VARCHAR(50),
                sentiment VARCHAR(20),
                theme TEXT,
                urgent BOOLEAN,
                PRIMARY KEY (feedback_id)
            )
        """)
        conn.commit()
        print("Connexion réussie")
except Exception as e:
    print("Erreur lors de la connexion :", e)
    exit(1)

# Load dataset
try:
    df = pd.read_csv(r'C:\Users\pc\Documents\UCAC-ICAM\X4\Hackaton\Datasets\dataset\patient_feedback.csv')
    print("Dataset chargé")
except Exception as e:
    print("Erreur lors du chargement du CSV :", e)
    exit(1)

# Clean data
try:
    df['feedback_text'] = df['feedback_text'].fillna('No comment')
    df['rating'] = df['rating'].fillna(3).clip(lower=1, upper=5)
    df['department'] = df['department'].fillna('Unknown')
    df['feedback_id'] = np.where(df['feedback_id'].isna(), 'UNKNOWN_' + df.index.astype(str), df['feedback_id'])
    print("Clean data ok")
except Exception as e:
    print("Erreur lors du nettoyage des données :", e)
    exit(1)

# Sentiment analysis with PyTorch and GPU
try:
    # Charger le tokenizer et le modèle
    model_name = "nlptown/bert-base-multilingual-uncased-sentiment"
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_name)
    model.to(device)  # Déplacer le modèle vers le GPU
    model.eval()  # Mode évaluation (pas d'entraînement)

    def get_sentiment(texts, batch_size=8):
        sentiments = []
        # Traiter les textes par lots
        for i in tqdm(range(0, len(texts), batch_size), desc="Analyse des sentiments"):
            batch_texts = texts[i:i + batch_size]
            # Tokenisation
            inputs = tokenizer(batch_texts, padding=True, truncation=True, max_length=512, return_tensors="pt")
            inputs = {key: val.to(device) for key, val in inputs.items()}  # Déplacer les tenseurs vers le GPU
            # Inférence
            with torch.no_grad():
                outputs = model(**inputs)
            # Extraire les scores
            scores = outputs.logits.argmax(dim=-1).cpu().numpy()  # 0 à 4 (correspond à 1 à 5 étoiles)
            # Convertir en sentiments
            sentiments.extend(['Positive' if score >= 3 else 'Negative' if score <= 1 else 'Neutral' for score in scores])
        return sentiments

    df['sentiment'] = get_sentiment(df['feedback_text'].tolist())
    print("Analyse des sentiments terminée")
except Exception as e:
    print("Erreur lors de l'analyse des sentiments :", e)
    exit(1)

# Theme extraction
try:
    vectorizer = CountVectorizer(stop_words='english')
    topic_model = BERTopic(vectorizer_model=vectorizer, language="english")
    topics, _ = topic_model.fit_transform(df['feedback_text'])
    df['theme'] = topic_model.get_document_info(df['feedback_text'])['Topic'].map(
        lambda x: topic_model.get_topic(x)[0][0] if x >= 0 else 'No theme'
    )
    print("Extraction des thèmes terminée")
except Exception as e:
    print("Erreur lors de l'extraction des thèmes :", e)
    exit(1)

# Urgent issue detection
try:
    urgent_keywords = ['long wait', 'scheduling issues', 'billing confusion', 'slow lab']
    df['urgent'] = df['feedback_text'].str.lower().apply(
        lambda x: True if any(keyword in x for keyword in urgent_keywords) else False
    )
    print("Détection des urgences terminée")
except Exception as e:
    print("Erreur lors de la détection des urgences :", e)
    exit(1)

# Save to PostgreSQL
try:
    with get_db_connection() as conn:
        cursor = conn.cursor()
        for _, row in df.iterrows():
            cursor.execute(
                """
                INSERT INTO feedback_analysis (feedback_id, sentiment, theme, urgent)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (feedback_id) DO UPDATE
                SET sentiment = EXCLUDED.sentiment,
                    theme = EXCLUDED.theme,
                    urgent = EXCLUDED.urgent
                """,
                (row['feedback_id'], row['sentiment'], row['theme'], row['urgent'])
            )
        conn.commit()
        print("Données enregistrées avec succès")
except Exception as e:
    print("Erreur lors de l'enregistrement :", e)
    exit(1)

# Print summary
try:
    print("Sentiment Distribution:")
    print(df['sentiment'].value_counts())
    print("\nTheme Distribution:")
    print(df['theme'].value_counts())
    print("\nUrgent Issues:")
    print(df[df['urgent']][['feedback_id', 'feedback_text']])
except Exception as e:
    print("Erreur lors de l'affichage du résumé :", e)