#!/usr/bin/env bash
set -Eeuo pipefail

VMID="$1"
PHASE="$2"
CONFIG_DIR="/etc/docker/containers/wg-easy"
COMPOSE_SNIPPET="/var/lib/vz/snippets/wg-easy-docker-compose.yml"

if [[ "$PHASE" == "pre-start" ]]; then
  modprobe tun 2>/dev/null || true
  modprobe wireguard 2>/dev/null || true
  exit 0
fi

if [[ "$PHASE" != "post-start" ]]; then
  exit 0
fi

modprobe tun 2>/dev/null || true
modprobe wireguard 2>/dev/null || true

if [[ ! -f "$COMPOSE_SNIPPET" ]]; then
  echo "Compose wg-easy introuvable: $COMPOSE_SNIPPET" >&2
  echo "Verifie que le storage snippets utilise /var/lib/vz/snippets." >&2
  exit 1
fi

if ! pct exec "$VMID" -- sh -c 'command -v bash >/dev/null 2>&1'; then
  pct exec "$VMID" -- sh -se <<'BOOTSTRAP_SHELL'
if command -v apk >/dev/null 2>&1; then
  apk add --no-cache bash
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y bash
else
  echo "Unsupported container OS: no apk or apt-get found" >&2
  exit 1
fi
BOOTSTRAP_SHELL
fi

pct exec "$VMID" -- bash -se <<'INSTALL_DOCKER'
set -Eeuo pipefail

if command -v apk >/dev/null 2>&1; then
  apk add --no-cache docker docker-cli-compose iptables ip6tables ca-certificates curl
  rc-update add docker default >/dev/null 2>&1 || true
  rc-service docker start
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose-plugin iptables ca-certificates curl
  systemctl enable docker
  systemctl start docker
else
  echo "Unsupported container OS: no apk or apt-get found" >&2
  exit 1
fi
INSTALL_DOCKER

pct exec "$VMID" -- mkdir -p "$CONFIG_DIR"
pct push "$VMID" "$COMPOSE_SNIPPET" "$CONFIG_DIR/docker-compose.yml" --perms 0644
pct exec "$VMID" -- docker compose -f "$CONFIG_DIR/docker-compose.yml" up -d
