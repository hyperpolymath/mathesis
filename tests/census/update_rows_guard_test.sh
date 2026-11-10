#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# update-rows.sh checks every name before any clone: an unlisted name, a
# private repository or an unlisted fork stops the run, and no file changes.
# Offline: each case fails before census-repo.sh would clone.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/scripts/census" "$t/docs/catalogue/census"
cp "$root/scripts/census/"*.sh "$t/scripts/census/"
c=$t/docs/catalogue/census
cat > "$c/repos.jsonl" <<'J'
{"fork":false,"full_name":"o/public","pushed_at":"2026-11-10T00:00:00Z","visibility":"public"}
{"fork":false,"full_name":"o/hidden","pushed_at":"2026-11-10T00:00:00Z","visibility":"private"}
{"fork":true,"full_name":"o/fork","pushed_at":"2026-11-10T00:00:00Z","visibility":"public"}
J
: > "$c/catalogue-rows.jsonl"; : > "$c/unreachable.jsonl"; : > "$c/forks-with-own-proofs.txt"
before=$(cat "$c"/*.jsonl | sha256sum)
fail=0
expect_refusal() { # want-message name...
  local want=$1; shift
  if err=$(bash "$t/scripts/census/update-rows.sh" "$@" 2>&1); then
    echo "FAIL: update-rows.sh $* succeeded"; fail=1
  elif [[ "$err" != *"$want"* ]]; then
    echo "FAIL: update-rows.sh $*: '$err'"; fail=1
  else echo "PASS: $* -> $want"; fi
}
expect_refusal "is not in repos.jsonl" o/missing
expect_refusal "is not public" o/public o/hidden
expect_refusal "is a fork not listed" o/fork
[ "$(cat "$c"/*.jsonl | sha256sum)" = "$before" ] || { echo "FAIL: a refused run changed census files"; fail=1; }
exit "$fail"
