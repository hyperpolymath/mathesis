#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
#
# PR #87: silence automatic status/issue comments while preserving docstrings.
# Usage: bash tests/workflows/coderabbit_config_test.sh
# Requires Bun; reads local configuration only, with no API calls.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
command -v bun >/dev/null 2>&1 || { echo 'FAIL: Bun is required' >&2; exit 1; }

bun run - "$REPO_DIR" <<'JS'
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const config = Bun.YAML.parse(
  readFileSync(resolve(process.argv[2], ".coderabbit.yaml"), "utf8")
);

// Strict equality requires an explicit YAML boolean: missing keys, null,
// quoted "false", and true must all fail instead of restoring vendor defaults
// or passing through JavaScript truthiness.
assert.equal(config?.reviews?.review_status, false,
  "review status comments must be explicitly disabled");
console.log("PASS: review status comments are disabled with a boolean");

assert.equal(config?.issue_enrichment?.auto_enrich?.enabled, false,
  "automatic Issue Planner comments must be explicitly disabled");
console.log("PASS: automatic issue enrichment is disabled with a boolean");

// These guards catch disabling docstring checks or finishing touches while
// silencing comments: the PR explicitly preserves their existing behavior.
assert.equal(config?.reviews?.pre_merge_checks?.docstrings?.mode, "warning",
  "docstring coverage must remain a warning, not a blocking error or off");
console.log("PASS: docstring coverage remains a warning");

assert.equal(config?.reviews?.pre_merge_checks?.docstrings?.threshold, 80,
  "docstring coverage must retain its numeric 80 percent threshold");
console.log("PASS: docstring coverage threshold remains numeric 80");

assert.equal(config?.reviews?.finishing_touches?.docstrings?.enabled, true,
  "docstring finishing touches must remain explicitly enabled");
console.log("PASS: docstring finishing touches remain enabled");
JS
