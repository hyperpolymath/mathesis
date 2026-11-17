#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# The Idris2 `partial` modifier is unsafe; an identifier that merely starts
# with "partial" is not. `\b` ends a word before a prime, so the rule
# `^\s*partial\b` used to count every line of a function named `partial'`.
# Regression for the hyperpolymath/hypatia row (unsafe 4, 2026-11-17), whose
# four hits were the clauses of `partial'` in tests/accept/ReceiptP5MissingExact.idr.
set -euo pipefail
SCAN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts/census/proof-holes.sh"
F=$(mktemp -d); trap 'rm -rf "$F"' EXIT
printf '%s\n' 'module Prime' '' "partial' : Nat -> Maybe Nat" "partial' Z = Just 1" "partial' _ = Nothing" \
  'partialBody : Nat' 'partialBody = 0' 'partial_x : Nat' 'partial_x = 0' > "$F/Prime.idr"
printf '%s\n' 'module Real' '' 'partial' 'loop : Nat -> Nat' 'loop n = loop n' '  partial  ' 'f : Nat' > "$F/Real.idr"
got=$(bash "$SCAN" --fail-on none "$F" | jq -r 'select(.class == "unsafe") | "\(.file):\(.line) \(.marker)"' | sort)
want=$(sort <<'WANT'
Real.idr:3 partial
Real.idr:6 partial
WANT
)
[[ "$got" == "$want" ]] || { echo "FAIL: partial modifier versus partial-prefixed identifiers"; diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") || true; exit 1; }
echo "PASS: only the partial modifier counts as unsafe; partial', partialBody and partial_x do not"
