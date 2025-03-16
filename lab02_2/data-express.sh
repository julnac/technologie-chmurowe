#!/bin/bash

# Funkcja do wyświetlania informacji o krokach
info() {
  echo -e "\n\033[1;34m[$1]\033[0m $2"
}

# Ustalamy wersję Node.js
NODE_VERSION="14"
CONTAINER_NAME="node14_express_server"
PORT=8080

info "KONFIGURACJA" "Używam Node.js w wersji $NODE_VERSION"

# Tworzymy i uruchamiamy kontener Docker w trybie detached (w tle)
info "KONTENER" "Tworzę i uruchamiam kontener Docker z Node.js $NODE_VERSION"
CONTAINER_ID=$(docker run -d -p $PORT:$PORT --name $CONTAINER_NAME -it node:$NODE_VERSION-alpine tail -f /dev/null)

echo "Utworzono kontener o ID: $CONTAINER_ID"

# Tworzymy katalog w kontenerze
info "STRUKTURA" "Tworzenie katalogu /app w kontenerze"
docker exec $CONTAINER_ID mkdir -p /app

# Tworzymy pliki aplikacji lokalnie
mkdir -p node_app
cat <<EOF > node_app/package.json
{
  "name": "express-app",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.17.1"
  }
}
EOF

cat <<EOF > node_app/server.js
const express = require('express');
const app = express();
const port = ${PORT};

app.get('/', (req, res) => {
  res.json({ datetime: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
EOF

# Kopiujemy pliki aplikacji do kontenera
info "KOPIOWANIE" "Kopiowanie plików aplikacji do kontenera za pomocą docker cp"
docker cp node_app/package.json $CONTAINER_ID:/app/
docker cp node_app/server.js $CONTAINER_ID:/app/

# Instalujemy zależności wewnątrz kontenera
info "ZALEŻNOŚCI" "Instalacja zależności Node.js wewnątrz kontenera"
docker exec -w /app $CONTAINER_ID npm install

# Uruchamiamy aplikację
info "URUCHOMIENIE" "Uruchamianie aplikacji Express.js w kontenerze"
docker exec -w /app $CONTAINER_ID node server.js &

# Oczekiwanie na uruchomienie serwera
sleep 3

# Testowanie poprawności działania serwera
echo "Running tests..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT})
if [ "$response" == "200" ]; then
    echo "Test passed: Server responded with HTTP 200"
else
    echo "Test failed: Server did not respond with HTTP 200"
    exit 1
fi

actual_output=$(curl -s http://localhost:${PORT})
if [[ "$actual_output" == *"datetime"* ]]; then
    echo "Test passed: Server returned expected JSON response"
else
    echo "Test failed: Expected JSON response with datetime but got '$actual_output'"
    exit 1
fi

echo "All tests passed successfully!"

# Na końcu pokazujemy instrukcje jak zatrzymać i usunąć kontener
info "SPRZĄTANIE" "Aby zatrzymać i usunąć kontener, wykonaj:"
echo "docker stop $CONTAINER_ID"
echo "docker rm $CONTAINER_ID"

# chmod +x data-express.sh
# ./data-express.sh 