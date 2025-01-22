#!/bin/bash

CWD=$(pwd)

CONTAINER_NAME=${GIT_SYNC_REPOS_CONTAINER_NAME:-git-sync}
COMPOSE_FILE=${GIT_SYNC_REPOS_COMPOSE_FILE:-compose.yml}

if ! command -v docker compose 2>&1; then
    echo "docker compose is not installed."
    exit 1
fi

echo "Getting logs from container '$CONTAINER_NAME'"

docker compose -f "${COMPOSE_FILE}" logs -f "${CONTAINER_NAME}"
