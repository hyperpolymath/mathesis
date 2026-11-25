#!/usr/bin/perl
# classify each commit by the set of path classes it touches (footprint), to size what content-keyed CI could skip
use strict; no warnings;
my ($repo,$hash,$auth,$n); my %cls; my %tot; my $commits=0; my $skipexplore=0;
sub flush {
  return unless defined $hash;
  return if $repo eq 'hyperpolymath/explore';
  return if $n==0;
  $commits++;
  my @k = sort keys %cls;
  my $key = join('+',@k);
  $tot{$key}++;
  $tot{'_bot'}++ if $auth =~ /dependabot/;
}
while(<>){ chomp; my @f=split /\t/;
  if($f[0] eq 'C'){ flush(); ($repo,$hash,$auth)=($f[1],$f[2],$f[4]); %cls=(); $n=0; }
  elsif($f[0] eq "F"){ my $p=$f[2]; next unless defined $p; $n++;
    my $c;
    if($p =~ m{^\.github/workflows/} ){ $c='workflow'; }
    elsif($p =~ m{^\.github/} ){ $c='github-meta'; }
    elsif($p =~ m{(^|/)(LICENSE|LICENSES|NOTICE|COPYING)} ){ $c='licence'; }
    elsif($p =~ m{^\.machine_readable/} || $p =~ m{_chora\.deed$} || $p =~ m{\.a2ml$} || $p =~ m{\.deed$}){ $c='metadata'; }
    elsif($p =~ m{\.(adoc|md|txt|rst)$}i || $p =~ m{^docs/} ){ $c='docs'; }
    elsif($p =~ m{(^|/)(Cargo\.lock|mix\.lock|bun\.lock|deno\.lock|pnpm-lock\.yaml|package-lock\.json|Manifest\.toml|flake\.lock|go\.sum|mise\.lock)$}){ $c='lockfile'; }
    else { $c='code-or-config'; }
    $cls{$c}=1;
  }
}
flush();
print "commits (non-merge, excl. explore, with files): $commits\n";
for my $k (sort { $tot{$b} <=> $tot{$a} } keys %tot){ printf "%7d  %5.1f%%  %s\n", $tot{$k}, 100*$tot{$k}/$commits, $k; }
