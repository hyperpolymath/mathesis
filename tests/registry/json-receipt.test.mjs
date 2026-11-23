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
const nonEmpty = a => (a && a.length ? a : null);
const receiptJson = r => drop({run: r.run, commit: r.commit, checker: r.checker,
  invocation: r.invocation, inputs_sha256: r['inputs-sha256'], state: r.state, reason: r.reason,
  result: r.state === 'regressed' ? 'fail' : 'pass', image: r.image, inputs_manifest: r.inputs_manifest,
  imports: nonEmpty((r.imports ?? []).map(i => ({repository: i.repository, commit: i.commit, inputs_sha256: i['inputs-sha256'], files: i.files}))),
  axioms: r.axioms});
function fromRecord(rec) {
  return {
    profile: 'proof-receipt', schema_version: '1.0.0', repository: rec.repository, source_commit: rec.source_commit,
    trusted_base: rec.trusted_base,
    echoes: rec.echoes.map(e => drop({source: e.source, image: e.image, witness: e.witness, tree_sha256: e.tree_sha256,
      inputs: e.witness === 'inputs-sha256' ? Object.entries(e.inputs).map(([prover, sha256]) => ({prover, sha256})) : null})),
    claims: rec.claims.map(c => drop({id: c.id, legs: c.legs.map(l => drop({prover: l.prover, route: l.route, token: l.token,
      state: l.state, reason: l.reason, receipts: l.receipts.map(receiptJson)})),
      controls: nonEmpty((c.controls ?? []).map(k => ({path: k.path, prover: k.prover, expect: k.expect, receipts: k.receipts.map(receiptJson)})))})),
  };
}
const canon = v => jcs(v) + '\n';
const good = () => fromRecord(readProofReceipt(ownReceipt, 'theory_praxis.deed'));
// The first receipt of the first leg of the first claim (THY-1, Agda, current).
const firstReceipt = v => v.claims[0].legs[0].receipts[0];
const edit = f => { const v = good(); f(v); return canon(v); };

// The worked echo example with an (import …) on its current Agda receipt and a
// (control …) on its claim (§8.5.1, §8.5.4), digests computed, not invented.
const sha = t => createHash('sha256').update(t).digest('hex');
function withImportAndControl(example) {
  const file = (p, h) => `(file :path "${p}" :sha256 "${h}")`;
  const lib = [['src/Lib.agda', 'd'.repeat(64)]];
  const libDigest = sha(lib.map(([p, h]) => `${h}  ${p}\n`).join(''));
  const ctl = [['controls/Bad.agda', 'e'.repeat(64)]];
  const ctlDigest = sha(ctl.map(([p, h]) => `${h}  ${p}\n`).join(''));
  const imp = `(import :repository "hyperpolymath/lib" :commit "${'2'.repeat(40)}" :inputs-sha256 "${libDigest}" ${file(...lib[0])})`;
  const control = `(control :path "controls/Bad.agda" :prover agda :expect refused\n` +
    `  (receipt :run "https://example.invalid/run/9" :commit "${'1'.repeat(40)}" :checker "agda 2.6.4.3"\n` +
    `    :invocation "agda --safe --without-K --cubical-compatible controls/Bad.agda" :inputs-sha256 "${ctlDigest}" :state current\n` +
    `    (inputs-manifest ${file(...ctl[0])}) (axioms)))`;
  // The first (axioms …) closes the current Agda receipt: the import goes before it.
  const at = example.indexOf('(axioms');
  let out = example.slice(0, at) + imp + '\n' + example.slice(at);
  const leg = out.indexOf('(leg :prover rocq');
  return out.slice(0, leg) + control + '\n    ' + out.slice(leg);
}

// ── Equivalence: the JSON route gives the canon reader's own record ─────────

test('a JSON receipt reads to the same record as its deed, for every worked receipt', () => {
  for (const [name, text] of [['theory_praxis.deed', ownReceipt],
    ['example_praxis.deed', standards('1-formats/deed/tools/fixtures/proof-receipt/example_praxis.deed')],
    ['echo_praxis.deed', standards('1-formats/deed/tools/fixtures/proof-receipt/echo_praxis.deed')],
    ['import_control_praxis.deed', withImportAndControl(standards('1-formats/deed/tools/fixtures/proof-receipt/echo_praxis.deed'))]]) {
    const record = readProofReceipt(text, name);
    expect(jcs(readJson(canon(fromRecord(record))))).toBe(jcs(record));
  }
});

test('the import-and-control deed really carries an import, a control and an image', () => {
  const rec = readProofReceipt(withImportAndControl(standards('1-formats/deed/tools/fixtures/proof-receipt/echo_praxis.deed')), 'ic_praxis.deed');
  const v = fromRecord(rec);
  expect(v.claims[0].controls).toHaveLength(1);
  expect(v.claims[0].legs[0].receipts[0].imports).toHaveLength(1);
  expect(v.claims[0].legs[0].receipts[0].image).toMatch(/@sha256:[0-9a-f]{64}$/);
  // Dropping the image loses PWG-1: the JSON form must carry it (§8.2, owner ruling 2026-11-16).
  for (const l of v.claims[0].legs) for (const r of l.receipts) delete r.image;
  expect(readJson(canon(v)).claims[0].pwg).toBe('PWG-2ii');
});

test('the grade is derived from the legs: a lean leg that is not RECONCILED lowers THY-1 to PWG-2i (one recheck leg)', () => {
  const v = good();
  v.claims[0].legs.find(l => l.prover === 'lean').state = 'BRIDGE-PENDING';
  const rec = readJson(canon(v));
  expect(rec.claims[0].pwg).toBe('PWG-2i');
  // The other claims keep whatever the canon reader derives from the deed itself,
  // so this test does not hard-code grades that move with the policy.
  const fromDeed = readProofReceipt(ownReceipt, 'theory_praxis.deed').claims.slice(1).map(c => c.pwg);
  expect(rec.claims.slice(1).map(c => c.pwg)).toEqual(fromDeed);
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
  // The fields added by reader 940a27af: imports and controls.
  ['empty imports', () => edit(v => { firstReceipt(v).imports = []; }), /imports is empty/],
  ['empty controls', () => edit(v => { v.claims[0].controls = []; }), /controls is empty/],
  ['unknown import field', () => edit(v => { firstReceipt(v).imports = [{repository: 'o/lib', commit: '2'.repeat(40), inputs_sha256: 'd'.repeat(64), files: [{path: 'a', sha256: 'd'.repeat(64)}], pwg: 'PWG-1'}]; }), /asserts a grade \(pwg\)/],
  ['short import commit', () => edit(v => { firstReceipt(v).imports = [{repository: 'o/lib', commit: '2'.repeat(12), inputs_sha256: 'd'.repeat(64), files: [{path: 'a', sha256: 'd'.repeat(64)}]}]; }), /commit must be the full 40-character/],
  ['control receipt that failed', () => edit(v => { v.claims[0].controls = [{path: 'c/Bad.agda', prover: 'agda', expect: 'refused', receipts: [{...firstReceipt(v), result: 'fail'}]}]; }), /current receipt has result pass/],
  ['import digest', () => edit(v => { firstReceipt(v).imports = [{repository: 'o/lib', commit: '2'.repeat(40), inputs_sha256: '0'.repeat(64), files: [{path: 'a', sha256: 'd'.repeat(64)}]}]; }), /is not the SHA-256 of its files/],
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
