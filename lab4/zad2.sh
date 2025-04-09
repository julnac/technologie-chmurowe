#!/bin/bash

# Tworzenie wolumenów
VOLUME_NGINX=nginx_data
VOLUME_NODEJS=nodejs_data
VOLUME_ALL=all_volumes

docker volume create $VOLUME_NODEJS

docker run -d --name my_nodejs -v $VOLUME_NODEJS:/app node:latest tail -f /dev/null

docker volume create $VOLUME_ALL

# Pobranie ścieżki do wolumenu Node.js
VOLUME_NODEJS_PATH=$(docker volume inspect $VOLUME_NODEJS --format '{{ .Mountpoint }}')

# Tworzenie przykładowego pliku w katalogu Node.js
echo "console.log('Hello from Node.js!');" > "$VOLUME_NODEJS_PATH/app.js"

# Uruchomienie kontenera pomocniczego do kopiowania danych
docker run --rm \
    -v $VOLUME_NGINX:/usr/share/nginx/html \
    -v $VOLUME_NODEJS:/app \
    -v $VOLUME_ALL:/all_volumes \
    alpine sh -c "cp -r /usr/share/nginx/html /all_volumes/ && cp -r /app /all_volumes/"

echo "Pliki zostały skopiowane do wolumenu all_volumes."
