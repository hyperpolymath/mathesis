#!/usr/bin/env bash
# For a sampled set of repair commits, save pre- (parent) and post-repair blobs of each workflow file the commit modified.
# Read-only on the clones except for lazily fetched objects into .git (blobless clone promisor fetch).
set -u
EST=/home/user/estate
OUT=/tmp/wfv/blobs; mkdir -p "$OUT"
: > /tmp/wfv/index.tsv
# sample: up to N commits per wave, distinct repos, deterministic (sorted by hash)
N=${N:-10}
sort -t$'\t' -k1,1 -k2,2 /tmp/wfv/g1w.tsv | awk -F'\t' -v n="$N" '{k=$1; if(seen[k SUBSEP $3]++) next; if(c[k]++<n) print}' > /tmp/wfv/sample.tsv
while IFS=$'\t' read -r wave h repo date subj; do
  d="$EST/$repo"; [ -d "$d/.git" ] || continue
  files=$(timeout 60 git -C "$d" diff-tree --no-commit-id --name-status -r "$h" -- .github/workflows 2>/dev/null | awk '$1=="M"{print $2}' | grep -E '\.ya?ml$' | head -4)
  for f in $files; do
    id="${h:0:10}_$(echo "$f" | tr '/' '_')"
    timeout 90 git -C "$d" cat-file -p "$h^:$f" > "$OUT/$id.pre" 2>/dev/null || { rm -f "$OUT/$id.pre"; continue; }
    timeout 90 git -C "$d" cat-file -p "$h:$f"  > "$OUT/$id.post" 2>/dev/null || { rm -f "$OUT/$id.post"; continue; }
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$wave" "$repo" "$h" "$date" "$f" "$id" >> /tmp/wfv/index.tsv
  done
done < /tmp/wfv/sample.tsv
wc -l /tmp/wfv/index.tsv
