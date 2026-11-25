use strict; use warnings;
# reproduce fan-out set: fix/revert-worded commits whose normalised subject occurs in >=8 repos
my (%repos,%rows);
open my $in,'<','/tmp/ct/classified.tsv' or die; <$in>;
while(<$in>){chomp;my($r,$h,$np,$c,$t,$p,$s)=split /\t/,$_,7;
 my %h=map{$_=>1}split /,/,$t; next unless $h{fix}||$h{revert};
 my $n=lc $s; $n=~s/^(\w+)(\([^)]*\))?!?:\s*/$1: /; $n=~s/\(#\d+\)//g; $n=~s/[0-9a-f]{7,40}/H/g; $n=~s/\d+(\.\d+)*/N/g; $n=~s/\s+/ /g; $n=substr($n,0,70);
 $repos{$n}{$r}=1; push @{$rows{$n}},"$r\t$h\t$np";
}
my ($subj,$cnt)=(0,0);
open my $o,'>','fan_commits.tsv';
for my $n(keys %repos){ next if scalar(keys %{$repos{$n}})<8; $subj++; for(@{$rows{$n}}){$cnt++; print $o "$_\t$n\n"} }
print "subjects>=8 repos: $subj; commits: $cnt\n";
