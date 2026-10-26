#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Usage: census-repo.sh OWNER/REPO   (run with cwd-independent absolute paths)
# Writes per-repo outputs into $BASE/out/<owner>__<repo>.{files,decls,holes,agdaopts,status,unreach}.jsonl
set -uo pipefail
FN=$1
BASE=${MATHESIS_DATA:?set MATHESIS_DATA to the census work directory}
HOLES=$(cd "$(dirname "$0")" && pwd)/proof-holes.sh
KEY=${FN/\//__}
D=$BASE/clones/$KEY
O=$BASE/out/$KEY
mkdir -p "$BASE/out"
rm -rf "$D" "$O".*

clone() { timeout 600 git clone -q --depth 1 --filter=blob:none --no-checkout "https://github.com/$FN" "$D" 2>&1; }
err=$(clone); rc=$?
if [ $rc -ne 0 ]; then
  rm -rf "$D"; sleep 2; err=$(clone); rc=$?
fi
if [ $rc -ne 0 ]; then
  jq -cnS --arg r "$FN" --arg e "$(printf '%s' "$err" | tr '\n' ' ' | cut -c1-300)" --argjson rc $rc '{repo:$r,error:$e,exit:$rc}' > "$O.unreach.jsonl"
  rm -rf "$D"; exit 0
fi

git -C "$D" ls-tree -r --name-only HEAD > "$O.tree" 2>/dev/null || true
if ! [ -s "$O.tree" ]; then rm -rf "$D" "$O.tree"; exit 0; fi

# proof-status docs
grep -iE '(^|/)(PROOF-STATUS[^/]*|PROOF-NEEDS[^/]*|proof-debt[^/]*)$' "$O.tree" \
  | jq -RcS --arg r "$FN" '{path:., repo:$r}' > "$O.status.jsonl"

# candidate paths
grep -E '\.(agda|lagda|lagda\.md|idr|lidr|ipkg|lean|v|thy|tla|cfg|dk|lp|smt2|tptp|p|ads|adb|mlw|fst|dfy|als|gpr)$|(^|/)(\.?lean-toolchain|lakefile\.lean|lakefile\.toml|_CoqProject|dune|dune-project)$|\.agda-lib$' "$O.tree" > "$O.cand"
if ! [ -s "$O.cand" ]; then rm -rf "$D"; rm -f "$O.tree" "$O.cand"; [ -s "$O.status.jsonl" ] || rm -f "$O.status.jsonl"; exit 0; fi

# .cfg only if a .tla sits in the same directory; dune only if .v exists
grep -E '\.tla$' "$O.cand" | sed -E 's#[^/]*$##' | sort -u > "$O.tladirs"
grep -qE '\.v$' "$O.cand" && HASV=1 || HASV=0
: > "$O.co"
while IFS= read -r p; do
  case "$p" in
    *.cfg) dir=${p%"${p##*/}"}; grep -qxF -- "$dir" "$O.tladirs" && echo "$p" >> "$O.co" ;;
    dune|*/dune|dune-project|*/dune-project) [ $HASV = 1 ] && echo "$p" >> "$O.co" ;;
    *) echo "$p" >> "$O.co" ;;
  esac
done < "$O.cand"

if [ -s "$O.co" ]; then
  tr '\n' '\0' < "$O.co" | (cd "$D" && timeout 1800 xargs -0 -n 400 git checkout -q HEAD -- >/dev/null 2>&1)
fi

# Rocq repo-level gate
ROCQ=0
if grep -qE '(^|/)_CoqProject$' "$O.cand"; then ROCQ=1; fi
if [ $ROCQ = 0 ] && [ $HASV = 1 ]; then
  while IFS= read -r p; do
    case "$p" in dune|*/dune|dune-project|*/dune-project) grep -qiE '\(coq|\(rocq' "$D/$p" 2>/dev/null && ROCQ=1 ;; esac
  done < "$O.co"
  if [ $ROCQ = 0 ]; then
    while IFS= read -r p; do
      grep -qE '(Require|Theorem)' "$D/$p" 2>/dev/null && { ROCQ=1; break; }
    done < <(grep -E '\.v$' "$O.co")
  fi
