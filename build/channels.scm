;; SPDX-License-Identifier: MPL-2.0
;; channels.scm — the Guix revision this repository's guix.scm and manifest.scm
;; were verified against. Reproduce that exact Guix with:
;;
;;   guix time-machine -C channels.scm -- shell -m manifest.scm
;;
;; Refresh it (after re-verifying) with: just toolchain-refresh
;; Re-pinned for this repository on 2026-11-10 (re-anchoring plan WO 1.4, owner
;; ruling 2026-11-10): from ae77aeb (canon pin of 2026-09-30) to 8edb9da, a
;; commit the Guix build farm evaluated, because at ae77aeb Guix had no
;; substitute for itself and each CI run compiled Guix first. The prover
;; versions are the same at both: Agda 2.7.0.1, Rocq 8.18.0, Lean 4.29.0.
;; PROVISIONING-STANDARD: channels.scm is re-pinned per repository, and is
;; checked for a 40-hex commit pin, not byte-compared with the canon.
(list (channel
       (name 'guix)
       (url "https://codeberg.org/guix/guix.git")
       (branch "master")
       (commit "8edb9da7052607f17f09007933275b43978fcf9d")
       (introduction
        (make-channel-introduction
         "9edb3f66fd807b096b48283debdcddccfea34bad"
         (openpgp-fingerprint
          "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
