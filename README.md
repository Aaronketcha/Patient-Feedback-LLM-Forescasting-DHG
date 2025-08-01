# Système de Retour des Patients

Une API basée sur FastAPI pour gérer les retours et rappels des patients dans les établissements de santé, optimisée pour les environnements à faible bande passante.

## Fonctionnalités
- **Authentification** : Authentification basée sur JWT pour les patients et les administrateurs.
- **Gestion des retours** : Soumission de retours textuels ou vocaux, avec analyse de sentiment, extraction de thèmes et détection d’urgence.
- **Transcription vocale** : Transcription automatique des retours audio à l’aide de `speech_recognition`.
- **Traduction** : Traduction des retours depuis les langues locales (Douala, Bassa) vers l’anglais.
- **Rappels** : Planification et envoi de rappels via WhatsApp, SMS ou appels vocaux à l’aide de Twilio.
- **Analytique** : Métriques du tableau de bord pour les administrateurs, incluant les taux de satisfaction et les problèmes urgents.
- **Optimisations** :
  - Compression Gzip pour les réponses API et les tâches Celery.
  - Mise en cache Redis pour les requêtes fréquentes.
  - File d’attente hors ligne pour les messages Twilio utilisant SQLite.
  - Modèle NLP léger (`distilbert-base-multilingual-cased`).
  - Détection de langue hors ligne avec `fasttext`.
  - Ensembles de données de traduction stockés dans PostgreSQL.

## Prérequis
- Python 3.9+
- PostgreSQL
- Redis
- Compte Twilio
- Modèle FastText (`lid.176.bin`)

## Configuration
1. Cloner le dépôt :
   ```bash
   git clone https://github.com/votre-repo/patient-feedback-system.git
   cd patient-feedback-system
   ```
2. Installer les dépendances :
   ```bash
   pip install -r requirements.txt
   ```
3. Configurer les variables d’environnement dans `.env` :
   ```bash
   DATABASE_URL=postgresql://postgres:123@localhost:5432/feedback_db
   JWT_SECRET_KEY=votre-cle-secrete
   TWILIO_ACCOUNT_SID=votre-sid-twilio
   TWILIO_AUTH_TOKEN=votre-token-twilio
   TWILIO_WHATSAPP_NUMBER=whatsapp:+1234567890
   TWILIO_PHONE_NUMBER=+1234567890
   CELERY_BROKER_URL=redis://localhost:6379/0
   CELERY_RESULT_BACKEND=redis://localhost:6379/0
   ENCRYPTION_KEY=votre-cle-de-chiffrement
   FASTTEXT_MODEL=/chemin/vers/lid.176.bin
   ```
4. Initialiser la base de données :
   ```bash
   python -c "from app.database import init_db; init_db()"
   ```
5. Lancer l’API :
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```
6. Démarrer le worker et le beat de Celery :
   ```bash
   celery -A app.celery_app worker --loglevel=info
   celery -A app.celery_app beat --loglevel=info
   ```

## Configuration avec Docker
1. Construire et exécuter avec Docker Compose :
   ```bash
   docker-compose up --build
   ```
2. Accéder à l’API à `http://localhost:8000`.

## Points de terminaison de l’API
- **Authentification** : `/auth/token` (POST)
- **Retours** :
  - `/feedback/submit` (POST)
  - `/feedback/transcribe` (POST)
  - `/feedback/metrics` (GET)
  - `/feedback/dashboard/metrics` (GET)
  - `/feedback/dashboard/export` (GET)
- **Rappels** :
  - `/reminders/create` (POST)
  - `/reminders/list` (GET)
  - `/reminders/trigger` (POST)
  - `/reminders/delete/{reminder_id}` (DELETE)
  - `/reminders/update/{reminder_id}` (PUT)
  - `/reminders/search` (GET)

## Tests
Exécuter les tests avec :
```bash
pytest tests/
```

## Remarques
- Assurez-vous que `lid.176.bin` est téléchargé et placé dans `/app/models/`.
- Les fichiers audio sont temporairement stockés dans `/tmp/` pour la transcription.
- Les ensembles de données de traduction (`eng_douala.csv`, `eng_bassa.csv`) sont chargés dans PostgreSQL au démarrage.
