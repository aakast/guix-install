(list
 (channel
  (name 'guix)
  (url "https://git.guix.gnu.org/guix.git")
  (branch "master")
  (commit "98c95df79d0352915aff161cc944b979fb9acfba")
  (introduction
   (make-channel-introduction
    "9edb3f66fd807b096b48283debdcddccfea34bad"
    (openpgp-fingerprint
     "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))

 (channel
  (name 'parauix)
  (url "https://github.com/aakast/parauix")
  (branch "main")
  (commit "1a4963b99f11ddcb790df5c0b1c81fbbce9165e7"))

 (channel
  (name 'nonguix)
  (url "https://gitlab.com/nonguix/nonguix")
  (branch "master")
  (commit "62ea83535efec8809187c8110b5583b79d053686")
  (introduction
   (make-channel-introduction
    "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
    (openpgp-fingerprint
     "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))

 (channel
  (name 'sops-guix)
  (url "https://github.com/fishinthecalculator/sops-guix.git")
  (branch "main")
  (commit "a3a890c82b5ff05cbe67636d5b8f7cf92a6f2f82")
  (introduction
   (make-channel-introduction
    "0bbaf1fdd25266c7df790f65640aaa01e6d2dbc9"
    (openpgp-fingerprint
     "8D10 60B9 6BB8 292E 829B  7249 AED4 1CC1 93B7 01E2")))))
