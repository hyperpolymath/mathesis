# Maths census: proof and formal-verification artefacts

Generated 2026-10-26T17:25Z from blobless shallow clones of each repo's default branch HEAD.

## Totals

| measure | count |
|---|---|
| repos enumerated (hyperpolymath, metadatastician, catachresis-colloquium, stuff-of-awe) | 476 |
| forks skipped | 5 |
| awesome-* list repos skipped | 9 |
| repos in census | 462 |
| unreachable (clone failed) | 37 |
| repos with any proof artefact | 275 |
| proof artefact files | 7770 |
| declarations extracted | 76166 |
| hole-scanner findings | 1492 |

Hole classes (from proof-holes.sh): hole = unfinished proof, axiom = trusted base grows, unsafe = checker switched off, policy = estate rule (Agda without --safe, import Mathlib).

## Repos with artefacts (sorted by declarations)

| repo | provers (files) | decls | holes | axioms | unsafe | policy | Agda --safe / without | proof-status doc |
|---|---|---|---|---|---|---|---|---|
| hyperpolymath/asdf-tool-plugins | idris2 567 | 11340 | 567 | 0 | 0 | 0 |  |  |
| hyperpolymath/proven | idris2 906, lean 14, spark 46, tla 1 | 11166 | 22 | 0 | 10 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt-triage-tier-a.adoc<br>docs/proof-debt-triage.adoc<br>docs/proof-debt.adoc |
| hyperpolymath/proven-servers | idris2 899, spark 198 | 6242 | 3 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/developer-ecosystem | agda 2, idris2 347, lean 3, rocq 274, spark 94, tla 2 | 4024 | 91 | 0 | 61 | 2 | 0 / 2 | PROOF-NEEDS.adoc<br>affinescript-ecosystem/affinescript-vite/.machine_readable/compliance/PROOF-NEEDS.adoc<br>affinescript-ecosystem/affinescript-vite/.machine_readable/compliance/PROOF-STATUS.adoc<br>affinescript-ecosystem/rattlescript/PROOF-NEEDS.adoc<br>affinescript-ecosystem/rattlescript/PROOF-STATUS.adoc<br>affinescript-ecosystem/rattlescript/affinescript/PROOF-NEEDS.adoc<br>rescript-ecosystem/rescript-tea/PROOF-NEEDS.adoc |
| hyperpolymath/echidna | agda 24, alloy 1, dafny 1, fstar 6, idris2 49, isabelle 6, lean 18, rocq 9, smtlib 22, spark 22, tptp 9, why3 1 | 1885 | 4 | 1 | 4 | 23 | 0 / 22 | docs/PROOF-NEEDS.adoc |
| metadatastician/gossamer | idris2 53, tla 9 | 1868 | 0 | 0 | 8 | 0 |  | PROOF-NEEDS.md |
| hyperpolymath/boj-server-cartridges | idris2 184 | 1500 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/echo-types | agda 148 | 1467 | 0 | 1 | 0 | 1 | 146 / 1 | PROOF-STATUS.adoc<br>docs/proof-debt.adoc |
| metadatastician/paint-type | agda 3, idris2 51, lean 2, rocq 1, tla 7 | 1149 | 4 | 0 | 8 | 3 | 0 / 3 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc<br>audits/outstanding_debt/proof-debt.md<br>third_party/gossamer/PROOF-NEEDS.md |
| hyperpolymath/valence-shell | agda 10, idris2 12, isabelle 9, lean 16, rocq 12, smtlib 5 | 960 | 5 | 1 | 0 | 9 | 0 / 9 | PROOF-NEEDS.adoc<br>docs/proof-debt.md |
| hyperpolymath/vcl-ut | idris2 36 | 953 | 0 | 0 | 0 | 0 |  | docs/proof-debt.adoc<br>docs/status/PROOF-NEEDS.adoc |
| hyperpolymath/absolute-zero | agda 5, idris2 5, isabelle 2, lean 11, rocq 16, smtlib 1 | 950 | 7 | 89 | 0 | 4 | 4 / 0 | PROOF-STATUS.adoc<br>docs/archive/PROOF-STATUS-2026-05-18.adoc<br>docs/proof-debt-triage.adoc<br>docs/proof-debt.adoc |
| hyperpolymath/proven-tests-and-benches | idris2 72 | 857 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/typed-wasm | idris2 46 | 850 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt.adoc<br>docs/wiki/Proof-Debt-Status.md |
| hyperpolymath/ambientops | idris2 39, spark 63 | 777 | 39 | 0 | 8 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/gnpl | idris2 4, lean 49 | 737 | 5 | 7 | 0 | 0 |  | docs/proof-debt.adoc |
| hyperpolymath/ephapax | idris2 24, rocq 19 | 635 | 15 | 0 | 1 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt.adoc<br>formal/PROOF-STATUS.a2ml |
| hyperpolymath/my-lang | idris2 9, rocq 16 | 617 | 0 | 26 | 0 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt.md |
| hyperpolymath/trope-checker | agda 11, idris2 25, lean 12, rocq 1, tla 1 | 580 | 10 | 0 | 0 | 2 | 9 / 1 | docs/proof-debt.adoc<br>docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/affinescript | agda 23, idris2 9, lean 1, rocq 21 | 568 | 9 | 1 | 0 | 0 | 23 / 0 | docs/PROOF-NEEDS.adoc |
| hyperpolymath/tropical-types | isabelle 9, lean 19 | 540 | 5 | 0 | 0 | 0 |  | PROOF-STATUS.adoc |
| hyperpolymath/hypatia | agda 1, idris2 29, lean 8, rocq 1, spark 2, tla 2 | 448 | 3 | 1 | 0 | 1 | 0 / 1 | docs/proof-debt.adoc<br>verification/PROOF-STATUS.adoc |
| hyperpolymath/boj-server | alloy 1, idris2 19, tla 6 | 421 | 4 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt.adoc |
| hyperpolymath/wokelang | idris2 8, lean 7, rocq 3 | 418 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/firmboot | agda 19, lean 19 | 409 | 0 | 1 | 0 | 0 | 19 / 0 |  |
| hyperpolymath/ochrance | idris2 48 | 404 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/julia-ecosystem | idris2 25 | 399 | 15 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/resource-algebra | agda 23, idris2 11, lean 2, rocq 1, tla 1 | 372 | 0 | 0 | 0 | 1 | 21 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/lithoglyph | agda 1, idris2 16, lean 10, rocq 1, tla 1 | 365 | 1 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/protocol-squisher | agda 10, idris2 12, isabelle 2, lean 4, rocq 4, smtlib 4, tla 6 | 365 | 2 | 2 | 0 | 0 | 10 / 0 | provenance/PROOF-NEEDS.adoc |
| hyperpolymath/verisimdb | idris2 11, rocq 9 | 365 | 3 | 43 | 0 | 0 |  | docs/proof-debt.adoc |
| hyperpolymath/residual-evidence-types | agda 27 | 328 | 0 | 0 | 0 | 0 | 26 / 0 | PROOF-STATUS.adoc |
| hyperpolymath/epistemic-types | agda 37 | 320 | 0 | 0 | 0 | 0 | 36 / 0 | PROOF-STATUS.adoc |
| catachresis-colloquium/evil-weevil | agda 1, idris2 15, lean 2, rocq 1, tla 1 | 317 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/lol | agda 3, idris2 15 | 314 | 0 | 2 | 0 | 2 | 1 / 2 | docs/proof-debt.md |
| metadatastician/stapeln | alloy 1, idris2 18 | 294 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt.md |
| hyperpolymath/nextgen-databases | idris2 24 | 279 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt.adoc<br>verisim-modular-experiment/PROOF-NEEDS.adoc |
| hyperpolymath/snifs | agda 3, idris2 10, lean 1, rocq 1, tla 1 | 255 | 0 | 0 | 0 | 1 | 2 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc<br>docs/proof-debt.adoc |
| catachresis-colloquium/universal-modding-studio | idris2 25, spark 4 | 254 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/iseriser | idris2 18 | 254 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/ExactCounts.jl | agda 15 | 236 | 0 | 1 | 0 | 6 | 8 / 6 | proofs/PROOF-STATUS.md |
| hyperpolymath/atoma | agda 5, idris2 14, lean 2, rocq 1, smtlib 14, tla 1 | 228 | 0 | 0 | 0 | 5 | 0 / 5 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/jtv-lang | idris2 1, lean 9 | 225 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/docudactyl | idris2 7, spark 6 | 223 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/eclexia | agda 1, idris2 4, rocq 6 | 218 | 0 | 5 | 0 | 1 | 0 / 1 | docs/proof-debt.adoc |
| catachresis-colloquium/game-server-admin | idris2 7 | 212 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/verisimiser | idris2 12 | 208 | 0 | 0 | 0 | 0 |  |  |
| metadatastician/hvn-dehallucinator | agda 5, idris2 11, lean 2, rocq 1, tla 3 | 205 | 0 | 0 | 0 | 0 | 5 / 0 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/enaction-engine | agda 1, idris2 16, lean 2, rocq 1, tla 1 | 199 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/phi-LAM | idris2 6, lean 5 | 199 | 0 | 4 | 0 | 0 |  |  |
| metadatastician/groove | idris2 19 | 185 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/CompositionalCounts.jl | agda 10 | 184 | 0 | 0 | 0 | 0 | 10 / 0 |  |
| hyperpolymath/tlaiser | idris2 9 | 181 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/choreographic-types | agda 25 | 178 | 0 | 1 | 0 | 1 | 23 / 1 | PROOF-STATUS.adoc |
| hyperpolymath/occupancy-types | agda 9, idris2 17, lean 7, rocq 1, tla 1 | 177 | 0 | 0 | 0 | 1 | 7 / 1 | PROOF-STATUS.adoc<br>docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/system-et | idris2 1, lean 22 | 174 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/anytype | agda 1, idris2 25, lean 1, rocq 1, tla 1 | 173 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/betlangiser | idris2 9 | 173 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/kitchenspeak | agda 6, idris2 10, lean 1, rocq 1, tla 1 | 168 | 0 | 4 | 0 | 2 | 3 / 2 | docs/proof-debt.adoc<br>docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/secret-types | agda 17, idris2 11, lean 2, rocq 1, tla 1 | 168 | 0 | 0 | 0 | 1 | 15 / 1 | PROOF-STATUS.adoc<br>docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/bofig | idris2 7 | 166 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/ideas-to-alphas | agda 1, idris2 13, lean 1, rocq 1, tla 1 | 165 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/trigger | agda 2, idris2 5, spark 57 | 165 | 0 | 13 | 0 | 0 | 2 / 0 |  |
| hyperpolymath/deed-core | idris2 15, spark 3 | 161 | 0 | 0 | 10 | 0 |  |  |
| hyperpolymath/halideiser | idris2 9 | 161 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/marches | lean 15 | 161 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/typell | idris2 6 | 159 | 3 | 0 | 0 | 0 |  | PROOF-STATUS.adoc<br>docs/status/PROOF-NEEDS.adoc |
| metadatastician/lintel | agda 7, idris2 11, lean 2, rocq 1, tla 1 | 159 | 0 | 0 | 0 | 1 | 6 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/otpiser | idris2 9 | 157 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/fireflag | idris2 10 | 156 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.md |
| hyperpolymath/oblibeniser | idris2 9 | 156 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/phronesiser | idris2 9 | 155 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/typedqliser | idris2 11 | 155 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/affinescriptiser | idris2 9 | 147 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/nimiser | idris2 9 | 147 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/dafniser | idris2 9 | 146 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/wokelangiser | idris2 9 | 143 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/januskey | agda 3, idris2 8 | 142 | 0 | 0 | 0 | 0 | 3 / 0 | PROOF-NEEDS.adoc |
| hyperpolymath/lustreiser | idris2 9 | 141 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/anvomidaviser | idris2 9 | 140 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/julianiser | idris2 9 | 140 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/phronesis | agda 3, idris2 2, lean 3, rocq 1, tla 3 | 140 | 3 | 0 | 0 | 2 | 0 / 2 |  |
| hyperpolymath/alloyiser | idris2 9 | 139 | 0 | 0 | 0 | 0 |  |  |
| metadatastician/_pathroot | agda 1, idris2 12, lean 2, rocq 1, spark 29, tla 1 | 139 | 3 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/atsiser | idris2 9 | 137 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/ponyiser | idris2 9 | 137 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/chapeliser | idris2 9 | 136 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/futharkiser | idris2 9 | 136 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/mylangiser | idris2 9 | 135 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/ephapaxiser | idris2 9 | 133 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/bqniser | idris2 9 | 132 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/Axiom.jl | idris2 11 | 131 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/krl | agda 2, idris2 12, tla 1 | 131 | 0 | 0 | 0 | 0 | 2 / 0 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/aerie | idris2 8 | 128 | 1 | 0 | 0 | 0 |  | PROOF-NEEDS.md |
| metadatastician/burble | idris2 12 | 127 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.md |
| hyperpolymath/panll | idris2 12 | 125 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>docs/proof-debt.adoc |
| hyperpolymath/stateful-artefacts | agda 1, idris2 11, lean 1, rocq 1, tla 3 | 125 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/sr71-blackglider | agda 1, idris2 12, lean 2, rocq 1, tla 1 | 123 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/ochrance-framework | idris2 14 | 123 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/idrisiser | idris2 9 | 122 | 0 | 0 | 0 | 0 |  |  |
| metadatastician/vordr | idris2 10, spark 13 | 122 | 0 | 0 | 4 | 0 |  |  |
| hyperpolymath/eclexiaiser | idris2 9 | 121 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/quintessence | agda 1, idris2 13, lean 2, rocq 1, tla 3 | 121 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/IDApTIK | idris2 9 | 120 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/ddraig-ssg | idris2 4 | 118 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/dictask | agda 1, idris2 12, lean 2, rocq 1, tla 1 | 118 | 2 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/session-sentinel | idris2 6 | 117 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/patallm-gallery | idris2 4 | 113 | 6 | 0 | 0 | 0 |  | PROOF-NEEDS.md |
| hyperpolymath/universal-chat-extractor | idris2 12 | 110 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/zerotier-k8s-link | idris2 12 | 110 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/autoformal-fidelity | agda 5, idris2 11, lean 2, rocq 1, tla 1 | 108 | 0 | 0 | 0 | 1 | 3 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/ssg-collection | idris2 6, lean 1, spark 16 | 108 | 3 | 0 | 4 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/kategoria | idris2 13 | 105 | 1 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/vexometer | idris2 10, spark 32 | 104 | 3 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| catachresis-colloquium/first-post | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/pong-ping | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/project-ovine | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/Apodeixis.jl | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/CoprocessorRuntime.jl | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/bactrian | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/cicd-squabbler | agda 1, idris2 11, lean 1, rocq 1, spark 3, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/czech-file-knife | agda 1, idris2 11, lean 2, rocq 1, spark 3, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/heron-polyfeed-reader | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/ordinal-notation | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/rsr-template-repo | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/sholes | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/smtp-notify-action | idris2 6 | 101 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/unified-api-adapter | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/xmlpull-zig | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/zig-boringtls | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/zig-dnssec | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/zig-icu-collation | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/zig-unorm | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/bowtie-workbench | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/cadastra | agda 1, idris2 11, lean 1, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/first-post | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/marid | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/odraz | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/sim-public-relations | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 101 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/deed-ecosystem | idris2 8 | 99 | 0 | 0 | 0 | 0 |  | deno/PROOF-NEEDS.adoc<br>haskell/PROOF-NEEDS.adoc<br>members/tooling/vscode-a2ml/PROOF-NEEDS.adoc<br>validate-action/PROOF-NEEDS.adoc |
| hyperpolymath/oblibeny | idris2 9 | 99 | 0 | 0 | 0 | 0 |  | docs/proof-debt.adoc |
| catachresis-colloquium/knot-rider | agda 1, idris2 11, lean 1, rocq 1, tla 1 | 98 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/hermeneia | agda 1, idris2 11, lean 1, rocq 1, tla 1 | 98 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/common-signal | agda 1, idris2 11, lean 2, rocq 1, tla 1 | 96 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/betlang | idris2 11, lean 3 | 95 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc<br>docs/proof-debt.adoc |
| hyperpolymath/zotero-tools | idris2 3, lean 9, tla 3 | 94 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| metadatastician/cerro-torre | idris2 8, spark 77 | 91 | 18 | 0 | 69 | 0 |  |  |
| hyperpolymath/haec | agda 1, idris2 10, lean 1, rocq 1, tla 1 | 89 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/cafescripto | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/contractiles | agda 1, idris2 10, lean 1, rocq 1, spark 36, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/fraying-model-computational-testbed | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/jaffascript | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/llm-grace | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc<br>docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/lucidscript | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/natsci-studio | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/proof-burrower | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/pseudoscript | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/rattlescript | agda 1, idris2 9, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/recon-silly-ation | agda 1, idris2 10, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/scaffoldia | agda 1, idris2 10, lean 1, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/somethings-fishy | agda 1, idris2 9, lean 1, rocq 1, spark 7, tla 1 | 88 | 0 | 0 | 2 | 1 | 0 / 1 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc<br>docs/proof-debt.adoc |
| metadatastician/ZeroInflatedCounts.jl | agda 1, idris2 10, lean 2, rocq 1, tla 1 | 88 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/JuliaPackageSpitter.jl | agda 17 | 83 | 1 | 1 | 1 | 1 | 16 / 1 | PROOF-NEEDS.adoc |
| hyperpolymath/cookie-rebound | idris2 3 | 83 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/k9-ecosystem | idris2 4 | 76 | 0 | 0 | 0 | 0 |  | deno/PROOF-NEEDS.adoc<br>haskell/PROOF-NEEDS.adoc<br>validate-action/PROOF-NEEDS.adoc |
| hyperpolymath/presswerk | idris2 6 | 76 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/ubicity | idris2 7 | 76 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/panoply | idris2 11 | 75 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/rpa-elysium | idris2 6 | 74 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/thunderbird-template-reloaded | idris2 10 | 74 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| catachresis-colloquium/chronicles-of-slavia | agda 1, idris2 7, lean 1, rocq 1, tla 1 | 73 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/ResidualEvidenceTypes.jl | agda 2, idris2 7, lean 2, rocq 1, tla 1 | 70 | 0 | 0 | 0 | 1 | 1 / 1 |  |
| metadatastician/MetaManifold-Evidence | agda 13 | 70 | 0 | 0 | 0 | 0 | 12 / 0 |  |
| hyperpolymath/EpistemicTypes.jl | agda 1, idris2 7, lean 2, rocq 1, tla 1 | 69 | 0 | 0 | 0 | 1 | 0 / 1 |  |
| hyperpolymath/Protoctist.jl | agda 1, idris2 7, lean 2, rocq 1, tla 1 | 69 | 0 | 0 | 0 | 1 | 0 / 1 |  |
| metadatastician/knot-knot | agda 1, idris2 7, lean 2, rocq 1, tla 1 | 69 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/hybrid-automation-router | idris2 5 | 66 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/vocarium | agda 1, idris2 7, lean 1, rocq 1, tla 1 | 66 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/robodog-defensive-systems-lab | idris2 6, spark 7 | 64 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/echidnabot | idris2 3, lean 2, rocq 2 | 63 | 6 | 0 | 0 | 0 |  | docs/proof-debt.adoc |
| hyperpolymath/gitbot-fleet | idris2 3, lean 2, rocq 2 | 63 | 6 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/tangle | lean 3 | 61 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/BowtieRisk.jl | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/Cliodynamics.jl | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/Cliometrics.jl | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/SMTLib.jl | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/cloudguard-cli | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/cloudguard-server | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/ffmpeg-ffi | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/pimcore-fortress | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/unified-dataset-vocab | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/universal-extension-format | idris2 3 | 60 | 3 | 0 | 0 | 0 |  |  |
| catachresis-colloquium/the-nash-equilibrium | idris2 3 | 59 | 3 | 0 | 0 | 0 |  | docs/proof-debt.adoc |
| hyperpolymath/http-capability-gateway | idris2 5 | 59 | 1 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/intsoc-transactor | idris2 3 | 59 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/nesy-solver | idris2 3 | 59 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/raze-tui | idris2 3, spark 19 | 59 | 0 | 0 | 2 | 0 |  |  |
| hyperpolymath/volumod | idris2 3 | 58 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/error-lang | idris2 5 | 57 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/bofj-kitt | agda 1, idris2 6, lean 1, rocq 1, tla 1 | 56 | 0 | 0 | 0 | 1 | 0 / 1 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/glyphbase | idris2 3 | 53 | 0 | 0 | 0 | 0 |  |  |
| metadatastician/ZenodoDeposits.jl | agda 3 | 53 | 0 | 0 | 0 | 0 | 2 / 0 | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/CompositionalDA.jl | agda 11 | 51 | 0 | 1 | 0 | 0 | 9 / 1 | proofs/PROOF-STATUS.md |
| hyperpolymath/veridical-simulation-core | idris2 7 | 51 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/explicit-trust-plane | idris2 3 | 47 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/flatracoon | idris2 3, spark 11 | 47 | 3 | 0 | 0 | 0 |  | PROOF-NEEDS.md |
| hyperpolymath/i-human | idris2 3 | 47 | 3 | 0 | 0 | 0 |  |  |
| hyperpolymath/universal-project-manager | idris2 3 | 47 | 3 | 0 | 0 | 0 |  |  |
| catachresis-colloquium/proof-of-work | idris2 4 | 46 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/boinc-boinc | lean 8 | 46 | 1 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/civic-connect | idris2 4, spark 9 | 46 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/panic-attack | idris2 6 | 46 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/ExactTests.jl | agda 9 | 44 | 0 | 1 | 0 | 1 | 7 / 1 |  |
| hyperpolymath/odds-and-sods-package-manager | idris2 4 | 41 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/feedback-o-tron | idris2 2 | 38 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| metadatastician/cleave | idris2 12 | 38 | 0 | 0 | 0 | 0 |  | docs/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/befunge93-vault-cracker | idris2 5 | 36 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/quandledb | agda 1, idris2 1, tla 3 | 36 | 0 | 0 | 0 | 0 | 1 / 0 | PROOF-NEEDS.adoc |
| hyperpolymath/checky-monkey | idris2 3 | 33 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/voyage-enterprise-decision-system | idris2 3 | 33 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/affinescript-vite | idris2 3 | 32 | 0 | 0 | 0 | 0 |  | .machine_readable/compliance/PROOF-NEEDS.adoc<br>.machine_readable/compliance/PROOF-STATUS.adoc |
| hyperpolymath/laniakea | alloy 1, idris2 7 | 32 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/bebop-ffi | idris2 4 | 29 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/hpm-github-api-rsr | idris2 3 | 28 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/kaldor-iiot | idris2 5 | 27 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/hpm-json-rsr | idris2 3 | 26 | 0 | 0 | 0 | 0 |  |  |
| catachresis-colloquium/megadog | lean 3 | 25 | 0 | 0 | 0 | 3 |  |  |
| metadatastician/insolvency-tycoon | idris2 6 | 25 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/hpm-crypto-rsr | idris2 4 | 24 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/0patch-lsa-sentinel | idris2 2, spark 6 | 23 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/conative-gating | idris2 4 | 23 | 3 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc<br>vendor/bunsenite/PROOF-NEEDS.adoc |
| metadatastician/selur | idris2 2 | 23 | 4 | 0 | 0 | 0 |  |  |
| hyperpolymath/statistikles | agda 4 | 22 | 0 | 0 | 0 | 3 | 0 / 3 | PROOF-NEEDS.adoc |
| metadatastician/standards | idris2 1 | 22 | 0 | 0 | 0 | 0 |  | 3-practice/PROOF-NEEDS.adoc<br>docs/proof-debt.adoc |
| hyperpolymath/neurophone | dafny 1, lean 3, tla 2 | 19 | 0 | 0 | 0 | 6 |  |  |
| hyperpolymath/julia-professional-registry | idris2 4 | 18 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/hpm-http-client-rsr | idris2 3 | 17 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/ipfs-overlay | idris2 5 | 17 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/nextgen-typing | agda 3 | 16 | 0 | 0 | 0 | 0 | 2 / 0 | PROOF-NEEDS.adoc<br>PROOF-STATUS.adoc |
| hyperpolymath/zerostep | isabelle 1 | 16 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/arghda-core | agda 13, idris2 7, isabelle 4, lean 2, rocq 4, smtlib 2 | 15 | 0 | 0 | 0 | 0 | 13 / 0 |  |
| hyperpolymath/continuation-mesh | idris2 5 | 15 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/nextgen-language-evangeliser | idris2 3 | 15 | 0 | 0 | 0 | 0 |  |  |
| catachresis-colloquium/pow-the-game | idris2 4 | 14 | 0 | 0 | 0 | 0 |  |  |
| catachresis-colloquium/enterglide-ncc-137-k | idris2 1 | 13 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/planer-1 | idris2 1 | 13 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/stealth-glider-ecosystem | idris2 1 | 13 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/tardis-rule-disruption | idris2 1 | 13 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| catachresis-colloquium/x15-rocket-glider | idris2 1 | 13 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| metadatastician/affinescript-libraries | idris2 1 | 13 | 0 | 0 | 0 | 0 |  |  |
| metadatastician/authority-watch | idris2 3 | 13 | 0 | 0 | 0 | 0 |  |  |
| metadatastician/consent-aware-web | idris2 1 | 13 | 0 | 0 | 0 | 0 |  | docs/status/PROOF-NEEDS.adoc<br>docs/status/PROOF-STATUS.adoc |
| hyperpolymath/maa-framework | agda 3, spark 6 | 11 | 0 | 0 | 1 | 2 | 0 / 2 | PROOF-NEEDS.adoc<br>docs/proof-debt.adoc |
| hyperpolymath/git-reticulator | idris2 2 | 10 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/phantom-metal-taste | tla 2 | 9 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/conflow | tla 6 | 8 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/invariant-path | agda 1 | 8 | 0 | 0 | 0 | 0 | 1 / 0 |  |
| hyperpolymath/patch-bridge | idris2 3 | 8 | 1 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/reposystem | idris2 1, spark 15 | 7 | 0 | 0 | 2 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/laminar | idris2 1 | 6 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/candy-crash | idris2 1 | 5 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/polyglot-formalisms-elixir | idris2 1 | 5 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/palimpsest-license | agda 5 | 3 | 0 | 0 | 0 | 0 | 5 / 0 | PROOF-NEEDS.adoc |
| hyperpolymath/launch-scaffolder | idris2 2 | 1 | 0 | 0 | 0 | 0 |  |  |
| metadatastician/proglanging-languages | idris2 1 | 1 | 0 | 0 | 0 | 0 |  |  |
| catachresis-colloquium/thejeffparadox | spark 6 | 0 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/bitfuckit | spark 39 | 0 | 0 | 0 | 2 | 0 |  |  |
| hyperpolymath/cloud-sync-tuner | spark 4 | 0 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/docmatrix | spark 11 | 0 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.md |
| hyperpolymath/formatrix-docs | spark 11 | 0 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.md |
| hyperpolymath/modshells | spark 12 | 0 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/network-ambulance | spark 6 | 0 | 0 | 0 | 1 | 0 |  |  |
| hyperpolymath/polyglot-i18n | spark 11 | 0 | 0 | 0 | 0 | 0 |  |  |
| hyperpolymath/resource-record-fluctuator | spark 32 | 0 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |
| hyperpolymath/tree-navigator | spark 16 | 0 | 0 | 0 | 0 | 0 |  | PROOF-NEEDS.adoc |

