#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
  printf 'Please run with bash, not sh. Example: bash %s /dev/<disk>\n' "$0" >&2
  exit 1
fi

# Usage:
#   sudo ./deploy/provision.sh /dev/nvme0n1
#   sudo ./deploy/provision.sh /dev/sda
#
# WARNING:
#   This destroys the target disk completely.

DISK="${1:?Usage: $0 /dev/<disk>}"

ESP_SIZE_MIB=1024
SWAP_SIZE_GIB=40
LUKS_CIPHER="aes-xts-plain64"
LUKS_KEY_SIZE=512
LUKS_HASH="sha512"
BTRFS_MOUNT_OPTS="subvol=@,compress=zstd:3,noatime,ssd,space_cache=v2"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

for cmd in lsblk wipefs sgdisk parted cryptsetup mkfs.fat mkfs.btrfs mkswap blkid mount umount partprobe; do
  require_cmd "$cmd"
done

if [[ ! -b "$DISK" ]]; then
  printf 'Not a block device: %s\n' "$DISK" >&2
  exit 1
fi

printf '\nTarget disk: %s\n' "$DISK"
printf 'About to DESTROY all data on %s\n\n' "$DISK"

read -r -p "Type YES to continue: " CONFIRM < /dev/tty
[[ "$CONFIRM" == "YES" ]] || {
  printf 'Aborted.\n'
  exit 1
}

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

printf '\n[1/9] Unmounting anything mounted from %s\n' "$DISK"
umount -R /mnt 2>/dev/null || true
swapoff "$P2" 2>/dev/null || true
cryptsetup close cryptroot 2>/dev/null || true
cryptsetup close cryptswap 2>/dev/null || true

printf '\n[2/9] Wiping old signatures and partition table\n'
wipefs -a "$DISK" || true
sgdisk --zap-all "$DISK"
dd if=/dev/zero of="$DISK" bs=1M count=100 status=progress conv=fsync

printf '\n[3/9] Creating GPT partition table\n'
parted -s "$DISK" mklabel gpt

SWAP_END_MIB=$((ESP_SIZE_MIB + 1 + SWAP_SIZE_GIB * 1024))

parted -s "$DISK" \
  mkpart ESP fat32 1MiB "${ESP_SIZE_MIB}MiB" \
  set 1 esp on

parted -s "$DISK" \
  mkpart cryptswap linux-swap "${ESP_SIZE_MIB}MiB" "${SWAP_END_MIB}MiB"

parted -s "$DISK" \
  mkpart cryptroot "${SWAP_END_MIB}MiB" 100%

partprobe "$DISK"
sleep 2

printf '\n[4/9] Formatting EFI partition\n'
mkfs.fat -F 32 -n EFI "$P1"

printf '\n[5/9] Creating LUKS2 containers\n'
printf 'Set passphrase for ROOT container:\n'
printf '  (input is hidden; type passphrase and press Enter)\n'
cryptsetup luksFormat \
  --type luks2 \
  --batch-mode \
  --verify-passphrase \
  --cipher "$LUKS_CIPHER" \
  --key-size "$LUKS_KEY_SIZE" \
  --hash "$LUKS_HASH" \
  "$P3" < /dev/tty

printf 'Set passphrase for SWAP container:\n'
printf '  (input is hidden; type passphrase and press Enter)\n'
cryptsetup luksFormat \
  --type luks2 \
  --batch-mode \
  --verify-passphrase \
  --cipher "$LUKS_CIPHER" \
  --key-size "$LUKS_KEY_SIZE" \
  --hash "$LUKS_HASH" \
  "$P2" < /dev/tty

printf '\n[6/9] Opening LUKS containers\n'
cryptsetup open "$P3" cryptroot
cryptsetup open "$P2" cryptswap

printf '\n[7/9] Creating filesystems\n'
mkfs.btrfs -f -L guixroot /dev/mapper/cryptroot
mkswap -L swap /dev/mapper/cryptswap

printf '\n[8/9] Creating Btrfs subvolumes\n'
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@gnu
btrfs subvolume create /mnt/@git
btrfs subvolume create /mnt/@data

umount /mnt

printf '\n[9/9] Mounting final layout under /mnt\n'
mount -o "$BTRFS_MOUNT_OPTS" /dev/mapper/cryptroot /mnt

mkdir -p /mnt/home
mkdir -p /mnt/var
mkdir -p /mnt/.snapshots
mkdir -p /mnt/gnu
mkdir -p /mnt/git
mkdir -p /mnt/data
mkdir -p /mnt/boot/efi

mount -o subvol=@home,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/home
mount -o subvol=@var,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/var
mount -o subvol=@snapshots,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/.snapshots
mount -o subvol=@gnu,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/gnu
mount -o subvol=@git,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/git
mount -o subvol=@data,compress=zstd:3,noatime,ssd,space_cache=v2 /dev/mapper/cryptroot /mnt/data

mount "$P1" /mnt/boot/efi
swapon /dev/mapper/cryptswap

ROOT_UUID="$(blkid -s UUID -o value "$P3")"
SWAP_UUID="$(blkid -s UUID -o value "$P2")"
ESP_UUID="$(blkid -s UUID -o value "$P1")"
BTRFS_UUID="$(blkid -s UUID -o value /dev/mapper/cryptroot)"

printf '\nProvisioning complete.\n\n'
printf 'Mounted layout:\n'
findmnt -R /mnt

printf '\nUUIDs for rendered host config:\n'
printf '  ESP partition UUID:        %s\n' "$ESP_UUID"
printf '  LUKS root partition UUID:  %s\n' "$ROOT_UUID"
printf '  LUKS swap partition UUID:  %s\n' "$SWAP_UUID"
printf '  Btrfs filesystem UUID:     %s\n\n' "$BTRFS_UUID"

printf 'Next:\n'
printf '  ./scripts/render-config.sh %s system/hosts/workstation.template.scm system/hosts/workstation.scm\n' "$DISK"
printf '  guix system init --load-path=. system/hosts/workstation.scm /mnt\n'
