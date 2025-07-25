import json
import os
from typing import List
from datetime import datetime, timedelta
import logging

from models import Medication
from config import MEDICATIONS_FILE_PATH

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def load_medications_data() -> List[Medication]:
    """
    Charge les données des médicaments depuis le fichier JSON spécifié.
    """
    logging.info(f"Attempting to load medications from: {MEDICATIONS_FILE_PATH}")
    if not os.path.exists(MEDICATIONS_FILE_PATH):
        logging.error(f"Medications file NOT FOUND at: {MEDICATIONS_FILE_PATH}")
        return []
    try:
        with open(MEDICATIONS_FILE_PATH, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
            loaded_medications = []
            for item in raw_data:
                try:
                    start_date_str = item.get('startDate')
                    if start_date_str:
                        try:
                            item['startDate'] = datetime.fromisoformat(start_date_str)
                        except ValueError as ve:
                            logging.error(f"ValueError: Could not parse startDate '{start_date_str}' for item {item.get('id')}: {ve}")
                            continue
                        except TypeError as te:
                            logging.error(f"TypeError: startDate '{start_date_str}' is not a string for item {item.get('id')}: {te}")
                            continue
                    else:
                        logging.error(f"Missing 'startDate' for item {item.get('id')}")
                        continue

                    item['endDate'] = item['startDate'] + timedelta(days=item['duration'] - 1)
                    loaded_medications.append(Medication(**item))
                except Exception as e:
                    logging.error(f"Error processing medication item {item.get('id')}: {e}")
            logging.info(f"Successfully loaded {len(loaded_medications)} medications.")
            return loaded_medications
    except json.JSONDecodeError as e:
        logging.error(f"Error decoding JSON from {MEDICATIONS_FILE_PATH}: {e}")
        return []
    except Exception as e:
        logging.error(f"An unexpected error occurred while loading medications data: {e}")
        return []
def get_all_medications() -> List[Medication]:
    """
    Récupère tous les médicaments chargés.
    Dans une application plus complexe, cela pourrait interagir avec une base de données.
    """
    return load_medications_data()