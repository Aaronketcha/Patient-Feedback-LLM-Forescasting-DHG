from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import schemas, crud, models
from app.dependencies import get_db, get_current_user
import pandas as pd

router = APIRouter(prefix="/feedback", tags=["Feedback"])


@router.post("/submit", response_model=schemas.FeedbackAnalysis)
async def submit_feedback(
        feedback: schemas.FeedbackSubmit,
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Submit a new feedback entry and analyze it for sentiment, theme, and urgency.

    Args:
        feedback: Feedback data including patient_id, text, rating, language, and department.
        db: Database session.
        current_user: Authenticated patient.

    Returns:
        FeedbackAnalysis schema with analysis results.

    Raises:
        HTTPException: If user is not a patient or patient_id does not match.
    """
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Not authorized")
    if feedback.patient_id != current_user.patient_id:
        raise HTTPException(status_code=403, detail="Patient ID mismatch")

    db_feedback = crud.submit_feedback(db, feedback)
    analyzed_feedback = crud.analyze_feedback(db, db_feedback)

    return schemas.FeedbackAnalysis(
        feedback_id=analyzed_feedback.feedback_id,
        sentiment=analyzed_feedback.sentiment,
        theme=analyzed_feedback.theme,
        urgent=analyzed_feedback.urgent,
        patient_id=analyzed_feedback.patient_id,
        department=analyzed_feedback.department
    )


@router.get("/metrics", response_model=schemas.FeedbackMetrics)
async def get_feedback_metrics(
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Retrieve aggregated feedback metrics for admin users.

    Args:
        db: Database session.
        current_user: Authenticated user.

    Returns:
        FeedbackMetrics schema with sentiment, theme, and urgency distributions.

    Raises:
        HTTPException: If user is not an admin or no feedback is available.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    metrics = crud.get_feedback_metrics(db)
    if not metrics.total_rows:
        raise HTTPException(status_code=404, detail="No feedback available")

    return metrics


@router.get("/dashboard/metrics", response_model=schemas.DashboardMetrics)
async def get_dashboard_metrics(
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Retrieve dashboard metrics for admin users, including satisfaction and reminder success rates.

    Args:
        db: Database session.
        current_user: Authenticated user.

    Returns:
        DashboardMetrics schema with satisfaction rate, reminder success rate, top themes, and urgent issues count.

    Raises:
        HTTPException: If user is not an admin.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    feedbacks = db.query(models.Feedback).all()
    reminders = db.query(models.Reminder).all()

    if not feedbacks:
        return schemas.DashboardMetrics(
            satisfaction_rate=0.0,
            reminder_success_rate=0.0,
            top_themes=[],
            urgent_issues_count=0
        )

    positive_count = sum(1 for fb in feedbacks if fb.sentiment == "Positive")
    satisfaction_rate = (positive_count / len(feedbacks)) * 100

    theme_counts = {}
    for fb in feedbacks:
        if fb.theme:
            theme_counts[fb.theme] = theme_counts.get(fb.theme, 0) + 1
    top_themes = sorted(theme_counts, key=theme_counts.get, reverse=True)[:3]

    urgent_count = sum(1 for fb in feedbacks if fb.urgent)
    reminder_success = sum(1 for r in reminders if r.sent) / len(reminders) if reminders else 0.0

    return schemas.DashboardMetrics(
        satisfaction_rate=satisfaction_rate,
        reminder_success_rate=reminder_success * 100,
        top_themes=top_themes,
        urgent_issues_count=urgent_count
    )


@router.get("/dashboard/export")
async def export_dashboard_data(
        db: Session = Depends(get_db),
        current_user: schemas.Patient = Depends(get_current_user)
):
    """
    Export feedback data as CSV for admin users.

    Args:
        db: Database session.
        current_user: Authenticated user.

    Returns:
        Dictionary with CSV data as a string.

    Raises:
        HTTPException: If user is not an admin.
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")

    feedbacks = db.query(models.Feedback).all()

    df = pd.DataFrame([
        {
            "feedback_id": fb.feedback_id,
            "patient_id": fb.patient_id,
            "text": fb.text,
            "rating": fb.rating,
            "sentiment": fb.sentiment,
            "theme": fb.theme,
            "urgent": fb.urgent,
            "department": fb.department,
            "submitted_at": fb.submitted_at
        } for fb in feedbacks
    ])
    csv_data = df.to_csv(index=False)

    return {"csv_data": csv_data}