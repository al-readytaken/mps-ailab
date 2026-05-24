FROM nousresearch/hermes-agent:latest

EXPOSE 8642 9119 22
USER root
RUN apt-get update && apt-get install -y libportaudio2 python3-pip openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH
RUN echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

# Python deps for TTS engine
USER hermes
RUN uv pip install --python /opt/hermes/.venv/bin/python \
    -t /opt/hermes/.venv/lib/python3.13/site-packages \
    sounddevice numpy python-telegram-bot

# Change hermes user UID to 1000 and home to /home/hermes (base image uses /opt/data)
USER root
RUN mkdir -p /home/hermes && \
    usermod -u 1000 hermes && groupmod -g 1000 hermes && \
    usermod -d /home/hermes hermes && \
    chown hermes:hermes /home/hermes && \
    find /opt/hermes -user 10000 -exec chown -h 1000 {} + 2>/dev/null || true

# Custom entrypoint (env init, dashboard, privilege drop)
COPY scripts/entrypoint.sh /opt/hermes/docker/entrypoint.sh
RUN chmod +x /opt/hermes/docker/entrypoint.sh

# chat script — PATH-installed shortcut to launch Hermes CLI in /opt/projects
COPY scripts/chat /usr/local/bin/chat
RUN chmod +x /usr/local/bin/chat

# setup script — initial config generator (env vars → .hermes/.env + config.yaml)
COPY scripts/setup /usr/local/bin/setup
RUN chmod +x /usr/local/bin/setup

# patch_providers — adds openrouter entry to _PROVIDER_MODELS dict
COPY scripts/patch_providers.py /tmp/patch_providers.py
RUN python3 /tmp/patch_providers.py && rm /tmp/patch_providers.py