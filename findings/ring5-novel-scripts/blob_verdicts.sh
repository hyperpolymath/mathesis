#!/usr/bin/env bash
# Per repo (HEAD, first-parent, no renames; tree-level only, no blob fetch):
#   E = sum over commits of the number of top-level workflow yml files in the tree   (full-tree per-push evaluation)
#   C = number of (commit,file) add/modify events for those files                   (per-repo incremental evaluation)
#   blobs: every post-image blob id (for the estate-wide distinct count D)
r="$1"
git -C "/home/user/estate/$r" log --first-parent --reverse --no-renames --raw --no-abbrev --format='tformat:@@%H' HEAD 2>/dev/null | awk -v repo="$r" '
/^@@/ { if (seen) E += n; seen=1; next }
/^:/ { split($0, a, "\t"); path=a[2]; if (path !~ /^\.github\/workflows\/[^\/]+\.ya?ml$/) next;
       split(a[1], m, " "); st=m[5]; nb=m[4];
       if (st=="A") { n++; C++; print "B\t" nb }
       else if (st=="D") { n-- }
       else { C++; print "B\t" nb } }
END { if (seen) E += n; print "R\t" repo "\t" E+0 "\t" C+0 "\t" n+0 }'
