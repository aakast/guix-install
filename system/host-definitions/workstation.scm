(define %host-definition
  '((host-name . "workstation")
    (timezone . "Europe/Copenhagen")
    (locale . "en_DK.utf8")
    (locale-source . "en_DK")
    (kernel-arguments . ("fbcon=rotate:1"))
    (managed-directories . ("/git" "/data"))
    (service-sets . (desktop))
    (primary-user
     (name . "philip")
     (comment . "Philip")
     (group . "users")
     (home-directory . "/home/philip")
     (supplementary-groups . ("wheel" "netdev" "audio" "video" "input")))))
