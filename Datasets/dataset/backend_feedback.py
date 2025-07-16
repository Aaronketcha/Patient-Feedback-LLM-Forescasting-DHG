# -*- coding: utf-8 -*-
from fastapi import FastAPI
from pydantic import BaseModel
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI()

def get_db_connection():
    return psycopg2.connect(
        dbname="feedback_db",
        user="postgres",
        password="Pinnocio@2025",
        host="localhost",
        port="5432"
    )

try:
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS feedback (
                id SERIAL PRIMARY KEY,
                feedback_text TEXT NOT NULL,
                rating INTEGER CHECK (rating >= 1 AND rating <= 5),
                language VARCHAR(10),
                submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        print("Connexion réussie")
except Exception as e:
    print("Erreur lors de la connexion :", e)

class Feedback(BaseModel):
    feedback_text: str
    rating: int
    language: str

@app.post("/feedback")
async def save_feedback(feedback: Feedback):
    with get_db_connection() as conn:
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(
            "INSERT INTO feedback (feedback_text, rating, language) VALUES (%s, %s, %s) RETURNING id",
            (feedback.feedback_text, feedback.rating, feedback.language)
        )
        feedback_id = cursor.fetchone()['id']
        conn.commit()
    return {"message": "Feedback received", "feedback_id": feedback_id}