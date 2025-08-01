from app.celery_app import celery_app
from app.database import SessionLocal
from app.crud import trigger_reminders


@celery_app.task
def trigger_reminders_task():
    """
    Celery task to trigger pending reminders periodically.

    Returns:
        dict: Result of the number of reminders processed.
    """
    db = SessionLocal()
    try:
        count = trigger_reminders(db, user_id=None)  # No user_id for automated tasks
        return {"message": f"Triggered {count} reminders"}
    except Exception as e:
        db.rollback()
        raise Exception(f"Failed to trigger reminders: {str(e)}")
    finally:
        db.close()