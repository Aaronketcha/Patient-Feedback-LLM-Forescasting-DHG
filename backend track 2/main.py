from fastapi import FastAPI, HTTPException
from google.cloud import translate_v2 as translate
from google.cloud import secretmanager
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.llms import HuggingFacePipeline
from langchain.prompts import PromptTemplate
from langchain.chains import RetrievalQA
import os
import json
import psycopg2
from datetime import datetime
from google.api_core.exceptions import NotFound, PermissionDenied
from google.oauth2 import service_account
from transformers import pipeline

app = FastAPI()

# Paramètres de connexion à la base de données
db_params = {
    'host': os.getenv('DB_HOST', '34.67.192.222'),  # Utilise Cloud SQL Auth Proxy
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'clinical_db'),
    'user': os.getenv('DB_USER', 'aaron'),
    'password': os.getenv('DB_PASSWORD', 'Datathon25')
}

# Fonction pour établir une connexion à la base de données
def get_db_connection():
    try:
        conn = psycopg2.connect(**db_params)
        return conn
    except Exception as e:
        print(f"Erreur lors de la connexion à la base de données : {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur de connexion à la base de données : {str(e)}")

# Accéder à Secret Manager
def access_secret(project_id="grounded-datum-466612-u9", secret_id="translation-service-account-key", version_id="1", parse_json=False):
    print(f"Tentative d'accès au secret {secret_id} dans le projet {project_id}, version {version_id}")
    if not project_id or not secret_id:
        raise ValueError("project_id et secret_id doivent être fournis")
    
    try:
        credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "translation-service-account-key.json")
        credentials = service_account.Credentials.from_service_account_file(
            credentials_path,
            scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        client = secretmanager.SecretManagerServiceClient(credentials=credentials)
        name = f"projects/{project_id}/secrets/{secret_id}/versions/{version_id}"
        response = client.access_secret_version(request={"name": name})
        secret_data = response.payload.data.decode("UTF-8")
        print(f"Secret récupéré avec succès : {secret_id}, version {version_id}")
        
        if parse_json:
            return json.loads(secret_data)
        return secret_data
    
    except NotFound as e:
        print(f"Erreur : Secret {secret_id} version {version_id} non trouvé")
        raise NotFound(f"Secret {secret_id} version {version_id} non trouvé dans le projet {project_id}: {str(e)}")
    except PermissionDenied as e:
        print(f"Erreur : Accès refusé pour le secret {secret_id} version {version_id}")
        raise PermissionDenied(f"Accès refusé pour le secret {secret_id} version {version_id}: {str(e)}")
    except Exception as e:
        print(f"Erreur inattendue : {str(e)}")
        raise Exception(f"Erreur lors de l'accès au secret {secret_id} version {version_id}: {str(e)}")

# Récupérer la clé JSON
print("Initialisation de la clé JSON")
try:
    key_data = access_secret(parse_json=True)
    with open("translation-service-account-key.json", "w") as f:
        json.dump(key_data, f)
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "translation-service-account-key.json"
    print("Clé JSON configurée avec succès")
except Exception as e:
    print(f"Erreur lors de la configuration de la clé JSON : {str(e)}")
    raise

# Initialiser le client Translation
try:
    translate_client = translate.Client()
    print("Client Translation initialisé")
except Exception as e:
    print(f"Erreur lors de l'initialisation du client Translation : {str(e)}")
    raise

# Charger le magasin vectoriel
print("Téléchargement de chroma_db")
os.system("gsutil cp -r gs://grounded-datum-466612-u9-clinical-data/chroma_db ./chroma_db")
print("Initialisation du vectorstore")
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vectorstore = Chroma(persist_directory="./chroma_db", embedding_function=embeddings)
print("Vectorstore chargé")

# Initialiser le modèle LLM pour RAG
print("Initialisation du modèle LLM")
llm = HuggingFacePipeline.from_model_id(
    model_id="facebook/bart-large",
    task="text-generation",
    pipeline_kwargs={"max_length": 512, "temperature": 0.7}
)
prompt_template = PromptTemplate(
    input_variables=["context", "question"],
    template="Vous êtes un assistant médical. Basé sur les informations suivantes : {context}, répondez à la question : {question}"
)
qa_chain = RetrievalQA.from_chain_type(
    llm=llm,
    chain_type="stuff",
    retriever=vectorstore.as_retriever(search_kwargs={"k": 3, "filter": {"patient_id": None}}),
    chain_type_kwargs={"prompt": prompt_template}
)
print("Modèle LLM initialisé")

# Fonction pour détecter la langue
def detect_language(text: str) -> str:
    try:
        if not text.strip():
            return "fr"  # Langue par défaut si le texte est vide
        result = translate_client.detect_language(text)
        return result["language"]
    except Exception as e:
        print(f"Erreur lors de la détection de la langue : {str(e)}")
        return "fr"  # Fallback au français

# Fonction pour traduire le texte
def translate_text(text: str, target_language: str) -> str:
    try:
        if target_language == "en":  # Pas de traduction si la langue est l'anglais (langue du LLM)
            return text
        result = translate_client.translate(text, target_language=target_language)
        return result["translatedText"]
    except Exception as e:
        print(f"Erreur lors de la traduction : {str(e)}")
        return text

# Fonction pour enregistrer les interactions dans conversation_history
def save_conversation(patient_id: str, message: str, response: str, language: str):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO conversation_history (patient_id, user_message, bot_response, timestamp, language)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (patient_id, message, response, datetime.utcnow(), language)
        )
        conn.commit()
        cursor.close()
        conn.close()
        print(f"Interaction enregistrée pour patient_id {patient_id} en langue {language}")
    except Exception as e:
        print(f"Erreur lors de l'enregistrement de l'interaction : {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'enregistrement de l'interaction : {str(e)}")

