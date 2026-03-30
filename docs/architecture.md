# Architecture

Composition model:

```
host = system common + system role(s)
     + home common   + home role(s)
     + host entry point + install scripts
```

The install lifecycle is split cleanly:

- `scripts/bootstrap-installer.sh` prepares the live environment (clock, `guix pull`, installer tools)
- `deploy/` handles partitioning, encryption, snapshots, and metadata backup
- `scripts/render-config.sh` renders host system configs from template + host definition + live UUIDs
- `system/host-definitions/<host>.scm` holds host-specific variables (hostname, primary user, locale, capability sets)
- `system/service-sets/` composes capability-specific service and package additions
- `system/hosts/workstation.scm` is the install entry point
- `home.scm` + `home/hosts/workstation.scm` define first-class user state
- `scripts/post-install.sh` handles only non-declarative, interactive tasks

Lifecycle phases:

1. bootstrap: `just bootstrap`
2. install: `just install <disk> <backup-dir>`
3. first boot: `just post-install`
4. user state: `just home`
