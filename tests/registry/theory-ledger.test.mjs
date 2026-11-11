// SPDX-License-Identifier: MPL-2.0
// The theory ledger: appends one entry per change, is append-only, and its
// fold matches the admissions and the claim pins.
import {test, expect} from 'bun:test';
import {readFileSync} from 'node:fs';
import {validateLedger, snapshot, fold, pending, checkAppendOnly, verifyOffline, jcs, sha256} from '../../scripts/registry/theory-ledger.mjs';
import {HOME} from '../../scripts/registry/theory.mjs';
import {parseJsonl} from '../../scripts/atlas/census-atlas.mjs';

const read = p => readFileSync(new URL(p, import.meta.url), 'utf8');
const rows = parseJsonl(read('../../docs/atlas/claims/claims.jsonl'));
const admissions = parseJsonl(read('../../docs/theory/admissions.jsonl'));
const ledgerText = read('../../docs/theory/ledger.jsonl');
const ledger = parseJsonl(ledgerText);
const homeIds = rows.filter(r => r.repo === HOME && r.kind === 'theorem').map(r => r.id);
const grades = new Map(homeIds.map(id => [id, 'PWG-1']));

test('the committed ledger is well formed and matches the admissions and pins', () => {
  expect(validateLedger(ledger)).toHaveLength(ledger.length);
  expect(() => verifyOffline(ledger, rows, admissions)).not.toThrow();
  expect(pending(ledger, snapshot(rows, admissions, grades), 'x')).toEqual([]);
});

test('the writer appends admitted, changed and withdrawn entries, and nothing when nothing changed', () => {
  const now = snapshot(rows, admissions, grades);
  const first = pending([], now, '2026-11-11');
  expect(first.map(e => e.event)).toEqual(homeIds.map(() => 'admitted'));
  expect(first[0].seq).toBe(1);
  expect(pending(first, now, '2026-11-12')).toEqual([]);
  const downgraded = snapshot(rows, admissions, new Map(homeIds.map(id => [id, 'ungraded'])));
  const changed = pending(first, downgraded, '2026-11-12', 'the receipt went stale');
  expect(changed.map(e => [e.event, e.changes, e.note])).toEqual(homeIds.map(() => ['changed', ['pwg'], 'the receipt went stale']));
  const gone = pending(first, new Map(), '2026-11-12');
  expect(gone.map(e => e.event)).toEqual(homeIds.map(() => 'withdrawn'));
  expect(fold([...first, ...gone]).size).toBe(0);
});

test('a malformed ledger fails closed', () => {
  const [e] = ledger;
  const bad = (list, msg) => expect(() => validateLedger(list)).toThrow(msg);
  bad([{...e, seq: 2}], /seq must count/);
  bad([{...e, grade: 'PWG-1'}], /Unknown ledger field/);
  bad([{...e, pwg: 'PWG-0'}], /derived grade/);
  bad([{...e, date: 'today'}], /date is a date/);
  bad([e, {...e, seq: 2}], /Admitted twice/);
  bad([{seq: 1, date: e.date, event: 'withdrawn', id: e.id}], /was not admitted/);
  bad([{...e, event: 'changed', changes: ['pwg']}], /not admitted/);
  bad([{...e, id: 'o/other#X'}], /names a home theorem/);
});

test('past entries are append-only', () => {
  const extra = jcs({...ledger[0], seq: ledger.length + 1, event: 'changed', changes: ['pwg']}) + '\n';
  expect(() => checkAppendOnly(ledgerText, ledgerText + extra)).not.toThrow();
  expect(() => checkAppendOnly('', ledgerText)).not.toThrow();
  const edited = ledgerText.replace(ledger[0].date, '2000-01-01');
  expect(() => checkAppendOnly(ledgerText, edited)).toThrow(/differs from main/);
  expect(() => checkAppendOnly(ledgerText + extra, ledgerText)).toThrow(/lost entries/);
});

test('the offline check catches a stale admission, a missing theorem and a leftover one', () => {
  const changedAdmission = admissions.map(a => ({...a, admitted: '2027-01-01'}));
  expect(() => verifyOffline(ledger, rows, changedAdmission)).toThrow(/admission .* is stale/);
  expect(() => verifyOffline([], rows, admissions)).toThrow(/does not record/);
  expect(() => verifyOffline(ledger, rows, [])).toThrow(/has no admission/);
  expect(sha256(jcs(admissions[0]))).toBe(ledger[0].admission_sha256);
});
