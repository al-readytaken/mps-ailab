#!/bin/sh
chown -R appuser:appuser /kokoro/voices 2>/dev/null || true
export HOME=/home/appuser
exec setpriv --reuid=appuser --regid=appuser --init-groups /app/entrypoint.sh "$@"
