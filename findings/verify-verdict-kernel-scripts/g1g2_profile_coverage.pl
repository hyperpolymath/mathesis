use strict;
my $P="/home/user/estate/hyperpolymath/proven-cicd-and-workflows/profiles/ci-gate";
my (%union,%per);
for my $f (glob("$P/*/*.json")){ my $j=`cat $f`; my ($repo)=$j=~/"repository":"([^"]+)"/; while($j=~/"workflow":"\.github\/workflows\/([^"]+)"/g){ $union{$1}=1; $per{$repo}{$1}=1; } }
my $G1=qr/unbreak workflow yaml|parse-dead|cannot parse it|unparse?able|unparsable|workflow[- ]linter yaml parse|invalid yaml|yaml (?:parse|syntax)|permissions block indentation|blind permissions insertion|not valid yaml|invalid workflow|malformed workflows?|orphan mapping key|invalid timeout-minutes|workflow syntax errors?|rejected at parse time|YAML parse error/i;
my $G2=qr/never matched|gate never|could not fail|cannot fail|able to fail|can actually fail|could not be satisfied|vacuous|matched nothing|caught 0|silently (?:did nothing|passes|pass)|never (?:ran|run|fired)|never detected|gate .{0,30}(?:inert|dead)|no-op gate/i;
my $FIX=qr/\b(?:fix(?:es|ed|ing)?|correct(?:s|ed|ion)?|repair(?:s|ed)?|typo|unbreak|restore[sd]?|normali[sz]e[sd]?|strip|trim|unblock|repoint|mend|amend|re-?anchor|add(?:s|ed)? missing|resolve[sd]?)\b|\b(?:missing|broken|invalid|wrong|incorrect|unparseable|malformed|phantom|never)\b|^style/i;
my ($repo,$h,$an,$s,@files); my %st; my %wf; my %all;
sub flush { return unless defined $h; $all{n}++; $all{pr}++ if $s=~/\(#\d+\)\s*$/;
  return if $an=~/dependabot/; return unless $s=~$FIX; my $g = $s=~$G1 ? 'G1' : $s=~$G2 ? 'G2' : undef; return unless $g;
  my @w = map { m{^\.github/workflows/([^/]+\.ya?ml)$} ? $1 : () } @files;
  my $x=$st{$g}||={}; $x->{n}++; $x->{pr}++ if $s=~/\(#\d+\)\s*$/; $x->{repos}{$repo}=1;
  $x->{touchwf}++ if @w; $x->{nowf}++ unless @w;
  $x->{anyunion}++ if grep {$union{$_}} @w; $x->{allunion}++ if @w && !grep {!$union{$_}} @w;
  $x->{wffiles}+=@w; $x->{wfunion}+=grep {$union{$_}} @w;
  if($per{$repo}){ $x->{inprof_repo}++; $x->{inprof_hit}++ if grep {$per{$repo}{$_}} @w; }
  $wf{$g}{$_}++ for @w;
}
while(<STDIN>){ chomp; if(/^@@\t([^\t]+)\t([0-9a-f]+)\t([^\t]*)\t(.*)$/){ flush(); ($repo,$h,$an,$s)=($1,$2,$3,$4); @files=(); } elsif(length){ push @files,$_; } }
flush();
printf "all commits (HEAD,no-merges)=%d with (#N) suffix=%d\n",$all{n},$all{pr};
print "profile-union workflow basenames: ",scalar(keys %union),"\n";
for my $g(qw(G1 G2)){ my $x=$st{$g}; printf "%s commits=%d repos=%d viaPR(#N)=%d touch_wf=%d no_wf=%d any_wf_in_union=%d all_wf_in_union=%d wf_file_touches=%d of_which_union=%d | in 17 profiled repos=%d hit that repo's profile=%d\n",$g,$x->{n},scalar keys %{$x->{repos}},$x->{pr},$x->{touchwf},$x->{nowf},$x->{anyunion},$x->{allunion},$x->{wffiles},$x->{wfunion},$x->{inprof_repo},$x->{inprof_hit};
  my @t=sort{$wf{$g}{$b}<=>$wf{$g}{$a}} keys %{$wf{$g}}; print "  top: ",join(" ",map{"$_=$wf{$g}{$_}".($union{$_}?"*":"")} @t[0..24]),"\n"; }
