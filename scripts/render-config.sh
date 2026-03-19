#!/usr/bin/env bash
set -euo pipefail

DISK="${1:?Usage: $0 /dev/<disk> [template] [out]}"
TEMPLATE="${2:-system/hosts/workstation.template.scm}"
OUT="${3:-system/hosts/workstation.scm}"

part() {
  local disk="$1"
  local n="$2"
  if [[ "$disk" =~ (nvme|mmcblk) ]]; then
    printf "%sp%s" "$disk" "$n"
  else
    printf "%s%s" "$disk" "$n"
  fi
}

P1="$(part "$DISK" 1)"
P2="$(part "$DISK" 2)"
P3="$(part "$DISK" 3)"

ESP_UUID="$(blkid -s UUID -o value "$P1")"
LUKS_SWAP_UUID="$(blkid -s UUID -o value "$P2")"
LUKS_ROOT_UUID="$(blkid -s UUID -o value "$P3")"

sed \
  -e "s/{{ESP_UUID}}/${ESP_UUID}/g" \
  -e "s/{{LUKS_SWAP_UUID}}/${LUKS_SWAP_UUID}/g" \
  -e "s/{{LUKS_ROOT_UUID}}/${LUKS_ROOT_UUID}/g" \
  "$TEMPLATE" > "$OUT"

printf 'Rendered %s from %s\n' "$OUT" "$TEMPLATE"
printf '  ESP_UUID=%s\n' "$ESP_UUID"
printf '  LUKS_SWAP_UUID=%s\n' "$LUKS_SWAP_UUID"
printf '  LUKS_ROOT_UUID=%s\n' "$LUKS_ROOT_UUID"
