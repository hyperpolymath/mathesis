#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
#
# build-rows.sh picks one proof-status document per repository.  A
# PROOF-STATUS file (the PROOF-POLICY §8.5 per-claim record) must win over
# PROOF-NEEDS and proof-debt, even where its path sorts later; without
# PROOF-STATUS, PROOF-NEEDS wins over proof-debt; within a kind, the first
# path in byte order (LC_ALL=C) wins.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
fail=0

printf '%s\n' \
  '{"ext":"agda","path":"A.agda","repo":"a/needs-sorts-first"}' \
  '{"ext":"agda","path":"A.agda","repo":"b/needs-over-debt"}' \
  '{"ext":"agda","path":"A.agda","repo":"c/debt-only"}' \
  '{"ext":"agda","path":"A.agda","repo":"d/two-status"}' > "$work/files.jsonl"
printf '%s\n' \
  '{"path":"docs/status/PROOF-NEEDS.adoc","repo":"a/needs-sorts-first"}' \
  '{"path":"docs/status/PROOF-STATUS.adoc","repo":"a/needs-sorts-first"}' \
  '{"path":"proof-debt.adoc","repo":"b/needs-over-debt"}' \
  '{"path":"docs/PROOF-NEEDS.adoc","repo":"b/needs-over-debt"}' \
  '{"path":"proofs/proof-debt.md","repo":"c/debt-only"}' \
  '{"path":"docs/status/PROOF-STATUS.adoc","repo":"d/two-status"}' \
  '{"path":"PROOF-STATUS.adoc","repo":"d/two-status"}' > "$work/repos-with-status.jsonl"
: > "$work/holes.jsonl"; : > "$work/decls.jsonl"
# A template list that matches nothing (an empty file would make build-rows'
# NR==FNR idiom swallow the first real input).
echo 'no/such/template/path' > "$work/template-paths.txt"

rows="$(bash "$root/scripts/census/build-rows.sh" "$work" "$work/template-paths.txt")"
expect() {
  local repo="$1" want="$2" got
  got="$(jq -r --arg r "$repo" '.[] | select(.repo == $r) | .status_doc' <<< "$rows")"
  if [ "$got" = "$want" ]; then
    echo "PASS: $repo -> $want"
  else
    echo "FAIL: $repo -> got '$got', want '$want'" >&2
    fail=1
  fi
}
expect a/needs-sorts-first docs/status/PROOF-STATUS.adoc
expect b/needs-over-debt   docs/PROOF-NEEDS.adoc
expect c/debt-only         proofs/proof-debt.md
expect d/two-status        PROOF-STATUS.adoc

(( fail == 0 )) && echo 'PASS: build-rows status-document preference' || exit 1
