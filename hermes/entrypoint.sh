#!/bin/bash
set -e

# Bootstrap data directory with default configs on first run
mkdir -p /opt/data/{sessions,memories,skills,cron,hooks,logs,skins}
[ -f /opt/data/config.yaml ] || cp /opt/hermes/config.yaml.default /opt/data/config.yaml 2>/dev/null || true
[ -f /opt/data/SOUL.md ] || cp /opt/hermes/SOUL.md.default /opt/data/SOUL.md 2>/dev/null || true

# Start dashboard (background) if enabled
if [ "${HERMES_DASHBOARD:-0}" = "1" ]; then
  /opt/hermes/.venv/bin/hermes dashboard --tui \
    --host "${HERMES_DASHBOARD_HOST:-0.0.0.0}" \
    --port "${HERMES_DASHBOARD_PORT:-9119}" --insecure &
fi

# Ensure hermes user can write to the data volume
if [ "$(id -u)" = "0" ]; then
  HERMES_UID=${HERMES_UID:-10000}
  HERMES_GID=${HERMES_GID:-10000}
  getent passwd "$HERMES_UID" > /dev/null 2>&1 \
    && chown -R "$HERMES_UID:$HERMES_GID" /opt/data \
    || chmod -R a+rwX /opt/data
fi

# Drop privileges to hermes user and run the requested command
if [ "$(id -u)" = "0" ] && getent passwd hermes > /dev/null 2>&1; then
  exec gosu hermes /opt/hermes/.venv/bin/hermes "$@"
else
  exec /opt/hermes/.venv/bin/hermes "$@"
fi
