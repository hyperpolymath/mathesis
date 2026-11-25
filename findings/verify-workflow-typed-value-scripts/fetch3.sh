#!/usr/bin/env bash
set -u
EST=/home/user/estate; OUT=/tmp/wfv/blobs3; mkdir -p "$OUT"; : > /tmp/wfv/index3.tsv
grep -P "^(S_|T_)" /tmp/wfv/sc.tsv | sort -t$'\t' -k1,1 -k2,2 | awk -F'\t' '{k=$1; if(seen[k SUBSEP $3]++) next; if(c[k]++<14) print}' > /tmp/wfv/sample3.tsv
while IFS=$'\t' read -r wave h repo date subj; do
  d="$EST/$repo"; [ -d "$d/.git" ] || continue
  for f in $(timeout 60 git -C "$d" diff-tree --no-commit-id --name-status -r "$h" -- .github/workflows | awk '$1=="M"{print $2}' | grep -E '\.ya?ml$' | head -8); do
    id="${h:0:10}_$(echo "$f" | tr '/' '_')"
    timeout 90 git -C "$d" cat-file -p "$h^:$f" > "$OUT/$id.pre" 2>/dev/null || { rm -f "$OUT/$id.pre"; continue; }
    timeout 90 git -C "$d" cat-file -p "$h:$f" > "$OUT/$id.post" 2>/dev/null || { rm -f "$OUT/$id.post"; continue; }
    printf '%s\t%s\t%s\t%s\t%s\n' "$wave" "$repo" "$h" "$f" "$id" >> /tmp/wfv/index3.tsv
  done
done < /tmp/wfv/sample3.tsv
wc -l /tmp/wfv/index3.tsv
