#!/usr/bin/env bash
set -euo pipefail

REMOTE_DIR="${REMOTE_DIR:-/opt/ids-dashboard}"
REQ_FILE="${REMOTE_DIR}/webapp/backend/requirements.txt"

if [ ! -f "$REQ_FILE" ]; then
  echo "requirements.txt introuvable: $REQ_FILE"
  exit 1
fi

python3 -m pip install --upgrade pip
python3 -m pip install -r "$REQ_FILE"