## Possible test corpora rather than obligations

Repos where artefact paths sit under tests/, fixtures/, examples/, benchmarks/, corpus/, vendor/ and similar, plus echidna's proofs/<prover>/ tree (prover test corpus). Flagged, not dropped; the counts above still include them.

| repo | files under corpus-like paths / all artefact files | sample prefixes |
|---|---|---|
| catachresis-colloquium/enaction-engine | 3 / 21 | verification/tests (3) |
| hyperpolymath/JuliaPackageSpitter.jl | 12 / 17 | tests/reject (7); tests/trusted-base-fixtures (5) |
| hyperpolymath/ResidualEvidenceTypes.jl | 1 / 13 | test/fixtures (1) |
| hyperpolymath/aerie | 2 / 8 | tests/idris2 (2) |
| hyperpolymath/affinescript | 2 / 54 | proposals/nextgen-evangelist (2) |
| hyperpolymath/ambientops | 1 / 102 | nano-aider/tests (1) |
| hyperpolymath/anytype | 1 / 29 | verification/tests (1) |
| hyperpolymath/arghda-core | 32 / 32 | tests/fixtures (32) |
| hyperpolymath/atoma | 17 / 37 | examples/atoma (17) |
| hyperpolymath/autoformal-fidelity | 1 / 20 | tests/reject (1) |
| hyperpolymath/betlang | 9 / 14 | playground/tests (5); tests/idris2 (4) |
| hyperpolymath/choreographic-types | 6 / 25 | tests/minimal-laws (1); tests/reject (5) |
| hyperpolymath/cloud-sync-tuner | 2 / 4 | tests/test_runner.adb (1); tests/verify_formal.adb (1) |
| hyperpolymath/deed-ecosystem | 3 / 8 | showcase/tests (3) |
| hyperpolymath/developer-ecosystem | 46 / 722 | dnfinition/tests (1); idris2-ecosystem/cno (3); idris2-ecosystem/dyadt (3); idris2-ecosystem/echidna (5); v-ecosystem/v_api_interfaces (34) |
| hyperpolymath/echidna | 87 / 168 | examples/simple_proof.v (1); examples/z3_quantifiers.smt2 (1); examples/z3_simple.smt2 (1); proofs/agda (14); proofs/coq (5); proofs/cvc5 (1) |
| hyperpolymath/echo-types | 6 / 148 | proofs/agda (6) |
| hyperpolymath/epistemic-types | 14 / 37 | tests/integration (1); tests/reject (13) |
| hyperpolymath/gnpl | 8 / 53 | test/FFITest.lean (1); test/LexerTest.lean (1); test/NarrationProofAudit.lean (1); test/NarrationTest.lean (1); test/ParserTest.lean (1); test/SubstrateTest.lean (1) |
| hyperpolymath/hypatia | 11 / 43 | test/soundness (4); tests/accept (2); tests/reject (5) |
| hyperpolymath/ipfs-overlay | 4 / 5 | tests/idris2 (4) |
| hyperpolymath/januskey | 5 / 11 | tests/reject-agda (2); tests/reject-idris (3) |
| hyperpolymath/julia-professional-registry | 3 / 4 | tests/idris2 (3) |
| hyperpolymath/kategoria | 3 / 13 | examples/Demo_ProvenArithmetic.idr (1); examples/Demo_SafeAPI.idr (1); examples/Demo_StateMachine.idr (1) |
| hyperpolymath/launch-scaffolder | 2 / 2 | crates/launcher-common (2) |
| hyperpolymath/maa-framework | 2 / 9 | aletheia/templates (2) |
| hyperpolymath/modshells | 2 / 12 | tests/test_shell_manager.adb (1); tests/tests.gpr (1) |
| hyperpolymath/nextgen-databases | 3 / 24 | typeql-experimental/test (3) |
| hyperpolymath/occupancy-types | 2 / 35 | tests/reject (2) |
| hyperpolymath/ochrance | 8 / 48 | tests/A2ML (2); tests/ffi (2); tests/integration (2); tests/property (2) |
| hyperpolymath/palimpsest-license | 4 / 5 | tests/reject (4) |
| hyperpolymath/panic-attack | 1 / 6 | tests/fixtures (1) |
| hyperpolymath/panll | 6 / 12 | panel-clades/tests (6) |
| hyperpolymath/polyglot-formalisms-elixir | 1 / 1 | tests/zigzag (1) |
| hyperpolymath/proven | 62 / 967 | benchmarks/Main.idr (1); benchmarks/SafeCryptoBench.idr (1); benchmarks/SafeJsonBench.idr (1); benchmarks/SafeMathBench.idr (1); benchmarks/SafeNetworkBench.idr (1); benchmarks/SafeStringBench.idr (1) |
| hyperpolymath/proven-tests-and-benches | 27 / 72 | benchmarks/Benchmark.idr (1); benchmarks/benchmark.ipkg (1); corpus/provenance (4); tests/AffineScriptTests (2); tests/HigherOrderTests (4); tests/ProvenLawsTests (2) |
| hyperpolymath/quintessence | 2 / 20 | examples/quintessence (2) |
| hyperpolymath/reposystem | 1 / 16 | tests/test_intervention.adb (1) |
| hyperpolymath/residual-evidence-types | 13 / 27 | tests/correspondence (2); tests/integration (2); tests/reject (9) |
| hyperpolymath/resource-algebra | 12 / 38 | tests/reject (8); tests/unit (4) |
| hyperpolymath/secret-types | 3 / 32 | tests/minimal-laws (1); tests/reject (2) |
| hyperpolymath/thunderbird-template-reloaded | 9 / 10 | tests/idris2 (9) |
| hyperpolymath/trigger | 20 / 64 | tests/benchmark (2); tests/integration (2); tests/security (2); tests/system (2); tests/test_harness-body.adb (1); tests/test_harness.adb (1) |
| hyperpolymath/typed-wasm | 12 / 46 | tests/reject (11); tests/transcription (1) |
| hyperpolymath/ubicity | 6 / 7 | tests/idris2 (6) |
| hyperpolymath/universal-chat-extractor | 9 / 12 | tests/idris2 (9) |
| hyperpolymath/vcl-ut | 15 / 36 | src/interface (2); verification/proofs (13) |
| hyperpolymath/vexometer | 6 / 42 | satellite-template/tests (1); vexometer/tests (5) |
| hyperpolymath/zerotier-k8s-link | 8 / 12 | tests/idris2 (8) |
| metadatastician/cerro-torre | 1 / 85 | tests/ct_test_e2e.adb (1) |
| metadatastician/cleave | 3 / 12 | tests/proofs (3) |
| metadatastician/gossamer | 10 / 62 | tests/idris2 (10) |
| metadatastician/groove | 3 / 19 | tests/proofs (3) |
| metadatastician/hvn-dehallucinator | 3 / 22 | tests/reject (3) |
| metadatastician/lintel | 4 / 22 | tests/accept (2); tests/reject (2) |
| metadatastician/paint-type | 36 / 64 | third_party/gossamer (36) |
| metadatastician/proglanging-languages | 1 / 1 | test/fixtures (1) |
| metadatastician/stapeln | 8 / 19 | tests/idris2 (8) |
| metadatastician/vordr | 2 / 23 | src/ada (2) |

