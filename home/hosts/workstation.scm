(use-modules (gnu home)
             (gnu home services)
             (gnu home services shells)
             (gnu home services xdg)
             (gnu services)
             (gnu packages)
             (guix gexp)
             (home common base)
             (home roles desktop))

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
               (plain-file "bashrc-extra" home-base-bash-extra)))))

   home-base-activation-service)))
