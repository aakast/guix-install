#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${1:-philip}"

if [[ -t 1 ]]; then
  C_RESET='\033[0m'
  C_CYAN='\033[36m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
else
  C_RESET=''
  C_CYAN=''
  C_GREEN=''
  C_YELLOW=''
fi

step() {
  local idx="$1"
  local total="$2"
  local msg="$3"
  printf '\n%s[%s/%s]%s %s\n' "$C_CYAN" "$idx" "$total" "$C_RESET" "$msg"
}

done_step() {
  printf '%s[ok]%s %s\n' "$C_GREEN" "$C_RESET" "$1"
}

warn() {
  printf '%s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$1"
}

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'Run as root: sudo %s %s\n' "$0" "$USER_NAME" >&2
  exit 1
fi

if ! id "$USER_NAME" >/dev/null 2>&1; then
  printf 'User does not exist: %s\n' "$USER_NAME" >&2
  exit 1
fi

step "1" "2" "Setting passwords"
passwd root
passwd "$USER_NAME"
done_step "Passwords set for root and $USER_NAME"

step "2" "2" "Fixing repository ownership"
REPO_DIR="/git/guix"
if [[ -d "$REPO_DIR" ]]; then
  chown -R "$USER_NAME:users" "$REPO_DIR"
  done_step "Chowned $REPO_DIR to $USER_NAME:users"
else
  warn "$REPO_DIR not found, skipping chown"
fi

printf '\n'
done_step "Post-install complete"
printf 'Next, apply Guix Home (as %s, not root):\n' "$USER_NAME"
printf '  just -f /git/guix/justfile home                 # defaults to hostname -s\n\n'
printf 'To reconfigure the system later:\n'
printf '  just -f /git/guix/justfile reconfigure          # defaults to hostname -s\n\n'
printf 'Optional hardening:\n'
printf '  cryptsetup luksAddKey /dev/<disk-partition-for-cryptroot>\n'
printf '  /git/guix/deploy/backup-storage-metadata.sh /dev/<disk> /path/to/off-machine-backup\n'
