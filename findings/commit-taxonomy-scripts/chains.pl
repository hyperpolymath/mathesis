use strict; use warnings;
# author class by hash
my %cls; open my $c,'<','classified.tsv'; <$c>; my %fixw;
while(<$c>){chomp;my($r,$h,$np,$k,$t,$p,$s)=split /\t/,$_,7; $cls{"$r $h"}=$k; $fixw{"$r $h"}=1 if $t=~/(^|,)(fix|revert)(,|$)/;}
my (%tot,%withprev,%chainlen,%pathcnt,%reposc,%pairs,%cnt_cls,%prev_cls,%catpair); my ($nfix,$nwith,$ncommits)=(0,0,0);
my $W=3;
my %repo_c;
sub flush { my ($repo,$list)=@_; 
  my @c=@$list; $ncommits+=@c; # newest first
  for my $i (0..$#c){
    my $a=$c[$i]; next unless $fixw{"$repo $a->{h}"}; $nfix++; $cnt_cls{$cls{"$repo $a->{h}"}||'?'}++; $reposc{$repo}{fix}++;
    my $found=0; my %shared;
    for my $j ($i+1..($i+$W)){ last if $j>$#c; my $b=$c[$j]; next unless $fixw{"$repo $b->{h}"};
      for my $p (keys %{$a->{f}}){ if($b->{f}{$p}){ $shared{$p}=1; $found=1; } }
      if($found && !$pairs{"$repo $a->{h}"}){ $pairs{"$repo $a->{h}"}="$b->{h}"; }
    }
    if($found){ $nwith++; $reposc{$repo}{chain}++; $withprev{$cls{"$repo $a->{h}"}||'?'}++;
      $pathcnt{$_}++ for keys %shared;
      push @{$main::ex{$repo}}, "$a->{h}<-$pairs{\"$repo $a->{h}\"}: ".join(",",(sort keys %shared)[0..(keys(%shared)>2?2:$#{[keys %shared]})]) if @{$main::ex{$repo}||[]}<1;
      my $bk=$cls{"$repo $pairs{\"$repo $a->{h}\"}"}||'?'; $catpair{$cls{"$repo $a->{h}"}." <- ".$bk}++;
    }
  }
  # chain length: runs of linked fix commits
  my $run=0; for my $i (0..$#c){ my $a=$c[$i]; if($pairs{"$repo $a->{h}"}){$run++} else { if($run>0){$chainlen{$run+1}++} $run=0 } } $chainlen{$run+1}++ if $run>0;
}
open my $n,'<','names.txt'; my ($cur,$repo,@list)=(undef,'');
while(<$n>){ chomp; if(/^@@\t([^\t]+)\t([0-9a-f]+)\t/){ my($r,$h)=($1,$2); if($r ne $repo){ flush($repo,\@list) if $repo ne ''; @list=(); $repo=$r } $cur={h=>$h,f=>{}}; push @list,$cur; } elsif(length $_ && $cur){ $cur->{f}{$_}=1 } }
flush($repo,\@list);
print "non-merge HEAD commits: $ncommits\nfix/revert-worded: $nfix\nfix with an earlier(older) fix/revert within $W commits sharing >=1 path: $nwith\n";
print "\nby author class (with-prev / fix): \n"; for my $k(sort{$cnt_cls{$b}<=>$cnt_cls{$a}}keys %cnt_cls){printf "%-30s %5d / %5d\n",$k,$withprev{$k}||0,$cnt_cls{$k}}
print "\nchain length (commits in linked run): "; print join(", ",map{"$_:$chainlen{$_}"}sort{$a<=>$b}keys %chainlen),"\n";
print "\ntop shared paths:\n"; my $i=0; for my $p(sort{$pathcnt{$b}<=>$pathcnt{$a}}keys %pathcnt){last if ++$i>25; printf "%5d %s\n",$pathcnt{$p},$p}
print "\ntop repos (chain/fix):\n"; $i=0; for my $r(sort{($reposc{$b}{chain}||0)<=>($reposc{$a}{chain}||0)}keys %reposc){last if ++$i>20; printf "%5d / %5d %s  ex %s\n",$reposc{$r}{chain}||0,$reposc{$r}{fix},$r,($main::ex{$r}[0]||'')}
print "\nclass pairs (newer <- older) top 12:\n"; $i=0; for my $p(sort{$catpair{$b}<=>$catpair{$a}}keys %catpair){last if ++$i>12; printf "%5d %s\n",$catpair{$p},$p}
