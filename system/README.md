# System

Operating-system configuration is composed from:

- `system/common/` shared baseline
- `system/service-sets/` composable capability-based service sets
- `system/host-definitions/` host variables (hostname, primary user, locale, etc.)
- `system/hosts/` concrete host entry points

## Render and install

Use `system/hosts/<host>.template.scm` plus
`system/host-definitions/<host>.scm` and render `system/hosts/<host>.scm`
before running:

```bash
guix system init --load-path=. system/hosts/workstation.scm /mnt
```

From the live installer, this is usually driven by:

```bash
just render /dev/nvme0n1 workstation
just system-init
```

## Host model

- Edit `system/hosts/*.template.scm` only for structural changes.
- Edit `system/host-definitions/*.scm` for host-specific values.
- `scripts/render-config.sh` merges template + host definition + discovered UUIDs
  into `system/hosts/<host>.scm`.

## Desktop session model

- `system/service-sets/desktop.scm` currently adds no services
  (`%desktop-services` is empty).
- There is no display manager/greeter by default (no greetd/sddm/gdm).
- The system boots to TTY login; River startup is handled by shell profile logic
  in Guix Home (`home/roles/desktop.scm`).

If you prefer display-manager based session startup, add `greetd-service-type`
in `system/service-sets/desktop.scm` and remove shell-based auto-start from Home.
