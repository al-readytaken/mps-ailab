# AGENTS.md

Reference for AI agents working on this codebase.

## What This Is

Docker Compose stack for local LLM inference with TTS and AI coding agent support. Five services, all with SSH access, sharing a common projects directory.

## Stack

```
docker-compose.yml          # Orchestrates all services
.env                        # Central config (ports, paths)
common/ssh/                 # Shared SSH keys + sshd_config
mounts/                     # Persistent data (models, configs, memory)
scripts/                    # Utility scripts (ollama-monitor.sh)
services/                   # One folder per service (Dockerfile, .env, entrypoint)
```

## Services

| Service | Base Image | Web | SSH | What |
|---------|-----------|-----|-----|------|
| **kokoro** | Kokoro FastAPI | 8880 | 22000 | Text-to-speech |
| **ollama** | `ollama/ollama:rocm` | 11434 | 22001 | LLM inference (AMD GPU) |
| **openwebui** | `ghcr.io/open-webui/open-webui:0.6.10` | 3001 | 22002 | Chat UI for Ollama |
| **hermes** | `debian:bookworm` | 9119 | 22003 | AI agent (memory, skills) |
| **opencode** | `debian:bookworm` | 4096 | 22004 | AI coding agent |

## Dependencies

- **openwebui** → **ollama** (starts only after ollama is healthy)
- All others are independent

## GPU

Only **ollama** uses GPU. Requires:
- AMD GPU with `amdgpu` driver (`lsmod | grep amdgpu`)
- Devices: `/dev/kfd`, `/dev/dri`
- Groups: `44`, `992`
- Env: `HSA_OVERRIDE_GFX_VERSION=12.0.0`

## Per-Service Details

### Kokoro (TTS)
- API: `POST /v1/audio/speech` — `{input, voice, response_format}`
- Voices: `GET /v1/voices`
- Health: `GET /health`
- Web: [http://localhost:8880](http://localhost:8880)

### Ollama (LLM)
- Models auto-pulled on startup from `services/ollama/models.txt`
- Supports Ollama library + HuggingFace GGUF (`hf.co/<user>/<repo>`)
- Interactive: `docker exec -it ollama ollama run <model>`
- Monitor: `./scripts/ollama-monitor.sh [interval] [model]`
- Health: `ollama list`
- API: [http://localhost:11434](http://localhost:11434)

### Open WebUI
- Chat, model management, conversation history, RAG, image generation
- Health: `GET /api/health`
- Web: [http://localhost:3001](http://localhost:3001)

### Hermes (Agent)
- Persistent memory, custom skills, multi-platform (CLI, web, Telegram, Discord)
- Requires model with ≥64K context window (override in `mounts/hermes/.hermes/hermes-agent/config.yaml`)
- Data: `mounts/hermes/.hermes/`
- Web: [http://localhost:9119](http://localhost:9119)
- First-time setup: `hermes setup` and `hermes gateway setup`

### OpenCode (Coding Agent)
- Code generation, refactoring, debugging, file operations
- Config: `mounts/opencode/`
- SSH usage: `ssh -p 22004 root@localhost` then run `opencode`

## Common Patterns

- **Dockerfiles**: base image + OpenSSH + locales (`en_US.UTF-8`) + dev tools (`vim`, `curl`, `git`, `build-essential`)
- **Entrypoints**: each service has `scripts/entrypoint.bash`
- **SSH**: all containers expose port 22, mapped to unique host ports via `common/ssh/authorized_keys`
- **Projects**: all containers mount `${PROJECTS_DIR}` at `/opt/projects`

## Commands

```bash
docker compose up -d                    # Start all
docker compose ps                       # Status
docker compose logs -f                  # Follow logs
docker compose logs -f <service>        # Logs for one service
docker compose build <service>          # Rebuild one service
docker compose down && docker compose up -d  # Full restart
```

## SSH Access

```bash
ssh -p 22000 root@localhost  # kokoro
ssh -p 22001 root@localhost  # ollama
ssh -p 22002 root@localhost  # openwebui
ssh -p 22003 root@localhost  # hermes
ssh -p 22004 root@localhost  # opencode
```

## Modifying This Stack

- **Change ports/paths**: edit `.env` at repo root
- **Add models**: edit `services/ollama/models.txt`
- **Change SSH keys**: edit `common/ssh/authorized_keys`
- **Change service config**: edit the service's `.env` or `scripts/entrypoint.bash`
- **Persistent data**: lives under `mounts/` — removing a subfolder resets that service's state

## Gotchas

- Ollama healthcheck has `start_period: 120s` — it takes time to load models
- Open WebUI won't start until Ollama is healthy — if Ollama is slow, Open WebUI is delayed
- Hermes requires ≥64K context window models — smaller models need explicit override
- All containers run as `root`
- Models are pulled once on startup via `models.txt` — not automatically updated
