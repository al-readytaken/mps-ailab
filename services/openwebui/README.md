# Open WebUI

Web-based chat interface for Ollama.

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 3001 | HTTP | Web UI (OPENWEBUI_PORT) |
| 22002 | SSH | Remote access (OPENWEBUI_PORT_SSH) |

## Usage

### Access Web Interface

Open in browser: `http://localhost:3001`

### Features

- Chat with any Ollama model
- Model management
- Conversation history
- RAG support
- Image generation

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| OPENWEBUI_PORT | 3001 | Host port for web UI |
| OPENWEBUI_PORT_SSH | 22002 | Host port for SSH |
| ROOT_PASSWORD | openwebui | Root password for SSH access |
| OLLAMA_BASE_URL | http://ollama:11434 | Ollama API endpoint |
| WEBUI_PORT | 3001 | Internal web port |

## Dockerfile

Custom Dockerfile extends `ghcr.io/open-webui/open-webui:0.6.10` with:
- OpenSSH server
- Locales (en_US.UTF-8)
- Development tools (vim, curl, git, etc.)

## Troubleshooting

### Check Health

```bash
curl http://localhost:3001/health
```

### View Logs

```bash
docker compose logs -f openwebui
```

### SSH Access

```bash
ssh -p 22002 root@localhost
```

### Rebuild

```bash
docker compose build openwebui
docker compose up -d openwebui
```