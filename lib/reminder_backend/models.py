from pydantic import BaseModel
from typing import List
from datetime import datetime

# medication_backend/models.py

class Medication(BaseModel):
    """
    Modèle Pydantic pour représenter un médicament.
    """
    id: str
    medicationName: str
    startDate: datetime
    endDate: datetime
    duration: int
    dosage: str
    times: List[str] # Format "HH:MM"
    image: str
    frequency: str # "daily", "every 2 days", etc.
    phoneNumber: str # Numéro de téléphone du client
