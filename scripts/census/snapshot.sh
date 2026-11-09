#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Shared publication protocol. Lock lives outside the exchanged directory.
# Requires flock and GNU mv with --exchange and --no-copy (no unsafe fallback).
snapshot_lock() {
  catalogue=$(cd "$here/../../docs/catalogue" && pwd)
  exec {snapshot_fd}>"${catalogue%/*}/.catalogue.lock"
  flock -x "$snapshot_fd"
}

snapshot_stage() {
  stage=$(mktemp -d "${catalogue%/*}/.catalogue-stage.XXXXXX")
  trap 'rm -rf -- "${stage:-}"' EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  cp -a "$catalogue/." "$stage/"
}

snapshot_publish() {
  local file
  for file in catalogue-rows unreachable repos; do
    jq -e 'type == "array"' "$stage/census/$file.json" >/dev/null
  done
  if [ -f "$stage/census/refreshed.json" ]; then
    jq -e 'type == "array"' "$stage/census/refreshed.json" >/dev/null
  fi
  bash "$here/render-catalogue.sh" --staged "$stage/census" > "$stage/catalogue.adoc"
  test -s "$stage/catalogue.adoc"
  # One rename exchange installs all outputs. On failure nothing is published;
  # on interruption either complete directory remains at the public path.
  mv --exchange --no-copy -T "$stage" "$catalogue"
  # stage now holds the previous snapshot; EXIT removes it while still locked.
}
