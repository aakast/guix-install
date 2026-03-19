#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   sudo ./deploy/backup-storage-metadata.sh /dev/nvme0n1 /secure/backup/path

DISK="${1:?Usage: $0 /dev/<disk> /path/to/backup-dir>}"
OUTDIR="${2:?Usage: $0 /dev/<disk> /path/to/backup-dir>}"

mkdir -p "$OUTDIR"

part() {
  local disk="$1"
  local n="$2"
  if [[ "$disk" =~ (nvme|mmcblk) ]]; then
    printf "%sp%s" "$disk" "$n"
  else
    printf "%s%s" "$disk" "$n"
  fi
}

P1="$(part "$DISK" 1)"   # ESP
P2="$(part "$DISK" 2)"   # cryptswap
P3="$(part "$DISK" 3)"   # cryptroot

STAMP="$(date +%F_%H%M%S)"
META="$OUTDIR/storage-metadata-$STAMP.txt"

printf 'Backing up LUKS headers...\n'
cryptsetup luksHeaderBackup "$P2" --header-backup-file "$OUTDIR/cryptswap-luks2-header-$STAMP.img"
cryptsetup luksHeaderBackup "$P3" --header-backup-file "$OUTDIR/cryptroot-luks2-header-$STAMP.img"

{
  printf 'Timestamp: %s\n\n' "$(date --iso-8601=seconds)"
  printf 'Disk:\n  %s\n\n' "$DISK"
  printf 'Partitions:\n'
  printf '  ESP:       %s\n' "$P1"
  printf '  cryptswap: %s\n' "$P2"
  printf '  cryptroot: %s\n\n' "$P3"
  printf 'blkid:\n'
  blkid "$P1" "$P2" "$P3" || true
  printf '\nlsblk:\n'
  lsblk -f "$DISK" || true
  printf '\ncryptsetup luksDump (UUID/Version/Label lines):\n'
  cryptsetup luksDump "$P2" | grep -E 'UUID|Version|Label' || true
  cryptsetup luksDump "$P3" | grep -E 'UUID|Version|Label' || true
  printf '\nParted layout:\n'
  parted -s "$DISK" unit MiB print || true
} > "$META"

chmod 600 "$OUTDIR"/crypt*-luks2-header-"$STAMP".img "$META"

printf '\nDone.\nCreated:\n'
printf '  %s\n' "$OUTDIR/cryptswap-luks2-header-$STAMP.img"
printf '  %s\n' "$OUTDIR/cryptroot-luks2-header-$STAMP.img"
printf '  %s\n\n' "$META"
printf 'Store these OFF the machine.\n'
