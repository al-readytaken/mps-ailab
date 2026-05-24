#!/bin/bash
set -e

MODELS_FILE="${OLLAMA_MODELS_FILE:-/opt/ollama-models.txt}"

# Start ollama serve in background
/bin/ollama serve &
OLLAMA_PID=$!

# Wait for ollama to be ready
echo "ollama-entrypoint: Waiting for ollama to be ready..."
for i in $(seq 1 30); do
  if /bin/ollama list >/dev/null 2>&1; then
    echo "ollama-entrypoint: Ollama is ready"
    break
  fi
  sleep 1
done

# Sync models from file — pulls any listed models not already present
sync_models() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "ollama-entrypoint: Models file $file not found, skipping"
    return
  fi
  grep -v '^\s*#' "$file" | grep -v '^\s*$' | while IFS= read -r model; do
    model="${model//[[:space:]]/}"
    [ -z "$model" ] && continue
    if ! /bin/ollama list 2>/dev/null | grep -qi "^${model}\s"; then
      echo "ollama-entrypoint: Pulling model: $model"
      /bin/ollama pull "$model"
    fi
  done
}

# Initial sync if file exists
if [ -f "$MODELS_FILE" ]; then
  sync_models "$MODELS_FILE"
  LAST_HASH=$(sha256sum "$MODELS_FILE" 2>/dev/null || echo "")
else
  LAST_HASH=""
fi

# Background watcher — polls for changes and syncs
(
  while true; do
    sleep 30
    if [ ! -f "$MODELS_FILE" ]; then
      continue
    fi
    NEW_HASH=$(sha256sum "$MODELS_FILE" 2>/dev/null || echo "")
    if [ "$NEW_HASH" != "$LAST_HASH" ]; then
      echo "ollama-entrypoint: Models file changed, syncing..."
      sync_models "$MODELS_FILE"
      LAST_HASH="$NEW_HASH"
    fi
  done
) &

# Wait for ollama serve to exit
wait $OLLAMA_PID
