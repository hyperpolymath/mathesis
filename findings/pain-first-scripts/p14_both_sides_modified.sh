#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: merge conflicts and concurrent-writer clashes.
# For every two-parent merge commit on the default-branch history of every clone (third-party fork
# hyperpolymath/explore excluded): which files were modified on BOTH sides since the merge base? Those are the
# only files where a three-way merge had to do real work (a textual conflict is a subset). Classified by
# whether the file has a grammar a value-level merge could use. Tree objects only (--name-only --no-renames).
set -uo pipefail
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/p14}; mkdir -p "$OUT"; cd "$EST"
: > "$OUT/both.tsv"; merges=0; contested=0
while read -r repo _; do
  [ "$repo" = "hyperpolymath/explore" ] && continue
  d="$EST/$repo"
  while read -r m p1 p2 rest; do
    [ -n "${p2:-}" ] && [ -z "${rest:-}" ] || continue
    merges=$((merges+1))
    b=$(git -C "$d" merge-base "$p1" "$p2" 2>/dev/null) || continue
    [ "$b" = "$p1" ] || [ "$b" = "$p2" ] && continue                      # fast-forwardable: no real three-way merge
    f=$(comm -12 <(git -C "$d" diff --name-only --no-renames "$b" "$p1" 2>/dev/null | sort) <(git -C "$d" diff --name-only --no-renames "$b" "$p2" 2>/dev/null | sort))
    [ -n "$f" ] || continue
    contested=$((contested+1)); printf '%s\n' "$f" | sed "s|^|$repo\t$m\t|" >> "$OUT/both.tsv"
  done < <(git -C "$d" log HEAD --merges --format='%H %P' 2>/dev/null)
done < "$EST/.stats.tsv"
echo "two-parent merges on default-branch history (explore excluded): $merges"
echo "merges with at least one file modified on both sides: $contested"
perl -F'\t' -lane '
  my $f=$F[2]; my $c;
  if    ($f =~ m{(^|/)actions\.lock$|\.lock$|(^|/)(Cargo\.lock|mix\.lock|bun\.lock|deno\.lock|Manifest\.toml|pnpm-lock\.yaml)$}) { $c="lockfile (derived artefact)" }
  elsif ($f =~ m{^\.github/workflows/.*\.ya?ml$})                { $c="workflow YAML" }
  elsif ($f =~ m{\.(json|jsonl|toml|deed|a2ml|kyaml|ya?ml|ncl|scm|k9)$}) { $c="other structured data/config" }
  elsif ($f =~ m{\.(adoc|md|txt)$|(^|/)(LICENSE|README)})      { $c="prose" }
  elsif ($f =~ m{(^|/)(Justfile|justfile|Mustfile|\.gitignore|\.gitattributes|CODEOWNERS)$}) { $c="line-oriented config (no value grammar)" }
  else { $c="source code / other" }
  $n{$c}++; $t++; $top{$f}++;
  END { printf "both-sides-modified file instances: %d\n", $t; printf "  %6d  %s\n", $n{$_}, $_ for sort { $n{$b} <=> $n{$a} } keys %n;
        print "-- most contested paths"; my $i=0; for (sort { $top{$b} <=> $top{$a} } keys %top){ printf "  %5d  %s\n", $top{$_}, $_; last if ++$i>=15 } }' "$OUT/both.tsv"
