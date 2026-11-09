#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Re-census named repositories and splice their rows into the committed census.
#
# Usage: refresh-rows.sh OWNER/REPO...
#
# Use this when a full `just census` cannot run (an agent session reaches only
# some repositories) but a row is known to be stale. Each named repository goes
# through the same census-repo.sh, summarise.sh and build-rows.sh steps as a
# full run. Its old row is replaced, or removed when it no longer has own proof
# files, and its unreachable entry is dropped or replaced. Every other row is
# left exactly as the last full census wrote it.
#
# refreshed.json records which rows are newer than the full census, with the
# date and the commit each was taken from, and the catalogue prints that list.
# run-census.sh clears it, because a full run supersedes every refresh.
set -euo pipefail
[ $# -gt 0 ] || { echo "usage: $0 OWNER/REPO..." >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../docs/catalogue/census
source "$here/snapshot.sh"
snapshot_lock
mapfile -t requested < <(printf '%s\n' "$@" | sort -u)
# Validate the entire request before doing any clone or refresh work.
for repo in "${requested[@]}"; do
  jq -e --arg r "$repo" 'any(.[]; .full_name == $r)' "$census/repos.json" >/dev/null \
    || { echo "$repo is not in repos.json; add it there first" >&2; exit 1; }
  jq -e --arg r "$repo" 'any(.[]; .full_name == $r and .visibility == "public")' "$census/repos.json" >/dev/null \
    || { echo "$repo is not public in repos.json" >&2; exit 1; }
done
work=${MATHESIS_WORK:-$(mktemp -d)}
mkdir -p "$work"
rm -rf "$work/out" "$work/clones"
jq -c '.[]' "$census/repos.json" > "$work/repos.jsonl"
printf '%s\n' "${requested[@]}" > "$work/census-list.txt"

today=$(date -u +%Y-%m-%d)
: > "$work/refreshed.jsonl"
for repo in "${requested[@]}"; do
  MATHESIS_DATA=$work bash "$here/census-repo.sh" "$repo"
  key=${repo/\//__}
  if [ -s "$work/out/$key.unreach.jsonl" ]; then
    echo "$repo: both clone attempts failed; catalogue unchanged" >&2
    exit 1
  fi
done
MATHESIS_DATA=$work bash "$here/summarise.sh" >/dev/null
bash "$here/build-rows.sh" "$work" "$census/template-paths.txt" > "$work/rows.json"

while IFS= read -r repo; do
  key=${repo/\//__}
  commit=$(cat "$work/out/$key.head")
  jq -cnS --arg r "$repo" --arg d "$today" --arg c "$commit" \
    '{repo:$r, refreshed:$d, commit:$c}' >> "$work/refreshed.jsonl"
done < <(jq -r '.[] | select(.own_files > 0) | .repo' "$work/rows.json")

names=$(printf '%s\n' "${requested[@]}" | jq -R . | jq -cs .)
jq -cS --argjson n "$names" --slurpfile new "$work/rows.json" \
  '[.[] | select(.repo as $r | $n | index($r) | not)] + $new[0] | sort_by(.repo)' \
  "$census/catalogue-rows.json" > "$work/merged-rows.json"
jq -cS --argjson n "$names" --slurpfile new <(jq -cs . "$work/unreachable.jsonl") \
  '[.[] | select(.repo as $r | $n | index($r) | not)] + $new[0]' \
  "$census/unreachable.json" > "$work/merged-unreach.json"
prev=$(cat "$census/refreshed.json" 2>/dev/null || echo "[]")
jq -cS --argjson n "$names" --slurpfile new <(jq -cs . "$work/refreshed.jsonl") \
  '[.[] | select(.repo as $r | $n | index($r) | not)] + $new[0] | sort_by(.repo)' \
  <<<"$prev" > "$work/merged-refreshed.json"

snapshot_stage
cp "$work/merged-rows.json" "$stage/census/catalogue-rows.json"
cp "$work/merged-unreach.json" "$stage/census/unreachable.json"
cp "$work/merged-refreshed.json" "$stage/census/refreshed.json"
snapshot_publish
echo "refreshed: $*; raw output kept in $work"
