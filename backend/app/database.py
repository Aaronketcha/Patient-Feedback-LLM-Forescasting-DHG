from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Configure for Google Cloud SQL or local PostgreSQL
DATABASE_URL = "postgresql://postgres:Pinnocio@2025@localhost:5432/feedback_db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()