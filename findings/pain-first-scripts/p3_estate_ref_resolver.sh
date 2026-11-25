#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: fabricated / unresolvable references.
# A closed-world resolver for the workflow references the clones can decide offline.
#  (A) every workflow `uses: OWNER/REPO[/PATH]@REF` whose OWNER is one of the four estate orgs and whose REF
#      is 40 hex: is the repo a clone here (under the written owner, or under another estate owner = moved)?
#      Of what SORT is the object REF names there: a commit (what Actions needs), a blob or tree (wrong sort:
#      found by searching tree entries of all history, no network), or nothing? Does PATH exist at the commit?
#  (B) any `@<hex>` pin, any owner, whose hex run is not exactly 40 characters.
# NOT judged (counted as undecided): refs written as a tag or branch NAME (the clones were made with
# --no-tags), and third-party repos (no network). GIT_NO_LAZY_FETCH=1: a partial clone would otherwise ask
# the remote for a missing id; with it set, a blob id is recognised from tree entries instead.
set -uo pipefail
export GIT_NO_LAZY_FETCH=1
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/p3}; mkdir -p "$OUT"; cd "$EST"
rg -N --no-heading -o -g '*.yml' -g '*.yaml' '^\s*-?\s*uses:\s*["'"'"']?([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)(/[^@\s"'"'"']*)?@([^\s"'"'"'#]+)' -r '$1 $2 $3 $4' */*/.github/workflows 2>/dev/null \
  | sed -E 's/^([^:]+):/\1 /' > "$OUT/uses.txt"
echo "uses: lines with an owner/repo@ref form: $(wc -l < "$OUT/uses.txt")"
perl -lane '
  BEGIN { %own = map { $_=>1 } qw(hyperpolymath metadatastician catachresis-colloquium stuff-of-awe); $est="/home/user/estate"; }
  my ($file,$o,$r,@rest)=@F; my $ref=pop @rest; my $path=join("",@rest); $path =~ s{^/}{};
  if ($ref =~ /^[0-9a-fA-F]{7,}$/ && length($ref)!=40) { $malformed++; push @mal,"$file $o/$r\@$ref" }
  unless ($own{lc $o}) { $third++; $third_sha++ if $ref =~ /^[0-9a-f]{40}$/i; next }
  $estate++;
  unless ($ref =~ /^[0-9a-f]{40}$/i) { $byname++; next }
  $sha++;
  my $d="$est/$o/$r"; my $moved=0;
  unless (-d "$d/.git") { for my $alt (keys %own){ if (-d "$est/$alt/$r/.git"){ $d="$est/$alt/$r"; $moved=1; last } } }
  unless (-d "$d/.git") { $norepo++; $nr{"$o/$r"}++; next }
  $movedrefs++ if $moved;
  my $k="$d $ref"; unless (exists $res{$k}) {
    my $t = (system("git -C \"$d\" cat-file -e \"$ref^{commit}\" 2>/dev/null")==0) ? "commit" : "";
    if ($t eq "") { my $hit=`git -C "$d" log --all --raw --no-abbrev --no-renames --format= 2>/dev/null | grep -m1 -F $ref`; if ($hit =~ /\t(\S+)$/) { $t="blob:$1" } }
    $res{$k}=$t; }
  my $t=$res{$k};
  if ($t eq "commit") { $commit++;
    if ($path ne "") { my $pk="$k $path"; $pres{$pk} = (system("git -C \"$d\" cat-file -e \"$ref:$path\" 2>/dev/null")==0 || `git -C "$d" ls-tree "$ref" -- "$path" 2>/dev/null` ne "") ? 1 : 0 unless exists $pres{$pk};
      unless ($pres{$pk}) { $nopath++; $np{"$o/$r/$path\@".substr($ref,0,12)}++ } } }
  elsif ($t =~ /^blob:(.*)/) { $wrongsort++; $ws{"$o/$r\@".substr($ref,0,12)." is the BLOB id of $1"}++ }
  else { $nothing++; $ur{"$o/$r\@".substr($ref,0,12)}++ }
  END {
    printf "third-party refs (not judged offline): %d (well-formed 40-hex: %d)\n", $third, $third_sha;
    printf "estate-owned refs: %d; written as a tag/branch name (undecided, clones have no tags): %d; written as 40 hex: %d\n", $estate, $byname, $sha;
    printf "  40-hex, repo not among the clones under any estate owner: %d (%d distinct repos)\n  40-hex, repo found under a DIFFERENT estate owner than written (moved, relies on redirect): %d\n", $norepo, scalar(keys %nr), $movedrefs;
    printf "  40-hex resolves to a COMMIT: %d (PATH absent at that commit: %d)\n  40-hex names an object of the WRONG SORT (a blob): %d\n  40-hex names NOTHING in the repository: %d\n", $commit, $nopath//0, $wrongsort//0, $nothing//0;
    printf "malformed hex pins (hex run not 40 chars), any owner: %d\n", $malformed//0;
    print "-- wrong-sort refs"; printf "  %4d  %s\n", $ws{$_}, $_ for sort { $ws{$b} <=> $ws{$a} } keys %ws;
    print "-- refs naming nothing"; printf "  %4d  %s\n", $ur{$_}, $_ for sort { $ur{$b} <=> $ur{$a} } keys %ur;
    print "-- repos not cloned (40-hex refs)"; my $i=0; for (sort { $nr{$b} <=> $nr{$a} } keys %nr){ printf "  %4d  %s\n", $nr{$_}, $_; last if ++$i>=10 }
  }' "$OUT/uses.txt"
