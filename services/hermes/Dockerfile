FROM debian:bookworm

# System dependencies + Node.js 22 LTS (Vite needs 20.19+)
RUN apt-get update && apt-get install -y vim curl procps net-tools \
      iproute2 openssh-server locales git build-essential python3-dev \
      libffi-dev ripgrep ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

RUN mkdir -p /var/run/sshd /root/.ssh && \
    chmod 700 /root/.ssh && \
    ssh-keygen -A

COPY common/ssh/authorized_keys /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys && chown root:root /root/.ssh/authorized_keys

# Pre-install Hermes to a staging path (bind mount hides /root/.hermes at runtime)
ENV HERMES_STAGE=/opt/hermes-stage
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh | \
    HERMES_HOME="$HERMES_STAGE" bash -s -- --dir "$HERMES_STAGE/hermes-agent" --skip-browser

# Pre-build web UI
RUN cd "$HERMES_STAGE/hermes-agent/web" && npm install && npm run build

# Ensure hermes is on PATH (installer links into ~/.local/bin)
ENV PATH="/root/.local/bin:$PATH"
RUN mkdir -p /root/.local/bin

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

WORKDIR /opt/projects
