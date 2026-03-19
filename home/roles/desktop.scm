(define-module (home roles desktop)
  #:export (home-desktop-env-vars))

(define home-desktop-env-vars
  '(("XDG_CURRENT_DESKTOP" . "sway")
    ("MOZ_ENABLE_WAYLAND" . "1")
    ("QT_QPA_PLATFORM" . "wayland")))