fi
# SPARK repo-level gate
SPARK=0
grep -qE '\.gpr$' "$O.cand" && SPARK=1
if [ $SPARK = 0 ]; then
  while IFS= read -r p; do grep -qi 'SPARK_Mode' "$D/$p" 2>/dev/null && { SPARK=1; break; }; done < <(grep -E '\.(ads|adb)$' "$O.co")
fi

prover_of() {
  case "$1" in
    *.agda|*.lagda|*.lagda.md|*.agda-lib) echo agda ;;
    *.idr|*.lidr|*.ipkg) echo idris2 ;;
    *.lean|*lean-toolchain|*lakefile.lean|*lakefile.toml) echo lean ;;
    *.v|*_CoqProject) echo rocq ;;
    *.thy) echo isabelle ;;
    *.tla|*.cfg) echo tla ;;
    *.dk) echo dedukti ;;
    *.lp) echo lambdapi ;;
    *.smt2) echo smtlib ;;
    *.tptp|*.p) echo tptp ;;
    *.ads|*.adb|*.gpr) echo spark ;;
    *.mlw) echo why3 ;;
    *.fst) echo fstar ;;
    *.dfy) echo dafny ;;
    *.als) echo alloy ;;
  esac
}
ext_of() {
  local b=${1##*/}
  case "$b" in
    *.lagda.md) echo lagda.md ;;
    lean-toolchain|.lean-toolchain|lakefile.lean|lakefile.toml|_CoqProject) echo "$b" ;;
    *.agda-lib) echo agda-lib ;;
    *.*) echo "${b##*.}" ;;
    *) echo "$b" ;;
  esac
}

: > "$O.keep"
while IFS= read -r p; do
  f=$D/$p
  case "$p" in
    dune|*/dune|dune-project|*/dune-project) continue ;;
    *.v)
      [ $ROCQ = 1 ] || continue
      # skip obvious Verilog
      if grep -qE '^\s*endmodule' "$f" 2>/dev/null && ! grep -qE '^\s*(Require|From|Theorem|Lemma|Definition|Inductive)' "$f"; then continue; fi ;;
    *.ads|*.adb|*.gpr) [ $SPARK = 1 ] || continue ;;
    *.p) grep -qE '^\s*(fof|cnf|tff|thf|include)\(' "$f" 2>/dev/null || continue ;;
    *.lp) grep -qE '^\s*(symbol|require|rule|constant|injective|opaque)\b' "$f" 2>/dev/null || continue ;;
  esac
  echo "$p" >> "$O.keep"
done < "$O.co"

while IFS= read -r p; do
  jq -cnS --arg e "$(ext_of "$p")" --arg p "$p" --arg r "$FN" '{ext:$e,path:$p,repo:$r}'
done < "$O.keep" > "$O.files.jsonl"

