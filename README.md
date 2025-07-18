# Sentimental Analysis Afrinova

This Python project performs an analysis of patient feedback data from a CSV file (`patient_feedback.csv`) and stores the results in a PostgreSQL database. It uses natural language processing (NLP) techniques to analyze sentiments, extract themes, and detect urgent issues in the feedback texts. This project was developed as part of the Afrinova hackathon to improve the analysis of patient feedback in a medical context.

## General Overview

The code performs the following steps:

1. **PostgreSQL Connection**: Connects to a PostgreSQL database and creates a table `feedback_analysis` to store the analysis results.
2. **Data Loading**: Reads the CSV file `patient_feedback.csv` containing patient feedback.
3. **Data Cleaning**: Handles missing values in the columns `feedback_text`, `rating`, `department`, and `feedback_id`.
4. **Sentiment Analysis**: Classifies feedback as **Positive**, **Neutral**, or **Negative** using a pre-trained model (`nlptown/bert-base-multilingual-uncased-sentiment`) with PyTorch and GPU support.
5. **Theme Extraction**: Identifies main themes in the feedback using the **BERTopic** model.
6. **Urgent Issue Detection**: Detects feedback containing predefined keywords (e.g., "long wait", "billing confusion") indicating critical issues.
7. **Result Storage**: Saves the results (sentiment, theme, urgency) in the PostgreSQL `feedback_analysis` table.
8. **Summary**: Displays the distribution of sentiments, themes, and urgent issues.

## Prerequisites

- **Python 3.8+**
- **PostgreSQL**: A running PostgreSQL instance with a database named `feedback_db`.
- **GPU (optional)**: An NVIDIA GPU with CUDA for accelerated sentiment analysis.
- **Python Dependencies**:
  - `pandas`
  - `psycopg2-binary`
  - `transformers`
  - `bertopic`
  - `scikit-learn`
  - `torch` (with CUDA support for GPU)
  - `tqdm`
- **CSV File**: A `patient_feedback.csv` file with columns `feedback_id`, `feedback_text`, `rating`, and `department`.
