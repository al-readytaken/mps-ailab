## Contents
- [Connection](#connection)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [Usage](#usage)
- [Examples](#examples)
- [Volumes](#volumes)

## Connection

| Service | URL / Command | Port |
|---------|---------------|------|
| Dashboard | http://localhost:9119 | `9119` |
| API | http://localhost:8642/v1 | `8642` |
| SSH | `ssh -p 8888 hermes@localhost` | `8888` |

Click the dashboard link to open the UI, or SSH in for CLI access. The API is OpenAI-compatible.

## Overview

Built from [`nousresearch/hermes-agent:latest`](https://hub.docker.com/r/nousresearch/hermes-agent) with TTS audio deps, SSH server, and a custom entrypoint. Customized via [`Dockerfile`](./Dockerfile) and [`entrypoint.sh`](./entrypoint.sh).

## Requirements

- Docker with at least 4GB RAM and 2 CPUs allocated
- An OpenRouter API key set via `OPENROUTER_API_KEY` in [`./.env`](./.env)
- An SSH public key (optional, for SSH access)
- AMD GPU (optional) — used by the fallback Ollama and LM Studio providers

## Configuration

Set these in [`./.env`](./.env):

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENROUTER_API_KEY` | Yes | — | API key for the OpenRouter LLM provider |
| `HERMES_SSH_PUBKEY` | No | — | Public SSH key for key-only auth |
| `HERMES_DASHBOARD` | No | `0` | Set to `1` to enable the web dashboard |
| `HERMES_DASHBOARD_HOST` | No | `0.0.0.0` | Dashboard bind address |
| `HERMES_DASHBOARD_PORT` | No | `9119` | Dashboard listen port |
| `TELEGRAM_BOT_TOKEN` | No | — | Telegram bot integration token |
| `TELEGRAM_ALLOWED_USERS` | No | — | Comma-separated Telegram usernames |
| `HERMES_UID` | No | `1000` | UID for `/home/hermes/.hermes` ownership |

| `HERMES_GID` | No | `1000` | GID for `/home/hermes/.hermes` ownership |
The [`entrypoint.sh`](./entrypoint.sh) reads these at startup, then drops privileges to the `hermes` user before running the gateway.

## Usage

### Dashboard

Open http://localhost:9119 in a browser. Session tokens are generated automatically.

### API

The gateway exposes an OpenAI-compatible API at http://localhost:8642/v1. Any OpenAI client can point here.

### SSH Access

The container runs an SSH server on port `8888` with key-only authentication.

**Setting up the key:** Set `HERMES_SSH_PUBKEY` in [`./.env`](./.env) with your public key. On first boot, the [`entrypoint.sh`](./entrypoint.sh) writes it to `~/.ssh/authorized_keys` for both `root` and the `hermes` user.

**Logging in:**

```bash
ssh -p 8888 hermes@localhost
ssh -p 8888 root@localhost
```

Once inside, the `chat` command launches the Hermes CLI from `/opt/projects`:

```bash
chat
```

Keys persist across restarts when placed in `/home/hermes/.ssh/` (the `hermes` user's home directory).

### Provider Chain

The container is configured with a three-tier fallback:

| Priority | Provider | Endpoint | Hardware |
|----------|----------|----------|----------|
| 1 (primary) | OpenRouter | `https://api.openrouter.ai/v1` | Cloud |
| 2 (fallback) | Ollama | `http://ollama:11434` | AMD GPU (ROCm) |
| 3 (fallback) | LM Studio | `http://lmstudio:1234/v1` | AMD GPU (Vulkan) |

When OpenRouter is unreachable or rate-limited, requests fall through to local providers.

## Examples

```bash
# SSH into the container
ssh -p 8888 hermes@localhost

# Inside the container, start the CLI
chat

# Test the API from the host
curl -X POST http://localhost:8642/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"ou-mini","messages":[{"role":"user","content":"Hello"}]}'
```

## Volumes

| Volume | Mount | Contents |
|--------|-------|----------|
| `./hermes/config` (bind) | `/home/hermes/.hermes` | Config, sessions, memories, skills, logs (host-editable) |
| `./projects` (bind) | `/opt/projects` | Shared project files (world-writable) |

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| Dashboard returns 404 | `HERMES_DASHBOARD` not set to `1` | Set `HERMES_DASHBOARD=1` in `.env` and restart |
| SSH "Permission denied" | No public key configured | Set `HERMES_SSH_PUBKEY` in `.env` and restart |
| "Session closed" in dashboard | WebSocket / token issue | Refresh page, check `HERMES_DASHBOARD_HOST`/`PORT` |
| TTS playback fails | Missing audio deps | Check container logs for PortAudio errors |