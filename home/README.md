# Home

Guix Home configuration is composed from:

- `home/common/` shared user baseline
- `home/roles/` role-specific user environment
- `home/hosts/` concrete home entry points

Entry points:

- `home.scm` convenience redirect (default host)
- `home/hosts/workstation.scm` concrete host configuration

Apply with:

```bash
guix home reconfigure --load-path=. home.scm
```
