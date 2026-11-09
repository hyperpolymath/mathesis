#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Fold the raw, path-level census into one row per repository.
#
# Usage: build-rows.sh RAW_DIR TEMPLATE_PATHS [TEMPLATE_BLOBS] > catalogue-rows.json
#   RAW_DIR         files.jsonl, holes.jsonl, decls.jsonl, repos-with-status.jsonl
#                   (written by census-repo.sh + summarise.sh; not committed)
#   TEMPLATE_PATHS  one path per line: proof files the RSR template ships
#   TEMPLATE_BLOBS  one git blob id per line: every version the template ever
#                   shipped at those paths (template-blobs.sh). Optional.
#
# Rows carry counts only, never file paths, so the committed data neither
# grows with the estate's file trees nor repeats other repositories' paths.
# A file is template boilerplate when its path is on the template list AND
# its blob is one the template shipped. A customised template file (a repo
# that edited its ABI, as the template asks it to) is the repo's own. With no
# TEMPLATE_BLOBS, or a file recorded without a blob (older census data), the
# path alone decides, as before. Every other file is "own"; files under
# tests/, fixtures/, corpus/, benches/ count as fixtures. "theory" is a
# first-pass heuristic: more Agda/Lean/Rocq/Isabelle files than Idris2/SPARK
# files. A human confirms each row.
set -euo pipefail
R=$1 T=$2 TB=${3:-}
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# boiler.tsv: the (repo, path) pairs that are template boilerplate.
# known.tsv: every (repo, path) the census recorded.
if [ -n "$TB" ]; then cp "$TB" "$tmp/blobs.txt"; else : > "$tmp/blobs.txt"; fi
jq -r '[.repo,.path,(.blob // "")]|@tsv' "$R/files.jsonl" \
| awk -F'\t' -v tb="$TB" -v known="$tmp/known.tsv" '
    FILENAME == ARGV[1] { t[$1]=1; next }
    FILENAME == ARGV[2] { b[$1]=1; next }
    { print $1"\t"$2 > known
      if (($2 in t) && (tb == "" || $3 == "" || ($3 in b))) print $1"\t"$2 }' \
    "$T" "$tmp/blobs.txt" - > "$tmp/boiler.tsv"

# own FILE COL: keep lines whose (repo, path) is not boilerplate. A path on the
# template list that the census never recorded as a file counts as boilerplate.
own() {
  awk -F'\t' -v col="$2" '
    FILENAME == ARGV[1] { t[$1]=1; next }
    FILENAME == ARGV[2] { bo[$1"\t"$2]=1; next }
    FILENAME == ARGV[3] { kn[$1"\t"$2]=1; next }
    { k=$1"\t"$col
      if (k in bo) next
      if (($col in t) && !(k in kn)) next
      print }' "$T" "$tmp/boiler.tsv" "$tmp/known.tsv" "$1"
}

jq -r '[.repo,.path,.ext]|@tsv' "$R/files.jsonl" > "$tmp/files.tsv"
own "$tmp/files.tsv" 2 \
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

jq -r '[.repo,.file,.class]|@tsv' "$R/holes.jsonl" > "$tmp/holes-all.tsv"
own "$tmp/holes-all.tsv" 2 | awk -F'\t' '{print $1"\t"$3}' > "$tmp/holes.tsv"

jq -r '[.repo,.file]|@tsv' "$R/decls.jsonl" > "$tmp/decls-all.tsv"
own "$tmp/decls-all.tsv" 2 | awk -F'\t' '{print $1}' > "$tmp/decls.tsv"

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
    policy:(.[9]|tonumber), status_doc:.[10]}' \
| jq -cS -s .
