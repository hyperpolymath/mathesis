#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
#
# build-rows.sh picks one status_doc per repository: PROOF-STATUS over
# proof-debt over PROOF-NEEDS, the first sorted path within a rank. The
# previous rule (first sorted path) named docs/status/PROOF-NEEDS.adoc for
# repositories whose status lives in docs/status/PROOF-STATUS.adoc.
# Usage: bash tests/census/build_rows_status_test.sh   (needs jq)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
command -v jq >/dev/null || { echo "FAIL: jq is required" >&2; exit 1; }
raw=$(mktemp -d); trap 'rm -rf "$raw"' EXIT

: > "$raw/holes.jsonl"; : > "$raw/decls.jsonl"
# A non-empty template list: build-rows.sh reads it with NR==FNR, so an
# empty list would swallow files.jsonl as template paths and emit no rows.
echo "verification/proofs/template-only.v" > "$raw/template.txt"
for r in o/both o/needs-only o/debt-and-needs o/root-status o/none; do
  printf '{"repo":"%s","path":"src/A.agda","ext":"agda"}\n' "$r"
done > "$raw/files.jsonl"
cat > "$raw/repos-with-status.jsonl" <<'J'
{"repo":"o/both","path":"docs/status/PROOF-NEEDS.adoc"}
{"repo":"o/both","path":"docs/status/PROOF-STATUS.adoc"}
{"repo":"o/needs-only","path":"docs/status/PROOF-NEEDS.adoc"}
{"repo":"o/debt-and-needs","path":"PROOF-NEEDS.md"}
{"repo":"o/debt-and-needs","path":"docs/proof-debt.adoc"}
{"repo":"o/root-status","path":"PROOF-NEEDS.adoc"}
{"repo":"o/root-status","path":"proofs/proof-status.md"}
{"repo":"o/root-status","path":"PROOF-STATUS.adoc"}
J

rows=$(bash "$ROOT/scripts/census/build-rows.sh" "$raw" "$raw/template.txt")
doc() { jq -r --arg r "$1" '.[] | select(.repo == $r) | .status_doc' <<< "$rows"; }
fail=0
expect() {
  local got; got=$(doc "$1")
  if [ "$got" = "$2" ]; then echo "PASS: $1 -> ${2:-<none>}"
  else echo "FAIL: $1 -> '$got', expected '${2:-}'"; fail=1; fi
}
expect o/both            docs/status/PROOF-STATUS.adoc
expect o/needs-only      docs/status/PROOF-NEEDS.adoc
expect o/debt-and-needs  docs/proof-debt.adoc
expect o/root-status     PROOF-STATUS.adoc
expect o/none            ""
exit "$fail"
