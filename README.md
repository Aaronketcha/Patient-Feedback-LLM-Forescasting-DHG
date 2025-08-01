Patient Feedback Analytics
Ce projet est un chatbot médical qui utilise un modèle RAG (Retrieval-Augmented Generation) pour fournir des diagnostics basés sur les données des patients stockées dans une base de données Cloud SQL et un vectorstore Chroma. Il prend en charge plusieurs langues via Google Cloud Translation et est déployé sur Google Cloud Run.
Prérequis

Python 3.9
Google Cloud SDK
Compte Google Cloud avec les permissions pour Cloud SQL, Cloud Storage, Secret Manager et Cloud Run
Git
Docker (pour la construction et le déploiement)

Dépendances
Les dépendances suivantes sont nécessaires pour exécuter le projet. Elles sont listées dans requirements.txt :

fastapi
uvicorn
langchain-huggingface
langchain_community
langchain
transformers==4.45.2
google-cloud-translate
google-cloud-secret-manager
sqlalchemy<2.0
psycopg2-binary
chromadb
sentence-transformers
pandas==1.5.3
torch==2.4.1
torchvision==0.19.1
tf-keras
google-auth

Pour installer les dépendances, exécutez :
pip install -r requirements.txt

Configuration

Cloner le dépôt :
git clone https://github.com/Aaronketcha/Patient-Feedback-Analytics.git
cd Patient-Feedback-Analytics


Configurer les variables d’environnement :

Configurez GOOGLE_APPLICATION_CREDENTIALS avec le chemin vers votre fichier de clé de compte de service Google Cloud.

Définissez les variables pour la base de données :
export DB_HOST=/cloudsql/grounded-datum-466612-u9:us-central1:medical-chatbot-db
export DB_PORT=5432
export DB_NAME=clinical_db
export DB_USER=aaron
export DB_PASSWORD=Datathon25




Charger les données dans Chroma : Exécutez le script pour charger les données de clinical_summaries dans chroma_db :
python load_clinical_summaries_to_chroma.py
gsutil cp -r ./chroma_db gs://grounded-datum-466612-u9-clinical-data/chroma_db


Lancer l’application localement :
uvicorn main:app --reload


Tester l’API :
curl "http://127.0.0.1:8000/chat?message=start&patient_id=P007282"



Déploiement sur Google Cloud Run

Construire l’image Docker :
docker build -t gcr.io/grounded-datum-466612-u9/medical-chatbot .


Pousser l’image :
gcloud builds submit --tag gcr.io/grounded-datum-466612-u9/medical-chatbot


Déployer sur Cloud Run :
gcloud run deploy medical-chatbot \
  --image gcr.io/grounded-datum-466612-u9/medical-chatbot \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars "DB_HOST=/cloudsql/grounded-datum-466612-u9:us-central1:medical-chatbot-db,DB_PORT=5432,DB_NAME=clinical_db,DB_USER=aaron,DB_PASSWORD=Datathon25,GOOGLE_CLOUD_PROJECT=grounded-datum-466612-u9" \
  --add-cloudsql-instances grounded-datum-466612-u9:us-central1:medical-chatbot-db \
  --memory 2Gi



Structure des fichiers

main.py : Point d’entrée de l’API FastAPI pour le chatbot.
load_clinical_summaries_to_chroma.py : Script pour charger les données dans Chroma.
requirements.txt : Liste des dépendances Python.
Dockerfile : Configuration pour construire l’image Docker.
