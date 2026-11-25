#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: template copy fan-out drift.
# Question: for each template-owned path, what share of child copies is byte-identical to SOME
# historical version of that path in rsr-template-repo (pure staleness, empty complement), versus
# identical to template HEAD, versus matching no template version (non-empty complement)?
# Uses tree objects only (git log --raw, git ls-tree): no blob is fetched.
set -euo pipefail
EST=${EST:-/home/user/estate}; T=$EST/hyperpolymath/rsr-template-repo; OUT=${OUT:-/tmp/pf/p1}
mkdir -p "$OUT"; cd "$EST"
# template-owned candidate paths: every path at template HEAD (files only)
git -C "$T" ls-tree -r HEAD | awk '{print $3"\t"$4}' > "$OUT/template_head.tsv"
# all historical blobs per path in the template (new side of every raw diff entry, all refs)
git -C "$T" log --all --raw --no-abbrev --no-renames --format= | awk '$1 ~ /^:/ {print $4"\t"$6}' | sort -u > "$OUT/template_hist.tsv"
: > "$OUT/children.tsv"
while read -r repo _; do
  [ "$repo" = "hyperpolymath/rsr-template-repo" ] && continue
  git -C "$EST/$repo" ls-tree -r HEAD 2>/dev/null | awk -v r="$repo" '{print r"\t"$3"\t"$4}' >> "$OUT/children.tsv" || true
done < "$EST/.stats.tsv"
perl -e '
  my ($out)=@ARGV; my (%head,%hist);
  open my $h,"<","$out/template_head.tsv"; while(<$h>){chomp; my($b,$p)=split /\t/; $head{$p}=$b}
  open my $i,"<","$out/template_hist.tsv"; while(<$i>){chomp; my($b,$p)=split /\t/; $hist{$p}{$b}=1}
  my (%n,%eqh,%eqa,%none);
  open my $c,"<","$out/children.tsv"; while(<$c>){chomp; my($r,$b,$p)=split /\t/; next unless exists $head{$p};
    $n{$p}++; if($b eq $head{$p}){$eqh{$p}++} elsif($hist{$p}{$b}){$eqa{$p}++} else {$none{$p}++} }
  my ($N,$H,$A,$X)=(0,0,0,0); my @rows;
  for my $p (keys %n){ next if $n{$p}<25; $N+=$n{$p}; $H+=$eqh{$p}//0; $A+=$eqa{$p}//0; $X+=$none{$p}//0;
    push @rows,[$p,$n{$p},$eqh{$p}//0,$eqa{$p}//0,$none{$p}//0, scalar(keys %{$hist{$p}})]; }
  printf "template paths present in >=25 children: %d; child file instances: %d\n", scalar(@rows), $N;
  printf "  identical to template HEAD: %d\n  identical to an older template version (stale, empty complement): %d\n  identical to no template version (non-empty complement or pre-template origin): %d\n", $H,$A,$X;
  print "path\tchildren\teq_head\teq_ancestor\tno_match\ttemplate_versions\n";
  for my $r (sort {$b->[1] <=> $a->[1]} @rows){ print join("\t",@$r),"\n" }
' "$OUT" > "$OUT/result.tsv"
head -5 "$OUT/result.tsv"
