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
import {readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, statSync, realpathSync} from 'node:fs';
import path from 'node:path';
import {parseJsonl} from '../atlas/census-atlas.mjs';
import {jcs} from '../registry/theory-ledger.mjs';
import {isClaimId} from '../registry/claims-registry.mjs';

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
export const SPECIAL_ADVISORS = ['contrarian', 'me'];
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

// A lowercase slug that begins with a letter: a node's id is also its AsciiDoc
// anchor, and an anchor cannot begin with a digit.
const SLUG = /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/;
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
// I-JSON (RFC 7493 §2.1) refuses a string or a member name that holds a lone
// surrogate or a Unicode noncharacter (U+FDD0 to U+FDEF, and the last two code
// points of every plane). JSON.parse accepts both and JSON.stringify writes them
// back unchanged, so they are refused here, as the I-JSON gate refuses them.
const isNonchar = cp => (cp >= 0xFDD0 && cp <= 0xFDEF) || (cp & 0xFFFE) === 0xFFFE;
const isIJsonString = s => s.isWellFormed() && ![...s].some(c => isNonchar(c.codePointAt(0)));
export function wellFormed(v) {
  if (typeof v === 'string') return isIJsonString(v);
  if (Array.isArray(v)) return v.every(wellFormed);
  if (v !== null && typeof v === 'object') return Object.entries(v).every(([k, x]) => isIJsonString(k) && wellFormed(x));
  return true;
}

// Each text in the plan is one line: a control character (a line break among
// them) would let a text start a line of the page, where AsciiDoc reads block
// syntax. This is the plan's own rule, stricter than I-JSON.
const hasControl = s => /[\u0000-\u001f\u007f-\u009f]/.test(s);
function oneLine(v) {
  if (typeof v === 'string') return !hasControl(v);
  if (Array.isArray(v)) return v.every(oneLine);
  if (v !== null && typeof v === 'object') return Object.entries(v).every(([k, x]) => !hasControl(k) && oneLine(x));
  return true;
}
// A description-list marker ("::", ":::", "::::" or ";;", then a blank or the
// end) makes Asciidoctor read the line that holds it as a list term, wherever
// in the line it sits, so no prefix such as {empty} keeps it text. No text in
// the plan may hold one.
const LIST_MARKER = /(?::{2,4}|;;)(?:[ \t]|$)/;
function noListMarker(v) {
  if (typeof v === 'string') return !LIST_MARKER.test(v);
  if (Array.isArray(v)) return v.every(noListMarker);
  if (v !== null && typeof v === 'object') return Object.entries(v).every(([k, x]) => !LIST_MARKER.test(k) && noListMarker(x));
  return true;
}

export function readSource(text, name) {
  const rows = parseJsonl(text, name);
  const lines = text === '' ? [] : text.slice(0, -1).split('\n');
  rows.forEach((r, i) => {
    if (!wellFormed(r)) throw new Error(`${name}: line ${i + 1} holds a lone surrogate or a Unicode noncharacter, which I-JSON refuses`);
    if (!oneLine(r)) throw new Error(`${name}: line ${i + 1} holds a control character; each text in the plan is one line`);
    if (!noListMarker(r)) throw new Error(`${name}: line ${i + 1} holds a description-list marker (:: or ;; before a blank or the end), which would make its line of the page a list term`);
    if (jcs(r) !== lines[i]) throw new Error(`${name}: line ${i + 1} is not in JCS form (RFC 8785); write it as ${jcs(r)}`);
  });
  return rows;
}

// ── Rules ────────────────────────────────────────────────────────────────────
// The checks are data. A rule is [holds, message]: holds(record, env) is true
// when the record keeps the rule, and the message says what it must be.
const list = v => (Array.isArray(v) ? v : []);
// Byte order, the same in every locale, so the views are deterministic.
const cmp = (a, b) => (a < b ? -1 : Number(a > b));
const oneOf = (name, allowed) => `${name} must be one of ${allowed.join(', ')}`;

function closed(obj, allowed, where) {
  if (obj === null || typeof obj !== 'object' || Array.isArray(obj)) throw new Error(`${where}: must be an object`);
  for (const k of Object.keys(obj)) if (!allowed.includes(k)) throw new Error(`${where}: unknown field "${k}"`);
}
// Whether a record is an object with only the allowed fields; a failure is recorded.
function isClosed(obj, allowed, where, fail) {
  try { closed(obj, allowed, where); return true; } catch (e) { fail(e.message); return false; }
}
function applyRules(rules, rec, env, where, fail) {
  for (const [holds, message] of rules) if (!holds(rec, env)) fail(`${where}: ${message}`);
}

// ── Evidence ─────────────────────────────────────────────────────────────────
// The grade the registry view derives for a claim id, or null when the view
// does not list it. The view is generated and checked by registry-check.
// A registry row opens with its claim cell (a link whose label is the claim id),
// then its kind and its grade. Only the claim cell names the row's claim: an id
// mentioned in another row's statement is not that claim's row. The link runs
// to the first "[", so the pattern matches in linear time.
const ROW = /^\|https:\/\/[^\s[]*\[([^\]]+)\][^|]* \|(?:theorem|demonstration|assumption) \|`(PWG-1|PWG-2ii|PWG-2i|PWG-3|ungraded)` \|/;
export function registryGrade(registryText, id) {
  for (const line of registryText.split('\n')) {
    const m = ROW.exec(line);
    if (m && m[1] === id) return m[2];
  }
  return null;
}

