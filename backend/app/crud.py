from sqlalchemy.orm import Session
from app import models, schemas
from passlib.context import CryptContext
from datetime import datetime
from app.utils.nlp import analyze_sentiment, extract_themes, detect_urgency
from app.utils.reminders import send_whatsapp, send_sms, send_call, validate_phone_number
from uuid import UUID
import logging

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.FileHandler("app.log")
handler.setFormatter(logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s"))
logger.addHandler(handler)

# Valid reminder methods and languages
VALID_REMINDER_METHODS = {"whatsapp", "sms", "call"}
VALID_LANGUAGES = {"english", "french"}

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_patient_by_name(db: Session, name: str) -> models.Patient:
    """
    Retrieve a patient by their name.

    Args:
        db: Database session.
        name: Patient name to query.

    Returns:
        Patient object or None if not found.
    """
    return db.query(models.Patient).filter(models.Patient.name == name).first()


def create_patient(db: Session, name: str, password: str, role: str, phone_number: str = None,
                   user_id: UUID = None) -> models.Patient:
    """
    Create a new patient in the database with encrypted phone number.

    Args:
        db: Database session.
        name: Unique patient name.
        password: Plain text password to hash.
        role: Role ('admin' or 'patient').
        phone_number: Optional phone number to encrypt.
        user_id: ID of the user performing the action (for logging).

    Returns:
        Created Patient object.
    """
    hashed_password = pwd_context.hash(password)
    db_patient = models.Patient(
        name=name,
        hashed_password=hashed_password,
        role=role,
        phone_number=phone_number
    )
    db.add(db_patient)
    db.commit()
    db.refresh(db_patient)
    logger.info(f"Created patient: {name} with role {role} by user {user_id or 'unknown'}")
    return db_patient


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify if the plain password matches the hashed password.

    Args:
        plain_password: Plain text password.
        hashed_password: Hashed password from database.

    Returns:
        True if passwords match, False otherwise.
    """
    return pwd_context.verify(plain_password, hashed_password)


def submit_feedback(db: Session, feedback: schemas.FeedbackSubmit, user_id: UUID = None) -> models.Feedback:
    """
    Submit a new feedback entry and store it in the database.

    Args:
        db: Database session.
        feedback: Feedback data from schema.
        user_id: ID of the user performing the action (for logging).

    Returns:
        Created Feedback object.
    """
    db_feedback = models.Feedback(
        feedback_id=feedback.feedback_id,
        patient_id=feedback.patient_id,
        text=feedback.text,
        rating=feedback.rating,
        language=feedback.language,
        department=feedback.department,
        submitted_at=datetime.utcnow()
    )
    db.add(db_feedback)
    db.commit()
    db.refresh(db_feedback)
    logger.info(
        f"Submitted feedback: {feedback.feedback_id} for patient {feedback.patient_id} by user {user_id or 'unknown'}")
    return db_feedback


def analyze_feedback(db: Session, feedback: models.Feedback, user_id: UUID = None) -> models.Feedback:
    """
    Analyze feedback text for sentiment, theme, and urgency, then update the database.

    Args:
        db: Database session.
        feedback: Feedback object to analyze.
        user_id: ID of the user performing the action (for logging).

    Returns:
        Updated Feedback object with analysis results.
    """
    text = feedback.text
    sentiment = analyze_sentiment([text])[0]
    theme = extract_themes([text])[0]
    urgent = detect_urgency([text])[0]

    feedback.sentiment = sentiment
    feedback.theme = theme
    feedback.urgent = urgent
    db.commit()
    logger.info(
        f"Analyzed feedback: {feedback.feedback_id} - sentiment: {sentiment}, theme: {theme}, urgent: {urgent} by user {user_id or 'unknown'}")
    return feedback


def get_feedback_metrics(db: Session, user_id: UUID = None) -> schemas.FeedbackMetrics:
    """
    Compute metrics from feedback data for dashboard analytics.

    Args:
        db: Database session.
        user_id: ID of the user performing the action (for logging).

    Returns:
        FeedbackMetrics schema with sentiment, theme, and urgency distributions.
    """
    feedbacks = db.query(models.Feedback).all()
    if not feedbacks:
        logger.warning(f"No feedback found for metrics computation by user {user_id or 'unknown'}")
        return schemas.FeedbackMetrics(
            sentiment_distribution={},
            theme_distribution={},
            urgent_by_department={},
            most_urgent_dept="None",
            total_rows=0
        )

    sentiment_dist = {}
    theme_dist = {}
    urgent_by_dept = {}

    for fb in feedbacks:
        sentiment_dist[fb.sentiment] = sentiment_dist.get(fb.sentiment, 0) + 1
        theme_dist[fb.theme] = theme_dist.get(fb.theme, 0) + 1
        if fb.urgent:
            urgent_by_dept[fb.department] = urgent_by_dept.get(fb.department, 0) + 1

    most_urgent_dept = max(urgent_by_dept.items(), key=lambda x: x[1], default=('None', 0))[0]

    logger.info(f"Computed feedback metrics: {len(feedbacks)} feedbacks processed by user {user_id or 'unknown'}")
    return schemas.FeedbackMetrics(
        sentiment_distribution=sentiment_dist,
        theme_distribution=theme_dist,
        urgent_by_department=urgent_by_dept,
        most_urgent_dept=most_urgent_dept,
        total_rows=len(feedbacks)
    )


def create_reminder(db: Session, reminder: schemas.ReminderCreate, user_id: UUID = None) -> models.Reminder:
    """
    Create a new reminder entry with encrypted phone number after validation.

    Args:
        db: Database session.
        reminder: Reminder data from schema.
        user_id: ID of the user performing the action (for logging).

    Returns:
        Created Reminder object.

    Raises:
        ValueError: If phone_number format, method, or language is invalid.
    """
    if reminder.phone_number:
        validated_number = validate_phone_number(reminder.phone_number)
        if not validated_number:
            logger.error(f"Invalid phone number format: {reminder.phone_number} by user {user_id or 'unknown'}")
            raise ValueError(f"Invalid phone number format: {reminder.phone_number}")
        reminder.phone_number = validated_number

    if reminder.method not in VALID_REMINDER_METHODS:
        logger.error(f"Invalid reminder method: {reminder.method} by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid reminder method: {reminder.method}. Must be one of {VALID_REMINDER_METHODS}")

    if reminder.language not in VALID_LANGUAGES:
        logger.error(f"Invalid language: {reminder.language} by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid language: {reminder.language}. Must be one of {VALID_LANGUAGES}")

    db_reminder = models.Reminder(
        patient_id=reminder.patient_id,
        patient_name=reminder.patient_name,
        phone_number=reminder.phone_number,
        appointment_reason=reminder.appointment_reason,
        medication_list=reminder.medication_list,
        consultation_list=reminder.consultation_list,
        language=reminder.language,
        method=reminder.method,
        scheduled_time=reminder.scheduled_time
    )
    db.add(db_reminder)
    db.commit()
    db.refresh(db_reminder)
    logger.info(
        f"Created reminder: ID {db_reminder.id} for patient {reminder.patient_id} by user {user_id or 'unknown'}")
    return db_reminder


def get_reminders(db: Session, patient_id: UUID, skip: int = 0, limit: int = 100, user_id: UUID = None) -> list[
    models.Reminder]:
    """
    Retrieve all reminders for a specific patient with pagination.

    Args:
        db: Database session.
        patient_id: UUID of the patient.
        skip: Number of records to skip.
        limit: Maximum number of records to return.
        user_id: ID of the user performing the action (for logging).

    Returns:
        List of Reminder objects.
    """
    reminders = db.query(models.Reminder).filter(models.Reminder.patient_id == patient_id).offset(skip).limit(
        limit).all()
    logger.info(
        f"Retrieved {len(reminders)} reminders for patient {patient_id} with skip={skip}, limit={limit} by user {user_id or 'unknown'}")
    return reminders


def trigger_reminders(db: Session, user_id: UUID = None) -> int:
    """
    Trigger pending reminders by sending messages via WhatsApp, SMS, or call.

    Args:
        db: Database session.
        user_id: ID of the user performing the action (for logging).

    Returns:
        Number of reminders triggered.
    """
    now = datetime.utcnow()
    reminders = db.query(models.Reminder).filter(
        models.Reminder.scheduled_time <= now,
        models.Reminder.sent == False
    ).all()

    for reminder in reminders:
        message = f"Reminder for {reminder.patient_name}: {reminder.appointment_reason}"
        if reminder.medication_list:
            message += f"\nMedications: {reminder.medication_list}"
        if reminder.consultation_list:
            message += f"\nConsultations: {reminder.consultation_list}"

        success = False
        if reminder.method == "whatsapp":
            success = send_whatsapp(reminder.encrypted_phone_number, message, reminder.language)
        elif reminder.method == "sms":
            success = send_sms(reminder.encrypted_phone_number, message, reminder.language)
        elif reminder.method == "call":
            success = send_call(reminder.encrypted_phone_number, message, reminder.language)

        if success:
            reminder.sent = True
            reminder.sent_at = now
            logger.info(
                f"Triggered reminder: ID {reminder.id} for patient {reminder.patient_id} via {reminder.method} by user {user_id or 'unknown'}")
        else:
            logger.error(
                f"Failed to trigger reminder: ID {reminder.id} for patient {reminder.patient_id} by user {user_id or 'unknown'}")

    db.commit()
    logger.info(f"Triggered {len(reminders)} reminders by user {user_id or 'unknown'}")
    return len(reminders)


def delete_reminder(db: Session, reminder_id: int, user_id: UUID = None) -> bool:
    """
    Delete a reminder by ID.

    Args:
        db: Database session.
        reminder_id: ID of the reminder to delete.
        user_id: ID of the user performing the action (for logging).

    Returns:
        True if deletion was successful, False if reminder not found.
    """
    reminder = db.query(models.Reminder).filter(models.Reminder.id == reminder_id).first()
    if not reminder:
        logger.warning(f"Failed to delete reminder: ID {reminder_id} not found by user {user_id or 'unknown'}")
        return False

    db.delete(reminder)
    db.commit()
    logger.info(f"Deleted reminder: ID {reminder_id} by user {user_id or 'unknown'}")
    return True


def update_reminder(db: Session, reminder_id: int, reminder_update: schemas.ReminderCreate,
                    user_id: UUID = None) -> models.Reminder:
    """
    Update an existing reminder by ID.

    Args:
        db: Database session.
        reminder_id: ID of the reminder to update.
        reminder_update: Updated reminder data.
        user_id: ID of the user performing the action (for logging).

    Returns:
        Updated Reminder object or None if not found.

    Raises:
        ValueError: If phone_number format, method, or language is invalid.
    """
    reminder = db.query(models.Reminder).filter(models.Reminder.id == reminder_id).first()
    if not reminder:
        logger.warning(f"Failed to update reminder: ID {reminder_id} not found by user {user_id or 'unknown'}")
        return None

    if reminder_update.phone_number:
        validated_number = validate_phone_number(reminder_update.phone_number)
        if not validated_number:
            logger.error(f"Invalid phone number format: {reminder_update.phone_number} by user {user_id or 'unknown'}")
            raise ValueError(f"Invalid phone number format: {reminder_update.phone_number}")
        reminder_update.phone_number = validated_number

    if reminder_update.method not in VALID_REMINDER_METHODS:
        logger.error(f"Invalid reminder method: {reminder_update.method} by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid reminder method: {reminder_update.method}. Must be one of {VALID_REMINDER_METHODS}")

    if reminder_update.language not in VALID_LANGUAGES:
        logger.error(f"Invalid language: {reminder_update.language} by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid language: {reminder_update.language}. Must be one of {VALID_LANGUAGES}")

    reminder.patient_id = reminder_update.patient_id
    reminder.patient_name = reminder_update.patient_name
    reminder.phone_number = reminder_update.phone_number
    reminder.appointment_reason = reminder_update.appointment_reason
    reminder.medication_list = reminder_update.medication_list
    reminder.consultation_list = reminder_update.consultation_list
    reminder.language = reminder_update.language
    reminder.method = reminder_update.method
    reminder.scheduled_time = reminder_update.scheduled_time

    db.commit()
    db.refresh(reminder)
    logger.info(f"Updated reminder: ID {reminder_id} for patient {reminder.patient_id} by user {user_id or 'unknown'}")
    return reminder


