from typing import List
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta, time
import logging
import pytz
from twilio.rest import Client

from models import Medication
from config import TIMEZONE, DEFAULT_WHATSAPP_NUMBER, TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Initialiser le scheduler
scheduler = BackgroundScheduler(timezone=TIMEZONE)

# Initialiser le client Twilio
client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

def send_whatsapp_message(phone_number: str, message: str):
    """
    Envoie un message WhatsApp via Twilio API.
    """
    try:
        to_number = phone_number if phone_number.startswith("whatsapp:") else f"whatsapp:{phone_number}"
        from_number = TWILIO_FROM if TWILIO_FROM.startswith("whatsapp:") else f"whatsapp:{TWILIO_FROM}"

        logging.info(f"--- Envoi WhatsApp ---\nÀ: {to_number}\nMessage: {message}\n----------------------")
        msg = client.messages.create(
            body=message,
            from_=from_number,
            to=to_number
        )
        logging.info(f"[TWILIO] Message envoyé avec succès (SID: {msg.sid})")
    except Exception as e:
        logging.error(f"[TWILIO] Échec d'envoi:\n{e}")

def load_medications_into_scheduler(medications: List[Medication]):
    """
    Planifie les rappels pour chaque médicament.
    """
    logging.info("Scheduling medication reminders...")
    scheduler.remove_all_jobs()

    tz = pytz.timezone(TIMEZONE)
    now_in_tz = datetime.now(tz)
    today_in_tz = now_in_tz.date()

    for med in medications:
        try:
            start_date = med.startDate.astimezone(tz).date()
            end_date = med.endDate.astimezone(tz).date()

            current_day = start_date
            day_count = 0
            frequency_days = 1

            if med.frequency.startswith('every '):
                try:
                    frequency_days = int(med.frequency.split(' ')[1])
                except ValueError:
                    pass

            medication_days = []
            while current_day <= end_date:
                if day_count % frequency_days == 0:
                    medication_days.append(current_day)
                current_day += timedelta(days=1)
                day_count += 1

            for med_day in medication_days:
                if med_day >= today_in_tz:
                    for time_str in med.times:
                        hour, minute = map(int, time_str.split(':'))
                        reminder_datetime = tz.localize(datetime.combine(med_day, time(hour, minute)))

                        if reminder_datetime > now_in_tz:
                            scheduler.add_job(
                                send_whatsapp_message,
                                'date',
                                run_date=reminder_datetime,
                                args=[
                                    med.phoneNumber or DEFAULT_WHATSAPP_NUMBER,
                                    f"Rappel: C'est l'heure de prendre votre {med.medicationName} ({med.dosage})."
                                ],
                                id=f"med_{med.id}_at_{med_day.strftime('%Y%m%d')}_{time_str.replace(':', '')}",
                                replace_existing=True
                            )
                            logging.info(f"✅ Rappel prévu pour {med.medicationName} le {med_day} à {time_str}")

                            early_reminder = reminder_datetime - timedelta(minutes=30)
                            if early_reminder > now_in_tz:
                                scheduler.add_job(
                                    send_whatsapp_message,
                                    'date',
                                    run_date=early_reminder,
                                    args=[
                                        med.phoneNumber or DEFAULT_WHATSAPP_NUMBER,
                                        f"⏳ Rappel dans 30 minutes : Préparez-vous à prendre votre {med.medicationName} ({med.dosage})."
                                    ],
                                    id=f"med_{med.id}_early_{med_day.strftime('%Y%m%d')}_{time_str.replace(':', '')}",
                                    replace_existing=True
                                )
                                logging.info(f"🕧 Rappel anticipé prévu pour {med.medicationName} à {early_reminder.strftime('%H:%M')}")
        except Exception as e:
            logging.error(f"[SCHEDULER] Erreur lors du traitement de {med.id}: {e}")