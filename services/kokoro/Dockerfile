FROM ghcr.io/remsky/kokoro-fastapi-cpu:latest

# SSH daemon + locales (base image runs as non-root)
USER root
RUN apt-get update && apt-get install -y vim curl procps net-tools \
      iproute2 openssh-server locales git build-essential python3-dev \
      libffi-dev ripgrep ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

RUN mkdir -p /var/run/sshd /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keygen -A

COPY common/ssh/authorized_keys /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys && chown root:root /root/.ssh/authorized_keys

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

USER appuser
WORKDIR /app
