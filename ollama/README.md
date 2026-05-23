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
| API | http://localhost:11434 | `11434` |
| List models | http://localhost:11434/api/tags | — |
| Chat | `POST http://localhost:11434/api/chat` | — |

## Overview

Runs [`ollama/ollama:latest`](https://hub.docker.com/r/ollama/ollama) with a custom [`entrypoint.sh`](./entrypoint.sh) that auto-pulls models from a manifest file and watches it for changes every 30 seconds. Supports AMD GPU acceleration via ROCm.

## Requirements

- Docker
- AMD GPU (optional) — requires `/dev/kfd` and `/dev/dri` passthrough, plus the `video` group. Configured in the parent `docker-compose.yml`. Without these, Ollama falls back to CPU.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OLLAMA_MODELS_FILE` | `/opt/ollama-models.txt` | Path to the model manifest file |

The model manifest is bind-mounted as [`ollama-models.txt`](./ollama-models.txt). Edit it to add or remove models:

```text
# One model per line, uncomment to enable
  llama3.2:1b
# llama3.2:3b
# mistral:7b
```

Changes are detected within 30 seconds — no restart needed. The entrypoint runs a background watcher that polls the file and pulls any new models.

## Usage

Ollama exposes its standard API on port `11434`. Key endpoints:

- `GET /api/tags` — list downloaded models
- `POST /api/chat` — chat completion
- `POST /api/generate` — text generation

Clients can use the OpenAI-compatible wrapper at `/v1/`.

## Examples

```bash
# List available models
curl http://localhost:11434/api/tags

# Chat with a model
curl -X POST http://localhost:11434/api/chat \
  -d '{"model":"llama3.2:1b","messages":[{"role":"user","content":"Hello"}]}'

# Add a model at runtime — just edit ollama-models.txt
echo "mistral:7b" >> ollama/ollama-models.txt
# Wait up to 30 seconds for it to auto-pull
```

## Volumes

| Volume | Mount | Contents |
|--------|-------|----------|
| `ollama_data` | `/root/.ollama` | Downloaded models (persistent across restarts) |
| `./ollama-models.txt` (bind) | `/opt/ollama-models.txt:ro` | Model manifest (editable at runtime) |

### Verifying GPU Access

```bash
# Check if ROCm device is detected
docker compose exec ollama rocminfo 2>&1 | head -20

# Check Ollama logs for GPU indicator
docker compose logs ollama | grep -i gpu
```

If no GPU is detected, verify `/dev/kfd` and `/dev/dri` are available on the host and configured in `docker-compose.yml`.

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| Model not downloading | Bad model name in manifest | Check spelling in `ollama-models.txt`, check logs |
| GPU not detected | Missing `/dev/dri` passthrough | Verify `devices` and `group_add` in docker-compose.yml |
| Slow response | CPU fallback | Check GPU access with `docker compose exec ollama rocminfo` |