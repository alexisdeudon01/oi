#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

INSTALL_USER="${INSTALL_USER:-${SUDO_USER:-$USER}}"

apt-get install -y docker.io docker-compose-plugin
systemctl enable --now docker

if [ -n "$INSTALL_USER" ]; then
  usermod -aG docker "$INSTALL_USER" || true
fi