# declarations: emit TSV prover\tkind\tline\tname\tfile then convert
: > "$O.decl.tsv"
while IFS= read -r p; do
  f=$D/$p; pr=$(prover_of "$p")
  [ -f "$f" ] || continue
  case "$p" in
    *.lean)
      grep -nE '^\s*((private|protected|noncomputable|partial|unsafe|@\[[^]]*\])\s+)*(theorem|lemma|def|structure|inductive|axiom)\s+[^ :({\[]+' "$f" \
      | sed -E 's/^([0-9]+):\s*((private|protected|noncomputable|partial|unsafe|@\[[^]]*\])\s+)*(theorem|lemma|def|structure|inductive|axiom)\s+([^ :({[]+).*/\1\t\4\t\5/' \
      | awk -F'\t' -v pr=lean -v fl="$p" 'NF==3{print pr"\t"$2"\t"$1"\t"$3"\t"fl}' ;;
    *.v)
      grep -nE '^\s*(Theorem|Lemma|Corollary|Proposition|Fact|Remark|Definition|Fixpoint|Inductive|Axiom|Parameter)\s+[^ :({]+' "$f" \
      | sed -E 's/^([0-9]+):\s*(Theorem|Lemma|Corollary|Proposition|Fact|Remark|Definition|Fixpoint|Inductive|Axiom|Parameter)\s+([^ :({.]+).*/\1\t\2\t\3/' \
      | awk -F'\t' -v pr=rocq -v fl="$p" 'NF==3{print pr"\t"$2"\t"$1"\t"$3"\t"fl}' ;;
    *.thy)
      grep -nE '^\s*(theorem|lemma|corollary|definition|fun|datatype|axiomatization)\s+[^ :]+' "$f" \
      | sed -E 's/^([0-9]+):\s*(theorem|lemma|corollary|definition|fun|datatype|axiomatization)\s+("?[^ :"]+"?).*/\1\t\2\t\3/' \
      | awk -F'\t' -v pr=isabelle -v fl="$p" 'NF==3{gsub(/"/,"",$3); print pr"\t"$2"\t"$1"\t"$3"\t"fl}' ;;
    *.agda|*.lagda|*.lagda.md)
      awk -v fl="$p" -v lit=$([[ "$p" == *.lagda* ]] && echo 1 || echo 0) '
        BEGIN{code = lit ? 0 : 1; post=0}
        {
          line=$0
          if (lit) {
            if (line ~ /^\\begin\{code\}/ || line ~ /^```/) { if (line ~ /^```/) code = !code; else code=1; next }
            if (line ~ /^\\end\{code\}/) { code=0; next }
            if (!code) next
          }
          if (post && line ~ /^[ \t]+[^ \t-][^ \t]*([ \t]+[^ \t:][^ \t]*)*[ \t]+:([ \t]|$)/) {
            s=line; sub(/^[ \t]+/,"",s); n=split(s,a,/[ \t]+/); for(i=1;i<=n && a[i]!=":";i++) print "agda\tpostulate\t" NR "\t" a[i] "\t" fl; next }
          if (line ~ /^[^ \t]/) post=0
          if (line ~ /^postulate[ \t]+[^ \t]/) { s=line; sub(/^postulate[ \t]+/,"",s); n=split(s,a,/[ \t]+/); for(i=1;i<=n && a[i]!=":";i++) print "agda\tpostulate\t" NR "\t" a[i] "\t" fl }
          if (line ~ /^postulate([ \t]|$)/) { post=1; print "agda\tpostulate-block\t" NR "\tpostulate\t" fl; next }
          if (line ~ /^(data|record)[ \t]+[^ \t]+/) { split(line,a,/[ \t]+/); print "agda\t" a[1] "\t" NR "\t" a[2] "\t" fl; next }
          if (line ~ /^(module|open|import|infix|infixl|infixr|private|abstract|instance|mutual|variable|syntax|pattern|--|\{-)/) next
          if (line ~ /^[^ \t:][^ \t]*([ \t]+[^ \t:][^ \t]*)*[ \t]+:([ \t]|$)/) { split(line,a,/[ \t]+/); print "agda\tsig\t" NR "\t" a[1] "\t" fl }
        }' "$f" ;;
    *.idr)
      awk -v fl="$p" '
        /^(module|import|namespace|%|--|\|\|\||infix|infixl|infixr|prefix|mutual|parameters|using)/ {next}
        /^((public[ \t]+)?export[ \t]+|private[ \t]+)?(data|record|interface)[ \t]+[^ \t]+/ {
          s=$0; sub(/^((public[ \t]+)?export[ \t]+|private[ \t]+)/,"",s); split(s,a,/[ \t]+/); print "idris2\t" a[1] "\t" NR "\t" a[2] "\t" fl; next }
        /^((public[ \t]+)?export[ \t]+|private[ \t]+|total[ \t]+|partial[ \t]+|covering[ \t]+)*[^ \t:(][^ \t]*[ \t]+:([ \t]|$)/ {
          s=$0; while (s ~ /^(public|export|private|total|partial|covering)[ \t]+/) sub(/^[^ \t]+[ \t]+/,"",s); split(s,a,/[ \t]+/); print "idris2\tsig\t" NR "\t" a[1] "\t" fl }' "$f" ;;
    *.tla)
      grep -nE '^\s*(THEOREM|LEMMA)\s+[A-Za-z_][A-Za-z0-9_]*\s*==' "$f" \
      | sed -E 's/^([0-9]+):\s*(THEOREM|LEMMA)\s+([A-Za-z0-9_]+).*/\1\t\2\t\3/' \
      | awk -F'\t' -v fl="$p" 'NF==3{print "tla\t"$2"\t"$1"\t"$3"\t"fl}' ;;
    *.cfg)
      awk -v fl="$p" '
        /^[ \t]*(INVARIANT|INVARIANTS|PROPERTY|PROPERTIES)([ \t]|$)/ { mode=$1; for(i=2;i<=NF;i++) if ($i ~ /^[A-Za-z_]/) print "tla\t" mode "\t" NR "\t" $i "\t" fl; next }
        /^[ \t]*[A-Z]+([ \t]|$)/ && $1 ~ /^(CONSTANT|CONSTANTS|INIT|NEXT|SPECIFICATION|SYMMETRY|VIEW|CONSTRAINT|ACTION_CONSTRAINT|CHECK_DEADLOCK|ALIAS|POSTCONDITION)$/ { mode=""; next }
        mode!="" && /^[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]*$/ { s=$0; gsub(/[ \t]/,"",s); print "tla\t" mode "\t" NR "\t" s "\t" fl }' "$f" ;;
  esac
