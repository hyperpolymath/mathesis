use strict;
my %date; open D,"/tmp/ts/dates.tsv"; while(<D>){chomp;my($r,$h,$d)=split /\t/;$date{$h}=$d if !$date{$h}||$d lt $date{$h}} close D;
my (%nf,%ext,%fl); open F,"/tmp/ts/allfiles.tsv"; while(<F>){chomp;my($r,$h,$f)=split /\t/,$_,3; $nf{$h}++; my $e=($f=~/(?:^|\/)[^\/]*?(\.[A-Za-z0-9_]+)$/)?lc $1:(($f=~m{(?:^|/)(justfile|Justfile|Makefile|Containerfile|Dockerfile|Mustfile|Gemfile|LICENSE|LICENCE|CODEOWNERS|\.gitignore|\.gitattributes|\.editorconfig)$})?lc $1:'(none)'); $ext{$h}{$e}++; if($f=~m{^\.github/workflows/}){$ext{$h}{'.github/workflows'}++} } close F;
my %S=(
 wf_yaml_parse=>qr/unbreak workflow yaml|parse-dead|cannot parse|can't parse|unparseable|unparsable|invalid yaml|yaml parse|yaml syntax|yaml error|permissions block indentation|malformed workflow|workflow[- ]linter yaml|invalid workflow|workflow.{0,30}(?:syntax error|does not parse|doesn't parse|fails to parse|not valid yaml|invalid)|orphan mapping key|mapping key.{0,30}unparse|never run\b.{0,40}pars|(?:fix|repair|unbreak)\w* (?:the )?(?:broken )?\S+\.ya?ml\b.{0,30}(?:syntax|indent|parse)|(?:yaml|yml).{0,25}(?:syntax|indent(?:ation)?) (?:error|fix)|unbreak.{0,20}\.ya?ml/i,
 typo=>qr/\btypos?\b(?! dir)|\bmisspell|\bspelling (?:fix|error|mistake)|fix(?:es|ed)? spelling/i,
 punct_balance=>qr/\bmissing (?:a |the )?(?:semi-?colon|comma|bracket|brace|closing|paren|quote|colon|end\b|`?end`?\b|then\b)|\bunclosed\b|\bunbalanced\b|\bunterminated\b|\b(?:extra|stray|dangling) (?:comma|bracket|brace|paren|quote|backtick)|trailing comma|code fence|stray `/i,
 syntax_err=>qr/syntax error|syntax fix|fix(?:es|ed)?(?: a| the| two| three| several| \d+)? (?:\w+ )?(?:syntax|parse|parsing) (?:errors?|issues?|problems?|failures?|bugs?)|parse errors?\b.{0,30}(?:fix|repair)|(?:fix|repair|unbreak)\w* .{0,25}(?:parse|syntax) error|invalid syntax|malformed/i,
 toml_json_syntax=>qr/(?:broken|invalid|malformed|repair|fix)\w* (?:the )?(?:\S+\.)?(?:toml|json|jsonl|kyaml|ncl|nickel|deed|k9)\b|(?:toml|json|kyaml|deed|k9|\.ncl).{0,25}(?:syntax|parse error|invalid|malformed)|final newline|trailing newline|newline at end|JCS|I-JSON/i,
 whitespace_eol=>qr/trailing[- ]?(?:white)?space|\bwhitespace\b|\bblank lines?\b|\bCRLF\b|\bline[- ]endings?\b|\bindent(?:ation)?\b|\bEOL\b|\bBOM\b|\btabs? (?:vs|to|->|→)|\bnewline/i,
 encoding=>qr/\bencoding\b|\bUTF-?8\b|\bmojibake\b|\bnon-?ascii\b|\bunicode\b|\bsmart quotes?\b|\bem[- ]dash/i,
 format_tool=>qr/\bcargo fmt\b|\brustfmt\b|\bmix format\b|\bprettier\b|\bgofmt\b|\bzig fmt\b|\bdeno fmt\b|\bruff\b|\bblack\b|\bfmt\b|\bformat(?:ting|ted)?\b|\breformat|\bstyle:|\bshfmt\b|\bkyaml-format|\bjulia ?formatter|\bockham/i,
 lint_mech=>qr/\bclippy\b|\bshellcheck\b|\byamllint\b|\bmarkdownlint\b|\bunused (?:import|variable|var|use|mut)|\bdead[_ ]code\b|\bcompiler warnings?\b|\blint (?:fix|error|warning)|\bSC\d{4}\b|\bsonar\b/i,
 spdx_header=>qr/\bSPDX\b|licen[cs]e header|copyright header/i,
 link=>qr/broken links?|dead links?|link rot|\b404\b|fix(?:es|ed)? (?:the |a |some |\d+ )?(?:\w+ )?(?:links?|urls?|hrefs?|xrefs?)\b|(?:wrong|incorrect|stale|bad|invalid|dead|broken) (?:\w+ )?(?:link|url|href|xref|anchor)s?\b|links? (?:fix|repair|check)|lychee|linkcheck|broken anchor|anchors?\b/i,
 markup=>qr/asciidoc|\badoc\b|markdown|mermaid|heading level|code block|codeblock|rendering|renders?\b|\bxref\b|\bpandoc\b|\basciidoctor/i,
 ext_rename=>qr/\bextension\b|\.md\s*(?:->|→|to)\s*\.adoc|\.yml\s*(?:->|→|to)\s*\.(?:yaml|kyaml)|\.(?:yaml|yml)\s*(?:->|→)|\.a2ml\b.{0,20}(?:->|→|to|rename)|rename[sd]? .{0,40}(?:\.\w{2,5})\b|\bmv\b/i,
 path_case=>qr/(?:wrong|incorrect|broken|bad|stale|dead|correct|fix(?:es|ed)?) (?:\w+ )?paths?\b|\bpaths? (?:fix|typo|correct)|\bcase[- ](?:sensitiv|insensitiv|mismatch)|\bcapitali[sz]ation\b|\bcapitali[sz]e\b|\blowercase\b|\bUPPERCASE\b|\bcasing\b|relative path|\bimport path|\binclude path/i,
 compile_trivial=>qr/(?:fix|resolve|repair)\w* (?:the |a |some |all |\d+ |several |remaining |two |three )?(?:\w+ )?(?:build|compile|compilation|type|import|name|module) (?:errors?|failures?|breakage)|missing (?:import|use|module|dependency|dep|include|export)\b|undefined (?:variable|name|symbol|function|reference)|\bdoes not compile|doesn't compile|\bwon't compile|unbreak (?:the )?build|\bbuild fix/i,
);
my $FIX=qr/\b(?:fix(?:es|ed|ing)?|correct(?:s|ed|ion)?|repair(?:s|ed)?|typo|unbreak|restore[sd]?|resolve[sd]?|patch|hotfix|oops|tidy|clean\s?up|normali[sz]e[sd]?|strip|trim|unblock|mend|amend)\b|\b(?:missing|broken|invalid|stale|wrong|incorrect|unparseable|malformed)\b|^(?:style|chore\(fmt\)|fmt)/i;
my %seen; my %repos; my @rows;
open C,"/tmp/ct/classified.tsv"; <C>;
while(<C>){chomp; my($repo,$h,$np,$cls,$tags,$prim,$s)=split /\t/,$_,7; next if $np>1; $repos{$h}{$repo}=1; next if $seen{$h}++; push @rows,[$repo,$h,$cls,$s]; }
close C;
my @order=qw(wf_yaml_parse typo punct_balance syntax_err toml_json_syntax whitespace_eol encoding format_tool lint_mech spdx_header link markup ext_rename path_case compile_trivial);
for my $r (@rows){ my($repo,$h,$cls,$s)=@$r; my @m; for my $k (@order){ push @m,$k if $s=~$S{$k} } 
 my $fx = ($s=~$FIX)?1:0; 
 my $nr=scalar keys %{$repos{$h}};
 my @e=sort {$ext{$h}{$b}<=>$ext{$h}{$a}} keys %{$ext{$h}||{}}; 
 print join("\t",$h,$repo,$nr,substr($date{$h}||'',0,10),$cls,$fx,($nf{$h}||0),join(",",map{"$_:".$ext{$h}{$_}} @e[0..($#e>5?5:$#e)]),join(",",@m)||'-',$s),"\n"; }
