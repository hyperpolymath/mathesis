#!/usr/bin/env bash
set -uo pipefail
EST=/home/user/estate
while read -r repo; do
  d="$EST/$repo"
  git -C "$d" log --no-merges --full-diff --format='@@%H%x09%cI%x09%an%x09%s' --name-only -- .github/workflows/actions.lock 2>/dev/null | awk -v repo="$repo" -F'\t' '
    function flush() { if (h!="") print repo"\t"dt"\t"an"\t"n"\t"wf"\t"other"\t"s }
    /^@@/ { flush(); h=substr($1,3); dt=$2; an=$3; s=$4; n=0; wf=0; other=0; next }
    NF==0 {next}
    { n++; if ($0 ~ /^\.github\/workflows\/.*\.ya?ml$/) wf++; else if ($0 !~ /actions\.lock$/) other++ }
    END { flush() }'
done < /tmp/v6/lockrepos.txt
