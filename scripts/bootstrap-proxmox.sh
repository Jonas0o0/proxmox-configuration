#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/config/proxmox-bootstrap.env"
DRY_RUN=false
ASSUME_YES=false

log() {
  printf '[proxmox-bootstrap] %s\n' "$*"
}

die() {
  printf '[proxmox-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap-proxmox.sh [options]

Options:
  --config PATH   Fichier de configuration a charger
  --dry-run       Affiche les actions sans les executer
  --yes           Ne demande pas de confirmation pour les actions sensibles
  -h, --help      Affiche cette aide

Exemple:
  sudo ./scripts/bootstrap-proxmox.sh --config config/proxmox-bootstrap.env --yes
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_FILE="${2:-}"
      [[ -n "$CONFIG_FILE" ]] || die "--config demande un chemin"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --yes)
      ASSUME_YES=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "option inconnue: $1"
      ;;
  esac
done

bool_enabled() {
  case "${1:-false}" in
    true|TRUE|yes|YES|1|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

run() {
  if bool_enabled "$DRY_RUN"; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

confirm_sensitive_action() {
  local message="$1"
  bool_enabled "$ASSUME_YES" && return 0
  printf '%s [y/N] ' "$message"
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

backup_file_once() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  local backup="${path}.before-proxmox-bootstrap"
  [[ -f "$backup" ]] && return 0
  run cp -a "$path" "$backup"
}

write_file_if_changed() {
  local path="$1"
  local mode="${2:-0644}"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"

  if [[ -f "$path" ]] && cmp -s "$tmp" "$path"; then
    rm -f "$tmp"
    log "inchangé: $path"
    return 0
  fi

  backup_file_once "$path"
  if bool_enabled "$DRY_RUN"; then
    log "modifierait: $path"
    sed 's/^/  | /' "$tmp"
    rm -f "$tmp"
  else
    install -m "$mode" "$tmp" "$path"
    rm -f "$tmp"
    log "mis a jour: $path"
  fi
}

load_config() {
  [[ -f "$CONFIG_FILE" ]] || die "fichier config introuvable: $CONFIG_FILE"
  # shellcheck source=/dev/null
  set -a
  source "$CONFIG_FILE"
  set +a
}

require_proxmox_host() {
  if [[ "${EUID}" -ne 0 ]]; then
    bool_enabled "$DRY_RUN" || die "lance ce script en root ou avec sudo"
    log "dry-run sans root"
  fi

  if ! command -v pveversion >/dev/null 2>&1; then
    bool_enabled "$DRY_RUN" || die "ce script doit etre lance sur un host Proxmox VE"
    log "dry-run hors Proxmox"
  fi
}

debian_codename() {
  # shellcheck source=/dev/null
  source /etc/os-release
  printf '%s\n' "${VERSION_CODENAME:?}"
}

configure_apt_repositories() {
  case "${APT_CHANNEL:-none}" in
    none)
      log "repos APT non geres"
      return 0
      ;;
    enterprise)
      log "repos enterprise conserves"
      return 0
      ;;
    no-subscription)
      ;;
    *)
      die "APT_CHANNEL invalide: ${APT_CHANNEL}"
      ;;
  esac

  local codename
  codename="$(debian_codename)"

  log "configuration du repo Proxmox no-subscription (${codename})"

  for file in \
    /etc/apt/sources.list.d/pve-enterprise.list \
    /etc/apt/sources.list.d/ceph.list; do
    if [[ -f "$file" ]]; then
      backup_file_once "$file"
      run sed -ri 's/^([^#])/# \1/' "$file"
    fi
  done

  for file in \
    /etc/apt/sources.list.d/pve-enterprise.sources \
    /etc/apt/sources.list.d/ceph.sources; do
    if [[ -f "$file" ]]; then
      backup_file_once "$file"
      run sed -ri 's/^Enabled:[[:space:]]*yes/Enabled: no/I' "$file"
    fi
  done

  write_file_if_changed /etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb http://download.proxmox.com/debian/pve ${codename} pve-no-subscription
EOF
}

