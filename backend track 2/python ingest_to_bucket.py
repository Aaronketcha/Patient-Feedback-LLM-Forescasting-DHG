import os
import requests
from bs4 import BeautifulSoup
from PyPDF2 import PdfReader
from google.cloud import storage
import io
import uuid
from datetime import datetime

# Configurer les credentials Google Cloud
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = r"C:\Users\pc\Documents\UCAC-ICAM\X4\Hackaton\chatbot backend\grounded-datum-466612-u9-d780d55633f3.json"
# Initialiser le client Google Cloud Storage
storage_client = storage.Client()
# Nom du bucket (à créer au préalable dans Google Cloud Console)
bucket_name = "grounded-datum-466612-u9-clinical-data"

# Dossier local contenant les documents
local_docs_folder = r"C:\Users\pc\Documents\UCAC-ICAM\X4\Hackaton\chatbot backend\RAG"

# Liste d'URLs à ingérer (exemple)
urls = [
    "https://www.hepb.org/languages/french/general-information/",
    "https://www.hepb.org/languages/french/la-vaccination-contre-lhepatite-b/",
    "https://www.hepb.org/languages/french/blood-test/",
    "https://www.hepb.org/languages/french/living-with-hepatitis-b/",
    "https://www.hepb.org/languages/french/pregnancy/",
    "https://www.arcat-sante.org/infos-cles/hepatites/traitement-de-lhepatite-chronique-b-lhepatite-b-sous-controle/",
    "https://www.passporthealthglobal.com/fr-ca/services-sante-voyage/prevention-de-la-dengue/",
    "https://www.vidal.fr/sante/voyage/conseils-sante-pays/afrique-equatoriale.html",
    "https://pharmacomedicale.org/medicaments/par-specialites/item/traitements-de-l-anemie-les-points-essentiels",
    "https://www.who.int/fr/news-room/fact-sheets/detail/anaemia",
    "https://exphar.com/info/traitement-curatif-des-anemies-ferriprives-par-deficit-de-fer/",
    "https://ileauxepices.com/blog/2017/01/16/lanemie-definition-causes-et-remedes-naturels/wpid12167/",
    "https://nutriandco.com/fr/pages/aliments-contre-l-anemie",
    "https://www.msdmanuals.com/fr/professional/maladies-infectieuses/bacilles-gram-n%C3%A9gatifs/fi%C3%A8vre-typho%C3%AFde#Symptomatologie_v11560016_fr",
    "https://www.who.int/fr/news-room/fact-sheets/detail/typhoid",
    "https://www.pharmanity.com/medicaments/fievre-typhoide-indications-22431",
    "https://www.medicoverhospitals.in/fr/articles/12-home-remedies-for-typhoid",
    "https://pmc.ncbi.nlm.nih.gov/articles/PMC7733348/",
    "https://www.france24.com/fr/20200502-covid-19-au-cameroun-la-m%C3%A9thode-raoult-%C3%A9rig%C3%A9e-en-protocole-d-%C3%A9tat",
    "https://www.afro.who.int/fr/node/12355",
    "https://www.who.int/fr/emergencies/diseases/novel-coronavirus-2019/advice-for-public",
    "https://www.canada.ca/fr/sante-publique/services/maladies/2019-nouveau-coronavirus/prevention-risques.html"
]

def extract_text_from_html(url):
    """Extraire le texte d'une page HTML."""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, "html.parser")
        # Supprimer les balises inutiles (scripts, styles, etc.)
        for script in soup(["script", "style", "nav", "footer", "header"]):
            script.decompose()
        text = soup.get_text(separator=" ", strip=True)
        return clean_text(text)
    except Exception as e:
        print(f"Erreur lors de l'extraction HTML de {url}: {e}")
        return None


