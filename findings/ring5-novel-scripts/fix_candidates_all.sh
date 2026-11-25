#!/usr/bin/env bash
# Every fix-worded HEAD non-merge commit whose workflow-dir footprint is exactly one top-level workflow yml (+ optional actions.lock).
r="$1"
git -C "/home/user/estate/$r" log HEAD --no-merges --no-renames --name-only --format='@@%H%x09%cs%x09%s' -- .github/workflows 2>/dev/null | awk -v repo="$r" -F'\t' '
function flush() { if (h!="" && fix && n==1) print repo "\t" h "\t" d "\t" f "\t" s }
/^@@/ { flush(); h=substr($1,3); d=$2; s=$3; fix=(tolower(s) ~ /^fix|fix\(/); n=0; f=""; next }
NF==0 { next }
$0 ~ /^\.github\/workflows\/actions\.lock$/ { next }
$0 ~ /^\.github\/workflows\/[^\/]+\.ya?ml$/ { n++; f=$0; next }
END { flush() }'
