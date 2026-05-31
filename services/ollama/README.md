# Ollama LLM

Ollama local LLM inference server with AMD GPU (ROCm) support.

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 11434 | HTTP | Ollama API (OLLAMA_PORT) |
| 22001 | SSH | Remote access (OLLAMA_PORT_SSH) |

## Usage

### Generate Text

```bash
curl http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "gemma4:e2b", "prompt": "Hello!", "stream": false}'
```

### Interactive Chat

```bash
docker exec -it ollama ollama run gemma4:e2b
```

### List Models

```bash
docker compose exec ollama ollama list
```

### Pull Model

```bash
docker compose exec ollama ollama pull llama3.2
```

### API Access

Access the Ollama API at: [http://localhost:11434](http://localhost:11434)

## Configuration

### Models

Edit `models.txt` to auto-pull models on startup:

```
# One per line. Lines starting with # are ignored.
qwen2.5-coder:7b
qwen2.5-coder:14b
llama3.2:3b
gemma4:e2b
mistral:7b
tinyllama:latest
```

Supports:
- **Ollama library models**: `llama3.2`, `tinyllama`, etc.
- **HuggingFace GGUF repos**: `hf.co/<user>/<repo>`

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| OLLAMA_PORT | 11434 | Host port for API |
| OLLAMA_PORT_SSH | 22001 | Host port for SSH |
| ROOT_PASSWORD | ollama | Root password for SSH access |
| OLLAMA_HOST | 0.0.0.0 | Bind address |
| HSA_OVERRIDE_GFX_VERSION | 12.0.0 | AMD GPU version |

### GPU Requirements

- AMD GPU with `amdgpu` driver loaded
- Check driver: `lsmod | grep amdgpu`
- Devices: `/dev/kfd`, `/dev/dri`

## Dockerfile

Custom Dockerfile extends `ollama/ollama:rocm` with:
- OpenSSH server
- Locales (en_US.UTF-8)
- Development tools (vim, curl, git, build-essential, etc.)

## Monitoring

### Throughput Monitor

```bash
./scripts/ollama-monitor.sh [interval_seconds] [model]
# Example: ./scripts/ollama-monitor.sh 10 gemma4:e2b
```

### Running Models

```bash
docker compose exec ollama ollama ps
```

### Resource Usage

```bash
docker stats ollama
```

## Troubleshooting

### Check Health

```bash
docker compose ps ollama
```

### View Logs

```bash
docker compose logs -f ollama
```

### SSH Access

```bash
ssh -p 22001 root@localhost
```