apply_base_system() {
  if [[ -n "${PROXMOX_HOSTNAME:-}" ]]; then
    local current_hostname
    current_hostname="$(hostname)"
    if [[ "$current_hostname" != "$PROXMOX_HOSTNAME" ]]; then
      log "hostname: ${current_hostname} -> ${PROXMOX_HOSTNAME}"
      run hostnamectl set-hostname "$PROXMOX_HOSTNAME"
    else
      log "hostname inchangé: ${PROXMOX_HOSTNAME}"
    fi
  fi

  if [[ -n "${TIMEZONE:-}" ]]; then
    log "timezone: ${TIMEZONE}"
    run timedatectl set-timezone "$TIMEZONE"
  fi

  if bool_enabled "${RUN_APT_UPDATE:-false}"; then
    run apt-get update
  fi

  if [[ -n "${INSTALL_PACKAGES:-}" ]]; then
    read -r -a packages <<< "$INSTALL_PACKAGES"
    if [[ "${#packages[@]}" -gt 0 ]]; then
      run apt-get install -y "${packages[@]}"
    fi
  fi

  if bool_enabled "${RUN_APT_DIST_UPGRADE:-false}"; then
    run env DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
  fi
}

configure_ssh() {
  bool_enabled "${SSH_HARDENING:-false}" || return 0

  log "configuration SSH"
  write_file_if_changed /etc/ssh/sshd_config.d/99-proxmox-bootstrap.conf <<EOF
PasswordAuthentication ${SSH_PASSWORD_AUTH:-no}
PermitRootLogin ${SSH_PERMIT_ROOT_LOGIN:-prohibit-password}
EOF

  run systemctl reload ssh
}

