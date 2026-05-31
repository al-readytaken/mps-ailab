# OpenCode

AI coding agent with web UI and SSH access.

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 4096 | HTTP | Web UI (OPENCODE_PORT_WEB) |
| 22004 | SSH | Remote access (OPENCODE_PORT_SSH) |

## Usage

### Access Web Interface

Open in browser: [http://localhost:4096](http://localhost:4096)

### SSH Usage

Connect via SSH and run opencode directly:

```bash
# Connect to the container
ssh -p 22004 root@localhost

# Run opencode interactively
opencode

# Or run a single prompt
opencode "explain this codebase"
```

### Features

- AI-assisted coding
- Code generation
- Refactoring
- Debugging
- File operations

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| OPENCODE_PORT_WEB | 4096 | Host port for web UI |
| OPENCODE_PORT_SSH | 22004 | Host port for SSH |
| OPENCODE_HOSTNAME_WEB | 0.0.0.0 | Web bind address |
| ROOT_PASSWORD | opencode | Root password for SSH access |

### Projects Directory

Projects are mounted at `/opt/projects` inside the container.

## Dockerfile

Custom Dockerfile extends `debian:bookworm` with:
- OpenSSH server
- Locales (en_US.UTF-8)
- Development tools (vim, curl, git, build-essential, etc.)

## Troubleshooting

### View Logs

```bash
docker compose logs -f opencode
```

### SSH Access

```bash
ssh -p 22004 root@localhost
```