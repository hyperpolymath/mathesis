#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: overclaim (status/proof claims beyond evidence).
# Per repo: does README/EXPLAINME claim machine verification, and is there (a) a workflow line that RUNS a
# prover or a proof gate (tight pattern; a looser word match hit 413 of 484 repos because template workflows
# merely name provers, so it was discarded), (b) a proof-receipt deed (verification/receipts/*_praxis.deed)?
# "claim, no prover-running workflow, no receipt" is the proof-claim-without-prover class named in
# proven-tests-and-benches corpus/provenance/reflexive/. Text heuristics: a hit is "the README says so"
# (negated or caveated sentences also match), so counts are upper bounds, not verified overclaims.
set -uo pipefail
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/p8}; mkdir -p "$OUT"; cd "$EST"
CLAIM='formally verified|machine[- ]checked|mechanically (verified|checked)|SPARK[- ]{1,2}proved|proved in (Agda|Coq|Rocq|Lean|Idris)|proofs? (are|is) (machine|kernel)[- ]checked|verified with (SPARK|Creusot|Verus|Agda|Coq|Lean|Idris)'
RUNS='^[[:space:]]*(-[[:space:]]+)?(run:[[:space:]]*)?(agda|idris2|lake|lean|coqc|coqchk|rocq|gnatprove|cargo[[:space:]]+creusot|verus|isabelle|tlc|just[[:space:]]+(proofs?|check-proofs|verify))([[:space:]]|$)|scripts/check-proofs\.sh|check-agda\.sh|proof-receipt\.sh|creusot-check|verus-check|spark-check|idris2-abi-check|proof-runner-check'
: > "$OUT/rows.tsv"
while read -r repo _; do
  d="$EST/$repo"
  claim=0; for f in README.adoc README.md EXPLAINME.adoc; do [ -f "$d/$f" ] && grep -Eqi "$CLAIM" "$d/$f" && claim=1; done
  ci=0; ls "$d"/.github/workflows/*.y*ml >/dev/null 2>&1 && grep -Eqi "$RUNS" "$d"/.github/workflows/*.y*ml 2>/dev/null && ci=1
  rc=0; ls "$d"/verification/receipts/*_praxis.deed >/dev/null 2>&1 && rc=1
  printf '%s\t%s\t%s\t%s\n' "$repo" "$claim" "$ci" "$rc" >> "$OUT/rows.tsv"
done < "$EST/.stats.tsv"
awk -F'\t' '{n++; if($3) allci++; if($4) allrc++; if($2){c++; if($3) ci++; if($4) rc++; if(!$3 && !$4) bare++; if($3 && !$4) cinorc++}}
 END{printf "repos %d; repos whose workflows run a prover (tight pattern): %d; repos with a proof-receipt deed: %d\nclaiming repos: %d; prover run in CI: %d; receipt deed: %d; prover in CI but no receipt: %d; neither: %d\n", n, allci, allrc, c, ci, rc, cinorc, bare}' "$OUT/rows.tsv"
