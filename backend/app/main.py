from fastapi import FastAPI
from fastapi.middleware.gzip import GZipMiddleware
from app.routers import auth, feedback, reminders
from app.database import engine
from app.models import Base
from app.celery_app import celery_app
import logging
import redis

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    filename="app.log",
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Patient Feedback System", version="1.1.0")
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Initialize Redis client
redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)

# Create database tables
Base.metadata.create_all(bind=engine)

# Include routers
app.include_router(auth.router)
app.include_router(feedback.router)
app.include_router(reminders.router)

@app.on_event("startup")
async def startup_event():
    """
    Startup event to initialize the application and log startup.
    """
    logger.info("Application started successfully")
