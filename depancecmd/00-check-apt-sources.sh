#!/usr/bin/env bash
set -euo pipefail

if [ ! -d /etc/apt/sources.list.d ] && [ ! -f /etc/apt/sources.list ]; then
  echo "Aucune source APT détectée (/etc/apt/sources.list.d absent)."
  exit 1
fi

if [ -d /etc/apt/sources.list.d ]; then
  if ! ls /etc/apt/sources.list.d/*.list >/dev/null 2>&1; then
    if [ ! -s /etc/apt/sources.list ]; then
      echo "Aucune source APT active. Vérifiez /etc/apt/sources.list(.d)."
      exit 1
    fi
  fi
fi

echo "Sources APT détectées."
