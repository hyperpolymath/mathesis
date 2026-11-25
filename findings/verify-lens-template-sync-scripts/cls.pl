use strict; use warnings;
my (%hist,%tpath,%anyblob,%head);
open my $h,'<','t_hist.tsv'; while(<$h>){chomp;my($b,$p)=split /\t/;$hist{$p}{$b}=1;$tpath{$p}=1;$anyblob{$b}=1}
open my $hh,'<','t_head.tsv'; while(<$hh>){chomp;my($b,$p)=split /\t/;$head{$p}=$b}
my (%c,%subj); open my $f,'<','fan_commits.tsv'; while(<$f>){chomp;my($r,$hsh,$np,$n)=split /\t/;$subj{"$r\t$hsh"}=$n}
my %F; # file-level
my %commit;
open my $in,'<','fan_raw.tsv';
while(<$in>){chomp;my($r,$cm,$old,$new,$st,$p)=split /\t/;
  my $k="$r\t$cm"; my $e=($commit{$k}//={n=>0,tp=>0,newT=>0,oldT=>0,both=>0,newAny=>0,wf=>0});
  $e->{n}++; $F{n}++;
  $e->{wf}++ if $p=~m{^\.github/workflows/};
  if($tpath{$p}){ $e->{tp}++; $F{tp}++;
    my $nT=$hist{$p}{$new}?1:0; my $oT=($st eq 'A')?1:($hist{$p}{$old}?1:0);
    $e->{newT}+=$nT; $e->{oldT}+=$oT; $e->{both}++ if $nT&&$oT;
    $F{newT}+=$nT; $F{oldT}+=$oT; $F{both}++ if $nT&&$oT; $F{oldT_notnew}++ if $oT && !$nT; $F{newT_notold}++ if $nT && !$oT;
    $F{"st_$st"}++;
  } else { $F{nontp}++; $F{nontp_wf}++ if $p=~m{^\.github/workflows/} }
}
printf "file changes: %d; on a path the template has ever held: %d; not: %d (of which .github/workflows: %d)\n",$F{n},$F{tp},$F{nontp},$F{nontp_wf};
printf " on template paths: new blob is a template version: %d; old blob a template version (or file added): %d; both: %d; old-yes/new-no: %d; new-yes/old-no: %d\n",$F{newT},$F{oldT},$F{both},$F{oldT_notnew},$F{newT_notold};
my %C; my %bysub;
for my $k(keys %commit){ my $e=$commit{$k}; $C{n}++;
  my $cls;
  if($e->{tp}==0){$cls='no-template-path'}
  elsif($e->{tp}<$e->{n}){ $cls= ($e->{both}==$e->{tp})?'mixed:template-part-pure':'mixed' }
  else { $cls = ($e->{both}==$e->{n})?'PURE (all files: old=template version, new=template version)': ($e->{newT}==$e->{n})?'all-new-are-template-versions (old was edited)': ($e->{newT}>0?'all-template-paths, some new=template':'all-template-paths, no new blob is a template version') }
  $C{$cls}++; $bysub{$subj{$k}//'?'}{$cls}++; $bysub{$subj{$k}//'?'}{n}++;
}
print "commits with raw rows: $C{n}\n"; for(sort{$C{$b}<=>$C{$a}}grep{$_ ne 'n'}keys %C){printf "  %6d  %s\n",$C{$_},$_}
print "\nper subject (top 30 by commits): n | pure | allnew | tp-none-new | notp | mixed*\n";
my $i=0; for my $s(sort{$bysub{$b}{n}<=>$bysub{$a}{n}}keys %bysub){ last if ++$i>30; my $b=$bysub{$s};
 printf "%4d %4d %4d %4d %4d %4d  %s\n",$b->{n},$b->{'PURE (all files: old=template version, new=template version)'}//0,($b->{'all-new-are-template-versions (old was edited)'}//0)+($b->{'all-template-paths, some new=template'}//0),$b->{'all-template-paths, no new blob is a template version'}//0,$b->{'no-template-path'}//0,($b->{'mixed'}//0)+($b->{'mixed:template-part-pure'}//0),substr($s,0,75)}
