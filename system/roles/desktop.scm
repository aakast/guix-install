(define-module (system roles desktop)
  #:use-module (gnu services)
  #:use-module (gnu services desktop)
  #:use-module (gnu services xorg)
  #:use-module (gnu system keyboard)
  #:export (%desktop-services))

(define %desktop-services
  (list
   (service elogind-service-type)
   (set-xorg-configuration
    (xorg-configuration (keyboard-layout (keyboard-layout "dk"))))))
