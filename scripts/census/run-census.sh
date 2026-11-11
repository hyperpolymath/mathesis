#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Re-run the whole census and regenerate the catalogue.
#
# Usage: run-census.sh [REPO_LIST]
#   REPO_LIST: one OWNER/REPO per line. Default: every non-fork repo in
#   docs/atlas/census/repos.jsonl, plus the forks named in
#   docs/atlas/census/forks-with-own-proofs.txt. Refresh repos.jsonl
#   first when repos are added; the GitHub listing is not scriptable from
#   agent sessions, so it is an input. repos.jsonl holds public records
#   only; the number of private repositories in the same listing goes to
#   private-count.json, with the date of the listing (ruling D-2 (a)).
#   To refresh only some rows, use update-rows.sh.
#
# Raw, path-level output (clones, per-file rows, summary.md) goes to
# MATHESIS_WORK (default: a fresh temporary directory) and is not committed.
# Only the per-repo rows and the rendered catalogue are written into the repo.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../docs/atlas/census
work=${MATHESIS_WORK:-$(mktemp -d)}
mkdir -p "$work"
cp "$census/repos.jsonl" "$work/repos.jsonl"
if [ -n "${1:-}" ]; then
  cp "$1" "$work/census-list.txt"
else
  jq -r 'select(.visibility == "public" and (.fork|not)) | .full_name | select(test("/awesome-")|not)' "$work/repos.jsonl" > "$work/census-list.txt"
  grep -vE '^[[:space:]]*(#|$)' "$census/forks-with-own-proofs.txt" >> "$work/census-list.txt" || true
fi
list=$work/census-list.txt
rm -rf "$work/out"
while IFS= read -r repo; do
  [ -n "$repo" ] && MATHESIS_DATA=$work bash "$here/census-repo.sh" "$repo" || true
done < "$list"
MATHESIS_DATA=$work bash "$here/summarise.sh"
# Only a public frame record may appear as not reached (ruling D-2 (a)).
jq -c 'select(.visibility == "public") | .full_name' "$work/repos.jsonl" | jq -s . > "$work/public.json"
jq -cS -s --slurpfile p "$work/public.json" \
  'map(select(.repo as $r | $p[0] | index($r))) | sort_by(.repo)[]' \
  "$work/unreachable.jsonl" > "$census/unreachable.jsonl"
bash "$here/build-rows.sh" "$work" "$census/template-blobs.tsv" > "$census/rows.jsonl"
bash "$here/render-catalogue.sh" "$census" > "$here/../../docs/atlas/generated/catalogue.adoc"
echo "raw census kept in $work"
