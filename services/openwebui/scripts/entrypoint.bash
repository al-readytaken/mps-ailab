#!/bin/bash
set -e

# Copy and secure authorized_keys
if [ -f /tmp/authorized_keys ]; then
  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  cp /tmp/authorized_keys /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chown root:root /root/.ssh/authorized_keys
fi

# Set root password if provided
if [ -n "$ROOT_PASSWORD" ]; then
  echo "root:$ROOT_PASSWORD" | chpasswd
fi

# Start SSH daemon in background
mkdir -p /var/run/sshd
/usr/sbin/sshd
echo ">>> SSH daemon started"

# Start Open WebUI
echo ">>> Starting Open WebUI on port ${WEBUI_PORT:-3001}"
exec /app/backend/start.sh
