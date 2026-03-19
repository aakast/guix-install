(use-modules (gnu home)
             (gnu home services)
             (home common base)
             (home roles desktop))

(home-environment
 (services
  (list
   (simple-service
    'workstation-env-vars
    home-environment-variables-service-type
    (append home-base-env-vars home-desktop-env-vars))
   home-base-activation-service)))
