## Contents
- [Connection](#connection)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [Usage](#usage)
- [Examples](#examples)
- [Volumes](#volumes)

## Connection

| Access | URL | Port |
|--------|-----|------|
| API | http://localhost:8880 | `8880` |
| Health check | http://localhost:8880/health | — |
| List voices | http://localhost:8880/v1/audio/voices | — |
| TTS | `POST http://localhost:8880/v1/audio/speech` | — |

Click any URL to test in your browser, or use `curl`.

## Overview

Runs [`ghcr.io/remsky/kokoro-fastapi-cpu`](https://github.com/remsky/Kokoro-FastAPI) — a lightweight TTS engine with 67 built-in voices. The [`Dockerfile`](./Dockerfile) and [`entrypoint.sh`](./entrypoint.sh) handle privilege drop only; no path rewriting patches are applied. The service serves at root.

## Requirements

- Docker
- CPU only — no GPU needed

## Configuration

No environment variables. The container runs out of the box with default voices.

## Usage

Kokoro exposes a FastAPI server with voice listing and speech generation:

- `GET /health` — readiness check
- `GET /v1/audio/voices` — list 67 built-in voices (returns JSON)
- `POST /v1/audio/speech` — generate speech from text (returns audio)

The API is OpenAI TTS-compatible. The upstream web UI is also available at the root URL.

## Examples

```bash
# Health check
curl http://localhost:8880/health

# List all voices
curl http://localhost:8880/v1/audio/voices | jq '.[:3]'

# Generate speech (saves to output.mp3)
curl -X POST http://localhost:8880/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"model":"kokoro","input":"Hello world","voice":"af_heart"}' \
  -o output.mp3
```

## Volumes

| Volume | Mount | Contents |
|--------|-------|----------|
| `kokoro_data` | `/kokoro/voices` | Custom voice data (optional) |

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| Health check returns non-200 | Container not ready | Wait a few seconds, check `docker compose logs kokoro` |
| Voice not found | Invalid voice name | Run `GET /v1/audio/voices` to list 67 built-in voices |
| TTS output is silent | Invalid `model` or `input` | Ensure JSON uses `{"model":"kokoro","input":"text","voice":"af_heart"}` |
