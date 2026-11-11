#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Refresh the census rows of named repositories without re-running the
# whole census, then re-render the catalogue.
#
# Usage: update-rows.sh OWNER/REPO...
#        update-rows.sh --frame   (no clone: drop rows and not-reached
#                                  entries outside the public frame)
#
# Each named repository is censused exactly as run-census.sh would census
# it. Its row in rows.jsonl is replaced, added, or removed when it
# no longer has proof files of its own. Every other row is left as it is.
# Raw output goes to MATHESIS_WORK (default: a fresh temporary directory)
# and is not committed. Every name is checked before any clone. A name must
# appear in repos.jsonl and be public there, so the catalogue's
# repository count stays the census input; a fork must also be listed in
# forks-with-own-proofs.txt.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../docs/atlas/census
[[ $# -gt 0 ]] || { echo "usage: update-rows.sh OWNER/REPO... | --frame" >&2; exit 2; }
# --frame applies the frame without a clone. A row or an unreachable entry
# must belong to a public record of repos.jsonl (ruling D-2 (a)): drop the
# others, then re-render the catalogue. Run it after each frame refresh.
if [[ "$1" = --frame ]]; then
  [[ $# -eq 1 ]] || { echo "usage: update-rows.sh --frame" >&2; exit 2; }
  pub=$(mktemp); trap 'rm -f "$pub" "$census"/*.jsonl.new' EXIT
  jq -c 'select(.visibility == "public") | .full_name' "$census/repos.jsonl" | jq -s . > "$pub"
  for f in rows unreachable; do
    jq -cS --slurpfile p "$pub" 'select(.repo as $r | $p[0] | index($r))' \
      "$census/$f.jsonl" > "$census/$f.jsonl.new"
    mv "$census/$f.jsonl.new" "$census/$f.jsonl"
  done
  bash "$here/render-catalogue.sh" "$census" > "$here/../../docs/atlas/generated/catalogue.adoc"
  echo "update-rows: applied the frame: $(wc -l < "$census/rows.jsonl") rows, $(wc -l < "$census/unreachable.jsonl") not reached"
  exit 0
fi
work=${MATHESIS_WORK:-$(mktemp -d)}
mkdir -p "$work"
cp "$census/repos.jsonl" "$work/repos.jsonl"
: > "$work/census-list.txt"
for repo in "$@"; do
  rec=$(jq -c --arg r "$repo" 'select(.full_name == $r)' "$work/repos.jsonl")
  [ -n "$rec" ] || { echo "update-rows: $repo is not in repos.jsonl" >&2; exit 1; }
  # A private repository never gets a row: the catalogue is public (ruling D-2).
  [ "$(jq -r '.visibility' <<<"$rec")" = public ] \
    || { echo "update-rows: $repo is not public in repos.jsonl" >&2; exit 1; }
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
bash "$here/build-rows.sh" "$work" "$census/template-blobs.tsv" > "$work/new-rows.jsonl"
jq -R . "$work/census-list.txt" | jq -s . > "$work/names.json"
jq -cS -s --slurpfile new "$work/new-rows.jsonl" --slurpfile names "$work/names.json" '
  map(select(.repo as $r | $names[0] | index($r) | not)) + $new | sort_by(.repo)[]
' "$census/rows.jsonl" > "$work/rows.jsonl"
mv "$work/rows.jsonl" "$census/rows.jsonl"
# A named repository was reached, so it leaves the "not reached" list.
jq -cS --slurpfile names "$work/names.json" \
  'select(.repo as $r | $names[0] | index($r) | not)' \
  "$census/unreachable.jsonl" > "$work/unreach.jsonl"
mv "$work/unreach.jsonl" "$census/unreachable.jsonl"
bash "$here/render-catalogue.sh" "$census" > "$here/../../docs/atlas/generated/catalogue.adoc"
echo "update-rows: refreshed $(wc -l < "$work/census-list.txt") repo(s); raw census kept in $work"
