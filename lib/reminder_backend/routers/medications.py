from fastapi import APIRouter, Request
from typing import List

from ..models import Medication
from ..crud import get_all_medications

# medication_backend/routers/medications.py

router = APIRouter(
    prefix="/medications",
    tags=["Medications"],
)

@router.get("/", response_model=List[Medication])
async def read_medications(request: Request):
    """
    Retourne la liste de tous les médicaments.
    Les médicaments sont chargés au démarrage de l'application et stockés dans app.state.
    """
    return request.app.state.medications
