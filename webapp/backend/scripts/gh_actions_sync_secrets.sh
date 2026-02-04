#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'USAGE'
Usage: scripts/gh_actions_sync_secrets.sh [--repo OWNER/REPO] [--map PATH]

Sync Codespaces environment secrets to GitHub Actions repository secrets.

Options:
  --repo OWNER/REPO   Target repository (default: current repo)
  --map PATH          Mapping file (default: scripts/actions_secrets.map if present)
  -h, --help          Show this help
USAGE
}

REPO=""
MAP_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --map)
      MAP_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${GH_TOKEN:-}" && -n "${GITAPI:-}" ]]; then
  export GH_TOKEN="${GITAPI}"
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required. Install from https://cli.github.com/" >&2
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

if [[ -z "$MAP_FILE" ]]; then
  if [[ -f "${ROOT_DIR}/scripts/actions_secrets.map" ]]; then
    MAP_FILE="${ROOT_DIR}/scripts/actions_secrets.map"
  fi
fi

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

declare -A SECRET_MAP=()

if [[ -n "$MAP_FILE" ]]; then
  if [[ ! -f "$MAP_FILE" ]]; then
    echo "Mapping file not found: $MAP_FILE" >&2
    exit 1
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(trim "$line")"
    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    if [[ "$line" != *"="* ]]; then
      echo "Invalid mapping line (expected target=source): $line" >&2
      exit 1
    fi
    target="$(trim "${line%%=*}")"
    source="$(trim "${line#*=}")"
    if [[ -z "$target" || -z "$source" ]]; then
      echo "Invalid mapping line (empty target or source): $line" >&2
      exit 1
    fi
    SECRET_MAP["$target"]="$source"
  done < "$MAP_FILE"
else
  # Default mapping: required secrets
  for name in \
    TAILSCALE_OAUTH_CLIENT_ID \
    TAILSCALE_OAUTH_CLIENT_SECRET \
    TAILSCALE_TAILNET \
    TAILSCALE_API_KEY \
    RASPBERRY_PI_TAILSCALE_IP \
    RASPBERRY_PI_USER \
    RASPBERRY_PI_SSH_KEY; do
    SECRET_MAP["$name"]="$name"
  done
  
  # Optional secrets (AWS, monitoring, etc.)
  for name in \
    AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY \
    AWS_SESSION_TOKEN \
    AWS_REGION \
    SONAR_TOKEN \
    SLACK_WEBHOOK_URL; do
    SECRET_MAP["$name"]="$name"
  done
fi

if [[ ${#SECRET_MAP[@]} -eq 0 ]]; then
  echo "No secrets configured to sync." >&2
  exit 1
fi

updated=0
missing=()
optional_missing=()

# Required secrets that must be present
REQUIRED_SECRETS=(
  "TAILSCALE_OAUTH_CLIENT_ID"
  "TAILSCALE_OAUTH_CLIENT_SECRET"
  "TAILSCALE_TAILNET"
  "TAILSCALE_API_KEY"
  "RASPBERRY_PI_TAILSCALE_IP"
  "RASPBERRY_PI_USER"
  "RASPBERRY_PI_SSH_KEY"
)

for target in "${!SECRET_MAP[@]}"; do
  source="${SECRET_MAP[$target]}"
  value="${!source-}"
  
  if [[ -z "$value" ]]; then
    # Check if this is a required secret
    is_required=0
    for req in "${REQUIRED_SECRETS[@]}"; do
      if [[ "$target" == "$req" ]]; then
        is_required=1
        break
      fi
    done
    
    if [[ $is_required -eq 1 ]]; then
      missing+=("${target} (env:${source})")
    else
      optional_missing+=("${target} (env:${source})")
    fi
    continue
  fi
  
  printf '%s' "$value" | gh secret set "$target" --repo "$REPO"
  echo "✓ Set secret: ${target} (from ${source})"
  updated=$((updated + 1))
done

echo ""
echo "Summary: ${updated} secret(s) synced to GitHub Actions"

if [[ ${#missing[@]} -gt 0 ]]; then
  echo ""
  echo "❌ Missing required env vars:" >&2
  for item in "${missing[@]}"; do
    echo "  - ${item}" >&2
  done
  exit 1
fi

if [[ ${#optional_missing[@]} -gt 0 ]]; then
  echo ""
  echo "⚠️  Optional secrets not set (will be skipped in CI):"
  for item in "${optional_missing[@]}"; do
    echo "  - ${item}"
  done
fi

if [[ $updated -eq 0 ]]; then
  echo ""
  echo "❌ No secrets were updated. Check your env vars or mapping file." >&2
  exit 1
fi
