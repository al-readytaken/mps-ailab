FROM ghcr.io/remsky/kokoro-fastapi-cpu:latest

EXPOSE 8880
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
