// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// The ultraplan of Mathesis: a tech tree whose source of truth is data.
//
//   bun scripts/ultraplan/ultraplan.mjs build   write the generated views
//   bun scripts/ultraplan/ultraplan.mjs check   refuse stale views or bad data
//
// Sources (I-JSON, one JCS record a line):
//   docs/ultraplan/advisors.jsonl     the council: who reads the tree, and how
//   docs/ultraplan/tree.jsonl         the nodes; `needs` are the edges
//   docs/ultraplan/expeditions.jsonl  return tickets: off-tree trips, each one
//                                     grafted onto the tree or archived
// Views:
//   docs/ultraplan/generated/ultraplan.adoc
//   docs/ultraplan/generated/tree.svg
//
// What is typed and what is derived. A node's era, what it enables, the
// frontier (what can be started now), the forks and confluences and each
// advisor's pick are derived from the data and never typed. A node's status
// is typed, but `done` must carry evidence that this script checks against the
// repository: a file that exists, a claim whose grade the registry view
// derives, or an ADR whose status is Accepted. A done node's needs must be
// done too, and no more than ACTIVE_LIMIT nodes may be active at once. The
// value marks are judgements, and the view says so.
//
// The "me" advisor is private (owner ruling 2026-11-24): its notes are kept
// outside this public repository, and a node carries at most the neutral tag
// `owner_value: "high"`. Counsel under the key `me` is refused.
import {readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync} from 'node:fs';
import path from 'node:path';
import {parseJsonl} from '../atlas/census-atlas.mjs';
import {jcs} from '../registry/theory-ledger.mjs';

export const ROOT = path.resolve(import.meta.dir, '../..');
export const DIR = 'docs/ultraplan';
export const VIEW = `${DIR}/generated/ultraplan.adoc`;
export const SVG = `${DIR}/generated/tree.svg`;

export const TRACKS = ['maths', 'engineering', 'science', 'economics', 'publications', 'ecosystem'];
export const STATUSES = ['done', 'active', 'open', 'blocked', 'dropped'];
export const SIZES = {S: 1, M: 2, L: 4, XL: 8};
export const VALUE_KEYS = ['maths', 'engineering', 'science', 'economics', 'publications', 'teaching', 'soundness', 'ecosystem'];
export const KINDS = ['theorem', 'tool', 'data', 'view', 'paper', 'decision', 'infrastructure', 'method'];
export const ACTIVE_LIMIT = 3;
export const PWG_ORDER = ['ungraded', 'PWG-3', 'PWG-2i', 'PWG-2ii', 'PWG-1'];

// The eras of the tree, by depth (the longest chain of needs below a node).
export const ERAS = [
  ['🪨', 'Tally sticks'], ['🧮', 'Abacus'], ['📐', 'Euclid'], ['🌌', 'Kepler'],
  ['♾️', 'Cantor'], ['🧩', 'Gödel'], ['🌀', 'Grothendieck'], ['🚀', 'Frontier beyond'],
];
export const era = d => d < ERAS.length ? ERAS[d] : ['🚀', `Frontier beyond +${d - ERAS.length + 1}`];

export const STATUS_GLYPH = {done: '✅', active: '🔨', open: '🌱', blocked: '⛔', dropped: '🍂'};
export const TRACK_GLYPH = {maths: '∑', engineering: '⚙', science: '🔬', economics: '🪙', publications: '📜', ecosystem: '🗺'};
export const TRACK_FILL = {
  maths: '#fff1b8', engineering: '#d6e8ff', science: '#d9f7df',
  economics: '#ffe0d6', publications: '#eee0ff', ecosystem: '#ffe9c7',
};

