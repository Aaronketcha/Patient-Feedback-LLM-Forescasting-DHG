from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from sqlalchemy import create_engine
from sqlalchemy.sql import text
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
import os
from mistralai import Mistral
from datetime import datetime
import pytz

app = FastAPI()

# Paramètres PostgreSQL
db_params = {
    'host': os.getenv('DB_HOST', '34.67.192.222'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'clinical_db'),
    'user': os.getenv('DB_USER', 'aaron'),
    'password': os.getenv('DB_PASSWORD', 'Datathon25')
}

# Configurer Mistral AI
mistral_client = Mistral(api_key=os.getenv("MISTRAL_API_KEY", "8mYQrrzksHwU0sQqQPvvtUZUvL2aOChL"))

# Charger le magasin vectoriel Chroma
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectorstore = Chroma(persist_directory="./chroma_db", embedding_function=embeddings)

# Modèle pour la requête de chat (pour l'endpoint POST)
class ChatRequest(BaseModel):
    message: str
    language: str = "fr"

# Vérifier le patient
def verify_patient(patient_id: str, pin: str):
    engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
    with engine.connect() as conn:
        query = text("SELECT pin FROM patient_auth WHERE patient_id = :patient_id")
        result = conn.execute(query, {"patient_id": patient_id}).fetchone()
        return result and result[0] == pin

# Obtenir le contexte du patient
def get_patient_context(patient_id: str):
    engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
    with engine.connect() as conn:
        query = text("SELECT combined_text FROM clinical_summaries WHERE patient_id = :patient_id")
        result = conn.execute(query, {"patient_id": patient_id}).fetchone()
        return result[0] if result else ""

# Endpoint POST original
@app.post("/chat")
async def chat(request: ChatRequest, patient_id: str = Header(...), pin: str = Header(...)):
    if not verify_patient(patient_id, pin):
        raise HTTPException(status_code=401, detail="Authentification échouée")
    
    context = get_patient_context(patient_id)
    docs = vectorstore.similarity_search(request.message, k=3)
    context += "\nDocuments pertinents:\n" + "\n".join([doc.page_content for doc in docs])
    
    # Ajouter la date actuelle au contexte
    current_time = datetime.now(pytz.timezone('Africa/Lagos')).strftime("%d %B %Y, %H:%M WAT")
    system_prompt = f"Vous êtes un assistant médical. Répondez de manière claire et précise en français, en utilisant le contexte suivant :\n{context}\nLa date et l'heure actuelles sont : {current_time}."
    
    response = mistral_client.chat.complete(
        model="mistral-small-3.2",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": request.message}
        ]
    )
    
    answer = response.choices[0].message.content
    
    # Enregistrer dans l'historique des conversations
    engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
    with engine.connect() as conn:
        conn.execute(
            text("INSERT INTO conversation_history (patient_id, user_message, bot_response, language) VALUES (:patient_id, :user_message, :bot_response, :language)"),
            {"patient_id": patient_id, "user_message": request.message, "bot_response": answer, "language": request.language}
        )
    
    return {"response": answer}

# Endpoint GET pour tester dans un navigateur
@app.get("/chat-test")
async def chat_test(patient_id: str, pin: str, message: str, language: str = "fr"):
    if not verify_patient(patient_id, pin):
        raise HTTPException(status_code=401, detail="Authentification échouée")
    
    context = get_patient_context(patient_id)
    docs = vectorstore.similarity_search(message, k=3)
    context += "\nDocuments pertinents:\n" + "\n".join([doc.page_content for doc in docs])
    
    # Ajouter la date actuelle au contexte
    current_time = datetime.now(pytz.timezone('Africa/Lagos')).strftime("%d %B %Y, %H:%M WAT")
    system_prompt = f"Vous êtes un assistant médical. Répondez de manière claire et précise en français, en utilisant le contexte suivant :\n{context}\nLa date et l'heure actuelles sont : {current_time}."
    
    response = mistral_client.chat.complete(
        model="mistral-small-3.2",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": message}
        ]
    )
    
    answer = response.choices[0].message.content
    
    # Enregistrer dans l'historique des conversations
    engine = create_engine(f"postgresql+psycopg2://{db_params['user']}:{db_params['password']}@{db_params['host']}:{db_params['port']}/{db_params['database']}")
    with engine.connect() as conn:
        conn.execute(
            text("INSERT INTO conversation_history (patient_id, user_message, bot_response, language) VALUES (:patient_id, :user_message, :bot_response, :language)"),
            {"patient_id": patient_id, "user_message": message, "bot_response": answer, "language": language}
        )
    
    return {"response": answer}