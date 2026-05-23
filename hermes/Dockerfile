FROM nousresearch/hermes-agent:latest

# System deps for audio (TTS) support
USER root
RUN apt-get update && apt-get install -y libportaudio2 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Python deps for TTS engine
USER hermes
RUN uv pip install --python /opt/hermes/.venv/bin/python \
    -t /opt/hermes/.venv/lib/python3.13/site-packages \
    sounddevice numpy

# Custom entrypoint (env init, dashboard, privilege drop)
USER root
COPY entrypoint.sh /opt/hermes/docker/entrypoint.sh
RUN chmod +x /opt/hermes/docker/entrypoint.sh
