#!/bin/bash

set -e

# Nazwy kontenerów
NODE_CONTAINER="my-node-app"
NGINX_CONTAINER="my-nginx-proxy"
NETWORK_NAME="my_network"

# Ścieżki do plików konfiguracyjnych
NGINX_CONF_DIR="./nginx"
SSL_DIR="./ssl"
CACHE_DIR="./nginx/cache"

# Tworzenie sieci Docker
echo "Tworzenie sieci Docker..."
docker network create $NETWORK_NAME || true

# Tworzenie katalogów
echo "Tworzenie katalogów konfiguracyjnych..."
mkdir -p $NGINX_CONF_DIR $SSL_DIR $CACHE_DIR

# Generowanie certyfikatu SSL
echo "Generowanie certyfikatu SSL..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $SSL_DIR/nginx.key -out $SSL_DIR/nginx.crt -subj "/CN=localhost"

# Tworzenie aplikacji Node.js
echo "Tworzenie aplikacji Node.js..."
cat > app.js <<EOF
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
    res.send('Hello from Node.js!');
});

app.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
});
EOF

cat > package.json <<EOF
{
  "name": "node-app",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.17.1"
  }
}
EOF

cat > Dockerfile-node <<EOF
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install
COPY app.js ./
CMD ["node", "app.js"]
EOF

# Budowanie i uruchamianie kontenera Node.js
echo "Budowanie i uruchamianie kontenera Node.js..."
docker build -t node-app -f Dockerfile-node .
docker run -d --rm --name $NODE_CONTAINER --network $NETWORK_NAME node-app

# Tworzenie konfiguracji Nginx
echo "Tworzenie konfiguracji Nginx..."
cat > $NGINX_CONF_DIR/nginx.conf <<EOF
worker_processes 1;
events {
    worker_connections 1024;
}
http {
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=100m inactive=60m use_temp_path=off;

    server {
        listen 80;
        server_name localhost;
        return 301 https://\$host\$request_uri;
    }

    server {
        listen 443 ssl;
        server_name localhost;

        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

        location / {
            proxy_pass http://$NODE_CONTAINER:3000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_cache my_cache;
            proxy_cache_valid 200 10m;
            add_header X-Cache \$upstream_cache_status;
        }
    }
}
EOF

# Tworzenie Dockerfile dla Nginx
echo "Tworzenie Dockerfile dla Nginx..."
cat > Dockerfile-nginx <<EOF
FROM nginx:latest
RUN apt-get update && apt-get install -y openssl
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY ssl /etc/nginx/ssl
RUN mkdir -p /var/cache/nginx && chown -R nginx:nginx /var/cache/nginx
CMD ["nginx", "-g", "daemon off;"]
EOF

# Budowanie i uruchamianie kontenera Nginx
echo "Budowanie i uruchamianie kontenera Nginx..."
docker build -t nginx-proxy -f Dockerfile-nginx .
docker run -d --rm --name $NGINX_CONTAINER --network $NETWORK_NAME -p 80:80 -p 443:443 nginx-proxy

# Testy
echo "Sprawdzanie poprawności kontenerów..."
sleep 5

# Testowanie aplikacji Node.js
if docker exec $NODE_CONTAINER curl -s http://localhost:3000 | grep "Hello from Node.js"; then
    echo "Node.js działa poprawnie."
else
    echo "Błąd: Node.js nie działa poprawnie!" && exit 1
fi

# Testowanie reverse proxy z SSL
if curl -ks https://localhost | grep "Hello from Node.js"; then
    echo "Nginx działa poprawnie jako reverse proxy."
else
    echo "Błąd: Nginx nie działa poprawnie!" && exit 1
fi

echo "Skrypt zakończony sukcesem!"

# chmod +x zad3.sh
# ./zad3.sh