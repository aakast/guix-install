# guix-install-kit

Reusable Guix System install kit for a desktop workstation.  The repository is
structured like `~/.config/guix`: composable `system/` and `home/` modules,
host entry points, deployment scripts, and host runbooks.

The default workflow is:

1. bootstrap live installer environment
2. install system (pull latest Guix, provision, backup metadata, render UUIDs, `guix system init`)
3. set passwords on first boot
4. apply Guix Home

## Layout

```
.
|-- justfile
|-- home.scm
|-- deploy/
|   |-- provision.sh
|   |-- backup-storage-metadata.sh
|   `-- snapshots/
|      |-- local.sh
|      `-- prune.sh
|-- scripts/
|   |-- bootstrap-installer.sh
|   |-- render-config.sh
|   |-- reinstall-system.sh
|   `-- post-install.sh
|-- system/
|   |-- common/base.scm
|   |-- roles/desktop.scm
|   `-- hosts/
|      |-- workstation.template.scm
|      `-- workstation.scm
|-- home/
|   |-- common/base.scm
|   |-- roles/desktop.scm
|   `-- hosts/workstation.scm
`-- docs/hosts/workstation/install-runbook.md
```

## Install flow (recommended with `just`)

From the live installer:

```bash
bash ./scripts/bootstrap-installer.sh
just install /dev/nvme0n1 /mnt/external/workstation-backup
```

`just install` runs this full pipeline:

- `guix pull` and `hash guix` in current shell
- destructive disk provisioning
- LUKS header/metadata backup
- UUID render into `system/hosts/workstation.scm`
- `guix system init --load-path=. ...`

## Install flow (manual steps)

```bash
bash ./scripts/bootstrap-installer.sh
bash ./deploy/provision.sh /dev/nvme0n1
bash ./deploy/backup-storage-metadata.sh /dev/nvme0n1 /mnt/external/workstation-backup
bash ./scripts/render-config.sh /dev/nvme0n1 system/hosts/workstation.template.scm system/hosts/workstation.scm
guix system init --load-path=. system/hosts/workstation.scm /mnt
```

First boot:

```bash
sudo ./scripts/post-install.sh philip
guix home reconfigure --load-path=. home.scm
```

`post-install.sh` intentionally handles only non-declarative operations (interactive
password setup and guidance for optional LUKS recovery-key hardening).  User home
state is declared in `home/` and applied via Guix Home.

## `just` commands

```bash
# Installer bootstrap (clock check, guix pull, install git+just)
just bootstrap

# Core install steps (can be run separately)
just provision /dev/nvme0n1
just backup /dev/nvme0n1 /mnt/external/workstation-backup
just render /dev/nvme0n1
just system-init

# Reinstall existing system from live USB (no repartition/format)
just reinstall /dev/nvme0n1

# Full install pipeline (recommended)
just install /dev/nvme0n1 /mnt/external/workstation-backup

# First boot and home
just post-install
just home
just home-build

# Optional hardening and snapshots
just harden /dev/nvme0n1
just snapshot
just snapshot-prune 14
```
