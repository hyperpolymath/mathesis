// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// Tests of the PROTOTYPE JSON receipt reader (proposed ADR 0005). Like the
// registry tests, they need MATHESIS_STANDARDS: a checkout of
// metadatastician/standards at READER.commit. The grades come from the pinned
// canon reader, never from this file.
//
// Falsification: JSON_RECEIPT_STUB=1 swaps the reader for a permissive stub
// that only parses JSON. Run that way, every refusal test must fail, which
// shows that each refusal comes from a rule of the reader and not from a
// broken fixture. The standing control "the permissive stub accepts every
// refusal case" checks the same thing on every run.
import {test, expect, beforeAll} from 'bun:test';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import path from 'node:path';
import {loadReader, READER} from '../../scripts/registry/claims-registry.mjs';
import {readJsonReceipt as realRead, JsonReceiptError, MAX_VALUE_OCTETS} from '../../scripts/registry/json-receipt.mjs';
import {jcs} from '../../scripts/registry/theory-ledger.mjs';

const stub = text => JSON.parse(typeof text === 'string' ? text : new TextDecoder().decode(text));
const STUBBED = process.env.JSON_RECEIPT_STUB === '1';
let readProofReceipt;
const readJson = text => (STUBBED ? stub(text) : realRead(text, readProofReceipt));
beforeAll(async () => { readProofReceipt = await loadReader(); });

const standards = rel => readFileSync(path.join(process.env.MATHESIS_STANDARDS, rel), 'utf8');
const ownReceipt = readFileSync(new URL('../../verification/receipts/theory_praxis.deed', import.meta.url), 'utf8');

// The JSON form of a record the canon reader returned: the inverse of the
// projection, used to build fixtures from real deeds. `result` has no deed
// field: a regressed receipt failed, and every other receipt passed.
const drop = o => Object.fromEntries(Object.entries(o).filter(([, v]) => v !== null && v !== undefined));
function fromRecord(rec) {
  return {
    profile: 'proof-receipt', schema_version: '1.0.0', repository: rec.repository, source_commit: rec.source_commit,
    trusted_base: rec.trusted_base,
    echoes: rec.echoes.map(e => drop({source: e.source, image: e.image, witness: e.witness, tree_sha256: e.tree_sha256,
      inputs: e.witness === 'inputs-sha256' ? Object.entries(e.inputs).map(([prover, sha256]) => ({prover, sha256})) : null})),
    claims: rec.claims.map(c => ({id: c.id, legs: c.legs.map(l => drop({prover: l.prover, route: l.route, token: l.token,
      state: l.state, reason: l.reason, receipts: l.receipts.map(r => drop({run: r.run, commit: r.commit, checker: r.checker,
        invocation: r.invocation, inputs_sha256: r['inputs-sha256'], state: r.state, reason: r.reason,
        result: r.state === 'regressed' ? 'fail' : 'pass', inputs_manifest: r.inputs_manifest, axioms: r.axioms}))}))})),
  };
}
const canon = v => jcs(v) + '\n';
const good = () => fromRecord(readProofReceipt(ownReceipt, 'theory_praxis.deed'));
// The first receipt of the first leg of the first claim (THY-1, Agda, current).
const firstReceipt = v => v.claims[0].legs[0].receipts[0];
const edit = f => { const v = good(); f(v); return canon(v); };

// ── Equivalence: the JSON route gives the canon reader's own record ─────────

test('a JSON receipt reads to the same record as its deed, for every worked receipt', () => {
  for (const [name, text] of [['theory_praxis.deed', ownReceipt],
    ['example_praxis.deed', standards('1-formats/deed/tools/fixtures/proof-receipt/example_praxis.deed')],
    ['echo_praxis.deed', standards('1-formats/deed/tools/fixtures/proof-receipt/echo_praxis.deed')]]) {
    const record = readProofReceipt(text, name);
    expect(jcs(readJson(canon(fromRecord(record))))).toBe(jcs(record));
  }
});

