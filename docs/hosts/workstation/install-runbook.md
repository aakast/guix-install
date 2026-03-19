# Workstation Install Runbook

This runbook follows the repository layout and scripts in this install kit.

## 1. Provision storage

```bash
sudo ./deploy/provision.sh /dev/nvme0n1
```

This step is destructive and asks for LUKS passphrases interactively.

## 2. Back up LUKS metadata off-machine

```bash
sudo ./deploy/backup-storage-metadata.sh /dev/nvme0n1 /mnt/external/workstation-backup
```

Keep the header backups and metadata outside the installed machine.

## 3. Render host config with UUIDs

```bash
./scripts/render-config.sh /dev/nvme0n1 system/hosts/workstation.template.scm system/hosts/workstation.scm
```

## 4. Install Guix system

```bash
guix system init --load-path=. system/hosts/workstation.scm /mnt
```

## 5. First boot password path (recommended)

Set passwords explicitly after boot:

```bash
sudo ./scripts/post-install.sh philip
```

This script runs `passwd root` and `passwd philip` interactively.

## 6. Apply Guix Home (first-class user state)

```bash
guix home reconfigure --load-path=. home.scm
```

Guix Home declaratively manages user-level directories and symlinks:

- `/home/philip/src`, `/home/philip/docs`, `/home/philip/tmp`
- `/home/philip/.local/bin`, `/home/philip/.local/share`, `/home/philip/.local/state`
- `/home/philip/git -> /git`
- `/home/philip/data -> /data`

System activation declaratively manages shared paths:

- `/git`, `/data`

## 7. Recommended hardening follow-up

Add a recovery keyslot for root LUKS:

```bash
sudo cryptsetup luksAddKey /dev/nvme0n1p3
```

Take another off-machine header backup after adding the keyslot.
