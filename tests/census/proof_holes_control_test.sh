#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# A file that declares itself a negative control (a header line comment
# `EXPECT: <pattern>`, as in CompositionalDA.jl proofs/agda/reject/) has its
# findings reported as class "control", not "axiom"/"policy". The same marker in
# a file with no EXPECT line is still an axiom, and --fail-on is unaffected by
# a control. Regression for the CompositionalDA.jl row (axioms 1, 2026-11-10).
set -euo pipefail
SCAN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/census/proof-holes.sh"
F=$(mktemp -d); trap 'rm -rf "$F"' EXIT
printf '%s\n' '-- Negative control.' '-- EXPECT: [Pp]ostulate' 'module reject.P where' 'postulate z : Set' > "$F/Control.agda"
printf '%s\n' '{-# OPTIONS --safe #-}' 'module Real where' 'postulate z : Set' > "$F/Real.agda"
printf '%s\n' '{-# OPTIONS --safe #-}' 'module Prose where' '-- see EXPECT: in the control' 'postulate y : Set' > "$F/Prose.agda"
got=$(bash "$SCAN" --fail-on none "$F" | jq -r '"\(.file):\(.line) \(.class) \(.marker)"' | sort)
want=$(sort <<'WANT'
Control.agda:1 control no --safe
Control.agda:4 control postulate
Prose.agda:4 axiom postulate
Real.agda:3 axiom postulate
WANT
)
[[ "$got" == "$want" ]] || { echo "FAIL: control classification differs"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") || true; exit 1; }
rm "$F/Real.agda" "$F/Prose.agda"
bash "$SCAN" --fail-on any "$F" >/dev/null || { echo "FAIL: a control alone must not fail --fail-on any"; exit 1; }
echo "PASS: negative-control findings classed control, real and prose-only files still axioms"

# Identifier controls: a keyword followed by a prime is an identifier, not the
# keyword (`'` is not a word character, so a bare \b matched `partial'`). Found
# in hyperpolymath/hypatia tests/accept/ReceiptP5MissingExact.idr, which defines
# a total function `partial'` and was counted as 4 `unsafe` lines.
P=$(mktemp -d); trap 'rm -rf "$F" "$P"' EXIT
printf '%s\n' 'module Ids' "partial' : Body -> Nat" "partial' x = 0" "partial'' : Nat" 'partial_sum : Nat' 'partialApply : Nat' \
  "y = believe_me' 1" "z = assert_total' 2" > "$P/Ids.idr"
printf '%s\n' "theorem t' : True := sorry'" "axiom' x : Nat" > "$P/Ids.lean"
printf '%s\n' "Axiom' f : nat." > "$P/Ids.v"
got=$(bash "$SCAN" --fail-on none "$P" | jq -r 'select(.class=="hole" or .class=="unsafe" or (.class=="axiom" and .marker!="undefined declaration")) | "\(.file):\(.line) \(.class) \(.marker)"')
[[ -z "$got" ]] || { echo "FAIL: identifiers with a trailing prime were counted:"; echo "$got"; exit 1; }
# Positive controls: the real keywords still count.
rm "$P"/*
printf '%s\n' 'module Real' 'partial' 'f : Nat -> Nat' '  partial' 'g : Nat -> Nat' 'partial h : Nat' 'y = believe_me 1' > "$P/Real.idr"
printf '%s\n' 'theorem t : True := sorry' 'axiom a : Nat' > "$P/Real.lean"
got=$(bash "$SCAN" --fail-on none "$P" | jq -r 'select(.marker!="undefined declaration") | "\(.file):\(.line) \(.class) \(.marker)"' | sort)
want=$(sort <<'WANT'
Real.idr:2 unsafe partial
Real.idr:4 unsafe partial
Real.idr:6 unsafe partial
Real.idr:7 hole believe_me
Real.lean:1 hole sorry
Real.lean:2 axiom axiom
WANT
)
[[ "$got" == "$want" ]] || { echo "FAIL: real keywords no longer counted"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") || true; exit 1; }
echo "PASS: trailing-prime identifiers not counted, real partial/believe_me/sorry/axiom still counted"
