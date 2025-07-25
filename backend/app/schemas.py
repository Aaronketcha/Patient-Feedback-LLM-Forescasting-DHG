from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict
from uuid import UUID

class Token(BaseModel):
    access_token: str
    token_type: str

class PatientLogin(BaseModel):
    name: str
    password: str

class Patient(BaseModel):
    patient_id: UUID
    name: str
    role: str

class FeedbackSubmit(BaseModel):
    feedback_id: str
    text: str
    rating: int
    language: str
    department: str
    patient_id: UUID

class FeedbackAnalysis(BaseModel):
    feedback_id: str
    sentiment: str
    theme: str
    urgent: bool
    patient_id: UUID
    department: str

class FeedbackMetrics(BaseModel):
    sentiment_distribution: Dict[str, int]
    theme_distribution: Dict[str, int]
    urgent_by_department: Dict[str, int]
    most_urgent_dept: str
    total_rows: int

class ReminderCreate(BaseModel):
    patient_id: UUID
    patient_name: str
    phone_number: str
    appointment_reason: str
    medication_list: Optional[str] = None
    consultation_list: Optional[str] = None
    language: str
    method: str  # 'whatsapp', 'sms', or 'call'
    scheduled_time: datetime

class Reminder(BaseModel):
    id: int
    patient_id: UUID
    patient_name: str
    appointment_reason: str
    language: str
    method: str
    scheduled_time: datetime
    sent: bool
    sent_at: Optional[datetime]

class DashboardMetrics(BaseModel):
    satisfaction_rate: float
    reminder_success_rate: float
    top_themes: List[str]
    urgent_issues_count: int