@app.get("/translate")
async def translate_text_endpoint(text: str, target_language: str = "fr"):
    try:
        result = translate_client.translate(text, target_language=target_language)
        print(f"Traduction réussie : {text} -> {result['translatedText']}")
        return {"original": text, "translated": result['translatedText'], "language": target_language}
    except Exception as e:
        print(f"Erreur de traduction : {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur de traduction : {str(e)}")

@app.get("/chat")
async def chat(message: str, patient_id: str):
    try:
        # Connexion à la base de données
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Récupérer les informations du patient depuis clinical_summaries
        cursor.execute("SELECT patient_id, patient_age, patient_gender FROM clinical_summaries WHERE patient_id = %s", (patient_id,))
        patient = cursor.fetchone()
        
        if not patient:
            cursor.close()
            conn.close()
            raise HTTPException(status_code=404, detail=f"Patient ID {patient_id} non trouvé dans la base de données")
        
        # Extraire les informations
        patient_info = {
            "patient_id": patient[0],
            "age": patient[1],
            "gender": patient[2]
        }
        
        # Fermer la connexion
        cursor.close()
        conn.close()
        
        # Détecter la langue du message
        language = detect_language(message)
        
        # Mettre à jour le filtre du retriever pour le patient spécifique
        qa_chain.retriever.search_kwargs["filter"] = {"patient_id": patient_id}
        
        # Générer la réponse initiale ou continue
        if message.lower() in ["", "start"]:  # Première interaction
            initial_questions = {
                "fr": "Voulez-vous connaître votre diagnostic ?",
                "en": "Would you like to know your diagnosis?",
                "es": "¿Desea conocer su diagnóstico?",
                # Ajouter d'autres langues si nécessaire
            }
            chat_response = initial_questions.get(language, initial_questions["fr"])
        else:
            # Traduire la question en anglais pour le RAG (LLM en anglais)
            question_en = translate_text(message, "en") if language != "en" else message
            # Utiliser RAG pour répondre
            rag_response = qa_chain.run(question_en)
            # Traduire la réponse dans la langue du patient
            chat_response = translate_text(rag_response.strip(), language)
        
        # Enregistrer l'interaction
        save_conversation(patient_id, message, chat_response, language)
        
        # Construire la réponse
        response = {
            "message": message,
            "patient_info": patient_info,
            "chat_response": chat_response,
            "language": language
        }
        return response
    except Exception as e:
        print(f"Erreur lors du chat : {str(e)}")
        raise HTTPException(status_code=500, detail=f"Erreur lors du traitement du chat : {str(e)}")