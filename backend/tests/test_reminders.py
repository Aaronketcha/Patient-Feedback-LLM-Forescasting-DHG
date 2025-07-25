import pytest
import pytest_asyncio
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.database import Base, get_db
from app.crud import create_patient
from app.dependencies import get_current_user
from app import schemas
from uuid import uuid4
from datetime import datetime, timedelta
import os

# Test database configuration
TEST_DATABASE_URL = "postgresql://test_user:test_password@localhost:5432/test_feedback_db"
engine = create_engine(TEST_DATABASE_URL)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


# Override dependencies for testing
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

# Mock user for authentication
mock_admin = schemas.Patient(
    patient_id=uuid4(),
    name="AdminUser",
    role="admin",
    hashed_password="mock_hashed_password",
    phone_number="+237123456789"
)


def override_get_current_user():
    return mock_admin


app.dependency_overrides[get_current_user] = override_get_current_user

# Test client
client = TestClient(app)


@pytest_asyncio.fixture(autouse=True)
async def setup_database():
    # Create tables before tests
    Base.metadata.create_all(bind=engine)
    yield
    # Drop tables after tests
    Base.metadata.drop_all(bind=engine)


@pytest_asyncio.fixture
async def test_patient():
    db = TestingSessionLocal()
    patient = create_patient(
        db,
        name="JaneDoe",
        password="secure123",
        role="patient",
        phone_number="+237987654321",
        user_id=mock_admin.patient_id
    )
    db.close()
    return patient


@pytest.mark.asyncio
async def test_create_reminder_success(test_patient):
    reminder_data = {
        "patient_id": str(test_patient.patient_id),
        "patient_name": "Jane Doe",
        "phone_number": "+237987654321",
        "appointment_reason": "Follow-up visit",
        "medication_list": "Aspirin",
        "consultation_list": "Cardiology",
        "language": "english",
        "method": "whatsapp",
        "scheduled_time": (datetime.utcnow() + timedelta(hours=1)).isoformat()
    }
    response = client.post("/reminders/create", json=reminder_data)
    assert response.status_code == 200
    data = response.json()
    assert data["patient_id"] == str(test_patient.patient_id)
    assert data["patient_name"] == "Jane Doe"
    assert data["language"] == "english"
    assert data["method"] == "whatsapp"


@pytest.mark.asyncio
async def test_create_reminder_invalid_language(test_patient):
    reminder_data = {
        "patient_id": str(test_patient.patient_id),
        "patient_name": "Jane Doe",
        "phone_number": "+237987654321",
        "appointment_reason": "Follow-up visit",
        "medication_list": "Aspirin",
        "consultation_list": "Cardiology",
        "language": "spanish",  # Invalid language
        "method": "whatsapp",
        "scheduled_time": (datetime.utcnow() + timedelta(hours=1)).isoformat()
    }
    response = client.post("/reminders/create", json=reminder_data)
    assert response.status_code == 422
    assert "Invalid language" in response.json()["detail"]


@pytest.mark.asyncio
async def test_list_reminders(test_patient):
    # Create a reminder first
    reminder_data = {
        "patient_id": str(test_patient.patient_id),
        "patient_name": "Jane Doe",
        "phone_number": "+237987654321",
        "appointment_reason": "Follow-up visit",
        "medication_list": "Aspirin",
        "consultation_list": "Cardiology",
        "language": "english",
        "method": "whatsapp",
        "scheduled_time": (datetime.utcnow() + timedelta(hours=1)).isoformat()
    }
    client.post("/reminders/create", json=reminder_data)

    response = client.get(f"/reminders/list?patient_id={test_patient.patient_id}&skip=0&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    assert data[0]["patient_id"] == str(test_patient.patient_id)


@pytest.mark.asyncio
async def test_search_reminders(test_patient):
    # Create a reminder
    reminder_data = {
        "patient_id": str(test_patient.patient_id),
        "patient_name": "Jane Doe",
        "phone_number": "+237987654321",
        "appointment_reason": "Follow-up visit",
        "medication_list": "Aspirin",
        "consultation_list": "Cardiology",
        "language": "english",
        "method": "whatsapp",
        "scheduled_time": (datetime.utcnow() + timedelta(hours=1)).isoformat()
    }
    client.post("/reminders/create", json=reminder_data)

    response = client.get(
        f"/reminders/search?patient_id={test_patient.patient_id}&method=whatsapp&scheduled_after={(datetime.utcnow() - timedelta(hours=1)).isoformat()}Z")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    assert data[0]["method"] == "whatsapp"


@pytest.mark.asyncio
async def test_delete_reminder(test_patient):
    # Create a reminder
    reminder_data = {
        "patient_id": str(test_patient.patient_id),
        "patient_name": "Jane Doe",
        "phone_number": "+237987654321",
        "appointment_reason": "Follow-up visit",
        "medication_list": "Aspirin",
        "consultation_list": "Cardiology",
        "language": "english",
        "method": "whatsapp",
        "scheduled_time": (datetime.utcnow() + timedelta(hours=1)).isoformat()
    }
    response = client.post("/reminders/create", json=reminder_data)
    reminder_id = response.json()["id"]

    response = client.delete(f"/reminders/delete/{reminder_id}")
    assert response.status_code == 200
    assert response.json() == {"message": f"Reminder {reminder_id} deleted"}


@pytest.mark.asyncio
async def test_update_reminder(test_patient):
    # Create a reminder
    reminder_data = {
        "patient_id": str(test_patient.patient_id),
        "patient_name": "Jane Doe",
        "phone_number": "+237987654321",
        "appointment_reason": "Follow-up visit",
        "medication_list": "Aspirin",
        "consultation_list": "Cardiology",
        "language": "english",
        "method": "whatsapp",
        "scheduled_time": (datetime.utcnow() + timedelta(hours=1)).isoformat()
    }
    response = client.post("/reminders/create", json=reminder_data)
    reminder_id = response.json()["id"]

    update_data = {
        "patient_id": str(test_patient.patient_id),
        "patient_name": "Jane Doe",
        "phone_number": "+237987654321",
        "appointment_reason": "Updated visit",
        "medication_list": "Ibuprofen",
        "consultation_list": "Neurology",
        "language": "french",
        "method": "sms",
        "scheduled_time": (datetime.utcnow() + timedelta(hours=2)).isoformat()
    }
    response = client.put(f"/reminders/update/{reminder_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["appointment_reason"] == "Updated visit"
    assert data["language"] == "french"
    assert data["method"] == "sms"


```