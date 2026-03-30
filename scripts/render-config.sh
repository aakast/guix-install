#!/usr/bin/env bash
set -euo pipefail

DISK="${1:?Usage: $0 /dev/<disk> [template] [out] [host-definition]}"
TEMPLATE="${2:-system/hosts/workstation.template.scm}"
OUT="${3:-system/hosts/workstation.scm}"
HOST_DEFINITION="${4:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ "${TEMPLATE}" != /* ]]; then
  TEMPLATE="${REPO_ROOT}/${TEMPLATE}"
fi

if [[ "${OUT}" != /* ]]; then
  OUT="${REPO_ROOT}/${OUT}"
fi

if [[ -z "${HOST_DEFINITION}" ]]; then
  host_name="$(basename "${OUT}" .scm)"
  HOST_DEFINITION="${REPO_ROOT}/system/host-definitions/${host_name}.scm"
elif [[ "${HOST_DEFINITION}" != /* ]]; then
  HOST_DEFINITION="${REPO_ROOT}/${HOST_DEFINITION}"
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

P1="$(part "$DISK" 1)"
P2="$(part "$DISK" 2)"
P3="$(part "$DISK" 3)"
P4="$(part "$DISK" 4)"

if [[ ! -f "${TEMPLATE}" ]]; then
  printf 'Template not found: %s\n' "${TEMPLATE}" >&2
  exit 1
fi

if [[ ! -f "${HOST_DEFINITION}" ]]; then
  printf 'Host definition not found: %s\n' "${HOST_DEFINITION}" >&2
  exit 1
fi

if [[ -z "${ESP_UUID:-}" ]]; then
  ESP_UUID="$(blkid -s UUID -o value "$P1")"
fi

if [[ -z "${BOOT_UUID:-}" ]]; then
  BOOT_UUID="$(blkid -s UUID -o value "$P2")"
fi

if [[ -z "${LUKS_SWAP_UUID:-}" ]]; then
  LUKS_SWAP_UUID="$(blkid -s UUID -o value "$P3")"
fi

if [[ -z "${LUKS_ROOT_UUID:-}" ]]; then
  LUKS_ROOT_UUID="$(blkid -s UUID -o value "$P4")"
fi

guile -L "${REPO_ROOT}" "${SCRIPT_DIR}/render-system-host.scm" \
  "${TEMPLATE}" \
  "${HOST_DEFINITION}" \
  "${OUT}" \
  "${ESP_UUID}" \
  "${BOOT_UUID}" \
  "${LUKS_SWAP_UUID}" \
  "${LUKS_ROOT_UUID}"

printf 'Rendered %s from %s\n' "$OUT" "$TEMPLATE"
printf '  host-definition=%s\n' "$HOST_DEFINITION"
printf '  ESP_UUID=%s\n' "$ESP_UUID"
printf '  BOOT_UUID=%s\n' "$BOOT_UUID"
printf '  LUKS_SWAP_UUID=%s\n' "$LUKS_SWAP_UUID"
printf '  LUKS_ROOT_UUID=%s\n' "$LUKS_ROOT_UUID"
