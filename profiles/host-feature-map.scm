(define %workstation-features
  '("base"
    "custom-cli"
    "desktop-wayland"
    "fonts-theme"
    "network"
    "hardware"
    "sysadmin"
    "backup"
    "p2p"))

(define %dev-features
  '("dev-rust"
    "dev-python"
    "dev-polyglot"
    "k8s-gitops"))

(define %host-feature-map
  `(("workstation"
     ,@%workstation-features
     ,@%dev-features
     "dev-embedded"
     "media-creation"
     "pim-productivity"
     "docs-design"
     "data"
     "comms"
     "host-workstation")))
