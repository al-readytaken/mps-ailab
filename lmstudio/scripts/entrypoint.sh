#!/bin/bash
set -e

export PATH="/root/.lmstudio/bin:${PATH}"

MODEL="${LMSTUDIO_MODEL:-llama-3.2-1b-instruct}"

lms daemon up

if [ "${LMSTUDIO_PRELOAD:-false}" = "true" ]; then
  echo "lmstudio: Pre-downloading model ${MODEL}..."
  lms get "$MODEL" 2>&1 || echo "lmstudio: Model download skipped — user can download later"
fi

echo "lmstudio: Starting server on port 1234..."
lms server start --port 1234 --bind 0.0.0.0

echo "lmstudio: Server ready"

tail -f /dev/null