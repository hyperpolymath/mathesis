#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Refresh the census rows of named repositories without re-running the
# whole census, then re-render the catalogue.
#
# Usage: update-rows.sh OWNER/REPO...
#
# Each named repository is censused exactly as run-census.sh would census
# it. Its row in catalogue-rows.json is replaced, added, or removed when it
# no longer has proof files of its own. Every other row is left as it is.
# Raw output goes to MATHESIS_WORK (default: a fresh temporary directory)
# and is not committed. Every name is checked before any clone. A name must
# appear in repos.json and be public there, so the catalogue's
# repository count stays the census input; a fork must also be listed in
# forks-with-own-proofs.txt.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../docs/catalogue/census
[ $# -gt 0 ] || { echo "usage: update-rows.sh OWNER/REPO..." >&2; exit 2; }
work=${MATHESIS_WORK:-$(mktemp -d)}
mkdir -p "$work"
jq -c '.[]' "$census/repos.json" > "$work/repos.jsonl"
: > "$work/census-list.txt"
for repo in "$@"; do
  rec=$(jq -c --arg r "$repo" 'select(.full_name == $r)' "$work/repos.jsonl")
  [ -n "$rec" ] || { echo "update-rows: $repo is not in repos.json" >&2; exit 1; }
  # A private repository never gets a row: the catalogue is public (ruling D-2).
  [ "$(jq -r '.visibility' <<<"$rec")" = public ] \
    || { echo "update-rows: $repo is not public in repos.json" >&2; exit 1; }
  if [ "$(jq -r '.fork' <<<"$rec")" = true ] \
     && ! grep -qxF "$repo" "$census/forks-with-own-proofs.txt"; then
    echo "update-rows: $repo is a fork not listed in forks-with-own-proofs.txt" >&2
    exit 1
  fi
  echo "$repo" >> "$work/census-list.txt"
done
rm -rf "$work/out"
while IFS= read -r repo; do
  MATHESIS_DATA=$work bash "$here/census-repo.sh" "$repo"
done < "$work/census-list.txt"
MATHESIS_DATA=$work bash "$here/summarise.sh" > /dev/null
if [ -s "$work/unreachable.jsonl" ]; then
  echo "update-rows: could not clone: $(jq -r .repo "$work/unreachable.jsonl" | tr '\n' ' ')" >&2
  exit 1
fi
bash "$here/build-rows.sh" "$work" "$census/template-blobs.tsv" > "$work/new-rows.json"
jq -R . "$work/census-list.txt" | jq -s . > "$work/names.json"
jq -cS --slurpfile new "$work/new-rows.json" --slurpfile names "$work/names.json" '
  map(select(.repo as $r | $names[0] | index($r) | not)) + $new[0] | sort_by(.repo)
' "$census/catalogue-rows.json" > "$work/rows.json"
mv "$work/rows.json" "$census/catalogue-rows.json"
# A named repository was reached, so it leaves the "not reached" list.
jq -cS --slurpfile names "$work/names.json" \
  'map(select(.repo as $r | $names[0] | index($r) | not))' \
  "$census/unreachable.json" > "$work/unreach.json"
mv "$work/unreach.json" "$census/unreachable.json"
bash "$here/render-catalogue.sh" "$census" > "$here/../../docs/catalogue/catalogue.adoc"
echo "update-rows: refreshed $(wc -l < "$work/census-list.txt") repo(s); raw census kept in $work"
