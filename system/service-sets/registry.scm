(define-module (system service-sets registry)
  #:use-module (srfi srfi-1)
  #:export (resolve-service-set))

(define %service-set-map
  '((desktop
     (module . (system service-sets desktop))
     (services-variable . %desktop-services)
     (packages-variable . %desktop-packages)
     (kernel-arguments-variable . %desktop-kernel-arguments))))

(define (resolve-service-set name)
  (let ((entry (assoc name %service-set-map)))
    (if entry
        (cdr entry)
        (error "Unknown service set" name))))