// Whether an ADR's Status section opens with "Accepted", as AsciiDoc reads it.
// It must never say yes where Asciidoctor finds no such section. So it does not
// try to mirror every way Asciidoctor reads a heading: it over-counts, and it
// accepts one plain shape only (it fails closed).
// - Every line that could be a heading titled Status counts, inside a block or
//   not: "=" or "#" markers and a blank, then a title that holds the letters
//   "status" in any case, or a reference that could spell them. An ADR with a
//   count other than one is not read.
// - That one line is "==" to "======", one space and "Status"; it is outside any
//   delimited block; and it follows a blank line, with nothing above it, across
//   blank lines and comments, that attaches it to what came before: a block
//   attribute line, a block title, a list continuation or a description-list term.
// - The first line after it, past blank lines and comments, is text that begins
//   "Accepted": not indented, and holding no description-list marker.
// - No text line stands over an underline ("-", "=", "~", "^" or "+" repeated)
//   of about its length: Asciidoctor reads such a pair as a section title.
// - A preprocessor directive could change which lines count, so an ADR that
//   holds one is not read.
// A delimiter is one of these characters four or more times, "--", or a table's "|===".
// It closes on the same line again.
const DELIMITER = /^(?:([/\-.+*=_])\1{3,}|--|[|,:!]={3,})$/;
// A Markdown fence, which Asciidoctor reads too: three backticks open it, with
// any language after them but never a fourth backtick, and only a line of
// exactly three backticks closes it. "````" and "~~~" delimit nothing.
const FENCE = /^```(?!`)/;
const opener = l => {
  if (DELIMITER.test(l)) return l;
  return FENCE.test(l) ? '```' : null;
};
const PREPROCESSOR = /^(?:ifdef|ifndef|ifeval|endif|include)::/;
// "//" begins a line comment, but "///" begins text.
const COMMENT = /^\/\/(?!\/)/;
// What each line is: inside a delimited block or one of its delimiters
// ('block'), part of a comment, which AsciiDoc drops ('comment'), or text.
const kindOf = (l, block) => {
  if (block) return block.startsWith('//') ? 'comment' : 'block';
  return COMMENT.test(l) ? 'comment' : 'text';
};
function lineKinds(lines) {
  let open = null;
  return lines.map(l => {
    const block = open ?? opener(l);
    const closes = open !== null && l === open;
    open = closes ? null : block;
    return kindOf(l, block);
  });
}
// A heading in any form AsciiDoc or Markdown gives one, whose title could read "Status".
const HEADING = /^[=#]+[ \t]+(.*)$/;
const mayBeStatus = l => {
  const m = HEADING.exec(l);
  return m !== null && (/\{|&#?\w+;/.test(m[1]) || /status/i.test(m[1].replace(/[^\p{L}]/gu, '')));
};
// Asciidoctor reads a line over an underline within one character of its
// length as a two-line section title; two characters are allowed here.
const UNDERLINE = /^([-=~^+])\1+$/;
const width = s => [...s].length;
const overUnderline = (lines, kinds, i) => kinds[i] === 'text' && lines[i] !== '' && UNDERLINE.test(lines[i + 1] ?? '')
  && Math.abs(width(lines[i + 1]) - width(lines[i])) <= 2;
// What, standing above a heading across blank lines and comments, attaches the
// heading to it: a block attribute line, a block title, a list continuation or
// a description-list term.
const ATTACHES = /^(?:\[.*\]|\.[^.\s].*|\+)$|(?::{2,4}|;;)(?:[ \t]|$)/;
function startsSection(lines, kinds, i) {
  if (i > 0 && lines[i - 1] !== '') return false;
  let j = i - 1;
  while (j >= 0 && (lines[j] === '' || kinds[j] === 'comment')) j--;
  return j < 0 || !ATTACHES.test(lines[j]);
}
export function adrAccepted(text) {
  const lines = text.split('\n').map(l => l.trimEnd());
  if (lines.some(l => PREPROCESSOR.test(l))) return false;
  const kinds = lineKinds(lines);
  if (lines.some((_, i) => overUnderline(lines, kinds, i))) return false;
  const heads = lines.flatMap((l, i) => (mayBeStatus(l) ? [i] : []));
  if (heads.length !== 1) return false;
  const [h] = heads;
  if (kinds[h] !== 'text' || !/^={2,6} Status$/.test(lines[h]) || !startsSection(lines, kinds, h)) return false;
  // The heading is text, so the line after it is text too, unless it opens a
  // block, and no delimiter that opens one begins "Accepted".
  const n = lines.findIndex((l, i) => i > h && l !== '' && kinds[i] !== 'comment');
  return n > h && /^\**Accepted\b/.test(lines[n]) && !LIST_MARKER.test(lines[n]);
}

// One check for each kind of evidence; each returns an error or null.
const EVIDENCE = {
  path(ev, ctx) {
    const p = ev.path;
    if (!isStr(p, 300) || p.startsWith('/') || p.split('/').includes('..')) return `evidence path ${JSON.stringify(p)} is not a repository path`;
    return ctx.isFile(p) ? null : `evidence path ${p} is not a file in the repository`;
  },
  claim(ev, ctx) {
    // The registry's own rule, so any claim it can list can be cited here.
    if (!isStr(ev.claim) || !isClaimId(ev.claim)) return `evidence claim ${JSON.stringify(ev.claim)} is not OWNER/REPO#ID`;
    const min = ev.min_pwg ?? 'PWG-3';
    if (!PWG_ORDER.includes(min) || min === 'ungraded') return `evidence min_pwg ${JSON.stringify(min)} is not a grade`;
    const got = registryGrade(ctx.registry, ev.claim);
    if (got === null) return `the registry view does not list ${ev.claim}`;
    return PWG_ORDER.indexOf(got) >= PWG_ORDER.indexOf(min) ? null : `${ev.claim} derives ${got}, below ${min}`;
  },
  adr(ev, ctx) {
    if (!isStr(ev.adr) || !/^\d{4}$/.test(ev.adr)) return `evidence adr ${JSON.stringify(ev.adr)} is not a four-digit ADR number`;
    const files = ctx.adrFiles(ev.adr);
    if (!files.length) return `no ADR ${ev.adr} in docs/decisions`;
    if (files.length > 1) return `ADR ${ev.adr} is ambiguous: ${files.join(', ')} share the number`;
    const [file] = files;
    if (!ctx.isFile(file)) return `ADR ${ev.adr} (${file}) is not a file in the repository`;
    return adrAccepted(ctx.read(file)) ? null : `ADR ${ev.adr} is not Accepted`;
  },
};

// Check one evidence item against the repository; return an error or null.
export function checkEvidence(ev, ctx) {
  closed(ev, ['path', 'claim', 'min_pwg', 'adr'], 'evidence');
  const kinds = Object.keys(EVIDENCE).filter(k => k in ev);
  if (kinds.length !== 1) return 'an evidence item names exactly one of path, claim or adr';
  if (ev.min_pwg !== undefined && ev.claim === undefined) return 'min_pwg belongs to claim evidence only';
  return EVIDENCE[kinds[0]](ev, ctx);
}
const evidenceError = (ev, ctx) => { try { return checkEvidence(ev, ctx); } catch (e) { return e.message; } };

// ── References ───────────────────────────────────────────────────────────────
// A ref points at one place, and no ref types a line number, which goes stale
// with the next edit. A ref into this repository is checked: its path exists,
// and its quote ("at") occurs in the file exactly once, so a ref whose passage
// was reworded, moved away or repeated is refused, never left pointing nowhere.
// A ref into another repository names a full commit, so its content cannot
// drift; it is not checked here. An issue ref names a GitHub issue or pull request.
const REF_FIELDS = ['path', 'at', 'repo', 'commit', 'issue'];
const isRepoPath = p => isStr(p, 300) && p.split('/').every(s => /^[-\w.]+$/.test(s) && s !== '.' && s !== '..');
// The page shows a quote verbatim in a literal code span, which a backtick, a
// plus or a backslash could end early.
const isQuote = s => isStr(s, 160) && !/[`+\\]/.test(s);
const occurrences = (text, s) => text.split(s).length - 1;
const REF = {
  issue: r => (Object.keys(r).length === 1 && typeof r.issue === 'string' && /^[\w.-]+\/[\w.-]+#[1-9]\d*$/.test(r.issue)
    ? null : `ref issue ${JSON.stringify(r.issue)} is not OWNER/REPO#N, alone`),
  pinned(r) {
    if (typeof r.repo !== 'string' || !/^[\w.-]+\/[\w.-]+$/.test(r.repo)) return `ref repo ${JSON.stringify(r.repo)} is not OWNER/REPO`;
    return typeof r.commit === 'string' && /^[0-9a-f]{40}$/.test(r.commit) ? null : `ref commit ${JSON.stringify(r.commit)} is not a full commit id`;
  },
  here(r, ctx) {
    if (r.at === undefined) return ctx.exists(r.path) ? null : `ref path ${r.path} is not in the repository`;
    if (!ctx.isFile(r.path)) return `ref path ${r.path} is not a file in the repository`;
    const k = occurrences(ctx.read(r.path), r.at);
    return k === 1 ? null : `ref ${r.path} holds ${JSON.stringify(r.at)} ${k} times; a ref quotes a passage that occurs exactly once`;
  },
};
const refKind = r => {
  if (r.issue !== undefined) return 'issue';
  return r.repo !== undefined || r.commit !== undefined ? 'pinned' : 'here';
};

// Check one ref; return an error or null.
export function checkRef(r, ctx) {
  closed(r, REF_FIELDS, 'ref');
  const kind = refKind(r);
  if (kind === 'issue') return REF.issue(r);
  if (!isRepoPath(r.path)) return `ref path ${JSON.stringify(r.path)} is not a repository path`;
  if (r.at !== undefined && !isQuote(r.at)) return `ref at ${JSON.stringify(r.at)} is not a short quote without a backtick, plus or backslash`;
  return REF[kind](r, ctx);
}
const refError = (r, ctx) => { try { return checkRef(r, ctx); } catch (e) { return e.message; } };

// ── Validation: the council ──────────────────────────────────────────────────
const ADVISOR_FIELDS = ['id', 'name', 'glyph', 'asks', 'reads', 'private'];
const ADVISOR_RULES = [
  ...['name', 'glyph', 'asks'].map(k => [a => isStr(a[k]), `${k} is required`]),
  [a => a.reads === undefined || VALUE_KEYS.includes(a.reads), oneOf('reads', VALUE_KEYS)],
  [a => a.private === undefined || a.private === true, 'private is true or absent'],
  // Exactly the me advisor is private: its ranking and the page's privacy claim depend on it.
  [a => a.id !== 'me' || a.private === true, 'must be private ("private":true)'],
  [a => a.id === 'me' || a.private === undefined, 'only the me advisor is private'],
  // The contrarian and the me advisor have their own ranking; every other advisor ranks by one mark.
  [a => !SPECIAL_ADVISORS.includes(a.id) || a.reads === undefined, 'reads no value mark (it has its own ranking)'],
  [a => SPECIAL_ADVISORS.includes(a.id) || a.reads !== undefined, 'reads is required (the value mark it ranks by)'],
];

function checkAdvisors(advisors, fail) {
  const ids = new Set();
  for (const a of advisors) {
    if (!isClosed(a, ADVISOR_FIELDS, `advisor ${a?.id}`, fail)) continue;
    if (!isStr(a.id, 40) || !SLUG.test(a.id) || ids.has(a.id)) fail(`advisor id ${JSON.stringify(a.id)} is missing, not a slug, or repeated`);
    ids.add(a.id);
    applyRules(ADVISOR_RULES, a, null, `advisor ${a.id}`, fail);
  }
  if (!ids.has('me')) fail('advisors: the me advisor is required ("id":"me","private":true)');
  return ids;
}

// ── Validation: the nodes ────────────────────────────────────────────────────
const NODE_FIELDS = ['id', 'name', 'glyph', 'track', 'kind', 'status', 'size', 'summary', 'needs', 'rivals', 'value',
  'counsel', 'evidence', 'blocked_by', 'where', 'owner_value', 'refs'];
const NODE_RULES = [
  [n => isStr(n.name, 80), 'name is required (at most 80 characters)'],
  [n => isStr(n.glyph, 16), 'glyph is required'],
  [n => TRACKS.includes(n.track), oneOf('track', TRACKS)],
  [n => KINDS.includes(n.kind), oneOf('kind', KINDS)],
  [n => STATUSES.includes(n.status), oneOf('status', STATUSES)],
  [n => isSize(n.size), oneOf('size', Object.keys(SIZES))],
  [n => isStr(n.summary, 600), 'summary is required (at most 600 characters)'],
  ...['needs', 'rivals', 'evidence', 'refs'].map(k => [n => n[k] === undefined || Array.isArray(n[k]), `${k} must be a list`]),
  [n => n.where === undefined || (typeof n.where === 'string' && /^(estate|upstream):[\w.-]+\/[\w.-]+$/.test(n.where)),
    'where is estate:OWNER/REPO or upstream:OWNER/REPO, or absent for this repository'],
  [n => n.owner_value === undefined || n.owner_value === 'high', 'owner_value is "high" or absent'],
  [n => n.status !== 'blocked' || isStr(n.blocked_by), 'a blocked node says what blocks it (blocked_by)'],
  [n => n.status === 'blocked' || n.blocked_by === undefined, 'blocked_by belongs to a blocked node only'],
];

function checkValue(n, where, fail) {
  if (n.value === undefined) return;
  isClosed(n.value, VALUE_KEYS, `${where} value`, fail);
  for (const [k, v] of Object.entries(n.value ?? {})) if (!Number.isInteger(v) || v < 0 || v > 3) fail(`${where}: value.${k} must be 0, 1, 2 or 3`);
}

function checkCounsel(n, advisorIds, where, fail) {
  if (n.counsel === undefined) return;
  if (n.counsel === null || typeof n.counsel !== 'object' || Array.isArray(n.counsel)) { fail(`${where}: counsel must be an object`); return; }
  for (const [k, v] of Object.entries(n.counsel)) {
    if (k === 'me') fail(`${where}: counsel.me is refused; the me advisor's notes stay outside the public repository`);
    else if (!advisorIds.has(k)) fail(`${where}: counsel from unknown advisor ${k}`);
    if (!isStr(v, 300)) fail(`${where}: counsel.${k} must be a short text`);
  }
}

function checkNodes(nodes, advisorIds, fail) {
  const byId = new Map();
  for (const n of nodes) {
    const where = `node ${n?.id}`;
    if (!isClosed(n, NODE_FIELDS, where, fail)) continue;
    if (!isStr(n.id, 60) || !SLUG.test(n.id)) { fail(`${where}: id must be a lowercase slug that begins with a letter`); continue; }
    if (byId.has(n.id)) { fail(`${where}: repeated id`); continue; }
    byId.set(n.id, n);
    applyRules(NODE_RULES, n, null, where, fail);
    checkValue(n, where, fail);
    checkCounsel(n, advisorIds, where, fail);
  }
  return byId;
}

// ── Validation: the edges ────────────────────────────────────────────────────
// needs and rivals name known nodes, never the node itself, and each at most once.
function checkNames(n, k, byId, fail) {
  const seen = new Set();
  for (const t of list(n[k])) {
    if (!byId.has(t)) fail(`node ${n.id}: ${k} names unknown node ${t}`);
    if (t === n.id) fail(`node ${n.id}: ${k} names itself`);
    if (seen.has(t)) fail(`node ${n.id}: ${k} names ${t} twice`);
    seen.add(t);
  }
}

function checkLinks(n, byId, fail) {
  checkNames(n, 'needs', byId, fail);
  checkNames(n, 'rivals', byId, fail);
  for (const r of list(n.rivals)) if (byId.has(r) && !list(byId.get(r).rivals).includes(n.id)) fail(`node ${n.id}: rival ${r} does not name ${n.id} back`);
}

// What a node's status asks of it: a done node shows evidence, a started
// node's evidence holds, and only a started node carries evidence.
function checkStarted(n, byId, ctx, fail) {
  const where = `node ${n.id}`;
  if (n.status === 'done' && !list(n.evidence).length) fail(`${where}: done needs evidence (a path, a claim grade or an accepted ADR)`);
  if (n.status !== 'done' && n.status !== 'active') {
    if (n.evidence !== undefined) fail(`${where}: evidence belongs to a done or active node`);
    return;
  }
  // Evidence an active node shows must hold as much as a done node's.
  for (const ev of list(n.evidence)) {
    const e = evidenceError(ev, ctx);
    if (e) fail(`${where}: ${e}`);
  }
  // A node is started only from the frontier, so an active node's needs are done too.
  for (const t of list(n.needs)) if (byId.get(t)?.status !== 'done') fail(`${where}: ${n.status}, but its need ${t} is not done`);
}

// Every ref of every node holds, whatever the node's status.
function checkRefs(n, ctx, fail) {
  for (const r of list(n.refs)) {
    const e = refError(r, ctx);
    if (e) fail(`node ${n.id}: ${e}`);
  }
}

// The needs form a DAG.
function checkAcyclic(byId, fail) {
  const state = new Map();
  const visit = (id, trail) => {
    if (state.get(id) === 2) return;
    if (state.get(id) === 1) { fail(`the needs form a cycle: ${[...trail, id].join(' -> ')}`); return; }
    state.set(id, 1);
    for (const t of list(byId.get(id)?.needs)) if (byId.has(t)) visit(t, [...trail, id]);
    state.set(id, 2);
  };
  for (const id of byId.keys()) visit(id, []);
}

function checkActiveLimit(byId, fail) {
  const active = [...byId.values()].filter(n => n.status === 'active');
  if (active.length > ACTIVE_LIMIT) fail(`${active.length} nodes are active (${active.map(n => n.id).join(', ')}); at most ${ACTIVE_LIMIT} may be, so finish or park one first`);
}

// ── Validation: the return tickets ───────────────────────────────────────────
const EXPEDITION_FIELDS = ['id', 'what', 'why', 'size', 'date', 'status', 'graft', 'lesson'];
const EXPEDITION_RULES = [
  ...['what', 'why'].map(k => [x => isStr(x[k]), `${k} is required`]),
  [x => isSize(x.size), oneOf('size', Object.keys(SIZES))],
  [x => isDate(x.date), 'date is a real calendar date, YYYY-MM-DD'],
  [x => ['out', 'grafted', 'archived'].includes(x.status), 'status is out, grafted or archived'],
  [(x, byId) => x.status !== 'grafted' || byId.has(x.graft), 'a grafted expedition names the node it became (graft)'],
  [x => x.status === 'grafted' || x.graft === undefined, 'graft belongs to a grafted expedition'],
  [x => x.status !== 'archived' || isStr(x.lesson), 'an archived expedition records what it taught (lesson)'],
  [x => x.status === 'archived' || x.lesson === undefined, 'lesson belongs to an archived expedition'],
];

// The rule tables, exported so the tests can show that every rule has a witness.
export const RULES = {advisor: ADVISOR_RULES, node: NODE_RULES, expedition: EXPEDITION_RULES};

function checkExpeditions(expeditions, byId, fail) {
  const ids = new Set();
  for (const x of expeditions) {
    const where = `expedition ${x?.id}`;
    if (!isClosed(x, EXPEDITION_FIELDS, where, fail)) continue;
    if (!isStr(x.id, 20) || !/^X-\d{3}$/.test(x.id) || ids.has(x.id)) fail(`${where}: id is X-NNN and unique`);
    ids.add(x.id);
    applyRules(EXPEDITION_RULES, x, byId, where, fail);
  }
}

// ── Validation ───────────────────────────────────────────────────────────────
// Every failure is collected, so one run reports them all.
export function validate({advisors, nodes, expeditions}, ctx) {
  const errors = [];
  const fail = m => errors.push(m);
  const advisorIds = checkAdvisors(advisors, fail);
  const byId = checkNodes(nodes, advisorIds, fail);
  for (const n of byId.values()) { checkLinks(n, byId, fail); checkStarted(n, byId, ctx, fail); checkRefs(n, ctx, fail); }
  checkAcyclic(byId, fail);
  checkActiveLimit(byId, fail);
  checkExpeditions(expeditions, byId, fail);
  if (errors.length) throw new Error(errors.join('\n'));
  return byId;
}

// ── Derivation ───────────────────────────────────────────────────────────────
// Each advisor's pick from the frontier. An advisor that reads a value key
// ranks the nodes it marks above zero by that mark, then as the council
// ranks: by leverage, then by value for effort. The contrarian takes the
// frontier node the council rates lowest that still unlocks the most. The me
// advisor reads no mark, since another advisor's mark is not the owner's
// preference: it ranks the nodes the owner tagged owner_value as the council
// ranks, and has no notes.
function pickFor(a, frontier, total, leverage) {
  const first = (pool, order) => [...pool].sort(order)[0] ?? null;
  const council = (x, y) => leverage(y.id) - leverage(x.id) || total(y) / SIZES[y.size] - total(x) / SIZES[x.size] || cmp(x.id, y.id);
  const byKey = k => (x, y) => (y.value?.[k] ?? 0) - (x.value?.[k] ?? 0) || council(x, y);
  if (a.id === 'contrarian') return first(frontier, (x, y) => total(x) - total(y) || leverage(y.id) - leverage(x.id) || cmp(x.id, y.id));
  // The me advisor names no public pick (owner ruling 2026-11-24): the owner chooses in a
  // private GELS panel, and the page lists the tagged frontier unranked (ownerTagged).
  if (a.private) return null;
  if (a.reads) return first(frontier.filter(n => (n.value?.[a.reads] ?? 0) > 0), byKey(a.reads));
  return null;
}

export function derive(byId, advisors) {
  const children = new Map([...byId.keys()].map(id => [id, []]));
  for (const n of byId.values()) for (const t of list(n.needs)) children.get(t).push(n.id);
  for (const c of children.values()) c.sort(cmp);

  const depth = new Map();
  const depthOf = id => {
    if (depth.has(id)) return depth.get(id);
    const ns = list(byId.get(id).needs);
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
  const nodes = [...byId.values()];
  // Active slots still free: when none is, the frontier is ready but cannot start.
  const slots = ACTIVE_LIMIT - nodes.filter(n => n.status === 'active').length;
  const frontier = nodes.filter(n => n.status === 'open' && list(n.needs).every(t => byId.get(t).status === 'done'));
  const total = n => Object.values(n.value ?? {}).reduce((a, b) => a + b, 0);
  const leverage = id => [...below.get(id)].filter(x => live(byId.get(x))).length;
  const tracksOf = ids => new Set(ids.map(t => byId.get(t)).filter(live).map(t => t.track));
  const byNodeId = (a, b) => cmp(a.id, b.id);

  const forks = nodes.filter(n => live(n) && tracksOf(children.get(n.id)).size >= 2).sort(byNodeId);
  const confluences = nodes.filter(n => live(n) && new Set(list(n.needs).map(t => byId.get(t).track)).size >= 2).sort(byNodeId);
  const rivalries = [];
  for (const n of nodes) for (const r of list(n.rivals)) if (n.id < r) rivalries.push([n.id, r]);

  const picks = new Map(advisors.map(a => [a.id, pickFor(a, frontier, total, leverage)]));
  // The frontier nodes the owner tagged, in id order: a list, never a ranking.
  const ownerTagged = frontier.filter(n => n.owner_value === 'high').sort(byNodeId);
  return {children, depth, below, frontier, forks, confluences, rivalries, picks, ownerTagged, leverage, total, slots};
}

// ── Rendering: AsciiDoc ──────────────────────────────────────────────────────
// The page is a list of sections; each section is a list of lines.
const cell = s => String(s).replaceAll('|', String.raw`\|`);
// A text that starts a line of the page (a node's summary) is read by AsciiDoc as
// block syntax if it looks like some: "|===" opens a table, "image::x[]" places an
// image, "//" makes a comment. "{empty}" (an attribute that is empty) in front makes
// the line a plain paragraph, whatever follows, and adds nothing to the text.
const lineStart = s => `{empty}${s}`;
const nameOf = (byId, id) => `${byId.get(id).glyph} ${byId.get(id).name}`;
// A link to a node, as the xref macro. Its text may hold anything but a few
// characters, written as character references so they mean the same everywhere,
// in a table or not: "|" (a table cell's end), "]" (the macro's end) and "="
// (which makes the text an attribute list). "<<id,text>>" cannot hold ">>".
const linkText = s => String(s).replaceAll('|', '&#124;').replaceAll(']', '&#93;').replaceAll('=', '&#61;');
const xref = (byId, id) => `xref:${id}[${linkText(nameOf(byId, id))}]`;
const xrefs = (byId, ids, sep = ', ') => ids.map(t => xref(byId, t)).join(sep);
const orNone = (items, none) => (items.length ? items : [none]);
const trackKey = t => `${TRACK_GLYPH[t]} ${t}`;

function introLines(byId, d) {
  const nodes = [...byId.values()];
  const count = s => nodes.filter(n => n.status === s).length;
  return [
    '// SPDX-License-Identifier: CC-BY-SA-4.0',
    '// GENERATED by scripts/ultraplan/ultraplan.mjs from docs/ultraplan/tree.jsonl,',
    '// docs/ultraplan/advisors.jsonl and docs/ultraplan/expeditions.jsonl; do not hand-edit.',
    '= Mathesis ultraplan: the tech tree',
    ':toc: macro',
    ':toclevels: 1',
    '',
    'Each node is a capability. Its needs are the nodes it is built on, so the tree reads',
    'like a civilisation game: one discovery enables the next. The data in',
    '`docs/ultraplan/` is the source; this page and its picture are generated from it.',
    'The era, the frontier, the forks, the confluences and each advisor\'s pick are derived,',
    'never typed. A node marked done carries evidence the generator checks: a file, a',
    'claim grade that the registry derives, or an accepted decision record. The value marks',
    'are judgements, written down so they can be argued with.',
    '',
    `Census of the tree: ${count('done')} done, ${count('active')} active (at most ${ACTIVE_LIMIT}), ${count('open')} open, ${count('blocked')} blocked, ${count('dropped')} dropped, of ${nodes.length} nodes. ${startable(d)}`,
    '',
    'toc::[]',
    '',
    'image::tree.svg[The tech tree of Mathesis, from the first era on the left to the frontier on the right]',
    '',
    'Key: ✅ done · 🔨 active · 🌱 open · ⛔ blocked · 🍂 dropped. A gold border marks a node',
    `that ${d.slots > 0 ? 'can be started now' : 'is ready, once an active slot is free'}. Colours are tracks: ${TRACKS.map(trackKey).join(' · ')}.`,
    '',
  ];
}

const beyondNote = n => (n.where ? ` _(${cell(n.where)})_` : '');
const startable = d => (d.slots > 0 ? `${d.frontier.length} can be started now.` : `${d.frontier.length} are ready, but all ${ACTIVE_LIMIT} active slots are full.`);
const slotsFull = `*All ${ACTIVE_LIMIT} active slots are full.* These nodes are ready, but none can start until an active node is finished or parked.`;
function frontierLines(byId, d) {
  const head = [
    '== Research now: the frontier',
    '',
    d.slots > 0 ? 'These open nodes have every need done, so any of them can start today. "Unlocks"'
      : 'These open nodes have every need done, so each can start once an active slot is free. "Unlocks"',
    'counts the live nodes that depend on it, directly or through others.',
    '',
  ];
  if (!d.frontier.length) return [...head, 'Nothing is on the frontier.', ''];
  if (d.slots <= 0) head.push(slotsFull, '');
  const rows = [...d.frontier].sort((a, b) => d.leverage(b.id) - d.leverage(a.id) || cmp(a.id, b.id));
  return [
    ...head,
    '[cols="3,1,1,1,5",options="header"]',
    '|===',
    '|Node |Track |Size |Unlocks |Summary',
    ...rows.map(n => `|${xref(byId, n.id)} |${n.track} |${n.size} |${d.leverage(n.id)} |${cell(n.summary)}${beyondNote(n)}`),
    '|===',
    '',
  ];
}

function pickLine(byId, a, p) {
  if (!p) return '_Pick:_ nothing on the frontier answers this advisor yet.';
  const note = p.counsel?.[a.id];
  return `_Pick:_ ${xref(byId, p.id)}${note ? '. ' + note : '.'}`;
}
// The me advisor's line: its choice is made privately, so the page shows only what the
// owner tagged, unranked.
function privateLine(byId, d) {
  const tagged = d.ownerTagged.length ? `Tagged on the frontier, in id order: ${xrefs(byId, d.ownerTagged.map(n => n.id))}.` : 'Nothing tagged is on the frontier.';
  return `_No public pick:_ the owner chooses in a private GELS panel. ${tagged}`;
}
function councilLines(byId, advisors, d) {
  return [
    '== The council',
    '',
    'Each advisor asks one question of every node and names one pick from the frontier,',
    'except the me advisor. It is private: its notes and its choice stay outside this',
    'repository, and the page lists, unranked, the frontier nodes the owner has tagged.',
    '',
    ...advisors.flatMap(a => [`=== ${a.glyph} ${a.name}`, '', `_Asks:_ ${a.asks}`, '', a.private ? privateLine(byId, d) : pickLine(byId, a, d.picks.get(a.id)), '']),
  ];
}

function forkLines(byId, d) {
  return [
    '== Forks and confluences',
    '',
    'A fork enables nodes on two or more tracks: work there spreads. A confluence needs',
    'nodes from two or more tracks: work there joins. Rivals are different routes to the',
    'same place; the contrarian keeps the road not taken in view.',
    '',
    '.Forks',
    ...orNone(d.forks.map(n => `* ${xref(byId, n.id)} -> ${xrefs(byId, d.children.get(n.id))}`), '* None yet.'),
    '',
    '.Confluences',
    ...orNone(d.confluences.map(n => `* ${xrefs(byId, list(n.needs), ' + ')} -> ${xref(byId, n.id)}`), '* None yet.'),
    '',
    '.Rivals',
    ...orNone(d.rivalries.map(([a, b]) => `* ${xref(byId, a)} or ${xref(byId, b)}`), '* None yet.'),
    '',
  ];
}

function evidenceText(ev) {
  if (ev.path) return `\`${ev.path}\``;
  if (ev.claim) return `${ev.claim} at ${ev.min_pwg ?? 'PWG-3'} or above`;
  return `ADR ${ev.adr} accepted`;
}
// A quote is shown verbatim, as a literal code span.
function refText(r) {
  if (r.issue) {
    const [repo, number] = r.issue.split('#');
    return `https://github.com/${repo}/issues/${number}[${r.issue}]`;
  }
  const at = r.at === undefined ? '' : `, at \`+${r.at}+\``;
  if (r.repo) return `https://github.com/${r.repo}/blob/${r.commit}/${r.path}[${r.repo}: ${r.path}] at \`${r.commit.slice(0, 12)}\`${at}`;
  return `\`${r.path}\`${at}`;
}
// Every mark the data holds is shown, a 0 as an open circle: a 0 is a judgement too.
const marks = value => VALUE_KEYS.filter(k => Object.hasOwn(value, k)).map(k => `${k} ${'●'.repeat(value[k]) || '○'}`).join(', ');

function nodeLines(byId, advisors, d, n) {
  const facts = [`*Track:* ${trackKey(n.track)}`, `*Kind:* ${n.kind}`, `*Size:* ${n.size}`, `*Status:* ${n.status}`];
  if (n.where) facts.push(`*Beyond this repository:* ${n.where}`);
  const enables = d.children.get(n.id);
  // Each fact the node has, one a line, joined by hard line breaks.
  const details = [
    [list(n.needs).length, () => `*Needs:* ${xrefs(byId, n.needs)}`],
    [enables.length, () => `*Enables:* ${xrefs(byId, enables)}`],
    [list(n.rivals).length, () => `*Rivals:* ${xrefs(byId, n.rivals)}`],
    [n.status === 'blocked', () => `*Blocked by:* ${n.blocked_by}`],
    [list(n.evidence).length, () => `*Evidence:* ${n.evidence.map(evidenceText).join('; ')}`],
    [n.value && Object.keys(n.value).length, () => `*Value (judgement):* ${marks(n.value)}`],
    [list(n.refs).length, () => `*See:* ${n.refs.map(refText).join('; ')}`],
  ].filter(([has]) => has).map(([, text]) => text());
  const counsel = Object.entries(n.counsel ?? {}).map(([id, text]) => {
    const adv = advisors.find(x => x.id === id);
    return `* ${adv.glyph} _${adv.name}:_ ${text}`;
  });
  return [
    `[[${n.id}]]`,
    `==== ${STATUS_GLYPH[n.status]} ${n.glyph} ${n.name}`,
    '',
    lineStart(n.summary),
    '',
    facts.join(' · '),
    '',
    ...details.map((line, i) => (i < details.length - 1 ? `${line} +` : line)),
    '',
    ...(counsel.length ? [...counsel, ''] : []),
  ];
}

function eraLines(byId, advisors, d) {
  const nodes = [...byId.values()];
  const maxDepth = Math.max(0, ...d.depth.values());
  const L = ['== The eras', ''];
  for (let k = 0; k <= maxDepth; k++) {
    const inEra = nodes.filter(n => d.depth.get(n.id) === k).sort((a, b) => TRACKS.indexOf(a.track) - TRACKS.indexOf(b.track) || cmp(a.id, b.id));
    if (!inEra.length) continue;
    const [g, name] = era(k);
    L.push(`=== ${g} Era ${k}: ${name}`, '', ...inEra.flatMap(n => nodeLines(byId, advisors, d, n)));
  }
  return L;
}

function outcomeText(byId, x) {
  if (x.status === 'out') return '🎒 out';
  if (x.status === 'grafted') return `🌿 grafted as ${xref(byId, x.graft)}`;
  return `📦 archived: ${cell(x.lesson)}`;
}
function ticketLines(byId, expeditions) {
  const head = [
    '== Return tickets',
    '',
    'Wandering off the tree is allowed. Each trip gets a card: what, why, and how big.',
    'On return it is grafted onto the tree as a node, or archived with what it taught.',
    '',
  ];
  if (!expeditions.length) return [...head, 'No trip is out.', ''];
  return [
    ...head,
    '[cols="1,1,1,3,3,3",options="header"]',
    '|===',
    '|Card |Date |Size |What |Why |Outcome',
    ...expeditions.map(x => `|${x.id} |${x.date} |${x.size} |${cell(x.what)} |${cell(x.why)} |${outcomeText(byId, x)}`),
    '|===',
    '',
  ];
}

function beyondLines(byId) {
  const beyond = [...byId.values()].filter(n => n.where).sort((a, b) => cmp(a.where, b.where) || cmp(a.id, b.id));
  return [
    '== Beyond this repository',
    '',
    'Nodes whose work lands in another repository. They are listed here so they can be',
    'carried to that repository, not done here.',
    '',
    ...orNone(beyond.map(n => `* ${n.where}: ${xref(byId, n.id)} (${n.status})`), 'None.'),
    '',
  ];
}

export function renderAdoc(byId, advisors, expeditions, d) {
  return [
    ...introLines(byId, d),
    ...frontierLines(byId, d),
    ...councilLines(byId, advisors, d),
    ...forkLines(byId, d),
    ...eraLines(byId, advisors, d),
    ...ticketLines(byId, expeditions),
    ...beyondLines(byId),
  ].join('\n');
}

// ── Rendering: SVG ───────────────────────────────────────────────────────────
const esc = s => String(s).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const clip = (s, n) => [...s].length <= n ? s : [...s].slice(0, n - 1).join('') + '…';
const COL = 250, BOX_W = 214, BOX_H = 50, GAP = 14, TOP = 96, LEFT = 24, LEGEND_STEP = 128;
const GOLD = '#d4a017', EDGE = '#b9ab8c';
// An arrowhead of fixed size whose tip sits on the end of its edge.
const arrowHead = (id, fill) => `<marker id="${id}" viewBox="0 0 10 10" refX="10" refY="5" markerUnits="userSpaceOnUse" markerWidth="9" markerHeight="9" orient="auto"><path d="M0,1 L10,5 L0,9 z" fill="${fill}"/></marker>`;

// Where each node sits: its era is its column, and each column is ordered by
// track, then by where its needs sit, so edges cross less.
function layout(byId, d) {
  const maxDepth = Math.max(0, ...d.depth.values());
  const cols = Array.from({length: maxDepth + 1}, () => []);
  for (const n of byId.values()) cols[d.depth.get(n.id)].push(n);
  const yOf = new Map();
  const bary = n => {
    const ys = list(n.needs).map(t => yOf.get(t)).filter(v => v !== undefined);
    return ys.length ? ys.reduce((a, b) => a + b, 0) / ys.length : -1;
  };
  for (const col of cols) {
    col.sort((a, b) => TRACKS.indexOf(a.track) - TRACKS.indexOf(b.track) || bary(a) - bary(b) || cmp(a.id, b.id));
    col.forEach((n, i) => yOf.set(n.id, TOP + i * (BOX_H + GAP)));
  }
  const tallest = Math.max(1, ...cols.map(c => c.length));
  // At least as wide as the fixed legend (six tracks and the beyond-repository key).
  const legendW = LEFT + TRACKS.length * LEGEND_STEP + 260;
  const W = Math.max(LEFT * 2 + (maxDepth + 1) * COL - (COL - BOX_W), legendW);
  const H = TOP + tallest * (BOX_H + GAP) + 70;
  return {maxDepth, yOf, xOf: id => LEFT + d.depth.get(id) * COL, W, H};
}

function svgHead(byId, {maxDepth, W, H}, d) {
  const desc = `Generated by scripts/ultraplan/ultraplan.mjs from docs/ultraplan/tree.jsonl. ${byId.size} nodes in ${maxDepth + 1} eras; each arrow runs from a node to a node it enables.`;
  return [
    // The SVG namespace is an identifier, never fetched, and XML Namespaces 1.0 fixes it as http.
    `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" role="img" aria-labelledby="t d" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif">`, // hypatia: allow code_safety/js_http_url_in_code -- the SVG namespace URI is an identifier, not a fetched URL
    '<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->',
    '<!-- SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) -->',
    '<title id="t">The Mathesis tech tree</title>',
    `<desc id="d">${desc}</desc>`,
    '<defs>',
    arrowHead('arrow', EDGE),
    arrowHead('arrow-hot', GOLD),
    '</defs>',
    `<rect x="0" y="0" width="${W}" height="${H}" rx="18" fill="#fffdf7" stroke="#e8dcc0"/>`,
    `<text x="${LEFT}" y="34" font-size="20" font-weight="700" fill="#4a3f2a">🦉 Mathesis tech tree</text>`,
    `<text x="${LEFT}" y="54" font-size="12" fill="#7a6a4a">each arrow: this enables that · gold border: ${d.slots > 0 ? 'start it now' : 'ready, once an active slot is free'} · ✅ done 🔨 active 🌱 open ⛔ blocked 🍂 dropped</text>`,
  ];
}

function svgEras({maxDepth, H}) {
  return Array.from({length: maxDepth + 1}, (_, k) => {
    const [g, name] = era(k);
    const x = LEFT + k * COL;
    return [
      `<rect x="${x - 6}" y="64" width="${BOX_W + 12}" height="${H - 80}" rx="12" fill="${k % 2 ? '#fbf6ea' : '#f7f0de'}"/>`,
      `<text x="${x + BOX_W / 2}" y="84" font-size="13" font-weight="600" text-anchor="middle" fill="#6b5a36">${esc(g + ' ' + name)}</text>`,
    ];
  }).flat();
}

function svgEdge(n, t, hot, {xOf, yOf}) {
  const x1 = xOf(t) + BOX_W, y1 = yOf.get(t) + BOX_H / 2, x2 = xOf(n.id), y2 = yOf.get(n.id) + BOX_H / 2;
  const dx = Math.max(30, (x2 - x1) / 2);
  const stroke = hot ? `stroke="${GOLD}" stroke-width="2" marker-end="url(#arrow-hot)"` : `stroke="${EDGE}" stroke-width="1.3" marker-end="url(#arrow)"`;
  return `<path d="M${x1},${y1} C${x1 + dx},${y1} ${x2 - dx},${y2} ${x2},${y2}" fill="none" ${stroke} opacity="${n.status === 'dropped' ? 0.35 : 0.85}"/>`;
}

function svgBox(n, hot, {xOf, yOf}) {
  const x = xOf(n.id), y = yOf.get(n.id);
  const faded = n.status === 'dropped' ? ' opacity="0.45"' : '';
  const border = hot ? `stroke="${GOLD}" stroke-width="3"` : 'stroke="#a8977a" stroke-width="1"';
  const dashed = n.status === 'blocked' ? ' stroke-dasharray="5 3"' : '';
  const tag = `${trackKey(n.track)} · ${n.size}${n.where ? ' · 🌍' : ''}`;
  return [
    `<g${faded}>`,
    `<title>${esc(n.name + ': ' + n.summary)}</title>`,
    `<rect x="${x}" y="${y}" width="${BOX_W}" height="${BOX_H}" rx="12" fill="${TRACK_FILL[n.track]}" ${border}${dashed}/>`,
    `<text x="${x + 10}" y="${y + 21}" font-size="15">${esc(n.glyph)}</text>`,
    `<text x="${x + 34}" y="${y + 21}" font-size="12.5" font-weight="600" fill="#2f2a20">${esc(clip(n.name, 22))}</text>`,
    `<text x="${x + 34}" y="${y + 39}" font-size="10.5" fill="#6b5f48">${esc(tag)}</text>`,
    `<text x="${x + BOX_W - 8}" y="${y + 20}" font-size="14" text-anchor="end">${STATUS_GLYPH[n.status]}</text>`,
    '</g>',
  ];
}

function svgLegend({H}) {
  const ly = H - 22;
  const keys = TRACKS.flatMap((t, i) => {
    const lx = LEFT + i * LEGEND_STEP;
    return [
      `<rect x="${lx}" y="${ly - 12}" width="16" height="16" rx="4" fill="${TRACK_FILL[t]}" stroke="#a8977a"/>`,
      `<text x="${lx + 22}" y="${ly + 1}" font-size="11.5" fill="#4a3f2a">${esc(trackKey(t))}</text>`,
    ];
  });
  return [...keys, `<text x="${LEFT + TRACKS.length * LEGEND_STEP + 8}" y="${ly + 1}" font-size="11.5" fill="#4a3f2a">🌍 lands in another repository</text>`];
}

export function renderSvg(byId, d) {
  const g = layout(byId, d);
  const frontier = new Set(d.frontier.map(n => n.id));
  const nodes = [...byId.values()];
  return [
    ...svgHead(byId, g, d),
    ...svgEras(g),
    ...nodes.flatMap(n => list(n.needs).map(t => svgEdge(n, t, frontier.has(n.id), g))),
    ...nodes.flatMap(n => svgBox(n, frontier.has(n.id), g)),
    ...svgLegend(g),
    '</svg>',
  ].join('\n') + '\n';
}


// ── Driver ───────────────────────────────────────────────────────────────────
export function context(root = ROOT) {
  const decisions = path.join(root, 'docs/decisions');
  const registry = 'docs/atlas/generated/registry.adoc';
  // The real path inside the repository (symlinks resolved) of a regular file, or
  // of what `kind` accepts, or null. Every path the checks read goes through it.
  const inside = (p, kind = s => s.isFile()) => {
    try {
      const base = realpathSync(root), real = realpathSync(path.join(root, p));
      return real.startsWith(base + path.sep) && kind(statSync(real)) ? real : null;
    } catch { return null; }
  };
  const read = p => {
    const real = inside(p);
    if (!real) throw new Error(`${p} is not a file in the repository`);
    return readFileSync(real, 'utf8');
  };
  return {
    isFile: p => inside(p) !== null,
    // A file or a directory: a ref may name either.
    exists: p => inside(p, s => s.isFile() || s.isDirectory()) !== null,
    read,
    // No registry view means no claim is listed; one that leads outside the repository is refused.
    registry: existsSync(path.join(root, registry)) ? read(registry) : '',
    // Every decision record with this number, in a fixed order. Only the boilerplate
    // NNNN-template.adoc is set aside; a record such as 0006-template-inheritance.adoc counts.
    adrFiles: n => (existsSync(decisions) ? readdirSync(decisions) : [])
      .filter(x => x.startsWith(`${n}-`) && x.endsWith('.adoc') && x !== `${n}-template.adoc`)
      .sort(cmp).map(x => `docs/decisions/${x}`),
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
