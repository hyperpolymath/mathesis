// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// The bridge records of the atlas (re-anchoring plan, "The bridge centre").
//
// docs/atlas/claims/bridges.jsonl holds one record for each bridge: a relation
// between two artefacts in two repositories. A record has a `stage`. A
// `candidate` (WO 2.4) carries only what Mathesis has read: the two endpoints
// with their §2.2 states, the relation, the bridge's own §2.2 state, the basis
// and the source. The full record (commit, path and blob digest at each end,
// criterion, what it preserves and forgets) is the `recorded` stage of WO 5.2,
// which this validator does not accept yet. A record holds no token and no
// grade. claims-registry.mjs renders docs/atlas/generated/bridges.adoc.

const STAGES = new Set(['candidate']);
const SYSTEMS = new Set(['agda', 'rocq', 'lean']);
// PROOF-POLICY §2.2 correspondence states.
const STATES = new Set(['NOT-INVENTORIED', 'INVENTORIED', 'AGDA-PENDING', 'AGDA-VERIFIED', 'COQ-CHECKED',
  'LEAN-CHECKED', 'BRIDGE-PENDING', 'RECONCILED', 'COUNTEREXAMPLE', 'QUARANTINED']);
const RELATIONS = new Set(['same-statement', 'refinement', 'conditional-transport', 'countermodel', 'unassessed']);
const BASES = new Set(['read', 'generated', 'transported', 'proved']);
const FIELDS = new Set(['id', 'stage', 'subject', 'endpoints', 'relation', 'state', 'basis', 'source', 'note',
  'proposed_by', 'reviewed_by']);
const ENDPOINT_FIELDS = new Set(['repository', 'system', 'name', 'state']);

const text = v => typeof v === 'string' && v.trim() !== '';

// Throw `message` unless `ok`.
const need = (ok, message) => {
  if (!ok) throw new Error(message);
};

// Check the fields of one record against a closed set.
const closed = (object, allowed, label, where) => {
  for (const k of Object.keys(object)) need(allowed.has(k), `${label} ${k}: ${where}`);
};

// Check one endpoint: a public repository, a known system, a name, a §2.2 state.
function checkEndpoint(e, visibility, where) {
  closed(e, ENDPOINT_FIELDS, 'Unknown endpoint field', where);
  need(visibility.get(e.repository) === 'public', `Nonpublic or unlisted repository ${e.repository}: ${where}`);
  need(SYSTEMS.has(e.system), `Unknown system ${e.system}: ${where}`);
  need(text(e.name), `Missing endpoint name: ${where}`);
  need(STATES.has(e.state), `Endpoint state ${e.state} is not a §2.2 state: ${where}`);
}

// Check who proposed and who reviewed a record. An agent's proposal stays
// unassessed until a person reviews a comparison that a home repository holds.
function checkReview(b, where) {
  need(b.proposed_by === 'agent' || b.proposed_by === 'person', `proposed_by is agent or person: ${where}`);
  need(b.reviewed_by === null || text(b.reviewed_by), `reviewed_by is null or a name: ${where}`);
  const unreviewedAgent = b.proposed_by === 'agent' && b.reviewed_by === null;
  need(!unreviewedAgent || b.relation === 'unassessed', `An unreviewed agent proposal has relation unassessed: ${where}`);
}

// Check one candidate record.
function checkRecord(b, visibility, where) {
  closed(b, FIELDS, 'Unknown field (a bridge holds no token or grade):', where);
  need(/^[a-z0-9]+(-[a-z0-9]+)*$/.test(b.id ?? ''), `id must be lowercase words joined by hyphens: ${where}`);
  need(STAGES.has(b.stage), `stage ${b.stage} is not accepted; only candidate until WO 5.2: ${where}`);
  need(text(b.subject), `Missing subject: ${where}`);
  need(Array.isArray(b.endpoints) && b.endpoints.length === 2, `A bridge has two endpoints: ${where}`);
  for (const e of b.endpoints) checkEndpoint(e, visibility, where);
  need(b.endpoints[0].repository !== b.endpoints[1].repository, `A bridge crosses repositories: ${where}`);
  need(RELATIONS.has(b.relation), `Unknown relation ${b.relation}: ${where}`);
  need(STATES.has(b.state), `Bridge state ${b.state} is not a §2.2 state: ${where}`);
  need(BASES.has(b.basis), `Unknown basis ${b.basis}: ${where}`);
  need(text(b.source), `Missing source: ${where}`);
  need(b.note === undefined || text(b.note), `An empty note: ${where}`);
  checkReview(b, where);
}

// Throw unless every record is a well-formed candidate whose repositories are
// public in the census inventory, and no two records share an id.
export function validateBridges(records, inventory) {
  const visibility = new Map(inventory.map(r => [r.full_name, r.visibility]));
  const seen = new Set();
  for (const b of records) {
    const where = text(b?.id) ? b.id : JSON.stringify(b);
    checkRecord(b, visibility, where);
    need(!seen.has(b.id), `Duplicate id: ${b.id}`);
    seen.add(b.id);
  }
  return records;
}

const cell = s => String(s).replaceAll('|', String.raw`\|`).replaceAll('\n', ' ');
const end = e => `https://github.com/${e.repository}[${e.repository}] ${e.system} \`${cell(e.name)}\` (${e.state})`;

// Render the bridge view as AsciiDoc, ordered by id.
export function renderBridges(records) {
  // Byte order of the id (ids are ASCII), independent of the locale.
  const ordered = [...records].sort((a, b) => Number(a.id > b.id) - Number(a.id < b.id));
  const out = [
    '// SPDX-License-Identifier: CC-BY-SA-4.0',
    '// GENERATED by scripts/registry/claims-registry.mjs from docs/atlas/claims/bridges.jsonl;',
    '// do not hand-edit.',
    '= Bridges',
    '',
    'A bridge relates two artefacts in two repositories (PROOF-POLICY §2.2). Each',
    'row below is a *candidate*: Mathesis has read that the relation may hold, and',
    'nothing more. A candidate is not evidence, and it gives no grade. Its relation',
    'stays `unassessed` until a person reviews a comparison that a home repository',
    'holds. The full record, with the commit, path and blob digest at each end, comes',
    'with re-anchoring plan WO 5.2.',
    '',
    `Candidates: ${records.filter(b => b.stage === 'candidate').length}.`,
    '',
    '[cols="2,4,4,1,1,3",options="header"]',
    '|===',
    '|Bridge |Subject |Endpoints (§2.2 state) |Relation |State |Source; note',
    '',
  ];
  for (const b of ordered) {
    const notes = [b.source, b.note].filter(Boolean).map(cell).join('; ');
    out.push(`|\`${b.id}\` |${cell(b.subject)} |${b.endpoints.map(end).join(' +\n')} |\`${b.relation}\` |\`${b.state}\` |${notes}`, '');
  }
  out.push('|===', '');
  return out.join('\n');
}
