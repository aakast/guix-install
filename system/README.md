# System

Operating-system configuration is composed from:

- `system/common/` shared baseline
- `system/roles/` role-specific services
- `system/hosts/` concrete host entry points

Use `system/hosts/workstation.template.scm` as the source template and render
`system/hosts/workstation.scm` before running:

```bash
guix system init --load-path=. system/hosts/workstation.scm /mnt
```
