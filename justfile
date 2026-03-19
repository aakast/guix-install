set shell := ["bash", "-cu"]

default:
  @just --list

# Destructive disk provisioning (partition, LUKS, btrfs, mounts).
provision disk:
  sudo ./deploy/provision.sh {{disk}}

# Backup LUKS headers and disk metadata off-machine.
backup disk outdir:
  sudo ./deploy/backup-storage-metadata.sh {{disk}} {{outdir}}

# Render install config with live UUIDs.
render disk template="system/hosts/workstation.template.scm" out="system/hosts/workstation.scm":
  ./scripts/render-config.sh {{disk}} {{template}} {{out}}

# Install system config to target mount.
install config="system/hosts/workstation.scm" target="/mnt":
  guix system init --load-path=. {{config}} {{target}}

# Build Guix Home configuration.
home-build config="home.scm":
  guix home build --load-path=. {{config}}

# Apply Guix Home configuration.
home-reconfigure config="home.scm":
  guix home reconfigure --load-path=. {{config}}

# First-boot password setup (interactive).
post-install user="philip":
  sudo ./scripts/post-install.sh {{user}}

# Add recovery keyslot to root LUKS container.
harden-add-recovery-key disk part="3":
  bash -c 'set -euo pipefail; disk="{{disk}}"; n="{{part}}"; if [[ "$disk" =~ (nvme|mmcblk) ]]; then p="${disk}p${n}"; else p="${disk}${n}"; fi; sudo cryptsetup luksAddKey "$p"'

snapshot-local:
  sudo ./deploy/snapshots/local.sh

snapshot-prune keep="14":
  sudo ./deploy/snapshots/prune.sh {{keep}}

# End-to-end first install pipeline.
first-install disk outdir user="philip" template="system/hosts/workstation.template.scm" out="system/hosts/workstation.scm" target="/mnt":
  just provision {{disk}}
  just backup {{disk}} {{outdir}}
  just render disk={{disk}} template={{template}} out={{out}}
  just install config={{out}} target={{target}}
  just post-install user={{user}}
