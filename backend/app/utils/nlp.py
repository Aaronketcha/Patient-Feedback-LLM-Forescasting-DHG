import pandas as pd
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from bertopic import BERTopic
from sklearn.feature_extraction.text import CountVectorizer
from langdetect import detect, LangdetectException
import re
import logging
from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from app.models import Feedback
from app.schemas import FeedbackAnalysis
from uuid import UUID
from functools import lru_cache
import os

# Configure logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.FileHandler("app.log")
handler.setFormatter(logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s"))
logger.addHandler(handler)

# Valid languages
VALID_LANGUAGES = {"english", "french", "bassa", "ewondo"}

# Dataset paths
DATASET_PATHS = {
    "eng_douala": "datasets/eng_douala.csv",
    "eng_bassa": "datasets/eng_bassa.csv"
}

# Device configuration
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


@lru_cache(maxsize=1)
def load_nlp_models(model_name: str = "nlptown/bert-base-multilingual-uncased-sentiment"):
    """
    Load and cache NLP models (tokenizer and sentiment model).

    Args:
        model_name: Name of the Hugging Face model.

    Returns:
        Tuple of (tokenizer, model).
    """
    logger.info(f"Loading NLP models: {model_name}")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_name).to(device)
    model.eval()
    return tokenizer, model


def load_multilingual_dataset(dataset_name: str, user_id: Optional[UUID] = None) -> pd.DataFrame:
    """
    Load and preprocess the multilingual dataset with local languages and translations.

    Args:
        dataset_name: Name of the dataset ('eng_douala' or 'eng_bassa').
        user_id: ID of the user performing the action (for logging).

    Returns:
        Preprocessed pandas DataFrame.

    Raises:
        ValueError: If dataset_name is invalid or required columns are missing.
        FileNotFoundError: If dataset file is not found.
    """
    if dataset_name not in DATASET_PATHS:
        logger.error(f"Invalid dataset name: {dataset_name} by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid dataset name: {dataset_name}. Must be one of {list(DATASET_PATHS.keys())}")

    file_path = DATASET_PATHS[dataset_name]
    try:
        if not os.path.exists(file_path):
            logger.error(f"Dataset file not found: {file_path} by user {user_id or 'unknown'}")
            raise FileNotFoundError(f"Dataset file not found: {file_path}")

        df = pd.read_csv(file_path)
        required_columns = ['text', 'translation', 'department']
        if not all(col in df.columns for col in required_columns):
            logger.error(f"Missing required columns in {file_path}: {required_columns} by user {user_id or 'unknown'}")
            raise ValueError(f"Dataset must contain 'text', 'translation', and 'department' columns.")

        # Clean text: remove extra spaces, special characters, handle missing values
        df['text'] = df['text'].fillna('').apply(lambda x: re.sub(r'\s+', ' ', str(x).strip()))
        df['translation'] = df['translation'].fillna('').apply(lambda x: re.sub(r'\s+', ' ', str(x).strip()))
        df['department'] = df['department'].fillna('General')

        logger.info(
            f"Loaded and preprocessed dataset {dataset_name} with {len(df)} rows by user {user_id or 'unknown'}")
        return df
    except Exception as e:
        logger.error(f"Error loading dataset {dataset_name}: {str(e)} by user {user_id or 'unknown'}")
        raise Exception(f"Error loading dataset: {str(e)}")


def detect_language(text: str, user_id: Optional[UUID] = None) -> str:
    """
    Detect the language of a given text.

    Args:
        text: Text to analyze.
        user_id: ID of the user performing the action (for logging).

    Returns:
        Detected language ('english', 'french', 'bassa', 'ewondo') or 'unknown'.
    """
    try:
        if not text.strip():
            logger.warning(f"Empty text provided for language detection by user {user_id or 'unknown'}")
            return 'unknown'

        lang = detect(text)
        if lang == 'fr':
            lang = 'french'
        elif lang == 'en':
            lang = 'english'
        elif any(keyword in text.lower() for keyword in ['bassa', 'basaa']):
            lang = 'bassa'
        elif any(keyword in text.lower() for keyword in ['ewondo']):
            lang = 'ewondo'
        else:
            lang = 'unknown'

        if lang not in VALID_LANGUAGES:
            logger.warning(
                f"Detected language {lang} not in valid languages {VALID_LANGUAGES} by user {user_id or 'unknown'}")
            return 'unknown'

        logger.info(f"Detected language: {lang} for text: {text[:50]}... by user {user_id or 'unknown'}")
        return lang
    except LangdetectException as e:
        logger.error(f"Language detection failed for text: {text[:50]}... by user {user_id or 'unknown'}: {str(e)}")
        return 'unknown'


