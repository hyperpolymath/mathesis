#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -uo pipefail
M=${MATHESIS_DATA:?set MATHESIS_DATA to the census work directory}
cd "$M" || exit 1
cat_sorted() { find out -name "*.$1.jsonl" -print0 | sort -z | xargs -0 cat 2>/dev/null | jq -cS . ; }
cat_sorted files > files.jsonl
cat_sorted decls > decls.jsonl
cat_sorted holes > holes.jsonl
cat_sorted agdaopts > agda-options.jsonl
cat_sorted status > repos-with-status.jsonl
cat_sorted unreach > unreachable.jsonl

PROVER='def prover: (.ext) as $e |
  if ($e|test("^(agda|lagda|lagda.md|agda-lib)$")) then "agda"
  elif ($e|test("^(idr|lidr|ipkg)$")) then "idris2"
  elif ($e|test("^(lean|lean-toolchain|.lean-toolchain|lakefile.lean|lakefile.toml)$")) then "lean"
  elif ($e|test("^(v|_CoqProject)$")) then "rocq"
  elif $e=="thy" then "isabelle"
  elif ($e|test("^(tla|cfg)$")) then "tla"
  elif $e=="dk" then "dedukti" elif $e=="lp" then "lambdapi"
  elif $e=="smt2" then "smtlib" elif ($e|test("^(tptp|p)$")) then "tptp"
  elif ($e|test("^(ads|adb|gpr)$")) then "spark" elif $e=="mlw" then "why3"
  elif $e=="fst" then "fstar" elif $e=="dfy" then "dafny" elif $e=="als" then "alloy" else $e end;'
CORPUS_RE='(^|/)(tests?|fixtures?|test-fixtures|testdata|test-data|examples?|benchmarks?|benches|bench|corpus|corpora|samples?|external_corpora|third_party|vendor|training_data)(/|$)'

total=$(wc -l < repos.jsonl)
forks=$(jq -s '[.[]|select(.fork)]|length' repos.jsonl)
awesome=$(jq -s '[.[]|select((.fork|not) and (.full_name|test("/awesome-")))]|length' repos.jsonl)
census=$(wc -l < census-list.txt)
unreach=$(wc -l < unreachable.jsonl)
witha=$(jq -rs '[.[].repo]|unique|length' files.jsonl)
nfiles=$(wc -l < files.jsonl); ndecls=$(wc -l < decls.jsonl)

{
echo "# Maths census: proof and formal-verification artefacts"
echo
echo "Generated $(date -u +%Y-%m-%dT%H:%MZ) from blobless shallow clones of each repo's default branch HEAD."
echo
echo "## Totals"
echo
echo "| measure | count |"
echo "|---|---|"
echo "| repos enumerated (hyperpolymath, metadatastician, catachresis-colloquium, stuff-of-awe) | $total |"
echo "| forks skipped | $forks |"
echo "| awesome-* list repos skipped | $awesome |"
echo "| repos in census | $census |"
echo "| unreachable (clone failed) | $unreach |"
echo "| repos with any proof artefact | $witha |"
echo "| proof artefact files | $nfiles |"
echo "| declarations extracted | $ndecls |"
echo "| hole-scanner findings | $(wc -l < holes.jsonl) |"
echo
echo "Hole classes (from proof-holes.sh): hole = unfinished proof, axiom = trusted base grows, unsafe = checker switched off, policy = estate rule (Agda without --safe, import Mathlib)."
echo
echo "## Repos with artefacts (sorted by declarations)"
echo
echo "| repo | provers (files) | decls | holes | axioms | unsafe | policy | Agda --safe / without | proof-status doc |"
echo "|---|---|---|---|---|---|---|---|---|"
jq -rn --slurpfile F files.jsonl --slurpfile D decls.jsonl --slurpfile H holes.jsonl --slurpfile A agda-options.jsonl --slurpfile S repos-with-status.jsonl "$PROVER"'
  ($F|map(.repo)|unique) as $repos
  | [ $repos[] as $r |
      { r:$r,
        p: ([$F[]|select(.repo==$r)|prover]|group_by(.)|map("\(.[0]) \(length)")|join(", ")),
        d: ([$D[]|select(.repo==$r)]|length),
        h: ([$H[]|select(.repo==$r and .class=="hole")]|length),
        a: ([$H[]|select(.repo==$r and .class=="axiom")]|length),
        u: ([$H[]|select(.repo==$r and .class=="unsafe")]|length),
        po: ([$H[]|select(.repo==$r and .class=="policy")]|length),
        as: ([$A[]|select(.repo==$r and has("options") and .safe)]|length),
        an: ([$A[]|select(.repo==$r and has("options") and (.safe|not))]|length),
        s: ([$S[]|select(.repo==$r)|.path]|join("<br>")) } ]
  | sort_by(-.d, .r)[]
  | "| \(.r) | \(.p) | \(.d) | \(.h) | \(.a) | \(.u) | \(.po) | \(if (.as+.an)>0 then "\(.as) / \(.an)" else "" end) | \(.s) |"'
echo
echo "## Possible test corpora rather than obligations"
echo
echo "Repos where artefact paths sit under tests/, fixtures/, examples/, benchmarks/, corpus/, vendor/ and similar, plus echidna's proofs/<prover>/ tree (prover test corpus). Flagged, not dropped; the counts above still include them."
echo
echo "| repo | files under corpus-like paths / all artefact files | sample prefixes |"
echo "|---|---|---|"
jq -rn --slurpfile F files.jsonl --arg re "$CORPUS_RE" '
  ($F|map(.repo)|unique)[] as $r
  | [$F[]|select(.repo==$r)] as $fs
  | [$fs[]|select((.path|test($re)) or ($r=="hyperpolymath/echidna" and (.path|test("^proofs/[^/]+/"))))] as $c
  | select(($c|length)>0)
  | ($c|map(.path|split("/")|.[0:2]|join("/"))|group_by(.)|map("\(.[0]) (\(length))")|sort_by(.)|.[0:6]|join("; ")) as $pre
  | "| \($r) | \($c|length) / \($fs|length) | \($pre) |"'
echo
echo "## Proof-status documents"
echo
jq -r '"- \(.repo): `\(.path)`"' repos-with-status.jsonl
echo
echo "## Unreachable"
echo
jq -r '"- \(.repo): \(.error)"' unreachable.jsonl
echo
echo "## Method and caveats"
echo
echo "- Enumeration used the session's list_repos tool (per-letter substring queries). Every repo it returned has pushed_at on or after 2026-09-15, so repos untouched since then may be missing from the listing."
echo "- Declarations are grep/awk best effort. Agda and Idris2 count every column-0 \`name : type\` signature (helpers included), plus data/record names and postulated names; Lean/Rocq/Isabelle use keyword rules; TLA+ counts THEOREM/LEMMA and .cfg INVARIANT/PROPERTY names. SMT-LIB, TPTP, Dafny, F*, Why3, Alloy and SPARK files are counted as files only."
echo "- .v files count only in repos with Rocq signs (_CoqProject, dune with coq, or a .v containing Require/Theorem); Verilog-looking files are skipped. .p counts only with TPTP formulas, .lp only with Lambdapi keywords, .ads/.adb only when the repo has a .gpr or SPARK_Mode."
echo "- Hole counts are textual (proof-holes.sh); a kernel-level audit is the authority."
} > summary.md
