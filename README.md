# guix-install-kit

Reusable Guix System install kit for a desktop workstation.

This repo is the source of truth on the workstation at `/git/guix`.
Do not assume `~/.config/guix` defaults; all operational commands use explicit
paths under `/git/guix`.

The end-to-end workflow is:

1. bootstrap live installer environment
2. install system (pull channels, provision disk, backup metadata, render UUIDs, `guix system init`)
3. set initial passwords on first boot
4. apply Guix Home
5. install host feature profiles
6. log in on `tty1` and auto-start River

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
just home
just profiles
```

`just home` and `just profiles` default to `host=$(hostname -s)`. Override by
passing a host argument, e.g. `just home workstation`.

`post-install.sh` intentionally handles only non-declarative operations (interactive
password setup and guidance for optional LUKS recovery-key hardening).  User home
state is declared in `home/` and applied via Guix Home.

After `just home`, shell login on `tty1` auto-starts River.

## `just` commands

```bash
# Installer bootstrap (clock check, guix pull, install git+just)
just bootstrap

# Core install steps (can be run separately)
just provision /dev/nvme0n1
just backup /dev/nvme0n1 /mnt/external/workstation-backup
just render /dev/nvme0n1
just render /dev/nvme0n1 workstation
just system-init
just system-init workstation
just reconfigure
just reconfigure workstation

# Reinstall existing system from live USB (no repartition/format)
just reinstall /dev/nvme0n1
just reinstall /dev/nvme0n1 workstation

# Full install pipeline (recommended)
just install /dev/nvme0n1 /mnt/external/workstation-backup
just install /dev/nvme0n1 /mnt/external/workstation-backup workstation

# First boot and user environment
just post-install
just home
just home workstation
just home-build
just home-build workstation
just profiles
just profiles workstation
just profiles-dry-run
just profiles-dry-run workstation

# Optional hardening and snapshots
just harden /dev/nvme0n1
just snapshot
just snapshot-prune 14
```

## Path conventions

- This repository is expected at `/git/guix` on the workstation.
- `just pull` uses `/git/guix/channels.scm`.
- `just home` and `just home-build` use `--load-path=/git/guix` and host-specific entry points under `/git/guix/home/hosts/<host>.scm`.
- `just render` defaults to `system/hosts/<hostname -s>.template.scm` and writes `system/hosts/<hostname -s>.scm`.
- `just install`, `just reinstall`, and `just system-init` also default to `hostname -s` and can be overridden by passing an explicit host argument.
- Extra profiles are installed through `/git/guix/profiles/install-host-profiles.sh`.

If `hostname -s` returns `localhost`, set `(host-name "<your-host>")` in your
system host config and apply it with `guix system reconfigure`, then reboot.

## Dotfiles + theming

- Guix Home imports files from `/git/dotfiles` via `local-file` in `home/hosts/workstation.scm`.
- Pywal dynamic files are rendered at runtime from `.tmpl` files by
  `/git/dotfiles/scripts/apply_pywal_theme.sh`.
- Guix Home manages static configs; pywal output stays in `~/.cache/wal/`.
