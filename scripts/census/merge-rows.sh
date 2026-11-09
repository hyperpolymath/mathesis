#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Merge a partial census into committed census data, per repository.
#
# Usage: merge-rows.sh [--sorted] COMMITTED NEW SCOPE > merged.json
#   COMMITTED  committed I-JSON array whose records carry a .repo key
#              (catalogue-rows.json, unreachable.json or provenance.json)
#   NEW        array of records produced by this run (same shape)
#   SCOPE      one OWNER/REPO per line: the repositories this run censused
#
# Every committed record whose repo is in SCOPE is dropped, then every NEW
# record whose repo is in SCOPE is added. A scoped repo with no new record
# (it now has no own proof files, or is reachable again) therefore leaves no
# record, exactly as a full census would. Records for repositories outside
# SCOPE are kept byte-for-byte. NEW records outside SCOPE are ignored.
#
# --sorted: the file is defined as sorted by .repo (catalogue-rows.json and
#   provenance.json); the result is sorted by .repo.
# Without it, committed records keep their order and added records follow,
#   sorted by .repo (unreachable.json keeps its census order this way).
#
# Fails closed: unreadable or non-array input, a record without a string
# .repo, a duplicate repo in either input, or an empty SCOPE is an error.
set -euo pipefail
sorted=false
if [ "${1:-}" = --sorted ]; then sorted=true; shift; fi
[ $# -eq 3 ] || { echo "usage: merge-rows.sh [--sorted] COMMITTED NEW SCOPE" >&2; exit 2; }
committed=$1 new=$2 scope=$3

jq -n --argjson sorted "$sorted" \
  --slurpfile C "$committed" --slurpfile N "$new" --rawfile S "$scope" '
  def checked(name):
    if type != "array" then error(name + ": not a JSON array") else . end
    | if any(.[]; (.repo | type) != "string") then error(name + ": record without a string repo") else . end
    | if (map(.repo) | length) != (map(.repo) | unique | length) then error(name + ": duplicate repo") else . end;
  ($S | split("\n") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0))) as $scope
  | if ($scope | length) == 0 then error("scope: empty") else . end
  | ($C[0] | checked("committed")) as $c
  | ($N[0] | checked("new")) as $n
  | ($c | map(select(.repo as $r | $scope | index($r) | not))) as $kept
  | ($n | map(select(.repo as $r | $scope | index($r))) | sort_by(.repo)) as $added
  | if $sorted then ($kept + $added | sort_by(.repo)) else ($kept + $added) end
' | jq -cS .
