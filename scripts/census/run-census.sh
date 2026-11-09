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
source "$here/snapshot.sh"
snapshot_lock
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
snapshot_stage
jq -cS -s . "$work/unreachable.jsonl" > "$stage/census/unreachable.json"
bash "$here/build-rows.sh" "$work" "$census/template-paths.txt" > "$stage/census/catalogue-rows.json"
# Only the staged snapshot loses provenance; failures leave the live copy intact.
rm -f "$stage/census/refreshed.json"
snapshot_publish
echo "raw census kept in $work"
