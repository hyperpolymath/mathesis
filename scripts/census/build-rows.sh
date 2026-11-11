#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Fold the raw, path-level census into one row per repository.
#
# Usage: build-rows.sh RAW_DIR TEMPLATE > rows.jsonl
#   RAW_DIR   files.jsonl, holes.jsonl, decls.jsonl, repos-with-status.jsonl,
#             meta.jsonl
#             (written by census-repo.sh + summarise.sh; not committed)
#   TEMPLATE  template-blobs.tsv: "path<TAB>blob" for every blob the RSR
#             template has had at a proof-file path (template-blobs.sh). A
#             file is template boilerplate only when its own (path, blob) is
#             listed, so a repository that rewrote a template file in place is
#             credited with it. A plain path list (template-paths.txt) still
#             works, and so do raw rows without a blob: both fall back to
#             matching by path alone. The template repository itself
#             (hyperpolymath/rsr-template-repo) owns its files.
#
# The output is JSON Lines (standards JSON-POLICY J-2): one JCS record for each
# repository, in byte order of the repository name. A change to one row then
# changes one line only.
# Each row carries its provenance from meta.jsonl: `commit`, the commit that
# the census read, and `censused_at`, when it read it. A row without them is an
# error, never a row with no source.
#
# Rows carry counts only, never file paths, so the committed data neither
# grows with the estate's file trees nor repeats other repositories' paths.
# Files under tests/, fixtures/, corpus/, benches/ count as fixtures. "theory"
# is a first-pass heuristic: more Agda/Lean/Rocq/Isabelle files than
# Idris2/SPARK/Creusot/Verus files. A human confirms each row.
#
# status_doc names one document per repository. A repository's proof status
# lives in its PROOF-STATUS file (standards PROOF-POLICY §8.5); proof-debt
# lists holes and PROOF-NEEDS lists obligations. So the rank is PROOF-STATUS,
# then proof-debt, then PROOF-NEEDS, by basename. A document nested deeper than
# one directory (outside docs/status/ and .machine_readable/compliance/)
# usually belongs to a sub-project and ranks after every shallow one. Within a
# rank the first path in byte order wins.
#
# Each input list is read with FILENAME==ARGV[1], not NR==FNR: an empty list
# makes NR==FNR true for the next file, which then vanishes.
set -euo pipefail
R=$1 T=$2
home=hyperpolymath/rsr-template-repo
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
: > "$tmp/template.tsv"