def extract_text_from_pdf(file_path=None, url=None):
    """Extraire le texte d'un PDF (local ou depuis une URL)."""
    try:
        if url:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            pdf_file = io.BytesIO(response.content)
        else:
            pdf_file = file_path
        reader = PdfReader(pdf_file)
        text = ""
        for page in reader.pages:
            page_text = page.extract_text() or ""
            text += page_text
        return clean_text(text)
    except Exception as e:
        print(f"Erreur lors de l'extraction PDF : {e}")
        return None

def clean_text(text):
    """Nettoyer le texte pour enlever les lignes vides ou trop courtes."""
    if not text:
        return ""
    lines = text.split("\n")
    cleaned = [line.strip() for line in lines if line.strip() and len(line) > 10]
    return "\n".join(cleaned)

def upload_to_bucket(content, filename, bucket_name="grounded-datum-466612-u9-clinical-data"):
    """Téléverser le contenu dans le bucket Google Cloud Storage."""
    if not content:
        print(f"Contenu vide pour {filename}, téléversement annulé.")
        return
    bucket = storage_client.bucket(bucket_name)
    # Ajouter un horodatage pour éviter les conflits de noms
    unique_filename = f"{filename.split('.')[0]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
    blob = bucket.blob(unique_filename)
    try:
        blob.upload_from_string(content, content_type="text/plain")
        print(f"Fichier {unique_filename} téléversé dans le bucket {bucket_name}.")
    except Exception as e:
        print(f"Erreur lors du téléversement de {unique_filename}: {e}")

def ingest_local_documents():
    """Téléverser les documents locaux dans le bucket."""
    if not os.path.exists(local_docs_folder):
        print(f"Dossier {local_docs_folder} non trouvé.")
        return
    for filename in os.listdir(local_docs_folder):
        file_path = os.path.join(local_docs_folder, filename)
        if filename.endswith(".txt"):
            with open(file_path, "r", encoding="utf-8") as f:
                content = clean_text(f.read())
                upload_to_bucket(content, f"local/{filename}")
        elif filename.endswith(".json"):
            with open(file_path, "r", encoding="utf-8") as f:
                import json
                data = json.load(f)
                content = clean_text(json.dumps(data, ensure_ascii=False))
                upload_to_bucket(content, f"local/{filename.replace('.json', '.txt')}")
        elif filename.endswith(".pdf"):
            content = extract_text_from_pdf(file_path=file_path)
            upload_to_bucket(content, f"local/pdf_{filename.replace('.pdf', '.txt')}")

def ingest_url_documents():
    """Téléverser les documents depuis les URLs dans le bucket."""
    for url in urls:
        # Générer un nom de fichier unique basé sur l'URL
        filename = url.split("/")[-1] or "document"
        filename = filename.replace(".html", "").replace(".pdf", "").replace(".txt", "")
        filename = f"{filename}_{uuid.uuid4().hex[:8]}"  # Ajouter un UUID court
        if url.endswith(".pdf"):
            content = extract_text_from_pdf(url=url)
            upload_to_bucket(content, f"web/pdf_{filename}.txt")
        elif url.endswith(".txt"):
            try:
                response = requests.get(url, timeout=10)
                response.raise_for_status()
                content = clean_text(response.text)
                upload_to_bucket(content, f"web/{filename}.txt")
            except Exception as e:
                print(f"Erreur lors du téléversement de {url}: {e}")
        else:
            content = extract_text_from_html(url)
            upload_to_bucket(content, f"web/html_{filename}.txt")

def main():
    """Créer le bucket si nécessaire et ingérer les documents."""
    try:
        bucket = storage_client.get_bucket(bucket_name)
        print(f"Bucket {bucket_name} déjà existant.")
    except:
        bucket = storage_client.create_bucket(bucket_name)
        print(f"Bucket {bucket_name} créé.")
    
    # Ingérer les documents locaux
    print("Ingestion des documents locaux...")
    ingest_local_documents()
    
    # Ingérer les documents depuis les URLs
    print("Ingestion des documents depuis les URLs...")
    ingest_url_documents()
    
    print("Ingestion terminée.")

if __name__ == "__main__":
    main()