render_network_interfaces() {
  [[ -n "${MGMT_IFACE:-}" ]] || die "MGMT_IFACE est requis"
  [[ -n "${MGMT_BRIDGE:-}" ]] || die "MGMT_BRIDGE est requis"
  [[ -n "${MGMT_ADDRESS:-}" ]] || die "MGMT_ADDRESS est requis"

  cat <<EOF
auto lo
iface lo inet loopback

iface ${MGMT_IFACE} inet manual

auto ${MGMT_BRIDGE}
iface ${MGMT_BRIDGE} inet static
    address ${MGMT_ADDRESS}
EOF

  if [[ -n "${MGMT_GATEWAY:-}" ]]; then
    printf '    gateway %s\n' "$MGMT_GATEWAY"
  fi

  if [[ -n "${MGMT_DNS:-}" ]]; then
    printf '    dns-nameservers %s\n' "$MGMT_DNS"
  fi

  cat <<EOF
    bridge-ports ${MGMT_IFACE}
    bridge-stp off
    bridge-fd 0
EOF

  if bool_enabled "${BRIDGE_VLAN_AWARE:-false}"; then
    cat <<EOF
    bridge-vlan-aware yes
    bridge-vids ${BRIDGE_VIDS:-2-4094}
EOF
  fi

  printf '\n'

  if [[ -n "${EXTRA_BRIDGES:-}" ]]; then
    local spec name address ports comment
    for spec in ${EXTRA_BRIDGES}; do
      IFS=':' read -r name address ports comment <<< "$spec"
      [[ -n "$name" ]] || die "bridge invalide dans EXTRA_BRIDGES: $spec"
      [[ -n "${address:-}" ]] || address="none"
      [[ -n "${ports:-}" ]] || ports="none"

      [[ -n "${comment:-}" ]] && printf '# %s\n' "$comment"
      printf 'auto %s\n' "$name"
      if [[ "$address" == "none" ]]; then
        printf 'iface %s inet manual\n' "$name"
      else
        printf 'iface %s inet static\n' "$name"
        printf '    address %s\n' "$address"
      fi
      printf '    bridge-ports %s\n' "$ports"
      printf '    bridge-stp off\n'
      printf '    bridge-fd 0\n\n'
    done
  fi

  cat <<'EOF'
source /etc/network/interfaces.d/*
EOF
}

configure_network() {
  bool_enabled "${MANAGE_NETWORK:-false}" || return 0

  confirm_sensitive_action "MANAGE_NETWORK=true va reecrire /etc/network/interfaces. Continuer ?" \
    || die "configuration reseau annulee"

  log "configuration reseau"
  render_network_interfaces | write_file_if_changed /etc/network/interfaces

  if bool_enabled "${APPLY_NETWORK_RELOAD:-false}"; then
    if command -v ifreload >/dev/null 2>&1; then
      run ifreload -a
    else
      run systemctl restart networking
    fi
  else
    log "reseau ecrit, reload non applique (APPLY_NETWORK_RELOAD=false)"
  fi
}

storage_exists() {
  local id="$1"
  pvesm status 2>/dev/null | awk 'NR > 1 {print $1}' | grep -qx "$id"
}

configure_storage() {
  if bool_enabled "${CREATE_SNIPPETS_STORAGE:-false}"; then
    log "storage snippets: ${SNIPPETS_STORAGE_ID}"
    run mkdir -p "${SNIPPETS_PATH}"
    if storage_exists "${SNIPPETS_STORAGE_ID}"; then
      run pvesm set "${SNIPPETS_STORAGE_ID}" --content snippets
    else
      run pvesm add dir "${SNIPPETS_STORAGE_ID}" --path "${SNIPPETS_PATH}" --content snippets
    fi
  fi

  if bool_enabled "${CREATE_BACKUP_DIR_STORAGE:-false}"; then
    log "storage backup dir: ${BACKUP_DIR_STORAGE_ID}"
    run mkdir -p "${BACKUP_DIR_PATH}"
    if storage_exists "${BACKUP_DIR_STORAGE_ID}"; then
      run pvesm set "${BACKUP_DIR_STORAGE_ID}" --content backup --path "${BACKUP_DIR_PATH}"
    else
      run pvesm add dir "${BACKUP_DIR_STORAGE_ID}" --path "${BACKUP_DIR_PATH}" --content backup
    fi
  fi
}

configure_pbs() {
  bool_enabled "${PBS_ENABLED:-false}" || return 0

  [[ -n "${PBS_STORAGE_ID:-}" ]] || die "PBS_STORAGE_ID est requis"
  [[ -n "${PBS_SERVER:-}" ]] || die "PBS_SERVER est requis"
  [[ -n "${PBS_DATASTORE:-}" ]] || die "PBS_DATASTORE est requis"
  [[ -n "${PBS_USERNAME:-}" ]] || die "PBS_USERNAME est requis"

  local args=(
    --server "$PBS_SERVER"
    --datastore "$PBS_DATASTORE"
    --username "$PBS_USERNAME"
  )

  [[ -n "${PBS_PASSWORD_FILE:-}" ]] && args+=(--password-file "$PBS_PASSWORD_FILE")
  [[ -n "${PBS_FINGERPRINT:-}" ]] && args+=(--fingerprint "$PBS_FINGERPRINT")

  log "storage PBS: ${PBS_STORAGE_ID}"
  if storage_exists "$PBS_STORAGE_ID"; then
    run pvesm set "$PBS_STORAGE_ID" "${args[@]}"
  else
    run pvesm add pbs "$PBS_STORAGE_ID" "${args[@]}"
  fi
}

configure_backup_job() {
  bool_enabled "${BACKUP_JOB_ENABLED:-false}" || return 0

  [[ -n "${BACKUP_JOB_ID:-}" ]] || die "BACKUP_JOB_ID est requis"
  [[ -n "${BACKUP_JOB_STORAGE:-}" ]] || die "BACKUP_JOB_STORAGE est requis"

  local args=(
    --enabled 1
    --storage "$BACKUP_JOB_STORAGE"
    --schedule "${BACKUP_JOB_SCHEDULE:-daily}"
    --mode "${BACKUP_JOB_MODE:-snapshot}"
    --vmid "${BACKUP_JOB_VMID:-all}"
  )

  [[ -n "${BACKUP_JOB_PRUNE:-}" ]] && args+=(--prune-backups "$BACKUP_JOB_PRUNE")

  log "job backup: ${BACKUP_JOB_ID}"
  if pvesh get "/cluster/backup/${BACKUP_JOB_ID}" >/dev/null 2>&1; then
    run pvesh set "/cluster/backup/${BACKUP_JOB_ID}" "${args[@]}"
  else
    run pvesh create /cluster/backup --id "$BACKUP_JOB_ID" "${args[@]}"
  fi
}

run_terraform() {
  bool_enabled "${RUN_TERRAFORM:-false}" || return 0

  command -v terraform >/dev/null 2>&1 || die "terraform introuvable"
  [[ -d "${TERRAFORM_DIR:-}" ]] || die "TERRAFORM_DIR introuvable: ${TERRAFORM_DIR:-}"

  log "terraform init: ${TERRAFORM_DIR}"
  run terraform -chdir="$TERRAFORM_DIR" init

  if bool_enabled "${TERRAFORM_AUTO_APPROVE:-false}"; then
    log "terraform apply auto-approve"
    run terraform -chdir="$TERRAFORM_DIR" apply -auto-approve
  else
    log "terraform apply interactif"
    run terraform -chdir="$TERRAFORM_DIR" apply
  fi
}

main() {
  load_config
  require_proxmox_host

  log "config: ${CONFIG_FILE}"
  configure_apt_repositories
  apply_base_system
  configure_ssh
  configure_network
  configure_storage
  configure_pbs
  configure_backup_job
  run_terraform

  log "termine"
}

main "$@"
