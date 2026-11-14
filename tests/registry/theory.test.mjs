// SPDX-License-Identifier: MPL-2.0
// The theory shelf (re-anchoring plan WO 4.1): admissions match the home
// theorem pins, name a public dependant, hold no grade; the index is
// deterministic.
import {test, expect} from 'bun:test';
import {readFileSync} from 'node:fs';
import {validateAdmissions, renderTheoryIndex, onTheoryShelf} from '../../scripts/registry/theory.mjs';
import {parseJsonl} from '../../scripts/atlas/census-atlas.mjs';

const read = p => parseJsonl(readFileSync(new URL(p, import.meta.url), 'utf8'));
const rows = read('../../docs/atlas/claims/claims.jsonl');
const inventory = read('../../docs/atlas/census/repos.jsonl');
const admissions = read('../../docs/theory/admissions.jsonl');
const [a] = admissions;

test('the committed admissions match the theory-shelf pins', () => {
  expect(validateAdmissions(admissions, rows, inventory)).toHaveLength(rows.filter(onTheoryShelf).length);
});

test('validation fails closed', () => {
  const bad = (list, msg) => expect(() => validateAdmissions(list, rows, inventory)).toThrow(msg);
  bad([], /has no admission record/);
  bad([a, a], /Duplicate admission/);
  bad([{...a, pwg: 'PWG-1'}], /holds no grade/);
  bad([{...a, id: 'hyperpolymath/mathesis#THY-99'}], /No theory-shelf pin/);
  bad([{...a, admitted: 'today'}], /admitted is a date/);
  bad([{...a, theory: ''}], /Missing theory test/);
  bad([{...a, owner: ' '}], /Missing owner test/);
  bad([{...a, dependant: {...a.dependant, repository: 'o/hidden'}}], /Nonpublic or unlisted dependant/);
  bad([{...a, dependant: {...a.dependant, rule: ''}}], /names a path and a rule/);
  bad([{...a, dependant: {...a.dependant, grade: 'x'}}], /Unknown dependant field/);
  // An applied-shelf theorem needs no admission, and an admission cannot name one.
  const applied = rows.map(r => (r.id === a.id ? {...r, shelf: 'applied'} : r));
  expect(validateAdmissions([], applied, inventory)).toEqual([]);
  expect(() => validateAdmissions([a], applied, inventory)).toThrow(/No theory-shelf pin/);
});

test('the index is deterministic and takes the grade from the derivation', () => {
  // Both shelves go in, as in a real derivation; only the theory shelf has
  // admissions, and only it may reach the index.
  const home = rows.filter(onTheoryShelf);
  const applied = rows.filter(r => r.shelf === 'applied');
  expect(applied.length).toBeGreaterThan(0);
  const derived = [...home, ...applied].map(row => ({row, pwg: 'PWG-1', reasons: [], evidence: row.source_commit}));
  const view = renderTheoryIndex(derived, admissions);
  expect(renderTheoryIndex([...derived].reverse(), admissions)).toEqual(view);
  expect(view).toContain('`PWG-1`');
  expect(renderTheoryIndex(derived.map(d => ({...d, pwg: 'ungraded'})), admissions)).toContain('`ungraded`');
  expect(view).toContain(`Theorems: ${home.length}.`);
  for (const r of applied) expect(view).not.toContain(r.id);
});