const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;
// A size is one of the four own keys of SIZES, never an inherited name such as "toString".
const isSize = s => typeof s === 'string' && Object.hasOwn(SIZES, s);
// A YYYY-MM-DD that names a real day (no 2026-02-30).
export const isDate = s => {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const d = new Date(`${s}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === s;
};
const isStr = (v, max = 400) => typeof v === 'string' && v.length > 0 && v.length <= max && v === v.trim() && !/[\u0000-\u001f]/.test(v);

// ── Reading ──────────────────────────────────────────────────────────────────
// Each source line must already be its own JCS form, so the data has one
// spelling and a diff shows only real change.
// I-JSON (RFC 7493) and JCS (RFC 8785) refuse a string or a member name that
// holds a lone surrogate, which JSON.parse would otherwise accept and
// JSON.stringify would write back unchanged.
export function wellFormed(v) {
  if (typeof v === 'string') return v.isWellFormed();
  if (Array.isArray(v)) return v.every(wellFormed);
  if (v !== null && typeof v === 'object') return Object.entries(v).every(([k, x]) => k.isWellFormed() && wellFormed(x));
  return true;
}

export function readSource(text, name) {
  const rows = parseJsonl(text, name);
  const lines = text === '' ? [] : text.slice(0, -1).split('\n');
  rows.forEach((r, i) => {
    if (!wellFormed(r)) throw new Error(`${name}: line ${i + 1} holds a lone surrogate, which I-JSON and JCS refuse`);
    if (jcs(r) !== lines[i]) throw new Error(`${name}: line ${i + 1} is not in JCS form (RFC 8785); write it as ${jcs(r)}`);
  });
  return rows;
}

function closed(obj, allowed, where) {
  if (obj === null || typeof obj !== 'object' || Array.isArray(obj)) throw new Error(`${where}: must be an object`);
  for (const k of Object.keys(obj)) if (!allowed.includes(k)) throw new Error(`${where}: unknown field "${k}"`);
}

// ── Evidence ─────────────────────────────────────────────────────────────────
// The grade the registry view derives for a claim id, or null when the view
// does not list it. The view is generated and checked by registry-check.
export function registryGrade(registryText, id) {
  const line = registryText.split('\n').find(l => l.includes(`[${id}]`));
  if (!line) return null;
  const m = /\|`(PWG-1|PWG-2ii|PWG-2i|PWG-3|ungraded)`/.exec(line) || /\|`?(ungraded)`?\s*\|/.exec(line);
  return m ? m[1] : null;
}

// Whether an ADR's Status section opens with "Accepted".
export function adrAccepted(text) {
  const lines = text.split('\n');
  const i = lines.findIndex(l => /^=+ Status\s*$/.test(l));
  if (i < 0) return false;
  const first = lines.slice(i + 1).find(l => l.trim() !== '');
  return !!first && /^\**Accepted\b/.test(first.trim());
}

// Check one evidence item against the repository; return an error or null.
export function checkEvidence(ev, ctx) {
  closed(ev, ['path', 'claim', 'min_pwg', 'adr'], 'evidence');
  const kinds = ['path', 'claim', 'adr'].filter(k => k in ev);
  if (kinds.length !== 1) return 'an evidence item names exactly one of path, claim or adr';
  if (ev.min_pwg !== undefined && ev.claim === undefined) return 'min_pwg belongs to claim evidence only';
  if (ev.path !== undefined) {
    if (!isStr(ev.path, 300) || ev.path.startsWith('/') || ev.path.split('/').includes('..')) return `evidence path ${JSON.stringify(ev.path)} is not a repository path`;
    return ctx.isFile(ev.path) ? null : `evidence path ${ev.path} is not a file in the repository`;
  }
  if (ev.claim !== undefined) {
    if (!isStr(ev.claim) || !/^[\w.-]+\/[\w.-]+#[A-Z]+-[0-9A-Za-z]+$/.test(ev.claim)) return `evidence claim ${JSON.stringify(ev.claim)} is not OWNER/REPO#ID`;
    const min = ev.min_pwg ?? 'PWG-3';
    if (!PWG_ORDER.includes(min) || min === 'ungraded') return `evidence min_pwg ${JSON.stringify(min)} is not a grade`;
    const got = registryGrade(ctx.registry, ev.claim);
    if (got === null) return `the registry view does not list ${ev.claim}`;
    return PWG_ORDER.indexOf(got) >= PWG_ORDER.indexOf(min) ? null : `${ev.claim} derives ${got}, below ${min}`;
  }
  if (!isStr(ev.adr) || !/^\d{4}$/.test(ev.adr)) return `evidence adr ${JSON.stringify(ev.adr)} is not a four-digit ADR number`;
  const file = ctx.adrFile(ev.adr);
  if (!file) return `no ADR ${ev.adr} in docs/decisions`;
  return adrAccepted(ctx.read(file)) ? null : `ADR ${ev.adr} is not Accepted`;
}

