#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Tests for scripts/census/merge-rows.sh: positive cases and fail-closed cases.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$here/../..
M=$root/scripts/census/merge-rows.sh
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
pass=0 fail=0
ok()  { pass=$((pass+1)); echo "ok   - $1"; }
bad() { fail=$((fail+1)); echo "FAIL - $1"; }
expect_eq() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1"; echo "  expected: $3"; echo "  got:      $2"; fi; }
expect_fail() { if bash "$M" "${@:2}" > /dev/null 2>&1; then bad "$1 (exit 0, expected failure)"; else ok "$1"; fi; }

echo '[{"n":1,"repo":"o/a"},{"n":1,"repo":"o/b"},{"n":1,"repo":"o/c"}]' > "$t/c.json"
printf 'o/b\n' > "$t/s-b"

echo '[{"n":2,"repo":"o/b"}]' > "$t/n.json"
expect_eq "replaces a scoped row, keeps the others" \
  "$(bash "$M" --sorted "$t/c.json" "$t/n.json" "$t/s-b")" \
  '[{"n":1,"repo":"o/a"},{"n":2,"repo":"o/b"},{"n":1,"repo":"o/c"}]'

echo '[]' > "$t/empty.json"
expect_eq "drops a scoped repo that has no new row" \
  "$(bash "$M" --sorted "$t/c.json" "$t/empty.json" "$t/s-b")" \
  '[{"n":1,"repo":"o/a"},{"n":1,"repo":"o/c"}]'

printf 'o/bb\n' > "$t/s-bb"
echo '[{"n":3,"repo":"o/bb"}]' > "$t/n-bb.json"
expect_eq "adds a new scoped repo in sorted position" \
  "$(bash "$M" --sorted "$t/c.json" "$t/n-bb.json" "$t/s-bb")" \
  '[{"n":1,"repo":"o/a"},{"n":1,"repo":"o/b"},{"n":3,"repo":"o/bb"},{"n":1,"repo":"o/c"}]'

echo '[{"n":9,"repo":"o/a"},{"n":2,"repo":"o/b"}]' > "$t/n-extra.json"
expect_eq "ignores new rows outside the scope" \
  "$(bash "$M" --sorted "$t/c.json" "$t/n-extra.json" "$t/s-b")" \
  '[{"n":1,"repo":"o/a"},{"n":2,"repo":"o/b"},{"n":1,"repo":"o/c"}]'

echo '[{"n":1,"repo":"o/z"},{"n":1,"repo":"o/a"},{"n":1,"repo":"o/m"}]' > "$t/u.json"
printf 'o/a\no/q\n' > "$t/s-aq"
echo '[{"n":5,"repo":"o/q"}]' > "$t/n-q.json"
expect_eq "unsorted mode keeps committed order and appends additions" \
  "$(bash "$M" "$t/u.json" "$t/n-q.json" "$t/s-aq")" \
  '[{"n":1,"repo":"o/z"},{"n":1,"repo":"o/m"},{"n":5,"repo":"o/q"}]'

rows=$root/docs/catalogue/census/catalogue-rows.json
jq -r '.[0:3][].repo' "$rows" > "$t/s-real"
jq -c --rawfile S "$t/s-real" '($S|split("\n")|map(select(length>0))) as $s | map(select(.repo as $r | $s | index($r)))' "$rows" > "$t/n-real.json"
if bash "$M" --sorted "$rows" "$t/n-real.json" "$t/s-real" | cmp -s - "$rows"; then
  ok "no-op merge on the committed rows is byte-identical"
else
  bad "no-op merge on the committed rows is byte-identical"
fi

echo '[{"n":1,"repo":"o/a"},{"n":2,"repo":"o/a"}]' > "$t/dup.json"
expect_fail "rejects a duplicate repo in the committed data" --sorted "$t/dup.json" "$t/n.json" "$t/s-b"
expect_fail "rejects a duplicate repo in the new data" --sorted "$t/c.json" "$t/dup.json" "$t/s-b"
echo '{"repo":"o/a"}' > "$t/obj.json"
expect_fail "rejects input that is not an array" --sorted "$t/obj.json" "$t/n.json" "$t/s-b"
echo '[{"n":1}]' > "$t/norepo.json"
expect_fail "rejects a record without a repo" --sorted "$t/c.json" "$t/norepo.json" "$t/s-b"
: > "$t/s-empty"
expect_fail "rejects an empty scope" --sorted "$t/c.json" "$t/n.json" "$t/s-empty"
expect_fail "rejects a missing input file" --sorted "$t/nope.json" "$t/n.json" "$t/s-b"
expect_fail "rejects the wrong argument count" --sorted "$t/c.json" "$t/n.json"

echo "merge-rows: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
