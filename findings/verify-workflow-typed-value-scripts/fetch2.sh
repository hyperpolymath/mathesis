#!/usr/bin/env bash
set -u
EST=/home/user/estate; OUT=/tmp/wfv/blobs2; mkdir -p "$OUT"; : > /tmp/wfv/index2.tsv
while read -r wave repo h; do
  d="$EST/$repo"
  # batch-fetch: list all modified workflow files, then cat-file each pre blob
  for f in $(timeout 60 git -C "$d" diff-tree --no-commit-id --name-status -r "$h" -- .github/workflows | awk '$1=="M"{print $2}' | grep -E '\.ya?ml$'); do
    id="${h:0:10}_$(echo "$f" | tr '/' '_')"
    timeout 90 git -C "$d" cat-file -p "$h^:$f" > "$OUT/$id.pre" 2>/dev/null || { rm -f "$OUT/$id.pre"; continue; }
    printf '%s\t%s\t%s\t%s\t%s\n' "$wave" "$repo" "$h" "$f" "$id" >> /tmp/wfv/index2.tsv
  done
done < /tmp/wfv/miss.txt
wc -l /tmp/wfv/index2.tsv
