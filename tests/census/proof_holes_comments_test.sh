#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# proof-holes.sh must report markers in code and skip the same markers in
# comments and strings (nested block comments, comments spanning lines,
# trailing line comments), while keeping Agda/Idris pragmas.
set -euo pipefail

SCAN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/census/proof-holes.sh"
F=$(mktemp -d)
trap 'rm -rf "$F"' EXIT

printf '%s\n' 'Require Import Arith.' '(* comment *) Lemma a : False. Admitted.' 'Axioms x y : nat.' \
  '(* Admitted.' '   Axiom z. *)' 'Unset Guard Checking.' 'Definition s := "Admitted.".' > "$F/A.v"
printf '%s\n' '{-# OPTIONS --safe --type-in-type #-}' 'module B where' '{- postulate q {- n -} -}' \
  'postulate p : Set -- postulate r' '{-# TERMINATING #-}' 'f = {! !}' > "$F/B.agda"
printf '%s\n' 'module C' '%default partial' '{- believe_me -}' 'x = believe_me 3 -- believe_me' \
  '||| believe_me in doc' '0 postulated : Void' '%foreign "C:f,libc"' 'export' 'ffi : Int -> Int' 'infixl 5 `snoc`' 'snoc : Nat -> Nat -> Nat' 'a `snoc` b = a' > "$F/C.idr"
printf '%s\n' 'theorem t : False := by sorry' '/- sorry' ' axiom a : False -/' 'axiom b : False' \
  'def s := "sorry"' > "$F/D.lean"
printf '%s\n' '/* #[trusted] */' '#[trusted]' 'fn f() { creusot::x; }' > "$F/E.rs"
printf '%s\n' 'pragma Assume (X);' '-- pragma Assume (Y);' > "$F/F.adb"
printf '%s\n' 'lemma x: "A" sorry' '(* sorry *)' > "$F/G.thy"

got=$(bash "$SCAN" --fail-on none "$F" | jq -r '"\(.file):\(.line) \(.marker)"' | sort)
want=$(sort <<'WANT'
A.v:2 Admitted
A.v:3 Axiom
A.v:6 Unset Checking
B.agda:1 --type-in-type
B.agda:4 postulate
B.agda:5 TERMINATING
B.agda:6 {! !}
C.idr:2 %default partial
C.idr:4 believe_me
C.idr:6 undefined declaration
D.lean:1 sorry
D.lean:4 axiom
E.rs:2 #[trusted]
F.adb:1 pragma Assume
G.thy:1 sorry
WANT
)
if [ "$got" != "$want" ]; then
  echo "FAIL: proof-holes.sh findings differ from the expected set"
  diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") || true
  exit 1
fi
bash "$SCAN" "$F" >/dev/null && { echo "FAIL: --fail-on hole passed although holes exist"; exit 1; }
echo "PASS: 15 markers in code reported, comment and string decoys skipped"
