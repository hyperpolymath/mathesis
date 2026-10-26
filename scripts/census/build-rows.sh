#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Fold the raw, path-level census into one row per repository.
#
# Usage: build-rows.sh RAW_DIR TEMPLATE_PATHS > catalogue-rows.jsonl
#   RAW_DIR         files.jsonl, holes.jsonl, decls.jsonl, repos-with-status.jsonl
#                   (written by census-repo.sh + summarise.sh; not committed)
#   TEMPLATE_PATHS  one path per line: proof files the RSR template ships,
#                   which are boilerplate wherever they appear
#
# Rows carry counts only, never file paths, so the committed data neither
# grows with the estate's file trees nor repeats other repositories' paths.
# A repo's "own" files are those not on the template list; files under
# tests/, fixtures/, corpus/, benches/ count as fixtures. "theory" is a
# first-pass heuristic: more Agda/Lean/Rocq/Isabelle files than Idris2/SPARK
# files. A human confirms each row.
set -euo pipefail
R=$1 T=$2
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

jq -r '[.repo,.path,.ext]|@tsv' "$R/files.jsonl" \
| awk -F'\t' 'NR==FNR{t[$1]=1;next} !($2 in t)' "$T" - \
| awk -F'\t' 'BEGIN{OFS="\t"} {
    e=$3; p="other"
    if (e ~ /agda/) p="agda"; else if (e ~ /idr|ipkg/) p="idris2"
    else if (e ~ /lean|lakefile/) p="lean"; else if (e == "v" || e ~ /CoqProject/) p="rocq"
    else if (e == "thy") p="isabelle"; else if (e == "tla" || e == "cfg") p="tla"
    else if (e == "dk" || e == "lp") p="dedukti"; else if (e ~ /smt2|tptp/ || e == "p") p="smt-atp"
    else if (e ~ /ad[sb]/) p="spark"; else if (e == "mlw") p="why3"
    else if (e == "fst") p="fstar"; else if (e == "dfy") p="dafny"; else if (e == "als") p="alloy"
    fx = ($2 ~ /(^|\/)(tests?|fixtures?|corpus|corpus_fixtures|benches|benchmarks?)\//) ? 1 : 0
    print $1, p, fx }' > "$tmp/cls.tsv"

jq -r '[.repo,.file,.class]|@tsv' "$R/holes.jsonl" \
| awk -F'\t' 'NR==FNR{t[$1]=1;next} !($2 in t){print $1"\t"$3}' "$T" - > "$tmp/holes.tsv"

jq -r '[.repo,.file]|@tsv' "$R/decls.jsonl" \
| awk -F'\t' 'NR==FNR{t[$1]=1;next} !($2 in t){print $1}' "$T" - > "$tmp/decls.tsv"

jq -r '.repo+"\t"+.path' "$R/repos-with-status.jsonl" | sort > "$tmp/status.tsv"

awk -F'\t' '
  FILENAME ~ /holes\.tsv$/  { h[$1" "$2]++; next }
  FILENAME ~ /decls\.tsv$/  { d[$1]++; next }
  FILENAME ~ /status\.tsv$/ { if (!($1 in st)) st[$1]=$2; next }
  { n[$1]++; if ($3) fx[$1]++; pc[$1" "$2]++
    if ($2 ~ /agda|lean|rocq|isabelle/) th[$1]++; if ($2 ~ /idris2|spark/) en[$1]++ }
  END {
    split("agda lean rocq isabelle idris2 spark tla dedukti smt-atp why3 fstar dafny alloy other", L, " ")
    for (r in n) {
      provers=""
      for (i=1;i<=14;i++) if (pc[r" "L[i]]) provers = provers L[i] " " pc[r" "L[i]] ", "
      sub(/, $/, "", provers)
      printf "%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\n",
        (th[r]+0 > en[r]+0) ? "theory" : "engineering", r, n[r], fx[r]+0, provers,
        d[r]+0, h[r" hole"]+0, h[r" axiom"]+0, h[r" unsafe"]+0, h[r" policy"]+0,
        (r in st) ? st[r] : ""
    }
  }' "$tmp/holes.tsv" "$tmp/decls.tsv" "$tmp/status.tsv" "$tmp/cls.tsv" \
| sort -t$'\t' -k2,2 \
| jq -RcS 'split("\t") | {class:.[0], repo:.[1], own_files:(.[2]|tonumber),
    fixture_files:(.[3]|tonumber), provers:.[4], declarations:(.[5]|tonumber),
    holes:(.[6]|tonumber), axioms:(.[7]|tonumber), unsafe:(.[8]|tonumber),
    policy:(.[9]|tonumber), status_doc:.[10]}'