// ── Validation ───────────────────────────────────────────────────────────────
export function validate({advisors, nodes, expeditions}, ctx) {
  const errors = [];
  const fail = m => errors.push(m);

  const advisorIds = new Set();
  for (const a of advisors) {
    try { closed(a, ['id', 'name', 'glyph', 'asks', 'reads', 'private'], `advisor ${a?.id}`); } catch (e) { fail(e.message); continue; }
    if (!isStr(a.id, 40) || !SLUG.test(a.id) || advisorIds.has(a.id)) fail(`advisor id ${JSON.stringify(a.id)} is missing, not a slug, or repeated`);
    advisorIds.add(a.id);
    for (const k of ['name', 'glyph', 'asks']) if (!isStr(a[k])) fail(`advisor ${a.id}: ${k} is required`);
    if (a.reads !== undefined && !VALUE_KEYS.includes(a.reads)) fail(`advisor ${a.id}: reads must be one of ${VALUE_KEYS.join(', ')}`);
    if (a.private !== undefined && a.private !== true) fail(`advisor ${a.id}: private is true or absent`);
    // Exactly the me advisor is private: its ranking and the page's privacy claim depend on it.
    if (a.id === 'me' && a.private !== true) fail('advisor me: must be private ("private":true)');
    if (a.id !== 'me' && a.private !== undefined) fail(`advisor ${a.id}: only the me advisor is private`);
  }

  const byId = new Map();
  for (const n of nodes) {
    const where = `node ${n?.id}`;
    try {
      closed(n, ['id', 'name', 'glyph', 'track', 'kind', 'status', 'size', 'summary', 'needs', 'rivals', 'value',
        'counsel', 'evidence', 'blocked_by', 'where', 'owner_value', 'refs'], where);
    } catch (e) { fail(e.message); continue; }
    if (!isStr(n.id, 60) || !SLUG.test(n.id)) { fail(`${where}: id must be a lowercase slug`); continue; }
    if (byId.has(n.id)) { fail(`${where}: repeated id`); continue; }
    byId.set(n.id, n);
    if (!isStr(n.name, 80)) fail(`${where}: name is required (at most 80 characters)`);
    if (!isStr(n.glyph, 16)) fail(`${where}: glyph is required`);
    if (!TRACKS.includes(n.track)) fail(`${where}: track must be one of ${TRACKS.join(', ')}`);
    if (!KINDS.includes(n.kind)) fail(`${where}: kind must be one of ${KINDS.join(', ')}`);
    if (!STATUSES.includes(n.status)) fail(`${where}: status must be one of ${STATUSES.join(', ')}`);
    if (!isSize(n.size)) fail(`${where}: size must be one of ${Object.keys(SIZES).join(', ')}`);
    if (!isStr(n.summary, 600)) fail(`${where}: summary is required (at most 600 characters)`);
    for (const k of ['needs', 'rivals', 'evidence', 'refs']) if (n[k] !== undefined && !Array.isArray(n[k])) fail(`${where}: ${k} must be a list`);
    if (n.value !== undefined) {
      try { closed(n.value, VALUE_KEYS, `${where} value`); } catch (e) { fail(e.message); }
      for (const [k, v] of Object.entries(n.value ?? {})) if (!Number.isInteger(v) || v < 0 || v > 3) fail(`${where}: value.${k} must be 0, 1, 2 or 3`);
    }
    if (n.counsel !== undefined) {
      if (n.counsel === null || typeof n.counsel !== 'object' || Array.isArray(n.counsel)) fail(`${where}: counsel must be an object`);
      else for (const [k, v] of Object.entries(n.counsel)) {
        if (k === 'me') fail(`${where}: counsel.me is refused; the me advisor's notes stay outside the public repository`);
        else if (!advisorIds.has(k)) fail(`${where}: counsel from unknown advisor ${k}`);
        if (!isStr(v, 300)) fail(`${where}: counsel.${k} must be a short text`);
      }
    }
    if (n.where !== undefined && !/^(estate|upstream):[\w.-]+\/[\w.-]+$/.test(n.where)) fail(`${where}: where is estate:OWNER/REPO or upstream:OWNER/REPO, or absent for this repository`);
    if (n.owner_value !== undefined && n.owner_value !== 'high') fail(`${where}: owner_value is "high" or absent`);
    if (n.status === 'blocked' && !isStr(n.blocked_by)) fail(`${where}: a blocked node says what blocks it (blocked_by)`);
    if (n.status !== 'blocked' && n.blocked_by !== undefined) fail(`${where}: blocked_by belongs to a blocked node only`);
    for (const r of n.refs ?? []) if (!isStr(r, 300)) fail(`${where}: each ref is a short text`);
  }

  for (const n of byId.values()) {
    const where = `node ${n.id}`;
    for (const k of ['needs', 'rivals']) {
      const seen = new Set();
      for (const t of n[k] ?? []) {
        if (!byId.has(t)) fail(`${where}: ${k} names unknown node ${t}`);
        if (t === n.id) fail(`${where}: ${k} names itself`);
        if (seen.has(t)) fail(`${where}: ${k} names ${t} twice`);
        seen.add(t);
      }
    }
    for (const r of n.rivals ?? []) if (byId.has(r) && !(byId.get(r).rivals ?? []).includes(n.id)) fail(`${where}: rival ${r} does not name ${n.id} back`);
    if (n.status === 'done' && !(n.evidence ?? []).length) fail(`${where}: done needs evidence (a path, a claim grade or an accepted ADR)`);
    if (n.status === 'done' || n.status === 'active') {
      // Evidence an active node shows must hold as much as a done node's.
      for (const ev of n.evidence ?? []) {
        let e;
        try { e = checkEvidence(ev, ctx); } catch (x) { e = x.message; }
        if (e) fail(`${where}: ${e}`);
      }
    } else if (n.evidence !== undefined) {
      fail(`${where}: evidence belongs to a done or active node`);
    }
    // A node is started only from the frontier, so an active node's needs are done too.
    if (n.status === 'done' || n.status === 'active') for (const t of n.needs ?? []) if (byId.get(t)?.status !== 'done') fail(`${where}: ${n.status}, but its need ${t} is not done`);
  }

  // The needs form a DAG.
  const state = new Map();
  const visit = (id, trail) => {
    if (state.get(id) === 2) return;
    if (state.get(id) === 1) { fail(`the needs form a cycle: ${[...trail, id].join(' -> ')}`); return; }
    state.set(id, 1);
    for (const t of byId.get(id)?.needs ?? []) if (byId.has(t)) visit(t, [...trail, id]);
    state.set(id, 2);
  };
  for (const id of byId.keys()) visit(id, []);

  const active = [...byId.values()].filter(n => n.status === 'active');
  if (active.length > ACTIVE_LIMIT) fail(`${active.length} nodes are active (${active.map(n => n.id).join(', ')}); at most ${ACTIVE_LIMIT} may be, so finish or park one first`);

  const exIds = new Set();
  for (const x of expeditions) {
    const where = `expedition ${x?.id}`;
    try { closed(x, ['id', 'what', 'why', 'size', 'date', 'status', 'graft', 'lesson'], where); } catch (e) { fail(e.message); continue; }
    if (!isStr(x.id, 20) || !/^X-\d{3}$/.test(x.id) || exIds.has(x.id)) fail(`${where}: id is X-NNN and unique`);
    exIds.add(x.id);
    for (const k of ['what', 'why']) if (!isStr(x[k])) fail(`${where}: ${k} is required`);
    if (!isSize(x.size)) fail(`${where}: size must be one of ${Object.keys(SIZES).join(', ')}`);
    if (!isDate(x.date)) fail(`${where}: date is a real calendar date, YYYY-MM-DD`);
    if (!['out', 'grafted', 'archived'].includes(x.status)) fail(`${where}: status is out, grafted or archived`);
    if (x.status === 'grafted' && !byId.has(x.graft)) fail(`${where}: a grafted expedition names the node it became (graft)`);
    if (x.status !== 'grafted' && x.graft !== undefined) fail(`${where}: graft belongs to a grafted expedition`);
    if (x.status === 'archived' && !isStr(x.lesson)) fail(`${where}: an archived expedition records what it taught (lesson)`);
    if (x.status !== 'archived' && x.lesson !== undefined) fail(`${where}: lesson belongs to an archived expedition`);
  }

  if (errors.length) throw new Error(errors.join('\n'));
  return byId;
}

