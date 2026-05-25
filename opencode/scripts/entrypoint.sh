#!/bin/bash
set -e

# Create shared projects volume
mkdir -p /opt/projects
chmod a+rwX /opt/projects

# Create configuration directory for Opencode
CONFIG_DIR=/root/.config/opencode
mkdir -p "$CONFIG_DIR"

# Ensure claude-mem plugin registration exists (build installs to image,
# but config dir is volume-mounted and may hide it at runtime)
if [ ! -f "$CONFIG_DIR/plugins/claude-mem.js" ]; then
  echo "opencode: Installing claude-mem plugin registration..."
  mkdir -p "$CONFIG_DIR/plugins"
  npx --yes claude-mem@13.3.0 install --ide opencode >/dev/null 2>&1 || true
fi

# Fix permissions on config volume so host user can edit files
if [ "$(id -u)" = "0" ]; then
  OPENCODE_UID=${OPENCODE_UID:-1000}
  OPENCODE_GID=${OPENCODE_GID:-1000}
  getent passwd "$OPENCODE_UID" >/dev/null 2>&1 &&
    chown -R "$OPENCODE_UID:$OPENCODE_GID" "$CONFIG_DIR" ||
    chmod -R a+rwX "$CONFIG_DIR"
fi

# Inject OpenRouter API key into opencode auth store
AUTH_DIR=/root/.local/share/opencode
if [ -n "${OPENROUTER_API_KEY}" ]; then
  mkdir -p "$AUTH_DIR"
  cat >"$AUTH_DIR/auth.json" <<EOF
{
  "openrouter": {
    "type": "api",
    "key": "${OPENROUTER_API_KEY}"
  }
}
EOF
  chmod 600 "$AUTH_DIR/auth.json"
fi

# Generate SSH host keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
  ssh-keygen -A
fi

# Setup authorized keys
if [ -n "${OPENCODE_SSH_PUBKEY}" ]; then
  mkdir -p /root/.ssh
  echo "$OPENCODE_SSH_PUBKEY" >/root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
fi

# Start SSH server
if [ -x /usr/sbin/sshd ]; then
  /usr/sbin/sshd
fi

# Run the command (sleep infinity by default)
exec "$@"
