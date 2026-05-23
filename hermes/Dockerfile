FROM nousresearch/hermes-agent:latest

# System deps for audio (TTS) support + SSH
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
    sounddevice numpy

# Custom entrypoint (env init, dashboard, privilege drop)
USER root
COPY scripts/entrypoint.sh /opt/hermes/docker/entrypoint.sh
RUN chmod +x /opt/hermes/docker/entrypoint.sh

# chat script — PATH-installed shortcut to launch Hermes CLI in /opt/projects
COPY scripts/chat /usr/local/bin/chat
RUN chmod +x /usr/local/bin/chat