// ── Derivation ───────────────────────────────────────────────────────────────
export function derive(byId, advisors) {
  const children = new Map([...byId.keys()].map(id => [id, []]));
  for (const n of byId.values()) for (const t of n.needs ?? []) children.get(t).push(n.id);
  for (const c of children.values()) c.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));

  const depth = new Map();
  const depthOf = id => {
    if (depth.has(id)) return depth.get(id);
    const ns = byId.get(id).needs ?? [];
    const d = ns.length ? 1 + Math.max(...ns.map(depthOf)) : 0;
    depth.set(id, d);
    return d;
  };
  const below = new Map();
  const belowOf = id => {
    if (below.has(id)) return below.get(id);
    const s = new Set();
    for (const c of children.get(id)) { s.add(c); for (const x of belowOf(c)) s.add(x); }
    below.set(id, s);
    return s;
  };
  for (const id of byId.keys()) { depthOf(id); belowOf(id); }

  const live = n => n.status !== 'dropped';
  const frontier = [...byId.values()].filter(n => n.status === 'open' && (n.needs ?? []).every(t => byId.get(t).status === 'done'));
  const total = n => Object.values(n.value ?? {}).reduce((a, b) => a + b, 0);
  const leverage = id => [...below.get(id)].filter(x => live(byId.get(x))).length;

  const forks = [...byId.values()].filter(n => live(n) && new Set(children.get(n.id).map(c => byId.get(c)).filter(live).map(c => c.track)).size >= 2);
  const confluences = [...byId.values()].filter(n => live(n) && new Set((n.needs ?? []).map(t => byId.get(t).track)).size >= 2);
  const rivalries = [];
  for (const n of byId.values()) for (const r of n.rivals ?? []) if (n.id < r) rivalries.push([n.id, r]);

  // Each advisor's pick from the frontier. An advisor that reads a value key
  // ranks by it, then by leverage, then by value for effort; the contrarian
  // takes the frontier node the council rates lowest that still unlocks the
  // most; the me advisor names only nodes tagged owner_value, with no notes.
  const byKey = (k) => (a, b) => (b.value?.[k] ?? 0) - (a.value?.[k] ?? 0) || leverage(b.id) - leverage(a.id)
    || total(b) / SIZES[b.size] - total(a) / SIZES[a.size] || (a.id < b.id ? -1 : 1);
  const picks = new Map();
  for (const a of advisors) {
    let pick = null;
    if (a.id === 'contrarian') {
      pick = [...frontier].sort((x, y) => total(x) - total(y) || leverage(y.id) - leverage(x.id) || (x.id < y.id ? -1 : 1))[0] ?? null;
    } else if (a.private) {
      pick = [...frontier].filter(n => n.owner_value === 'high').sort(byKey('maths'))[0] ?? null;
    } else if (a.reads) {
      pick = [...frontier].filter(n => (n.value?.[a.reads] ?? 0) > 0).sort(byKey(a.reads))[0] ?? null;
    }
    picks.set(a.id, pick);
  }
  return {children, depth, below, frontier, forks, confluences, rivalries, picks, leverage, total};
}

