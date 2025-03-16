#!/bin/bash

# Funkcja do wyświetlania informacji o krokach
info() {
  echo -e "\n\033[1;34m[$1]\033[0m $2"
}

# Ustalamy wersję Node.js
NODE_VERSION="16"
CONTAINER_NAME="node16_express_mongo"
MONGO_CONTAINER_NAME="mongo_db"
PORT=8080
MONGO_PORT=27017
MONGO_DB="testdb"

info "KONFIGURACJA" "Używam Node.js w wersji $NODE_VERSION oraz MongoDB"

# Uruchamiamy kontener MongoDB
info "BAZA DANYCH" "Tworzenie i uruchamianie kontenera MongoDB"
docker run -d --name $MONGO_CONTAINER_NAME -p $MONGO_PORT:$MONGO_PORT mongo:latest

echo "Utworzono kontener MongoDB o nazwie: $MONGO_CONTAINER_NAME"

# Tworzymy i uruchamiamy kontener aplikacji Node.js
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
  "name": "express-mongo-app",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.17.1",
    "mongoose": "^6.0.0"
  }
}
EOF

cat <<EOF > node_app/server.js
const express = require('express');
const mongoose = require('mongoose');
const app = express();
const port = ${PORT};
const mongoUri = "mongodb://host.docker.internal:${MONGO_PORT}/${MONGO_DB}";

mongoose.connect(mongoUri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log("Connected to MongoDB"))
  .catch(err => console.error("MongoDB connection error:", err));

const dataSchema = new mongoose.Schema({ message: String });
const DataModel = mongoose.model("Data", dataSchema);

async function seedDatabase() {
  const count = await DataModel.countDocuments();
  if (count === 0) {
    await DataModel.create({ message: "Hello from MongoDB" });
    console.log("Inserted initial data into MongoDB");
  }
}

seedDatabase();

app.get('/', async (req, res) => {
  try {
    const data = await DataModel.find();
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
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
sleep 5

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
if [[ "$actual_output" == *"message"* ]]; then
    echo "Test passed: Server returned expected JSON response from MongoDB"
else
    echo "Test failed: Expected JSON response from MongoDB but got '$actual_output'"
    exit 1
fi

echo "All tests passed successfully!"

# Na końcu pokazujemy instrukcje jak zatrzymać i usunąć kontenery
info "SPRZĄTANIE" "Aby zatrzymać i usunąć kontenery, wykonaj:"
echo "docker stop $CONTAINER_ID $MONGO_CONTAINER_NAME"
echo "docker rm $CONTAINER_ID $MONGO_CONTAINER_NAME"

# chmod +x zad3.sh
# ./zad3.sh 