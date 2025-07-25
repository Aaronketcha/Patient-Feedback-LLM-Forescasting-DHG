from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from cryptography.fernet import Fernet
import os
import uuid

Base = declarative_base()

# Load or generate encryption key securely (store in environment variable for production)
ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY", Fernet.generate_key().decode())
cipher = Fernet(ENCRYPTION_KEY.encode())


class Patient(Base):
    __tablename__ = "patients"

    patient_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    phone_number = Column(String(20), nullable=True)  # Encrypted
    role = Column(String(20), nullable=False)  # 'admin' or 'patient'

    # Relationships
    feedbacks = relationship("Feedback", back_populates="patient")
    reminders = relationship("Reminder", back_populates="patient")

    @property
    def encrypted_phone_number(self):
        """Encrypt phone number before storing."""
        if self.phone_number:
            return cipher.encrypt(self.phone_number.encode()).decode()
        return None

    @encrypted_phone_number.setter
    def encrypted_phone_number(self, value):
        """Decrypt phone number when retrieving."""
        if value:
            self.phone_number = cipher.decrypt(value.encode()).decode()
        else:
            self.phone_number = None

    __table_args__ = (
        {"comment": "Stores patient and admin user data with encrypted phone numbers."},
    )


class Feedback(Base):
    __tablename__ = "feedback"

    id = Column(Integer, primary_key=True, index=True)
    feedback_id = Column(String(50), unique=True, index=True, nullable=False)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False)
    text = Column(Text, nullable=False)
    rating = Column(Integer, nullable=False)
    language = Column(String(20), nullable=False)
    sentiment = Column(String(20), nullable=True)
    theme = Column(String(100), nullable=True)
    urgent = Column(Boolean, default=False, nullable=False)
    department = Column(String(50), nullable=False)
    submitted_at = Column(DateTime, nullable=False)

    # Relationship
    patient = relationship("Patient", back_populates="feedbacks")

    __table_args__ = (
        {"comment": "Stores patient feedback with sentiment analysis and urgency flags."},
    )


class Reminder(Base):
    __tablename__ = "reminders"

    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(UUID(as_uuid=True), ForeignKey("patients.patient_id"), nullable=False)
    patient_name = Column(String(100), nullable=False)
    phone_number = Column(String(20), nullable=True)  # Encrypted
    appointment_reason = Column(String(255), nullable=False)
    medication_list = Column(Text, nullable=True)
    consultation_list = Column(Text, nullable=True)
    language = Column(String(20), nullable=False)
    method = Column(String(20), nullable=False)  # 'whatsapp', 'sms', or 'call'
    scheduled_time = Column(DateTime, nullable=False)
    sent = Column(Boolean, default=False, nullable=False)
    sent_at = Column(DateTime, nullable=True)

    # Relationship
    patient = relationship("Patient", back_populates="reminders")

    @property
    def encrypted_phone_number(self):
        """Encrypt phone number before storing."""
        if self.phone_number:
            return cipher.encrypt(self.phone_number.encode()).decode()
        return None

    @encrypted_phone_number.setter
    def encrypted_phone_number(self, value):
        """Decrypt phone number when retrieving."""
        if value:
            self.phone_number = cipher.decrypt(value.encode()).decode()
        else:
            self.phone_number = None

    __table_args__ = (
        {"comment": "Stores reminders for patients with encrypted phone numbers."},
    )