from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app import schemas, crud
from app.dependencies import get_db, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/token", response_model=schemas.Token)
async def login_for_access_token(
        form_data: OAuth2PasswordRequestForm = Depends(),
        db: Session = Depends(get_db)
):
    """
    Authenticate a patient and return a JWT access token.

    Args:
        form_data: OAuth2 password request form with name and password.
        db: Database session for querying the patient.

    Returns:
        Token schema with access token and token type.

    Raises:
        HTTPException: If name or password is incorrect.
    """
    patient = crud.get_patient_by_name(db, form_data.username)
    if not patient or not crud.verify_password(form_data.password, patient.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect name or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": patient.name, "role": patient.role})
    return {"access_token": access_token, "token_type": "bearer"}