def analyze_sentiment(texts: List[str], batch_size: int = 8, lang: str = 'english', user_id: Optional[UUID] = None) -> \
List[str]:
    """
    Analyze sentiment for a list of texts using a multilingual model.

    Args:
        texts: List of texts to analyze.
        batch_size: Number of texts to process in one batch.
        lang: Language for stop words ('english' or 'french').
        user_id: ID of the user performing the action (for logging).

    Returns:
        List of sentiments ('Positive', 'Negative', 'Neutral').

    Raises:
        ValueError: If lang is not in VALID_LANGUAGES.
    """
    if lang not in VALID_LANGUAGES:
        logger.error(f"Invalid language for sentiment analysis: {lang} by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid language: {lang}. Must be one of {VALID_LANGUAGES}")

    tokenizer, model = load_nlp_models()
    sentiments = []

    try:
        for i in range(0, len(texts), batch_size):
            batch_texts = texts[i:i + batch_size]
            inputs = tokenizer(batch_texts, padding=True, truncation=True, max_length=512, return_tensors="pt")
            inputs = {key: val.to(device) for key, val in inputs.items()}
            with torch.no_grad():
                outputs = model(**inputs)
            scores = outputs.logits.argmax(dim=-1).cpu().numpy()
            sentiments.extend(
                ['Positive' if score >= 3 else 'Negative' if score <= 1 else 'Neutral' for score in scores])

        logger.info(f"Analyzed sentiment for {len(texts)} texts in {lang} by user {user_id or 'unknown'}")
        return sentiments
    except Exception as e:
        logger.error(f"Sentiment analysis failed for {len(texts)} texts by user {user_id or 'unknown'}: {str(e)}")
        raise Exception(f"Sentiment analysis failed: {str(e)}")


def extract_themes(texts: List[str], lang: str = 'english', user_id: Optional[UUID] = None) -> List[str]:
    """
    Extract themes from texts using BERTopic.

    Args:
        texts: List of texts to analyze.
        lang: Language for stop words ('english' or 'french').
        user_id: ID of the user performing the action (for logging).

    Returns:
        List of extracted themes.

    Raises:
        ValueError: If lang is not in VALID_LANGUAGES.
    """
    if lang not in VALID_LANGUAGES:
        logger.error(f"Invalid language for theme extraction: {lang} by user {user_id or 'unknown'}")
        raise ValueError(f"Invalid language: {lang}. Must be one of {VALID_LANGUAGES}")

    try:
        vectorizer = CountVectorizer(stop_words='english' if lang == 'english' else 'french')
        topic_model = BERTopic(vectorizer_model=vectorizer, language='english' if lang == 'english' else 'french')
        topics, _ = topic_model.fit_transform(texts)
        themes = topic_model.get_document_info(texts)['Topic'].map(
            lambda x: topic_model.get_topic(x)[0][0] if x >= 0 else 'No theme'
        ).tolist()

        logger.info(f"Extracted themes for {len(texts)} texts in {lang} by user {user_id or 'unknown'}")
        return themes
    except Exception as e:
        logger.error(f"Theme extraction failed for {len(texts)} texts by user {user_id or 'unknown'}: {str(e)}")
        raise Exception(f"Theme extraction failed: {str(e)}")


def detect_urgency(texts: List[str], user_id: Optional[UUID] = None) -> List[bool]:
    """
    Detect urgency in texts based on predefined keywords.

    Args:
        texts: List of texts to analyze.
        user_id: ID of the user performing the action (for logging).

    Returns:
        List of boolean values indicating urgency.
    """
    urgent_keywords = ['long wait', 'scheduling issues', 'billing confusion', 'slow lab', 'urgent', 'emergency',
                       'attente longue', 'problèmes de planification', 'confusion de facturation', 'laboratoire lent',
                       'urgence']
    try:
        results = [any(keyword in text.lower() for keyword in urgent_keywords) for text in texts]
        logger.info(f"Detected urgency for {len(texts)} texts by user {user_id or 'unknown'}")
        return results
    except Exception as e:
        logger.error(f"Urgency detection failed for {len(texts)} texts by user {user_id or 'unknown'}: {str(e)}")
        raise Exception(f"Urgency detection failed: {str(e)}")


