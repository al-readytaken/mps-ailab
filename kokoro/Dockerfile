FROM ghcr.io/remsky/kokoro-fastapi-cpu:latest

USER root
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
