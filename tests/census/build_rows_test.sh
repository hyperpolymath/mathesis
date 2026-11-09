#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Focused regression tests for census status-document selection. No network used.
# Usage: bash tests/census/build_rows_test.sh
set -euo pipefail
export LC_ALL=C
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
command -v jq >/dev/null || fail 'jq is required'

# Every repo has one non-template file so it produces a catalogue row.
# A nonempty template list also exercises the production filtering contract.
printf '%s\n' 'template/Boilerplate.agda' > "$work/templates.txt"
: > "$work/files.jsonl"
: > "$work/holes.jsonl"
: > "$work/decls.jsonl"
: > "$work/repos-with-status.jsonl"
: > "$work/expected.jsonl"
add_case() { # <repo component> <expected pointer> [candidate paths...]
  local name="test/$1" expected=$2 path
  shift 2
  jq -cn --arg repo "$name" '{repo:$repo,path:"src/Main.agda",ext:"agda"}' >> "$work/files.jsonl"
  jq -cn --arg repo "$name" --arg path "$expected" '{repo:$repo,status_doc:$path}' >> "$work/expected.jsonl"
  for path in "$@"; do
    jq -cn --arg repo "$name" --arg path "$path" '{repo:$repo,path:$path}' >> "$work/repos-with-status.jsonl"
  done
}

add_case all-ranks docs/status/PROOF-STATUS.adoc \
  docs/proof-debt.adoc docs/PROOF-NEEDS.adoc docs/status/PROOF-STATUS.adoc README.adoc
add_case needs-before-debt z/PROOF-NEEDS.adoc \
  a/PROOF-DEBT.adoc z/PROOF-NEEDS.adoc 0/overview.adoc
add_case debt-before-other z/PROOF-DEBT.adoc \
  a/overview.adoc z/PROOF-DEBT.adoc
add_case mixed-case nested/pRoOf-StAtUs.AdOc \
  PROOF-NEEDS.adoc nested/pRoOf-StAtUs.AdOc proof-debt.adoc
add_case mixed-case-needs nested/pRoOf-NeEdS.md \
  PROOF-DEBT.adoc nested/pRoOf-NeEdS.md
add_case mixed-case-debt nested/pRoOf-DeBt.md \
  README.adoc nested/pRoOf-DeBt.md
# A directory name is not the basename: all three ranks must resist it.
add_case misleading-status z/PROOF-NEEDS.adoc \
  PROOF-STATUS/proof-debt.adoc z/PROOF-NEEDS.adoc
add_case misleading-needs z/PROOF-DEBT.adoc \
  PROOF-NEEDS/overview.adoc z/PROOF-DEBT.adoc
add_case misleading-debt a/overview.adoc \
  z/PROOF-DEBT/overview.adoc a/overview.adoc
# Root paths, nesting, suffixes, and spaces must preserve the selected path.
add_case root PROOF-STATUS.adoc PROOF-STATUS.adoc
add_case suffix 'docs with spaces/deep/PROOF-STATUS-history.md' \
  docs/PROOF-NEEDS.adoc 'docs with spaces/deep/PROOF-STATUS-history.md'
add_case non-prefix z/proof-needs.adoc \
  a/my-proof-status.adoc z/proof-needs.adoc
add_case fallback a/overview.adoc z/overview.adoc a/overview.adoc
add_case same-rank a/PROOF-STATUS.adoc z/PROOF-STATUS.adoc a/PROOF-STATUS.adoc
add_case duplicate PROOF-STATUS.adoc PROOF-STATUS.adoc PROOF-STATUS.adoc
add_case absent ''
# Prefix-related repository names must not share their selected document.
add_case shared docs/PROOF-STATUS.adoc docs/PROOF-STATUS.adoc
add_case shared-child docs/PROOF-DEBT.adoc docs/PROOF-DEBT.adoc
# Status-only repositories do not create census rows.
printf '%s\n' '{"repo":"test/status-only","path":"PROOF-STATUS.adoc"}' >> "$work/repos-with-status.jsonl"

# Nonzero counters catch accidental changes to the row fold while choosing a
# pointer. Template artefacts contribute neither files nor declarations/holes.
cat >> "$work/files.jsonl" <<'JSONL'
{"repo":"test/all-ranks","path":"tests/Example.lean","ext":"lean"}
{"repo":"test/all-ranks","path":"template/Boilerplate.agda","ext":"agda"}
JSONL
cat >> "$work/decls.jsonl" <<'JSONL'
{"repo":"test/all-ranks","file":"src/Main.agda"}
{"repo":"test/all-ranks","file":"tests/Example.lean"}
{"repo":"test/all-ranks","file":"template/Boilerplate.agda"}
JSONL
for class in hole axiom unsafe policy; do
  jq -cn --arg class "$class" '{repo:"test/all-ranks",file:"src/Main.agda",class:$class}' >> "$work/holes.jsonl"
  jq -cn --arg class "$class" '{repo:"test/all-ranks",file:"template/Boilerplate.agda",class:$class}' >> "$work/holes.jsonl"
done

run_rows() {
  bash "$repo/scripts/census/build-rows.sh" "$work" "$work/templates.txt" > "$work/actual.json"
}
run_rows
jq -sS 'sort_by(.repo)' "$work/expected.jsonl" > "$work/expected.json"
jq -S 'map({repo,status_doc})' "$work/actual.json" > "$work/pointers.json"
diff -u "$work/expected.json" "$work/pointers.json" || fail 'status precedence or repository isolation'
echo 'PASS: 18 status selection cases, including absent and duplicate candidates'
jq -e '
  (map(.repo) == (map(.repo) | sort)) and
  (map(select(.repo == "test/all-ranks")) == [{
    repo:"test/all-ranks", class:"theory", own_files:2, fixture_files:1,
    provers:"agda 1, lean 1", declarations:2, holes:1, axioms:1,
    unsafe:1, policy:1, status_doc:"docs/status/PROOF-STATUS.adoc"
  }]) and
  (map(select(.repo != "test/all-ranks")) | all(
    .class == "theory" and .own_files == 1 and .fixture_files == 0 and
    .provers == "agda 1" and .declarations == 0 and .holes == 0 and
    .axioms == 0 and .unsafe == 0 and .policy == 0
  ))
' "$work/actual.json" >/dev/null || fail 'status selection changed census counts or row order'
echo 'PASS: counters, template exclusions, fixtures, and row ordering preserved'
cp "$work/actual.json" "$work/original.json"
# Deliberately reverse all candidates, including ties, to catch first-input wins.
jq -cs '. | reverse[]' "$work/repos-with-status.jsonl" > "$work/reversed.jsonl"
mv "$work/reversed.jsonl" "$work/repos-with-status.jsonl"
run_rows
cmp "$work/original.json" "$work/actual.json" || fail 'candidate input order changed output'
echo 'PASS: reversed status candidates produce byte-identical rows'
: > "$work/repos-with-status.jsonl"
run_rows
jq 'map(.status_doc = "")' "$work/original.json" > "$work/no-status-expected.json"
jq . "$work/actual.json" > "$work/no-status-actual.json"
diff -u "$work/no-status-expected.json" "$work/no-status-actual.json" || fail 'empty status input changed rows'
echo 'PASS: an empty status stream preserves every row with an empty pointer'
