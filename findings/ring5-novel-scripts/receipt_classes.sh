#!/usr/bin/env bash
# For a repo and a list of manifest paths: how many HEAD first-parent commits fall in how many footprint classes
# (class = tuple of git blob ids of the manifest paths; tree-level only, no blob fetch).
repo="$1"; shift
git -C "$repo" log --first-parent --format='%H %cs' HEAD | while read c d; do
  k=$(git -C "$repo" ls-tree "$c" -- "$@" | awk '{print $3}' | tr '\n' ',' )
  echo "$d $c $k"
done
