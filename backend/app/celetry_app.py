from celetry_app import Celery
from celetry_app.schedules import crontab
import os

# Configure Celery with Redis as broker and backend
celery_app = Celery(
    app="patient_feedback",
    broker=os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0"),
    backend=os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/0")
)

# Celery configuration
celery_app.conf.timezone = "UTC"
celery_app.conf.task_track_started = True
celery_app.conf.task_serializer = "json"
celery_app.conf.accept_content = ["json"]
celery_app.conf.result_serializer = "json"
celery_app.conf.result_expires = 86400  # Results expire after 24 hours

# Autodiscover tasks in app.tasks
celery_app.autodiscover_tasks(["app.tasks"])

# Configure periodic tasks
celery_app.conf.beat_schedule = {
    "trigger-reminders-every-hour": {
        "task": "app.tasks.trigger_reminders_task",
        "schedule": crontab(minute=0, hour="*"),  # Run every hour
    }
}