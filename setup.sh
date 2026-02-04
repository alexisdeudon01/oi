#!/usr/bin/env bash
set -euo pipefail

prompt() {
  local label="$1"
  local default="${2:-}"
  local value=""
  if [ -n "$default" ]; then
    read -r -p "${label} [${default}]: " value
    echo "${value:-$default}"
  else
    read -r -p "${label}: " value
    echo "$value"
  fi
}

PI_HOST="$(prompt 'IP du Raspberry Pi')"
PI_USER="$(prompt 'Utilisateur SSH' 'pi')"

# Offer SSH key-based authentication as the preferred method
echo ""
echo "Options d'authentification:"
echo "  1) Clé SSH (recommandé - plus sécurisé)"
echo "  2) Mot de passe (sshpass requis)"
AUTH_METHOD="$(prompt 'Méthode d'authentification' '1')"

USE_SSH_KEY=false
PI_PASS=""
SUDO_PASS=""

if [ "$AUTH_METHOD" = "1" ]; then
  USE_SSH_KEY=true
  SSH_KEY_PATH="$(prompt 'Chemin vers la clé SSH' "$HOME/.ssh/id_rsa")"
  if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ Clé SSH introuvable: $SSH_KEY_PATH"
    exit 1
  fi
  echo "✅ Utilisation de la clé SSH: $SSH_KEY_PATH"
  read -r -s -p "Mot de passe sudo: " SUDO_PASS
  echo ""
else
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "❌ sshpass est requis pour l'authentification par mot de passe."
    echo "   Installez avec: sudo apt-get install -y sshpass"
    echo "   Ou utilisez l'authentification par clé SSH (option 1)."
    exit 1
  fi
  read -r -s -p "Mot de passe SSH: " PI_PASS
  echo ""
  read -r -s -p "Mot de passe sudo: " SUDO_PASS
  echo ""
fi

REMOTE_DIR="$(prompt 'Répertoire d'installation sur le Pi' '/opt/ids-dashboard')"
MIRROR_INTERFACE="$(prompt 'Interface miroir' 'eth0')"

if [ -z "$PI_HOST" ]; then
  echo "❌ IP du Raspberry Pi requise."
  exit 1
fi

run_remote() {
  local cmd="$1"
  if [ "$USE_SSH_KEY" = true ]; then
    ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_HOST}" "$cmd"
  else
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_HOST}" "$cmd"
  fi
}

run_remote_sudo() {
  local cmd="$1"
  
  # Helper function to execute the sudo command remotely
  # Password is passed via stdin to sudo to avoid appearing in ps output
  local execute_remote_sudo='
    REMOTE_SCRIPT=$(mktemp /tmp/sudo-helper.XXXXXX.sh)
    cat > "$REMOTE_SCRIPT"
    chmod +x "$REMOTE_SCRIPT"
    sudo -S -p "" "$REMOTE_SCRIPT"
    EXIT_CODE=$?
    rm -f "$REMOTE_SCRIPT"
    exit $EXIT_CODE
  '
  
  if [ "$USE_SSH_KEY" = true ]; then
    printf '%s\n' "$SUDO_PASS" | ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_HOST}" \
      "$execute_remote_sudo" <<EOF
#!/bin/bash
$cmd
EOF
  else
    printf '%s\n' "$SUDO_PASS" | sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "${PI_USER}@${PI_HOST}" \
      "$execute_remote_sudo" <<EOF
#!/bin/bash
$cmd
EOF
  fi
}

echo "📦 Préparation du paquet..."
ARCHIVE_PATH="$(mktemp -t ids-dashboard-XXXXXX.tar.gz)"
tar \
  --exclude=.git \
  --exclude=webapp/frontend/node_modules \
  --exclude=webapp/backend/.venv \
  --exclude=__pycache__ \
  -czf "$ARCHIVE_PATH" .

echo "🔐 Création du répertoire distant..."
run_remote_sudo "mkdir -p '$REMOTE_DIR' && chown -R '${PI_USER}:${PI_USER}' '$REMOTE_DIR'"

echo "🚚 Transfert du dépôt vers le Pi..."
if [ "$USE_SSH_KEY" = true ]; then
  scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=accept-new "$ARCHIVE_PATH" \
    "${PI_USER}@${PI_HOST}:/tmp/ids-dashboard.tar.gz"
else
  sshpass -p "$PI_PASS" scp -o StrictHostKeyChecking=accept-new "$ARCHIVE_PATH" \
    "${PI_USER}@${PI_HOST}:/tmp/ids-dashboard.tar.gz"
fi

echo "📂 Extraction sur le Pi..."
run_remote_sudo "rm -rf '$REMOTE_DIR'/*"
run_remote_sudo "tar -xzf /tmp/ids-dashboard.tar.gz -C '$REMOTE_DIR'"
run_remote_sudo "chmod +x '$REMOTE_DIR/depancecmd/'*.sh"

echo "🧩 Exécution des scripts d'installation..."
for script in depancecmd/*.sh; do
  script_name="$(basename "$script")"
  echo "➡️  $script_name"
  if ! run_remote_sudo \
    "REMOTE_DIR='$REMOTE_DIR' INSTALL_USER='$PI_USER' MIRROR_INTERFACE='$MIRROR_INTERFACE' bash '$REMOTE_DIR/depancecmd/$script_name'"; then
    echo "❌ Échec sur $script_name."
    echo "➡️  Conseil: éditez $REMOTE_DIR/depancecmd/$script_name pour ajuster la commande."
    echo "➡️  Exemple: ajoutez un paquet manquant via 'apt-get install -y <package>'."
  else
    echo "✅ $script_name terminé."
  fi
done

echo "✅ Installation terminée. Vérifiez les services et l'interface web."
