#!/bin/bash
set -e

export PATH="/root/.lmstudio/bin:${PATH}"

MODEL="${LMSTUDIO_MODEL:-llama-3.2-1b-instruct}"

lms daemon up

echo "lmstudio-entrypoint: Waiting for daemon to be ready..."
for i in $(seq 1 30); do
  if lms daemon status 2>/dev/null | grep -q "running"; then
    echo "lmstudio-entrypoint: Daemon is ready"
    break
  fi
  sleep 1
done

if [ "${LMSTUDIO_PRELOAD:-false}" = "true" ]; then
  echo "lmstudio: Pre-downloading model ${MODEL}..."
  lms get "$MODEL" 2>&1 || echo "lmstudio: Model download skipped — user can download later"
fi

echo "lmstudio: Starting server on port 1234..."
lms server start --port 1234 --bind 0.0.0.0

echo "lmstudio: Server ready"

exec sleep infinity