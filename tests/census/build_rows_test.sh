#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# build-rows.sh: a template file counts as boilerplate only when its (path,
# blob) is one the template shipped; a customised copy is the repository's own.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
build=$here/../../scripts/census/build-rows.sh
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0 fail=0
check() { local msg=$1; shift; if "$@"; then pass=$((pass + 1)); else echo "FAIL: $msg"; fail=$((fail + 1)); fi; }

printf 'src/Abi/Types.idr\nsrc/Abi/Layout.idr\n' > "$T/paths.txt"
printf 'src/Abi/Types.idr\tb1\nsrc/Abi/Layout.idr\tb2\n' > "$T/template.tsv"
R=$T/raw; mkdir -p "$R"
cat > "$R/files.jsonl" <<'EOF'
{"blob":"b9","ext":"idr","path":"src/Abi/Types.idr","repo":"x/custom"}
{"blob":"b2","ext":"idr","path":"src/Abi/Layout.idr","repo":"x/custom"}
{"blob":"b7","ext":"agda","path":"proofs/Extra.agda","repo":"x/custom"}
{"blob":"b1","ext":"idr","path":"src/Abi/Types.idr","repo":"x/pristine"}
{"ext":"idr","path":"src/Abi/Types.idr","repo":"x/old"}
{"blob":"b1","ext":"idr","path":"src/Abi/Types.idr","repo":"hyperpolymath/rsr-template-repo"}
EOF
cat > "$R/holes.jsonl" <<'EOF'
{"class":"hole","file":"src/Abi/Types.idr","repo":"x/custom"}
{"class":"hole","file":"src/Abi/Layout.idr","repo":"x/custom"}
{"class":"hole","file":"src/Abi/Types.idr","repo":"x/pristine"}
EOF
cat > "$R/decls.jsonl" <<'EOF'
{"file":"src/Abi/Types.idr","repo":"x/custom"}
{"file":"src/Abi/Types.idr","repo":"x/custom"}
{"file":"src/Abi/Layout.idr","repo":"x/custom"}
{"file":"proofs/Extra.agda","repo":"x/custom"}
{"file":"src/Abi/Types.idr","repo":"x/pristine"}
EOF
: > "$R/repos-with-status.jsonl"

out=$(bash "$build" "$R" "$T/template.tsv")
row() { jq -c --arg r "$1" 'select(.repo == $r)' <<<"$out"; }
check "customised Types.idr is own (2 own files)" [ "$(row x/custom | jq .own_files)" = 2 ]
check "customised repo provers" [ "$(row x/custom | jq -r .provers)" = "agda 1, idris2 1" ]
check "hole in the customised file counts, the boilerplate one does not" [ "$(row x/custom | jq .holes)" = 1 ]
check "declarations: 2 in Types.idr + 1 in Extra.agda" [ "$(row x/custom | jq .declarations)" = 3 ]
check "pristine template copy yields no row" [ -z "$(row x/pristine)" ]
check "a file with no recorded blob falls back to its path" [ -z "$(row x/old)" ]
check "the template repository owns its template files" [ "$(row hyperpolymath/rsr-template-repo | jq .own_files)" = 1 ]

# With a plain path list the path alone decides, as before.
out=$(bash "$build" "$R" "$T/paths.txt")
check "path-only mode: only Extra.agda is own" [ "$(row x/custom | jq .own_files)" = 1 ]
check "path-only mode: no template-path hole counts" [ "$(row x/custom | jq .holes)" = 0 ]

echo "build-rows tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
