import psycopg2
import os
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.docstore.document import Document

# Paramètres de connexion à la base de données
db_params = {
    'host': os.getenv('DB_HOST', '34.67.192.222'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'clinical_db'),
    'user': os.getenv('DB_USER', 'aaron'),
    'password': os.getenv('DB_PASSWORD', 'Datathon25')
}

def get_db_connection():
    try:
        conn = psycopg2.connect(**db_params)
        return conn
    except Exception as e:
        print(f"Erreur lors de la connexion à la base de données : {str(e)}")
        raise

def load_clinical_summaries_to_chroma():
    # Connexion à la base de données
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Récupérer la structure de la table pour inclure toutes les colonnes pertinentes
    cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'clinical_summaries'")
    columns = [row[0] for row in cursor.fetchall()]
    print(f"Colonnes disponibles dans clinical_summaries : {columns}")
    
    # Exclure patient_id, age, gender pour le contenu du document, inclure les autres colonnes
    content_columns = [col for col in columns if col not in ['patient_id', 'patient_age', 'patient_gender']]
    if not content_columns:
        print("Aucune colonne de contenu trouvée (ex. diagnosis, summary).")
        return
    
    # Construire la requête SQL
    select_columns = ', '.join(content_columns)
    cursor.execute(f"SELECT patient_id, patient_age, patient_gender, {select_columns} FROM clinical_summaries")
    rows = cursor.fetchall()
    
    # Créer des documents pour Chroma
    documents = []
    for row in rows:
        patient_id, age, gender = row[:3]
        content_values = row[3:]
        # Combiner les colonnes de contenu
        content_parts = [f"{content_columns[i]}: {value}" for i, value in enumerate(content_values) if value]
        content = f"Patient ID: {patient_id}, Age: {age}, Gender: {gender}, " + ", ".join(content_parts)
        documents.append(Document(page_content=content, metadata={"patient_id": patient_id}))
        print(f"Document créé pour patient_id {patient_id}: {content}")
    
    # Fermer la connexion
    cursor.close()
    conn.close()
    
    # Supprimer l'ancien dossier chroma_db
    if os.path.exists("./chroma_db"):
        import shutil
        shutil.rmtree("./chroma_db")
    
    # Initialiser les embeddings et le vectorstore
    embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    vectorstore = Chroma.from_documents(
        documents=documents,
        embedding=embeddings,
        persist_directory="./chroma_db"
    )
    vectorstore.persist()
    print("Données chargées dans chroma_db")

if __name__ == "__main__":
    load_clinical_summaries_to_chroma()