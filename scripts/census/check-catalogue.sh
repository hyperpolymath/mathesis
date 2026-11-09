#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
source "$here/snapshot.sh"
snapshot_lock
if [ "${1:-}" = --write ]; then
  snapshot_stage
  snapshot_publish
  exit
fi
bash "$here/render-catalogue.sh" --staged "$catalogue/census" | diff -u "$catalogue/catalogue.adoc" -
