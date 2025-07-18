# medication_backend/config.py
import os

# Chemin du fichier JSON contenant les données des médicaments
# Utilise os.path.abspath et os.path.join pour construire un chemin absolu robuste
# en se basant sur l'emplacement de ce fichier config.py
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MEDICATIONS_FILE_PATH = os.path.join(BASE_DIR, "medications.json")

# Numéro WhatsApp par défaut (utilisé pour les tests si non spécifié dans les données)
DEFAULT_WHATSAPP_NUMBER = "+237657624346"

# Fuseau horaire pour la planification des rappels (important pour les cron jobs)
TIMEZONE = "Africa/Douala" # Ou 'UTC', 'Europe/Paris', etc.

# Twilio config
TWILIO_ACCOUNT_SID = "ACedeba49bc8d4eaf57bb4d0c51116272e"
TWILIO_AUTH_TOKEN = "6ead51e5d2012672035ffa7d95fa720a"
TWILIO_FROM = "whatsapp:+14155238886"
