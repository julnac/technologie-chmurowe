#!/bin/bash

set -e

echo "✅ Sprawdzanie dostępności kontenerów..."
docker-compose ps

echo "🔄 Uruchamianie kontenerów..."
docker-compose up -d --build

echo "⏳ Oczekiwanie na zdrowie backendu..."
until [ "$(docker inspect -f '{{.State.Health.Status}}' $(docker-compose ps -q backend))" == "healthy" ]; do
    sleep 2
    echo "⏳ Backend jeszcze nie gotowy..."
done

echo "🌐 Test połączenia frontend → backend..."
docker exec $(docker-compose ps -q frontend) wget -qO- http://backend:8000/health || {
  echo "❌ Brak połączenia frontend → backend"
  exit 1
}

echo "🌐 Test połączenia backend → database..."
docker exec $(docker-compose ps -q backend) python3 -c "
import psycopg2
conn = psycopg2.connect(host='database', dbname='mydb', user='user', password='password')
conn.close()
print('Połączenie OK')
"

echo "✅ Wszystko działa prawidłowo!"
