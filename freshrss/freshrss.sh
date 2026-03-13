#!/usr/bin/env bash
set -e

APP_DIR="$HOME/sayarchi/freshrss"
BACKUP_DIR="$APP_DIR/backups"
INTERVAL=120
MAX_BACKUPS=20

echo "[+] Starting FreshRSS..."
cd "$APP_DIR"
docker compose up -d

echo "[+] Checking permissions..."

if [ ! -w "$APP_DIR/data" ]; then
    echo "[!] Permission fix required."

    PASSWORD=$(rofi -dmenu -password -p "sudo password:")

    if [ -z "$PASSWORD" ]; then
        echo "[-] No password entered. Exiting."
        exit 1
    fi

    echo "$PASSWORD" | sudo -S chown -R "$USER:$USER" "$APP_DIR/data" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "[-] Failed to fix permissions."
        exit 1
    fi

    echo "[+] Permissions fixed."
else
    echo "[✓] Permissions OK."
fi

mkdir -p "$BACKUP_DIR"

echo "[+] Starting backup loop (every $INTERVAL seconds)..."

while true; do
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    BACKUP_FILE="$BACKUP_DIR/freshrss_$TIMESTAMP.tar.gz"

    echo "[+] Creating backup: $BACKUP_FILE"
    tar -czf "$BACKUP_FILE" data

    # keep only latest N backups
    ls -tp "$BACKUP_DIR" | grep -v '/$' | tail -n +$((MAX_BACKUPS+1)) | while read file; do
        rm -- "$BACKUP_DIR/$file"
    done

    sleep "$INTERVAL"
done
