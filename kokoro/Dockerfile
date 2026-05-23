FROM ghcr.io/remsky/kokoro-fastapi-cpu:latest

USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    sed -i "s|/v1/audio/voices|/kokoro/v1/audio/voices|g" /app/web/src/services/VoiceService.js && \
    sed -i "s|/v1/audio/speech|/kokoro/v1/audio/speech|g" /app/web/src/services/AudioService.js && \
    sed -i "s|/v1\${|/kokoro/v1\${|g" /app/web/src/services/AudioService.js && \
    sed -i "s|/v1/audio/download|/kokoro/v1/audio/download|g" /app/web/src/services/AudioService.js
ENTRYPOINT ["/entrypoint.sh"]
