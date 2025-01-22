#!/bin/bash

CWD=$(pwd)

COMPOSE_FILE=${COMPOSE_FILE:-compose.yml}

if ! command -v docker compose 2>&1; then
    echo "docker compose is not installed."
    exit 1
fi

echo "Bringing Docker Compose stack down."

docker compose -f "${COMPOSE_FILE}" down
