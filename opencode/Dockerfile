FROM debian:stable-slim

RUN apt-get update && apt-get install -y openssh-server curl \
    nodejs npm unzip \
    && rm -rf /var/lib/apt/lists/*

RUN echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
      ARCH="arm64"; \
    else \
      ARCH="x64"; \
    fi && \
    curl -sL "https://github.com/anomalyco/opencode/releases/download/v1.15.10/opencode-linux-${ARCH}.tar.gz" \
    -o /tmp/opencode.tar.gz && \
    tar xzf /tmp/opencode.tar.gz -C /usr/local/bin/ opencode && \
    chmod +x /usr/local/bin/opencode && \
    rm /tmp/opencode.tar.gz

RUN npx -y claude-mem@13.3.0 install --ide opencode
EXPOSE 22
COPY scripts/entrypoint.sh /opt/opencode/entrypoint.sh
RUN chmod +x /opt/opencode/entrypoint.sh
COPY scripts/chat /usr/local/bin/chat
RUN chmod +x /usr/local/bin/chat
ENTRYPOINT ["/opt/opencode/entrypoint.sh"]
