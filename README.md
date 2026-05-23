# Hermes Docker Stack

A complete Docker-based deployment of Hermes AI Agent with integrated backends:

- **Hermes AI Agent** - Central gateway with dashboard
- **Kokoro TTS** - Text-to-speech engine  
- **Ollama LLM** - Large language model server
- **Nginx** - Reverse proxy with TLS termination

All services are accessible through a single HTTPS entry point with proper path routing.

## 🏗️ Architecture

```
                    ┌─────────────┐
                    │   Browser   │
                    └──────┬──────┘
                           │ HTTPS (443)
                    ┌──────▼──────┐
                    │             │
                    │   Nginx     │
                    │  Reverse    │
                    │   Proxy     │
                    │             │
                    └─┬────┬────┬─┘
                      │    │    │
          ┌───────────┘    │    └────────────┐
          │                │                 │
┌─────────▼────────┐ ┌─────▼──────┐ ┌────────▼────────┐
│                  │ │            │ │                 │
│  Hermes Agent    │ │   Ollama   │ │     Kokoro      │
│ (LLM Gateway)    │ │ (LLM API)  │ │   (TTS API)     │
│                  │ │            │ │                 │
└──────────────────┘ └────────────┘ └─────────────────┘
```

## 🚀 Quick Start

1. **One-time setup:**
   ```bash
   ./hermes/scripts/setup-hermes.sh
   ```

2. **Start the stack:**
   ```bash
   docker compose up -d
   ```

3. **Access services:**
   - Hermes Dashboard: https://localhost/hermes/
   - Kokoro TTS: https://localhost/kokoro/
   - Ollama API: https://localhost/ollama/

## 📁 Repository Structure

```
├── docker-compose.yml        # Orchestration file
├── .gitignore
├── README.md
├── AGENTS.md                 # Detailed architecture docs
├── hermes/
│   ├── .env                  # Configuration (gitignored)
│   ├── Dockerfile            # Extends upstream image
│   ├── entrypoint.sh         # Runtime setup
│   └── scripts/
│       └── setup-hermes.sh   # One-time setup script
├── kokoro/
│   ├── Dockerfile            # Fixes volume permissions
│   └── entrypoint.sh         # Permission fix + privilege drop
├── ollama/
│   ├── Dockerfile            # Custom entrypoint
│   ├── entrypoint.sh         # Model auto-downloader
│   └── ollama-models.txt     # Models to auto-download
└── nginx/
    ├── dashboard.conf        # Reverse proxy config
    └── certs/                # TLS certificates (gitignored)
```

## ⚙️ Configuration

### Environment Variables

Edit `hermes/.env` before first run:

```bash
# API Keys
OPENROUTER_API_KEY=your-openrouter-key

# Dashboard Settings
HERMES_DASHBOARD=1
HERMES_DASHBOARD_HOST=0.0.0.0
HERMES_DASHBOARD_PORT=9119

# Telegram Integration
TELEGRAM_BOT_TOKEN=your-telegram-token
TELEGRAM_ALLOWED_USERS=your-username

# Container Permissions
HERMES_UID=10000
HERMES_GID=10000
```

### Ollama Models

Edit `ollama/ollama-models.txt` to specify which models to auto-download:

```txt
# Uncomment lines to auto-download models
# llama3.2:1b
# llama3.2:3b
# mistral:7b
```

Changes are detected every 30 seconds without restart.

## 🌐 URL Routing

| Path | Service | Purpose |
|------|---------|---------|
| `https://localhost/hermes/` | Hermes | Dashboard + assets |
| `https://localhost/api/` | Hermes | API + WebSocket endpoints |
| `https://localhost/kokoro/` | Kokoro | TTS API + web UI |
| `https://localhost/ollama/` | Ollama | LLM API |

### Key Endpoints

**Hermes:**
- Dashboard: `https://localhost/hermes/`
- API Status: `https://localhost/api/status`
- Sessions: `https://localhost/api/sessions`

**Kokoro TTS:**
- Voices: `https://localhost/kokoro/v1/audio/voices`
- Speech: `https://localhost/kokoro/v1/audio/speech`
- Health: `https://localhost/kokoro/health`

**Ollama LLM:**
- Models: `https://localhost/ollama/api/tags`
- Chat: `https://localhost/ollama/api/chat`
- Generate: `https://localhost/ollama/api/generate`

## 🛠️ Setup Scripts

### `hermes/scripts/setup-hermes.sh`

