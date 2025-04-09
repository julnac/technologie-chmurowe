#!/bin/bash

# Tworzenie wolumenu
VOLUME_NAME=nginx_data
docker volume create $VOLUME_NAME

# Uruchomienie kontenera Nginx z zamontowanym wolumenem
docker run -d --name my_nginx -p 8080:80 -v $VOLUME_NAME:/usr/share/nginx/html nginx

# Pobranie ścieżki do wolumenu
VOLUME_PATH=$(docker volume inspect $VOLUME_NAME --format '{{ .Mountpoint }}')

# Tworzenie nowej strony HTML
echo "<html><head><title>Moja Strona</title></head><body><h1>Witaj w Nginx!</h1></body></html>" > "$VOLUME_PATH/index.html"

# Restart kontenera, aby załadować zmiany
docker restart my_nginx

echo "Serwer Nginx działa na porcie 8080. Sprawdź w przeglądarce http://localhost:8080"
