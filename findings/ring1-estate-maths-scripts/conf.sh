#!/usr/bin/env bash
r="$1"
git -C "/home/user/estate/$r" log --all --no-renames --name-only --format='@@%H%x09%s' 2>/dev/null | awk -v repo="$r" '
/^@@/ { keep = (tolower($0) ~ /((resolv|fix|repair)[a-z]*[^\t]*conflict|conflict marker|merge clash)/); h=$0; next }
NF>0 && keep { print repo "\t" h "\t" $0 }'
