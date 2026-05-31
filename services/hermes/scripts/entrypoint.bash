#!/bin/bash
set -e

# Copy and secure authorized_keys
if [ -f /tmp/authorized_keys ]; then
  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  cp /tmp/authorized_keys /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chown root:root /root/.ssh/authorized_keys
fi

HERMES_REPO=/root/.hermes/hermes-agent
HERMES_DATA=/root/.hermes
HERMES_STAGE=/opt/hermes-stage

# On first boot, seed the bind mount from the pre-built stage
if [ ! -f "$HERMES_REPO/pyproject.toml" ]; then
  echo ">>> Seeding Hermes from stage..."
  cp -a "$HERMES_STAGE"/. "$HERMES_DATA"
  echo ">>> Hermes ready"
fi

# Ensure OPENAI_BASE_URL is set in Hermes' .env
HERMES_ENV_FILE="$HERMES_DATA/.env"
if ! grep -q '^OPENAI_BASE_URL=' "$HERMES_ENV_FILE" 2>/dev/null; then
  echo ">>> Setting Ollama as provider..."
  echo "OPENAI_BASE_URL=${OPENAI_BASE_URL:-http://ollama:11434/v1}" >>"$HERMES_ENV_FILE"
fi

# Ensure hermes is on PATH (installer links into HERMES_HOME/.local/bin)
export PATH="$HERMES_DATA/.local/bin:/root/.local/bin:$PATH"

# Set root password from environment variable
if [ -n "$ROOT_PASSWORD" ]; then
  echo "root:$ROOT_PASSWORD" | chpasswd
fi

# Start Hermes web dashboard in the background
hermes dashboard --host "${HERMES_HOSTNAME_WEB:-0.0.0.0}" --port "${HERMES_PORT_WEB:-9119}" --tui --insecure &

# Start the gateway
hermes gateway &

# Start SSH daemon
exec /usr/sbin/sshd -D
