#!/usr/bin/env bash
# Read-only probe for Ring 3 candidate "exact-resemblance law, both ways" (BFO generic vs specific dependence).
# For a list of paths, report: repos holding the path, distinct blob ids at HEAD, size of the largest
# byte-identical group. Uses `git ls-tree` object ids only (no blob is fetched or read).
# Usage: bash resemblance_probe.sh PATH...   (run from /home/user/estate)
for p in "$@"; do
  for r in */*/; do
    id=$(git -C "$r" ls-tree HEAD -- "$p" 2>/dev/null | awk '{print $3}')
    [ -n "$id" ] && echo "$id"
  done | sort | uniq -c | sort -rn | awk -v p="$p" '{n+=$1; d++; if (NR==1) top=$1} END {printf "%-58s repos=%4d distinct=%4d largest-identical=%4d\n", p, n+0, d+0, top+0}'
done
