API de Gestion des Retours et Rappels des Patients
Cette API fournit un système robuste pour gérer les retours des patients et les rappels de rendez-vous dans un contexte de santé. Elle permet d'envoyer des rappels via WhatsApp, SMS ou appels vocaux, d'analyser les retours des patients pour leur sentiment et leur urgence, et de planifier des tâches périodiques avec Celery. L'API est construite avec FastAPI, SQLAlchemy, PostgreSQL, Twilio et Celery avec Redis.

Fonctionnalités
Authentification des Patients : Authentification basée sur JWT pour les patients et les administrateurs.
Gestion des Retours : Soumettre et analyser les retours des patients pour leur sentiment, leurs thèmes et leur urgence.
Gestion des Rappels :
Créer, mettre à jour, supprimer et lister les rappels pour les rendez-vous des patients.
Envoyer des rappels via WhatsApp, SMS ou appels vocaux avec Twilio.
Rechercher des rappels avec des filtres (méthode, langue, statut d'envoi, heure planifiée, raison du rendez-vous).
Support de la pagination pour la liste et la recherche des rappels.
Tâches Périodiques : Déclencher automatiquement les rappels en attente toutes les heures avec Celery et Redis.
Validation des Données : Valider les numéros de téléphone, les méthodes de rappel (whatsapp, sms, call) et les langues (english, french).
Journalisation : Journalisation complète de toutes les opérations (création, mises à jour, suppressions, envoi de messages) avec contexte utilisateur.
Base de Données : PostgreSQL pour le stockage persistant des patients, retours et rappels.
Pile Technologique
Framework Backend : FastAPI
ORM pour la Base de Données : SQLAlchemy avec PostgreSQL
Authentification : JWT (JSON Web Tokens)
Service de Messagerie : Twilio (WhatsApp, SMS, Voix)
File d'Attente des Tâches : Celery avec Redis
Journalisation : Module logging de Python
Gestion de l'Environnement : python-dotenv
Pré-requis
Python 3.9+
PostgreSQL 13+
Redis 6+
Compte Twilio avec les fonctionnalités WhatsApp, SMS et Voix configurées
Variables d'environnement configurées dans un fichier .env
Installation
Cloner le Dépôt

git clone https://github.com/votre-depot/patient-feedback-system.git
cd patient-feedback-system
Configurer un Environnement Virtuel

python -m venv venv
source venv/bin/activate  # Sous Windows : venv\Scripts\activate
Installer les Dépendances

Mettez à jour requirements.txt avec le contenu suivant :

fastapi==0.111.0
uvicorn==0.23.2
sqlalchemy==2.0.31
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-dotenv==1.0.0
twilio==9.2.3
celery==5.2.7
redis==4.6.0
pytest==7.4.0
pytest-asyncio==0.21.0
Installez les dépendances :

pip install -r requirements.txt
Configurer les Variables d'Environnement

Créez un fichier .env à la racine du projet :

DATABASE_URL=postgresql://utilisateur:mot_de_passe@localhost:5432/feedback_db
JWT_SECRET_KEY=votre_clé_jwt_sécurisée
TWILIO_ACCOUNT_SID=votre_twilio_account_sid
TWILIO_AUTH_TOKEN=votre_twilio_auth_token
TWILIO_WHATSAPP_NUMBER=whatsapp:+votre_numéro_whatsapp
TWILIO_PHONE_NUMBER=+votre_numéro_téléphone
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/0
ENV=development  # Passez à 'production' pour les appels Twilio réels
Configurer PostgreSQL

Créez une base de données :

CREATE DATABASE feedback_db;
Configurer Redis

Lancez Redis via Docker :

docker run -d -p 6379:6379 redis
Vérifiez la connexion :

redis-cli ping  # Doit retourner "PONG"
Initialiser les Tables de la Base de Données

Exécutez le script suivant pour créer les tables :

from app.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
Lancement de l'Application
Démarrer le Serveur FastAPI

uvicorn app.main:app --reload
L'API sera disponible à http://localhost:8000.

Démarrer le Worker Celery

celery -A app.celery_app worker --loglevel=info
Démarrer Celery Beat (pour les tâches périodiques)

celery -A app.celery_app beat --loglevel=info
Accéder à la Documentation de l'API

Ouvrez http://localhost:8000/docs dans votre navigateur pour consulter l'interface Swagger interactive.

Endpoints de l'API
Authentification
POST /auth/token : Obtenir un jeton JWT pour l'authentification.
Requête : { "username": "nom_patient", "password": "mot_de_passe" }
Réponse : { "access_token": "jeton_jwt", "token_type": "bearer" }
Retours
POST /feedback/submit : Soumettre un retour de patient.
Requis : Jeton JWT, rôle admin ou patient.
GET /feedback/metrics : Récupérer les analyses des retours (sentiment, thèmes, urgence).
Requis : Jeton JWT, rôle admin.
Rappels
POST /reminders/create : Créer un nouveau rappel (admin uniquement).
Exemple de requête :
{
  "patient_id": "<uuid>",
  "patient_name": "Jane Doe",
  "phone_number": "+237987654321",
  "appointment_reason": "Visite de suivi",
  "medication_list": "Aspirine",
  "consultation_list": "Cardiologie",
  "language": "french",
  "method": "whatsapp",
  "scheduled_time": "2025-07-26T10:00:00"
}
GET /reminders/list : Lister les rappels pour un patient avec pagination.
Paramètres de requête : patient_id, skip, limit
Exemple : /reminders/list?patient_id=<uuid>&skip=0&limit=10
GET /reminders/search : Rechercher des rappels avec des filtres.
Paramètres de requête : patient_id, method, language, sent, scheduled_after, appointment_reason, skip, limit
Exemple : /reminders/search?patient_id=<uuid>&method=whatsapp&scheduled_after=2025-07-26T00:00:00Z&appointment_reason=suivi
POST /reminders/trigger : Déclencher les rappels en attente (admin uniquement).
DELETE /reminders/delete/{reminder_id} : Supprimer un rappel par ID (admin uniquement).
PUT /reminders/update/{reminder_id} : Mettre à jour un rappel par ID (admin uniquement).
Tests
Créer des Données de Test

from app.crud import create_patient
from app.database import SessionLocal

db = SessionLocal()
create_patient(db, name="JaneDoe", password="secure123", role="patient", phone_number="+237987654321")
create_patient(db, name="AdminUser", password="admin123", role="admin", phone_number="+237123456789")
db.close()
Tester les Endpoints

Utilisez curl ou Postman pour tester les endpoints. Exemple pour créer un rappel :

curl -X POST "http://localhost:8000/reminders/create" \
     -H "Authorization: Bearer <jeton_jwt_admin>" \
     -H "Content-Type: application/json" \
     -d '{
         "patient_id": "<uuid_patient>",
         "patient_name": "Jane Doe",
         "phone_number": "+237987654321",
         "appointment_reason": "Visite de suivi",
         "medication_list": "Aspirine",
         "consultation_list": "Cardiologie",
         "language": "french",
         "method": "whatsapp",
         "scheduled_time": "2025-07-26T10:00:00"
     }'
