#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# check-proofs.sh <prover>            prover in: idris2 | lean4 | agda | coq
#
# The single source of truth for "do the <prover> proofs in this repo compile?".
# build/just/proofs.just calls this (`just proof-check-<prover>`), and CI should
# too, so a green local run and a green CI run mean the same thing.
#
# It replaces four separate "checks that could not fail" that let non-compiling
# proofs sit in estate repos for months while every status file said "proved":
#
#   1. `command -v <prover> || { echo SKIP; exit 0; }` — a MISSING TOOLCHAIN
#      reported success.  A gate that cannot run must never report OK: it
#      manufactures false confidence, which is worse than having no gate.
#   2. `<prover> --check <full/path/To/Mod>` — Idris2 (and friends) derive the
#      expected module name from the path they are handed, so a module checked
#      from the wrong directory fails on a name mismatch rather than its real
#      errors, and verdicts invert.  Every module here is checked from its own
#      SOURCE ROOT (declared in the MANIFEST).
#   3. Path-filtered CI that only looked at one directory — nothing checked the
#      rest.  Here, a proof file present on disk but absent from the MANIFEST is
#      an ERROR, so new proofs are gated by default, not by remembering.
#   4. `idris2 --check X && ok` — `idris2 --check` EXITS 0 ON A MISSING IMPORT
#      (verified against 0.7.0) while printing `Error: ...`.  Testing the exit
#      code alone is unsound; for idris2 we require exit 0 AND no `Error:` line.
#
# They share one shape: a null check that emits reassuring text.  If you extend
# this script, the test to apply is not "does it pass?" but "have I watched it
# fail?".
#
# CONVENTION: proofs live under verification/proofs/<prover>/ ; the MANIFEST for
# a prover is verification/proofs/<prover>/MANIFEST, one entry per line:
#
#   <source-root>|<module-path-relative-to-source-root>|gated|quarantine|<note>
#
#     source-root : directory the prover is invoked from, chosen so the module's
#                   declared name matches its path (getting this wrong is hole #2).
#     gated       : MUST compile.  A failure fails this script and CI.
#     quarantine  : known-broken, tracked in docs/status/ROADMAP.adoc.  Must CONTINUE to fail;
#                   if one starts compiling the script fails and tells you to
#                   promote it, so the list cannot rot into a permanent excuse.
#
# Blank lines and lines starting with # are ignored.
#
# Exit: 0 = every gated module compiles AND every quarantined module still fails
#           AND every proof file on disk is listed; 1 = otherwise; 2 = misuse.

set -euo pipefail

PROVER="${1:-}"
case "$PROVER" in
  idris2|lean4|agda|coq) ;;
  *) echo "usage: $(basename "$0") <idris2|lean4|agda|coq>" >&2; exit 2 ;;
esac

# This script lives in <repo-root>/scripts/ ; run everything from the repo root.
cd "$(dirname "${BASH_SOURCE[0]}")/.."
ROOT="$PWD"
PROOF_DIR="verification/proofs/$PROVER"
MANIFEST_FILE="$PROOF_DIR/MANIFEST"

# --- per-prover configuration -------------------------------------------------
# CMD      : executable that must be on PATH (absent => FAIL, never skip).
# EXT      : file extension, for the "unlisted proof" coverage scan.
# ERROR_RE : if non-empty, output must not match it even when the exit code is 0.
#            Only idris2 needs this (its --check exits 0 on a missing import);
#            for lean4 it is a harmless belt-and-braces guard.
case "$PROVER" in
  idris2) CMD=idris2; EXT=idr;  ERROR_RE='^Error:' ;;
  lean4)  CMD=lean;   EXT=lean; ERROR_RE='error:'  ;;
  agda)   CMD=agda;   EXT=agda; ERROR_RE=''        ;;
  coq)    CMD=coqc;   EXT=v;    ERROR_RE=''        ;;
esac

