#!/bin/bash
set -e

cd "$(dirname "$0")/../.."

echo "==> Checking prerequisites..."
docker compose version >/dev/null 2>&1 || { echo "docker compose not found"; exit 1; }

# Generate self-signed certs for Nginx if they don't exist
CERTS_DIR="nginx/certs"
if [ ! -f "$CERTS_DIR/fullchain.pem" ] || [ ! -f "$CERTS_DIR/privkey.pem" ]; then
  echo "==> Generating self-signed TLS certs..."
  mkdir -p "$CERTS_DIR"
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$CERTS_DIR/privkey.pem" \
    -out "$CERTS_DIR/fullchain.pem" \
    -days 365 -subj "/CN=localhost" 2>/dev/null
  echo "     Replace with real certs when ready."
fi

echo "==> Building image..."
docker compose build

# One-time provider config (persisted in /opt/data/config.yaml)
echo "==> Configuring OpenRouter provider..."
docker compose run --rm hermes config set model.provider openrouter
docker compose run --rm hermes config set model.name ou-mini
docker compose run --rm hermes config set model.base_url https://api.openrouter.ai/v1

echo ""
echo "Setup complete."
echo "1. Edit .env and set your real OPENROUTER_API_KEY"
echo "2. Run: docker compose up -d"
echo "3. Dashboard: https://localhost/hermes/"
