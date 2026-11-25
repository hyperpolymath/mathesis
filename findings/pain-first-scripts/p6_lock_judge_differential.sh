#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: derived-artefact desync (actions.lock vs workflow YAML).
# For every cloned repo with .github/workflows/actions.lock, at checked-out HEAD:
#   J = verdict of the proved judge (proven-cicd-and-workflows src/Proven/Lock/Judge.idr, built from the
#       shipped C dist/proven-lock/proven-lock-verdict.c + vendored RefC runtime; facts by scripts/extract-lock-facts.sh)
#   T = exit of rsr-template-repo HEAD scripts/check-lock-sync.sh
#   O = exit of the repo's OWN scripts/check-lock-sync.sh, when it carries one
# Nothing is written inside any clone. Needs: mikefarah yq v4 on PATH, jq, gcc-built judge at $V.
set -uo pipefail
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/lock}; V=${V:-$OUT/proven-lock}
SUITE=$EST/hyperpolymath/proven-cicd-and-workflows; TPL=$EST/hyperpolymath/rsr-template-repo/scripts/check-lock-sync.sh
: > "$OUT/verdicts.tsv"
while read -r repo _; do
  d="$EST/$repo"; [ -f "$d/.github/workflows/actions.lock" ] || continue
  f="$OUT/facts.json"; j=NOT_RUN; why=""
  if timeout 120 bash "$SUITE/scripts/extract-lock-facts.sh" "$d" > "$f" 2> "$OUT/x.err"; then
    timeout 60 "$V" --json "$f" > "$OUT/v.jsonl" 2>/dev/null; rc=$?
    case $rc in 0) j=CONSISTENT;; 1) j=INCONSISTENT;; *) j=NOT_RUN; why="verdict";; esac
    reasons=$(jq -r 'select(has("reason")) | .reason' "$OUT/v.jsonl" 2>/dev/null | sort | uniq -c | awk '{printf "%s:%s,", $2, $1}')
  else why="extract: $(head -c 100 "$OUT/x.err" | tr '\n\t' '  ')"; reasons=""; fi
  ( cd "$d" && timeout 120 bash "$TPL" .github/workflows >/dev/null 2>&1 ); t=$?
  o=none; if [ -f "$d/scripts/check-lock-sync.sh" ]; then ( cd "$d" && timeout 120 bash scripts/check-lock-sync.sh .github/workflows >/dev/null 2>&1 ); o=$?; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "$j" "$t" "$o" "${reasons:-}" "$why" >> "$OUT/verdicts.tsv"
done < "$EST/.stats.tsv"
echo "repos with actions.lock: $(wc -l < "$OUT/verdicts.tsv")"
echo "-- judge verdicts"; cut -f2 "$OUT/verdicts.tsv" | sort | uniq -c
echo "-- template check-lock-sync.sh exit codes"; cut -f3 "$OUT/verdicts.tsv" | sort | uniq -c
echo "-- own-copy check-lock-sync.sh exit codes"; cut -f4 "$OUT/verdicts.tsv" | sort | uniq -c
echo "-- judge x template-script"; awk -F'\t' '{print $2" / template_exit="$3}' "$OUT/verdicts.tsv" | sort | uniq -c
echo "-- judge x own-copy"; awk -F'\t' '$4!="none"{print $2" / own_exit="$4}' "$OUT/verdicts.tsv" | sort | uniq -c
echo "-- judge reasons (count of findings by reason, summed over repos)"
cut -f5 "$OUT/verdicts.tsv" | tr ',' '\n' | awk -F: 'NF==2{a[$1]+=$2} END{for(k in a) print a[k], k}' | sort -rn
