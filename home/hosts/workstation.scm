(use-modules (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu home services xdg)
             (gnu services)
             (gnu packages)
             (guix gexp)
             (home common base)
             (home roles desktop))

(define (resolve-dotfiles-root)
  (let* ((home (or (getenv "HOME") "/home/discritic"))
         (user-dotfiles (string-append home "/git/dotfiles")))
    (cond
     ((file-exists? "/git/dotfiles") "/git/dotfiles")
     ((file-exists? user-dotfiles) user-dotfiles)
     (else "/git/dotfiles"))))

(define dotfiles-root (resolve-dotfiles-root))

(define (dotfiles-local relative-path)
  (local-file (string-append dotfiles-root "/" relative-path)))

(define managed-xdg-files
  `(("river/init" ,(dotfiles-local "config/river/init"))
    ("waybar/config" ,(dotfiles-local "config/waybar/config"))
    ("dunst/dunstrc" ,(dotfiles-local "config/dunst/dunstrc"))
    ("kitty/kitty.conf" ,(dotfiles-local "config/kitty/kitty.conf"))
    ("alacritty/alacritty.toml" ,(dotfiles-local "config/alacritty/alacritty.toml"))
    ("kanshi/config" ,(dotfiles-local "config/kanshi/config"))
    ("gammastep/config.ini" ,(dotfiles-local "config/gammastep/config.ini"))
    ("wluma/config.toml" ,(dotfiles-local "config/wluma/config.toml"))
    ("swappy/config" ,(dotfiles-local "config/swappy/config"))
    ("environment.d/wayland.conf" ,(dotfiles-local "config/environment.d/wayland.conf"))
    ("xdg-desktop-portal/portals.conf" ,(dotfiles-local "config/xdg-desktop-portal/portals.conf"))
    ("gtk-3.0/settings.ini" ,(dotfiles-local "config/gtk-3.0/settings.ini"))
    ("gtk-4.0/settings.ini" ,(dotfiles-local "config/gtk-4.0/settings.ini"))
    ("qt5ct/qt5ct.conf" ,(dotfiles-local "config/qt5ct/qt5ct.conf"))
    ("qt6ct/qt6ct.conf" ,(dotfiles-local "config/qt6ct/qt6ct.conf"))
    ("mpd/mpd.conf" ,(dotfiles-local "config/mpd/mpd.conf"))
    ("eww/eww.yuck" ,(dotfiles-local "config/eww/eww.yuck"))
    ("eww/eww.scss" ,(dotfiles-local "config/eww/eww.scss"))
    ("eww/scripts/music" ,(dotfiles-local "config/eww/scripts/music"))
    ("eww/scripts/sys-info" ,(dotfiles-local "config/eww/scripts/sys-info"))
    ("eww/scripts/weather" ,(dotfiles-local "config/eww/scripts/weather"))
    ("starship.toml" ,(dotfiles-local "config/starship.toml"))
    ("mimeapps.list" ,(dotfiles-local "config/mimeapps.list"))
    ("nushell/config.nu" ,(dotfiles-local "config/nushell/config.nu"))
    ("nushell/env.nu" ,(dotfiles-local "config/nushell/env.nu"))
    ("nushell/modules/developer/direnv.nu" ,(dotfiles-local "config/nushell/modules/developer/direnv.nu"))
    ("nushell/modules/developer/mod.nu" ,(dotfiles-local "config/nushell/modules/developer/mod.nu"))
    ("nushell/modules/theme/mod.nu" ,(dotfiles-local "config/nushell/modules/theme/mod.nu"))
    ("nushell/modules/theme/pywal.nu" ,(dotfiles-local "config/nushell/modules/theme/pywal.nu"))
    ("nushell/modules/theme/starship.nu" ,(dotfiles-local "config/nushell/modules/theme/starship.nu"))
    ("nushell/modules/theme/starship/init.nu" ,(dotfiles-local "config/nushell/modules/theme/starship/init.nu"))))

(define managed-home-files
  `((".local/bin/screenshot" ,(dotfiles-local "local/bin/screenshot"))
    (".local/bin/power-menu" ,(dotfiles-local "local/bin/power-menu"))
    (".local/bin/wifi-menu" ,(dotfiles-local "local/bin/wifi-menu"))
    (".local/bin/bluetooth-menu" ,(dotfiles-local "local/bin/bluetooth-menu"))
    (".local/bin/clipboard-menu" ,(dotfiles-local "local/bin/clipboard-menu"))
    (".local/bin/eww-toggle" ,(dotfiles-local "local/bin/eww-toggle"))
    (".local/bin/river-layout-cycle" ,(dotfiles-local "local/bin/river-layout-cycle"))
    (".scripts/apply_pywal_theme.sh" ,(dotfiles-local "scripts/apply_pywal_theme.sh"))))

(home-environment
 (packages (specifications->packages '()))

 (services
  (list
   (simple-service 'workstation-env-vars
                   home-environment-variables-service-type
                   (append home-base-env-vars home-desktop-env-vars))

   (service home-xdg-user-directories-service-type
            (home-xdg-user-directories-configuration
             (desktop "$HOME")
             (templates "$HOME")
             (publicshare "$HOME")
             (download "$HOME/Downloads")
             (documents "$HOME/Documents")
             (music "$HOME/Music")
             (pictures "$HOME/Pictures")
             (videos "$HOME/Videos")))

   (simple-service 'workstation-xdg-files
                   home-xdg-configuration-files-service-type
                   managed-xdg-files)

   (simple-service 'workstation-home-files
                   home-files-service-type
                   managed-home-files)

   (service home-zsh-service-type
            (home-zsh-configuration
             (zshrc
              (list
               (plain-file "zshrc-extra"
                           (string-append home-base-zsh-extra
                                          home-desktop-zsh-extra))))))

    (service home-bash-service-type
             (home-bash-configuration
              (bashrc
               (list
               (plain-file "bashrc-extra"
                           (string-append home-base-bash-extra
                                          home-desktop-bash-extra))))))

   home-base-activation-service)))
