(define-module (home common base)
  #:use-module (gnu home services)
  #:use-module (guix gexp)
  #:export (home-base-env-vars
            home-base-activation-service))

(define home-base-env-vars
  '(("EDITOR" . "nvim")
    ("PAGER" . "less")
    ("XDG_STATE_HOME" . "$HOME/.local/state")))

(define home-base-activation-service
  (simple-service
   'home-base-directories
   home-activation-service-type
   #~(begin
       (use-modules (guix build utils)
                    (ice-9 passwd))
       (let* ((home (passwd:dir (getpwuid (getuid))))
              (dirs (list (string-append home "/src")
                          (string-append home "/docs")
                          (string-append home "/tmp")
                          (string-append home "/.local/bin")
                          (string-append home "/.local/share")
                          (string-append home "/.local/state")))
              (git-link (string-append home "/git"))
              (data-link (string-append home "/data")))
         (for-each mkdir-p dirs)
         (unless (file-exists? git-link)
           (symlink "/git" git-link))
         (unless (file-exists? data-link)
           (symlink "/data" data-link))))))
