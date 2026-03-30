(define-module (system common base)
  #:use-module (gnu services)
  #:use-module (gnu services networking)
  #:use-module (gnu services ssh)
  #:export (%common-services
            %common-packages))

(define %common-services
  (list
   (service dhcpcd-service-type
            (dhcpcd-configuration
             (no-hook '("hostname"))))
   (service openssh-service-type)))

;; nss-certs is included in %base-packages by default since Guix 1.4.
;; Add any extra system-wide packages here.
(define %common-packages
  '())