# Split files into template boilerplate ($tmp/template.tsv: repo, path) and
# the repository's own files (passed on).
jq -r '[.repo,.path,.ext,(.blob // "")]|@tsv' "$R/files.jsonl" \
| awk -F'\t' -v TM="$tmp/template.tsv" -v home="$home" '
    FILENAME == ARGV[1] { tp[$1]=1; if (NF >= 2 && $2 != "") { tb[$1 "\t" $2]=1; nb++ }; next }
    { tmpl = ($1 == home) ? 0 : ($4 != "" && nb > 0) ? (($2 "\t" $4) in tb) : ($2 in tp)
      if (tmpl) print $1 "\t" $2 > TM; else print }' "$T" - \
| awk -F'\t' 'BEGIN{OFS="\t"} {
    e=$3; p="other"
    if (e ~ /agda/) p="agda"; else if (e ~ /idr|ipkg/) p="idris2"
    else if (e ~ /lean|lakefile/) p="lean"; else if (e == "v" || e ~ /CoqProject/) p="rocq"
    else if (e == "thy") p="isabelle"; else if (e == "tla" || e == "cfg") p="tla"
    else if (e == "dk" || e == "lp") p="dedukti"; else if (e ~ /smt2|tptp/ || e == "p") p="smt-atp"
    else if (e ~ /ad[sbc]/) p="spark"; else if (e == "mlw") p="why3"
    else if (e == "fst") p="fstar"; else if (e == "dfy") p="dafny"; else if (e == "als") p="alloy"
    else if (e == "rs-creusot") p="creusot"; else if (e == "rs-verus") p="verus"
    fx = ($2 ~ /(^|\/)(tests?|fixtures?|corpus|corpus_fixtures|benches|benchmarks?)\//) ? 1 : 0
    print $1, p, fx }' > "$tmp/cls.tsv"

jq -r '[.repo,.file,.class]|@tsv' "$R/holes.jsonl" \
| awk -F'\t' 'FILENAME==ARGV[1]{t[$1 "\t" $2]=1;next} !(($1 "\t" $2) in t){print $1"\t"$3}' "$tmp/template.tsv" - > "$tmp/holes.tsv"

jq -r '[.repo,.file]|@tsv' "$R/decls.jsonl" \
| awk -F'\t' 'FILENAME==ARGV[1]{t[$1 "\t" $2]=1;next} !(($1 "\t" $2) in t){print $1}' "$tmp/template.tsv" - > "$tmp/decls.tsv"

jq -r '.repo+"\t"+.path' "$R/repos-with-status.jsonl" \
| awk -F'\t' 'BEGIN{OFS="\t"} {
    b = tolower($2); sub(/.*\//, "", b)
    rk = (b ~ /^proof-status/) ? 0 : (b ~ /proof-debt/) ? 1 : 2
    d = $2; if (d ~ /\//) sub(/\/[^\/]*$/, "", d); else d = ""
    if (d ~ /\// && d !~ /^(docs\/status|\.machine_readable\/compliance)$/) rk += 10
    print $1, rk, $2 }' \
| LC_ALL=C sort -t$'\t' -k1,1 -k2,2n -k3,3 | cut -f1,3 > "$tmp/status.tsv"

awk -F'\t' '
  FILENAME ~ /holes\.tsv$/  { h[$1" "$2]++; next }
  FILENAME ~ /decls\.tsv$/  { d[$1]++; next }
  FILENAME ~ /status\.tsv$/ { if (!($1 in st)) st[$1]=$2; next }
  { n[$1]++; if ($3) fx[$1]++; pc[$1" "$2]++
    if ($2 ~ /agda|lean|rocq|isabelle/) th[$1]++; if ($2 ~ /idris2|spark|creusot|verus/) en[$1]++ }
  END {
    split("agda lean rocq isabelle idris2 spark creusot verus tla dedukti smt-atp why3 fstar dafny alloy other", L, " ")
    for (r in n) {
      provers=""
      for (i=1;i<=16;i++) if (pc[r" "L[i]]) provers = provers L[i] " " pc[r" "L[i]] ", "
      sub(/, $/, "", provers)
      printf "%s\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\n",
        (th[r]+0 > en[r]+0) ? "theory" : "engineering", r, n[r], fx[r]+0, provers,
        d[r]+0, h[r" hole"]+0, h[r" axiom"]+0, h[r" unsafe"]+0, h[r" policy"]+0,
        (r in st) ? st[r] : ""
    }
  }' "$tmp/holes.tsv" "$tmp/decls.tsv" "$tmp/status.tsv" "$tmp/cls.tsv" \
| LC_ALL=C sort -t$'\t' -k2,2 \
| jq -RcS --slurpfile meta "$R/meta.jsonl" '
    (reduce $meta[] as $m ({}; .[$m.repo] = $m)) as $by
  | split("\t") | {class:.[0], repo:.[1], own_files:(.[2]|tonumber),
    fixture_files:(.[3]|tonumber), provers:.[4], declarations:(.[5]|tonumber),
    holes:(.[6]|tonumber), axioms:(.[7]|tonumber), unsafe:(.[8]|tonumber),
    policy:(.[9]|tonumber), status_doc:.[10]}
  | . as $row
  | ($by[$row.repo] // error("build-rows: no commit recorded for " + $row.repo)) as $m
  | $row + {commit: $m.commit, censused_at: $m.censused_at}'
