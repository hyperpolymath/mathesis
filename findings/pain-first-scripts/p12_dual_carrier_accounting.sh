#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: format-migration churn (A2ML -> deed), two carriers of one fact.
# For each repo with a root <repo>_chora.deed: which legacy descriptile .a2ml files are still tracked while the
# deed already has the clause that supersedes them? Each such pair is one pending instance of the canon's
# three-condition deletion rule (standards .claude/CLAUDE.md, "delete what the deed already holds"), whose
# condition 1 is a fact-by-fact accounting (every fact mapped, or dropped on purpose). Counts pairs only;
# it does not compare facts (that is the experiment this probe sizes).
set -uo pipefail
EST=${EST:-/home/user/estate}; cd "$EST"
pairs=0; repos=0; both=0; declare -A per
for deed in */*/*_chora.deed; do
  d=${deed%/*}; repos=$((repos+1)); hit=0
  for kv in STATE:status META:meta ECOSYSTEM:ecosystem AGENTIC:agentic NEUROSYM:neurosym PLAYBOOK:playbook ANCHOR:anchor; do
    k=${kv%%:*}; c=${kv##*:}
    n=$(git -C "$d" ls-files -- "*${k}.a2ml" 2>/dev/null | grep -c . || true)
    [ "$n" -gt 0 ] || continue
    if grep -qE "^\s*\($c([[:space:])]|$)" "$deed"; then pairs=$((pairs+n)); per[$k]=$(( ${per[$k]:-0} + n )); hit=1; fi
  done
  [ $hit = 1 ] && both=$((both+1))
done
echo "repos with a root chora deed: $repos; of those still tracking a legacy descriptile whose clause the deed has: $both"
echo "legacy-file / deed-clause pairs awaiting fact accounting: $pairs"; for k in "${!per[@]}"; do echo "  $k.a2ml: ${per[$k]}"; done
echo "all tracked .a2ml in repos WITH a chora deed: $(for deed in */*/*_chora.deed; do git -C "${deed%/*}" ls-files -- '*.a2ml' 2>/dev/null; done | wc -l)"
