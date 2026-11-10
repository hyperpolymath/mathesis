#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# The census must see proofs written in Rust (PROOF-POLICY §1.2: Creusot with
# Pearlite contracts, and Verus), and must prefer a repository's proof-status
# page over its debt ledger.
#
# Builds a throwaway git repository with:
#   kernel/   a crate that depends on creusot-std: two functions carry
#             contracts (one in the cfg_attr form), one is #[trusted] in the
#             cfg_attr form, and one carries no contract;
#   checked/  a crate that depends on vstd: a verus! block with a proof fn, a
#             spec fn and an exec fn with an ensures clause, plus an
#             #[verifier::external_body] escape;
#   plain/    a crate with no verifier dependency, whose file mentions
#             `ensures` in a comment: it must not be counted;
#   docs/status/PROOF-STATUS.adoc and crates/CREUSOT-PROOF-DEBT.tsv: the
#             status page must win over the debt file.
# then runs census-repo.sh and build-rows.sh against it over file://.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
census=$here/../../scripts/census
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail() { echo "census_rust_test: FAIL: $*" >&2; exit 1; }

src=$work/forge/fixture/rusty
mkdir -p "$src/kernel/src" "$src/checked/src" "$src/plain/src" "$src/docs/status" "$src/crates"
cat > "$src/Cargo.toml" <<'EOF'
[workspace]
members = ["kernel", "checked", "plain"]
[workspace.dependencies]
creusot-std = "0.14"
EOF
cat > "$src/kernel/Cargo.toml" <<'EOF'
[package]
name = "kernel"
[dependencies]
creusot-std = { workspace = true }
EOF
cat > "$src/kernel/src/lib.rs" <<'EOF'
#[cfg_attr(creusot, creusot_std::macros::requires(x@ <= 10))]
#[cfg_attr(creusot, creusot_std::macros::ensures(result@ == x@ + 1))]
pub fn succ(x: u32) -> u32 {
    x + 1
}

#[ensures(result == a)]
fn id(a: u8) -> u8 {
    a
}

#[cfg_attr(creusot, creusot_std::macros::trusted)]
pub fn as_float(x: u32) -> f64 {
    f64::from(x)
}

pub fn uncontracted(x: u32) -> u32 {
    x
}
EOF
cat > "$src/checked/Cargo.toml" <<'EOF'
[package]
name = "checked"
[dependencies]
vstd = "0.0.0"
EOF
cat > "$src/checked/src/lib.rs" <<'EOF'
use vstd::prelude::*;
verus! {
spec fn double(x: nat) -> nat { x + x }
proof fn double_is_even(x: nat)
    ensures double(x) % 2 == 0,
{
}
fn add_one(x: u8) -> (r: u8)
    requires x < 255,
    ensures r == x + 1,
{
    x + 1
}
#[verifier::external_body]
fn opaque() {}
}
EOF
cat > "$src/plain/Cargo.toml" <<'EOF'
[package]
name = "plain"
[dependencies]
serde = "1"
EOF
cat > "$src/plain/src/lib.rs" <<'EOF'
// This ensures nothing: an ordinary crate with no verifier.
pub fn f() {}
EOF
echo '= Proof status' > "$src/docs/status/PROOF-STATUS.adoc"
printf 'PD-01\tkernel/src/lib.rs\tas_float\ttrusted\n' > "$src/crates/CREUSOT-PROOF-DEBT.tsv"
git -C "$src" init -q
git -C "$src" add -A
git -C "$src" -c user.name=t -c user.email=t@example.invalid commit -q -m fixture
git -C "$src" config uploadpack.allowFilter true

data=$work/data
MATHESIS_DATA=$data MATHESIS_GIT_BASE="file://$work/forge" \
  bash "$census/census-repo.sh" fixture/rusty
o=$data/out/fixture__rusty
[ -s "$o.files.jsonl" ] || fail "no files.jsonl: the Rust proofs were not found"

files=$(jq -r '[.path,.ext]|@tsv' "$o.files.jsonl" | sort)
expected=$(printf 'checked/src/lib.rs\trs-verus\nkernel/src/lib.rs\trs-creusot')
[ "$files" = "$expected" ] || fail "files were
$files
expected
$expected"

