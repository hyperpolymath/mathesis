#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# List every git blob the RSR template has ever shipped at a template path.
#
# Usage: template-blobs.sh TEMPLATE_CLONE TEMPLATE_PATHS > template-blobs.txt
#   TEMPLATE_CLONE  a clone of hyperpolymath/rsr-template-repo with the full
#                   history of its default branch (not shallow)
#   TEMPLATE_PATHS  docs/catalogue/census/template-paths.txt
#
# build-rows.sh treats a file as template boilerplate only when its path is on
# the template list AND its blob is one the template shipped. A repository
# that customised a template file (as the template tells it to) keeps that
# file as its own. Path alone cannot tell the two apart.
set -euo pipefail
clone=$1 paths=$2
if [ "$(git -C "$clone" rev-parse --is-shallow-repository)" != false ]; then
  echo "template-blobs.sh: $clone is shallow; fetch its full history first" >&2
  exit 1
fi
mapfile -t list < <(grep -v '^[[:space:]]*$' "$paths")
# --raw lines read ":<mode> <mode> <old-blob> <new-blob> <status>\t<path>";
# every version a path ever had appears as some commit's new blob.
git -C "$clone" log --format= --raw --no-abbrev --no-renames HEAD -- "${list[@]}" \
  | awk '$1 ~ /^:/ && $4 !~ /^0+$/ { print $4 }' \
  | sort -u
