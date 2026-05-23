#!/bin/bash
set -e

cd "$(dirname "$0")/../.."

echo "==> Checking prerequisites..."
docker compose version >/dev/null 2>&1 || { echo "docker compose not found"; exit 1; }

echo "==> Building images..."
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
echo "3. Dashboard: http://localhost:9119"
