#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: sweep amplification / unstaged change rollout.
# A "sweep" = one normalised commit subject (PR numbers and hex ids stripped) landing in >=20 repos.
# For each sweep: how many repos, and how much of the fleet had already received it 1 h / 24 h after the
# FIRST repo did (committer time, default-branch history, non-merge). A staged rollout would show a small
# canary share at 1 h and 24 h; a flat "everything at once" sweep shows most of the fleet inside the window,
# i.e. no time in which the platform's verdict on the canary could have stopped the rest.
set -uo pipefail
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/p9}; mkdir -p "$OUT"; cd "$EST"
: > "$OUT/log.tsv"
while read -r repo _; do
  [ "$repo" = "hyperpolymath/explore" ] && continue     # third-party fork history
  git -C "$EST/$repo" log HEAD --no-merges --format="$repo%x09%ct%x09%s" 2>/dev/null >> "$OUT/log.tsv"
done < "$EST/.stats.tsv"
perl -F'\t' -lane '
  my ($r,$t,$s)=@F; next if $s =~ /^(chore\(deps\)|build\(deps\)|Bump |chore\(ci\)\(deps\))/i;   # dependabot-style bumps are not sweeps
  $s =~ s/\s*\(#\d+\)//g; $s =~ s/#\d+//g; $s =~ s/\b[0-9a-f]{7,40}\b/H/g; $s =~ s/\d+/N/g; $s = lc $s;
  $first{$s}{$r} = $t if !exists $first{$s}{$r} || $t < $first{$s}{$r};
  END {
    my (@rows,$n,$h1,$h24,$big,$bigh24); 
    for my $s (keys %first){ my @ts = sort { $a <=> $b } values %{$first{$s}}; my $k=@ts; next if $k<20;
      my $t0=$ts[0]; my $a=grep { $_-$t0 <= 3600 } @ts; my $b=grep { $_-$t0 <= 86400 } @ts;
      push @rows,[$k,$a,$b,($ts[-1]-$t0)/86400,$s]; $n++; $h1++ if $a/$k>=0.5; $h24++ if $b/$k>=0.5; }
    printf "sweeps (subject in >=20 repos, bumps excluded): %d\n", $n;
    printf "  >=50%% of the sweep'"'"'s repos reached within 1 h of the first: %d\n  >=50%% reached within 24 h: %d\n", $h1,$h24;
    my $tot=0; my $in24=0; for my $r (@rows){ $tot+=$r->[0]; $in24+=$r->[2] } printf "  repo-landings: %d; within 24 h of the sweep'"'"'s first landing: %d\n", $tot,$in24;
    print "repos\twithin_1h\twithin_24h\tspan_days\tsubject";
    printf "%d\t%d\t%d\t%.1f\t%s\n", @$_ for (sort { $b->[0] <=> $a->[0] } @rows)[0..39];
  }' "$OUT/log.tsv" > "$OUT/result.tsv"
sed -n 1,4p "$OUT/result.tsv"
