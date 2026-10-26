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
#
# This is a textual scan: it finds candidates, it does not decide them. A
# kernel-level audit (#print axioms, Print Assumptions, gnatprove report,
# agda --safe) is the authority; see references/ledger.md. Whole-line comments
# are skipped; markers inside block comments or strings may still be reported.
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
    -h|--help) sed -n '3,22p' "$0"; exit 0 ;;
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
creusot~*.rs~^\s*//~axiom~#[trusted]~#\[\s*(creusot::)?trusted\s*\]
creusot~*.rs~^\s*//~hole~assume!~\b(proof_)?assume!\s*\(
spark~*.adb,*.ads~^\s*--~hole~pragma Assume~pragma\s+Assume\b
spark~*.adb,*.ads~^\s*--~unsafe~SPARK_Mode Off~SPARK_Mode\s*(=>\s*)?\(?\s*Off
spark~*.adb,*.ads~^\s*--~unsafe~Skip_Proof~Skip_(Flow_And_)?Proof
spark~*.adb,*.ads~^\s*--~axiom~Annotate False_Positive~Annotate\s*\(\s*GNATprove\s*,\s*(False_Positive|Intentional)
dedukti~*.dk,*.lp~^\s*(//|\(;)~hole~admit~\badmit(ted)?\b
EOF
)

emit() { # lang class marker file line text
  jq -cnS --arg lang "$1" --arg class "$2" --arg marker "$3" --arg file "$4" \
        --argjson line "$5" --arg text "$6" \
        '{lang:$lang,class:$class,marker:$marker,file:$file,line:$line,text:$text}'
}

OUT=$(mktemp); trap 'rm -f "$OUT"' EXIT
while IFS='~' read -r lang globs comment class marker re; do
  [ -z "$lang" ] && continue
  inc=(); IFS=',' read -ra gl <<<"$globs"; for g in "${gl[@]}"; do inc+=(--include="$g"); done
  # Rocq shares .v with V and Verilog; only scan .v files that look like Rocq.
  grep -rnPI "${EXCLUDE[@]}" "${inc[@]}" -e "$re" "$DIR" 2>/dev/null | while IFS= read -r hit; do
    f=${hit%%:*}; rest=${hit#*:}; n=${rest%%:*}; txt=${rest#*:}
    printf '%s\n' "$txt" | grep -qP -- "$comment" && continue
    if [ "$lang" = rocq ] && ! grep -qE '^\s*(Require|From|Theorem|Lemma|Definition|Inductive|Proof\.)' "$f"; then continue; fi
    if [ "$lang" = creusot ] && ! grep -qE 'creusot|pearlite|#\[\s*(requires|ensures)' "$f"; then continue; fi
    emit "$lang" "$class" "$marker" "${f#"$DIR"/}" "$n" "$(printf '%s' "$txt" | sed 's/^\s*//' | cut -c1-200)"
  done >>"$OUT"
done <<<"$RULES"

# Agda: every non-fixture module should be checked under --safe.
while IFS= read -r f; do
  grep -qE 'OPTIONS[^#]*--safe' "$f" || emit agda policy "no --safe" "${f#"$DIR"/}" 1 "file does not set {-# OPTIONS --safe #-}" >>"$OUT"
done < <(find "$DIR" \( -name .git -o -name _build -o -name build -o -name target $(for d in "${EXTRA_EX[@]}"; do printf -- "-o -name %s " "$d"; done)\) -prune -o -type f -name '*.agda' -print 2>/dev/null)

sort -u "$OUT"

if [ "$SUMMARY" = 1 ]; then
  jq -rs 'group_by(.lang+" "+.class) | map("\(.[0].lang) \(.[0].class): \(length)") | .[]' "$OUT" >&2
fi

count() { jq -s --arg c "$1" '[.[] | select($c=="any" or .class==$c)] | length' "$OUT"; }
case "$FAIL_ON" in
  none) exit 0 ;;
  hole) [ "$(count hole)" -eq 0 ] ;;
  axiom) [ "$(( $(count hole) + $(count axiom) ))" -eq 0 ] ;;
  any) [ "$(count any)" -eq 0 ] ;;
esac
