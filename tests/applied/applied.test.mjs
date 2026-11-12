// SPDX-License-Identifier: MPL-2.0
// The shared input schema and the worked cohort examples (re-anchoring plan
// WO 4.2): a missing input is null, never zero; each example is complete and
// synthetic; the generated files follow from the examples alone.
import {test, expect} from 'bun:test';
import {readFileSync} from 'node:fs';
import {validateInput} from '../../scripts/applied/inputs.mjs';
import {validateExample, parseNumber, views, EXAMPLES} from '../../scripts/applied/cohort.mjs';
import {parseJsonl} from '../../scripts/atlas/census-atlas.mjs';

const load = name => parseJsonl(readFileSync(new URL(`../../${EXAMPLES}/${name}.jsonl`, import.meta.url), 'utf8'));
const input = {
  access: 'public', depends_on: [], description: 'Cash at the start', evidence_status: 'illustrative', id: 'opening_cash',
  kind: 'input', owner: 'mathesis', period: null, source: 'synthetic', unit: 'pence', value: 1, verified_on: null,
};

test('the input schema accepts a well-formed input and a missing one', () => {
  expect(validateInput(input)).toBe(input);
  expect(validateInput({...input, evidence_status: 'missing', value: null}).value).toBeNull();
  expect(validateInput({...input, evidence_status: 'verified', verified_on: '2026-11-12'}).evidence_status).toBe('verified');
});

test('the input schema keeps missing apart from zero', () => {
  const bad = (r, msg) => expect(() => validateInput(r)).toThrow(msg);
  bad({...input, evidence_status: 'missing', value: 0}, /value null, not zero/);
  bad({...input, evidence_status: 'missing', value: ''}, /value null, not zero/);
  bad({...input, value: null}, /only a missing input/);
  bad({...input, evidence_status: 'verified'}, /verified_on/);
  bad({...input, evidence_status: 'guessed'}, /evidence_status/);
  bad({...input, access: 'secret'}, /access/);
  bad({...input, extra: 1}, /unknown field/);
  bad({...input, evidence_status: 'verified', verified_on: '2026-02-31'}, /verified_on is a date/);
  bad({...input, evidence_status: 'verified', verified_on: '2026-13-01'}, /verified_on is a date/);
  bad({...input, depends_on: ['???']}, /depends_on lists input ids/);
  bad({...input, value: true}, /a number or text/);
  bad({...input, value: {n: 1}}, /a number or text/);
  const {unit, ...noUnit} = input;
  bad(noUnit, /missing field unit/);
});

test('each committed example is valid and its generated files are current', async () => {
  for (const name of ['simple', 'approximate', 'exact']) expect(validateExample(load(name), name).ex.mode).toBe(name);
  const files = await views();
  for (const [rel, body] of files) expect(readFileSync(new URL(`../../${rel}`, import.meta.url), 'utf8')).toBe(body);
});

test('the example validator fails closed', () => {
  const recs = load('approximate');
  const bad = (list, msg) => expect(() => validateExample(list, 'approximate')).toThrow(msg);
  const without = id => recs.filter(r => !(r.kind === 'input' && r.id === id));
  const swap = (id, change) => recs.map(r => (r.kind === 'input' && r.id === id ? {...r, ...change} : r));
  bad(without('B.retention'), /B.retention@null is absent; a missing input is a record with the value null/);
  bad(swap('A.retention', {value: 1001}), /from 0 to 1000/);
  bad(swap('A.retention', {evidence_status: 'reported'}), /not evidence about an organisation/);
  bad(swap('A.retention', {access: 'restricted'}), /public inputs only/);
  bad(swap('A.retention', {source: 'organisation ledger'}), /"synthetic"/);
  bad(swap('support_minutes', {value: -2}), /support_minutes@null is a whole number/);
  bad(recs.map(r => (r.kind === 'input' && r.id === 'capacity_minutes' && r.period === 'P2' ? {...r, value: -1} : r)), /capacity_minutes@P2 is a whole number/);
  expect(() => validateExample([{...recs[0], name: 'Approximate'}, ...recs.slice(1)], 'Approximate')).toThrow(/lower-case/);
  bad([{...recs[0], synthetic: false}, ...recs.slice(1)], /synthetic by construction/);
  bad([{...recs[0], mode: 'exact'}, ...recs.slice(1)], /fraction/);
  bad(recs.filter(r => !(r.kind === 'expected' && r.id === 'closing' && r.period === 'P4')), /no expected closing for P4/);
  bad(recs.map(r => (r.kind === 'expected' && r.id === 'closing' && r.period === 'P4' ? {...r, value: 0} : r)), /a missing output has the value null/);
});

test('numbers parse exactly', () => {
  expect(parseNumber(-3, 'x')).toEqual({n: -3n, d: 1n});
  expect(parseNumber('138657.5', 'x')).toEqual({n: 1386575n, d: 10n});
  expect(parseNumber('-17/20', 'x')).toEqual({n: -17n, d: 20n});
  expect(() => parseNumber('1/0', 'x')).toThrow(/not an integer/);
  expect(() => parseNumber(1.5, 'x')).toThrow(/decimal string/);
});
