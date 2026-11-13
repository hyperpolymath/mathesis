#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# proof-craft: inventory proof escape hatches in a tree.
#
# Usage: proof-holes.sh [--fail-on hole|axiom|any|none] [--summary] [--exclude DIRNAME]... [DIR]
#
# Prints one JSON object per finding (keys sorted, one per line):
#   {"class":…,"file":…,"lang":…,"line":N,"marker":…,"text":…}
# class is one of
#   hole    an unfinished proof (sorry, Admitted, ?hole, believe_me, …)  -> OWED
#   axiom   trusted base grows (postulate, Axiom, #[trusted], pragma Assume, …)
#   unsafe  a checker is switched off (TERMINATING, Unset Guard Checking, SPARK_Mode Off, …)
#   policy  estate rule broken (import Mathlib, Agda file without --safe)
#   control a finding inside a declared negative control: a file whose own header
#           carries a line comment `EXPECT: <pattern>`, the home repository's
#           statement that the checker must reject it for that reason (for
#           example CompositionalDA.jl proofs/agda/reject/). It is reported, not
#           dropped, but it is not a hole, axiom, unsafe or policy count and does
#           not affect --fail-on: the home gate is what rejects it.
#
# This is a textual scan: it finds candidates, it does not decide them. A
# kernel-level audit (#print axioms, Print Assumptions, gnatprove report,
# agda --safe) is the authority; see references/ledger.md. Each file is scanned
# with its comments blanked out (nested block comments, line comments, and
# string literals where the language has a simple string syntax), so prose
# that mentions a marker is not reported. Agda/Idris pragmas are kept.
#
# Local changes in hyperpolymath/mathesis (2026-11-09, landed 2026-11-10):
# the comment-blanking pass, the Idris2 undefined-declaration rule, the Verus
# rules and the wider Creusot #[trusted] rule are not yet in the proof-craft
# skill this file was copied from; carry them back there.
#
# Exit: 0 clean at the chosen --fail-on level (default: hole), 1 otherwise,
# 2 usage error.
set -uo pipefail

FAIL_ON=hole SUMMARY=0 DIR=. EXTRA_EX=()
while [ $# -gt 0 ]; do
  case "$1" in
    --fail-on) FAIL_ON=${2:-}; shift 2 ;;
    --summary) SUMMARY=1; shift ;;
    --exclude) EXTRA_EX+=("$2"); shift 2 ;;
    -h|--help) sed -n '3,28p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) DIR=$1; shift ;;
  esac
done
case "$FAIL_ON" in hole|axiom|any|none) ;; *) echo "--fail-on must be hole|axiom|any|none" >&2; exit 2 ;; esac
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }

EXCLUDE=(--exclude-dir=.git --exclude-dir=target --exclude-dir=_build --exclude-dir=build
         --exclude-dir=.lake --exclude-dir=node_modules --exclude-dir=deps --exclude-dir=vendor)
for d in "${EXTRA_EX[@]}"; do EXCLUDE+=(--exclude-dir="$d"); done

