Blood Bank Management System
This repository contains a blood bank management system designed to optimize blood stock levels and forecast demand using machine learning and optimization techniques. The system is built with a React frontend and a FastAPI backend, utilizing PostgreSQL for data storage and PuLP for optimization.
Table of Contents

Project Overview
Features
Tech Stack
Installation
Usage
File Structure
API Endpoints
Database Schema
Contributing
License

Project Overview
This project aims to assist blood banks in managing inventory by forecasting blood demand and optimizing stock orders. It integrates machine learning models (Random Forest, XGBoost, LSTM, and ARIMA) for demand forecasting and uses linear programming to minimize costs while ensuring adequate stock levels.
Features

Demand Forecasting: Predicts blood demand for different blood types using ARIMA, Random Forest, XGBoost, and LSTM models.
Stock Optimization: Uses PuLP to optimize blood orders, balancing normal and emergency orders while respecting storage capacity and safety stock requirements.
Data Visualization: A React-based dashboard (StockDashboard.jsx) to visualize stock levels, forecasts, and optimization recommendations.
API Endpoints: FastAPI provides endpoints to retrieve stock data, forecasts, and model performance metrics.
Robust Data Processing: Handles data preprocessing, outlier filtering, and feature engineering for accurate predictions.

Tech Stack

Frontend: React, Tailwind CSS
Backend: FastAPI, Python
Database: PostgreSQL
Machine Learning: scikit-learn, XGBoost, TensorFlow, pmdarima
Optimization: PuLP
Data Processing: pandas, NumPy
Other: SQLAlchemy, uvicorn, logging

Installation
Prerequisites

Python 3.8+
Node.js 16+
PostgreSQL
pip for Python package management
npm or yarn for Node.js package management

Steps

Clone the Repository:
git clone https://github.com/your-username/blood-bank-management.git
cd blood-bank-management


Backend Setup:

Install Python dependencies:pip install -r requirements.txt


Update the PostgreSQL connection string in stock_sqlalchemy.py and forecasting.py:engine = create_engine('postgresql+psycopg2://your_username:your_password@your_host:5432/clinical_db')


Ensure blood_bank_records.csv is in the project root for data loading.


Frontend Setup:

Navigate to the frontend directory (assuming StockDashboard.jsx is part of a React app):cd frontend
npm install


Update API endpoint URLs in StockDashboard.jsx to match your backend host (e.g., http://localhost:8000).


Database Setup:

Create a PostgreSQL database named clinical_db.
The forecasting.py script automatically creates the required tables (stocks and forecasts) on startup.


Run the Application:

Start the FastAPI backend:uvicorn stock_sqlalchemy:app --host 0.0.0.0 --port 8000
uvicorn forecasting:app --host 0.0.0.0 --port 8001


Start an additional FastAPI backend instance for forecasting (on a different port, e.g., 8001).
Start the React frontend:cd frontend
npm start





Usage

Backend: The FastAPI servers provide endpoints for stock management, forecasting, and model performance.
Frontend: Access the React dashboard in your browser (default: http://localhost:3000) to view stock levels, forecasts, and optimization recommendations.
Data: Ensure blood_bank_records.csv contains historical blood donation data with columns like record_id, donor_id, donor_age, blood_type, collection_volume_ml, etc.

File Structure

stock_sqlalchemy.py: FastAPI backend for stock optimization using PuLP. Queries current stock, forecasts, and expiring stock, then provides order recommendations.
forecasting.py: FastAPI backend for demand forecasting using ARIMA, Random Forest, XGBoost, and LSTM models. Includes data preprocessing and model evaluation.
StockDashboard.jsx: React component for the frontend dashboard (assumed to be part of a larger React app, not fully provided in the input).

API Endpoints
stock_sqlalchemy.py

GET /recommendations:
Returns optimized blood order recommendations, emergency orders, and total cost.
Response: JSON with recommendations, emergency_orders, and total_cost.



forecasting.py

GET /forecast/{blood_type}:
Returns 30-day demand forecasts for a specific blood type using multiple models.
Response: JSON with blood_type, forecast_date, arima, random_forest, xgboost, neural_network, and avg_forecast.


GET /stocks/{blood_type}:
Returns current stock data for a specific blood type.
Response: JSON with stock records.


GET /model_performance:
Returns performance metrics (RMSE, MAE) for all models and feature importance.
Response: JSON with metrics for Random Forest, XGBoost, LSTM, and ARIMA.



Database Schema

stocks:
record_id: VARCHAR(50)
donor_id: VARCHAR(50)
donor_age: INT
donor_gender: VARCHAR(10)
blood_type: VARCHAR(10)
collection_site: VARCHAR(50)
donation_date: DATE
expiry_date: DATE
collection_volume_ml: FLOAT
hemoglobin_g_dl: FLOAT


forecasts:
blood_type: VARCHAR(10) (Primary Key)
forecast_date: DATE (Primary Key)
arima: INTEGER
random_forest: INTEGER
xgboost: INTEGER
neural_network: INTEGER
avg_forecast: INTEGER



Contributing

Fork the repository.
Create a feature branch (git checkout -b feature/your-feature).
Commit your changes (git commit -m "Add your feature").
Push to the branch (git push origin feature/your-feature).
Open a pull request.

License
This project is licensed under the MIT License. See the LICENSE file for details.