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
| API | http://localhost:1234/v1 | `1234` |
| List models | http://localhost:1234/v1/models | — |
| Chat | `POST http://localhost:1234/v1/chat/completions` | — |

The API is OpenAI-compatible — use any OpenAI client pointing to this URL.

## Overview

A headless [LM Studio](https://lmstudio.ai/) deployment running the `llmster` daemon with Vulkan compute for AMD GPU acceleration. Built from [`Dockerfile`](./Dockerfile) (Debian slim + Mesa Vulkan drivers) and [`entrypoint.sh`](./entrypoint.sh). No GUI required.

## Requirements

- Docker
- AMD GPU (optional) — requires `/dev/dri` passthrough and the `video` group. Configured in the parent `docker-compose.yml`. Without these it falls back to CPU.

## Configuration

Set these in [`./.env`](./.env):

| Variable | Default | Description |
|----------|---------|-------------|
| `LMSTUDIO_MODEL` | `llama-3.2-1b-instruct` | Model to pre-download on startup |
| `LMSTUDIO_PRELOAD` | `false` | Whether to download the model at boot |

> **Note:** The default model `llama-3.2-1b-instruct` may not be a valid search term for `lms get`. If preloading fails, set `LMSTUDIO_PRELOAD=false` and download models manually after startup (see [Adding More Models](#adding-more-models)). To find valid model names, run `lms get --help` or browse the LM Studio Hub.

On first startup, if `LMSTUDIO_PRELOAD=true`, the container downloads the configured model. This can take a few minutes depending on the model size. Subsequent starts use the cached model from the volume.

## Usage

LM Studio exposes an OpenAI-compatible API:

- `GET /v1/models` — list available (downloaded) models
- `POST /v1/chat/completions` — chat completions
- `POST /v1/completions` — text completions
- `POST /v1/embeddings` — embeddings

The `llmster` daemon handles the server lifecycle. All requests use the currently loaded model.

### Adding More Models

SSH into the container or use `docker compose exec`:

```bash
docker compose exec lmstudio lms get llama-3.2-3b-instruct
```

## Examples

```bash
# List available models
curl http://localhost:1234/v1/models

# Chat with the loaded model
curl -X POST http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"llama-3.2-1b-instruct","messages":[{"role":"user","content":"Hello"}]}'

# Download a different model
docker compose exec lmstudio lms get qwen2.5-0.5b-instruct
```

## Volumes

| Volume | Mount | Contents |
|--------|-------|----------|
| `lmstudio_data` | `/root/.cache/lm-studio` | Downloaded models and runtime config |

### Verifying GPU Access

```bash
# Check Vulkan device name
docker compose exec lmstudio vulkaninfo 2>&1 | grep "deviceName"

# Check LM Studio logs for GPU backend
docker compose logs lmstudio | grep -i vulkan
```

If no GPU is detected, verify `/dev/dri` passthrough and the `video` group are configured in `docker-compose.yml`.

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| Model not found at API | No model loaded | Check `docker compose logs lmstudio`, download via `lms get <name>` |
| GPU not detected | Missing Vulkan drivers | Verify with `docker compose exec lmstudio vulkaninfo 2>&1 \| grep "deviceName"` |
| Model download fails | Invalid model name | Model name must be a valid `lms get` search term — try partial names |
| Server won't start | Port conflict | Check port 1234 isn't already in use on the host |