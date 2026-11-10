#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# build-rows.sh picks one status document per repository: PROOF-STATUS
# before proof-debt before PROOF-NEEDS, whatever their paths sort to.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."
raw=$(mktemp -d); trap 'rm -rf "$raw"' EXIT
: > "$raw/holes.jsonl"; : > "$raw/decls.jsonl"
# An empty template list must not drop every row (awk NR==FNR did).
: > "$raw/template.txt"
for r in a/needs-first a/debt-only a/needs-only; do
  printf '{"repo":"%s","path":"src/X.agda","ext":"agda"}\n' "$r" >> "$raw/files.jsonl"
done
cat > "$raw/repos-with-status.jsonl" <<'J'
{"repo":"a/needs-first","path":"docs/status/PROOF-NEEDS.adoc"}
{"repo":"a/needs-first","path":"docs/status/PROOF-STATUS.adoc"}
{"repo":"a/needs-first","path":"docs/proof-debt.adoc"}
{"repo":"a/debt-only","path":"PROOF-NEEDS.adoc"}
{"repo":"a/debt-only","path":"docs/proof-debt.md"}
{"repo":"a/needs-only","path":"PROOF-NEEDS.adoc"}
J
# Provenance fixture: one meta record per repository (census-repo.sh writes it).
jq -cS '{repo, commit: "0123456789abcdef0123456789abcdef01234567", censused_at: "2026-11-10T00:00:00Z"}' "$raw/files.jsonl" | sort -u > "$raw/meta.jsonl"
got=$(bash scripts/census/build-rows.sh "$raw" "$raw/template.txt" \
      | jq -r '.repo + " " + .status_doc' | sort)
want=$'a/debt-only docs/proof-debt.md\na/needs-first docs/status/PROOF-STATUS.adoc\na/needs-only PROOF-NEEDS.adoc'
if [ "$got" != "$want" ]; then
  printf 'FAIL: status documents\n--- want\n%s\n--- got\n%s\n' "$want" "$got" >&2
  exit 1
fi
echo "PASS: build-rows.sh ranks PROOF-STATUS, then proof-debt, then PROOF-NEEDS"
# A listed template path still counts as boilerplate: with every proof file
# on the list, no repository has own files, so there are no rows.
echo "src/X.agda" > "$raw/template.txt"
if [ "$(bash scripts/census/build-rows.sh "$raw" "$raw/template.txt")" != "" ]; then
  echo "FAIL: template paths were counted as own files" >&2
  exit 1
fi
echo "PASS: template paths are set aside, and an empty template list drops nothing"
