// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// The shared input schema of the applied shelf (re-anchoring plan WO 4.2).
//
// applied-systems/methods/input-schema.adoc states the schema; this module
// enforces it. One input record holds the fields that
// applied-systems/methods/evidence-and-assumptions.adoc asks for: a
// description, unit, period, source, owner, evidence status, last
// verification date and dependencies, with access as a separate field. A
// missing input has the value null: never zero.

export const STATUSES = ['verified', 'reported', 'estimate', 'illustrative', 'missing'];
export const ACCESS = ['public', 'restricted'];
const FIELDS = ['access', 'depends_on', 'description', 'evidence_status', 'id', 'kind', 'owner', 'period', 'source', 'unit', 'value', 'verified_on'];

const text = v => typeof v === 'string' && v.trim() !== '';
const isDate = v => typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v);
const need = (ok, message) => {
  if (!ok) throw new Error(message);
};

// Throw unless `r` is a well-formed input record. `where` names it in errors.
export function validateInput(r, where = 'input') {
  need(r !== null && typeof r === 'object' && !Array.isArray(r), `${where}: an input is an object`);
  for (const k of Object.keys(r)) need(FIELDS.includes(k), `${where}: unknown field ${k}`);
  for (const k of FIELDS) need(k in r, `${where}: missing field ${k}`);
  need(r.kind === 'input', `${where}: kind is "input"`);
  need(typeof r.id === 'string' && /^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)*$/.test(r.id), `${where}: id is a dotted name`);
  for (const k of ['description', 'unit', 'source', 'owner']) need(text(r[k]), `${where} (${r.id}): ${k} is text`);
  need(r.period === null || text(r.period), `${where} (${r.id}): period is text or null`);
  need(STATUSES.includes(r.evidence_status), `${where} (${r.id}): evidence_status is one of ${STATUSES.join(', ')}`);
  need(r.verified_on === null || isDate(r.verified_on), `${where} (${r.id}): verified_on is a date or null`);
  need(r.evidence_status !== 'verified' || r.verified_on !== null, `${where} (${r.id}): a verified input has a verified_on date`);
  need(Array.isArray(r.depends_on) && r.depends_on.every(text), `${where} (${r.id}): depends_on lists input ids`);
  need(ACCESS.includes(r.access), `${where} (${r.id}): access is one of ${ACCESS.join(', ')}`);
  if (r.evidence_status === 'missing') {
    need(r.value === null, `${where} (${r.id}): a missing input has the value null, not zero or text`);
  } else {
    need(r.value !== null && r.value !== undefined, `${where} (${r.id}): only a missing input has the value null`);
  }
  return r;
}
