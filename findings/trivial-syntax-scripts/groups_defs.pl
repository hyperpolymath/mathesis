use strict;
my @G=(
 ['G1 workflow/YAML parse-dead repair', qr/unbreak workflow yaml|parse-dead|cannot parse it|unparse?able|unparsable|workflow[- ]linter yaml parse|invalid yaml|yaml (?:parse|syntax)|permissions block indentation|blind permissions insertion|not valid yaml|invalid workflow|malformed workflows?|orphan mapping key|invalid timeout-minutes|workflow syntax errors?|rejected at parse time|YAML parse error/i],
 ['G2 vacuous/unsatisfiable gate repaired (gate could not fail)', qr/never matched|gate never|could not fail|cannot fail|able to fail|can actually fail|could not be satisfied|vacuous|matched nothing|caught 0|silently (?:did nothing|passes|pass)|never (?:ran|run|fired)|never detected|gate .{0,30}(?:inert|dead)|no-op gate/i],
 ['G3a phantom/nonexistent reference (hallucinated SHA, deleted repo, dead link)', qr/phantom|nonexistent|non-existent|does not exist|doesn.t exist|never existed|a SHA that exists|names no commit|dead (?:internal |external )?links?|broken links?|dangling/i],
 ['G3b repoint to relocated/renamed target', qr/repoint|stale (?:pin|sha|reference|link)/i],
 ['G4 trailing newline / EOL / whitespace', qr/trailing newline|newline at (?:the )?end|final newline|end of file|\bEOF\b|\bCRLF\b|line[- ]endings?|trailing[- ]?(?:white)?space|strip trailing/i],
 ['G5 typo / spelling', qr/\btypos?\b(?! dir)|misspell|spelling (?:fix|error|mistake|of)|fix(?:es|ed)? spelling|\bnpermissions\b/i],
 ['G6 punctuation/bracket balance (code fence, brace, comma, quote)', qr/missing (?:a |the )?(?:semi-?colon|comma|bracket|brace|closing|paren|quote|colon)|unclosed|unbalanced|unterminated|stray `|(?:extra|stray|dangling) (?:comma|bracket|brace|paren|quote)/i],
 ['G7 code-language syntax/parse error fix', qr/(?:syntax|parse|parsing) errors?|invalid syntax|doc comment cannot precede|unexpected token/i],
 ['G8 TOML/JSON/KYAML/deed/k9/Nickel data-file syntax', qr/(?:broken|invalid|malformed|repair|fix)\w* (?:the )?(?:\S+\.)?(?:toml|json|jsonl|kyaml|ncl|deed|k9)\b|(?:toml|json|kyaml|deed|k9|\.ncl).{0,25}(?:syntax error|parse error|invalid|malformed)|k9 syntax|valid nickel/i],
 ['G9 encoding / invisible chars / BOM', qr/\bencoding\b|\bUTF-?8\b|mojibake|non-?ascii|\bBOM\b|invisible[- ]char|zero-width|smart quotes?|em[- ]dash/i],
 ['G10 formatter/indent/lint mechanical', qr/\bindent(?:ation)?\b|\bcargo fmt\b|\brustfmt\b|\bmix format\b|\bprettier\b|\bgofmt\b|\bzig fmt\b|\bdeno fmt\b|\bshfmt\b|\bformatting\b|\breformat|^style(?:\(|:)|\bclippy\b|\bshellcheck\b|unused (?:import|variable|var|use|mut)|\bSC\d{4}\b|lint (?:fix|error|warning)s?/i],
 ['G11 SPDX header add/position/malformed (excl. licence-flip sweeps)', qr/missing SPDX|add(?:s|ed)? (?:missing )?(?:SPDX|licen[cs]e headers?)|SPDX .{0,25}line 1|SPDX.{0,20}(?:position|banner|first line)|malformed .{0,20}SPDX|SPDX (?:head|lint|check|rule|recipe)|restore SPDX|SPDX-License-Identifier header/i],
 ['G12 licence-identifier flip sweeps (AGPL/MPL/PMPL) - flag only, not mechanical errors', qr/AGPL|PMPL|MPL-2\.0|CC-BY-SA|licen[cs]e(?:\)|:)? (?:normali|fix|SPDX)|licence\(|normalise the tree/i],
 ['G13 template-placeholder / unfilled scaffold', qr/placeholder/i],
 ['G14 markdown<->adoc extension/migration/rename', qr/\.md\b.{0,40}\.adoc|\.adoc\b.{0,40}\.md\b|markdown to asciidoc|convert(?:ed)? .{0,20}(?:to|->) (?:asciidoc|adoc)|rename .{0,40}README|restore canonical README|stale \.md|retired \.md/i],
 ['G15 asciidoc/markdown render syntax (heading, table, fence, xref)', qr/(?:asciidoc|adoc|markdown|mermaid|heading|code fence|xref|tree).{0,40}(?:render|syntax|quote|fence|table|heading)|render(?:s|ing)?\b.{0,40}(?:tree|table|asciidoc|adoc|markdown)|section heading/i],
 ['G16 path / case / capitalisation', qr/(?:wrong|incorrect|broken|bad|stale|dead|correct) (?:\w+ )?paths?\b|fix(?:es|ed)? (?:the )?(?:\w+ )?paths?\b|\bcase[- ](?:sensitiv|insensitiv|mismatch)|capitali[sz]e|capitali[sz]ation|lowercase|\bcasing\b|relative path/i],
 ['G17 trivial compile/build/import error', qr/(?:build|compile|compilation|type|import|name|module) errors?|missing (?:import|use|module|dependency|dep|include|export)\b|undefined (?:variable|name|symbol|function)|does not compile|doesn't compile|unbreak (?:the )?build/i],
);
my $FIX=qr/\b(?:fix(?:es|ed|ing)?|correct(?:s|ed|ion)?|repair(?:s|ed)?|typo|unbreak|restore[sd]?|normali[sz]e[sd]?|strip|trim|unblock|repoint|mend|amend|re-?anchor|add(?:s|ed)? missing|resolve[sd]?)\b|\b(?:missing|broken|invalid|wrong|incorrect|unparseable|malformed|phantom|never)\b|^style/i;
my %st;
my %e; my %n;
while(<STDIN>){chomp; my @f=split /\t/,$_,10; my ($h,$repo,$nr,$d,$cls,$fx,$nf,$exts,$m,$s)=@f; next if $cls eq 'dependabot'||$cls eq 'third-party-human'; next unless $s=~$FIX;
 for my $g(@G){ if($s=~$g->[1]){ my $k=substr($g->[0],0,3); $k=~s/\s//g; $n{$k}++; for my $p(split /,/,$exts){ my($x,$c)=split /:/,$p; next if $x eq '.github/workflows'; $e{$k}{$x}+=1; } last } } }
for my $k(sort keys %e){ my @t=sort{$e{$k}{$b}<=>$e{$k}{$a}} keys %{$e{$k}}; print "$k (n=$n{$k}): ",join(" ",map{"$_=$e{$k}{$_}"} @t[0..($#t>7?7:$#t)]),"\n"; }
