FROM python:3.14-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8002
CMD ["gunicorn", "--bind", "0.0.0.0:8002", "app:app"]
