(define-module (home roles desktop)
  #:export (home-desktop-env-vars
            home-desktop-zsh-extra))

(define home-desktop-env-vars
  '(("XDG_CURRENT_DESKTOP" . "sway")
    ("MOZ_ENABLE_WAYLAND" . "1")
    ("QT_QPA_PLATFORM" . "wayland")))

(define home-desktop-zsh-extra
  "
alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
eval \"$(starship init zsh)\"
")
