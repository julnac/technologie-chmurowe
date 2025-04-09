#!/bin/bash

# Nazwa woluminu do zabezpieczenia
VOLUME_NAME=secure_volume
ARCHIVE_NAME=${VOLUME_NAME}.tar.gz
ENCRYPTED_ARCHIVE=${ARCHIVE_NAME}.gpg

# Tworzenie woluminu Docker
docker volume create $VOLUME_NAME

# Pobranie ścieżki do woluminu
VOLUME_PATH=$(docker volume inspect $VOLUME_NAME --format '{{ .Mountpoint }}')

# Tworzenie przykładowych danych w wolumenie
echo "Sekretne dane w wolumenie" > "$VOLUME_PATH/secret.txt"

echo "Zabezpieczanie woluminu..."
# Archiwizacja danych woluminu
tar -czf $ARCHIVE_NAME -C "$VOLUME_PATH" .

# Szyfrowanie archiwum
echo "Podaj hasło do zaszyfrowania woluminu:"
gpg --symmetric --cipher-algo AES256 --output $ENCRYPTED_ARCHIVE $ARCHIVE_NAME

# Usunięcie oryginalnego archiwum po zaszyfrowaniu
rm -f $ARCHIVE_NAME

echo "Wolumen został zabezpieczony i zapisany jako $ENCRYPTED_ARCHIVE."

# Odszyfrowanie woluminu
echo "Czy chcesz odszyfrować wolumen? (tak/nie)"
read response
if [ "$response" == "tak" ]; then
    echo "Podaj hasło do odszyfrowania woluminu:"
    gpg --output $ARCHIVE_NAME --decrypt $ENCRYPTED_ARCHIVE
    
    echo "Rozpakowywanie danych do woluminu..."
    tar -xzf $ARCHIVE_NAME -C "$VOLUME_PATH"
    
    # Usunięcie archiwum po odszyfrowaniu
    rm -f $ARCHIVE_NAME
    echo "Wolumen został odszyfrowany."
else
    echo "Odszyfrowanie pominięte."
fi
