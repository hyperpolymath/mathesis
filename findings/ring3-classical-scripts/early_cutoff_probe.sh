#!/usr/bin/env bash
# Read-only probe for Ring 3 candidate "CI as a build system".
# For each repo that carries .github/workflows/rust-ci.yml: over first-parent commits on HEAD since
# 2026-01-01, how many change at least one declared input of the Rust CI task?
# Declared input set (an assumption, stated): *.rs, Cargo.toml, Cargo.lock, rust-toolchain*, .cargo/*,
# build.rs, and the workflow file itself plus actions.lock.
# A commit that changes none of them has the same task key as its parent: under hermeticity the run is a
# provable repeat (Build Systems a la Carte, minimality).
# Usage: bash early_cutoff_probe.sh   (run from /home/user/estate)
set -euo pipefail
tot=0; hit=0; repos=0
for wf in */*/.github/workflows/rust-ci.yml; do
  r=${wf%%/.github/*}
  [ "$r" = "hyperpolymath/explore" ] && continue
  out=$(git -C "$r" log --first-parent --no-merges --since=2026-01-01 --format='@@%h' --name-only 2>/dev/null | awk '
    /^@@/ { if (seen) { n++; if (touch) t++ } seen=1; touch=0; next }
    /^$/ { next }
    { if ($0 ~ /\.rs$/ || $0 ~ /(^|\/)Cargo\.(toml|lock)$/ || $0 ~ /rust-toolchain/ || $0 ~ /(^|\/)\.cargo\// || $0 ~ /^\.github\/workflows\/(rust-ci\.yml|actions\.lock)$/) touch=1 }
    END { if (seen) { n++; if (touch) t++ } printf "%d %d\n", n+0, t+0 }')
  n=${out% *}; t=${out#* }
  tot=$((tot+n)); hit=$((hit+t)); repos=$((repos+1))
  printf '%s\t%s\t%s\n' "$r" "$n" "$t"
done > "${1:-/dev/stdout}.rows" 2>/dev/null || true
echo "repos with rust-ci.yml: $repos"
echo "first-parent non-merge commits since 2026-01-01: $tot"
echo "commits changing a declared Rust CI input: $hit"
echo "commits whose Rust CI task key equals the parent's: $((tot-hit))"
