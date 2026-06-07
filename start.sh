#!/bin/bash
set -e

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  if [ -f ".env.example" ]; then
    echo "No .env found. Copying from .env.example..."
    cp .env.example .env
  else
    echo "Error: No .env file found."
    exit 1
  fi
fi

# Read toggles from .env
PROXY_ENABLED=$(grep -E '^PROXY_ENABLED=' "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
WEBAPP_ENABLED=$(grep -E '^WEBAPP_ENABLED=' "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
MARKETPLACE_ENABLED=$(grep -E '^MARKETPLACE_ENABLED=' "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')

PROFILES=""

if [ "$PROXY_ENABLED" = "true" ]; then
  PROFILES="$PROFILES --profile proxy"
fi

if [ "$WEBAPP_ENABLED" = "true" ]; then
  PROFILES="$PROFILES --profile webapp"
fi

if [ "$MARKETPLACE_ENABLED" = "true" ]; then
  PROFILES="$PROFILES --profile marketplace"
fi

echo "Starting PeakSSH services..."
echo "  Sync backend: always on"
echo "  Proxy:        $PROXY_ENABLED"
echo "  Webapp:       $WEBAPP_ENABLED"
echo "  Marketplace:  $MARKETPLACE_ENABLED"
echo ""

# shellcheck disable=SC2086
docker compose $PROFILES up -d
