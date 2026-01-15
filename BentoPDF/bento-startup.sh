#!/bin/bash
set -e

APP_DIR="$HOME/sayarchi/BentoPDF"
SERVICE_NAME="bentopdf"
URL="http://localhost:3000"

cd "$APP_DIR"

# Check if container is already running
if docker ps --format '{{.Names}}' | grep -q "^${SERVICE_NAME}$"; then
    echo "BentoPDF is already running."
else
    echo "Starting BentoPDF..."
    docker compose up -d
fi

# Wait until BentoPDF responds
echo "Waiting for BentoPDF to be available..."
until curl -s "$URL" >/dev/null; do
    sleep 1
done

notify-send "BentoPDF is ready."

