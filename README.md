# Hermes Docker Stack

A complete Docker-based deployment of **Hermes AI Agent** alongside **Kokoro TTS**, **Ollama LLM**, **LM Studio**, and **Opencode CLI** — all accessible via their native ports.

Each component has its own README with detailed docs — see the [Repository Structure](#repository-structure) below.

## Services

| Service | Description | Access |
|---------|-------------|--------|
| **Hermes Agent** | AI agent gateway with dashboard and SSH | HTTP :8642 (API) + :9119 (dashboard) + SSH :2222 |
| **Opencode CLI** | Code assistant CLI with SSH | SSH :9999 |
| **Kokoro TTS** | Text-to-speech engine | HTTP :8880 |
| **Ollama LLM** | LLM server (CPU / AMD ROCm) | HTTP :11434 |
| **LM Studio** | OpenAI-compatible LLM (AMD Vulkan) | HTTP :1234 |

## Quick Start

```bash
# One-time setup (certs, build, provider config)
./hermes/scripts/setup-hermes.sh

# Configure API keys and SSH keys in .env files
#   hermes/.env    → OPENROUTER_API_KEY, HERMES_SSH_PUBKEY
#   opencode/.env  → OPENCODE_SSH_PUBKEY

# Start everything
docker compose up -d
```

## Architecture

```
                    ┌─────────────┐
                    │   Browser   │
                    └──────┬──────┘
                           │ HTTP
              ┌────────────┼────────────┬───────────┐
              │            │            │           │
    ┌─────────▼────────┐ ┌─▼─────┐ ┌───▼────────┐ ┌─▼──────────┐
    │  Hermes Agent    │ │ Ollama│ │   Kokoro   │ │ LM Studio  │
    │ :8642+SSH :2222  │ │:11434 │ │  TTS :8880 │ │ :1234      │
    │ dashboard :9119  │ │       │ │            │ │            │
    └─────────┬────────┘ └───────┘ └────────────┘ └────────────┘
              │
         hermes_data
        (persistent)
          projects
        (shared vol.)
              │
    ┌─────────▼────────┐
    │   Opencode CLI   │
    │   SSH port 9999  │
    └──────────────────┘
          projects
        (shared vol.)
```

## Access

### SSH Containers (Hermes & Opencode)

```bash
# SSH into Hermes
ssh -p 2222 root@localhost

# SSH into Opencode
ssh -p 9999 root@localhost
```

SSH public keys are injected via environment variables before sshd starts:
- `HERMES_SSH_PUBKEY` in `hermes/.env`
- `OPENCODE_SSH_PUBKEY` in `opencode/.env`

Inside each container, the `chat` command launches the CLI from `/opt/projects`:
```bash
chat
```

### HTTP Services

| Host Port | Container | Service |
|-----------|-----------|---------|
| `8642` | hermes | Gateway API (OpenAI-compatible) |
| `9119` | hermes | Dashboard web UI |
| `8880` | kokoro | TTS API |
| `11434` | ollama | LLM API |
| `1234` | lmstudio | OpenAI-compatible API (LLM via Vulkan) |

## Configuration

Each component has its own documentation with all available options:

- [`hermes/README.md`](./hermes/README.md) — Hermes env vars, TTS, SSH, provider chain
- [`opencode/README.md`](./opencode/README.md) — Opencode SSH setup
- [`ollama/README.md`](./ollama/README.md) — Ollama model manifest, GPU setup
- [`kokoro/README.md`](./kokoro/README.md) — Kokoro TTS API
- [`lmstudio/README.md`](./lmstudio/README.md) — LM Studio model config, GPU setup

### Direct Port Access

Every service exposes its native port directly on `localhost`. Zero path rewriting, zero prefix confusion:

| Service | URL | Port | Purpose |
|---------|-----|------|---------|
| **Hermes dashboard** | `http://localhost:9119` | `9119` | Dashboard web UI |
| **Hermes API** | `http://localhost:8642` | `8642` | OpenAI-compatible API |
| **Hermes SSH** | `ssh -p 2222 root@localhost` | `2222` | SSH into Hermes container |
| **Kokoro TTS** | `http://localhost:8880` | `8880` | TTS API + web UI |
| **Ollama LLM** | `http://localhost:11434` | `11434` | LLM API |
| **Opencode SSH** | `ssh -p 9999 root@localhost` | `9999` | SSH into Opencode container |
| **LM Studio** | `http://localhost:1234` | `1234` | OpenAI-compatible API |

No auth prompts. No path rewriting. No CSP issues. Just the service as it was designed to work.

### Shared Project Directory

Both Hermes and Opencode mount `./projects` from the host at `/opt/projects`. Files you put in `hermes-docker/projects/` are instantly visible inside both containers and vice versa. No copying needed.

## Repository Structure

```
├── docker-compose.yml        # Orchestration — 5 services
├── .gitignore
├── README.md                 # This file — quick start
├── AGENTS.md                 # Architecture docs (cross-project)
├── hermes/
│   ├── README.md               # Dashboard, API, SSH, provider chain
│   ├── .env                    # Configuration (gitignored)
│   ├── .env.example            # Reference config with all keys
│   ├── Dockerfile              # Audio deps, SSH, chat script, custom entrypoint
│   └── scripts/
│       ├── entrypoint.sh       # Bootstrap, dashboard, SSH, privilege drop
│       ├── chat                # PATH-installed CLI shortcut → cd /opt/projects && hermes
│       └── setup-hermes.sh     # One-time: build, provider config
├── opencode/
│   ├── README.md               # SSH access, key setup, chat usage
│   ├── .env                    # SSH pubkey (gitignored)
│   ├── .env.example            # Reference config with SSH key placeholder
│   ├── Dockerfile              # Debian slim + SSH + opencode binary
│   └── scripts/
│       ├── entrypoint.sh       # Volume setup, SSH key injection, sshd
│       └── chat                # PATH-installed CLI shortcut → cd /opt/projects && opencode
├── kokoro/
│   ├── README.md               # TTS API, voices, usage
│   ├── Dockerfile              # No proxy patches — serves at root :8880
│   └── scripts/
│       └── entrypoint.sh       # Permission fix + privilege drop
├── ollama/
│   ├── README.md               # API, model manifest, GPU setup
│   ├── Dockerfile              # Custom entrypoint + AMD GPU
│   ├── ollama-models.txt       # Model manifest (editable at runtime)
│   └── scripts/
│       └── entrypoint.sh       # Auto-download + background watcher
├── lmstudio/
│   ├── README.md               # API, model download, GPU setup
│   ├── .env                    # Model config (gitignored)
│   ├── .env.example            # Reference config with model defaults
│   ├── Dockerfile              # Vulkan + llmster install
│   └── scripts/
│       └── entrypoint.sh       # Daemon startup + model preload
```

## Operations

```bash
# Start / stop / restart
docker compose up -d
docker compose down
docker compose restart <service>

# Logs
docker compose logs -f
docker compose logs -f <service>

# Rebuild images
docker compose build
docker compose build --no-cache hermes
docker compose build --no-cache opencode

# Access service shells
docker compose exec hermes bash
docker compose exec opencode sh
docker compose exec kokoro sh
docker compose exec ollama sh
```

## Security

- **SSH**: Key-only auth (`PasswordAuthentication no`). Inject your public key via `*_SSH_PUBKEY` env vars.
- **Direct ports** (`8642`, `9119`, `2222`, `9999`, `11434`, `8880`, `1234`): Exposed to host — consider firewall rules for production.
- **Data**: Named volumes for persistence. `docker compose down -v` destroys all data.

## Testing

```bash
# Test all services on their direct ports
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:9119/
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8642/v1/chat/completions
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8880/health
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:11434/api/tags
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| SSH "Permission denied (publickey)" | Set `*_SSH_PUBKEY` in the container's `.env` and restart |
| Ollama model not downloading | Check model name in `ollama-models.txt`, check logs |
