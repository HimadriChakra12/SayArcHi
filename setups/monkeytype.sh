#!/usr/bin/env bash
set -e

MONKEYTYPE_DIR="$HOME/.monkeytype"
DOCKER_DIR="$MONKEYTYPE_DIR/docker"

# Clone repo if it doesn't exist
if [[ ! -d "$MONKEYTYPE_DIR" ]]; then
  git clone https://github.com/HimadriChakra12/monkeytype.git "$MONKEYTYPE_DIR"
fi

# Go to docker directory
cd "$DOCKER_DIR"

# Create env file if it doesn't exist
if [[ ! -f ".env" ]]; then
  cp example.env .env
fi

# Start services
docker compose up -d