## Proof-status documents

- catachresis-colloquium/airborne-submarine-squadron: `docs/governance/PROOF-NEEDS.adoc`
- catachresis-colloquium/chronicles-of-slavia: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/chronicles-of-slavia: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/enaction-engine: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/enaction-engine: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/enterglide-ncc-137-k: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/enterglide-ncc-137-k: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/evil-weevil: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/evil-weevil: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/first-post: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/first-post: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/game-server-admin: `PROOF-NEEDS.adoc`
- catachresis-colloquium/knot-rider: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/knot-rider: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/planer-1: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/planer-1: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/pong-ping: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/pong-ping: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/project-ovine: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/project-ovine: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/proof-of-work: `PROOF-NEEDS.adoc`
- catachresis-colloquium/sr71-blackglider: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/sr71-blackglider: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/stealth-glider-ecosystem: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/stealth-glider-ecosystem: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/tardis-rule-disruption: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/tardis-rule-disruption: `docs/status/PROOF-STATUS.adoc`
- catachresis-colloquium/the-nash-equilibrium: `docs/proof-debt.adoc`
- catachresis-colloquium/x15-rocket-glider: `docs/status/PROOF-NEEDS.adoc`
- catachresis-colloquium/x15-rocket-glider: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/Apodeixis.jl: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/Apodeixis.jl: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/Axiology.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/Causals.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/Cladistics.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/CompositionalDA.jl: `proofs/PROOF-STATUS.md`
- hyperpolymath/CoprocessorRuntime.jl: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/CoprocessorRuntime.jl: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/ExactCounts.jl: `proofs/PROOF-STATUS.md`
- hyperpolymath/InvestigativeJournalism.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/JuliaKids.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/JuliaPackageSpitter.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/KnotTheory.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/PRComms.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/PolyglotFormalisms.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/PostDisciplinary.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/QuantumCircuit.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/Skein.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/TradeUnionism.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/ZeroProb.jl: `PROOF-NEEDS.adoc`
- hyperpolymath/absolute-zero: `PROOF-STATUS.adoc`
- hyperpolymath/absolute-zero: `docs/archive/PROOF-STATUS-2026-05-18.adoc`
- hyperpolymath/absolute-zero: `docs/proof-debt-triage.adoc`
- hyperpolymath/absolute-zero: `docs/proof-debt.adoc`
- hyperpolymath/academic-workflow-suite: `PROOF-NEEDS.adoc`
- hyperpolymath/accessibility-everywhere: `PROOF-NEEDS.md`
- hyperpolymath/aerie: `PROOF-NEEDS.md`
- hyperpolymath/affinescript-vite: `.machine_readable/compliance/PROOF-NEEDS.adoc`
- hyperpolymath/affinescript-vite: `.machine_readable/compliance/PROOF-STATUS.adoc`
- hyperpolymath/affinescript: `docs/PROOF-NEEDS.adoc`
- hyperpolymath/ambientops: `PROOF-NEEDS.adoc`
- hyperpolymath/anamnesis: `PROOF-NEEDS.adoc`
- hyperpolymath/anytype: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/anytype: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/aspasia: `PROOF-NEEDS.adoc`
- hyperpolymath/atoma: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/atoma: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/autoformal-fidelity: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/autoformal-fidelity: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/bactrian: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/bactrian: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/betlang: `PROOF-NEEDS.adoc`
- hyperpolymath/betlang: `PROOF-STATUS.adoc`
- hyperpolymath/betlang: `docs/proof-debt.adoc`
- hyperpolymath/bgp-backbone-lab: `PROOF-NEEDS.adoc`
- hyperpolymath/bofj-kitt: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/bofj-kitt: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/boinc-boinc: `PROOF-NEEDS.adoc`
- hyperpolymath/boj-server: `PROOF-NEEDS.adoc`
- hyperpolymath/boj-server: `docs/proof-debt.adoc`
- hyperpolymath/branch-newspaper: `PROOF-NEEDS.adoc`
- hyperpolymath/bunsenite: `PROOF-NEEDS.adoc`
- hyperpolymath/cafescripto: `PROOF-NEEDS.adoc`
- hyperpolymath/cafescripto: `PROOF-STATUS.adoc`
- hyperpolymath/cccp: `PROOF-NEEDS.adoc`
- hyperpolymath/chimichanga: `PROOF-NEEDS.adoc`
- hyperpolymath/choreographic-types: `PROOF-STATUS.adoc`
- hyperpolymath/cicd-squabbler: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/cicd-squabbler: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/civic-connect: `PROOF-NEEDS.adoc`
- hyperpolymath/cloud-sync-tuner: `PROOF-NEEDS.adoc`
- hyperpolymath/cloudflare-dns-terraform: `PROOF-NEEDS.adoc`
- hyperpolymath/conative-gating: `PROOF-NEEDS.adoc`
- hyperpolymath/conative-gating: `vendor/bunsenite/PROOF-NEEDS.adoc`
- hyperpolymath/conflow: `PROOF-NEEDS.adoc`
- hyperpolymath/contractiles: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/contractiles: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/cookie-rebound: `PROOF-NEEDS.adoc`
- hyperpolymath/czech-file-knife: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/czech-file-knife: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/deed-ecosystem: `deno/PROOF-NEEDS.adoc`
- hyperpolymath/deed-ecosystem: `haskell/PROOF-NEEDS.adoc`
- hyperpolymath/deed-ecosystem: `members/tooling/vscode-a2ml/PROOF-NEEDS.adoc`
- hyperpolymath/deed-ecosystem: `validate-action/PROOF-NEEDS.adoc`
- hyperpolymath/defiant: `PROOF-NEEDS.adoc`
- hyperpolymath/developer-ecosystem: `PROOF-NEEDS.adoc`
- hyperpolymath/developer-ecosystem: `affinescript-ecosystem/affinescript-vite/.machine_readable/compliance/PROOF-NEEDS.adoc`
- hyperpolymath/developer-ecosystem: `affinescript-ecosystem/affinescript-vite/.machine_readable/compliance/PROOF-STATUS.adoc`
- hyperpolymath/developer-ecosystem: `affinescript-ecosystem/rattlescript/PROOF-NEEDS.adoc`
- hyperpolymath/developer-ecosystem: `affinescript-ecosystem/rattlescript/PROOF-STATUS.adoc`
- hyperpolymath/developer-ecosystem: `affinescript-ecosystem/rattlescript/affinescript/PROOF-NEEDS.adoc`
- hyperpolymath/developer-ecosystem: `rescript-ecosystem/rescript-tea/PROOF-NEEDS.adoc`
- hyperpolymath/dictask: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/dictask: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/docmatrix: `PROOF-NEEDS.md`
- hyperpolymath/dotmatrix-fileprinter: `PROOF-NEEDS.adoc`
- hyperpolymath/double-track-browser: `PROOF-NEEDS.adoc`
- hyperpolymath/echidna: `docs/PROOF-NEEDS.adoc`
- hyperpolymath/echidnabot: `docs/proof-debt.adoc`
- hyperpolymath/echo-types: `PROOF-STATUS.adoc`
- hyperpolymath/echo-types: `docs/proof-debt.adoc`
- hyperpolymath/eclexia: `docs/proof-debt.adoc`
- hyperpolymath/empty-linter: `PROOF-NEEDS.adoc`
- hyperpolymath/ephapax: `PROOF-NEEDS.adoc`
- hyperpolymath/ephapax: `docs/proof-debt.adoc`
- hyperpolymath/ephapax: `formal/PROOF-STATUS.a2ml`
- hyperpolymath/epistemic-types: `PROOF-STATUS.adoc`
- hyperpolymath/error-lang: `PROOF-NEEDS.adoc`
- hyperpolymath/excel-economic-numbers-tool: `PROOF-NEEDS.md`
- hyperpolymath/feedback-o-tron: `PROOF-NEEDS.adoc`
- hyperpolymath/filesoup: `PROOF-NEEDS.adoc`
- hyperpolymath/fireflag: `PROOF-NEEDS.md`
- hyperpolymath/flatracoon: `PROOF-NEEDS.md`
- hyperpolymath/formatrix-docs: `PROOF-NEEDS.md`
- hyperpolymath/fraying-model-computational-testbed: `PROOF-NEEDS.adoc`
- hyperpolymath/fraying-model-computational-testbed: `PROOF-STATUS.adoc`
- hyperpolymath/git-reticulator: `PROOF-NEEDS.adoc`
- hyperpolymath/gitbot-fleet: `PROOF-NEEDS.adoc`
- hyperpolymath/gnpl: `docs/proof-debt.adoc`
- hyperpolymath/gv-clade-index: `PROOF-NEEDS.adoc`
- hyperpolymath/haec: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/haec: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/hermeneia: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/hermeneia: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/heron-polyfeed-reader: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/heron-polyfeed-reader: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/http-capability-gateway: `PROOF-NEEDS.adoc`
- hyperpolymath/hybrid-automation-router: `PROOF-NEEDS.adoc`
- hyperpolymath/hypatia: `docs/proof-debt.adoc`
- hyperpolymath/hypatia: `verification/PROOF-STATUS.adoc`
- hyperpolymath/ideas-to-alphas: `PROOF-NEEDS.adoc`
- hyperpolymath/ideas-to-alphas: `PROOF-STATUS.adoc`
- hyperpolymath/jaffascript: `PROOF-NEEDS.adoc`
- hyperpolymath/jaffascript: `PROOF-STATUS.adoc`
- hyperpolymath/januskey: `PROOF-NEEDS.adoc`
- hyperpolymath/julia-ecosystem: `PROOF-NEEDS.adoc`
- hyperpolymath/k9-ecosystem: `deno/PROOF-NEEDS.adoc`
- hyperpolymath/k9-ecosystem: `haskell/PROOF-NEEDS.adoc`
- hyperpolymath/k9-ecosystem: `validate-action/PROOF-NEEDS.adoc`
- hyperpolymath/kategoria: `PROOF-NEEDS.adoc`
- hyperpolymath/kategoria: `PROOF-STATUS.adoc`
- hyperpolymath/kea: `PROOF-NEEDS.adoc`
- hyperpolymath/kitchenspeak: `docs/proof-debt.adoc`
- hyperpolymath/kitchenspeak: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/kitchenspeak: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/krl: `PROOF-NEEDS.adoc`
- hyperpolymath/krl: `PROOF-STATUS.adoc`
- hyperpolymath/laminar: `PROOF-NEEDS.adoc`
- hyperpolymath/laniakea: `PROOF-NEEDS.adoc`
- hyperpolymath/lithoglyph: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/lithoglyph: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/llm-grace: `PROOF-NEEDS.adoc`
- hyperpolymath/llm-grace: `PROOF-STATUS.adoc`
- hyperpolymath/llm-grace: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/llm-grace: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/lol: `docs/proof-debt.md`
- hyperpolymath/lucidscript: `PROOF-NEEDS.adoc`
- hyperpolymath/lucidscript: `PROOF-STATUS.adoc`
- hyperpolymath/maa-framework: `PROOF-NEEDS.adoc`
- hyperpolymath/maa-framework: `docs/proof-debt.adoc`
- hyperpolymath/metadata-grammar: `PROOF-NEEDS.adoc`
- hyperpolymath/misinformation-defence-platform: `PROOF-NEEDS.adoc`
- hyperpolymath/modshells: `PROOF-NEEDS.adoc`
- hyperpolymath/my-lang: `PROOF-NEEDS.adoc`
- hyperpolymath/my-lang: `docs/proof-debt.md`
- hyperpolymath/natsci-studio: `PROOF-NEEDS.adoc`
- hyperpolymath/natsci-studio: `PROOF-STATUS.adoc`
- hyperpolymath/neural-foundations: `PROOF-NEEDS.adoc`
- hyperpolymath/nextgen-databases: `PROOF-NEEDS.adoc`
- hyperpolymath/nextgen-databases: `docs/proof-debt.adoc`
- hyperpolymath/nextgen-databases: `verisim-modular-experiment/PROOF-NEEDS.adoc`
- hyperpolymath/nextgen-languages: `PROOF-NEEDS.adoc`
- hyperpolymath/nextgen-typing: `PROOF-NEEDS.adoc`
- hyperpolymath/nextgen-typing: `PROOF-STATUS.adoc`
- hyperpolymath/nickel-augmentation: `PROOF-NEEDS.adoc`
- hyperpolymath/no-nonsense-nntps: `PROOF-NEEDS.adoc`
- hyperpolymath/oblibeny: `docs/proof-debt.adoc`
- hyperpolymath/occupancy-types: `PROOF-STATUS.adoc`
- hyperpolymath/occupancy-types: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/occupancy-types: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/ochrance-framework: `PROOF-NEEDS.adoc`
- hyperpolymath/ochrance: `PROOF-NEEDS.adoc`
- hyperpolymath/odds-and-sods-package-manager: `PROOF-NEEDS.adoc`
- hyperpolymath/ordinal-notation: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/ordinal-notation: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/palimpsest-license: `PROOF-NEEDS.adoc`
- hyperpolymath/panic-attack: `PROOF-NEEDS.adoc`
- hyperpolymath/panll: `PROOF-NEEDS.adoc`
- hyperpolymath/panll: `docs/proof-debt.adoc`
- hyperpolymath/panoply: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/panoply: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/patallm-gallery: `PROOF-NEEDS.md`
- hyperpolymath/patch-bridge: `PROOF-NEEDS.adoc`
- hyperpolymath/php-aegis: `PROOF-NEEDS.adoc`
- hyperpolymath/plasma-parser-writer: `PROOF-NEEDS.adoc`
- hyperpolymath/polyglot-formalisms-elixir: `PROOF-NEEDS.adoc`
- hyperpolymath/polyglot-formalisms-gleam: `PROOF-NEEDS.adoc`
- hyperpolymath/polysafe-gitfixer: `PROOF-NEEDS.adoc`
- hyperpolymath/proof-burrower: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/proof-burrower: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/protocol-squisher: `provenance/PROOF-NEEDS.adoc`
- hyperpolymath/proven-servers: `PROOF-NEEDS.adoc`
- hyperpolymath/proven: `PROOF-NEEDS.adoc`
- hyperpolymath/proven: `docs/proof-debt-triage-tier-a.adoc`
- hyperpolymath/proven: `docs/proof-debt-triage.adoc`
- hyperpolymath/proven: `docs/proof-debt.adoc`
- hyperpolymath/pseudoscript: `PROOF-NEEDS.adoc`
- hyperpolymath/pseudoscript: `PROOF-STATUS.adoc`
- hyperpolymath/quandledb: `PROOF-NEEDS.adoc`
- hyperpolymath/quintessence: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/quintessence: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/rattlescript: `PROOF-NEEDS.adoc`
- hyperpolymath/rattlescript: `PROOF-STATUS.adoc`
- hyperpolymath/recon-silly-ation: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/recon-silly-ation: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/reposystem: `PROOF-NEEDS.adoc`
- hyperpolymath/residual-evidence-types: `PROOF-STATUS.adoc`
- hyperpolymath/resource-algebra: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/resource-algebra: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/resource-record-fluctuator: `PROOF-NEEDS.adoc`
- hyperpolymath/rpa-elysium: `PROOF-NEEDS.adoc`
- hyperpolymath/rsr-template-repo: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/rsr-template-repo: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/sanctify-php: `PROOF-NEEDS.adoc`
- hyperpolymath/scaffoldia: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/scaffoldia: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/seamstress: `PROOF-NEEDS.adoc`
- hyperpolymath/secret-types: `PROOF-STATUS.adoc`
- hyperpolymath/secret-types: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/secret-types: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/sholes: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/sholes: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/snifs: `PROOF-NEEDS.adoc`
- hyperpolymath/snifs: `PROOF-STATUS.adoc`
- hyperpolymath/snifs: `docs/proof-debt.adoc`
- hyperpolymath/somethings-fishy: `PROOF-NEEDS.adoc`
- hyperpolymath/somethings-fishy: `PROOF-STATUS.adoc`
- hyperpolymath/somethings-fishy: `docs/proof-debt.adoc`
- hyperpolymath/squeakwell: `PROOF-NEEDS.adoc`
- hyperpolymath/ssg-collection: `PROOF-NEEDS.adoc`
- hyperpolymath/stateful-artefacts: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/stateful-artefacts: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/statistikles: `PROOF-NEEDS.adoc`
- hyperpolymath/system-et: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/system-et: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/tangle: `PROOF-NEEDS.adoc`
- hyperpolymath/thunderbird-template-reloaded: `PROOF-NEEDS.adoc`
- hyperpolymath/tree-navigator: `PROOF-NEEDS.adoc`
- hyperpolymath/trope-checker: `docs/proof-debt.adoc`
- hyperpolymath/trope-checker: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/trope-checker: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/tropical-types: `PROOF-STATUS.adoc`
- hyperpolymath/twingate-helm-deploy: `PROOF-NEEDS.adoc`
- hyperpolymath/typed-wasm: `PROOF-NEEDS.adoc`
- hyperpolymath/typed-wasm: `docs/proof-debt.adoc`
- hyperpolymath/typed-wasm: `docs/wiki/Proof-Debt-Status.md`
- hyperpolymath/typedqliser: `PROOF-NEEDS.adoc`
- hyperpolymath/typell: `PROOF-STATUS.adoc`
- hyperpolymath/typell: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/ubicity: `PROOF-NEEDS.adoc`
- hyperpolymath/unified-api-adapter: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/unified-api-adapter: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/universal-chat-extractor: `PROOF-NEEDS.adoc`
- hyperpolymath/universal-language-server-plugin: `PROOF-NEEDS.adoc`
- hyperpolymath/valence-shell: `PROOF-NEEDS.adoc`
- hyperpolymath/valence-shell: `docs/proof-debt.md`
- hyperpolymath/vcl-ut: `docs/proof-debt.adoc`
- hyperpolymath/vcl-ut: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/verisimdb-data: `PROOF-NEEDS.adoc`
- hyperpolymath/verisimdb: `docs/proof-debt.adoc`
- hyperpolymath/vexometer: `PROOF-NEEDS.adoc`
- hyperpolymath/vocarium: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/vocarium: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/wokelang: `PROOF-NEEDS.adoc`
- hyperpolymath/wordpress-tools: `PROOF-NEEDS.adoc`
- hyperpolymath/xmlpull-zig: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/xmlpull-zig: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/zerostep: `PROOF-NEEDS.adoc`
- hyperpolymath/zig-boringtls: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/zig-boringtls: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/zig-dnssec: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/zig-dnssec: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/zig-icu-collation: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/zig-icu-collation: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/zig-unorm: `docs/status/PROOF-NEEDS.adoc`
- hyperpolymath/zig-unorm: `docs/status/PROOF-STATUS.adoc`
- hyperpolymath/zotero-tools: `PROOF-NEEDS.adoc`
- metadatastician/ZenodoDeposits.jl: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/ZenodoDeposits.jl: `docs/status/PROOF-STATUS.adoc`
- metadatastician/ZeroInflatedCounts.jl: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/ZeroInflatedCounts.jl: `docs/status/PROOF-STATUS.adoc`
- metadatastician/_pathroot: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/_pathroot: `docs/status/PROOF-STATUS.adoc`
- metadatastician/bowtie-workbench: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/bowtie-workbench: `docs/status/PROOF-STATUS.adoc`
- metadatastician/burble: `PROOF-NEEDS.md`
- metadatastician/cadastra: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/cadastra: `docs/status/PROOF-STATUS.adoc`
- metadatastician/cleave: `docs/PROOF-NEEDS.adoc`
- metadatastician/cleave: `docs/status/PROOF-STATUS.adoc`
- metadatastician/common-signal: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/common-signal: `docs/status/PROOF-STATUS.adoc`
- metadatastician/consent-aware-web: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/consent-aware-web: `docs/status/PROOF-STATUS.adoc`
- metadatastician/first-post: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/first-post: `docs/status/PROOF-STATUS.adoc`
- metadatastician/gossamer: `PROOF-NEEDS.md`
- metadatastician/hvn-dehallucinator: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/hvn-dehallucinator: `docs/status/PROOF-STATUS.adoc`
- metadatastician/knot-knot: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/knot-knot: `docs/status/PROOF-STATUS.adoc`
- metadatastician/lintel: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/lintel: `docs/status/PROOF-STATUS.adoc`
- metadatastician/marid: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/marid: `docs/status/PROOF-STATUS.adoc`
- metadatastician/odraz: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/odraz: `docs/status/PROOF-STATUS.adoc`
- metadatastician/paint-type: `PROOF-NEEDS.adoc`
- metadatastician/paint-type: `PROOF-STATUS.adoc`
- metadatastician/paint-type: `audits/outstanding_debt/proof-debt.md`
- metadatastician/paint-type: `third_party/gossamer/PROOF-NEEDS.md`
- metadatastician/sim-public-relations: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/sim-public-relations: `docs/status/PROOF-STATUS.adoc`
- metadatastician/spline: `docs/status/PROOF-NEEDS.adoc`
- metadatastician/spline: `docs/status/PROOF-STATUS.adoc`
- metadatastician/standards: `3-practice/PROOF-NEEDS.adoc`
- metadatastician/standards: `docs/proof-debt.adoc`
- metadatastician/stapeln: `PROOF-NEEDS.adoc`
- metadatastician/stapeln: `docs/proof-debt.md`
- metadatastician/svalinn: `PROOF-NEEDS.md`

