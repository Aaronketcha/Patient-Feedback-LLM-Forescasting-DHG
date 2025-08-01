from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app import schemas, crud, models
from app.dependencies import get_db, get_current_user
from typing import List, Optional
from uuid import UUID
from datetime import datetime

router = APIRouter(prefix="/reminders", tags=["Reminders"])


@router.post("/create", response_model=schemas.Reminder)
async def create_reminder(
        reminder: schemas.ReminderCreate,
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Create a new reminder for a patient (admin only).

    Args:
        reminder: Reminder data including patient_id, patient_name, phone_number, etc.
        db: Database session.
        current_user: Authenticated user.

    Returns:
        Reminder schema with created reminder details.

    Raises:
        HTTPException: If user is not an admin or patient_id is invalid.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    patient = db.query(models.Patient).filter(models.Patient.patient_id == reminder.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    db_reminder = crud.create_reminder(db, reminder, user_id=current_user.patient_id)
    return schemas.Reminder(
        id=db_reminder.id,
        patient_id=db_reminder.patient_id,
        patient_name=db_reminder.patient_name,
        appointment_reason=db_reminder.appointment_reason,
        language=db_reminder.language,
        method=db_reminder.method,
        scheduled_time=db_reminder.scheduled_time,
        sent=db_reminder.sent,
        sent_at=db_reminder.sent_at
    )


@router.get("/list", response_model=List[schemas.Reminder])
async def list_reminders(
        patient_id: UUID,
        skip: int = Query(0, ge=0),
        limit: int = Query(100, ge=1, le=100),
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    List reminders for a specific patient with pagination (accessible by patient or admin).

    Args:
        patient_id: UUID of the patient to query reminders for.
        skip: Number of records to skip (for pagination).
        limit: Maximum number of records to return (for pagination).
        db: Database session.
        current_user: Authenticated user.

    Returns:
        List of Reminder schemas.

    Raises:
        HTTPException: If user is neither the patient nor an admin.
    """
    if current_user.role != "admin" and current_user.patient_id != patient_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    reminders = crud.get_reminders(db, patient_id, skip=skip, limit=limit, user_id=current_user.patient_id)
    return [
        schemas.Reminder(
            id=r.id,
            patient_id=r.patient_id,
            patient_name=r.patient_name,
            appointment_reason=r.appointment_reason,
            language=r.language,
            method=r.method,
            scheduled_time=r.scheduled_time,
            sent=r.sent,
            sent_at=r.sent_at
        ) for r in reminders
    ]


@router.post("/trigger")
async def trigger_reminders(
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Trigger pending reminders (admin only).

    Args:
        db: Database session.
        current_user: Authenticated user.

    Returns:
        Message indicating the number of reminders triggered.

    Raises:
        HTTPException: If user is not an admin.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    count = crud.trigger_reminders(db, user_id=current_user.patient_id)
    return {"message": f"{count} reminders triggered"}


@router.delete("/delete/{reminder_id}", response_model=dict)
async def delete_reminder(
        reminder_id: int,
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Delete a reminder by ID (admin only).

    Args:
        reminder_id: ID of the reminder to delete.
        db: Database session.
        current_user: Authenticated user.

    Returns:
        Message confirming deletion.

    Raises:
        HTTPException: If user is not an admin or reminder ID is invalid.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    success = crud.delete_reminder(db, reminder_id, user_id=current_user.patient_id)
    if not success:
        raise HTTPException(status_code=404, detail="Reminder not found")

    return {"message": f"Reminder {reminder_id} deleted"}


@router.put("/update/{reminder_id}", response_model=schemas.Reminder)
async def update_reminder(
        reminder_id: int,
        reminder_update: schemas.ReminderCreate,
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Update an existing reminder by ID (admin only).

    Args:
        reminder_id: ID of the reminder to update.
        reminder_update: Updated reminder data.
        db: Database session.
        current_user: Authenticated user.

    Returns:
        Updated Reminder schema.

    Raises:
        HTTPException: If user is not an admin or patient_id is invalid.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    patient = db.query(models.Patient).filter(models.Patient.patient_id == reminder_update.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    db_reminder = crud.update_reminder(db, reminder_id, reminder_update, user_id=current_user.patient_id)
    if db_reminder is None:
        raise HTTPException(status_code=404, detail="Reminder not found")

    return schemas.Reminder(
        id=db_reminder.id,
        patient_id=db_reminder.patient_id,
        patient_name=db_reminder.patient_name,
        appointment_reason=db_reminder.appointment_reason,
        language=db_reminder.language,
        method=db_reminder.method,
        scheduled_time=db_reminder.scheduled_time,
        sent=db_reminder.sent,
        sent_at=db_reminder.sent_at
    )


@router.get("/search", response_model=List[schemas.Reminder])
async def search_reminders(
        patient_id: UUID,
        method: Optional[str] = Query(None, description="Filter by reminder method (whatsapp, sms, call)"),
        language: Optional[str] = Query(None, description="Filter by language (e.g., english, french)"),
        sent: Optional[bool] = Query(None, description="Filter by sent status (true/false)"),
        scheduled_after: Optional[datetime] = Query(None, description="Filter by scheduled time after this datetime"),
        appointment_reason: Optional[str] = Query(None, description="Filter by appointment reason (partial match)"),
        skip: int = Query(0, ge=0, description="Number of records to skip"),
        limit: int = Query(100, ge=1, le=100, description="Maximum number of records to return"),
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Search reminders for a specific patient with optional filters and pagination.

    Args:
        patient_id: UUID of the patient to query reminders for.
        method: Optional filter for reminder method (whatsapp, sms, call).
        language: Optional filter for reminder language.
        sent: Optional filter for sent status.
        scheduled_after: Optional filter for reminders scheduled after this time.
        appointment_reason: Optional filter for appointment reason (partial match).
        skip: Number of records to skip (for pagination).
        limit: Maximum number of records to return (for pagination).
        db: Database session.
        current_user: Authenticated user.

    Returns:
        List of Reminder schemas matching the filters.

    Raises:
        HTTPException: If user is neither the patient nor an admin or invalid method.
    """
    if current_user.role != "admin" and current_user.patient_id != patient_id:
        raise HTTPException(status_code=403, detail="Not authorized")

    from sqlalchemy import or_
    query = db.query(models.Reminder).filter(models.Reminder.patient_id == patient_id)

    if method:
        if method not in crud.VALID_REMINDER_METHODS:
            raise HTTPException(status_code=400,
                                detail=f"Invalid method: {method}. Must be one of {crud.VALID_REMINDER_METHODS}")
        query = query.filter(models.Reminder.method == method)

    if language:
        if language not in crud.VALID_LANGUAGES:
            raise HTTPException(status_code=400,
                                detail=f"Invalid language: {language}. Must be one of {crud.VALID_LANGUAGES}")
        query = query.filter(models.Reminder.language == language)

    if sent is not None:
        query = query.filter(models.Reminder.sent == sent)

    if scheduled_after:
        query = query.filter(models.Reminder.scheduled_time > scheduled_after)

    if appointment_reason:
        query = query.filter(or_(models.Reminder.appointment_reason.ilike(f"%{appointment_reason}%")))

    reminders = query.offset(skip).limit(limit).all()
    return [
        schemas.Reminder(
            id=r.id,
            patient_id=r.patient_id,
            patient_name=r.patient_name,
            appointment_reason=r.appointment_reason,
            language=r.language,
            method=r.method,
            scheduled_time=r.scheduled_time,
            sent=r.sent,
            sent_at=r.sent_at
        ) for r in reminders
    ]