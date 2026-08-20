#!/usr/bin/env bash
# Idempotent Build-time prep for CloudPanel SSH ops.
set -euo pipefail

if command -v sudo >/dev/null 2>&1; then
  SUDO=sudo
else
  SUDO=
fi

$SUDO apt-get update -y
$SUDO apt-get install -y --no-install-recommends \
  openssh-client \
  jq \
  curl \
  rsync \
  python3 \
  mysql-client \
  php-cli \
  ca-certificates

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Pre-seed host key so SSH is non-interactive.
KNOWN_HOSTS="$HOME/.ssh/known_hosts"
HOST_IP="${CLOUDPANEL_SSH_HOST:-188.245.192.203}"
if ! grep -qF "$HOST_IP" "$KNOWN_HOSTS" 2>/dev/null; then
  cat >> "$KNOWN_HOSTS" <<'EOF'
188.245.192.203 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILOMT83n5RqhYWZG0wp28GV5k260yganOrwzPWDt6Pbc
188.245.192.203 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDd9rW8c78TOruhjPmpzK31XB32rERzjTxiA+lUlX8wIYtGrcHGVwQZN+iy2dbCD6ssitjMpNDElUpMyRi5NuS3Sj4oaW/V2FJZwKt1zE7sZI6HxTomnBSAv6qa1SfZGiEXdkZtHbSySsUFiEicej7ufhEzFTFrzMCQ+8JmICf1R3pS3y0xY+0ylZeaoBMeqJTBRpbn3fHTpaDe4gawv2GcKoHAGjfgY9v4VmSh+BU7wSsKTYQlQLVSlM1AmkRGLh5iT3ssaO/61TdGZPZ6mPZSxnfOFh48F4whGTtah/xb0pEwQ439tg2qwC/m0t1R1nPlycZr3JsIzzkvagMJECUfYgIEiI/LqonbBM+uzt0CRO5tAOvZ3g7vKB9hfbEu9nfy/E+0TURYPdzQsomcnqSDeEVVYSrkcK+zJWDW+f+GICNvw/rI2QuqIvmRge4S+t0Vfyfn3iibbXm7Bchfy7R7f4xf0DWAOVG4OKSi7/5F/hbXT6tW3R984BR15j2F9sc=
188.245.192.203 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBODCQbeJd0jtN61pgtdGy0+PtuHeWuOMfH7UOWmHkEUGW/Of1z21fK47bSF66XPIlPd/VN+A3OG0aFJ9eOAvau4=
EOF
fi
chmod 600 "$KNOWN_HOSTS"

# SSH host alias (key file is written at agent start from secrets).
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -qF 'Host cloudpanel' "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" <<EOF
Host cloudpanel
  HostName ${HOST_IP}
  User ${CLOUDPANEL_SSH_USER:-root}
  Port ${CLOUDPANEL_SSH_PORT:-22}
  IdentityFile ~/.ssh/cursor_cloudpanel_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking yes
  UserKnownHostsFile ~/.ssh/known_hosts
  ServerAliveInterval 30
  ServerAliveCountMax 3
EOF
fi
chmod 600 "$SSH_CONFIG"

echo "cloudpanel tools installed"