## Unreachable

- catachresis-colloquium/reflexive-ai-studio: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/007-lang: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/HOL: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/achievements-lab: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/ai-cli-lab: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/axel-protocol: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/blog-drafts: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/claude-config-vault: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/claude-memory: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/contractiles-a2-lab: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/cut-calculus: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/dev-notes-vault: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/dev-notes: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/dotfiles: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/echobox: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/email-octad-experiment: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/estate-scripts: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/frayed-knot-toolkit: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/fumble: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/git-seo: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/hottchpotch: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/hyperpolymath-sovereign-registry: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/info: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/jewell.nexus: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/jonathanjewell.dev: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/lcb-website: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/lfs-shared: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/linguist: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/memory-vault: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/poly-observability-mcp: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/polystack: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/rescript: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/squisher-corpus: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/this-ssg: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/tools: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/typefix-zero: fatal: could not read Username for 'https://github.com': terminal prompts disabled
- hyperpolymath/vex-tools: fatal: could not read Username for 'https://github.com': terminal prompts disabled

## Method and caveats

- Enumeration used the session's list_repos tool (per-letter substring queries). Every repo it returned has pushed_at on or after 2026-09-15, so repos untouched since then may be missing from the listing.
- Declarations are grep/awk best effort. Agda and Idris2 count every column-0 `name : type` signature (helpers included), plus data/record names and postulated names; Lean/Rocq/Isabelle use keyword rules; TLA+ counts THEOREM/LEMMA and .cfg INVARIANT/PROPERTY names. SMT-LIB, TPTP, Dafny, F*, Why3, Alloy and SPARK files are counted as files only.
- .v files count only in repos with Rocq signs (_CoqProject, dune with coq, or a .v containing Require/Theorem); Verilog-looking files are skipped. .p counts only with TPTP formulas, .lp only with Lambdapi keywords, .ads/.adb only when the repo has a .gpr or SPARK_Mode.
- Hole counts are textual (proof-holes.sh); a kernel-level audit is the authority.