// ── Rendering: AsciiDoc ──────────────────────────────────────────────────────
const cell = s => String(s).replace(/\|/g, '\\|');
const nameOf = (byId, id) => `${byId.get(id).glyph} ${byId.get(id).name}`;
const xref = (byId, id) => `<<${id},${cell(nameOf(byId, id))}>>`;

export function renderAdoc(byId, advisors, expeditions, d) {
  const L = [];
  const nodes = [...byId.values()];
  const count = s => nodes.filter(n => n.status === s).length;
  L.push('// SPDX-License-Identifier: CC-BY-SA-4.0');
  L.push('// GENERATED by scripts/ultraplan/ultraplan.mjs from docs/ultraplan/tree.jsonl,');
  L.push('// docs/ultraplan/advisors.jsonl and docs/ultraplan/expeditions.jsonl; do not hand-edit.');
  L.push('= Mathesis ultraplan: the tech tree');
  L.push(':toc: macro');
  L.push(':toclevels: 1');
  L.push('');
  L.push('Each node is a capability. Its needs are the nodes it is built on, so the tree reads');
  L.push('like a civilisation game: one discovery enables the next. The data in');
  L.push('`docs/ultraplan/` is the source; this page and its picture are generated from it.');
  L.push('The era, the frontier, the forks, the confluences and each advisor\'s pick are derived,');
  L.push('never typed. A node marked done carries evidence the generator checks: a file, a');
  L.push('claim grade that the registry derives, or an accepted decision record. The value marks');
  L.push('are judgements, written down so they can be argued with.');
  L.push('');
  L.push(`Census of the tree: ${count('done')} done, ${count('active')} active (at most ${ACTIVE_LIMIT}), ${count('open')} open, ${count('blocked')} blocked, ${count('dropped')} dropped, of ${nodes.length} nodes. ${d.frontier.length} can be started now.`);
  L.push('');
  L.push('toc::[]');
  L.push('');
  L.push('image::tree.svg[The tech tree of Mathesis, from the first era on the left to the frontier on the right]');
  L.push('');
  L.push('Key: ✅ done · 🔨 active · 🌱 open · ⛔ blocked · 🍂 dropped. A gold border marks a node');
  L.push('that can be started now. Colours are tracks: ' + TRACKS.map(t => `${TRACK_GLYPH[t]} ${t}`).join(' · ') + '.');
  L.push('');

  L.push('== Research now: the frontier');
  L.push('');
  L.push('These open nodes have every need done, so any of them can start today. "Unlocks"');
  L.push('counts the live nodes that depend on it, directly or through others.');
  L.push('');
  if (!d.frontier.length) L.push('Nothing is on the frontier.');
  else {
    L.push('[cols="3,1,1,1,5",options="header"]');
    L.push('|===');
    L.push('|Node |Track |Size |Unlocks |Summary');
    for (const n of [...d.frontier].sort((a, b) => d.leverage(b.id) - d.leverage(a.id) || (a.id < b.id ? -1 : 1))) {
      L.push(`|${xref(byId, n.id)} |${n.track} |${n.size} |${d.leverage(n.id)} |${cell(n.summary)}${n.where ? ` _(${cell(n.where)})_` : ''}`);
    }
    L.push('|===');
  }
  L.push('');

  L.push('== The council');
  L.push('');
  L.push('Each advisor asks one question of every node and names one pick from the frontier.');
  L.push('The me advisor is private: its notes stay outside this repository, and it names only');
  L.push('nodes the owner has tagged.');
  L.push('');
  for (const a of advisors) {
    const p = d.picks.get(a.id);
    L.push(`=== ${a.glyph} ${a.name}`);
    L.push('');
    L.push(`_Asks:_ ${a.asks}`);
    L.push('');
    if (!p) L.push('_Pick:_ nothing on the frontier answers this advisor yet.');
    else {
      const note = p.counsel?.[a.id];
      L.push(`_Pick:_ ${xref(byId, p.id)}${note ? `. ${note}` : '.'}`);
    }
    L.push('');
  }

  L.push('== Forks and confluences');
  L.push('');
  L.push('A fork enables nodes on two or more tracks: work there spreads. A confluence needs');
  L.push('nodes from two or more tracks: work there joins. Rivals are different routes to the');
  L.push('same place; the contrarian keeps the road not taken in view.');
  L.push('');
  L.push('.Forks');
  for (const n of d.forks.sort((a, b) => (a.id < b.id ? -1 : 1))) {
    L.push(`* ${xref(byId, n.id)} -> ${d.children.get(n.id).map(c => xref(byId, c)).join(', ')}`);
  }
  if (!d.forks.length) L.push('* None yet.');
  L.push('');
  L.push('.Confluences');
  for (const n of d.confluences.sort((a, b) => (a.id < b.id ? -1 : 1))) {
    L.push(`* ${(n.needs ?? []).map(t => xref(byId, t)).join(' + ')} -> ${xref(byId, n.id)}`);
  }
  if (!d.confluences.length) L.push('* None yet.');
  L.push('');
  L.push('.Rivals');
  for (const [a, b] of d.rivalries) L.push(`* ${xref(byId, a)} or ${xref(byId, b)}`);
  if (!d.rivalries.length) L.push('* None yet.');
  L.push('');

  L.push('== The eras');
  L.push('');
  const maxDepth = Math.max(0, ...[...d.depth.values()]);
  for (let k = 0; k <= maxDepth; k++) {
    const [g, name] = era(k);
    const inEra = nodes.filter(n => d.depth.get(n.id) === k).sort((a, b) => TRACKS.indexOf(a.track) - TRACKS.indexOf(b.track) || (a.id < b.id ? -1 : 1));
    if (!inEra.length) continue;
    L.push(`=== ${g} Era ${k}: ${name}`);
    L.push('');
    for (const n of inEra) {
      L.push(`[[${n.id}]]`);
      L.push(`==== ${STATUS_GLYPH[n.status]} ${n.glyph} ${n.name}`);
      L.push('');
      L.push(n.summary);
      L.push('');
      const facts = [`*Track:* ${TRACK_GLYPH[n.track]} ${n.track}`, `*Kind:* ${n.kind}`, `*Size:* ${n.size}`, `*Status:* ${n.status}`];
      if (n.where) facts.push(`*Beyond this repository:* ${n.where}`);
      L.push(facts.join(' · '));
      L.push('');
      if ((n.needs ?? []).length) L.push(`*Needs:* ${n.needs.map(t => xref(byId, t)).join(', ')}` + ' +');
      if (d.children.get(n.id).length) L.push(`*Enables:* ${d.children.get(n.id).map(c => xref(byId, c)).join(', ')}` + ' +');
      if ((n.rivals ?? []).length) L.push(`*Rivals:* ${n.rivals.map(t => xref(byId, t)).join(', ')}` + ' +');
      if (n.status === 'blocked') L.push(`*Blocked by:* ${n.blocked_by}` + ' +');
      if ((n.evidence ?? []).length) L.push(`*Evidence:* ${n.evidence.map(ev => ev.path ? `\`${ev.path}\`` : ev.claim ? `${ev.claim} at ${ev.min_pwg ?? 'PWG-3'} or above` : `ADR ${ev.adr} accepted`).join('; ')}` + ' +');
      if (n.value && Object.keys(n.value).length) L.push(`*Value (judgement):* ${VALUE_KEYS.filter(k => n.value[k]).map(k => `${k} ${'●'.repeat(n.value[k])}`).join(', ')}` + ' +');
      if ((n.refs ?? []).length) L.push(`*See:* ${n.refs.join('; ')}` + ' +');
      if (L[L.length - 1].endsWith(' +')) L[L.length - 1] = L[L.length - 1].slice(0, -2);
      L.push('');
      const counsel = Object.entries(n.counsel ?? {});
      if (counsel.length) {
        for (const [a, text] of counsel) {
          const adv = advisors.find(x => x.id === a);
          L.push(`* ${adv.glyph} _${adv.name}:_ ${text}`);
        }
        L.push('');
      }
    }
  }

  L.push('== Return tickets');
  L.push('');
  L.push('Wandering off the tree is allowed. Each trip gets a card: what, why, and how big.');
  L.push('On return it is grafted onto the tree as a node, or archived with what it taught.');
  L.push('');
  if (!expeditions.length) L.push('No trip is out.');
  else {
    L.push('[cols="1,1,3,3,3",options="header"]');
    L.push('|===');
    L.push('|Card |Date |What |Why |Outcome');
    for (const x of expeditions) {
      const out = x.status === 'out' ? '🎒 out' : x.status === 'grafted' ? `🌿 grafted as ${xref(byId, x.graft)}` : `📦 archived: ${cell(x.lesson)}`;
      L.push(`|${x.id} |${x.date} |${cell(x.what)} |${cell(x.why)} |${out}`);
    }
    L.push('|===');
  }
  L.push('');

  L.push('== Beyond this repository');
  L.push('');
  L.push('Nodes whose work lands in another repository. They are listed here so they can be');
  L.push('carried to that repository, not done here.');
  L.push('');
  const beyond = nodes.filter(n => n.where).sort((a, b) => (a.where < b.where ? -1 : a.where > b.where ? 1 : a.id < b.id ? -1 : 1));
  if (!beyond.length) L.push('None.');
  for (const n of beyond) L.push(`* ${n.where}: ${xref(byId, n.id)} (${n.status})`);
  L.push('');
  return L.join('\n');
}

// ── Rendering: SVG ───────────────────────────────────────────────────────────
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const clip = (s, n) => [...s].length <= n ? s : [...s].slice(0, n - 1).join('') + '…';

export function renderSvg(byId, d) {
  const COL = 250, BOX_W = 214, BOX_H = 50, GAP = 14, TOP = 96, LEFT = 24;
  const maxDepth = Math.max(0, ...[...d.depth.values()]);
  const cols = Array.from({length: maxDepth + 1}, () => []);
  for (const n of byId.values()) cols[d.depth.get(n.id)].push(n);
  // Order each column by track, then by where its needs sit, so edges cross less.
  const yOf = new Map();
  for (let k = 0; k <= maxDepth; k++) {
    const bary = n => {
      const ys = (n.needs ?? []).map(t => yOf.get(t)).filter(v => v !== undefined);
      return ys.length ? ys.reduce((a, b) => a + b, 0) / ys.length : -1;
    };
    cols[k].sort((a, b) => TRACKS.indexOf(a.track) - TRACKS.indexOf(b.track) || bary(a) - bary(b) || (a.id < b.id ? -1 : 1));
    cols[k].forEach((n, i) => yOf.set(n.id, TOP + i * (BOX_H + GAP)));
  }
  const tallest = Math.max(1, ...cols.map(c => c.length));
  const W = LEFT * 2 + (maxDepth + 1) * COL - (COL - BOX_W);
  const H = TOP + tallest * (BOX_H + GAP) + 70;
  const frontier = new Set(d.frontier.map(n => n.id));
  const xOf = id => LEFT + d.depth.get(id) * COL;
  const o = [];
  // The SVG namespace is an identifier, never fetched, and XML Namespaces 1.0 fixes it as http.
  o.push(`<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-labelledby="t d" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif">`); // hypatia: allow code_safety/js_http_url_in_code -- the SVG namespace URI is an identifier, not a fetched URL
  o.push('<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->');
  o.push('<!-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) -->');
  o.push(`<title id="t">The Mathesis tech tree</title>`);
  o.push(`<desc id="d">Generated by scripts/ultraplan/ultraplan.mjs from docs/ultraplan/tree.jsonl. ${byId.size} nodes in ${maxDepth + 1} eras; each arrow runs from a node to a node it enables.</desc>`);
  o.push(`<rect x="0" y="0" width="${W}" height="${H}" rx="18" fill="#fffdf7" stroke="#e8dcc0"/>`);
  o.push(`<text x="${LEFT}" y="34" font-size="20" font-weight="700" fill="#4a3f2a">🦉 Mathesis tech tree</text>`);
  o.push(`<text x="${LEFT}" y="54" font-size="12" fill="#7a6a4a">each arrow: this enables that · gold border: start it now · ✅ done 🔨 active 🌱 open ⛔ blocked 🍂 dropped</text>`);
  for (let k = 0; k <= maxDepth; k++) {
    const [g, name] = era(k);
    const x = LEFT + k * COL;
    o.push(`<rect x="${x - 6}" y="64" width="${BOX_W + 12}" height="${H - 80}" rx="12" fill="${k % 2 ? '#fbf6ea' : '#f7f0de'}"/>`);
    o.push(`<text x="${x + BOX_W / 2}" y="84" font-size="13" font-weight="600" text-anchor="middle" fill="#6b5a36">${esc(`${g} ${name}`)}</text>`);
  }
  for (const n of byId.values()) {
    for (const t of n.needs ?? []) {
      const x1 = xOf(t) + BOX_W, y1 = yOf.get(t) + BOX_H / 2, x2 = xOf(n.id), y2 = yOf.get(n.id) + BOX_H / 2;
      const dx = Math.max(30, (x2 - x1) / 2);
      const hot = frontier.has(n.id);
      o.push(`<path d="M${x1},${y1} C${x1 + dx},${y1} ${x2 - dx},${y2} ${x2},${y2}" fill="none" stroke="${hot ? '#d4a017' : '#b9ab8c'}" stroke-width="${hot ? 2 : 1.3}" opacity="${n.status === 'dropped' ? 0.35 : 0.85}"/>`);
    }
  }
  for (const n of byId.values()) {
    const x = xOf(n.id), y = yOf.get(n.id);
    const hot = frontier.has(n.id);
    const faded = n.status === 'dropped' ? ' opacity="0.45"' : '';
    o.push(`<g${faded}>`);
    o.push(`<title>${esc(`${n.name}: ${n.summary}`)}</title>`);
    o.push(`<rect x="${x}" y="${y}" width="${BOX_W}" height="${BOX_H}" rx="12" fill="${TRACK_FILL[n.track]}" stroke="${hot ? '#d4a017' : '#a8977a'}" stroke-width="${hot ? 3 : 1}"${n.status === 'blocked' ? ' stroke-dasharray="5 3"' : ''}/>`);
    o.push(`<text x="${x + 10}" y="${y + 21}" font-size="15">${esc(n.glyph)}</text>`);
    o.push(`<text x="${x + 34}" y="${y + 21}" font-size="12.5" font-weight="600" fill="#2f2a20">${esc(clip(n.name, 22))}</text>`);
    o.push(`<text x="${x + 34}" y="${y + 39}" font-size="10.5" fill="#6b5f48">${esc(`${TRACK_GLYPH[n.track]} ${n.track} · ${n.size}${n.where ? ' · 🌍' : ''}`)}</text>`);
    o.push(`<text x="${x + BOX_W - 8}" y="${y + 20}" font-size="14" text-anchor="end">${STATUS_GLYPH[n.status]}</text>`);
    o.push('</g>');
  }
  let lx = LEFT;
  const ly = H - 22;
  for (const t of TRACKS) {
    o.push(`<rect x="${lx}" y="${ly - 12}" width="16" height="16" rx="4" fill="${TRACK_FILL[t]}" stroke="#a8977a"/>`);
    o.push(`<text x="${lx + 22}" y="${ly + 1}" font-size="11.5" fill="#4a3f2a">${esc(`${TRACK_GLYPH[t]} ${t}`)}</text>`);
    lx += 128;
  }
  o.push(`<text x="${lx + 8}" y="${ly + 1}" font-size="11.5" fill="#4a3f2a">🌍 lands in another repository</text>`);
  o.push('</svg>');
  return o.join('\n') + '\n';
}

// ── Driver ───────────────────────────────────────────────────────────────────
export function context(root = ROOT) {
  const decisions = path.join(root, 'docs/decisions');
  return {
    isFile: p => { try { return statSync(path.join(root, p)).isFile(); } catch { return false; } },
    read: p => readFileSync(path.join(root, p), 'utf8'),
    registry: existsSync(path.join(root, 'docs/atlas/generated/registry.adoc')) ? readFileSync(path.join(root, 'docs/atlas/generated/registry.adoc'), 'utf8') : '',
    adrFile: n => {
      const f = existsSync(decisions) && readdirSync(decisions).find(x => x.startsWith(`${n}-`) && x.endsWith('.adoc') && !x.includes('template'));
      return f ? `docs/decisions/${f}` : null;
    },
  };
}

export function generate(root = ROOT) {
  const read = f => readSource(readFileSync(path.join(root, DIR, f), 'utf8'), `${DIR}/${f}`);
  const data = {advisors: read('advisors.jsonl'), nodes: read('tree.jsonl'), expeditions: read('expeditions.jsonl')};
  const byId = validate(data, context(root));
  const d = derive(byId, data.advisors);
  return {[VIEW]: renderAdoc(byId, data.advisors, data.expeditions, d), [SVG]: renderSvg(byId, d), derived: d, byId};
}

if (import.meta.main) {
  const cmd = process.argv[2];
  if (!['build', 'check'].includes(cmd)) { console.error('usage: ultraplan.mjs build|check'); process.exit(2); }
  let out;
  try { out = generate(); } catch (e) { console.error(`ultraplan: FAIL\n${e.message}`); process.exit(1); }
  const files = [VIEW, SVG];
  if (cmd === 'build') {
    mkdirSync(path.join(ROOT, DIR, 'generated'), {recursive: true});
    for (const f of files) writeFileSync(path.join(ROOT, f), out[f]);
    console.log(`WROTE ${files.join(' and ')} (${out.byId.size} nodes, ${out.derived.frontier.length} on the frontier)`);
  } else {
    const stale = files.filter(f => !existsSync(path.join(ROOT, f)) || readFileSync(path.join(ROOT, f), 'utf8') !== out[f]);
    if (stale.length) { console.error(`ultraplan: FAIL\nstale: ${stale.join(', ')}; run: bun scripts/ultraplan/ultraplan.mjs build`); process.exit(1); }
    console.log(`PASS: the ultraplan views match the data (${out.byId.size} nodes, ${out.derived.frontier.length} on the frontier)`);
  }
}
