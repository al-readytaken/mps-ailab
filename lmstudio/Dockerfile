FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    curl \
    mesa-vulkan-drivers \
    libvulkan1 \
    libatomic1 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://lmstudio.ai/install.sh | bash

ENV PATH="/root/.lmstudio/bin:${PATH}"

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1234

ENTRYPOINT ["/entrypoint.sh"]