#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Controls for the golden path (re-anchoring plan WO 2.5): `just test` fails on
# a stale view; `just check-proofs` (a dependency of `just check`, which
# `just test` runs first) fails on a proof that does not check; and it fails
# when a worked cohort example reads a missing value as zero (WO 4.2).
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
printf '\nbroken : Set\nbroken = Set\n' >> "$d/verification/proofs/agda/FeatureReachability.agda"
expect_fail "failing proof" "$d" check-proofs "FeatureReachability.agda"

# A missing value read as zero (re-anchoring plan WO 4.2): the worked example
# says that the closing cash of P4, which depends on a missing input, is 0.
# The generated Agda check then fails, because the model keeps it missing.
d=$(copy missing)
f="$d/applied-systems/finance/cohort-economics/examples/approximate.jsonl"
grep -qF '{"evidence_status":"missing","id":"closing","kind":"expected","period":"P4","value":null}' "$f"
sed -i 's/{"evidence_status":"missing","id":"closing","kind":"expected","period":"P4","value":null}/{"evidence_status":"illustrative","id":"closing","kind":"expected","period":"P4","value":0}/' "$f"
(cd "$d" && just --quiet applied-build >/dev/null)
expect_fail "missing read as zero" "$d" check-proofs "Applied/Example/Approximate.agda FAIL"

# A receipt report outlives no failed run: a report left by an earlier passing
# run is removed when a later run fails, even when it fails at once because its
# prover is not on PATH. The PATH holds only the tools the script needs before
# its toolchain check, so no prover is on it.
bin=$t/report-bin; reports=$t/reports
mkdir -p "$bin" "$reports"
for tool in bash dirname mkdir rm; do ln -s "$(type -P "$tool")" "$bin/$tool"; done
for prover in agda coq lean4 idris2; do
  printf 'an earlier PASS report\n' >"$reports/$prover"
  if PATH=$bin PROOF_REPORT_DIR=$reports "$bin/bash" "$root/scripts/check-proofs.sh" "$prover" >/dev/null 2>&1; then
    echo "FAIL: stale report: check-proofs.sh $prover passed with no prover on PATH"; fail=1
  elif [ -e "$reports/$prover" ]; then
    echo "FAIL: stale report: a failed $prover run left the earlier report"; fail=1
  else
    echo "PASS: stale report: a failed $prover run removes the earlier report"
  fi
done

exit "$fail"
