(define-module (home common base)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:export (home-base-env-vars
            home-base-zsh-extra
            home-base-bash-extra
            home-base-activation-service))

(define home-base-env-vars
  '(("EDITOR" . "nvim")
    ("VISUAL" . "nvim")
    ("PAGER" . "less")
    ("GOPATH" . "$HOME/go")
    ("CARGO_HOME" . "$HOME/.cargo")
    ("RUSTUP_HOME" . "$HOME/.rustup")
    ("GUIX_LOCPATH" . "$HOME/.guix-home/profile/lib/locale")
    ("SSL_CERT_DIR" . "$HOME/.guix-home/profile/etc/ssl/certs")
    ("SSL_CERT_FILE" . "$HOME/.guix-home/profile/etc/ssl/certs/ca-certificates.crt")))

(define home-base-zsh-extra
  "
if [ -f ~/.guix-home/profile/etc/profile ]; then
  source ~/.guix-home/profile/etc/profile
fi
if [ -f ~/.config/guix/current/etc/profile ]; then
  source ~/.config/guix/current/etc/profile
fi

setopt local_options nonomatch
for p in ~/.guix-extra-profiles/*/; do
  profile=\"${p}$(basename $p)\"
  if [ -f \"${profile}/etc/profile\" ]; then
    source \"${profile}/etc/profile\"
  fi
done
")

(define home-base-bash-extra
  "
if [ -f ~/.guix-home/profile/etc/profile ]; then
  source ~/.guix-home/profile/etc/profile
fi
if [ -f ~/.config/guix/current/etc/profile ]; then
  source ~/.config/guix/current/etc/profile
fi

shopt -s nullglob
for p in ~/.guix-extra-profiles/*/; do
  profile=\"${p}$(basename $p)\"
  if [ -f \"${profile}/etc/profile\" ]; then
    source \"${profile}/etc/profile\"
  fi
done
shopt -u nullglob
")

(define home-base-activation-service
  (simple-service
   'home-base-directories
   home-activation-service-type
   #~(begin
       (use-modules (guix build utils))
       (let* ((home (passwd:dir (getpwuid (getuid))))
              (dirs (list (string-append home "/src")
                          (string-append home "/docs")
                          (string-append home "/tmp")
                          (string-append home "/Downloads")
                          (string-append home "/Documents")
                          (string-append home "/Music")
                          (string-append home "/Pictures")
                          (string-append home "/Videos")
                          (string-append home "/.local/bin")
                          (string-append home "/.local/share")
                          (string-append home "/.local/state")
                          (string-append home "/.cache/wal")
                          (string-append home "/.config/fuzzel")
                          (string-append home "/.config/tofi")
                          (string-append home "/.config/swaylock")
                          (string-append home "/.config/waybar")
                          (string-append home "/.config/eww")
                          (string-append home "/.config/dunst/dunstrc.d")))
              (git-link (string-append home "/git"))
              (data-link (string-append home "/data")))
         (for-each mkdir-p dirs)
         (unless (file-exists? git-link)
           (symlink "/git" git-link))
         (unless (file-exists? data-link)
           (symlink "/data" data-link))))))
