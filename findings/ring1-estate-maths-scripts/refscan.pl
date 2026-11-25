#!/usr/bin/perl
# Heuristic baseline: backticked repo-relative path citations in agent/status docs that do not resolve.
use strict; use warnings;
my $root = "/home/user/estate";
my @docs = ("CLAUDE.md", "README.adoc", "EXPLAINME.adoc", "docs/status/PROOF-STATUS.adoc", "PROOF-STATUS.adoc", "PROOF-NEEDS.adoc");
my $extre = qr/\.(adoc|md|sh|idr|agda|lean|v|rs|ex|exs|jl|zig|ncl|deed|json|jsonl|toml|yml|yaml|js|mjs|just|scm|k9|tla|thy|hs|ml|affine|txt|lock|ipkg|cfg|pl|rb|a2ml)$/;
my %tot; my %unres; my %repo_unres; my @examples;
opendir(my $dh, $root) or die;
for my $owner (grep { !/^\./ && -d "$root/$_" } readdir $dh) {
  opendir(my $rh, "$root/$owner") or next;
  for my $repo (grep { !/^\./ && -d "$root/$owner/$_" } readdir $rh) {
    my $rr = "$root/$owner/$repo";
    for my $d (@docs) {
      my $f = "$rr/$d"; next unless -f $f;
      open(my $fh, "<", $f) or next; local $/; my $txt = <$fh>; close $fh;
      my %seen;
      while ($txt =~ /`([^`\s]{3,200})`/g) {
        my $t = $1;
        $t =~ s/[#:].*$//;            # drop anchors / line numbers
        next unless $t =~ m{^[A-Za-z0-9_.\-/]+$};
        next unless $t =~ m{/};
        next if $t =~ m{^/} || $t =~ /\.\./ || $t =~ m{^(http|www)};
        next unless $t =~ $extre;
        next if $seen{$t}++;
        $tot{$d}++;
        next if -e "$rr/$t";
        # cross-repo: standards canon or sibling repo prefix
        my $ok = 0;
        $ok = 1 if -e "/home/user/standards/$t";
        if (!$ok && $t =~ m{^([^/]+)/(.+)$}) { my ($h,$rest)=($1,$2);
          for my $o (qw(hyperpolymath metadatastician catachresis-colloquium stuff-of-awe)) { $ok = 1 if -e "$root/$o/$h/$rest"; }
          if (!$ok && $rest =~ m{^([^/]+)/(.+)$}) { $ok = 1 if -e "$root/$h/$1/$2"; }
        }
        next if $ok;
        $unres{$d}++; $repo_unres{"$owner/$repo"}{$d}++;
        push @examples, "$owner/$repo\t$d\t$t" if @examples < 4000;
      }
    }
  }
}
for my $d (@docs) { printf "%-32s path-citations=%6d unresolved=%6d\n", $d, $tot{$d}//0, $unres{$d}//0; }
printf "repos with >=1 unresolved: %d\n", scalar keys %repo_unres;
open(my $o, ">", "unresolved.tsv"); print $o "$_\n" for @examples; close $o;