One-time setup script that:
1. Generates self-signed TLS certificates
2. Builds Hermes Docker image
3. Configures OpenRouter as default provider
4. Sets API keys from `hermes/.env`

```bash
# Run once before first use
./hermes/scripts/setup-hermes.sh
```

### `docker compose` Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Rebuild images after Dockerfile changes
docker compose build

# Restart specific service
docker compose restart hermes
```

## 🔧 Operational Commands

### Service Management

```bash
# View running services
docker compose ps

# Access service shells
docker compose exec hermes bash
docker compose exec nginx sh
docker compose exec kokoro sh
docker compose exec ollama sh

# View service logs
docker compose logs hermes
docker compose logs nginx
docker compose logs kokoro
docker compose logs ollama
```

### Configuration Updates

```bash
# Update environment variables
# 1. Edit hermes/.env
# 2. Restart services
docker compose down && docker compose up -d

# Update Ollama models
# 1. Edit ollama/ollama-models.txt
# 2. Models auto-download within 30 seconds

# Update TLS certificates
# 1. Replace nginx/certs/fullchain.pem
# 2. Replace nginx/certs/privkey.pem
# 3. Restart nginx
docker compose restart nginx
```

## 🔒 Security

### TLS Certificates

Default self-signed certificates are generated by `setup-hermes.sh`:
- `nginx/certs/fullchain.pem` - Certificate chain
- `nginx/certs/privkey.pem` - Private key

Replace with production certificates for real deployments.

### API Authentication

- Hermes dashboard generates session tokens automatically
- Ollama and Kokoro APIs are protected by the reverse proxy
- Telegram integration requires bot token and allowed users

## 🧪 Testing Connectivity

```bash
# Test all routes
for r in /hermes/ /api/status /kokoro/health /ollama/api/tags; do
  printf '%-25s  ' "https://localhost$r"
  curl -sko /dev/null -w '%{http_code}\n' "https://localhost$r"
done

# Test Hermes WebSocket
curl -sk -I https://localhost/api/ws

# Test Ollama models
curl -sk https://localhost/ollama/api/tags | jq '.models[].name'
```

## 📦 Model Downloads

### Ollama Models

Models are automatically downloaded based on `ollama/ollama-models.txt`:
1. Edit the file to uncomment desired models
2. Changes detected within 30 seconds
3. Models download automatically in background

Popular models:
- `llama3.2:1b` - Small, fast model (default)
- `llama3.2:3b` - Balanced performance
- `mistral:7b` - High capability
- `phi3:3.8b` - Microsoft's efficient model

### Kokoro Voices

Kokoro includes 67 built-in voices. List available voices:
```bash
curl -sk https://localhost/kokoro/v1/audio/voices | jq
```

## 🚨 Troubleshooting

### Common Issues

**"Session closed" in Hermes dashboard:**
- Refresh the page to get new session token
- Check WebSocket connectivity in browser console
- Verify nginx `/api/` route configuration

**Ollama model not downloading:**
- Check `ollama/ollama-models.txt` format
- Verify model name spelling
- Check ollama logs: `docker compose logs ollama`

**TLS certificate errors:**
- Use `-k` flag with curl for self-signed certs
- Replace with valid certificates for production
- Restart nginx after certificate changes

**Permission errors with volumes:**
- Check `HERMES_UID`/`HERMES_GID` in `.env`
- Verify file ownership in containers
- Use named volumes for persistent data

### Log Inspection

```bash
# View recent errors
docker compose logs --tail=50 | grep -i error

# Follow specific service logs
docker compose logs -f hermes

# Export logs for debugging
docker compose logs > hermes-stack-logs.txt
```

## 🔄 Maintenance

### Updates

```bash
# Update Hermes to latest version
docker compose build --no-cache hermes

# Update Kokoro (if using different image)
docker compose pull kokoro

# Update Ollama
docker compose pull ollama
```

### Data Management

```bash
# Backup Hermes data
docker compose down
tar -czf hermes-backup-$(date +%Y%m%d).tar.gz hermes_data/

# Restore Hermes data
tar -xzf hermes-backup-*.tar.gz
docker compose up -d

# Reset all data (CAUTION: destroys all data)
docker compose down -v
```

## 📚 Additional Resources

- [Hermes Agent Documentation](https://github.com/lemonhx/hermes)
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Kokoro TTS Documentation](https://github.com/remsky/kokoro-fastapi)
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)