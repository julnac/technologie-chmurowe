#!/bin/bash

CONTAINER_NAME="custom_nginx"
PORT=8080
CONFIG_DIR="./nginx_config"
HTML_DIR="./nginx_html"
HTML_FILE="index.html"
NGINX_CONF="$CONFIG_DIR/nginx.conf"

mkdir -p $CONFIG_DIR
mkdir -p $HTML_DIR

echo "<html><body><h1>Niestandardowy Nginx</h1></body></html>" > $HTML_DIR/$HTML_FILE

if [ ! -f "$NGINX_CONF" ]; then
    cat > "$NGINX_CONF" <<EOL
worker_processes 1;
events { worker_connections 1024; }
http {
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOL
fi

if [ $(docker ps -aq -f name=$CONTAINER_NAME) ]; then
    docker stop $CONTAINER_NAME &>/dev/null
    docker rm $CONTAINER_NAME &>/dev/null
fi

docker run -d --name $CONTAINER_NAME -p $PORT:80 \
    -v "$PWD/$HTML_DIR:/usr/share/nginx/html" \
    -v "$PWD/$CONFIG_DIR/nginx.conf:/etc/nginx/nginx.conf" \
    nginx &>/dev/null

if [ $? -eq 0 ]; then
    echo "Kontener Nginx został uruchomiony na porcie $PORT z niestandardową konfiguracją."
else
    echo "Nie udało się uruchomić kontenera Nginx."
    exit 1
fi

# Testy
sleep 3 
RESPONSE=$(curl -s http://localhost:$PORT)

if [[ "$RESPONSE" == *"Niestandardowy Nginx"* ]]; then
    echo "Test zakończony sukcesem: Strona działa poprawnie."
else
    echo "Test nie powiódł się: Strona nie zawiera oczekiwanej treści."
    exit 1
fi

# Test sprawdzający, czy kontener działa
if docker ps | grep -q $CONTAINER_NAME; then
    echo "Test zakończony sukcesem: Kontener jest uruchomiony."
else
    echo "Test nie powiódł się: Kontener nie działa."
    exit 1
fi