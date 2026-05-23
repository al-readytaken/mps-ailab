## Contents
- [Connection](#connection)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [SSH Access](#ssh-access)
- [Examples](#examples)
- [Volumes](#volumes)

## Connection

| Access | Command | Port |
|--------|---------|------|
| SSH | `ssh -p 9999 root@localhost` | `9999` |

No HTTP services. All access is via SSH with key-only authentication.

## Overview

A minimal Debian container running the [Opencode CLI](https://opencode.ai) — an AI code assistant. Built from [`Dockerfile`](./Dockerfile) with an SSH server and a `chat` shortcut script. The [`entrypoint.sh`](./entrypoint.sh) bootstraps the shared project volume, injects your SSH key, and starts sshd.

## Requirements

- Docker
- An SSH public key set via `OPENCODE_SSH_PUBKEY` in [`./.env`](./.env)
- No GPU or HTTP services needed

## Configuration

Set this in [`./.env`](./.env):

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENCODE_SSH_PUBKEY` | No | — | Public SSH key for key-only auth |

Without this variable, sshd still starts but root login has no authorized keys.

## SSH Access

The container runs an SSH server on port `9999` with **key-only auth** (`PasswordAuthentication no`).

**Setting up the key:** Add your public key to [`./.env`](./.env):

```
OPENCODE_SSH_PUBKEY="ssh-ed25519 AAAAC3..."
```

On startup, the [`entrypoint.sh`](./entrypoint.sh) writes it to `/root/.ssh/authorized_keys`.

**Logging in:**

```bash
ssh -p 9999 root@localhost
```

Once connected, use the `chat` shortcut to launch Opencode from `/opt/projects`:

```bash
chat          # start a new session
chat --help   # see all options
```

The container runs `sleep infinity` by default, so it stays alive even when not in use. SSH sessions are independent — you can disconnect and reconnect, and opencode sessions persist.

## Examples

```bash
# SSH in and start a coding session
ssh -p 9999 root@localhost
chat

# Run opencode directly from the host via SSH
ssh -p 9999 root@localhost "opencode 'refactor this'"
```

## Volumes

| Volume | Mount | Contents |
|--------|-------|----------|
| `./projects` (bind) | `/opt/projects` | Shared project files (same volume as Hermes) |

Files written inside the container are instantly visible in the host's `./projects/` directory and vice versa.

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| SSH "Permission denied" | No public key configured | Set `OPENCODE_SSH_PUBKEY` in `.env` and restart |
| `chat` command not found | Check entrypoint execution | Run `docker compose exec opencode sh` and verify `/usr/local/bin/chat` exists |
| Container exits immediately | Command misconfiguration | Should run `sleep infinity` — check `docker compose ps` |