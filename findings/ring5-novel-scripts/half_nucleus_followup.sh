#!/usr/bin/env bash
# For each half-nucleus commit (dependabot changed workflow yml, lock present and untouched): does one of the next 10 HEAD
# commits in that repo change actions.lock?  (tree-level only)
r="$1"; d="/home/user/estate/$r"
grep -P "^\Q$r\E\t" /tmp/r5/half_nucleus.tsv | awk -F'\t' '$3==1 && $4==0 {print $2}' > "/tmp/r5/hn.$$" || true
[ -s "/tmp/r5/hn.$$" ] || { rm -f "/tmp/r5/hn.$$"; exit 0; }
git -C "$d" log HEAD --no-merges --no-renames --reverse --name-only --format='@@%H%x09%an' 2>/dev/null | awk -v repo="$r" -v hn="/tmp/r5/hn.$$" -F'\t' '
BEGIN { while ((getline l < hn) > 0) H[l]=1 }
/^@@/ { n++; id[n]=substr($1,3); bot[n]=($2 ~ /dependabot/); next }
$0 == ".github/workflows/actions.lock" { lk[n]=1 }
END { for (i=1;i<=n;i++) if (id[i] in H) { f=0; fb=0; for (j=i+1;j<=i+10&&j<=n;j++) if (lk[j]) { f=1; if (!bot[j]) fb=1; break } print repo "\t" id[i] "\t" f "\t" fb } }'
rm -f "/tmp/r5/hn.$$"
