// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
import {test, expect} from 'bun:test';
import {readFileSync, mkdtempSync, mkdirSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {validate, parseReceipt, derive, deriveAll, render} from '../../scripts/registry/claims-registry.mjs';
import {parseJsonl} from '../../scripts/atlas/census-atlas.mjs';

const rows = JSON.parse(readFileSync(new URL('../../docs/registry/claims.json', import.meta.url), 'utf8'));
const inventory = parseJsonl(readFileSync(new URL('../../docs/catalogue/census/repos.jsonl', import.meta.url), 'utf8'));

const commit = 'a'.repeat(40);
const theorem = {id: 'o/r#T-1', repo: 'o/r', claim: 'T-1', kind: 'theorem', statement: 'a statement of some length',
  status_doc: 'PROOF-STATUS.adoc', source_commit: commit, agda: {module: 'M', names: ['t']}, receipt: null};
const inv = [{full_name: 'o/r', visibility: 'public'}];

// A §8.5-shaped receipt with the given flags, token, asserted pwg and leg states.
const receipt = ({flags = '--safe --without-K --cubical-compatible -W error', token = 'proven', pwg = null, rocq = 'AGDA-VERIFIED', lean = 'AGDA-VERIFIED'} = {}) =>
  `  (prover\n    :flags "${flags}")\n  (claims\n` +
  `    (claim :id "T-1" :token "${token}" :kind "theorem"${pwg === null ? '' : ` :pwg "${pwg}"`} :foundation-diverse #f\n` +
  `      (leg :prover "rocq" :route "re-proved" :token "proven" :state "${rocq}" :receipts ())\n` +
  `      (leg :prover "lean" :route "re-proved" :token "proven" :state "${lean}" :receipts ()))\n  )\n`;

test('the committed registry validates against the census inventory', () => {
  expect(validate(rows, inventory).length).toBe(rows.length);
  expect(rows.every(r => !('pwg' in r) && !('grade' in r))).toBe(true); // grades are derived, never stored
});

test('validation fails closed', () => {
  expect(() => validate([theorem, theorem], inv)).toThrow(/Duplicate/);
  expect(() => validate([{...theorem, source_commit: 'abc'}], inv)).toThrow(/40 lowercase hex/);
  expect(() => validate([{...theorem, kind: 'machine-verified'}], inv)).toThrow(/Unknown kind/);
  expect(() => validate([{...theorem, agda: null}], inv)).toThrow(/Agda module/);
  expect(() => validate([{...theorem, id: 'o/r#X'}], inv)).toThrow(/repo#claim/);
  expect(() => validate([theorem], [{full_name: 'o/r', visibility: 'private'}])).toThrow(/Nonpublic/);
  expect(() => validate([{...theorem, receipt: {path: 'x', sha256: 'nope'}}], inv)).toThrow(/sha256/);
});

test('the ladder is derived from leg states (§8.2)', () => {
  expect(derive(theorem, parseReceipt(receipt())).pwg).toBe('3');
  expect(derive(theorem, parseReceipt(receipt({rocq: 'RECONCILED'}))).pwg).toBe('2i');
  expect(derive(theorem, parseReceipt(receipt({rocq: 'RECONCILED', lean: 'RECONCILED'}))).pwg).toBe('2ii');
  // A checked but unbridged leg does not count.
  expect(derive(theorem, parseReceipt(receipt({rocq: 'BRIDGE-PENDING', lean: 'COQ-CHECKED'}))).pwg).toBe('3');
  // This slice never derives PWG-1.
  expect(derive(theorem, parseReceipt(receipt({rocq: 'RECONCILED', lean: 'RECONCILED'}))).pwg).not.toBe('1');
});

test('each reason a grade is withheld', () => {
  const noFlag = derive(theorem, parseReceipt(receipt({flags: '--safe --without-K'})));
  expect(noFlag.pwg).toBe('ungraded');
  expect(noFlag.reasons.join()).toContain('missing --cubical-compatible');
  expect(derive(theorem, parseReceipt(receipt({token: 'open'}))).pwg).toBe('ungraded');
  expect(derive(theorem, null).reasons.join()).toContain('no machine receipt');
  expect(derive({...theorem, claim: 'T-9'}, parseReceipt(receipt())).reasons.join()).toContain('absent');
  expect(derive({...theorem, kind: 'demonstration'}, parseReceipt(receipt())).pwg).toBe('ungraded');
});

test('an asserted grade the evidence does not support is drift; legacy vocabulary is a finding', () => {
  const over = derive(theorem, parseReceipt(receipt({pwg: '2i'})));
  expect(over.findings.join()).toContain('§8.4 drift');
  expect(derive(theorem, parseReceipt(receipt({pwg: '3'}))).findings).toEqual([]);
  const legacy = parseReceipt('    :flags "--safe --without-K"\n    (claim :id "T-1" :token "proven" :grade "grade-3" :coq-leg "unavailable" :lean-leg "unavailable")\n');
  const d = derive(theorem, legacy);
  expect(d.pwg).toBe('ungraded');
  expect(d.findings.join()).toContain('pre-§8 vocabulary');
  expect(d.findings.join()).not.toContain('drift');
});

test('a receipt that does not match its pinned digest is refused', async () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'registry-'));
  const text = receipt();
  mkdirSync(path.join(dir, `o__r@${commit}`), {recursive: true});
  writeFileSync(path.join(dir, `o__r@${commit}`, 'r.deed'), text);
  const good = {...theorem, receipt: {path: 'r.deed', sha256: createHash('sha256').update(text).digest('hex')}};
  expect((await deriveAll([good], dir))[0].pwg).toBe('3');
  await expect(deriveAll([{...good, receipt: {path: 'r.deed', sha256: 'b'.repeat(64)}}], dir)).rejects.toThrow(/digest mismatch/);
});

test('the view is a census with its denominator, never a percentage, and is deterministic', () => {
  const ds = [{row: theorem, pwg: '3', reasons: [], findings: [], legs: []},
              {row: {...theorem, id: 'o/r#T-2', claim: 'T-2'}, pwg: 'ungraded', reasons: ['x'], findings: [], legs: []}];
  const v = render(ds);
  expect(v).toContain('1 at `PWG-3`');
  expect(v).toContain('1 `ungraded`, of 2 theorems');
  expect(v).not.toMatch(/\d+(\.\d+)?\s*%/);
  expect(render([...ds].reverse())).toEqual(v);
});
