# Patient Feedback System

A FastAPI-based API for managing patient feedback and reminders in healthcare facilities, optimized for low-bandwidth environments.

## Features
- **Authentication**: JWT-based authentication for patients and admins.
- **Feedback Management**: Submit text or voice feedback, with sentiment analysis, theme extraction, and urgency detection.
- **Voice Transcription**: Automatic transcription of audio feedback using `speech_recognition`.
- **Translation**: Translate feedback from local languages (Douala, Bassa) to English.
- **Reminders**: Schedule and send reminders via WhatsApp, SMS, or voice calls using Twilio.
- **Analytics**: Dashboard metrics for admins, including satisfaction rates and urgent issues.
- **Optimizations**:
  - Gzip compression for API responses and Celery tasks.
  - Redis caching for frequent queries.
  - Offline queue for Twilio messages using SQLite.
  - Lightweight NLP model (`distilbert-base-multilingual-cased`).
  - Offline language detection with `fasttext`.
  - Translation datasets stored in PostgreSQL.

## Requirements
- Python 3.9+
- PostgreSQL
- Redis
- Twilio account
- FastText model (`lid.176.bin`)

## Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/patient-feedback-system.git
   cd patient-feedback-system
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Set environment variables in `.env`:
   ```bash
   DATABASE_URL=postgresql://postgres:123@localhost:5432/feedback_db
   JWT_SECRET_KEY=your-secret-key
   TWILIO_ACCOUNT_SID=your-twilio-sid
   TWILIO_AUTH_TOKEN=your-twilio-token
   TWILIO_WHATSAPP_NUMBER=whatsapp:+1234567890
   TWILIO_PHONE_NUMBER=+1234567890
   CELERY_BROKER_URL=redis://localhost:6379/0
   CELERY_RESULT_BACKEND=redis://localhost:6379/0
   ENCRYPTION_KEY=your-encryption-key
   FASTTEXT_MODEL=/path/to/lid.176.bin
   ```
4. Initialize the database:
   ```bash
   python -c "from app.database import init_db; init_db()"
   ```
5. Run the API:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```
6. Start Celery worker and beat:
   ```bash
   celery -A app.celery_app worker --loglevel=info
   celery -A app.celery_app beat --loglevel=info
   ```

## Docker Setup
1. Build and run with Docker Compose:
   ```bash
   docker-compose up --build
   ```
2. Access the API at `http://localhost:8000`.

## API Endpoints
- **Auth**: `/auth/token` (POST)
- **Feedback**:
  - `/feedback/submit` (POST)
  - `/feedback/transcribe` (POST)
  - `/feedback/metrics` (GET)
  - `/feedback/dashboard/metrics` (GET)
  - `/feedback/dashboard/export` (GET)
- **Reminders**:
  - `/reminders/create` (POST)
  - `/reminders/list` (GET)
  - `/reminders/trigger` (POST)
  - `/reminders/delete/{reminder_id}` (DELETE)
  - `/reminders/update/{reminder_id}` (PUT)
  - `/reminders/search` (GET)

## Testing
Run tests with:
```bash
pytest tests/
```

## Notes
- Ensure `lid.176.bin` is downloaded and placed in `/app/models/`.
- Audio files are temporarily stored in `/tmp/` for transcription.
- Translation datasets (`eng_douala.csv`, `eng_bassa.csv`) are loaded into PostgreSQL on startup.
