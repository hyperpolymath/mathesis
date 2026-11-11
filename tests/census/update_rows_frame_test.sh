#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# update-rows.sh --frame drops each row and each not-reached entry whose
# repository is not a public frame record, clones nothing, and renders a
# catalogue that names no private repository (ruling D-2 (a)). Offline.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/scripts/census" "$t/docs/atlas/census" "$t/docs/atlas/generated"
cp "$root/scripts/census/"*.sh "$t/scripts/census/"
c=$t/docs/atlas/census
cat > "$c/repos.jsonl" <<'J'
{"fork":false,"full_name":"o/kept","pushed_at":"2026-11-10T00:00:00Z","visibility":"public"}
{"fork":false,"full_name":"o/lost","pushed_at":"2026-11-10T00:00:00Z","visibility":"public"}
J
printf '%s\n' '{"listed":"2026-11-10","listing_commit":"c8246ee","private_repositories":2}' > "$c/private-count.json"
row='"axioms":0,"censused_at":"2026-11-10T00:00:00Z","class":"theory","commit":"0000000000000000000000000000000000000000","declarations":1,"fixture_files":0,"holes":0,"own_files":1,"policy":0,"provers":"agda 1","status_doc":"","unsafe":0'
printf '{%s,"repo":"o/kept"}\n{%s,"repo":"o/gone"}\n' "$row" "$row" > "$c/rows.jsonl"
printf '%s\n' '{"error":"x","exit":128,"repo":"o/hidden"}' '{"error":"x","exit":128,"repo":"o/lost"}' > "$c/unreachable.jsonl"
fail=0
check() { if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; fail=1; fi; }
PATH="/nonexistent-git:$PATH" bash "$t/scripts/census/update-rows.sh" --frame > /dev/null
check "rows outside the frame are dropped" '[ "$(jq -r .repo "$c/rows.jsonl")" = o/kept ]'
check "not-reached entries outside the frame are dropped" '[ "$(jq -r .repo "$c/unreachable.jsonl")" = o/lost ]'
cat_=$t/docs/atlas/generated/catalogue.adoc
check "the catalogue prints the private count" 'grep -q "counted 2 private repositories" "$cat_"'
check "the catalogue names no dropped repository" '! grep -q "o/hidden\|o/gone" "$cat_"'
check "a second run changes nothing" 'before=$(cat "$c"/*.jsonl "$cat_" | sha256sum); bash "$t/scripts/census/update-rows.sh" --frame >/dev/null; [ "$(cat "$c"/*.jsonl "$cat_" | sha256sum)" = "$before" ]'
rm "$c/private-count.json"
check "a missing private-count.json fails the render" '! bash "$t/scripts/census/update-rows.sh" --frame >/dev/null 2>&1'
exit "$fail"
