from fastapi import FastAPI
from contextlib import asynccontextmanager
import logging

# Les imports relatifs sont corrects si le dossier est traité comme un package Python
# Assurez-vous que le dossier 'routers' contient un fichier __init__.py (même vide)
from .routers import medications
from .scheduler import scheduler, load_medications_into_scheduler
from .crud import load_medications_data

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Gère les événements de démarrage et d'arrêt de l'application.
    Charge les données et démarre le scheduler au démarrage.
    """
    logging.info("Application startup event: Loading medications and starting scheduler.")
    
    medications_data = load_medications_data()
    app.state.medications = medications_data # Stocke les médicaments dans l'état de l'application

    if not app.state.medications:
        logging.warning("No medication data loaded. Check medications.json file.")

    scheduler.start()
    load_medications_into_scheduler(app.state.medications) # Charge les médicaments dans le scheduler
    logging.info("Scheduler started and initial reminders scheduled.")

    yield # L'application est en cours d'exécution

    logging.info("Application shutdown event: Shutting down scheduler.")
    scheduler.shutdown()
    logging.info("Scheduler shut down.")

# L'objet FastAPI est maintenant défini directement au niveau supérieur
# pour être facilement trouvé par Uvicorn.
app = FastAPI(lifespan=lifespan)

# Inclure les routeurs de l'API
app.include_router(medications.router)

# Pour exécuter ce serveur, utilisez la commande dans votre terminal:
# Naviguez D'ABORD au répertoire PARENT de 'medication_backend'
# Par exemple, si 'medication_backend' est dans 'Projet_mobile/reminder_backend',
# alors naviguez à 'Projet_mobile/reminder_backend' et exécutez:
# uvicorn medication_backend.main:app --reload
# Ou si vous êtes déjà dans 'medication_backend', vous pouvez essayer:
# python -m uvicorn main:app --reload
# Assurez-vous que le fichier medications.json est dans le même répertoire que main.py
