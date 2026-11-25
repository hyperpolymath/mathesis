#!/usr/bin/perl
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: template residue counted as content (stub proofs, placeholders).
# Inputs: /tmp/pf/p1/children.tsv and template_hist.tsv (written by p1_template_ancestor_identity.sh).
# For each repo: proof-language files at HEAD (.agda .lean .v .idr .tla .thy; reject/fixture/vendor dirs
# skipped) and how many are byte-identical (git blob id) to some version of a file in rsr-template-repo
# history. A repo whose proof files are all template-identical has no proof content of its own.
# NOT a claim of census inflation: mathesis scripts/census/build-rows.sh already drops a file whose
# (path, blob) is in template-blobs.tsv, so its own_files exclude these. This probe sizes what any OTHER
# reader (a README badge, a file-count, an agent listing "proofs") would wrongly count. Blob ids only.
use strict; use warnings;
my $P="/tmp/pf/p1"; my %tblob;
open my $h,"<","$P/template_hist.tsv" or die; while(<$h>){ chomp; my($b,$p)=split /\t/; $tblob{$b}=1 }
my (%tot,%stub);
open my $c,"<","$P/children.tsv" or die;
while(<$c>){ chomp; my($r,$b,$p)=split /\t/;
  next unless $p =~ /\.(agda|lean|v|idr|tla|thy)$/; next if $p =~ m{(^|/)(tests?/reject|fixtures?|vendor|node_modules|deps|\.lake|9-archive|corpus)(/|$)}i;
  $tot{$r}++; $stub{$r}++ if $tblob{$b}; }
my ($repos,$all,$some,$files,$stubs)=(0,0,0,0,0);
for my $r (keys %tot){ $repos++; $files+=$tot{$r}; my $s=$stub{$r}//0; $stubs+=$s; $all++ if $s==$tot{$r}; $some++ if $s>0 && $s<$tot{$r}; }
printf "repos with proof-language files at HEAD: %d; files: %d; byte-identical to a template version: %d\n", $repos,$files,$stubs;
printf "  repos where EVERY proof-language file is a template copy: %d\n  repos with some template copies beside own files: %d\n", $all,$some;
