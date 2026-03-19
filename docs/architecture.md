# Architecture

Composition model:

```
host = system common + system role(s)
     + home common   + home role(s)
     + host entry point + install scripts
```

The install lifecycle is split cleanly:

- `deploy/` handles partitioning, encryption, snapshots, and metadata backup
- `scripts/render-config.sh` injects live UUIDs into a host template
- `system/hosts/workstation.scm` is the install entry point
- `home.scm` + `home/hosts/workstation.scm` define first-class user state
- `scripts/post-install.sh` handles only non-declarative, interactive tasks
