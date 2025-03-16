#!/bin/bash

NODE_CONTAINER="node_app"
NGINX_CONTAINER="nginx_proxy"
PORT_NODE=3000
PORT_NGINX=80
CONFIG_DIR="./nginx_config"
SSL_DIR="./nginx_ssl"
APP_DIR="./node_app"
NGINX_CONF="$CONFIG_DIR/nginx.conf"
CERT_FILE="$SSL_DIR/nginx.crt"
KEY_FILE="$SSL_DIR/nginx.key"

docker --version &>/dev/null
if [ $? -ne 0 ]; then
    echo "Docker nie jest zainstalowany. Zainstaluj Docker i spróbuj ponownie."
    exit 1
fi

mkdir -p $CONFIG_DIR $SSL_DIR $APP_DIR

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $KEY_FILE -out $CERT_FILE \
    -subj "/C=PL/ST=State/L=City/O=Company/OU=Org/CN=localhost"
fi

if [ ! -f "$APP_DIR/server.js" ]; then
    cat > "$APP_DIR/server.js" <<EOL
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Hello from Node.js!'));
app.listen($PORT_NODE, () => console.log('Server running on port $PORT_NODE'));
EOL
    echo "{}" > "$APP_DIR/package.json"
fi

docker stop $NODE_CONTAINER &>/dev/null
docker rm $NODE_CONTAINER &>/dev/null

docker run -d --name $NODE_CONTAINER -p $PORT_NODE:3000 \
    -v "$PWD/$APP_DIR:/usr/src/app" \
    -w /usr/src/app node:14 bash -c "npm install express && node server.js" &>/dev/null

if [ ! -f "$NGINX_CONF" ]; then
    cat > "$NGINX_CONF" <<EOL
worker_processes 1;
events { worker_connections 1024; }
http {
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m inactive=60m;
    server {
        listen 80;
        listen 443 ssl;
        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            proxy_pass http://my-node-app:3000;
            proxy_cache my_cache;
            proxy_cache_valid 200 10m;
        }
    }
}
EOL
fi

docker stop $NGINX_CONTAINER &>/dev/null
docker rm $NGINX_CONTAINER &>/dev/null

docker run -d --name $NGINX_CONTAINER -p $PORT_NGINX:80 -p 443:443 \
    --link $NODE_CONTAINER:my-node-app \
    -v "$PWD/$CONFIG_DIR/nginx.conf:/etc/nginx/nginx.conf" \
    -v "$PWD/$SSL_DIR:/etc/nginx/ssl" \
    nginx &>/dev/null

if [ $? -eq 0 ]; then
    echo "Nginx reverse proxy z SSL został uruchomiony na porcie $PORT_NGINX."
else
    echo "Nie udało się uruchomić kontenera Nginx. Sprawdź logi: 'docker logs $NGINX_CONTAINER'."
    exit 1
fi

# Testy
sleep 3

echo "Sprawdzanie, czy kontenery są uruchomione..."
if docker ps | grep -q $NODE_CONTAINER && docker ps | grep -q $NGINX_CONTAINER; then
    echo "Test 1: Oba kontenery działają."
else
    echo "Test 1 nie powiódł się: Jeden z kontenerów nie działa."
    exit 1
fi

echo "Sprawdzanie, czy Node.js działa..."
NODE_RESPONSE=$(wget -qO- http://127.0.0.1:$PORT_NODE)
if [[ "$NODE_RESPONSE" == *"Hello from Node.js!"* ]]; then
    echo "Test 2: Node.js działa poprawnie."
else
    echo "Test 2 nie powiódł się: Node.js nie działa."
    docker logs $NODE_CONTAINER
    exit 1
fi

echo "Sprawdzanie, czy reverse proxy działa..."
NGINX_RESPONSE=$(curl -s http://localhost:$PORT_NGINX)
if [[ "$NGINX_RESPONSE" == *"Hello from Node.js!"* ]]; then
    echo "Test 3: Reverse proxy działa poprawnie."
else
    echo "Test 3 nie powiódł się: Proxy nie działa."
    docker logs $NGINX_CONTAINER
    exit 1
fi

echo "Wszystkie testy zakończone sukcesem!"