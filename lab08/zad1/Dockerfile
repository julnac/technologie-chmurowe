# Użyj oficjalnego obrazu Pythona
FROM python:latest

# Ustaw katalog roboczy w kontenerze
WORKDIR /app

# Skopiuj pliki do kontenera
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py app.py

# Uruchom aplikację
CMD ["python", "app.py"]
