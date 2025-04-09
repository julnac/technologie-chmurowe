# Sprawdzenie zużycia przestrzeni dyskowej wszystkich wolumenów Docker
echo "\nZużycie przestrzeni dyskowej dla wszystkich wolumenów Docker:"
docker volume ls -q | while read volume; do
    path=$(docker volume inspect $volume --format '{{ .Mountpoint }}')
    if [ -d "$path" ]; then
        usage=$(df -h "$path" | awk 'NR==2 {print $5}')
        echo "Wolumen: $volume - Zużycie: $usage"
    else
        echo "Wolumen: $volume - Brak danych (wolumen może być pusty lub niezamontowany)"
    fi
done
