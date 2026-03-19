# guix-install-kit

Reusable Guix System install kit for a desktop workstation.  The repository is
structured like `~/.config/guix`: composable `system/` and `home/` modules,
host entry points, deployment scripts, and host runbooks.

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
|   |-- render-config.sh
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

## Install flow

```bash
just provision /dev/nvme0n1
just backup /dev/nvme0n1 /mnt/external/workstation-backup
just render /dev/nvme0n1
just install
```

First boot:

```bash
just post-install philip
just home-reconfigure
```

`post-install.sh` intentionally handles only non-declarative operations (interactive
password setup and guidance for optional LUKS recovery-key hardening).  User home
state is declared in `home/` and applied via Guix Home.

## Optional commands

```bash
# Build home config without applying
just home-build

# Add a LUKS recovery keyslot to cryptroot (example: /dev/nvme0n1p3)
just harden-add-recovery-key /dev/nvme0n1

# Snapshot helpers
just snapshot-local
just snapshot-prune 14

# Full guided pipeline (runs all core install steps in order)
just first-install /dev/nvme0n1 /mnt/external/workstation-backup
```
