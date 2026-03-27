# Home

Guix Home configuration is composed from:

- `home/common/` shared user baseline
- `home/roles/` role-specific user environment
- `home/hosts/` concrete home entry points

Entry points:

- `home.scm` convenience redirect (default host)
- `home/hosts/workstation.scm` concrete host configuration

## Apply

```bash
guix home reconfigure --load-path=/git/guix /git/guix/home.scm
```

Or from the repo justfile:

```bash
just home
```

## Dotfiles integration

- Dotfiles are sourced from `/git/dotfiles` (with fallback to `$HOME/git/dotfiles` during development).
- `home-xdg-configuration-files-service-type` manages XDG configs as store symlinks.
- `home-files-service-type` manages helper scripts in `~/.local/bin` and `~/.scripts`.

## Shell and session behavior

- Shared shell setup lives in `home/common/base.scm`.
- Desktop-specific shell setup lives in `home/roles/desktop.scm`.
- On `tty1`, shell login auto-starts River when no Wayland session is active.

## Theming model

- Static configs are managed declaratively by Guix Home.
- Dynamic pywal outputs are runtime-generated in `~/.cache/wal/` by
  `/git/dotfiles/scripts/apply_pywal_theme.sh`.
- Template-driven configs (`*.tmpl`) are rendered to `~/.config/` at runtime;
  these files are intentionally not managed by Guix Home.
