#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only measurement (2026-11-24): SHA-pinned refs to standards reusable workflows.
# For each (workflow file, pinned SHA): does the SHA resolve in the local standards clone, which blob does the
# file have at that SHA, how many commits behind HEAD is the pin (raw) and how many of those touched the file.
# Uses tree objects only (no blob fetch). Output: resolved.txt, dist.txt in $OUT.
set -euo pipefail
EST=${EST:-/home/user/estate}; STD=${STD:-$EST/metadatastician/standards}; OUT=${OUT:-$(mktemp -d)}
cd "$EST"
rg -N --no-heading -o -g '*.yml' -g '*.yaml' \
  'uses:\s*(hyperpolymath|metadatastician)/standards/(\.github/workflows/[A-Za-z0-9_.-]+)@([0-9a-f]{40})' \
  -r '$2 $3' */*/.github/workflows 2>/dev/null | sed -E 's/^[^ ]*:(\.github)/\1/' > "$OUT/refs.txt"
sort "$OUT/refs.txt" | uniq -c | awk '{print $2, $3, $1}' > "$OUT/pairs.txt"
: > "$OUT/resolved.txt"; : > "$OUT/dist.txt"
while read -r f sha n; do
  if git -C "$STD" cat-file -e "$sha^{commit}" 2>/dev/null; then
    blob=$(git -C "$STD" rev-parse -q --verify "$sha:$f" 2>/dev/null || echo MISSINGFILE)
    raw=$(git -C "$STD" rev-list --count "$sha..HEAD"); sem=$(git -C "$STD" rev-list --count "$sha..HEAD" -- "$f")
    echo "$f $sha $n $raw $sem" >> "$OUT/dist.txt"
  else blob=NOCOMMIT; fi
  head=$(git -C "$STD" rev-parse -q --verify "HEAD:$f" 2>/dev/null || echo NOHEADFILE)
  echo "$f $sha $n $blob $head" >> "$OUT/resolved.txt"
done < "$OUT/pairs.txt"
awk '{s+=$3} END{print "refs:", s}' "$OUT/resolved.txt"
awk '$4=="NOCOMMIT"{s+=$3; k++} END{print "unresolved refs:", s+0, "in", k+0, "(file,sha) pairs"}' "$OUT/resolved.txt"
awk '$4==$5{s+=$3} END{print "refs whose file blob equals HEAD blob:", s+0}' "$OUT/resolved.txt"
awk '$4!="NOCOMMIT"{p++; if(!(($1" "$4) in b)){b[$1" "$4]=1; nb++}} END{print "resolvable (file,sha) pairs:", p, "distinct (file,blob) pairs:", nb}' "$OUT/resolved.txt"
awk '{r+=$3*$4; s+=$3*$5; n+=$3} END{printf "mean commits behind HEAD: raw %.1f, file-touching %.1f (n=%d refs)\n", r/n, s/n, n}' "$OUT/dist.txt"
echo "outputs in $OUT"