def process_multilingual_texts(dataset_name: str, db: Session, user_id: Optional[UUID] = None) -> List[Dict]:
    """
    Process texts from a multilingual dataset, analyze sentiment, themes, and urgency, and store results in the database.

    Args:
        dataset_name: Name of the dataset ('eng_douala' or 'eng_bassa').
        db: Database session.
        user_id: ID of the user performing the action (for logging).

    Returns:
        List of dictionaries with analysis results.

    Raises:
        ValueError: If dataset_name or data is invalid.
    """
    try:
        df = load_multilingual_dataset(dataset_name, user_id)
        results = []

        for _, row in df.iterrows():
            local_text = row['text']
            translation = row['translation']
            department = row['department']

            # Detect languages
            local_lang = detect_language(local_text, user_id)
            translation_lang = detect_language(translation, user_id) if translation else 'english'
            if translation_lang not in ['english', 'french']:
                logger.warning(
                    f"Fallback to english for translation language: {translation_lang} by user {user_id or 'unknown'}")
                translation_lang = 'english'

            # Analyze using translation
            sentiment = analyze_sentiment([translation], lang=translation_lang, user_id=user_id)[0]
            theme = extract_themes([translation], lang=translation_lang, user_id=user_id)[0]
            urgent = detect_urgency([translation], user_id=user_id)[0]

            # Generate a unique feedback ID
            feedback_id = f"FB_{pd.Timestamp.now().strftime('%Y%m%d%H%M%S')}_{len(results)}"

            # Store in database
            db_feedback = Feedback(
                feedback_id=feedback_id,
                text=local_text,
                language=local_lang,
                sentiment=sentiment,
                theme=theme,
                urgent=urgent,
                department=department,
                submitted_at=pd.Timestamp.now()
            )
            db.add(db_feedback)

            results.append({
                'feedback_id': feedback_id,
                'local_text': local_text,
                'local_language': local_lang,
                'translation': translation,
                'translation_language': translation_lang,
                'sentiment': sentiment,
                'theme': theme,
                'urgent': urgent,
                'department': department
            })

        db.commit()
        logger.info(f"Processed {len(results)} feedback entries from {dataset_name} by user {user_id or 'unknown'}")
        return results
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to process dataset {dataset_name} by user {user_id or 'unknown'}: {str(e)}")
        raise Exception(f"Failed to process dataset: {str(e)}")


def analyze_single_feedback(feedback: Feedback, db: Session, user_id: Optional[UUID] = None) -> FeedbackAnalysis:
    """
    Analyze a single feedback entry (used by /feedback/submit endpoint).

    Args:
        feedback: Feedback object to analyze.
        db: Database session.
        user_id: ID of the user performing the action (for logging).

    Returns:
        FeedbackAnalysis schema with analysis results.

    Raises:
        ValueError: If language is invalid.
    """
    try:
        translation = feedback.text
        translation_lang = detect_language(translation, user_id) if translation else 'english'
        if translation_lang not in ['english', 'french']:
            logger.warning(f"Fallback to english for feedback {feedback.feedback_id} by user {user_id or 'unknown'}")
            translation_lang = 'english'

        sentiment = analyze_sentiment([translation], lang=translation_lang, user_id=user_id)[0]
        theme = extract_themes([translation], lang=translation_lang, user_id=user_id)[0]
        urgent = detect_urgency([translation], user_id=user_id)[0]

        feedback.sentiment = sentiment
        feedback.theme = theme
        feedback.urgent = urgent
        db.commit()

        logger.info(
            f"Analyzed feedback {feedback.feedback_id}: sentiment={sentiment}, theme={theme}, urgent={urgent} by user {user_id or 'unknown'}")
        return FeedbackAnalysis(
            feedback_id=feedback.feedback_id,
            sentiment=sentiment,
            theme=theme,
            urgent=urgent
        )
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to analyze feedback {feedback.feedback_id} by user {user_id or 'unknown'}: {str(e)}")
        raise Exception(f"Failed to analyze feedback: {str(e)}")