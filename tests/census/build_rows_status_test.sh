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

# Provenance fixture: one meta record per repository (census-repo.sh writes it).
jq -cS '{repo, commit: "0123456789abcdef0123456789abcdef01234567", censused_at: "2026-11-10T00:00:00Z"}' "$raw/files.jsonl" | sort -u > "$raw/meta.jsonl"
rows=$(bash "$ROOT/scripts/census/build-rows.sh" "$raw" "$raw/template.txt")
doc() {
  local repo="$1"
  jq -r --arg r "$repo" 'select(.repo == $r) | .status_doc' <<< "$rows"
}
fail=0
expect() {
  local repo="$1" want="$2" got
  got=$(doc "$repo")
  if [[ "$got" == "$want" ]]; then echo "PASS: $repo -> ${want:-<none>}"
  else echo "FAIL: $repo -> '$got', expected '$want'"; fail=1; fi
}
expect o/both            docs/status/PROOF-STATUS.adoc
expect o/needs-only      docs/status/PROOF-NEEDS.adoc
expect o/debt-and-needs  docs/proof-debt.adoc
expect o/root-status     PROOF-STATUS.adoc
expect o/none            ""
exit "$fail"
