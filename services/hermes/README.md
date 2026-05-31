# Hermes Agent

AI agent with web UI, memory, and skill system.

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 9119 | HTTP | Web UI (HERMES_PORT_WEB) |
| 22003 | SSH | Remote access (HERMES_PORT_SSH) |

## Usage

### Access Web Interface

Open in browser: [http://localhost:9119](http://localhost:9119)

### First-time Setup

On first usage, Hermes needs to be initialized with two commands:

```bash
# Initialize Hermes
hermes setup

# Setup gateway for external connections
hermes gateway setup
```

### Features

- AI-assisted development
- Persistent memory
- Custom skills
- Multi-platform support (CLI, web, Telegram, Discord)
- Session management

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| HERMES_PORT_WEB | 9119 | Host port for web UI |
| HERMES_PORT_SSH | 22003 | Host port for SSH |
| HERMES_HOSTNAME_WEB | 0.0.0.0 | Web bind address |
| ROOT_PASSWORD | hermes | Root password for SSH access |

### Model Requirements

Hermes requires a model with at least 64K context window. If using a smaller model (like `mistral:7b` with 32K), override in config:

```yaml
# mounts/hermes/.hermes/hermes-agent/config.yaml
model:
  default: mistral:7b
  context_length: 65536  # Override minimum 64K requirement
```

### Data Directory

Hermes data is stored in `mounts/hermes/.hermes/`:
- Config files
- Memory database
- Session history
- Skills

## Dockerfile

Custom Dockerfile extends `debian:bookworm` with:
- OpenSSH server
- Locales (en_US.UTF-8)
- Node.js 22 LTS (for web UI)
- Development tools (vim, curl, git, build-essential, etc.)
- Hermes pre-installed to staging path

## Troubleshooting

### View Logs

```bash
docker compose logs -f hermes
```

### SSH Access

```bash
ssh -p 22003 root@localhost
```

### Reset Hermes

```bash
docker compose down hermes
rm -rf mounts/hermes/.hermes
docker compose up -d hermes
```