test('the grade is derived from the legs: a lean leg that is not RECONCILED lowers THY-1 to PWG-2i (one recheck leg)', () => {
  const v = good();
  v.claims[0].legs.find(l => l.prover === 'lean').state = 'BRIDGE-PENDING';
  const rec = readJson(canon(v));
  expect(rec.claims[0].pwg).toBe('PWG-2i');
  expect(rec.claims.slice(1).every(c => c.pwg === 'PWG-1')).toBe(true);
});

test('bytes, with or without one final LF, are accepted; the reader pin is the one in use', () => {
  const v = good();
  expect(readJson(new TextEncoder().encode(jcs(v))).claims).toHaveLength(5);
  expect(READER.commit).toMatch(/^[0-9a-f]{40}$/);
});

// ── Refusals ─────────────────────────────────────────────────────────────────
//
// Each case is valid JSON (the permissive stub parses it) with one defect.

const CASES = [
  // Not canonical: the sha256 pin needs one byte form.
  ['indented', () => JSON.stringify(good(), null, 2) + '\n', /not canonical/],
  // JSON.stringify keeps insertion order (profile, schema_version, …), which is not JCS order.
  ['keys out of order', () => JSON.stringify(good()) + '\n', /not canonical/],
  ['duplicate key', () => canon(good()).replace('{"claims":', '{"claims":[],"claims":'), /not canonical/],
  ['two final newlines', () => canon(good()) + '\n', /not canonical/],
  ['escaped ASCII', () => canon(good()).replace('"proof-receipt"', '"proof\\u002dreceipt"'), /not canonical/],
  ['byte order mark', () => '﻿' + canon(good()), /byte order mark/],
  // Unknown fields, top level and nested.
  ['unknown top field', () => edit(v => { v.note = 'x'; }), /unknown field note/],
  ['unknown receipt field', () => edit(v => { firstReceipt(v).checker_version = '2.7.0.1'; }), /unknown field checker_version/],
  ['unknown leg field', () => edit(v => { v.claims[0].legs[0].declarations = ['x']; }), /unknown field declarations/],
  // Asserted grades, anywhere.
  ['claim asserts pwg', () => edit(v => { v.claims[0].pwg = 'PWG-1'; }), /asserts a grade \(pwg\)/],
  ['claim asserts foundation_diverse', () => edit(v => { v.claims[0].foundation_diverse = 'false'; }), /asserts a grade \(foundation_diverse\)/],
  ['top asserts grades', () => edit(v => { v.grades = []; }), /asserts a grade \(grades\)/],
  ['receipt asserts pwg', () => edit(v => { firstReceipt(v).pwg = 'PWG-1'; }), /asserts a grade \(pwg\)/],
  // Short commits.
  ['short source_commit', () => edit(v => { v.source_commit = v.source_commit.slice(0, 12); }), /source_commit must be the full 40-character/],
  ['short receipt commit', () => edit(v => { firstReceipt(v).commit = firstReceipt(v).commit.slice(0, 7); }), /commit must be the full 40-character/],
  ['uppercase commit', () => edit(v => { v.source_commit = v.source_commit.toUpperCase(); }), /source_commit must be the full 40-character/],
  // Values that end in a newline, or hold any other control character.
  ['trailing newline in invocation', () => edit(v => { firstReceipt(v).invocation += '\n'; }), /control character/],
  ['trailing newline in claim id', () => edit(v => { v.claims[0].id += '\n'; }), /control character/],
  ['tab in checker', () => edit(v => { firstReceipt(v).checker += '\t'; }), /control character/],
  ['empty reason', () => edit(v => { v.claims[0].legs[0].receipts[1].reason = ' '; }), /is empty/],
  ['over-long value', () => edit(v => { firstReceipt(v).run = 'x'.repeat(MAX_VALUE_OCTETS + 1); }), /longer than/],
  // Results outside pass|fail, and results that contradict the state.
  ['result passed', () => edit(v => { firstReceipt(v).result = 'passed'; }), /must be pass or fail/],
  ['result PASS', () => edit(v => { firstReceipt(v).result = 'PASS'; }), /must be pass or fail/],
  ['result missing', () => edit(v => { delete firstReceipt(v).result; }), /missing result/],
  ['current receipt that failed', () => edit(v => { firstReceipt(v).result = 'fail'; }), /current receipt has result pass/],
  ['superseded receipt that failed', () => edit(v => { v.claims[0].legs[0].receipts[1].result = 'fail'; }), /result fail has state regressed/],
  // I-JSON, types and one form for each value.
  ['lone surrogate', () => edit(v => { firstReceipt(v).checker = 'agda \ud800'; }), /lone UTF-16 surrogate/],
  ['a number', () => edit(v => { v.claims[0].id = 1; }), /must be a string/],
  ['a boolean', () => edit(v => { v.trusted_base = true; }), /must be an array/],
  ['null optional', () => edit(v => { v.claims[0].legs[0].reason = null; }), /is null/],
  ['symbol injection', () => edit(v => { v.claims[0].legs[1].route = 're-proved :token proven'; }), /must be a symbol/],
  ['wrong profile', () => edit(v => { v.profile = 'pwg-ledger'; }), /profile must be proof-receipt/],
  // Refusals the pinned canon reader makes after the JSON layer: no coercion.
  ['uppercase token', () => edit(v => { v.claims[0].legs[0].token = 'PROVEN'; }), /:token PROVEN .* is not one of/],
  ['agda leg not source', () => edit(v => { v.claims[0].legs[0].route = 're-proved'; }), /route source belongs to the agda leg/],
  ['manifest digest', () => edit(v => { firstReceipt(v).inputs_sha256 = '0'.repeat(64); }), /is not the SHA-256 of its \(inputs-manifest/],
  ['duplicate claim id', () => edit(v => { v.claims[1].id = v.claims[0].id; }), /duplicate claim id/],
];

for (const [name, make, why] of CASES) {
  test(`refuses: ${name}`, () => {
    expect(() => readJson(make())).toThrow(why);
  });
}

test('the permissive stub accepts every refusal case (each case is a well-formed JSON text)', () => {
  for (const [name, make] of CASES) {
    const text = make().replace(/^﻿/, '');
    expect(() => stub(text), name).not.toThrow();
  }
});

test('a JSON-layer refusal is a JsonReceiptError; a reader refusal is the reader\'s', () => {
  expect(() => realRead(edit(v => { v.claims[0].pwg = 'PWG-1'; }), readProofReceipt)).toThrow(JsonReceiptError);
  try { realRead(edit(v => { v.claims[0].legs[0].token = 'PROVEN'; }), readProofReceipt); } catch (e) {
    expect(e.name).toBe('ProofReceiptError');
  }
});

// ── trope-checker's published ledger, fetched at a pinned commit ─────────────
//
// verification/pwg.json is canonical JCS, but it is an evidence ledger, not a
// §8.5.1 receipt: the reader must refuse it as it stands. Fetched, never
// vendored (AUTHORITY: receipts stay home); a failed fetch fails the test.
const TROPE = {
  url: 'https://raw.githubusercontent.com/hyperpolymath/trope-checker/0dceab68459d46b2cda22137c261023223c30e9a/verification/pwg.json',
  sha256: '3bf20a2e79eabde1b9c2d898eb7cc04e1934abeb76cebd0ee45c4f35089b5bda',
};

test('trope-checker verification/pwg.json at 0dceab6 is canonical JCS, and is refused as a receipt', async () => {
  const res = await fetch(TROPE.url);
  expect(res.ok).toBe(true);
  const bytes = new Uint8Array(await res.arrayBuffer());
  expect(createHash('sha256').update(bytes).digest('hex')).toBe(TROPE.sha256);
  const text = new TextDecoder().decode(bytes);
  expect(text).toBe(jcs(JSON.parse(text)) + '\n'); // the canonical layer already holds
  expect(() => readJson(bytes)).toThrow(/unknown field commit/);
});
