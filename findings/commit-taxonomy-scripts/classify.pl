use strict; use warnings;
my @tags = (
 [fix      => qr/(^|\b)(fix(es|ed|ing)?|bug-?fix|hotfix|repair(s|ed)?|resolve[sd]? (issue|bug|error))\b/],
 [revert   => qr/\brevert/],
 [typo     => qr/\btypos?\b|misspell/],
 [syntax   => qr/syntax|parse error|parsing error|unbalanced|missing (semicolon|paren|bracket|brace|comma|quote|colon|end)|malformed|invalid (yaml|json|toml|syntax|nickel|deed)|yaml (error|parse)|unterminated|unexpected token|does not parse|doesn't parse|fails? to parse/],
 [lint     => qr/\blint|clippy|shellcheck|eslint|yamllint|codacy|actionlint|\bwarnings?\b|deprecat/],
 [format   => qr/\bformat|\bfmt\b|whitespace|prettier|indent|rustfmt|trailing (space|newline|ws)|line ending|eol\b|newline/],
 [conflict => qr/conflict|<<<<<<<|merge marker/],
 [merge    => qr/^merge\b|\bmerge (branch|pull|remote)/],
 [ci       => qr/\bci\b|ci\/cd|pipeline|github actions?|\bactions?\/|\brunner|\bjobs?\b/],
 [workflow => qr/workflow|\.github\/|\.ya?ml\b/],
 [bump     => qr/\bbump|\bupgrade|\bupdate[sd]? .{1,60} (from|to) v?\d|\bupdate .*\bversion/],
 [deps     => qr/\bdeps?\b|dependenc|dependabot|cargo\.toml|package\.json|\bcrates?\b|npm|\bbun\b|\bdeno\b|\bpnpm\b/],
 [lockfile => qr/lock ?files?|\.lock\b|bun\.lock|cargo\.lock|deno\.lock|package-lock|pnpm-lock|mix\.lock|manifest\.toml/],
 [sign     => qr/\bsign(ed|ing|ature|s)?\b|\bgpg\b|ssh.?key|unverified|\bverified\b|allowed.?signers/],
 [licence  => qr/licen[cs]e|spdx|copyright|\bmpl\b|agpl|pmpl|\bgpl\b/],
 [drift    => qr/\bdrift|out[- ]of[- ]sync|\bstale\b|re-?sync|diverge|desync/],
 [template_sync => qr/(sync|align|update|propagat|port|backport|apply|adopt).{0,40}(template|rsr|standards|estate)|(template|rsr).{0,30}(sync|drift|update|align|propag)|\brsr\b/],
 [rename   => qr/\brenam|\brelocat|\bmove[sd]? |\bmoving\b|\bmigrat/],
 [a2ml_deed=> qr/a2ml|\.deed\b|\bdeed\b|descriptile|machine_readable|\bchora\b|contractile|\bk9\b/],
 [ai_honesty=> qr/hallucinat|fabricat|overclaim|over-claim|\bwrong\b|incorrect|\boops\b|\bactually\b|mistake|bogus|false claim|inflated|honest|misleading|phantom|made.?up|non-?existent|invented|unsubstantiated|\bnot real\b|\bfake\b|overstat|misreport/],
 [pinning  => qr/\bpin(ned|ning|s)?\b|sha-?pin|\bsha\b|\bdigest\b/],
 [security => qr/secur|vuln|\bcve\b|secret|\btoken\b|permission|\bcodeql\b|scorecard|trufflehog|\bhypatia\b/],
 [test_fail=> qr/\btests?\b.{0,20}(fail|broken|red)|flak|\btimeout|failing|\bfails?\b|\bfailure|\bred\b/],
 [build_break=> qr/build (fail|break|error|broke)|\bcompil|\bbroken\b|unbreak|\bbreak(s|ing)?\b|\bcrash|\berrors?\b/],
 [docs     => qr/\bdocs?\b|readme|documentation|\badoc\b|changelog/],
 [link_path=> qr/broken link|\blinks?\b|\bpaths?\b|\burl\b|404|dead link|\bmissing\b|not found/],
 [placeholder=> qr/placeholder|\bstub\b|\btodo\b|\bwip\b|scaffold/],
 [proof    => qr/\bproof|\bagda\b|\bidris|\blean\b|\brocq\b|\bcoq\b|\bpostulate|\bsorry\b|believe_me|admitted|verus|creusot|\bspark\b/],
 [skip_ci  => qr/\[skip ci\]|\[ci skip\]|\*\*\*no_ci\*\*\*/],
);
my @prio = qw(revert conflict syntax typo ai_honesty licence sign lockfile bump deps template_sync a2ml_deed drift format lint ci workflow proof security test_fail build_break link_path docs rename merge pinning placeholder);
my %seen;
my %ai_re_cache;
sub aiclass {
  my ($an,$ae,$tr)=@_;
  return 'dependabot' if $an=~/dependabot/i || $ae=~/dependabot/i;
  return 'github-actions' if $an=~/^github[- ]actions/i || $ae=~/github-actions/i;
  return 'ai-author' if $an=~/^claude$/i || $ae=~/anthropic\.com/i;
  return 'other-bot' if $an=~/\[bot\]|arena|rhodibot|hypatia|gitbot|stage5|renovate|^e0-agent|copilot|codacy/i;
  return 'human+AI-coauthored' if $tr=~/claude|anthropic|mistral|arena|copilot|gemini|codex|gpt|e0-agent|vibe|fable|opus|sonnet|haiku|stage5|rhodibot|hypatia|autofix|agent/i && ($ae=~/hyperpolymath|jonathan|joshua/i || $an=~/jewell|hyperpolymath/i);
  return 'other-coauthored' if $tr=~/claude|anthropic|mistral|arena|copilot|gemini|codex|gpt|vibe/i;
  return 'owner-human(no AI trailer)' if $ae=~/hyperpolymath|jonathan\.jewell|joshua/i || $an=~/jewell|hyperpolymath/i;
  return 'third-party-human';
}
open my $out,'>','classified.tsv' or die;
print $out join("\t",'repo','hash','nparents','class','tags','prim','subject'),"\n";
open my $in,'<','all.tsv' or die;
while(<$in>){
  chomp; my ($repo,$h,$np,$an,$ae,$tr,$s)=split /\t/,$_,7;
  my $l=lc $s; my @t;
  for my $t (@tags){ push @t,$t->[0] if $l=~$t->[1]; }
  my %h=map{$_=>1}@t;
  my $prim='none';
  # primary: first fix-ish category by priority among tags; if tagged fix/revert but nothing else => generic-fix
  for my $p (@prio){ if($h{$p}){$prim=$p;last} }
  if($prim eq 'none'){ $prim = $h{fix}?'generic-fix':'other'; }
  print $out join("\t",$repo,$h,$np,aiclass($an,$ae,$tr),join(",",@t),$prim,$s),"\n";
}
