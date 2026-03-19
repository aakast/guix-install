#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${1:-philip}"

if [[ "$(id -u)" -ne 0 ]]; then
  printf 'Run as root: sudo %s %s\n' "$0" "$USER_NAME" >&2
  exit 1
fi

if ! id "$USER_NAME" >/dev/null 2>&1; then
  printf 'User does not exist: %s\n' "$USER_NAME" >&2
  exit 1
fi

printf 'Setting passwords explicitly:\n'
passwd root
passwd "$USER_NAME"

printf '\nPassword bootstrap complete for %s\n' "$USER_NAME"
printf 'Next, apply Guix Home:\n'
printf '  guix home reconfigure --load-path=. home.scm\n\n'
printf 'Optional hardening:\n'
printf '  cryptsetup luksAddKey /dev/<disk-partition-for-cryptroot>\n'
printf '  ./deploy/backup-storage-metadata.sh /dev/<disk> /path/to/off-machine-backup\n'
printf '\nIf this script is run from the live installer, use the full path for home.scm.\n'
