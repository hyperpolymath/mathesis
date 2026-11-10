#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Every blob the RSR template has ever had at its proof-file paths.
#
# Usage: template-blobs.sh TEMPLATE_PATHS [OWNER/REPO] > template-blobs.tsv
#   TEMPLATE_PATHS  one path per line: proof files the RSR template ships
#   OWNER/REPO      the template repository (default hyperpolymath/rsr-template-repo)
#
# Output: one "path<TAB>blob" line per (path, git blob id) the template has
# held at any commit on any ref, sorted. build-rows.sh treats a repository's
# file as template boilerplate only when its own (path, blob) is on this list.
#
# Why blobs and not paths: a repository that rewrites a template file in place
# (the RSR template's ABI seam, src/interface/Abi/*.idr, is meant to be
# replaced) keeps the path but not the content, and is doing exactly the work
# the census exists to find. Matching every historical blob, not only the
# current one, also keeps an untouched copy of an older template version
# classed as boilerplate. Template proof files carry no {{…}} mint tokens, so
# a mint copies them byte for byte.
#
# The clone is blobless and fetches commits and trees only.
set -euo pipefail
T=${1:?usage: template-blobs.sh TEMPLATE_PATHS [OWNER/REPO]}
REPO=${2:-hyperpolymath/rsr-template-repo}
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
git clone -q --filter=blob:none --no-checkout "https://github.com/$REPO" "$work/t"
mapfile -t paths < <(grep -v '^[[:space:]]*$' "$T")
git -C "$work/t" log --all --format= --raw --no-abbrev --no-renames -- "${paths[@]}" \
  | awk -F'\t' '{ split($1, f, " "); if (f[4] !~ /^0+$/) print $2 "\t" f[4] }' \
  | LC_ALL=C sort -u
