(define-module (system common base)
  #:use-module (gnu services)
  #:use-module (gnu services networking)
  #:use-module (gnu services ssh)
  #:use-module (gnu packages tls)
  #:export (%common-services
            %common-packages))

(define %common-services
  (list
   (service dhcpcd-service-type)
   (service openssh-service-type)))

(define %common-packages
  (list nss-certs))
