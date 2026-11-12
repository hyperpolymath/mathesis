;; SPDX-License-Identifier: MPL-2.0
;; SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
;;
;; manifest.scm — the Guix development shell for mathesis.
;;
;;   guix shell -m manifest.scm                  # or: just dev-shell
;;   guix time-machine -C channels.scm -- shell -m manifest.scm   # the pinned Guix
;;
;; Minted by provision-set from the languages detected here (idris2, zig).
;; Tools Guix does not package: idris2 (via pack). They come from mise, which this
;; shell provides:  guix shell -m manifest.scm -- mise install
;; Canon: hyperpolymath/standards 3-practice/provisioning/PROVISIONING-STANDARD.adoc
(specifications->manifest
 (list "git" "bash" "coreutils" "nss-certs" "just" "mise"
       "shellcheck" "chez-scheme" "gmp" "gcc-toolchain" "zig"
       ;; Provers for the proof lanes (re-anchoring plan WO 1.4, ruling D-8 (a)).
       ;; No agda-stdlib: its Guix package does not build, and no proof here
       ;; imports it (owner ruling 2026-11-10).
       "agda" "coq" "lean4"
       ;; Static site of the generated views (re-anchoring plan WO 4.3).
       "ruby-asciidoctor"))
