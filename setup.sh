#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  fi
  echo "This script must be run as root (sudo)."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
INSTALL_USER="${SUDO_USER:-$USER}"
MIRROR_INTERFACE="${MIRROR_INTERFACE:-eth0}"

echo "Updating apt package lists..."
apt-get update -y

echo "Installing system dependencies..."
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  git \
  build-essential \
  python3 \
  python3-venv \
  python3-pip \
  nodejs \
  npm \
  jq \
  suricata \
  suricata-update \
  docker.io \
  docker-compose-plugin \
  pigpio \
  sqlite3

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not detected after install. Please check your package sources."
else
  systemctl enable --now docker
  if [ -n "${INSTALL_USER}" ]; then
    usermod -aG docker "${INSTALL_USER}" || true
  fi
fi

if command -v suricata-update >/dev/null 2>&1; then
  echo "Updating Suricata rules..."
  suricata-update || true
fi

echo "Enabling promiscuous mode on ${MIRROR_INTERFACE}..."
ip link set "${MIRROR_INTERFACE}" promisc on || true

echo "Installing backend dependencies..."
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

if [ -f "frontend/package.json" ]; then
  echo "Installing frontend dependencies..."
  if command -v npm >/dev/null 2>&1; then
    sudo -u "${INSTALL_USER}" bash -c "cd frontend && npm install"
  else
    echo "npm not found. Skipping frontend dependency install."
  fi
fi

echo "Setup complete."
