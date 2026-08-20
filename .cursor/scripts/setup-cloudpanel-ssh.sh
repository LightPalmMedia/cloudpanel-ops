#!/usr/bin/env bash
# Runtime SSH key materialization from Cursor Secrets.
# Required secret: CLOUDPANEL_SSH_PRIVATE_KEY (Runtime Secret / environment-scoped)
# Optional env vars: CLOUDPANEL_SSH_HOST, CLOUDPANEL_SSH_USER, CLOUDPANEL_SSH_PORT
set -euo pipefail

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

KEY_FILE="$HOME/.ssh/cursor_cloudpanel_ed25519"
HOST_IP="${CLOUDPANEL_SSH_HOST:-188.245.192.203}"
SSH_USER="${CLOUDPANEL_SSH_USER:-root}"
SSH_PORT="${CLOUDPANEL_SSH_PORT:-22}"

if [[ -z "${CLOUDPANEL_SSH_PRIVATE_KEY:-}" ]]; then
  echo "WARNING: CLOUDPANEL_SSH_PRIVATE_KEY is not set."
  echo "Add it as an environment-scoped Runtime Secret in Cursor Cloud Agents dashboard."
  exit 0
fi

# Support both literal newlines and escaped \n from secret UIs.
printf '%s\n' "${CLOUDPANEL_SSH_PRIVATE_KEY}" | sed 's/\r$//' | sed 's/\\n/\n/g' > "$KEY_FILE"
chmod 600 "$KEY_FILE"

# Ensure config exists / stays correct.
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -qF 'Host cloudpanel' "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" <<EOF
Host cloudpanel
  HostName ${HOST_IP}
  User ${SSH_USER}
  Port ${SSH_PORT}
  IdentityFile ~/.ssh/cursor_cloudpanel_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking yes
  UserKnownHostsFile ~/.ssh/known_hosts
  ServerAliveInterval 30
  ServerAliveCountMax 3
EOF
  chmod 600 "$SSH_CONFIG"
fi

if ssh -o BatchMode=yes -o ConnectTimeout=10 cloudpanel 'echo CLOUDPANEL_SSH_OK; hostname; whoami'; then
  echo "CloudPanel SSH ready (ssh cloudpanel)"
else
  echo "ERROR: SSH to CloudPanel failed. Check secret key + network allowlist for ${HOST_IP}:22"
  exit 1
fi