# rule: lang~include-globs~comment-regex~class~marker~PCRE
# (comment-regex is kept for the rule format; comments are now blanked by
# strip_comments before matching, so it is no longer consulted.)
RULES=$(cat <<'EOF'
agda~*.agda,*.lagda,*.lagda.md~^\s*--~axiom~postulate~^\s*postulate\b
agda~*.agda,*.lagda,*.lagda.md~^\s*--~hole~{! !}~\{!
agda~*.agda,*.lagda,*.lagda.md~^\s*--~unsafe~TERMINATING~\{-#\s*(NON_)?TERMINATING\s*#-\}
agda~*.agda,*.lagda,*.lagda.md~^\s*--~unsafe~NO_POSITIVITY_CHECK~\{-#\s*NO_POSITIVITY_CHECK
agda~*.agda,*.lagda,*.lagda.md~^\s*--~unsafe~NO_UNIVERSE_CHECK~\{-#\s*NO_UNIVERSE_CHECK
agda~*.agda,*.lagda,*.lagda.md~^\s*--~unsafe~--type-in-type~--type-in-type
agda~*.agda,*.lagda,*.lagda.md~^\s*--~axiom~primTrustMe~\bprimTrustMe\b
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~hole~believe_me~\bbelieve_me\b
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~hole~assert_total~\bassert_total\b
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~hole~assert_smaller~\bassert_smaller\b
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~hole~idris_crash~\bidris_crash\b
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~hole~?hole~(^|[\s(=])\?[a-z_][A-Za-z0-9_']*
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~unsafe~%default partial~%default\s+partial
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~unsafe~partial~^\s*partial\b
idris2~*.idr,*.lidr~^\s*(--|\|\|\|)~axiom~unsafePerformIO~\bunsafePerformIO\b
lean~*.lean~^\s*--~hole~sorry~\bsorry\b
lean~*.lean~^\s*--~hole~admit~\badmit\b
lean~*.lean~^\s*--~axiom~axiom~^\s*(private\s+|protected\s+)?axiom\b
lean~*.lean~^\s*--~axiom~native_decide~\bnative_decide\b
lean~*.lean~^\s*--~axiom~implemented_by~@\[implemented_by
lean~*.lean~^\s*--~unsafe~unsafe~^\s*(private\s+)?unsafe\b
lean~*.lean~^\s*--~policy~import Mathlib~^\s*import\s+Mathlib
rocq~*.v~^\s*\(\*~hole~Admitted~\bAdmitted\.
rocq~*.v~^\s*\(\*~hole~admit~\badmit\.
rocq~*.v~^\s*\(\*~hole~give_up~\bgive_up\b
rocq~*.v~^\s*\(\*~axiom~Axiom~^\s*(Axiom|Axioms|Conjecture|Parameter|Parameters)\b
rocq~*.v~^\s*\(\*~unsafe~Unset Checking~Unset\s+(Guard|Positivity|Universe)\s+Checking
rocq~*.v~^\s*\(\*~unsafe~bypass_check~#\[\s*bypass_check
isabelle~*.thy~^\s*\(\*~hole~sorry~\bsorry\b
isabelle~*.thy~^\s*\(\*~hole~oops~\boops\b
isabelle~*.thy~^\s*\(\*~axiom~axiomatization~\baxiomatization\b
isabelle~*.thy~^\s*\(\*~unsafe~quick_and_dirty~quick_and_dirty
creusot~*.rs~^\s*//~axiom~#[trusted]~#\[\s*((creusot|creusot_std|creusot_contracts)::(macros::)?)?trusted\s*\]|cfg_attr\([^)]*,\s*((creusot|creusot_std|creusot_contracts)::(macros::)?)?trusted\s*\)
verus~*.rs~^\s*//~hole~admit()~\badmit\s*\(\s*\)
verus~*.rs~^\s*//~axiom~assume()~(?<![!\w])assume\s*\(
verus~*.rs~^\s*//~axiom~external_body~#\[\s*verifier(::|\s*\(\s*)external_body
verus~*.rs~^\s*//~axiom~assume_specification~\bassume_specification\b
creusot~*.rs~^\s*//~hole~assume!~\b(proof_)?assume!\s*\(
spark~*.adb,*.ads~^\s*--~hole~pragma Assume~pragma\s+Assume\b
spark~*.adb,*.ads~^\s*--~unsafe~SPARK_Mode Off~SPARK_Mode\s*(=>\s*)?\(?\s*Off
spark~*.adb,*.ads~^\s*--~unsafe~Skip_Proof~Skip_(Flow_And_)?Proof
spark~*.adb,*.ads~^\s*--~axiom~Annotate False_Positive~Annotate\s*\(\s*GNATprove\s*,\s*(False_Positive|Intentional)
dedukti~*.dk,*.lp~^\s*(//|\(;)~hole~admit~\badmit(ted)?\b
EOF
)

# A negative control declares itself: a line comment `EXPECT: <pattern>` in the
# file names the error the home gate expects when it rejects the file.
is_control() { grep -qE '^[[:space:]]*(--|//|#)[[:space:]]*EXPECT:[[:space:]]*[^[:space:]]' "$1" 2>/dev/null; }
emit() { # lang class marker file line text
  if [ "$2" != control ] && is_control "$DIR/$4"; then set -- "$1" control "$3" "$4" "$5" "$6"; fi
  jq -cnS --arg lang "$1" --arg class "$2" --arg marker "$3" --arg file "$4" \
        --argjson line "$5" --arg text "$6" \
        '{lang:$lang,class:$class,marker:$marker,file:$file,line:$line,text:$text}'
}

OUT=$(mktemp); MIRROR=$(mktemp -d); trap 'rm -rf "$OUT" "$MIRROR"' EXIT

# Comment syntax per language: block-open block-close line-comment
# second-line-comment kept-pragma-opener string-style ("-" = none).
syntax() {
  case "$1" in
    rocq) echo '(* *) - - - dq' ;;
    isabelle) echo '(* *) - - - -' ;;
    agda) echo '{- -} -- - {-# bs' ;;
    idris2) echo '{- -} -- ||| {-# bs' ;;
    lean) echo '/- -/ -- - - bs' ;;
    creusot) echo '/* */ // - - bs' ;;
    verus) echo '/* */ // - - bs' ;;
    spark) echo '- - -- - - dq' ;;
    dedukti) echo '(; ;) // - - -' ;;
  esac
}
strip_comments() { # lang file -> stdout
  read -r bo bc lc lc2 keep str <<<"$(syntax "$1")"
  for v in bo bc lc lc2 keep str; do [ "${!v}" = - ] && printf -v "$v" ''; done
  awk -v bo="$bo" -v bc="$bc" -v lc="$lc" -v lc2="$lc2" -v keep="$keep" -v str="$str" '
  # Blank out comments (and, where str is set, string literals) while keeping
  # every newline, so line numbers and the code on each line stay put.
  # Variables: bo/bc block-comment open/close (nested), lc line-comment
  # prefix (empty for none), lc2 a second line prefix, keep a block opener
  # that is *not* a comment (Agda/Idris pragmas "{-#", closed by "#-}"),
  # str = "bs" (backslash escapes), "dq" (doubled quote) or "" (none).
  BEGIN { depth = 0; instr = 0; inkeep = 0 }
  {
    out = ""; n = length($0); i = 1
    while (i <= n) {
      c = substr($0, i, 1)
      if (instr) {
        if (str == "bs" && c == "\\") { out = out "  "; i += 2; continue }
        if (c == "\"") {
          if (str == "dq" && substr($0, i + 1, 1) == "\"") { out = out "  "; i += 2; continue }
          instr = 0; out = out c; i++; continue
        }
        out = out " "; i++; continue
      }
      if (depth > 0) {
        if (substr($0, i, length(bo)) == bo) { depth++; out = out sprintf("%*s", length(bo), ""); i += length(bo); continue }
        if (substr($0, i, length(bc)) == bc) { depth--; out = out sprintf("%*s", length(bc), ""); i += length(bc); continue }
        out = out " "; i++; continue
      }
      if (inkeep) {
        if (substr($0, i, 3) == "#-}") { inkeep = 0; out = out "#-}"; i += 3; continue }
        out = out c; i++; continue
      }
      if (keep != "" && substr($0, i, length(keep)) == keep) { inkeep = 1; out = out keep; i += length(keep); continue }
      if (bo != "" && substr($0, i, length(bo)) == bo) { depth = 1; out = out sprintf("%*s", length(bo), ""); i += length(bo); continue }
      if (lc != "" && substr($0, i, length(lc)) == lc) break
      if (lc2 != "" && substr($0, i, length(lc2)) == lc2) break
      if (str != "" && c == "\"") { instr = 1; out = out c; i++; continue }
      out = out c; i++
    }
    print out
  }
  ' "$2"
}
PRUNE=(.git target _build build .lake node_modules deps vendor "${EXTRA_EX[@]}")
mirror() { # lang globs -> fills $MIRROR/<lang>/ with comment-blanked copies
  local lang=$1 g names=() pr=()
  IFS=',' read -ra gl <<<"$2"; for g in "${gl[@]}"; do names+=(-o -name "$g"); done
  for g in "${PRUNE[@]}"; do pr+=(-o -name "$g"); done
  find "$DIR" \( "${pr[@]:1}" \) -prune -o -type f \( "${names[@]:1}" \) -print 2>/dev/null |
  while IFS= read -r src; do
    rel=${src#"$DIR"/}; mkdir -p "$MIRROR/$lang/$(dirname "$rel")"
    strip_comments "$lang" "$src" > "$MIRROR/$lang/$rel"
  done
}
while IFS='~' read -r lang globs comment class marker re; do
  [ -z "$lang" ] && continue
  inc=(); IFS=',' read -ra gl <<<"$globs"; for g in "${gl[@]}"; do inc+=(--include="$g"); done
  # Rocq shares .v with V and Verilog; only scan .v files that look like Rocq.
  [ -d "$MIRROR/$lang" ] || { mkdir -p "$MIRROR/$lang"; mirror "$lang" "$globs"; }
  grep -rnPI "${inc[@]}" -e "$re" "$MIRROR/$lang" 2>/dev/null | while IFS= read -r hit; do
    m=${hit%%:*}; rest=${hit#*:}; n=${rest%%:*}
    f="$DIR/${m#"$MIRROR/$lang"/}"; txt=$(sed -n "${n}p" "$f")
    if [ "$lang" = rocq ] && ! grep -qE '^\s*(Require|From|Theorem|Lemma|Definition|Inductive|Proof\.)' "$f"; then continue; fi
    if [ "$lang" = creusot ] && ! grep -qE 'creusot|pearlite|#\[\s*(requires|ensures)' "$f"; then continue; fi
    if [ "$lang" = verus ] && ! grep -qE 'verus!\s*\{' "$f"; then continue; fi
    emit "$lang" "$class" "$marker" "${f#"$DIR"/}" "$n" "$(printf '%s' "$txt" | sed 's/^\s*//' | cut -c1-200)"
  done >>"$OUT"
done <<<"$RULES"

# Idris2: a top-level signature with no clauses is accepted and treated as a
# postulate, even under %default total (checked with Idris2 0.8.0), so it is
# an axiom candidate. FFI signatures after %foreign/%extern are not reported.
UNDEF_AWK="$(cd "$(dirname "$0")" && pwd)/idris2-undefined.awk"
[ -d "$MIRROR/idris2" ] || { mkdir -p "$MIRROR/idris2"; mirror idris2 "*.idr,*.lidr"; }
while IFS= read -r m; do
  f="$DIR/${m#"$MIRROR/idris2"/}"
  awk -f "$UNDEF_AWK" "$m" | while IFS=$'\t' read -r n name; do
    emit idris2 axiom "undefined declaration" "${f#"$DIR"/}" "$n" "$(sed -n "${n}p" "$f" | sed 's/^[[:space:]]*//' | cut -c1-200)"
  done
done < <(find "$MIRROR/idris2" -type f -name '*.idr') >>"$OUT"

# Agda: every non-fixture module should be checked under --safe.
while IFS= read -r f; do
  grep -qE 'OPTIONS[^#]*--safe' "$f" || emit agda policy "no --safe" "${f#"$DIR"/}" 1 "file does not set {-# OPTIONS --safe #-}" >>"$OUT"
done < <(find "$DIR" \( -name .git -o -name _build -o -name build -o -name target $(for d in "${EXTRA_EX[@]}"; do printf -- "-o -name %s " "$d"; done)\) -prune -o -type f -name '*.agda' -print 2>/dev/null)

sort -u "$OUT"

if [ "$SUMMARY" = 1 ]; then
  jq -rs 'group_by(.lang+" "+.class) | map("\(.[0].lang) \(.[0].class): \(length)") | .[]' "$OUT" >&2
fi

count() { jq -s --arg c "$1" '[.[] | select(.class!="control" and ($c=="any" or .class==$c))] | length' "$OUT"; }
case "$FAIL_ON" in
  none) exit 0 ;;
  hole) [ "$(count hole)" -eq 0 ] ;;
  axiom) [ "$(( $(count hole) + $(count axiom) ))" -eq 0 ] ;;
  any) [ "$(count any)" -eq 0 ] ;;
esac
