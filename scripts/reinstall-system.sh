#!/usr/bin/env bash
set -euo pipefail

# Reinstall an existing system from the live USB without repartitioning.
# Expected disk layout:
#   p1 = ESP (vfat)
#   p2 = /boot (ext4)
#   p3 = cryptswap (LUKS2)
#   p4 = cryptroot (LUKS2, btrfs subvolumes)

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf 'Please run with bash, not sh. Example: bash %s /dev/<disk>\n' "$0" >&2
  exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'Run as root: sudo %s /dev/<disk> [target]\n' "$0" >&2
  exit 1
fi

DISK="${1:?Usage: $0 /dev/<disk> [target]}"
TARGET="${2:-/mnt}"
TEMPLATE="${TEMPLATE:-system/hosts/workstation.template.scm}"
OUT="${OUT:-system/hosts/workstation.scm}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ "$TEMPLATE" = /* ]]; then
  TEMPLATE_PATH="$TEMPLATE"
else
  TEMPLATE_PATH="$REPO_ROOT/$TEMPLATE"
fi

if [[ "$OUT" = /* ]]; then
  OUT_PATH="$OUT"
else
  OUT_PATH="$REPO_ROOT/$OUT"
fi

part() {
  local disk="$1"
  local n="$2"
  if [[ "$disk" =~ (nvme|mmcblk) ]]; then
    printf "%sp%s" "$disk" "$n"
  else
    printf "%s%s" "$disk" "$n"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

for cmd in cryptsetup mount umount blkid findmnt guix sync; do
  require_cmd "$cmd"
done

if [[ ! -b "$DISK" ]]; then
  printf 'Not a block device: %s\n' "$DISK" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  printf 'Template not found: %s\n' "$TEMPLATE_PATH" >&2
  exit 1
fi

P1="$(part "$DISK" 1)"
P2="$(part "$DISK" 2)"
P3="$(part "$DISK" 3)"
P4="$(part "$DISK" 4)"

for p in "$P1" "$P2" "$P3" "$P4"; do
  if [[ ! -b "$p" ]]; then
    printf 'Expected partition is missing: %s\n' "$p" >&2
    exit 1
  fi
done

printf 'Reinstall target disk: %s\n' "$DISK"
printf 'Mount target: %s\n' "$TARGET"
printf 'Template: %s\n' "$TEMPLATE_PATH"
printf 'Rendered config: %s\n\n' "$OUT_PATH"

if [[ "${PULL_GUIX:-0}" == "1" ]]; then
  printf '[1/6] Pulling latest Guix in current shell\n'
  guix pull
  hash guix
else
  printf '[1/6] Skipping guix pull (set PULL_GUIX=1 to enable)\n'
fi

printf '[2/6] Closing old mappings and mounts (if any)\n'
umount -R "$TARGET" 2>/dev/null || true
swapoff /dev/mapper/cryptswap 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true
cryptsetup close cryptswap 2>/dev/null || true

printf '[3/6] Unlocking encrypted containers\n'
cryptsetup open "$P4" cryptroot
cryptsetup open "$P3" cryptswap

printf '[4/6] Mounting target layout\n'
mount -o subvol=@,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot "$TARGET"

mkdir -p "$TARGET/home" "$TARGET/var" "$TARGET/.snapshots" "$TARGET/gnu" "$TARGET/git" "$TARGET/data"
mkdir -p "$TARGET/boot" "$TARGET/boot/efi"

mount -o subvol=@home,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot "$TARGET/home"
mount -o subvol=@var,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot "$TARGET/var"
ln -sfn /run "$TARGET/var/run"
mount -o subvol=@snapshots,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot "$TARGET/.snapshots"
mount -o subvol=@gnu,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot "$TARGET/gnu"
mount -o subvol=@git,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot "$TARGET/git"
mount -o subvol=@data,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot "$TARGET/data"

mount "$P2" "$TARGET/boot"
mount "$P1" "$TARGET/boot/efi"

swapon /dev/mapper/cryptswap
findmnt -R "$TARGET"

printf '[5/6] Rendering config\n'
"$REPO_ROOT/scripts/render-config.sh" "$DISK" "$TEMPLATE_PATH" "$OUT_PATH"

printf '[6/6] Installing system to %s\n' "$TARGET"
"$REPO_ROOT/scripts/install-system.sh" "$OUT_PATH" "$TARGET"

printf '\nReinstall complete.\n'
printf 'You can now reboot.\n'
