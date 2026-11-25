#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only, FLAG-ONLY probe (2026-11-24). Pain class: licence/SPDX metadata drift.
# Nothing here says which licence is right for a repo (owner-only decision; estate policy forbids automated
# licence edits). It only asks whether the carriers of the SAME fact inside one repo agree with each other:
#   L = licence named by the root LICENSE text      S = modal SPDX-License-Identifier in tracked files
#   C = root Cargo.toml license =                   G = guix.scm (license ...)
# Third-party forks are listed, not excluded; they must never be edited. Heuristic text matching.
set -uo pipefail
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/p10}; mkdir -p "$OUT"; cd "$EST"
norm() { tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9.+-]//g'; }
: > "$OUT/rows.tsv"
while read -r repo _; do
  d="$EST/$repo"; L=-; S=-; C=-; G=-
  if [ -f "$d/LICENSE" ]; then h=$(head -c 1500 "$d/LICENSE" | tr 'A-Z' 'a-z')
    case "$h" in *"mozilla public license"*"2.0"*) L=mpl-2.0;; *palimpsest*) L=pmpl;; *"gnu affero"*) L=agpl-3.0;; *"gnu general public license"*) L=gpl;;
      *"mit license"*|*"permission is hereby granted, free of charge"*) L=mit;; *"apache license"*) L=apache-2.0;; *"creative commons"*) L=cc;; *"all rights reserved"*) L=arr;; *) L=other;; esac; fi
  S=$(git -C "$d" grep -h -I -o -E 'SPDX-License-Identifier: *[A-Za-z0-9.+ ()-]+' -- . ':!LICENSES' ':!LICENSE*' ':!*.lock' 2>/dev/null | sed -E 's/SPDX-License-Identifier: *//; s/ +$//' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn | head -1 | sed -E 's/^ *[0-9]+ //')
  [ -n "$S" ] || S=-
  [ -f "$d/Cargo.toml" ] && C=$(grep -m1 -E '^license *= *"' "$d/Cargo.toml" | sed -E 's/^license *= *"([^"]*)".*/\1/' | tr 'A-Z' 'a-z'); [ -n "$C" ] || C=-
  [ -f "$d/guix.scm" ] && G=$(grep -m1 -A3 -E "\\(license" "$d/guix.scm" | tr "A-Z\n" "a-z " | grep -oE "\"(mpl-2\\.0|pmpl[^\"]*|agpl[^\"]*|mit|apache[^\"]*)\"|agpl3\\+?|mpl2\\.0|gpl3\\+?|expat|asl2\\.0|#f" | head -1 | tr -d "\""); case "$G" in mpl2.0) G=mpl-2.0;; agpl3*) G=agpl-3.0;; expat) G=mit;; asl2.0) G=apache-2.0;; "#f"|"") G=-;; esac   # the quoted licence NAME is read first: a first version matched "palimpsest" inside the licence URL and reported 26 false disagreements
  printf '%s\t%s\t%s\t%s\t%s\n' "$repo" "$L" "$S" "$C" "$G" >> "$OUT/rows.tsv"
done < "$EST/.stats.tsv"
perl -F'\t' -lane '
  sub fam { my $x=shift; return "-" if $x eq "-"; return "mpl-2.0" if $x =~ /mpl-?2/ && $x !~ /pmpl/; return "pmpl" if $x =~ /pmpl|palimpsest/; return "agpl" if $x =~ /agpl/;
            return "gpl" if $x =~ /gpl/; return "mit" if $x =~ /\bmit\b|expat/; return "apache" if $x =~ /apache|asl2/; return "cc" if $x =~ /^cc/; return $x }
  my ($r,@c)=@F; my %f; my @named; for my $i (0..3){ my $v=fam($c[$i]); next if $v eq "-" || $v eq "other"; $f{$v}++; push @named,(qw(LICENSE SPDX Cargo guix))[$i]."=".$v }
  $n++; $with++ if @named>=2; if (@named>=2 && keys(%f)>1){ $dis++; push @ex,"$r\t@named" } $single++ if @named>=2 && keys(%f)==1;
  END { printf "repos: %d; with >=2 readable licence carriers: %d; carriers agree: %d; carriers DISAGREE: %d\n",$n,$with,$single,$dis; print for @ex[0..24] }' "$OUT/rows.tsv"
