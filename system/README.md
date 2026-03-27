# System

Operating-system configuration is composed from:

- `system/common/` shared baseline
- `system/roles/` role-specific services
- `system/hosts/` concrete host entry points

## Render and install

Use `system/hosts/workstation.template.scm` as the source template and render
`system/hosts/workstation.scm` before running:

```bash
guix system init --load-path=. system/hosts/workstation.scm /mnt
```

From the live installer, this is usually driven by:

```bash
just render /dev/nvme0n1
just system-init
```

## Desktop session model

- `system/roles/desktop.scm` currently adds no services (`%desktop-services` is empty).
- There is no display manager/greeter by default (no greetd/sddm/gdm).
- The system boots to TTY login; River startup is handled by shell profile logic
  in Guix Home (`home/roles/desktop.scm`).

If you prefer display-manager based session startup, add `greetd-service-type`
in `system/roles/desktop.scm` and remove shell-based auto-start from Home.
