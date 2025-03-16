#!/bin/bash

# Ustawienia domyślne
PORT=8080
CONFIG_FILE=""
CONTAINER_NAME="custom-nginx"

# Obsługa argumentów
while getopts p:f: flag
do
    case "${flag}" in
        p) PORT=${OPTARG};;  # Ustawienie portu
        f) CONFIG_FILE=${OPTARG};;  # Ścieżka do pliku konfiguracyjnego Nginx
    esac
done

# Sprawdzenie, czy podano plik konfiguracyjny
if [[ -z "$CONFIG_FILE" ]]; then
    echo "Błąd: Musisz podać plik konfiguracyjny Nginx za pomocą opcji -f."
    exit 1
fi

# Sprawdzenie, czy plik istnieje
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Błąd: Podany plik konfiguracyjny ($CONFIG_FILE) nie istnieje."
    exit 1
fi

# Tworzenie katalogu dla konfiguracji
mkdir -p ./nginx-config
cp "$CONFIG_FILE" ./nginx-config/nginx.conf

# Usunięcie starego kontenera (jeśli istnieje)
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# Uruchomienie kontenera Nginx z niestandardową konfiguracją
docker run -d --name $CONTAINER_NAME -p $PORT:80 \
  -v "$(pwd)/nginx-config/nginx.conf:/etc/nginx/nginx.conf:ro" \
  --restart always \
  nginx

echo "Serwer Nginx działa na porcie ${PORT} z niestandardową konfiguracją."

# Testowanie poprawności działania skryptu
sleep 2
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)

if [[ "$RESPONSE" != "200" ]]; then
  echo "Błąd: Serwer Nginx nie zwrócił HTTP 200!"
  exit 1
fi

echo "Test zakończony sukcesem!"

# chmod +x zad2.sh
# ./zad2.sh -p 9090 -f my-nginx.conf
# curl http://localhost:9090