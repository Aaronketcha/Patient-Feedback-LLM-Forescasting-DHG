#  Reminder Backend API

API de gestion de rappels de prise de médicaments, développée avec **FastAPI**. Elle permet de planifier et d'envoyer des rappels via WhatsApp à l'aide de **Twilio**.

---

##  Structure du projet

```
reminder_backend/
├── main.py
├── config.py
├── models.py
├── crud.py
├── routers/
│   └── medications.py
├── scheduler.py
├── medications.json
├── requirements.txt
```

---

## Prérequis

- Python 3.10 ou plus recommandé
- `pip` ou `pipenv`
- Accès Internet (pour Twilio)
- Un compte Twilio configuré pour WhatsApp

---

##  Installation

### 1. Clonez le projet

```bash
git clone https://github.com/votre-utilisateur/reminder_backend.git
cd reminder_backend
```

### 2. Créez un environnement virtuel (recommandé)

```bash
python -m venv env
source env/bin/activate     # Linux/macOS
env\Scripts\activate      # Windows
```

### 3. Installez les dépendances

```bash
pip install -r requirements.txt
```

> Si le fichier `requirements.txt` n'existe pas encore, créez-le via :
>
> ```bash
> pip freeze > requirements.txt
> ```

---

##  Configuration

1. **Fichier `medications.json`**  
   Ajoutez vos médicaments avec la structure suivante :

```json
[
  {
    "id": "med001",
    "medicationName": "Ibuprofen",
    "startDate": "2025-07-16T00:00:00",
    "duration": 6,
    "dosage": "3 times/day",
    "times": ["09:00", "16:30", "22:00"],
    "image": "https://placehold.co/60x60/AEC6CF/FFFFFF?text=IBU",
    "frequency": "daily",
    "phoneNumber": "+2376XXXXXXXX"
  }
]
```

2. **Fichier `config.py`**  
   Renseignez vos identifiants Twilio :

```python
TWILIO_ACCOUNT_SID = "your_sid"
TWILIO_AUTH_TOKEN = "your_token"
TWILIO_FROM = "whatsapp:+14155238886"
```

---

##  Démarrage du serveur

### En local

```bash
uvicorn reminder_backend.main:app --reload
```

### Sur le réseau local (LAN)

```bash
 uvicorn main:app --app-dir . --host 0.0.0.0 --port 8000 --reload
```

Puis accédez à :

```
http://<IP_de_votre_machine>:8000/medications/
```

> Pour trouver votre IP :
> - `ipconfig` (Windows)
> - `ifconfig` ou `ip a` (Linux/macOS)

---

##  Endpoints disponibles

- `GET /medications/` : Liste des médicaments

---

##  Conseils utiles

- Vérifiez que le **pare-feu Windows** autorise le port 8000.
- Twilio Sandbox WhatsApp : seuls les numéros vérifiés peuvent recevoir les messages.
- Heures au format `"HH:MM"` (24h).

---

##  Support

Pour toute aide ou contribution, contactez [votre.email@exemple.com] ou créez une issue.

---

##  Licence

Ce projet est sous licence MIT.