decls=$(jq -r '[.file,.kind,.name]|@tsv' "$o.decls.jsonl" | sort)
expected=$(printf 'checked/src/lib.rs\tcontract\tadd_one\nchecked/src/lib.rs\tproof\tdouble_is_even\nchecked/src/lib.rs\tspec\tdouble\nkernel/src/lib.rs\tcontract\tid\nkernel/src/lib.rs\tcontract\tsucc')
[ "$decls" = "$expected" ] || fail "declarations were
$decls
expected
$expected"

holes=$(jq -r '[.file,.lang,.class,.marker]|@tsv' "$o.holes.jsonl" | sort)
expected=$(printf 'checked/src/lib.rs\tverus\taxiom\texternal_body\nkernel/src/lib.rs\tcreusot\taxiom\t#[trusted]')
[ "$holes" = "$expected" ] || fail "holes were
$holes
expected
$expected"

jq -r '.path' "$o.status.jsonl" | grep -qx 'docs/status/PROOF-STATUS.adoc' \
  || fail "the PROOF-STATUS page was not recognised as a status doc"
jq -r '.path' "$o.status.jsonl" | grep -qx 'crates/CREUSOT-PROOF-DEBT.tsv' \
  || fail "the debt ledger CREUSOT-PROOF-DEBT.tsv was not recognised as a status doc"

# Fold into a catalogue row the way run-census.sh does.
: > "$data/repos.jsonl"; echo fixture/rusty > "$data/census-list.txt"
MATHESIS_DATA=$data bash "$census/summarise.sh" >/dev/null
: > "$work/template-paths.txt"
row=$(bash "$census/build-rows.sh" "$data" "$work/template-paths.txt" | jq -c '.[0]')
[ "$(jq -r .provers <<<"$row")" = "creusot 1, verus 1" ] || fail "provers: $row"
[ "$(jq -r .class <<<"$row")" = "engineering" ] || fail "class: $row"
[ "$(jq -r .declarations <<<"$row")" = "5" ] || fail "declarations: $row"
[ "$(jq -r .axioms <<<"$row")" = "2" ] || fail "axioms: $row"
[ "$(jq -r .status_doc <<<"$row")" = "docs/status/PROOF-STATUS.adoc" ] || fail "status_doc: $row"

# Status-doc ranking, on build-rows.sh alone: a nested sub-project's status
# page (two or more directories deep) must not displace the
# repository's own top-level needs list, as it did for developer-ecosystem.
raw=$work/raw-ranking
mkdir -p "$raw"
printf '%s\n' '{"ext":"idr","path":"src/A.idr","repo":"x/nested"}' > "$raw/files.jsonl"
: > "$raw/holes.jsonl"; : > "$raw/decls.jsonl"
printf '%s\n' \
  '{"path":"PROOF-NEEDS.adoc","repo":"x/nested"}' \
  '{"path":"ecosystem/sub/PROOF-STATUS.adoc","repo":"x/nested"}' \
  > "$raw/repos-with-status.jsonl"
doc=$(bash "$census/build-rows.sh" "$raw" "$work/template-paths.txt" | jq -r '.[0].status_doc')
[ "$doc" = "PROOF-NEEDS.adoc" ] || fail "nested status page won over the top-level needs list: $doc"

# A repository's own one-level layout (standards keeps its needs list in
# 3-practice/) is not a nested sub-project: its needs list beats a debt
# ledger nested two directories deep, which would otherwise rank first.
printf '%s\n' \
  '{"path":"3-practice/PROOF-NEEDS.adoc","repo":"x/nested"}' \
  '{"path":"crates/sub/proof-debt.adoc","repo":"x/nested"}' \
  > "$raw/repos-with-status.jsonl"
doc=$(bash "$census/build-rows.sh" "$raw" "$work/template-paths.txt" | jq -r '.[0].status_doc')
[ "$doc" = "3-practice/PROOF-NEEDS.adoc" ] || fail "a one-level needs list lost to a nested debt ledger: $doc"

echo "census_rust_test: ok (Creusot and Verus files, contracts, escapes and the status page all found)"
