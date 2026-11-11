// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// The ledger of the theory shelf (owner ruling 2026-11-11, after WO 4.1).
//
// docs/theory/ledger.jsonl tells the story of the theory work: one entry for
// each change to a home theorem's admission, receipt pin or derived grade.
// It is append-only and has one writer: `just theory-ledger`, which folds the
// ledger into the current state of each theorem, compares it with the
// admissions, the claim pins and the derived grades, and appends one entry for
// each difference. The working documents state only the present; the ledger
// keeps the past. A ledger entry holds a grade that the canon reader derived,
// copied at the time of the entry; it never asserts one.
//
// `node theory-ledger.mjs verify` is the offline part of the check (the `must`
// clause theory-ledger-current): the ledger is well formed, and its folded
// state matches each admission and claim pin. The grade needs the canon reader
// and network access, so `just registry-check` checks it.

import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {readJsonl} from '../atlas/census-atlas.mjs';
import {HOME} from './theory.mjs';

const EVENTS = new Set(['admitted', 'changed', 'withdrawn']);
const FIELDS = new Set(['seq', 'date', 'event', 'id', 'pwg', 'receipt', 'admission_sha256', 'changes', 'note']);
const RECEIPT_FIELDS = new Set(['path', 'sha256', 'commit']);
const CHANGE_KEYS = new Set(['pwg', 'receipt', 'admission']);

const need = (ok, message) => {
  if (!ok) throw new Error(message);
};

// RFC 8785 serialisation of parsed JSON (keys in UTF-16 order).
export function jcs(v) {
  if (Array.isArray(v)) return '[' + v.map(jcs).join(',') + ']';
  if (v !== null && typeof v === 'object') {
    return '{' + Object.keys(v).sort((a, b) => (a < b ? -1 : a > b ? 1 : 0)).map(k => JSON.stringify(k) + ':' + jcs(v[k])).join(',') + '}';
  }
  return JSON.stringify(v);
}

export const sha256 = s => createHash('sha256').update(s).digest('hex');

// The state of one home theorem that the ledger tracks.
const stateOf = (row, admission, pwg) => ({
  pwg,
  receipt: row.receipt ? {path: row.receipt.path, sha256: row.receipt.sha256, commit: row.source_commit} : null,
  admission_sha256: sha256(jcs(admission)),
});

// The current state of each home theorem, from the claim pins, the admissions
// and the derived grade of each pin (a Map id -> pwg).
export function snapshot(rows, admissions, grades) {
  const byId = new Map(admissions.map(a => [a.id, a]));
  const out = new Map();
  for (const row of rows) {
    if (row.repo !== HOME || row.kind !== 'theorem' || !byId.has(row.id)) continue;
    need(grades.has(row.id), `No derived grade for ${row.id}`);
    out.set(row.id, stateOf(row, byId.get(row.id), grades.get(row.id)));
  }
  return out;
}

// Throw unless the ledger is well formed: closed fields, seq 1..n in order,
// a date on each entry, and events that follow the life of each theorem.
export function validateLedger(ledger) {
  need(Array.isArray(ledger), 'docs/theory/ledger.jsonl must hold one entry on each line');
  const live = new Set();
  ledger.forEach((e, i) => {
    const where = `ledger entry ${i + 1}`;
    for (const k of Object.keys(e)) need(FIELDS.has(k), `Unknown ledger field ${k}: ${where}`);
    need(e.seq === i + 1, `seq must count 1, 2, 3 ... without a gap: ${where}`);
    need(typeof e.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(e.date), `date is a date: ${where}`);
    need(EVENTS.has(e.event), `Unknown event ${e.event}: ${where}`);
    need(typeof e.id === 'string' && e.id.startsWith(HOME + '#'), `id names a home theorem: ${where}`);
    need(e.note === undefined || (typeof e.note === 'string' && e.note.trim() !== ''), `note is text: ${where}`);
    if (e.event === 'withdrawn') {
      need(live.has(e.id), `A withdrawn theorem was not admitted: ${where}`);
      live.delete(e.id);
      return;
    }
    need(typeof e.pwg === 'string' && /^(PWG-1|PWG-2ii|PWG-2i|PWG-3|ungraded)$/.test(e.pwg), `pwg is a derived grade: ${where}`);
    need(e.receipt === null || (typeof e.receipt === 'object' && Object.keys(e.receipt).every(k => RECEIPT_FIELDS.has(k))), `receipt is null or {path, sha256, commit}: ${where}`);
    need(typeof e.admission_sha256 === 'string' && /^[0-9a-f]{64}$/.test(e.admission_sha256), `admission_sha256 is a SHA-256: ${where}`);
    if (e.event === 'admitted') {
      need(!live.has(e.id), `Admitted twice without a withdrawal: ${where}`);
      live.add(e.id);
    } else {
      need(live.has(e.id), `A change to a theorem that is not admitted: ${where}`);
      need(Array.isArray(e.changes) && e.changes.length > 0 && e.changes.every(c => CHANGE_KEYS.has(c)), `changes lists pwg, receipt or admission: ${where}`);
    }
  });
  return ledger;
}

