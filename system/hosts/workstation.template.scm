(use-modules
 (gnu)
 (gnu system nss)
 (gnu system locale)
 (gnu system file-systems)
 (gnu system mapped-devices)
 (gnu services)
 (guix gexp)
 (system common base)
 (system roles desktop))

(define keyboard-layout
  (keyboard-layout "us"))

(define %mapped-devices
  (list
   (mapped-device
    (source (uuid "{{LUKS_ROOT_UUID}}" 'luks))
    (target "cryptroot")
    (type luks-device-mapping))
   (mapped-device
    (source (uuid "{{LUKS_SWAP_UUID}}" 'luks))
    (target "cryptswap")
    (type luks-device-mapping))))

(define %root-file-systems
  (list
   (file-system
    (mount-point "/")
    (device "/dev/mapper/cryptroot")
    (type "btrfs")
    (flags '(no-atime))
    (options "subvol=@,compress=zstd:3,ssd,space_cache=v2")
    (dependencies %mapped-devices))
   (file-system
    (mount-point "/home")
    (device "/dev/mapper/cryptroot")
    (type "btrfs")
    (flags '(no-atime))
    (options "subvol=@home,compress=zstd:3,ssd,space_cache=v2")
    (dependencies %mapped-devices))
   (file-system
    (mount-point "/var")
    (device "/dev/mapper/cryptroot")
    (type "btrfs")
    (needed-for-boot? #t)
    (flags '(no-atime))
    (options "subvol=@var,compress=zstd:3,ssd,space_cache=v2")
    (dependencies %mapped-devices))
   (file-system
    (mount-point "/.snapshots")
    (device "/dev/mapper/cryptroot")
    (type "btrfs")
    (flags '(no-atime))
    (options "subvol=@snapshots,compress=zstd:3,ssd,space_cache=v2")
    (dependencies %mapped-devices))
   (file-system
    (mount-point "/gnu")
    (device "/dev/mapper/cryptroot")
    (type "btrfs")
    (flags '(no-atime))
    (options "subvol=@gnu,compress=zstd:3,ssd,space_cache=v2")
    (dependencies %mapped-devices))
   (file-system
    (mount-point "/git")
    (device "/dev/mapper/cryptroot")
    (type "btrfs")
    (flags '(no-atime))
    (options "subvol=@git,compress=zstd:3,ssd,space_cache=v2")
    (dependencies %mapped-devices))
   (file-system
    (mount-point "/data")
    (device "/dev/mapper/cryptroot")
    (type "btrfs")
    (flags '(no-atime))
    (options "subvol=@data,compress=zstd:3,ssd,space_cache=v2")
    (dependencies %mapped-devices))
   (file-system
    (mount-point "/boot")
    (device (uuid "{{BOOT_UUID}}" 'ext4))
    (type "ext4"))
   (file-system
    (mount-point "/boot/efi")
    (device (uuid "{{ESP_UUID}}" 'fat32))
    (type "vfat"))))

(define %directory-bootstrap-service
  (simple-service
   'create-workstation-directories
   activation-service-type
   #~(begin
       (use-modules (guix build utils))
       (let* ((pw (getpwnam "philip"))
              (uid (passwd:uid pw))
              (gid (passwd:gid pw))
              (dirs '("/git"
                      "/data")))
         (for-each mkdir-p dirs)
         (for-each (lambda (dir)
                     (chown dir uid gid))
                   dirs)))))

(operating-system
  (host-name "workstation")
  (timezone "Europe/Copenhagen")
  (locale "en_DK.utf8")
  (locale-definitions
   (cons (locale-definition
          (name "en_DK.utf8")
          (source "en_DK"))
         %default-locale-definitions))
  (keyboard-layout keyboard-layout)

  (kernel-arguments
   (append (list "fbcon=rotate:1") %default-kernel-arguments))

  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-bootloader)
    (targets '("/boot/efi"))
    (keyboard-layout keyboard-layout)))

  (mapped-devices %mapped-devices)

  (file-systems (append %root-file-systems %base-file-systems))

  (swap-devices
   (list
    (swap-space
     (target "/dev/mapper/cryptswap")
     (dependencies %mapped-devices))))

  (users
   (cons
    (user-account
     (name "philip")
     (comment "Philip")
     (group "users")
     (home-directory "/home/philip")
     (supplementary-groups '("wheel" "netdev" "audio" "video" "input")))
    %base-user-accounts))

  (packages (append %common-packages %base-packages))

  (services
   (append
    %common-services
    %desktop-services
    (list %directory-bootstrap-service)
    %base-services))

  (name-service-switch %mdns-host-lookup-nss))
