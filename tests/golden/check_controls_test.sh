#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Controls for the golden path (re-anchoring plan WO 2.5): `just test` fails on
# a stale view, and `just check-proofs` (a dependency of `just check`, which
# `just test` runs first) fails on a proof that does not check.
#
# Each control runs in a copy of the working tree, so the repository is never
# changed. The proof control needs agda on PATH (CI runs it in the pinned Guix).
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fail=0

copy() { # a fresh copy of the tracked files
  local d=$t/$1
  mkdir -p "$d"
  (cd "$root" && git ls-files -z | xargs -0 cp --parents -t "$d")
  echo "$d"
}

expect_fail() { # name dir recipe want
  local name=$1 dir=$2 recipe=$3 want=$4 out
  if out=$(cd "$dir" && just "$recipe" 2>&1); then
    echo "FAIL: $name: just $recipe passed"; fail=1
  elif [[ "$out" != *"$want"* ]]; then
    printf 'FAIL: %s: just %s failed for another reason:\n%s\n' "$name" "$recipe" "$(tail -5 <<<"$out")"; fail=1
  else
    echo "PASS: $name: just $recipe fails"
  fi
}

# A stale view: the committed catalogue no longer matches the census rows.
d=$(copy stale)
echo '* a row that no census wrote' >> "$d/docs/atlas/generated/catalogue.adoc"
expect_fail "stale catalogue" "$d" test "a row that no census wrote"

# A proof that does not check: a gated Agda module gains a type error.
d=$(copy proof)
printf '\nbroken : Set\nbroken = Set\n' >> "$d/verification/proofs/agda/Properties.agda"
expect_fail "failing proof" "$d" check-proofs "Properties.agda"

exit "$fail"
