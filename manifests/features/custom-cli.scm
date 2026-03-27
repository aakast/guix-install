(use-modules (guix profiles)
             (packages cli-tools))

(concatenate-manifests
 (list
  (specifications->manifest
   '(
     "atuin"
     "battop"
     "duf"
     "glow"
     "lazygit"
     "manga-tui"
     "mods"
     "sops"
     ))
  (packages->manifest
   (list opencode))))
