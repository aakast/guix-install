#!/usr/bin/env bash
set -euo pipefail

# Full Guix System install pipeline for a fresh disk.
#
# Chains every step from guix pull through system init:
#   1. Update Guix          (guix pull + hash guix)
#   2. Provision disk       (partition, LUKS, btrfs, mount at $TARGET)
#   3. Backup LUKS metadata (headers + UUIDs to $BACKUP_DIR)
#   4. Render config        (inject live UUIDs into template)
#   5. Install system       (cow-store, guix system init, copy repo)
#
# Usage:
#   sudo ./scripts/full-install.sh /dev/<disk> <backup-dir> [target]
#
# Environment:
#   SKIP_PULL=1   Skip guix pull (default: pull is ON)
#   TEMPLATE=...  Override template path  (default: system/hosts/workstation.template.scm)
#   OUT=...       Override rendered output (default: system/hosts/workstation.scm)

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf 'Please run with bash, not sh. Example: bash %s /dev/<disk> <backup-dir>\n' "$0" >&2
  exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'Run as root: sudo %s /dev/<disk> <backup-dir> [target]\n' "$0" >&2
  exit 1
fi

DISK="${1:?Usage: $0 /dev/<disk> <backup-dir> [target]}"
BACKUP_DIR="${2:?Usage: $0 /dev/<disk> <backup-dir> [target]}"
TARGET="${3:-/mnt}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEMPLATE="${TEMPLATE:-system/hosts/workstation.template.scm}"
OUT="${OUT:-system/hosts/workstation.scm}"

# Resolve relative paths against repo root.
if [[ "$TEMPLATE" != /* ]]; then TEMPLATE="$REPO_ROOT/$TEMPLATE"; fi
if [[ "$OUT" != /* ]]; then OUT="$REPO_ROOT/$OUT"; fi

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

phase() {
  printf '\n%s========== %s ==========%s\n' "$C_CYAN" "$1" "$C_RESET"
}

done_phase() {
  printf '%s[ok]%s %s\n' "$C_GREEN" "$C_RESET" "$1"
}

# --- Validation ---

if [[ ! -b "$DISK" ]]; then
  printf 'Not a block device: %s\n' "$DISK" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
  printf 'Template not found: %s\n' "$TEMPLATE" >&2
  exit 1
fi

printf 'Disk:       %s\n' "$DISK"
printf 'Backup dir: %s\n' "$BACKUP_DIR"
printf 'Target:     %s\n' "$TARGET"
printf 'Template:   %s\n' "$TEMPLATE"
printf 'Output:     %s\n\n' "$OUT"

# --- Pipeline ---

# 1. Update Guix
if [[ "${SKIP_PULL:-0}" != "1" ]]; then
  phase "1/5  Updating Guix"
  guix pull
  hash guix
  done_phase "Guix updated"
else
  printf '%s[skip]%s guix pull (SKIP_PULL=1)\n' "$C_YELLOW" "$C_RESET"
fi

# 2. Provision disk (destructive)
phase "2/5  Provisioning disk"
"$REPO_ROOT/deploy/provision.sh" "$DISK"
done_phase "Disk provisioned and mounted at $TARGET"

# 3. Backup LUKS metadata
phase "3/5  Backing up LUKS metadata"
"$REPO_ROOT/deploy/backup-storage-metadata.sh" "$DISK" "$BACKUP_DIR"
done_phase "LUKS metadata backed up to $BACKUP_DIR"

# 4. Render config with live UUIDs
phase "4/5  Rendering config"
"$REPO_ROOT/scripts/render-config.sh" "$DISK" "$TEMPLATE" "$OUT"
done_phase "Config rendered to $OUT"

# 5. Install system to target
phase "5/5  Installing system"
"$REPO_ROOT/scripts/install-system.sh" "$OUT" "$TARGET"

printf '\n%s========== Full install complete ==========%s\n' "$C_GREEN" "$C_RESET"
printf '\nAfter rebooting into the new system:\n'
printf '  sudo /git/guix/scripts/post-install.sh          # set passwords + fix repo ownership\n'
printf '  just -f /git/guix/justfile home                 # uses hostname -s by default\n'
printf '\nTo reconfigure later:\n'
printf '  sudo guix system reconfigure --load-path=/git/guix /git/guix/system/hosts/<host>.scm\n'
