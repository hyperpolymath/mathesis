// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
import {test, expect} from 'bun:test';
import {readFileSync} from 'node:fs';
import {validateBridges, renderBridges} from '../../scripts/registry/bridges.mjs';
import {parseJsonl} from '../../scripts/atlas/census-atlas.mjs';

const read = p => parseJsonl(readFileSync(new URL(p, import.meta.url), 'utf8'));
const records = read('../../docs/atlas/claims/bridges.jsonl');
const inventory = read('../../docs/atlas/census/repos.jsonl');

const inv = [{full_name: 'o/a', visibility: 'public'}, {full_name: 'o/b', visibility: 'public'}, {full_name: 'o/p', visibility: 'private'}];
const good = {id: 'a-b', stage: 'candidate', subject: 'a subject', relation: 'unassessed', state: 'BRIDGE-PENDING',
  basis: 'read', source: 'a source', proposed_by: 'agent', reviewed_by: null,
  endpoints: [{repository: 'o/a', system: 'agda', name: 'A.agda', state: 'AGDA-VERIFIED'},
              {repository: 'o/b', system: 'rocq', name: 'B.v', state: 'COQ-CHECKED'}]};
const ends = (i, e) => good.endpoints.map((x, j) => (j === i ? {...x, ...e} : x));

test('the committed bridge records validate against the census inventory', () => {
  expect(validateBridges(records, inventory)).toHaveLength(records.length);
  expect(records.every(b => b.stage === 'candidate' && b.relation === 'unassessed')).toBe(true);
});

test('a bridge holds no token and no grade', () => {
  expect(() => validateBridges([{...good, pwg: 'PWG-3'}], inv)).toThrow(/no token or grade/);
  expect(() => validateBridges([{...good, token: 'proven'}], inv)).toThrow(/no token or grade/);
  expect(() => validateBridges([{...good, endpoints: ends(0, {pwg: 'PWG-1'})}], inv)).toThrow(/Unknown endpoint field/);
});

test('validation fails closed', () => {
  expect(validateBridges([good], inv)).toHaveLength(1);
  expect(() => validateBridges([good, good], inv)).toThrow(/Duplicate/);
  expect(() => validateBridges([{...good, stage: 'recorded'}], inv)).toThrow(/only candidate until WO 5.2/);
  expect(() => validateBridges([{...good, endpoints: [good.endpoints[0]]}], inv)).toThrow(/two endpoints/);
  expect(() => validateBridges([{...good, endpoints: ends(1, {repository: 'o/a'})}], inv)).toThrow(/crosses repositories/);
  expect(() => validateBridges([{...good, endpoints: ends(1, {repository: 'o/p'})}], inv)).toThrow(/Nonpublic/);
  expect(() => validateBridges([{...good, endpoints: ends(1, {state: 'PWG-3'})}], inv)).toThrow(/§2.2 state/);
  expect(() => validateBridges([{...good, state: 'RECONCILED?'}], inv)).toThrow(/§2.2 state/);
  expect(() => validateBridges([{...good, relation: 'equivalent'}], inv)).toThrow(/Unknown relation/);
  expect(() => validateBridges([{...good, basis: 'vibes'}], inv)).toThrow(/Unknown basis/);
  expect(() => validateBridges([{...good, id: 'A B'}], inv)).toThrow(/id must be/);
});

test('an unreviewed agent proposal stays unassessed', () => {
  expect(() => validateBridges([{...good, relation: 'refinement'}], inv)).toThrow(/unassessed/);
  expect(validateBridges([{...good, relation: 'refinement', reviewed_by: 'the owner'}], inv)).toHaveLength(1);
});

test('the view is deterministic and says a candidate is not evidence', () => {
  const two = [good, {...good, id: 'a-c'}];
  const v = renderBridges(two);
  expect(renderBridges([...two].reverse())).toEqual(v);
  expect(v).toContain('A candidate is not evidence, and it gives no grade');
  expect(v).toContain('Candidates: 2.');
  expect(v).not.toMatch(/PWG-/);
});
