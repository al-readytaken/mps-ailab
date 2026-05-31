# Kokoro TTS

Kokoro FastAPI text-to-speech service.

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 8880 | HTTP | TTS API (KOKORO_PORT) |
| 22000 | SSH | Remote access (KOKORO_PORT_SSH) |

## Usage

### Generate Speech

```bash
curl -s -X POST http://localhost:8880/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Hello world", "voice": "af_heart", "response_format": "wav"}' \
  | paplay
```

### Available Voices

Check available voices with:

```bash
curl http://localhost:8880/v1/voices
```

### Web Interface

Access the API documentation at: [http://localhost:8880](http://localhost:8880)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| KOKORO_PORT | 8880 | Host port for TTS API |
| KOKORO_PORT_SSH | 22000 | Host port for SSH |
| ROOT_PASSWORD | kokoro | Root password for SSH access |

## Dockerfile

Custom Dockerfile extends the base Kokoro image with:
- OpenSSH server
- Locales (en_US.UTF-8)
- Development tools (vim, curl, git, etc.)

## Troubleshooting

### Check Health

```bash
curl http://localhost:8880/health
```

### View Logs

```bash
docker compose logs -f kokoro
```

### SSH Access

```bash
ssh -p 22000 root@localhost
```