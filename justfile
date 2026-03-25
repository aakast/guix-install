set shell := ["bash", "-cu"]

default:
  @just --list

# Bootstrap live-installer environment (clock, pull, tools).
bootstrap:
  ./scripts/bootstrap-installer.sh

# Pull Guix with pinned channels for this repo.
pull:
  guix pull -C channels.scm

# Destructive disk provisioning (partition, LUKS, btrfs, mounts).
provision disk:
  sudo ./deploy/provision.sh {{disk}}

# Backup LUKS headers and disk metadata off-machine.
backup disk outdir:
  sudo ./deploy/backup-storage-metadata.sh {{disk}} {{outdir}}

# Render install config with live UUIDs.
render disk template="system/hosts/workstation.template.scm" out="system/hosts/workstation.scm":
  ./scripts/render-config.sh {{disk}} {{template}} {{out}}

# Install rendered system config to target mount (cow-store, init, copy repo).
system-init config="system/hosts/workstation.scm" target="/mnt":
  sudo ./scripts/install-system.sh {{config}} {{target}}

# Reinstall existing encrypted system from live USB.
reinstall disk target="/mnt":
  sudo ./scripts/reinstall-system.sh {{disk}} {{target}}

# Full install pipeline (pull, provision, backup, render, install).
install disk outdir:
  sudo ./scripts/full-install.sh {{disk}} {{outdir}}

# Build Guix Home configuration.
home-build config="home.scm":
  guix home build --load-path=. {{config}}

# Apply Guix Home configuration.
home config="home.scm":
  guix home reconfigure --load-path=. {{config}}

# Install extra package profiles for workstation host.
profiles host="workstation":
  ./profiles/install-host-profiles.sh {{host}}

# Preview extra package profile installs for workstation host.
profiles-dry-run host="workstation":
  ./profiles/install-host-profiles.sh --dry-run {{host}}

# First-boot password setup (interactive).
post-install user="philip":
  sudo ./scripts/post-install.sh {{user}}

# Add recovery keyslot to root LUKS container.
harden disk part="4":
  bash -c 'set -euo pipefail; disk="{{disk}}"; n="{{part}}"; if [[ "$disk" =~ (nvme|mmcblk) ]]; then p="${disk}p${n}"; else p="${disk}${n}"; fi; sudo cryptsetup luksAddKey "$p"'

snapshot:
  sudo ./deploy/snapshots/local.sh

snapshot-prune keep="14":
  sudo ./deploy/snapshots/prune.sh {{keep}}
