#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: gates that cannot fail (silent green).
# (a) runs the canon's own detector scripts/check-pipe-grep-q.sh --list over every clone (fail-open shape
#     `writer | grep -q` under pipefail; standards 0b84726b);
# (b) for every gate script scripts/check-*.sh in every clone: is there any file under tests/ (or test/) that
#     names it, i.e. a candidate negative control? A gate with no test naming it has no evidence it can reject.
# Nothing is written inside any clone.
set -uo pipefail
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/p4}; mkdir -p "$OUT"; cd "$EST"
DET=$EST/metadatastician/standards/scripts/check-pipe-grep-q.sh
: > "$OUT/pipegrep.tsv"; : > "$OUT/gates.tsv"
while read -r repo _; do
  d="$EST/$repo"
  n=$(timeout 120 bash "$DET" --root "$d" --list 2>/dev/null | wc -l)
  printf '%s\t%s\n' "$repo" "$n" >> "$OUT/pipegrep.tsv"
  for g in "$d"/scripts/check-*.sh; do
    [ -f "$g" ] || continue; b=$(basename "$g"); t=0
    if [ -d "$d/tests" ] || [ -d "$d/test" ]; then
      grep -rIlqF -- "$b" "$d/tests" "$d/test" 2>/dev/null && t=1
    fi
    printf '%s\t%s\t%s\n' "$repo" "$b" "$t" >> "$OUT/gates.tsv"
  done
done < "$EST/.stats.tsv"
awk -F'\t' '{s+=$2; if($2>0) r++} END{printf "pipe-into-quiet-grep findings: %d in %d of %d repos\n", s, r, NR}' "$OUT/pipegrep.tsv"
awk -F'\t' '{n++; t+=$3; rp[$1]=1; if(!$3) u[$2]++; a[$2]++} END{printf "gate scripts (scripts/check-*.sh): %d in %d repos; named by some test file: %d; named by none: %d\n", n, length(rp), t, n-t}' "$OUT/gates.tsv"
echo "-- most-copied gate scripts: copies / copies with no test naming them"
awk -F'\t' '{a[$2]++; if(!$3) u[$2]++} END{for(k in a) printf "%d\t%d\t%s\n", a[k], u[k]+0, k}' "$OUT/gates.tsv" | sort -rn | awk 'NR<=25'   # awk reads all input: `sort | head` under pipefail exits 141 (SIGPIPE), which is how the first run of this probe ended
