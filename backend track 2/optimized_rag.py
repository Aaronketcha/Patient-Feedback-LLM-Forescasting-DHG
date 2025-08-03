from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from google.cloud import storage
import os
import pickle
from sqlalchemy import create_engine
import pandas as pd

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = r"C:\Users\pc\Documents\UCAC-ICAM\X4\Hackaton\chatbot backend\grounded-datum-466612-u9-d780d55633f3.json"
storage_client = storage.Client()
bucket_name = "grounded-datum-466612-u9-clinical-data"

db_params = {
    'host': '34.67.192.222',
    'port': '5432',
    'database': 'clinical_db',
    'user': 'aaron',
    'password': 'Datathon25'
}

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

def create_optimized_vector_store():
    documents, metadatas = load_documents_from_bucket()
    embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    vectorstore = Chroma.from_texts(
        texts=documents,
        embedding=embeddings,
        metadatas=metadatas,
        persist_directory="./chroma_db",
        collection_metadata={"hnsw:space": "cosine"}
    )
    
    # Cache des requêtes fréquentes
    cache_file = "query_cache.pkl"
    cache = {}
    if os.path.exists(cache_file):
        with open(cache_file, "rb") as f:
            cache = pickle.load(f)
    
    def cached_similarity_search(query, k=3):
        if query in cache:
            return cache[query]
        results = vectorstore.similarity_search(query, k=k)
        cache[query] = results
        with open(cache_file, "wb") as f:
            pickle.dump(cache, f)
        return results
    
    print("Pipeline RAG optimisé créé.")
    return vectorstore, cached_similarity_search

if __name__ == "__main__":
    create_optimized_vector_store()