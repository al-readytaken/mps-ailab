#!/bin/bash
set -e

mkdir -p /opt/projects
chmod a+rwX /opt/projects

if [ -n "${OPENCODE_SSH_PUBKEY}" ]; then
  mkdir -p /root/.ssh
  echo "$OPENCODE_SSH_PUBKEY" > /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
fi

/usr/sbin/sshd

exec "$@"