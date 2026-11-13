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
