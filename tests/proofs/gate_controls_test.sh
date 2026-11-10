#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# The proof gate must fail on a planted escape and pass the same module
# without it (re-anchoring plan WO 1.3): an Agda `postulate`, a Rocq
# `Admitted`, a Lean `sorry`. Each of these compiled, or would have, before
# the axiom audit. A decoy in a comment must not fail the gate.
# Usage: bash tests/proofs/gate_controls_test.sh agda|coq|lean4
# Needs the prover on PATH; an absent prover fails, as in the gate itself.
set -euo pipefail
prover=${1:?usage: gate_controls_test.sh agda|coq|lean4}
root=$(cd "$(dirname "$0")/../.." && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
case "$prover" in
  agda)  ext=agda; clean='module Clean where
-- postulate in a comment is not a postulate
data N : Set where
  z : N
  s : N → N'
         planted='module Planted where
postulate X : Set' ;;
  coq)   ext=v; clean='(* Admitted. in a comment *)
Theorem clean : 1 + 1 = 2. Proof. reflexivity. Qed.'
         planted='Theorem planted : 2 + 2 = 5. Admitted.' ;;
  lean4) ext=lean; clean='-- sorry in a comment
theorem clean : 1 + 1 = 2 := rfl'
         planted='theorem planted : 2 + 2 = 5 := by sorry' ;;
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
if run Clean "$clean"; then echo "PASS: $prover clean control passes"
else echo "FAIL: $prover clean control failed"; cat "$t/Clean.log"; fail=1; fi
if run Planted "$planted"; then echo "FAIL: $prover planted escape passed the gate"; cat "$t/Planted.log"; fail=1
else echo "PASS: $prover planted escape fails the gate"; fi
exit "$fail"