// Fold the ledger into the last recorded state of each live theorem.
export function fold(ledger) {
  const out = new Map();
  for (const e of ledger) {
    if (e.event === 'withdrawn') out.delete(e.id);
    else out.set(e.id, {pwg: e.pwg, receipt: e.receipt, admission_sha256: e.admission_sha256});
  }
  return out;
}

// The entries that bring the ledger up to `current`, in id order.
export function pending(ledger, current, date, note) {
  const before = fold(ledger);
  const ids = [...new Set([...before.keys(), ...current.keys()])].sort();
  const out = [];
  for (const id of ids) {
    const was = before.get(id);
    const now = current.get(id);
    let entry = null;
    if (!was) entry = {event: 'admitted', id, ...now};
    else if (!now) entry = {event: 'withdrawn', id};
    else {
      const changes = [];
      if (was.pwg !== now.pwg) changes.push('pwg');
      if (jcs(was.receipt) !== jcs(now.receipt)) changes.push('receipt');
      if (was.admission_sha256 !== now.admission_sha256) changes.push('admission');
      if (changes.length) entry = {event: 'changed', id, ...now, changes};
    }
    if (entry) out.push({seq: ledger.length + out.length + 1, date, ...entry, ...(note ? {note} : {})});
  }
  return out;
}

// Throw unless `base` (the ledger on main) is a prefix of `ledger`, line for
// line: no past entry may change or disappear.
export function checkAppendOnly(baseText, text) {
  const base = baseText.split('\n').filter(Boolean);
  const now = text.split('\n').filter(Boolean);
  need(now.length >= base.length, `The ledger lost entries: main has ${base.length}, this tree has ${now.length}`);
  base.forEach((line, i) => need(now[i] === line, `Ledger entry ${i + 1} differs from main: past entries are append-only`));
}

// Offline check: the folded ledger matches each admission and claim pin
// (everything but the derived grade, which needs the canon reader).
export function verifyOffline(ledger, rows, admissions) {
  validateLedger(ledger);
  const state = fold(ledger);
  const byId = new Map(admissions.map(a => [a.id, a]));
  for (const row of rows.filter(r => r.repo === HOME && r.kind === 'theorem' && byId.has(r.id))) {
    const s = state.get(row.id);
    need(s, `The ledger does not record ${row.id}; run: just theory-ledger`);
    const now = stateOf(row, byId.get(row.id), s.pwg);
    need(jcs(now.receipt) === jcs(s.receipt), `The ledger's receipt for ${row.id} is stale; run: just theory-ledger`);
    need(now.admission_sha256 === s.admission_sha256, `The ledger's admission for ${row.id} is stale; run: just theory-ledger`);
  }
  for (const id of state.keys()) need(byId.has(id), `The ledger still holds ${id}, which has no admission; run: just theory-ledger`);
}

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [cmd] = process.argv.slice(2);
  try {
    need(cmd === 'verify', 'usage: theory-ledger.mjs verify');
    const read = p => readJsonl(path.join(root, p));
    verifyOffline(await read('docs/theory/ledger.jsonl'), await read('docs/atlas/claims/claims.jsonl'), await read('docs/theory/admissions.jsonl'));
    console.log('PASS: the theory ledger matches the admissions and the claim pins');
  } catch (e) {
    console.error('ERROR: ' + e.message);
    process.exitCode = 1;
  }
}
