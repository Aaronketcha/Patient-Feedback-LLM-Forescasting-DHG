from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from app import models, schemas
from app.database import SessionLocal
import os

# Load JWT secret key from environment variable for security
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key")  # Store securely in production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")


def get_db():
    """
    Provide a database session for dependency injection.
    Ensures the session is properly closed after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create a JWT access token with the provided data and expiration time.

    Args:
        data: Dictionary containing token payload (e.g., name, role).
        expires_delta: Optional custom expiration time.

    Returns:
        Encoded JWT token as a string.
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + (
        expires_delta if expires_delta else timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> schemas.Patient:
    """
    Validate JWT token and return the authenticated patient.

    Args:
        token: JWT token from Authorization header.
        db: Database session for querying the patient.

    Returns:
        Patient schema with patient_id, name, and role.

    Raises:
        HTTPException: If credentials are invalid or the patient is not found.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        name: str = payload.get("sub")
        role: str = payload.get("role")
        if name is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    patient = db.query(models.Patient).filter(models.Patient.name == name).first()
    if patient is None or patient.role != role:
        raise credentials_exception

    return schemas.Patient(
        patient_id=patient.patient_id,
        name=patient.name,
        role=patient.role
    )