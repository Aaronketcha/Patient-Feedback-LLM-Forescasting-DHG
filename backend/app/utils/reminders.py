from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
from twilio.twiml.voice_response import VoiceResponse
import os
import logging
from typing import Optional
from uuid import UUID

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.FileHandler("app.log")
handler.setFormatter(logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s"))
logger.addHandler(handler)

# Valid languages
VALID_LANGUAGES = {"english", "french"}

# Twilio configuration (loaded from environment variables)
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID", "your-account-sid")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN", "your-auth-token")
TWILIO_WHATSAPP_NUMBER = os.getenv("TWILIO_WHATSAPP_NUMBER", "whatsapp:+14155238886")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER", "+14155238886")

client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)


def validate_phone_number(phone_number: str) -> Optional[str]:
    """
    Validate and normalize phone number format (e.g., +237xxxxxxxxxx).

    Args:
        phone_number: Phone number to validate.

    Returns:
        Normalized phone number or None if invalid.
    """
    if not phone_number:
        logger.error("Phone number is empty")
        return None

    # Remove spaces, dashes, and other non-digits except +
    cleaned = ''.join(c for c in phone_number if c.isdigit() or c == '+')

    # Basic validation: starts with + followed by 10-14 digits
    if len(cleaned) < 11 or len(cleaned) > 15 or not cleaned.startswith('+'):
        logger.error(f"Invalid phone number format: {phone_number}")
        return None

    return cleaned


def send_whatsapp(phone_number: str, message: str, language: str, user_id: Optional[UUID] = None) -> bool:
    """
    Send a WhatsApp message to the specified phone number.

    Args:
        phone_number: Decrypted phone number (e.g., +237xxxxxxxxxx).
        message: Message content.
        language: Language of the message (must be in VALID_LANGUAGES).
        user_id: ID of the user performing the action (for logging).

    Returns:
        True if message was sent successfully, False otherwise.

    Raises:
        ValueError: If language is invalid.
    """
    if language not in VALID_LANGUAGES:
        logger.error(f"Invalid language: {language} for WhatsApp message by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid language: {language}. Must be one of {VALID_LANGUAGES}")

    try:
        validated_number = validate_phone_number(phone_number)
        if not validated_number:
            logger.error(f"Invalid phone number: {phone_number} for WhatsApp message by user {user_id or 'unknown'}")
            return False

        to_number = f"whatsapp:{validated_number}"
        client.messages.create(
            from_=TWILIO_WHATSAPP_NUMBER,
            body=message,
            to=to_number
        )
        logger.info(f"Sent WhatsApp to {validated_number} in {language} by user {user_id or 'unknown'}: {message}")
        return True
    except TwilioRestException as e:
        logger.error(f"Failed to send WhatsApp to {phone_number} by user {user_id or 'unknown'}: {e}")
        return False


def send_sms(phone_number: str, message: str, language: str, user_id: Optional[UUID] = None) -> bool:
    """
    Send an SMS to the specified phone number.

    Args:
        phone_number: Decrypted phone number.
        message: Message content.
        language: Language of the message (must be in VALID_LANGUAGES).
        user_id: ID of the user performing the action (for logging).

    Returns:
        True if message was sent successfully, False otherwise.

    Raises:
        ValueError: If language is invalid.
    """
    if language not in VALID_LANGUAGES:
        logger.error(f"Invalid language: {language} for SMS by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid language: {language}. Must be one of {VALID_LANGUAGES}")

    try:
        validated_number = validate_phone_number(phone_number)
        if not validated_number:
            logger.error(f"Invalid phone number: {phone_number} for SMS by user {user_id or 'unknown'}")
            return False

        client.messages.create(
            from_=TWILIO_PHONE_NUMBER,
            body=message,
            to=validated_number
        )
        logger.info(f"Sent SMS to {validated_number} in {language} by user {user_id or 'unknown'}: {message}")
        return True
    except TwilioRestException as e:
        logger.error(f"Failed to send SMS to {phone_number} by user {user_id or 'unknown'}: {e}")
        return False


def send_call(phone_number: str, message: str, language: str, user_id: Optional[UUID] = None) -> bool:
    """
    Send a voice call to the specified phone number using Twilio Voice API.

    Args:
        phone_number: Decrypted phone number.
        message: Message content to be voiced.
        language: Language of the message (must be in VALID_LANGUAGES).
        user_id: ID of the user performing the action (for logging).

    Returns:
        True if call was successfully initiated, False otherwise.

    Raises:
        ValueError: If language is invalid.
    """
    if language not in VALID_LANGUAGES:
        logger.error(f"Invalid language: {language} for voice call by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid language: {language}. Must be one of {VALID_LANGUAGES}")

    try:
        validated_number = validate_phone_number(phone_number)
        if not validated_number:
            logger.error(f"Invalid phone number: {phone_number} for voice call by user {user_id or 'unknown'}")
            return False

        # Map language to Twilio Voice language code
        twilio_language = "en-US" if language == "english" else "fr-FR"

        # Generate TwiML for voice call
        twiml = VoiceResponse()
        twiml.say(message, language=twilio_language)

        # Simulate call in development mode (if environment variable is set)
        if os.getenv("ENV", "development") == "development":
            logger.info(
                f"Simulated voice call to {validated_number} in {language} by user {user_id or 'unknown'}: {message}")
            return True

        # Actual Twilio Voice API call
        call = client.calls.create(
            twiml=str(twiml),
            from_=TWILIO_PHONE_NUMBER,
            to=validated_number
        )
        logger.info(
            f"Initiated voice call to {validated_number} in {language} with SID {call.sid} by user {user_id or 'unknown'}")
        return True

    except TwilioRestException as e:
        logger.error(f"Failed to initiate voice call to {phone_number} by user {user_id or 'unknown'}: {e}")
        return False


