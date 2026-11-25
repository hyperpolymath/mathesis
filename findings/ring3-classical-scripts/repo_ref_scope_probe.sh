#!/usr/bin/env bash
# Read-only probe for Ring 3 candidate "closed-world scope check of repository references".
# Extracts every `<estate-owner>/<name>` token from prose and metadata (.adoc, .md, .deed, .toml, .kyaml,
# .yml outside vendored trees) and resolves it against the known universe:
#   .stats.tsv (484 cloned repos) plus the FAIL lines of .clone.log (48 names that exist but did not clone).
# A token outside that universe is UNRESOLVED here: it may be a renamed, deleted, private or invented repo.
# This says nothing about the forge; no network call is made.
# Usage: bash repo_ref_scope_probe.sh   (run from /home/user/estate)
set -euo pipefail
T=$(mktemp -d)
{ cut -f1 .stats.tsv; grep '^FAIL' .clone.log | awk '{print $2}'; } | tr 'A-Z' 'a-z' | sort -u > "$T/universe"
rg --no-messages -o -I -N \
   -g '*.adoc' -g '*.md' -g '*.deed' -g '*.toml' -g '*.kyaml' -g '*.yml' \
   -g '!**/node_modules/**' -g '!**/vendor/**' -g '!**/deps/**' -g '!**/9-archive/**' -g '!**/.lake/**' \
   -e '\b(hyperpolymath|metadatastician|catachresis-colloquium|stuff-of-awe)/[A-Za-z0-9][A-Za-z0-9_.-]*' . \
 | sed -E 's/[.]+$//; s/\.git$//' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn > "$T/mentions"
awk '{print $2}' "$T/mentions" | sort -u > "$T/names"
comm -23 "$T/names" "$T/universe" > "$T/unresolved"
echo "distinct owner/name tokens mentioned: $(wc -l < "$T/names")"
echo "resolve to a known repo:              $(comm -12 "$T/names" "$T/universe" | wc -l)"
echo "unresolved against the known universe: $(wc -l < "$T/unresolved")"
echo "mentions (occurrences) of unresolved names: $(awk 'NR==FNR{u[$1]=1;next} ($2 in u){s+=$1} END{print s+0}' "$T/unresolved" "$T/mentions")"
echo "total mentions: $(awk '{s+=$1} END{print s}' "$T/mentions")"
echo "--- top unresolved by mention count"
awk 'NR==FNR{u[$1]=1;next} ($2 in u)' "$T/unresolved" "$T/mentions" | head -40
