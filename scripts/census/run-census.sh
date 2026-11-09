#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Re-run the census and regenerate the catalogue.
#
# Usage: run-census.sh [REPO_LIST]
#        run-census.sh --merge REPO_LIST
#   REPO_LIST: one OWNER/REPO per line. Default: every non-fork repo in
#   docs/catalogue/census/repos.json. Refresh that file first when repos are
#   added; the GitHub listing is not scriptable from agent sessions, so it is
#   an input.
#
#   Full mode (no --merge) replaces the committed census with this run.
#   --merge censuses only REPO_LIST and merges the result into the committed
#   data with merge-rows.sh: rows, unreachable entries and provenance change
#   for the listed repositories only; every other record is kept as is.
#
# Provenance: docs/catalogue/census/provenance.json records, per censused
# repository, the commit the census read and the UTC date of the run.
# Repositories censused before provenance was recorded have no entry.
#
# Raw, path-level output (clones, per-file rows, summary.md) goes to
# MATHESIS_WORK (default: a fresh temporary directory) and is not committed.
# Only the per-repo rows and the rendered catalogue are written into the repo.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../docs/catalogue/census
merge=false
if [ "${1:-}" = --merge ]; then
  merge=true; shift
  [ -n "${1:-}" ] || { echo "run-census.sh --merge needs a REPO_LIST" >&2; exit 2; }
fi
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

today=$(date -u +%Y-%m-%d)
jq -cS -s . "$work/unreachable.jsonl" > "$work/unreachable.json"
bash "$here/build-rows.sh" "$work" "$census/template-paths.txt" > "$work/catalogue-rows.json"
jq -cS -s --arg d "$today" 'map(. + {census_date: $d}) | sort_by(.repo)' "$work/heads.jsonl" > "$work/provenance.json"

if $merge; then
  [ -f "$census/provenance.json" ] || echo '[]' > "$census/provenance.json"
  for f in catalogue-rows provenance; do
    bash "$here/merge-rows.sh" --sorted "$census/$f.json" "$work/$f.json" "$list" > "$work/$f.merged.json"
    mv "$work/$f.merged.json" "$census/$f.json"
  done
  bash "$here/merge-rows.sh" "$census/unreachable.json" "$work/unreachable.json" "$list" > "$work/unreachable.merged.json"
  mv "$work/unreachable.merged.json" "$census/unreachable.json"
else
  for f in unreachable catalogue-rows provenance; do cp "$work/$f.json" "$census/$f.json"; done
fi
bash "$here/render-catalogue.sh" "$census" > "$here/../../docs/catalogue/catalogue.adoc"
echo "raw census kept in $work"
