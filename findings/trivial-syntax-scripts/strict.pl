use strict;
# strict primary classification from mech.tsv rows
my @R=(
 ['wf_yaml_parse', qr/unbreak workflow yaml|parse-dead|cannot parse it|unparse?able|unparsable|workflow[- ]linter yaml parse|invalid yaml|yaml (?:parse|syntax|error)|permissions block indentation|blind permissions insertion|not valid yaml|invalid workflow|malformed workflows?|orphan mapping key|invalid timeout-minutes|workflow syntax errors?|workflows? (?:are|is) (?:invalid|rejected)|rejected at parse time|(?:fix|repair)\w* (?:\S+\.)?ya?ml.{0,25}(?:syntax|indent)|YAML parse error/i],
 ['trailing_newline_eol', qr/trailing newline|newline at (?:the )?end|final newline|end of file|end-of-file|\bEOF\b|\bCRLF\b|line[- ]endings?|trailing[- ]?(?:white)?space|whitespace (?:fix|cleanup)|strip trailing/i],
 ['typo', qr/\btypos?\b(?! dir)|misspell|spelling (?:fix|error|mistake|of)|fix(?:es|ed)? spelling|\bnpermissions\b/i],
 ['punct_balance', qr/missing (?:a |the )?(?:semi-?colon|comma|bracket|brace|closing|paren|quote|colon)|unclosed|unbalanced|unterminated|stray `|(?:extra|stray|dangling) (?:comma|bracket|brace|paren|quote)/i],
 ['code_syntax_parse', qr/(?:syntax|parse|parsing) errors?|invalid syntax|\bparse (?:fix|failure)|fix(?:es|ed)? (?:the )?(?:two |three |\d+ )?(?:\w+ )?syntax|doc comment cannot precede|unexpected token/i],
 ['data_format_syntax', qr/(?:broken|invalid|malformed|repair|fix)\w* (?:the )?(?:\S+\.)?(?:toml|json|jsonl|kyaml|ncl|deed|k9)\b|(?:toml|json|kyaml|deed|k9|\.ncl).{0,25}(?:syntax error|parse error|invalid|malformed)|\bk9 syntax/i],
 ['encoding_unicode', qr/\bencoding\b|\bUTF-?8\b|\bmojibake\b|non-?ascii|\bBOM\b|invisible[- ]char|zero-width|smart quotes?|em[- ]dash/i],
 ['indent_format_tool', qr/\bindent(?:ation)?\b|\bcargo fmt\b|\brustfmt\b|\bmix format\b|\bprettier\b|\bgofmt\b|\bzig fmt\b|\bdeno fmt\b|\bshfmt\b|\bformatting\b|\breformat|fix(?:es|ed)? format\b|^style(?:\(|:)|kyaml-format|\bjulia ?formatter/i],
 ['lint_mechanical', qr/\bclippy\b|\bshellcheck\b|\byamllint\b|\bmarkdownlint\b|unused (?:import|variable|var|use|mut)|dead[_ ]code warnings?|compiler warnings?|\bSC\d{4}\b|lint (?:fix|error|warning)s?/i],
 ['spdx_header', qr/\bSPDX\b|licen[cs]e headers?|copyright headers?/i],
 ['link_broken', qr/broken links?|dead (?:internal |external )?links?|link rot|fix(?:es|ed)? (?:the |a |some |\d+ |three |two )?(?:\w+ )?(?:links?|urls?|hrefs?|xrefs?)\b|(?:wrong|incorrect|stale|bad|invalid|dead|broken) (?:\w+ )?(?:link|url|href|xref|anchor)s?\b|links? (?:fix|repair)|broken anchor|re-?anchor|repoint/i],
 ['asciidoc_markdown_syntax', qr/asciidoc|\badoc\b|markdown|mermaid|heading|code (?:block|fence)|renders?\b|rendering|\bxref\b/i],
 ['ext_rename_path_case', qr/\bfile extension|extension (?:mismatch|fix)|\.md\s*(?:->|→|to)\s*\.adoc|rename[sd]? .{0,40}\.\w{2,5}\b|(?:wrong|incorrect|broken|bad|stale|dead|correct) (?:\w+ )?paths?\b|fix(?:es|ed)? (?:the )?(?:\w+ )?paths?\b|\bcase[- ](?:sensitiv|insensitiv|mismatch)|capitali[sz]|lowercase|uppercase|\bcasing\b|relative path/i],
 ['compile_trivial', qr/(?:build|compile|compilation|type|import|name|module) (?:errors?|failures?)|missing (?:import|use|module|dependency|dep|include|export)\b|undefined (?:variable|name|symbol|function)|does not compile|doesn't compile|unbreak (?:the )?build/i],
);
my $FIX=qr/\b(?:fix(?:es|ed|ing)?|correct(?:s|ed|ion)?|repair(?:s|ed)?|typo|unbreak|restore[sd]?|normali[sz]e[sd]?|strip|trim|unblock|repoint|mend|amend|re-?anchor|remove(?:s|d)? (?:broken|dead|stale))\b|\b(?:missing|broken|invalid|wrong|incorrect|unparseable|malformed)\b|^style/i;
my $NOTFIX=qr/^(?:feat|refactor|docs?: add|Add |Create |Initial)/i;
my %n;
while(<STDIN>){chomp; my @f=split /\t/,$_,10; my $s=$f[9]; 
  my $prim='-'; if($s=~$FIX){ for my $r(@R){ if($s=~$r->[1]){$prim=$r->[0];last} } }
  print join("\t",@f[0..8],$prim,$s),"\n"; }
