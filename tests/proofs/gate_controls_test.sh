#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# The proof gate must fail on a planted escape and pass the same module
# without it (re-anchoring plan WO 1.3): an Agda `postulate`, a Rocq
# `Admitted`, a Lean `sorry`. Each of these compiled, or would have, before
# the axiom audit. A decoy in a comment must not fail the gate.
# For Rocq and Lean the escape is also planted in a DEFINITION, and a module
# with nothing to audit is planted too. Before the audit covered definitions
# and refused an empty domain, all four of those passed (measured 2026-11-17).
# Rocq also gets the escapes that a reading of the source misses, each beside a
# clean theorem: a Local Definition, a #[local] attribute, a Program
# obligation, an Instance, an unused Axiom, a guard bypass and an Admitted in
# a nested Module (coqchk -o catches them; before it, an unused
# `Local Definition planted : False. Admitted.` passed). Lean gets an unused
# axiom beside a clean theorem, which also passed before 2026-11-17. A
# definition-only module must pass, so that the audit is not refusing a whole
# kind of declaration, and so must a declaration that sits in a comment.
# Usage: bash tests/proofs/gate_controls_test.sh agda|coq|lean4
# Needs the prover on PATH; an absent prover fails, as in the gate itself.
set -euo pipefail
prover=${1:?usage: gate_controls_test.sh agda|coq|lean4}
root=$(cd "$(dirname "$0")/../.." && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
# Each list holds "Name|body" entries; a body may span lines.
must_pass=() must_fail=()
case "$prover" in
  agda)  ext=agda
         must_pass+=('Clean|module Clean where
-- postulate in a comment is not a postulate
data N : Set where
  z : N
  s : N → N')
         must_fail+=('Planted|module Planted where
postulate X : Set') ;;
  coq)   ext=v
         ok='Theorem clean : 1 + 1 = 2. Proof. reflexivity. Qed.'
         must_pass+=("Clean|(* Admitted. in a comment *)
$ok"
           'CleanDef|Definition clean : nat := 0.'
           "Commented|(*
Definition documentation_example := 0.
(* nested *) Lemma also_not_real : False.
*)
$ok")
         must_fail+=('Planted|Theorem planted : 2 + 2 = 5. Admitted.'
           'PlantedDef|Definition planted : 2 + 2 = 5.
Admitted.'
           'Empty|(* nothing to audit *)'
           "PlantedLocal|Definition clean_def : nat := 0.
$ok
Local Definition planted : False.
Admitted."
           "PlantedAttr|$ok
#[local] Definition planted : nat.
Admitted."
           "PlantedProgram|From Coq Require Import Program.Tactics.
$ok
Program Definition planted : False := _.
Next Obligation. Admitted."
           "PlantedInstance|$ok
Class K := { k : False }.
Instance planted : K.
Admitted."
           "PlantedAxiom|$ok
Axiom planted : False."
           "PlantedGuard|$ok
#[bypass_check(guard)] Fixpoint loop (n : nat) : nat := loop n."
           "PlantedModule|$ok
Module Inner.
Definition hidden : False.
Admitted.
End Inner.") ;;
  lean4) ext=lean
         ok='theorem clean : 1 + 1 = 2 := rfl'
         must_pass+=("Clean|-- sorry in a comment
$ok"
           'CleanDef|def clean : Nat := 0')
         must_fail+=('Planted|theorem planted : 2 + 2 = 5 := by sorry'
           'PlantedDef|def planted : 2 + 2 = 5 := sorry'
           'Empty|-- nothing to audit'
           "PlantedAxiom|$ok
axiom planted : False") ;;
  *) echo "unknown prover: $prover" >&2; exit 2 ;;
esac
run() { # name body -> exit status of the gate on a tree holding that module
  local name=$1 body=$2 d=$t/$1
  mkdir -p "$d/scripts" "$d/verification/proofs/$prover"
  cp "$root/scripts/check-proofs.sh" "$root/scripts/scan-postulates.sh" "$d/scripts/"
  printf '%s\n' "$body" > "$d/verification/proofs/$prover/$name.$ext"
  echo "verification/proofs/$prover|$name.$ext|gated| control" > "$d/verification/proofs/$prover/MANIFEST"
  bash "$d/scripts/check-proofs.sh" "$prover" > "$d.log" 2>&1
}
fail=0
for e in "${must_pass[@]}"; do
  name=${e%%|*}
  if run "$name" "${e#*|}"; then echo "PASS: $prover control $name passes the gate"
  else echo "FAIL: $prover control $name should pass the gate"; cat "$t/$name.log"; fail=1; fi
done
for e in "${must_fail[@]}"; do
  name=${e%%|*}
  if run "$name" "${e#*|}"; then echo "FAIL: $prover control $name passed the gate"; cat "$t/$name.log"; fail=1
  else echo "PASS: $prover control $name fails the gate"; fi
done
echo "$prover: ${#must_pass[@]} control(s) must pass, ${#must_fail[@]} must fail"
exit "$fail"
