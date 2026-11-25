#!/bin/bash
# per repo: hash, parents, author, email, trailers(coauthor), subject
repo="$1"; d=/home/user/estate/$repo
git -C "$d" log --all --format='%H%x09%P%x09%an%x09%ae%x09%(trailers:key=Co-Authored-By,valueonly,separator=;)%x09%s' 2>/dev/null | tr -d '\r' | awk -F'\t' -v r="$repo" 'NF>=6{n=split($2,p," "); print r"\t"$1"\t"n"\t"$3"\t"$4"\t"$5"\t"$6}'
