use strict; use warnings;
my (%tag,%cls,%cx,%fixtag,%fixcls,%ex,%prim,%primfix,%exprim,%repo_fix,%repo_tot,%norm,%normex,%normcls,%nmerge);
my $N=0;
open my $in,'<','classified.tsv'; <$in>;
while(<$in>){chomp;my($r,$h,$np,$c,$t,$p,$s)=split /\t/,$_,7;$N++;
 $cls{$c}++; $repo_tot{$r}++; $nmerge{merge}++ if $np>1;
 my @t=split /,/,$t; my %h=map{$_=>1}@t; my $isfix=($h{fix}||$h{revert})?1:0;
 $prim{$p}++; $primfix{$p}++ if $isfix; push @{$exprim{$p}},substr($h,0,9)." ".$r if @{$exprim{$p}||[]}<3;
 $fixcls{$c}++ if $isfix; $repo_fix{$r}++ if $isfix;
 for my $x(@t){ $tag{$x}++; $cx{$x}{$c}++; if($isfix){$fixtag{$x}++} push @{$ex{$x}},substr($h,0,9)." ".$r." | ".substr($s,0,90) if @{$ex{$x}||[]}<3; }
 if($isfix){ my $n=lc $s; $n=~s/^(\w+)(\([^)]*\))?!?:\s*/$1: /; $n=~s/\(#\d+\)//g; $n=~s/[0-9a-f]{7,40}/H/g; $n=~s/\d+(\.\d+)*/N/g; $n=~s/\s+/ /g; $n=substr($n,0,70); $norm{$n}++; push @{$normex{$n}},substr($h,0,9) if @{$normex{$n}||[]}<2; $normcls{$n}{$c}++}
}
print "TOTAL commits (all refs): $N\n";
print "merge commits: $nmerge{merge}\n";
print "\n## per author class (total, fix|revert-worded, share)\n";
for my $c(sort{$cls{$b}<=>$cls{$a}}keys %cls){printf "%-30s %6d  fix/revert %5d  (%.1f%%)\n",$c,$cls{$c},$fixcls{$c}||0,100*($fixcls{$c}||0)/$cls{$c}}
print "\n## tags: total, fix/revert-worded subset; examples\n";
for my $x(sort{$tag{$b}<=>$tag{$a}}keys %tag){printf "%-14s %6d  in-fix %5d\n",$x,$tag{$x},$fixtag{$x}||0; print "      $_\n" for @{$ex{$x}}}
print "\n## tag x class counts\n";
my @cl=sort{$cls{$b}<=>$cls{$a}}keys %cls;
print join("\t",'tag',@cl),"\n";
for my $x(sort{$tag{$b}<=>$tag{$a}}keys %tag){print join("\t",$x,map{$cx{$x}{$_}||0}@cl),"\n"}
print "\n## primary class (most specific tag by priority): total / fix-worded\n";
for my $p(sort{$prim{$b}<=>$prim{$a}}keys %prim){printf "%-14s %6d  fix %5d  ex: %s\n",$p,$prim{$p},$primfix{$p}||0,join("; ",@{$exprim{$p}})}
print "\n## top normalized fix subjects\n";
my $i=0; for my $n(sort{$norm{$b}<=>$norm{$a}}keys %norm){last if ++$i>40; my ($top)=sort{$normcls{$n}{$b}<=>$normcls{$n}{$a}}keys %{$normcls{$n}};printf "%5d  %-72s [%s] %s\n",$norm{$n},$n,$top,join(",",@{$normex{$n}})}
print "\n## repos by fix/revert count (top 25) with total\n";
$i=0; for my $r(sort{($repo_fix{$b}||0)<=>($repo_fix{$a}||0)}keys %repo_tot){last if ++$i>25; printf "%5d / %5d  %s\n",$repo_fix{$r}||0,$repo_tot{$r},$r}