Vérifier les Logs

Consultez les logs dans app.log :

cat app.log
Exemple de log :

2025-07-25 21:40:00,123 - app.utils.reminders - INFO - Sent WhatsApp to +237987654321 in french by user <uuid_utilisateur>: Rappel pour Jane Doe : Visite de suivi
Notes de Configuration
Twilio : Assurez-vous que les identifiants et numéros Twilio sont valides dans .env. En mode development (ENV=development), les appels vocaux sont simulés pour éviter les coûts.
Celery : Le déclenchement périodique des rappels s'exécute toutes les heures. Ajustez la planification dans app/celery_app.py si nécessaire (ex. : crontab(minute="*/5") pour toutes les 5 minutes).
Validation :
Les numéros de téléphone doivent être au format international (ex. : +237xxxxxxxxxx).
Méthodes de rappel : whatsapp, sms, call.
Langues : english, french.
Sécurité : Stockez les données sensibles (clé JWT, identifiants Twilio) de manière sécurisée dans .env.
Améliorations Futures
Tests Unitaires : Ajouter des tests avec pytest et pytest-asyncio pour les endpoints et les tâches Celery.
Traduction des Messages : Intégrer une API de traduction pour une localisation dynamique des messages.
Politiques de Réessai : Implémenter des stratégies de réessai pour les tâches Twilio et Celery avec tenacity.
Tableau de Bord Admin : Ajouter des endpoints pour les statistiques des rappels et retours.
Monitoring : Utiliser Flower pour surveiller les tâches Celery (celery -A app.celery_app flower).
Contribution
Forkez le dépôt.
Créez une branche pour votre fonctionnalité (git checkout -b feature/votre-fonctionnalité).
Validez vos changements (git commit -m "Ajouter votre fonctionnalité").
Poussez vers la branche (git push origin feature/votre-fonctionnalité).
Ouvrez une Pull Request.
Licence
Licence MIT. Voir LICENSE pour plus de détails.

