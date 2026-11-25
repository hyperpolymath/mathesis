#!/usr/bin/env bash
# Dependabot commits on HEAD that change a top-level workflow yml: was actions.lock present in that commit's tree,
# and did the commit also change it? (tree-level only)
r="$1"; d="/home/user/estate/$r"
git -C "$d" log HEAD --no-merges --no-renames --author='dependabot' --name-only --format='@@%H' -- .github/workflows 2>/dev/null | awk '
/^@@/ { if (h!="") print h "\t" wf "\t" lk; h=substr($0,3); wf=0; lk=0; next }
/^\.github\/workflows\/actions\.lock$/ { lk=1; next }
/^\.github\/workflows\/[^\/]+\.ya?ml$/ { wf=1 }
END { if (h!="") print h "\t" wf "\t" lk }' | while IFS=$'\t' read h wf lk; do
  [ "$wf" = 1 ] || continue
  if [ -n "$(git -C "$d" ls-tree "$h" -- .github/workflows/actions.lock)" ]; then has=1; else has=0; fi
  printf '%s\t%s\t%s\t%s\n' "$r" "$h" "$has" "$lk"
done
