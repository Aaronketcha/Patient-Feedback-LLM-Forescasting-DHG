from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging

from routers import medications
from scheduler import scheduler, load_medications_into_scheduler
from crud import load_medications_data

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Définir la fonction lifespan avant de l'utiliser
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gère les événements de démarrage et d'arrêt de l'application.
    Charge les données et démarre le scheduler au démarrage.
    """
    logging.info("Application startup event: Loading medications and starting scheduler.")
    
    medications_data = load_medications_data()
    app.state.medications = medications_data  # Stocke les médicaments dans l'état de l'application

    if not app.state.medications:
        logging.warning("No medication data loaded. Check medications.json file.")

    scheduler.start()
    load_medications_into_scheduler(app.state.medications)  # Charge les médicaments dans le scheduler
    logging.info("Scheduler started and initial reminders scheduled.")

    yield  # L'application est en cours d'exécution

    logging.info("Application shutdown event: Shutting down scheduler.")
    scheduler.shutdown()
    logging.info("Scheduler shut down.")

# Créer l'instance de l'application après avoir défini lifespan
app = FastAPI(lifespan=lifespan)

# Configuration du middleware CORS
origins = [
    "http://localhost",  # Pour les tests locaux
    "*"  # Autorise tous les domaines (utilisez avec précaution en production)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,  # Domaines autorisés
    allow_credentials=True,
    allow_methods=["*"],  # Autorise toutes les méthodes (GET, POST, etc.)
    allow_headers=["*"],  # Autorise tous les en-têtes
)

# Inclure les routeurs de l'API
app.include_router(medications.router)

# Pour exécuter ce serveur, utilisez la commande dans votre terminal:
# uvicorn main:app --reload
# Assurez-vous que le fichier medications.json est dans le même répertoire que main.py