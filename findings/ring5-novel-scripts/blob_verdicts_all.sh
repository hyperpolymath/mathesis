#!/usr/bin/env bash
# As blob_verdicts.sh, but for every regular file (mode 100644/100755), excluding nothing. Tree-level only.
r="$1"
git -C "/home/user/estate/$r" log --first-parent --reverse --no-renames --raw --no-abbrev --format='tformat:@@%H' HEAD 2>/dev/null | awk -v repo="$r" '
/^@@/ { if (seen) E += n; seen=1; next }
/^:/ { split($0, a, "\t"); split(a[1], m, " "); st=m[5]; nb=m[4]; nm=m[2];
       if (nm ~ /^160000|^120000/) next;
       if (st=="A") { n++; C++; print "B\t" nb }
       else if (st=="D") { if (m[1] !~ /160000|120000/) n-- }
       else { C++; print "B\t" nb } }
END { if (seen) E += n; print "R\t" repo "\t" E+0 "\t" C+0 "\t" n+0 }'
