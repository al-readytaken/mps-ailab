# lab-llm

Docker Compose stack for local LLM inference with TTS and AI coding agent support.

## Services

| Service | Description | Web Port | SSH Port | Details |
|---------|-------------|----------|----------|---------|
| **kokoro** | Kokoro FastAPI TTS (text-to-speech) | 8880 | 22000 | [README](services/kokoro/README.md) |
| **ollama** | Ollama with ROCm (AMD GPU) | 11434 | 22001 | [README](services/ollama/README.md) |
| **openwebui** | Open WebUI interface for Ollama | 3001 | 22002 | [README](services/openwebui/README.md) |
| **hermes** | Hermes AI agent (web UI + SSH) | 9119 | 22003 | [README](services/hermes/README.md) |
| **opencode** | OpenCode AI coding agent (web UI + SSH) | 4096 | 22004 | [README](services/opencode/README.md) |

## Prerequisites

- Docker & Docker Compose v2
- **For Ollama GPU**: AMD GPU with amdgpu driver loaded (`lsmod | grep amdgpu`)

## Quick Start

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# Follow logs
docker compose logs -f
```

## Configuration

Edit `.env` at the repo root to configure ports and paths:

```env
# ─── Ports ──────────────────────────────────
KOKORO_PORT=8880
KOKORO_PORT_SSH=22000

OLLAMA_PORT=11434
OLLAMA_PORT_SSH=22001

OPENWEBUI_PORT=3001
OPENWEBUI_PORT_SSH=22002

HERMES_PORT_WEB=9119
HERMES_PORT_SSH=22003

OPENCODE_PORT_WEB=4096
OPENCODE_PORT_SSH=22004
```

## SSH Access

All services run SSH daemon on port 22 inside the container, mapped to unique host ports. Add your public key to `common/ssh/authorized_keys`:

```bash
ssh -p 22000 root@localhost  # kokoro
ssh -p 22001 root@localhost  # ollama
ssh -p 22002 root@localhost  # openwebui
ssh -p 22003 root@localhost  # hermes
ssh -p 22004 root@localhost  # opencode
```

## Directory Structure

```
├── docker-compose.yml
├── .env                          # Shared variables (ports, paths)
├── common/
│   └── ssh/
│       ├── authorized_keys       # Public SSH keys
│       └── sshd_config           # Shared SSH config (port 22)
├── mounts/                       # Persistent data
├── scripts/
│   └── ollama-monitor.sh         # Throughput monitor
└── services/
    ├── kokoro/                   # TTS service
    ├── ollama/                   # LLM inference
    ├── openwebui/                # Chat interface
    ├── hermes/                   # AI agent
    └── opencode/                 # Coding agent
```

## Update / Restart

```bash
# After changing .env or models.txt
docker compose up -d

# Rebuild a specific service
docker compose build <service>
docker compose up -d <service>

# Full restart
docker compose down && docker compose up -d
```
