#!/bin/bash

# Funkcja do wyświetlania informacji
info() {
  echo -e "\n\033[1;34m[$1]\033[0m $2"
}

# Konfiguracja
CONTAINER_NAME="nginx_configured_container"
PORT=8080
CONFIG_DIR=$(mktemp -d) # Tworzymy tymczasowy katalog na konfigurację
HTML_DIR=$(mktemp -d)   # Tworzymy tymczasowy katalog na stronę HTML

# Tworzymy plik HTML (treść strony)
echo '<html><head><title>Custom Nginx</title></head><body><h1>Witaj na serwerze Nginx!</h1></body></html>' > "$HTML_DIR/index.html"

# Tworzymy plik konfiguracyjny Nginx
cat <<EOF > "$CONFIG_DIR/default.conf"
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Sprawdzamy, czy istnieje kontener o tej samej nazwie i usuwamy go
EXISTING_CONTAINER=$(docker ps -aq -f name=$CONTAINER_NAME)
if [ -n "$EXISTING_CONTAINER" ]; then
  info "USUWANIE" "Usuwam istniejący kontener $CONTAINER_NAME"
  docker rm -f $CONTAINER_NAME
fi

# Uruchamiamy kontener Docker z Nginx, montując konfigurację i stronę HTML
info "KONTENER" "Uruchamiam kontener Docker z Nginx na porcie $PORT"
docker run -d --name $CONTAINER_NAME -p $PORT:80 \
  -v "$CONFIG_DIR/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  -v "$HTML_DIR:/usr/share/nginx/html:ro" \
  nginx:latest

# Czekamy chwilę na uruchomienie serwera
sleep 3

# Testy poprawności działania
info "TESTY" "Sprawdzam dostępność strony..."

response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT)
if [ "$response_code" == "200" ]; then
    echo "Test 1 PASSED: Serwer zwrócił HTTP 200"
else
    echo "Test 1 FAILED: Serwer nie zwrócił HTTP 200"
    exit 1
fi

page_content=$(curl -s http://localhost:$PORT)
if [[ "$page_content" == *"Witaj na serwerze Nginx!"* ]]; then
    echo "Test 2 PASSED: Strona zawiera oczekiwany tekst"
else
    echo "Test 2 FAILED: Strona nie zawiera oczekiwanego tekstu"
    exit 1
fi

info "SPRZĄTANIE" "Aby zatrzymać i usunąć kontener, użyj:"
echo "docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"

# chmod +x run-nginx.sh
# ./run-nginx.sh 
