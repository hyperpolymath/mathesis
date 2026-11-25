use strict; use warnings;
my @q=(
["fabricated/nonexistent/fake refs (SHA,action,path,tool)", qr/(fake|nonexistent|non-existent|phantom|does not exist|doesn.t exist|dangling|invented|hallucinat|fabricat|made.up|bogus|unreachable).{0,40}(sha|pin|action|ref|path|file|tool|link|version|repo|import|crate|url|workflow|tag)|(sha|pin|action|ref|path|tool|link|version|repo|import|crate|url|tag).{0,40}(fake|nonexistent|non-existent|phantom|does not exist|doesn.t exist|bogus|fabricat|hallucinat|unreachable|that exists)/],
["pin/SHA repair (fix/repoint/repin/restore + pin|sha)", qr/(pin|sha).{0,40}(fix|repair|repoint|re-point|repin|restore)|(fix|repair|repoint|re-point|repin|restore).{0,40}(pin|sha)/],
["workflow YAML invalid/parse/startup", qr/(invalid|broken|malformed|bad).{0,20}(yaml|workflow)|yaml.{0,20}(parse|syntax|error|indent|invalid)|startup_failure|parse error|unbreak.*workflow|workflow.{0,20}(never ran|has never run)/],
["email/author identity fixes", qr/(fix|correct).{0,20}(email|author|identity)/],
["a2ml removal/migration", qr/a2ml.{0,40}(remov|delet|migrat|retire|translat|convert|→|->)|(remov|delet|migrat|retire|convert).{0,40}a2ml/],
["format migrations (a2ml/deed/kyaml/ijson/yaml/json/bun/deno/affine)", qr/migrat.{0,30}(a2ml|deed|kyaml|ijson|yaml|json|bun|deno|affine)/],
["deed grammar/lint fixes", qr/deed.{0,30}(lint|grammar|parse|syntax|invalid|valid)|(lint|grammar|invalid).{0,30}deed/],
["merge-conflict resolution", qr/(resolve|resolving|fix|fixed|repair).{0,25}conflict|conflict markers|resolve conflicts/],
["lockfile regen/resync/reconcile", qr/(regen|regenerate|resync|re-sync|reconcile|refresh|sync|update).{0,30}(lock|actions\.lock|bun\.lock|cargo\.lock|deno\.lock)/],
["signing/unverified", qr/(unsigned|unverified|re-?sign|signature|signing).{0,30}(fix|require|enforce|key|commit)|\bgpg\b|ssh signing/],
["template sync/propagation/canonical", qr/(sync|propagat|roll ?out|backport|port).{0,30}(template|rsr|canonical|standards)|rsr (compliance|template|sync)|canonical/],
["typo", qr/\btypos?\b/],
["placeholder/stub/unfilled", qr/placeholder|\{\{|\bstub\b|\btodo\b|unfilled/],
["honest/honesty wording", qr/\bhonest/],
["fix-after-bump (fix.*bump/dependabot)", qr/fix.*(dependabot|bump)|dependabot.*(fix|break|broke|fail)/],
["bump breaks / revert bump", qr/revert.*(bump|dep|upgrade|update)|bump.{0,30}(break|broke|fail)/],
["claims vs reality (actually has/does not/never ran/never matched/could never)", qr/never (ran|matched|fired|run|worked|passed)|could never|actually (has|have|exists?|uses?|contains?|does|is|are)|\bno-?op\b|silently|silent(ly)? (pass|green|skip)|vacuous|false (green|positive|negative)|fail-?closed|fail loud/],
["wrong repo/name/path/value (self-correction)", qr/wrong (sha|path|name|repo|file|ref|value|version|link|url|email|licen|spdx|owner|org|directory|dir|branch)|incorrect|mistaken|accidental|forgot|missed|oversight|\boops\b|my mistake/],
["stale/sync drift of generated views", qr/(regenerate|regen|stale|out of date|out-of-date|out of sync|desync).{0,40}(view|catalogue|census|readme|badge|docs|generated|index|registry)|generated.{0,30}(stale|drift|out of)/],
["dead/broken links", qr/(broken|dead|stale|wrong).{0,10}link|repoint|re-point|404/],
);
my $N=0; my @cnt=(0)x@q; my @repos=map{{}}@q; my @ex=map{[]}@q; my @fixw=(0)x@q;
open my $in,'<','classified.tsv'; <$in>;
while(<$in>){chomp;my($r,$h,$np,$c,$t,$p,$s)=split /\t/,$_,7;$N++; my $l=lc $s;
 for my $i(0..$#q){ if($l=~$q[$i][1]){$cnt[$i]++;$repos[$i]{$r}=1; push @{$ex[$i]},substr($h,0,9)." ".$r." | ".substr($s,0,80) if @{$ex[$i]}<2}}}
print "N=$N\n";
for my $i(0..$#q){printf "%-70s commits=%5d repos=%3d\n",$q[$i][0],$cnt[$i],scalar keys %{$repos[$i]}; print "    $_\n" for @{$ex[$i]}}
