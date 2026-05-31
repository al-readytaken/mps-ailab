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

# Start Ollama server in background
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_CONTEXT_LENGTH=128000 
/bin/ollama serve &
SERVER_PID=$!

# Wait for server to be ready
echo ">>> Waiting for Ollama server..."
for i in $(seq 1 30); do
  if /bin/ollama list >/dev/null 2>&1; then
    echo ">>> Server ready"
    break
  fi
  sleep 1
done

# Pull models from models.txt
if [ -f /models.txt ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    line="$(echo "$line" | xargs)"
    [ -z "$line" ] && continue
    [[ "$line" == \#* ]] && continue

    echo ">>> Pulling model: $line"
    /bin/ollama pull "$line"
  done </models.txt
fi

# Run instance
/bin/ollama run "qwen3.5:9b" &

# Bring server to foreground
wait $SERVER_PID
