#!/usr/bin/perl
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: CI cost (every job re-run on every push).
# Input: /tmp/ct/names.txt from Phase A (commit-taxonomy-scripts/names.sh): HEAD, non-merge, name-only.
# Each commit is classified by the SUPPORT it touches. A job whose declared inputs are disjoint from the
# commit's support has the same task key as on the parent commit: under hermeticity its run is a provable
# repeat (survives-retraction with support ⊆ kept context; Build Systems a la Carte minimality).
# Classes are by path only; the mapping from class to "which jobs may skip" is the experiment, not this probe.
use strict; use warnings;
my (%n,$tot,$cur,%set); my $third=0;
sub flush { return unless defined $cur; my @k=sort keys %set; return unless @k; $tot++; my $c = @k==1 ? "only: $k[0]" : (grep { $_ eq "code/other" } @k) ? "touches code/other" : "non-code mix (".join("+",@k).")"; $n{$c}++; %set=(); }
open my $f,"<","/tmp/ct/names.txt" or die;
while(<$f>){ chomp;
  if (/^@@\t([^\t]+)\t/) { flush(); $cur = ($1 eq "hyperpolymath/explore") ? undef : $1; %set=(); next }
  next unless defined $cur; next if $_ eq "";
  my $p=$_; my $c;
  if    ($p =~ m{^\.github/workflows/actions\.lock$|(^|/)(Cargo\.lock|mix\.lock|bun\.lock|deno\.lock|pnpm-lock\.yaml|Manifest\.toml|flake\.lock)$}) { $c="lockfile" }
  elsif ($p =~ m{^\.github/})                                         { $c="ci-config" }
  elsif ($p =~ m{\.(adoc|md|txt)$|^docs/|(^|/)(LICENSE|LICENSES/)})   { $c="prose/licence" }
  elsif ($p =~ m{^\.machine_readable/|_chora\.deed$|\.a2ml$|\.deed$|(^|/)(CODEOWNERS|\.gitignore|\.gitattributes|\.editorconfig)$}) { $c="metadata" }
  else { $c="code/other" }
  $set{$c}=1; }
flush();
printf "HEAD non-merge commits with a file list (explore excluded): %d\n", $tot;
printf "  %6d  %5.1f%%  %s\n", $n{$_}, 100*$n{$_}/$tot, $_ for sort { $n{$b} <=> $n{$a} } keys %n;
my $nc=0; $nc += $n{$_} for grep { $_ !~ m{code/other} } keys %n;   # first run summed "only: code/other" in by mistake
printf "commits whose support contains NO code/other path: %d of %d\n", $nc, $tot;