done < "$O.keep" >> "$O.decl.tsv"
awk -F'\t' 'NF==5' "$O.decl.tsv" | jq -RcS --arg r "$FN" 'split("\t") | {prover:.[0],kind:.[1],line:(.[2]|tonumber),name:.[3],file:.[4],repo:$r}' > "$O.decls.jsonl"

# Agda OPTIONS pragmas
while IFS= read -r p; do
  case "$p" in
    *.agda|*.lagda|*.lagda.md)
      opts=$(grep -oE '\{-#\s*OPTIONS[^#]*#-\}' "$D/$p" 2>/dev/null | sed -E 's/\{-#\s*OPTIONS\s*//; s/\s*#-\}//' | tr '\n' ' ' | sed 's/ *$//')
      jq -cnS --arg f "$p" --arg o "$opts" --arg r "$FN" '{file:$f,options:$o,repo:$r,safe:($o|test("--safe"))}' ;;
    *.agda-lib)
      fl=$(grep -E '^\s*flags\s*:' "$D/$p" 2>/dev/null | sed -E 's/^\s*flags\s*:\s*//' | tr '\n' ' ' | sed 's/ *$//')
      jq -cnS --arg f "$p" --arg o "$fl" --arg r "$FN" '{file:$f,lib_flags:$o,repo:$r,safe:($o|test("--safe"))}' ;;
  esac
done < "$O.keep" > "$O.agdaopts.jsonl"

# holes (only if any kept proof file)
if [ -s "$O.keep" ]; then
  timeout 1800 bash "$HOLES" --fail-on none "$D" 2>/dev/null | jq -cS --arg r "$FN" '. + {repo:$r}' > "$O.holes.jsonl"
fi

rm -rf "$D"
rm -f "$O.tree" "$O.cand" "$O.co" "$O.tladirs" "$O.decl.tsv" "$O.keep"
for x in "$O".*; do [ -s "$x" ] || rm -f "$x"; done
exit 0
