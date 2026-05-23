# Hermes Docker Stack — Architecture Documentation

> **Cross-project info (ports, volumes, networks, provider chain) is duplicated in AGENTS.md and sub-READMEs — keep in sync.**

## Overview

This project deploys **Hermes AI Agent** alongside **Kokoro TTS**, **Ollama LLM**, **LM Studio**, and **Opencode CLI** via Docker Compose. Each service is accessible directly via its native HTTP port — no reverse proxy, no path rewriting.

Each component has its own README with detailed configuration, usage, and examples — see the [Repository Structure](#repository-structure) below.

```
                    ┌─────────────┐
                    │   Browser   │
                    └──────┬──────┘
                           │ HTTP
              ┌────────────┼────────────┬───────────┐
              │            │            │           │
    ┌─────────▼────────┐ ┌─▼─────┐ ┌───▼────────┐ ┌─▼──────────┐
    │  Hermes Agent    │ │ Ollama│ │   Kokoro   │ │ LM Studio  │
    │ :8642 + SSH :8888│ │:11434 │ │  TTS :8880 │ │ :1234      │
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

---

## Services

| Component | README | Container | Host Ports | Key Details |
|-----------|--------|-----------|------------|-------------|
| Hermes Agent | [`hermes/README.md`](./hermes/README.md) | `hermes` | `8642`, `9119`, `8888` | AI gateway + dashboard + SSH, memory 4G/2CPU |
| Ollama | [`ollama/README.md`](./ollama/README.md) | `ollama` | `11434` | Local LLM (CPU/ROCm), auto-pulls models |
| Kokoro TTS | [`kokoro/README.md`](./kokoro/README.md) | `kokoro` | `8880` | Text-to-speech engine, 67 built-in voices |
| Opencode CLI | [`opencode/README.md`](./opencode/README.md) | `opencode` | `9999` | Code assistant CLI (SSH-only) |
| LM Studio | [`lmstudio/README.md`](./lmstudio/README.md) | `lmstudio` | `1234` | Local LLM (Vulkan), headless llmster daemon |

## Provider Chain

The stack configures a three-tier provider chain for Hermes:

| Priority | Provider | Endpoint | Hardware |
|----------|----------|----------|----------|
| 1 (primary) | OpenRouter | `https://api.openrouter.ai/v1` | Cloud |
| 2 (fallback) | Ollama | `http://ollama:11434` | AMD GPU (ROCm) |
| 3 (fallback) | LM Studio | `http://lmstudio:1234/v1` | AMD GPU (Vulkan) |

When OpenRouter is unreachable (network down, rate-limited), Hermes automatically
falls back to Ollama, then LM Studio.

---

## Networking & Ports

### Host → Container Port Mappings

| Host Port | Container | Internal Port | Purpose |
|-----------|-----------|---------------|---------|
| `8642` | hermes | `8642` | Gateway API (OpenAI-compatible) |
| `9119` | hermes | `9119` | Dashboard web UI |
| `8888` | hermes | `22` | SSH access |
| `9999` | opencode | `22` | SSH access |
| `11434` | ollama | `11434` | Ollama API |
| `8880` | kokoro | `8880` | Kokoro TTS API |
| `1234` | lmstudio | `1234` | LM Studio API (OpenAI-compatible) |

### Networks

| Network | Type | Attached Services |
|---------|------|-------------------|
| `backend` | bridge | hermes, ollama, kokoro, opencode, lmstudio |

---

## Access Patterns

This stack has two fundamentally different access patterns depending on the container:

### Pattern A: SSH Containers (CLI-first)

Hermes Agent and Opencode CLI follow this pattern. They have **no HTTP/HTTPS services** — you reach them via SSH:

| Container | SSH Port | Purpose |
|-----------|----------|---------|
| `hermes` | `8888` | AI agent CLI + SSH access to data |
| `opencode` | `9999` | Code assistant CLI |

**How it works:**
1. SSH server is baked into the Docker image (`openssh-server`)
2. Entrypoint reads a public key from an environment variable (`HERMES_SSH_PUBKEY` / `OPENCODE_SSH_PUBKEY`)
3. Before starting sshd, it writes the key to `~/.ssh/authorized_keys`
4. sshd starts with `PubkeyAuthentication yes`, `PasswordAuthentication no`
5. The key is regenerated every boot — survives volume wipes

**Configuration:**
```bash
# hermes/.env
HERMES_SSH_PUBKEY="ssh-rsa AAAA..."

# opencode/.env
OPENCODE_SSH_PUBKEY="ssh-rsa AAAA..."
```

**Convenience:** Inside each container, `chat` is a PATH-installed script that `cd`s to `/opt/projects` and launches the CLI — no need to remember the full binary path.

**Shared volume:** Both containers mount the `projects` volume at `/opt/projects`. Files written by one are instantly visible to the other. This is how they "join work" — same source of truth for project files.

### Pattern B: HTTP Services (Web-first)

Kokoro, Ollama, and LM Studio follow this pattern. They expose HTTP APIs — reach them via `http://localhost:<port>`:

| Service | Direct Port | Purpose |
|---------|-------------|---------|
| Hermes dashboard | `9119` | Dashboard web UI |
| Hermes API | `8642` | OpenAI-compatible API |
| Kokoro | `8880` | TTS API + web UI |
| Ollama | `11434` | LLM API |
| LM Studio | `1234` | OpenAI-compatible API |

**How it works:**
Each service exposes its native port directly on the host. No path rewriting, no prefix confusion, no auth prompts.

---

## URL Routing

| Service | URL | Purpose |
|---------|-----|---------|
| **Hermes dashboard** | `http://localhost:9119` | Dashboard web UI |
| **Hermes API** | `http://localhost:8642` | OpenAI-compatible API |
| **Hermes SSH** | `ssh -p 8888 root@localhost` | SSH into Hermes container |
| **Kokoro TTS** | `http://localhost:8880` | TTS API + web UI |
| **Ollama LLM** | `http://localhost:11434` | LLM API |
| **Opencode SSH** | `ssh -p 9999 root@localhost` | SSH into Opencode container |
| **LM Studio** | `http://localhost:1234` | OpenAI-compatible API |

### Key Endpoints

**Hermes:**
| Endpoint | Expected Status |
|----------|----------------|
| `http://localhost:9119/` | 200 (dashboard) |
| `http://localhost:8642/v1/chat/completions` | 405 (POST-only endpoint exists) |

**Kokoro TTS:**
| Endpoint | Expected Status |
|----------|----------------|
| `http://localhost:8880/health` | 200 |
| `http://localhost:8880/v1/audio/voices` | 200 (67 built-in voices) |
| `POST http://localhost:8880/v1/audio/speech` | 200 (TTS generation) |

**Ollama LLM:**
| Endpoint | Expected Status |
|----------|----------------|
| `GET http://localhost:11434/api/tags` | 200 (list models) |
| `POST http://localhost:11434/api/chat` | 200 (chat completion) |
| `POST http://localhost:11434/api/generate` | 200 (text generation) |

---

## Environment Variables

Each component documents its own config options:

| Component | README |
|-----------|--------|
| Hermes Agent | [`hermes/README.md`](./hermes/README.md#configuration) |
| Opencode CLI | [`opencode/README.md`](./opencode/README.md#configuration) |
| Ollama | [`ollama/README.md`](./ollama/README.md#configuration) |
| LM Studio | [`lmstudio/README.md`](./lmstudio/README.md#configuration) |

Kokoro has no env vars — it runs out of the box.

---

## Volumes

| Volume Name | Mount Point | Contents | Persistence |
|-------------|-------------|----------|-------------|
| `hermes_data` | `/opt/data` | Config, sessions, memories, skills, logs | Named volume |
| `ollama_data` | `/root/.ollama` | Downloaded models | Named volume |
| `kokoro_data` | `/kokoro/voices` | Custom voice data | Named volume |
| `lmstudio_data` | `/root/.cache/lm-studio` | Downloaded models | Named volume |
| `./projects` | `/opt/projects` | Shared project directory | Bind mount |

---

## Repository Structure

```
├── docker-compose.yml          # Orchestration — 5 services
├── .gitignore
├── README.md                   # Quick start + user-facing docs
├── AGENTS.md                   # This file — detailed architecture
├── hermes/
│   ├── README.md               # Dashboard, API, SSH, provider chain
│   ├── .env                    # Configuration (gitignored)
│   ├── .env.example            # Reference config with all keys
│   ├── Dockerfile              # Audio deps, SSH, chat script, custom entrypoint
│   └── scripts/
│       ├── entrypoint.sh       # Bootstrap, dashboard, SSH, privilege drop
│       ├── chat                # PATH-installed CLI shortcut → cd /opt/projects && hermes
│       └── setup-hermes.sh     # One-time: build, provider config
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
└── opencode/
    ├── README.md               # SSH access, key setup, chat usage
    ├── .env                    # SSH pubkey and config (gitignored)
    ├── .env.example            # Reference config with SSH key placeholder
    ├── Dockerfile               # Debian slim + SSH + opencode binary
    └── scripts/
        ├── entrypoint.sh        # Volume setup, SSH key injection, sshd
        └── chat                 # PATH-installed CLI shortcut → cd /opt/projects && opencode
```

---

## Setup & Configuration

### First-time Setup

```bash
docker compose build
docker compose up -d
```

### Ongoing Configuration

- **Environment**: Edit `hermes/.env`, then `docker compose down && docker compose up -d`
- **Ollama models**: Edit `ollama/ollama-models.txt` — auto-detected within 30 seconds

---

## Operational Commands

### Service Lifecycle

```bash
docker compose up -d          # Start all services
docker compose down           # Stop all services
docker compose restart <svc>  # Restart a single service
docker compose ps             # View running services
```

### Logs

```bash
docker compose logs -f        # Follow all logs
docker compose logs -f <svc>  # Follow specific service
docker compose logs --tail=50 | grep -i error   # Recent errors
```

### Access Service Shells

```bash
docker compose exec hermes bash
docker compose exec kokoro sh
docker compose exec ollama sh
docker compose exec opencode sh
```

### SSH Access to Hermes

```bash
ssh -p 8888 root@localhost
ssh -p 8888 hermes@localhost
```

### SSH Access to Opencode

```bash
ssh -p 9999 root@localhost
```

Set `OPENCODE_SSH_PUBKEY` in `opencode/.env` with your public key.

Add your public key to the container's `~/.ssh/authorized_keys` for the user you want to log in as. The key persists across restarts if placed in `/opt/data/.ssh/` (hermes user's home).

### CLI Shortcut (Hermes)

```bash
# Inside the container, the `chat` command runs Hermes CLI from /opt/projects
chat
chat --help
```

### CLI Shortcut (Opencode)

```bash
# Inside the container, the `chat` command runs Opencode CLI from /opt/projects
chat
chat --help
```

### Build & Update

```bash
docker compose build              # Rebuild all images
docker compose build --no-cache hermes   # Rebuild Hermes from scratch
docker compose build --no-cache opencode # Rebuild Opencode from scratch
docker compose pull kokoro        # Pull updated Kokoro image
```

---

## Security Considerations

### Authentication

- **Hermes dashboard**: Generates session tokens automatically (no manual auth)
- **SSH**: Key-only auth (`PasswordAuthentication no`). Add your public key to `~/.ssh/authorized_keys` for the user you want to log in as.
- **Direct ports** (`8642`, `9119`, `8888`, `9999`, `11434`, `8880`, `1234`): Exposed to host — consider firewall rules for production
- **Telegram**: Requires `TELEGRAM_BOT_TOKEN` + `TELEGRAM_ALLOWED_USERS`

### Data

- Named volumes persist sessions, memories, models, and config
- No volume encryption — sensitive data at rest is unprotected
- `docker compose down -v` destroys all data (use with caution)

---

## Testing Connectivity

```bash
# Test all services on their direct ports
for r in http://localhost:9119/ http://localhost:8642/v1/chat/completions http://localhost:8880/health http://localhost:11434/api/tags http://localhost:1234/v1/models; do
  printf '%-45s  ' "$r"
  curl -s -w '%{http_code}\n' -o /dev/null "$r"
done
```

Expected results:
- `http://localhost:9119/` → 200 (dashboard)
- `http://localhost:8642/v1/chat/completions` → 405 (POST-only)
- `http://localhost:8880/health` → 200
- `http://localhost:11434/api/tags` → 200
- `http://localhost:1234/v1/models` → 200

---

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| "Session closed" in dashboard | WebSocket / token | Refresh page, check Hermes config |
| Ollama model not downloading | Bad model name in file | Check spelling in `ollama-models.txt`, check logs |
| Permission errors on volumes | Wrong UID/GID | Set `HERMES_UID`/`HERMES_GID` in `.env` |
| SSH "Permission denied (publickey)" | No authorized key for user | Add your public key to `~/.ssh/authorized_keys` inside container |
| LM Studio model not found | Wrong model name | Check `LMSTUDIO_MODEL` in `lmstudio/.env`, use `lms get` with correct name |
