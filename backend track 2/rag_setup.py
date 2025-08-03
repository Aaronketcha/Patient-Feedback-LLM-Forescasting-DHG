from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from google.cloud import storage
import os

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = r"C:\Users\pc\Documents\UCAC-ICAM\X4\Hackaton\chatbot backend\grounded-datum-466612-u9-d780d55633f3.json"
storage_client = storage.Client()
bucket_name = "grounded-datum-466612-u9-clinical-data"

def load_documents_from_bucket():
    bucket = storage_client.bucket(bucket_name)
    blobs = bucket.list_blobs()
    documents = []
    metadatas = []
    for blob in blobs:
        if blob.name.endswith(".txt"):
            content = blob.download_as_text(encoding="utf-8")
            if content.strip():
                documents.append(content)
                metadatas.append({"source": blob.name})
    return documents, metadatas

def create_vector_store():
    documents, metadatas = load_documents_from_bucket()
    embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    batch_size = 100
    vectorstore = None
    for i in range(0, len(documents), batch_size):
        batch_texts = documents[i:i + batch_size]
        batch_metadatas = metadatas[i:i + batch_size]
        if vectorstore is None:
            vectorstore = Chroma.from_texts(batch_texts, embeddings, metadatas=batch_metadatas, persist_directory="./chroma_db")
        else:
            vectorstore.add_texts(batch_texts, metadatas=batch_metadatas)
    print("Magasin vectoriel mis à jour dans ./chroma_db.")

if __name__ == "__main__":
    create_vector_store()