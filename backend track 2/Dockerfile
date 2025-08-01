FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p ./chroma_db
ENV GOOGLE_CLOUD_PROJECT=grounded-datum-466612-u9
RUN gsutil cp -r gs://grounded-datum-466612-u9-clinical-data/chroma_db/* ./chroma_db

ENV DB_HOST=/cloudsql/grounded-datum-466612-u9:us-central1:medical-chatbot-db
ENV DB_PORT=5432
ENV DB_NAME=clinical_db
ENV DB_USER=aaron
ENV DB_PASSWORD=Datathon25

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]