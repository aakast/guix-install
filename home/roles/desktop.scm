(define-module (home roles desktop)
  #:export (home-desktop-env-vars
            home-desktop-zsh-extra
            home-desktop-bash-extra))

(define home-desktop-env-vars
  '(("XDG_CURRENT_DESKTOP" . "river")
    ("XDG_SESSION_TYPE" . "wayland")
    ("MOZ_ENABLE_WAYLAND" . "1")
    ("QT_QPA_PLATFORM" . "wayland")
    ("QT_WAYLAND_DISABLE_WINDOWDECORATION" . "1")
    ("CLUTTER_BACKEND" . "wayland")
    ("SDL_VIDEODRIVER" . "wayland")
    ("GDK_BACKEND" . "wayland,x11")
    ("ELECTRON_OZONE_PLATFORM_HINT" . "wayland")
    ("XCURSOR_THEME" . "phinger-cursors-dark")
    ("XCURSOR_SIZE" . "24")
    ("WLR_NO_HARDWARE_CURSORS" . "1")
    ("_JAVA_AWT_WM_NONREPARENTING" . "1")))

(define home-desktop-zsh-extra
  "
alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
eval \"$(starship init zsh)\"

if [[ -z \"$WAYLAND_DISPLAY\" && \"$(tty)\" == \"/dev/tty1\" ]]; then
  exec river
fi
")

(define home-desktop-bash-extra
  "
if [ -z \"$WAYLAND_DISPLAY\" ] && [ \"$(tty)\" = \"/dev/tty1\" ]; then
  exec river
fi
")
