(use-modules (guix profiles))

(specifications->manifest
 '(
   "avrdude"
   "dfu-util"
   "gcc-cross-avr-toolchain"
   ))
