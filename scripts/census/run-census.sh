#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Re-run the whole census and regenerate the catalogue.
#
# Usage: run-census.sh [REPO_LIST]
#   REPO_LIST: one OWNER/REPO per line. Default: every non-fork repo in
#   data/repos.jsonl. Refresh data/repos.jsonl first when repos are added; the
#   GitHub listing is not scriptable from agent sessions, so it is an input.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
data=${MATHESIS_DATA:-$here/../../data}
list=${1:-}
if [ -z "$list" ]; then
  list=$(mktemp); trap 'rm -f "$list"' EXIT
  jq -r 'select(.fork|not) | .full_name | select(test("/awesome-")|not)' "$data/repos.jsonl" > "$list"
fi
rm -rf "$data/out"
while IFS= read -r repo; do
  [ -n "$repo" ] && MATHESIS_DATA=$data bash "$here/census-repo.sh" "$repo" || true
done < "$list"
MATHESIS_DATA=$data bash "$here/summarise.sh"
bash "$here/generate-catalogue.sh" "$data" "$data/template-paths.txt" > "$here/../../catalogue/catalogue.adoc"
rm -rf "$data/out" "$data/clones"
