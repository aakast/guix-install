set shell := ["bash", "-cu"]

current_host := `hostname -s`

default:
  @just --list

# Bootstrap live-installer environment (clock, pull, tools).
bootstrap:
  ./scripts/bootstrap-installer.sh

# Pull Guix with pinned channels for this repo.
pull:
  guix pull -C "{{justfile_directory()}}/channels.scm"

# Destructive disk provisioning (partition, LUKS, btrfs, mounts).
provision disk:
  sudo ./deploy/provision.sh {{disk}}

# Backup LUKS headers and disk metadata off-machine.
backup disk outdir:
  sudo ./deploy/backup-storage-metadata.sh {{disk}} {{outdir}}

# Render install config with live UUIDs.
render disk host=current_host template=("system/hosts/" + host + ".template.scm") out=("system/hosts/" + host + ".scm"):
  if [[ ! -f "{{justfile_directory()}}/{{template}}" ]]; then echo "Error: missing system template '{{template}}'" >&2; echo "Available system templates:" >&2; for p in "{{justfile_directory()}}"/system/hosts/*.template.scm; do [[ -e "$p" ]] || continue; b="${p##*/}"; echo "  ${b%.template.scm}" >&2; done; exit 1; fi
  ./scripts/render-config.sh {{disk}} {{template}} {{out}}

# Install rendered system config to target mount (cow-store, init, copy repo).
system-init host=current_host config=("system/hosts/" + host + ".scm") target="/mnt":
  if [[ ! -f "{{justfile_directory()}}/{{config}}" ]]; then echo "Error: missing rendered system config '{{config}}'" >&2; echo "Detected host: {{host}}" >&2; echo "Available rendered system configs:" >&2; for p in "{{justfile_directory()}}"/system/hosts/*.scm; do [[ -e "$p" ]] || continue; b="${p##*/}"; [[ "$b" == *.template.scm ]] && continue; echo "  ${b%.scm}" >&2; done; exit 1; fi
  sudo ./scripts/install-system.sh {{config}} {{target}}

# Reconfigure running system from rendered host config.
reconfigure host=current_host config=("system/hosts/" + host + ".scm"):
  if [[ ! -f "{{justfile_directory()}}/{{config}}" ]]; then echo "Error: missing rendered system config '{{config}}'" >&2; echo "Detected host: {{host}}" >&2; echo "Tip: run 'just render <disk> {{host}}' first." >&2; echo "Available rendered system configs:" >&2; for p in "{{justfile_directory()}}"/system/hosts/*.scm; do [[ -e "$p" ]] || continue; b="${p##*/}"; [[ "$b" == *.template.scm ]] && continue; echo "  ${b%.scm}" >&2; done; exit 1; fi
  sudo guix system reconfigure --load-path="{{justfile_directory()}}" "{{justfile_directory()}}/{{config}}"

# Reinstall existing encrypted system from live USB.
reinstall disk host=current_host target="/mnt" template=("system/hosts/" + host + ".template.scm") out=("system/hosts/" + host + ".scm"):
  if [[ ! -f "{{justfile_directory()}}/{{template}}" ]]; then echo "Error: missing system template '{{template}}'" >&2; echo "Available system templates:" >&2; for p in "{{justfile_directory()}}"/system/hosts/*.template.scm; do [[ -e "$p" ]] || continue; b="${p##*/}"; echo "  ${b%.template.scm}" >&2; done; exit 1; fi
  sudo env TEMPLATE="{{template}}" OUT="{{out}}" ./scripts/reinstall-system.sh {{disk}} {{target}}

# Full install pipeline (pull, provision, backup, render, install).
install disk outdir host=current_host template=("system/hosts/" + host + ".template.scm") out=("system/hosts/" + host + ".scm"):
  if [[ ! -f "{{justfile_directory()}}/{{template}}" ]]; then echo "Error: missing system template '{{template}}'" >&2; echo "Available system templates:" >&2; for p in "{{justfile_directory()}}"/system/hosts/*.template.scm; do [[ -e "$p" ]] || continue; b="${p##*/}"; echo "  ${b%.template.scm}" >&2; done; exit 1; fi
  sudo env TEMPLATE="{{template}}" OUT="{{out}}" ./scripts/full-install.sh {{disk}} {{outdir}}

# Build Guix Home configuration.
home-build host=current_host config=("home/hosts/" + host + ".scm"):
  if [[ ! -f "{{justfile_directory()}}/{{config}}" ]]; then echo "Error: missing home config '{{config}}'" >&2; echo "Detected host: {{host}}" >&2; echo "Available home hosts:" >&2; for p in "{{justfile_directory()}}"/home/hosts/*.scm; do [[ -e "$p" ]] || continue; b="${p##*/}"; echo "  ${b%.scm}" >&2; done; exit 1; fi
  guix home build --load-path="{{justfile_directory()}}" "{{justfile_directory()}}/{{config}}"

# Apply Guix Home configuration.
home host=current_host config=("home/hosts/" + host + ".scm"):
  if [[ ! -f "{{justfile_directory()}}/{{config}}" ]]; then echo "Error: missing home config '{{config}}'" >&2; echo "Detected host: {{host}}" >&2; echo "Available home hosts:" >&2; for p in "{{justfile_directory()}}"/home/hosts/*.scm; do [[ -e "$p" ]] || continue; b="${p##*/}"; echo "  ${b%.scm}" >&2; done; exit 1; fi
  guix home reconfigure --load-path="{{justfile_directory()}}" "{{justfile_directory()}}/{{config}}"

# Install extra package profiles for current host.
profiles host=current_host:
  "{{justfile_directory()}}/profiles/install-host-profiles.sh" "{{host}}"

# Preview extra package profile installs for current host.
profiles-dry-run host=current_host:
  "{{justfile_directory()}}/profiles/install-host-profiles.sh" --dry-run "{{host}}"

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
