#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Re-census one repository and splice its row into the committed catalogue.
#
# Usage: refresh-repo.sh OWNER/REPO
#
# run-census.sh rebuilds every row from scratch, which takes hours for the
# whole estate. This reruns census-repo.sh for one repository, folds that
# repository's raw output into rows with build-rows.sh, and replaces only its
# row (or removes it, if it no longer has proof files of its own) in
# catalogue-rows.json and unreachable.json. Every other row is untouched.
# The repository must already be listed in repos.json.
set -euo pipefail
FN=${1:?usage: refresh-repo.sh OWNER/REPO}
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../docs/catalogue/census
jq -e --arg r "$FN" 'any(.[]; .full_name == $r)' "$census/repos.json" >/dev/null \
  || { echo "refresh-repo.sh: $FN is not in repos.json; add it there first" >&2; exit 1; }

work=${MATHESIS_WORK:-$(mktemp -d)}
mkdir -p "$work"
rm -rf "$work/out"
printf '%s\n' "$FN" > "$work/census-list.txt"
jq -c --arg r "$FN" '.[] | select(.full_name == $r)' "$census/repos.json" > "$work/repos.jsonl"
MATHESIS_DATA=$work bash "$here/census-repo.sh" "$FN"
MATHESIS_DATA=$work bash "$here/summarise.sh" >/dev/null

bash "$here/build-rows.sh" "$work" "$census/template-paths.txt" "$census/template-blobs.txt" > "$work/new-rows.json"
jq -cS -s --arg r "$FN" '(.[0] | map(select(.repo != $r))) + (.[1] | map(select(.repo == $r))) | sort_by(.repo)' \
  "$census/catalogue-rows.json" "$work/new-rows.json" > "$work/rows.json"
mv "$work/rows.json" "$census/catalogue-rows.json"

# summarise.sh orders unreachable entries by their per-repo file names
# (OWNER__REPO.unreach.jsonl, bytewise), not by repository name.
jq -cS -s --arg r "$FN" '(.[0] | map(select(.repo != $r))) + (.[1] // []) | sort_by((.repo | sub("/"; "__")) + ".unreach.jsonl")' \
  "$census/unreachable.json" <(jq -cS . "$work/unreachable.jsonl" 2>/dev/null || true) > "$work/unreach.json"
mv "$work/unreach.json" "$census/unreachable.json"

bash "$here/render-catalogue.sh" "$census" > "$here/../../docs/catalogue/catalogue.adoc"
jq -c --arg r "$FN" '.[] | select(.repo == $r)' "$census/catalogue-rows.json" \
  | grep . || echo "$FN: no proof files of its own; no row"
echo "raw census for $FN kept in $work"
