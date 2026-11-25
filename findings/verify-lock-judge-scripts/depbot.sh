#!/usr/bin/env bash
# For each repo with actions.lock at HEAD: list dependabot commits touching workflow yml; flag whether actions.lock touched too.
set -uo pipefail
EST=/home/user/estate
while read -r repo; do
  d="$EST/$repo"
  # first commit date that added actions.lock
  first=$(git -C "$d" log --diff-filter=A --format=%cI --reverse -- .github/workflows/actions.lock 2>/dev/null | head -1)
  [ -n "$first" ] || continue
  git -C "$d" log --since="$first" --author='dependabot' --format='@@%H %cI' --name-only -- .github/workflows 2>/dev/null | awk -v repo="$repo" '
    /^@@/ { if (h!="") print repo"\t"dt"\t"h"\t"yml"\t"lock; split($0,a," "); h=substr(a[1],3); dt=a[2]; yml=0; lock=0; next }
    /actions\.lock$/ { lock=1; next }
    /\.ya?ml$/ { yml=1 }
    END { if (h!="") print repo"\t"dt"\t"h"\t"yml"\t"lock }'
done < /tmp/v6/lockrepos.txt
