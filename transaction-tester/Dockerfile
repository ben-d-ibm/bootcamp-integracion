FROM python:3.12-slim

WORKDIR /app

COPY transaction-tester/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY transaction-tester/app.py .
COPY transaction-tester/static ./static

EXPOSE 8080

CMD ["python", "app.py"]
