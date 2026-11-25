#!/usr/bin/perl
use strict; use warnings;
my $root="/home/user/estate"; my %files; my %res; my %tot; my %still; my @ex;
open(my $in,"<","unresolved.tsv") or die;
while(<$in>){ chomp; my($repo,$doc,$t)=split /\t/;
  $tot{$doc}++;
  unless($files{$repo}){ my @l=`git -C $root/$repo ls-files 2>/dev/null`; chomp @l; $files{$repo}=\@l; }
  my $hit=0; for my $f (@{$files{$repo}}){ if(length($f)>=length($t) && substr($f,-length($t)) eq $t && (length($f)==length($t) || substr($f,-length($t)-1,1) eq '/')){ $hit=1; last; } }
  if($hit){ $res{$doc}++; } else { $still{$doc}++; push @ex,"$repo\t$doc\t$t"; }
}
for my $d (sort keys %tot){ printf "%-32s unresolved-exact=%4d suffix-resolved=%4d still-unresolved=%4d\n",$d,$tot{$d},$res{$d}//0,$still{$d}//0; }
open(my $o,">","still.tsv"); print $o "$_\n" for @ex; close $o;
my %r; $r{(split /\t/)[0]}++ for @ex; printf "repos with still-unresolved: %d; total still: %d\n", scalar keys %r, scalar @ex;
