use strict; use warnings;
my (%hist,%tpath);
open my $h,'<','t_hist.tsv'; while(<$h>){chomp;my($b,$p)=split /\t/;$hist{$p}{$b}=1;$tpath{$p}=1}
my %subj; open my $f,'<','fan_commits.tsv'; while(<$f>){chomp;my($r,$hsh,$np,$n)=split /\t/;$subj{"$r\t$hsh"}=$n}
my (%nb,%cnt,%tot,%paths);
open my $in,'<','fan_raw.tsv';
while(<$in>){chomp;my($r,$cm,$old,$new,$st,$p)=split /\t/; next unless $tpath{$p}; next if $hist{$p}{$new}; next if $st eq 'D';
  my $s=$subj{"$r\t$cm"}; $nb{$s}{$p}{$new}++; $cnt{$s}{$p}++; $tot{$s}++; }
# global: file writes (template path, new blob not a template version): how many are a blob written identically to >=5 repos' same path in same subject?
my ($all,$uniform,$unique)=(0,0,0);
for my $s(keys %nb){ for my $p(keys %{$nb{$s}}){ for my $b(keys %{$nb{$s}{$p}}){ my $n=$nb{$s}{$p}{$b}; $all+=$n; $uniform+=$n if $n>=5; $unique+=$n if $n==1; } } }
printf "non-template-version writes on template paths: %d; blob shared by >=5 repos in the same sweep: %d; blob written to exactly one repo: %d\n",$all,$uniform,$unique;
print "\nsubject | path | writes | distinct new blobs | top blob count\n";
my $i=0; for my $s(sort{$tot{$b}<=>$tot{$a}}keys %tot){ last if ++$i>22; my ($p)=sort{$cnt{$s}{$b}<=>$cnt{$s}{$a}}keys %{$cnt{$s}}; my @b=sort{$b<=>$a}values %{$nb{$s}{$p}}; printf "%-58s | %-45s | %4d | %4d | %4d\n",substr($s,0,58),substr($p,0,45),$cnt{$s}{$p},scalar(@b),$b[0]; }