check_one() {
  # $1 source-root (rel to ROOT), $2 module (rel to source-root).
  # Sets LAST_OUT to the tool output on failure; returns 0 iff the module compiles.
  local root="$1" rel="$2" out rc
  set +e
  case "$PROVER" in
    idris2) out="$(cd "$ROOT/$root" && idris2 --check "$rel" 2>&1)"; rc=$? ;;
    lean4)  out="$(cd "$ROOT/$root" && lean          "$rel" 2>&1)"; rc=$? ;;
    agda)   out="$(cd "$ROOT/$root" && agda --safe --without-K --cubical-compatible "$rel" 2>&1)"; rc=$? ;;
    coq)    out="$(cd "$ROOT/$root" && coqc           "$rel" 2>&1)"; rc=$? ;;
  esac
  set -e
  if [ "$rc" -eq 0 ] && { [ -z "$ERROR_RE" ] || ! grep -qE "$ERROR_RE" <<<"$out"; }; then
    LAST_OUT=""; return 0
  fi
  LAST_OUT="$out"; return 1
}

# --- axiom audit: a gated module must also be free of axioms -------------------
# Compiling is not enough (re-anchoring plan WO 1.3): coqc accepts `Admitted`
# and lean accepts `sorry`; both name the gap only in their axiom reports. So a
# gated module that compiles is audited as well, and fails if its axiom report
# names an axiom. PROOF-POLICY §8.4: axioms travel with the grade.
#   agda : the first-party modules of the import cone that Agda itself reports
#          go through scan-postulates.sh (the reference gate of januskey).
#   coq  : two checks, both required.
#          (1) coqchk -o, Rocq's independent kernel checker, re-checks the
#          compiled library and its whole import cone (the standard library
#          included) and lists every assumption in it: axioms (an Admitted
#          proof is one), type-in-type, unsafe (co)fixpoints and assumed
#          positivity. Each list must be <none>, and Set predicative. This
#          reads the compiled library, not the source text, so no spelling
#          escapes it: Local, #[local], Program, Instance, a nested Module,
#          an unused Axiom and a guard bypass were each caught (measured
#          2026-11-17; the text matcher alone passed an unused
#          `Local Definition planted : False. Admitted.`).
#          (2) `Print Assumptions` for every Theorem, Lemma, Corollary,
#          Proposition, Fact, Remark, Example, Definition, Fixpoint and
#          CoFixpoint that the comment-free source declares (Local, Global,
#          Program, Polymorphic, Monomorphic and #[...] prefixes allowed) must
#          print "Closed under the global context". It names what the receipt
#          covers, and it refuses a file that declares nothing.
#   lean4: every theorem and every definition that carries a source range
#          must depend on no axiom (Lean.collectAxioms, the function behind
#          #print axioms), and the source may declare no axiom of its own,
#          used or not. That covers each declaration of the source, and
#          the definitions Lean generates for an inductive with its range
#          (casesOn, recOn, below, brecOn, ...), which are counted too. The
#          lemmas Lean generates (injEq, inj, sizeOf_spec) carry no range.
#          (Measured 2026-11-17: before the axiom rule, a module holding a
#          clean theorem and an unused `axiom planted : False` passed.)
# Definitions are audited as well as theorems because a development can
# carry its results as definitions: THY-1's Lean leg is Type-valued, so every
# result there is a `def`, and an audit of theorems alone inspected none of
# them (proof audit 2026-11-16, finding 31). Measured before this fix: a Lean
# module whose only declaration was `def planted : 2 + 2 = 5 := sorry`, or a
# Rocq file whose only declaration was an Admitted Definition, PASSED.
# Each audit fails closed: if it cannot show that it ran, or if it inspected
# no declaration at all, the module fails. An empty audit is not a clean one.
# Both axiom reports are transitive: a theorem's report covers every Fixpoint,
# Definition or def it uses. A declaration that no audited theorem uses is not
# reported; Lean still warns on its sorry, and Rocq still compiles its Admitted.
# On success the gate prints the receipt fields of PWG-1 (PROOF-POLICY 8.2) for
# each gated module: the SHA-256 of the file and the axioms reported.
audit_one() {
  # $1 source-root, $2 module; sets LAST_OUT on failure; returns 0 iff clean.
  # On success AUDIT_NOTE holds the axiom report that a receipt records (PWG-1),
  # and AUDIT_SUMMARY the same report without the list of names it covers.
  AUDIT_NOTE=""; AUDIT_SUMMARY=""
  local root="$1" rel="$2" dir out rc base copy names expect got
  dir="$(mktemp -d)"
  case "$PROVER" in
    agda)
      set +e
      out="$(cd "$ROOT/$root" && agda --safe --without-K --cubical-compatible \
              --dependency-graph="$dir/cone.dot" "$rel" 2>&1)"; rc=$?
      set -e
      if [ "$rc" -ne 0 ] || [ ! -s "$dir/cone.dot" ]; then
        LAST_OUT="axiom audit: no import cone from agda --dependency-graph"$'\n'"$out"; rm -rf "$dir"; return 1
      fi
      : >"$dir/own"
      sed -n 's/.*label="\([^"]*\)".*/\1/p' "$dir/cone.dot" | LC_ALL=C sort -u |
        while IFS= read -r name; do
          f="$ROOT/$root/${name//.//}.agda"
          [ -f "$f" ] && echo "$f" >>"$dir/own"
        done
      [ -s "$dir/own" ] || { LAST_OUT="axiom audit: no first-party module in the import cone"; rm -rf "$dir"; return 1; }
      set +e; mapfile -t own <"$dir/own"; out="$(bash "$ROOT/scripts/scan-postulates.sh" "${own[@]}" 2>&1)"; rc=$?; set -e
      AUDIT_SUMMARY="postulates: none in the ${#own[@]} first-party module(s) of the import cone"
      AUDIT_NOTE="$AUDIT_SUMMARY: $(sed -n 's/.*label="\([^"]*\)".*/\1/p' "$dir/cone.dot" | LC_ALL=C sort -u | tr '\n' ' ')"
      ;;
    coq)
      if ! command -v coqchk >/dev/null 2>&1; then
        rm -rf "$dir"; LAST_OUT="axiom audit: coqchk not on PATH (the kernel audit cannot run, so the module fails)"; return 1
      fi
      base="$(basename "$rel" .v)"; copy="GateAudit_${base}"
      # Comments (nested, across lines) and string literals are blanked first,
      # as Rocq's lexer reads them, so a declaration in a comment is not
      # collected. Line breaks are kept, so the Module stack sees real lines.
      names="$(awk '
        { out = ""; n = length($0)
          for (i = 1; i <= n; i++) {
            c = substr($0, i, 1); two = substr($0, i, 2)
            if (instr) { if (c == "\"") { if (substr($0, i + 1, 1) == "\"") i++; else instr = 0 }; continue }
            if (c == "\"") { instr = 1; continue }
            if (two == "(*") { depth++; i++; continue }
            if (two == "*)" && depth > 0) { depth--; i++; continue }
            if (depth == 0) out = out c }
          print out }' "$ROOT/$root/$rel" | awk '
        /^[ \t]*Module[ \t]+Type[ \t]/ { split($0, w, /[ \t.]+/); stack[++d] = "T:" w[4]; next }
        /^[ \t]*Module[ \t]+[A-Za-z_][A-Za-z0-9_'\'']*[ \t]*\.[ \t]*$/ ||
        /^[ \t]*Module[ \t]+[A-Za-z_][A-Za-z0-9_'\'']*[ \t]*[:(<]/ && !/:=/ {
          s = $0; sub(/^[ \t]*Module[ \t]+/, "", s); sub(/[^A-Za-z0-9_'\''].*/, "", s); stack[++d] = "M:" s; next }
        /^[ \t]*Section[ \t]/ { stack[++d] = "S:"; next }
        /^[ \t]*End[ \t]/ { if (d > 0) d--; next }
        /^[ \t]*((Local|Global|Program|Polymorphic|Monomorphic|#\[[^]]*\])[ \t]+)*(Theorem|Lemma|Corollary|Proposition|Fact|Remark|Example|Definition|Fixpoint|CoFixpoint)[ \t]/ {
          s = $0; sub(/^[ \t]*((Local|Global|Program|Polymorphic|Monomorphic|#\[[^]]*\])[ \t]+)*[A-Za-z]+[ \t]+/, "", s); sub(/[^A-Za-z0-9_'\''].*/, "", s)
          q = ""; for (i = 1; i <= d; i++) if (stack[i] ~ /^M:/) q = q substr(stack[i], 3) "."
          print q s }')"
      if [ -z "$names" ]; then rm -rf "$dir"; LAST_OUT="axiom audit: no theorem or definition declared, so nothing was audited"; return 1; fi
      { cat "$ROOT/$root/$rel"; echo; while IFS= read -r n; do echo "Print Assumptions $n."; done <<<"$names"; } \
        >"$ROOT/$root/$copy.v"
      set +e; out="$(cd "$ROOT/$root" && coqc "$copy.v" 2>&1)"; rc=$?
      # The kernel audit reads the library that coqc has just written.
      chk=""; chk_rc=1
      [ "$rc" -eq 0 ] && { chk="$(cd "$ROOT/$root" && coqchk -silent -o -Q . "" "$copy" 2>&1)"; chk_rc=$?; }
      set -e
      rm -f "$ROOT/$root/$copy".{v,vo,vok,vos,glob} "$ROOT/$root/.$copy".aux
      expect="$(grep -c . <<<"$names")"
      got="$(grep -c '^Closed under the global context' <<<"$out" || true)"
      # coqchk exits 0 when it finds an assumption; only its summary tells.
      # A list that is not empty prints its header with no value and the
      # names on the lines below, so every "* " line must be one of these.
      summary="$(sed -n '/^CONTEXT SUMMARY/,$p' <<<"$chk" | sed 's/[[:space:]]*$//')"
      kernel_ok=0
      if [ "$chk_rc" -eq 0 ] && [ -n "$summary" ] &&
         ! grep -E '^\* ' <<<"$summary" | grep -qvxE '\* (Theory: Set is predicative|[^:]+: <none>)'; then
        kernel_ok=1
        for h in "Axioms" "Constants/Inductives relying on type-in-type" \
                 "Constants/Inductives relying on unsafe (co)fixpoints" "Inductives whose positivity is assumed"; do
          grep -qxF "* $h: <none>" <<<"$summary" || kernel_ok=0
        done
        grep -qxF "* Theory: Set is predicative" <<<"$summary" || kernel_ok=0
      fi
      if [ "$rc" -eq 0 ] && [ "$got" -eq "$expect" ] && [ "$kernel_ok" -eq 1 ]; then rc=0
        AUDIT_SUMMARY="coqchk -o: no axiom, type-in-type, unsafe (co)fixpoint or assumed positivity in the library or its import cone; Print Assumptions: closed under the global context for $expect declaration(s)"
        AUDIT_NOTE="$AUDIT_SUMMARY: $(tr '\n' ' ' <<<"$names")"
      elif [ "$rc" -eq 0 ] && [ "$got" -eq "$expect" ]; then rc=1
        out="axiom audit: the kernel checker (coqchk -o) reports an assumption, or did not run (exit $chk_rc)"$'\n'"${summary:-$chk}"
      else rc=1; out="axiom audit: $got of $expect declaration(s) closed under the global context"$'\n'"$out"; fi
      ;;
    lean4)
      { echo "import Lean"; cat "$ROOT/$root/$rel"; cat <<'LEAN'

open Lean Elab Command in
#eval show CommandElabM Unit from do
  let env ← getEnv
  let mut n := 0
  let mut m := 0
  for (name, ci) in env.constants.map₂.toList do
    -- An axiom the source declares fails the module even if nothing uses it.
    if let .axiomInfo _ := ci then
      if (← liftCoreM (findDeclarationRanges? name)).isSome then
        logInfo m!"GATE-AXIOMS {name}: declared by the source"
      continue
    -- Theorems and definitions the source declares: the declarations Lean
    -- generates (injEq, inj, sizeOf_spec, match_1, …) carry no range.
    let isThm := match ci with | .thmInfo _ => true | _ => false
    let isDef := match ci with | .defnInfo _ => true | .opaqueInfo _ => true | _ => false
    unless isThm || isDef do continue
    if (← liftCoreM (findDeclarationRanges? name)).isNone then continue
    if isThm then n := n + 1 else m := m + 1
    let axs ← Lean.collectAxioms name
    unless axs.isEmpty do
      logInfo m!"GATE-AXIOMS {name}: {axs.toList}"
  logInfo m!"GATE-AUDIT-DONE {n} {m}"
LEAN
      } >"$dir/Audit.lean"
      set +e; out="$(cd "$ROOT/$root" && lean "$dir/Audit.lean" 2>&1)"; rc=$?; set -e
      thms="$(sed -n 's/.*GATE-AUDIT-DONE \([0-9]*\) \([0-9]*\).*/\1/p' <<<"$out")"
      defs="$(sed -n 's/.*GATE-AUDIT-DONE \([0-9]*\) \([0-9]*\).*/\2/p' <<<"$out")"
      if [ "$rc" -ne 0 ] || [ -z "$thms" ] || grep -q 'GATE-AXIOMS' <<<"$out"; then
        rc=1; out="axiom audit: a declaration depends on an axiom, or the audit did not run"$'\n'"$(grep -E 'GATE-|error' <<<"$out" || printf '%s' "$out")"
      elif [ $((thms + defs)) -eq 0 ]; then
        rc=1; out="axiom audit: no theorem or definition declared, so nothing was audited"
      fi
      [ "$rc" -eq 0 ] && AUDIT_NOTE="axioms: none for $thms theorem(s) and $defs definition(s) with a source range" && AUDIT_SUMMARY="$AUDIT_NOTE"
      ;;
    *) rc=0; out="" ;;
  esac
  rm -rf "$dir"
  if [ "$rc" -eq 0 ]; then LAST_OUT=""; return 0; fi
  LAST_OUT="$out"; return 1
}

echo "=== $PROVER proof check ==="

# --- the receipt report: what a ledger row of this run records -----------------
# With PROOF_REPORT_DIR set, a run that passes writes $PROOF_REPORT_DIR/$PROVER,
# three lines that scripts/grade-receipt.sh --run-row takes as they are (the
# Proof Policy Gate does, on main; PROOF-POLICY §8.5.1):
#   1. the checker, "<command> <version>", from the version line printed below;
#   2. the axioms the run reported: "none", since a run passes only when every
#      gated module's audit found none;
#   3. what the run reported: the result, then each gated module and the
#      summary of its audit (AUDIT_SUMMARY), in MANIFEST order.
# The file is removed here, before anything can fail (the toolchain check
# included), so a run that fails leaves none behind: a report exists only for
# a run that passed. Nothing is read back from the log.
if [ -n "${PROOF_REPORT_DIR:-}" ]; then
  mkdir -p "$PROOF_REPORT_DIR"
  rm -f -- "${PROOF_REPORT_DIR:?}/${PROVER:?}"
fi

# --- toolchain: absent means FAIL, never skip ---------------------------------
if ! command -v "$CMD" >/dev/null 2>&1; then
  {
    echo "FAIL: '$CMD' not found on PATH."
    echo
    echo "This is deliberately fatal.  The previous recipe did 'exit 0' here with"
    echo "\"SKIP: $CMD not installed\", so every $PROVER proof reported green on any"
    echo "machine that could not check it.  Install the $PROVER toolchain, or run"
    echo "this in CI where the workflow installs it."
  } >&2
  exit 1
fi
TOOL_VERSION="$("$CMD" --version 2>/dev/null | head -1 || true)"
printf '%s\n' "$TOOL_VERSION"

# --- Agda: a data directory it can write ---------------------------------------
# Agda keeps the interfaces of its own primitive modules (Agda.Primitive and the
# Agda.Builtin modules) in <data dir>/lib/prim/_build. A packaged Agda whose
# store path is read-only and ships without them (Guix agda 2.7.0.1, found
# 2026-11-10: "lib/prim/_build: createDirectory: permission denied") cannot
# check any module. Then the gate gives Agda a writable copy of its data
# directory through Agda_datadir, the variable Agda reads for it. The copy holds
# Agda's own library unchanged; only the interfaces are written there.
if [ "$PROVER" = agda ] && [ -z "${Agda_datadir:-}" ]; then
  agda_data="$(agda --print-agda-data-dir 2>/dev/null || true)"
  if [ -n "$agda_data" ] && [ ! -d "$agda_data/lib/prim/_build" ] && [ ! -w "$agda_data/lib/prim" ]; then
    Agda_datadir="$(mktemp -d)"
    cp -r "$agda_data/." "$Agda_datadir/"
    chmod -R u+w "$Agda_datadir"
    export Agda_datadir
    echo "Agda data directory is read-only without interfaces; using a writable copy"
  fi
fi
echo

# --- a repo with proofs but no MANIFEST is itself a failure -------------------
if [ ! -f "$MANIFEST_FILE" ]; then
  if [ -d "$PROOF_DIR" ] && [ -n "$(find "$PROOF_DIR" -name "*.$EXT" 2>/dev/null)" ]; then
    echo "FAIL: $PROOF_DIR contains .$EXT proofs but has no MANIFEST." >&2
    echo "      Create $MANIFEST_FILE listing each as 'gated' or 'quarantine'." >&2
    exit 1
  fi
  echo "no $PROOF_DIR/*.$EXT proofs and no MANIFEST — nothing to check."
  exit 0
fi

fails=0
reported=""
unexpected_pass=0
listed_tmp="$(mktemp)"
trap 'rm -f "$listed_tmp"' EXIT

while IFS='|' read -r root rel status note; do
  # skip blank lines and comments
  [ -z "${root// }" ] && continue
  case "${root#"${root%%[![:space:]]*}"}" in \#*) continue ;; esac
  printf '  %-30s %-24s ' "$root" "$rel"
  echo "$root/$rel" >>"$listed_tmp"
  if check_one "$root" "$rel"; then
    if [ "$status" = gated ] && ! audit_one "$root" "$rel"; then
      echo "FAIL (compiles, but the axiom audit fails)"
      printf '%s\n' "${LAST_OUT//$'\n'/$'\n        '}" | sed '1s/^/        /'
      fails=$((fails + 1))
    elif [ "$status" = gated ]; then
      echo "PASS"
      # The receipt fields of PWG-1: a digest of the input and the axioms reported.
      echo "        sha256 $(sha256sum "$ROOT/$root/$rel" | cut -d' ' -f1)"
      echo "        $AUDIT_NOTE"
      reported+="; $rel: $AUDIT_SUMMARY"
    else
      echo "PASS -- UNEXPECTED (quarantined module now compiles)"
      echo "        Promote '$rel' to 'gated' in $MANIFEST_FILE and update docs/status/ROADMAP.adoc."
      unexpected_pass=$((unexpected_pass + 1))
    fi
  else
    if [ "$status" = gated ]; then
      echo "FAIL"
      printf '%s\n' "${LAST_OUT//$'\n'/$'\n        '}" | sed '1s/^/        /'
      fails=$((fails + 1))
    else
      echo "fail (quarantined, expected)"
      [ -n "${note// }" ] && echo "        reason:$note"
    fi
  fi
done < "$MANIFEST_FILE"

# --- coverage: every proof on disk must be listed -----------------------------
# The anti-recurrence rule: proofs went unchecked for months because nothing
# forced them onto anyone's list.  A file absent from the MANIFEST is an error.
echo
echo "=== manifest coverage ($PROOF_DIR) ==="
listed="$(sort -u "$listed_tmp")"
found="$(cd "$ROOT" && find "$PROOF_DIR" -name "*.$EXT" -not -path '*/build/*' 2>/dev/null | sort)"
unlisted="$(comm -13 <(printf '%s\n' "$listed") <(printf '%s\n' "$found") || true)"
missing="$(comm -23 <(printf '%s\n' "$listed") <(printf '%s\n' "$found") || true)"

if [ -n "${unlisted//[[:space:]]/}" ]; then
  echo "FAIL: .$EXT proofs on disk but absent from $MANIFEST_FILE:"
  printf '  %s\n' $unlisted
  echo "      List each as 'gated' or 'quarantine'; new proofs are gated by default."
  fails=$((fails + 1))
fi
if [ -n "${missing//[[:space:]]/}" ]; then
  echo "FAIL: MANIFEST lists modules that do not exist (stale entries):"
  printf '  %s\n' $missing
  fails=$((fails + 1))
fi
[ -z "${unlisted//[[:space:]]/}${missing//[[:space:]]/}" ] && \
  echo "  all $(printf '%s\n' "$found" | grep -c .) .$EXT file(s) accounted for"

echo
if [ "$fails" -gt 0 ] || [ "$unexpected_pass" -gt 0 ]; then
  echo "RESULT: FAIL ($fails failure(s), $unexpected_pass unexpected pass(es))"
  exit 1
fi
echo "RESULT: PASS -- gated modules compile; quarantined modules still fail as recorded"
if [ -n "${PROOF_REPORT_DIR:-}" ]; then
  version="$(grep -oE '[0-9]+(\.[0-9]+)+' <<<"$TOOL_VERSION" | head -1 || true)"
  [ -n "$version" ] || { echo "FAIL: no version in '$TOOL_VERSION', so the receipt report cannot name the checker" >&2; exit 1; }
  [ -n "$reported" ] || { echo "FAIL: no gated module passed, so there is nothing for a receipt to record" >&2; exit 1; }
  printf '%s %s\nnone\ncheck-proofs.sh %s: RESULT: PASS%s\n' "$CMD" "$version" "$PROVER" "$reported" >"$PROOF_REPORT_DIR/$PROVER"
  echo "receipt report: $PROOF_REPORT_DIR/$PROVER"
fi
