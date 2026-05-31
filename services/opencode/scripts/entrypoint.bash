#!/bin/bash
set -e

# Copy and secure authorized_keys
if [ -f /tmp/authorized_keys ]; then
  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  cp /tmp/authorized_keys /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  chown root:root /root/.ssh/authorized_keys
fi

# Install OpenCode into the bind mount if not already present
if [ ! -f /root/.opencode/bin/opencode ]; then
  echo ">>> Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  echo ">>> OpenCode installed"
fi

# Ensure symlink exists on every start (bind mount can lose it on rebuild)
ln -sf /root/.opencode/bin/opencode /usr/local/bin/opencode

# Set root password from environment variable
if [ -n "$ROOT_PASSWORD" ]; then
  echo "root:$ROOT_PASSWORD" | chpasswd
fi

# Start OpenCode web UI in the background
/root/.opencode/bin/opencode --hostname "$OPENCODE_HOSTNAME_WEB" web &

# Start SSH daemon
exec /usr/sbin/sshd -D
