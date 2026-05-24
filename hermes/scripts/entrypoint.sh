#!/bin/bash
set -e

HOME_DIR=/home/hermes
CONFIG_DIR=$HOME_DIR/.hermes

# Bootstrap config directory with default configs on first run
mkdir -p "$CONFIG_DIR"/{sessions,memories,skills,cron,hooks,logs,skins}
[ -f "$CONFIG_DIR"/config.yaml ] || cp /opt/hermes/config.yaml.default "$CONFIG_DIR"/config.yaml 2>/dev/null || true
[ -f "$CONFIG_DIR"/SOUL.md ] || cp /opt/hermes/SOUL.md.default "$CONFIG_DIR"/SOUL.md 2>/dev/null || true

# Auto-generate API_SERVER_KEY if not set (required for 0.0.0.0 binding)
[ -n "$API_SERVER_KEY" ] || API_SERVER_KEY=$(openssl rand -hex 32)
export API_SERVER_KEY

# Auto-generate .env from host environment variables if missing
if [ ! -f "$CONFIG_DIR/.env" ]; then
  if [ -n "$OPENROUTER_API_KEY" ]; then
    cat > "$CONFIG_DIR/.env" <<EOF
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_ALLOWED_USERS=$TELEGRAM_ALLOWED_USERS
TELEGRAM_HOME_CHANNEL=$TELEGRAM_HOME_CHANNEL
TELEGRAM_HOME_CHANNEL_THREAD_ID=$TELEGRAM_HOME_CHANNEL_THREAD_ID
EOF
    [ -n "$TELEGRAM_MODEL_PROVIDER" ] && echo "TELEGRAM_MODEL_PROVIDER=$TELEGRAM_MODEL_PROVIDER" >> "$CONFIG_DIR/.env"
    [ -n "$TELEGRAM_MODEL_NAME" ] && echo "TELEGRAM_MODEL_NAME=$TELEGRAM_MODEL_NAME" >> "$CONFIG_DIR/.env"
    chmod 600 "$CONFIG_DIR/.env"
    chown hermes:hermes "$CONFIG_DIR/.env"

    gosu hermes /opt/hermes/.venv/bin/hermes config set model.provider "${MODEL_PROVIDER:-openrouter}" 2>/dev/null || true
    gosu hermes /opt/hermes/.venv/bin/hermes config set model.name "${MODEL_NAME:-deepseek/deepseek-v4-pro}" 2>/dev/null || true
    gosu hermes /opt/hermes/.venv/bin/hermes config set model.base_url "${MODEL_BASE_URL:-https://openrouter.ai/api/v1}" 2>/dev/null || true
  else
    echo "Warning: OPENROUTER_API_KEY not set — can't generate .env. Set it in hermes/.env"
  fi
fi

# Start dashboard (background) if enabled
if [ "${HERMES_DASHBOARD:-0}" = "1" ]; then
  /opt/hermes/.venv/bin/hermes dashboard --tui \
    --host "${HERMES_DASHBOARD_HOST:-0.0.0.0}" \
    --port "${HERMES_DASHBOARD_PORT:-9119}" --insecure &
fi

# Fix permissions on shared projects volume
mkdir -p /opt/projects
chmod a+rwX /opt/projects

# SSH pubkey setup — env var OR baked-in file
if [ -n "${HERMES_SSH_PUBKEY}" ] || [ -f /etc/hermes/ssh.pub ]; then
  KEY="${HERMES_SSH_PUBKEY:-$(cat /etc/hermes/ssh.pub)}"

  # Authorize for hermes user (home = /home/hermes)
  mkdir -p "$HOME_DIR"/.ssh
  echo "$KEY" > "$HOME_DIR"/.ssh/authorized_keys
  chmod 700 "$HOME_DIR"/.ssh
  chmod 600 "$HOME_DIR"/.ssh/authorized_keys
  chown -R hermes:hermes "$HOME_DIR"/.ssh

  # Also for root
  mkdir -p /root/.ssh
  echo "$KEY" > /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
fi

# Start SSH server
if [ -f /usr/sbin/sshd ]; then
  /usr/sbin/sshd
fi

# Ensure hermes user can write to the config volume
if [ "$(id -u)" = "0" ]; then
  HERMES_UID=${HERMES_UID:-1000}
  HERMES_GID=${HERMES_GID:-1000}
  getent passwd "$HERMES_UID" > /dev/null 2>&1 \
    && chown -R "$HERMES_UID:$HERMES_GID" "$CONFIG_DIR" \
    || chmod -R a+rwX "$CONFIG_DIR"
fi

# Drop privileges to hermes user and run the requested command
if [ "$(id -u)" = "0" ] && getent passwd hermes > /dev/null 2>&1; then
  exec gosu hermes /opt/hermes/.venv/bin/hermes "$@"
else
  exec /opt/hermes/.venv/bin/hermes "$@"
fi