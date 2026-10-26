#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Re-run the whole census and regenerate the catalogue.
#
# Usage: run-census.sh [REPO_LIST]
#   REPO_LIST: one OWNER/REPO per line. Default: every non-fork repo in
#   docs/catalogue/census/repos.json. Refresh that file first when repos are
#   added; the GitHub listing is not scriptable from agent sessions, so it is
#   an input.
#
# Raw, path-level output (clones, per-file rows, summary.md) goes to
# MATHESIS_WORK (default: a fresh temporary directory) and is not committed.
# Only the per-repo rows and the rendered catalogue are written into the repo.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../docs/catalogue/census
work=${MATHESIS_WORK:-$(mktemp -d)}
mkdir -p "$work"
jq -c '.[]' "$census/repos.json" > "$work/repos.jsonl"
if [ -n "${1:-}" ]; then
  cp "$1" "$work/census-list.txt"
else
  jq -r 'select(.fork|not) | .full_name | select(test("/awesome-")|not)' "$work/repos.jsonl" > "$work/census-list.txt"
fi
list=$work/census-list.txt
rm -rf "$work/out"
while IFS= read -r repo; do
  [ -n "$repo" ] && MATHESIS_DATA=$work bash "$here/census-repo.sh" "$repo" || true
done < "$list"
MATHESIS_DATA=$work bash "$here/summarise.sh"
jq -cS -s . "$work/unreachable.jsonl" > "$census/unreachable.json"
bash "$here/build-rows.sh" "$work" "$census/template-paths.txt" > "$census/catalogue-rows.json"
bash "$here/render-catalogue.sh" "$census" > "$here/../../docs/catalogue/catalogue.adoc"
echo "raw census kept in $work"
