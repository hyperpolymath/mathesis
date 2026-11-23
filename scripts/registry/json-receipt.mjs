// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// PROTOTYPE for the proposed ADR 0005 (docs/decisions/0005-jcs-json-receipt.adoc,
// status: proposed). Not wired into claims-registry.mjs: the registry still
// reads praxis deeds only, until the owner accepts the ADR.
//
// A JSON proof receipt is the PROOF-POLICY §8.5.1 receipt with the same fields
// in I-JSON (RFC 7493), serialised by JCS (RFC 8785), and with no grade. This
// file has no grading rule. It checks the JSON layer, projects the receipt to
// §8.5.1 deed text, and lets the PINNED canon reader (readProofReceipt, passed
// in by the caller after loadReader() has checked its digest) derive each grade.
// The reader's grade check is used as an oracle. For each claim, exactly one
// (:pwg, :foundation-diverse) pair in the closed vocabulary is accepted, and
// that pair is the derived grade. No grade is ever taken from the JSON.
//
//   bun scripts/registry/json-receipt.mjs read FILE   (needs MATHESIS_STANDARDS)
import {jcs} from './theory-ledger.mjs';

export const PROFILE = 'proof-receipt';
export const SCHEMA_VERSION = '1.0.0';

// The grades and flags of PROOF-POLICY §8.2 and §8.3, in the order they are
// tried. They are tried, never read: a receipt that names one is refused.
const GRADES = ['ungraded', 'PWG-3', 'PWG-2i', 'PWG-2ii', 'PWG-1'];
const DIVERSE = ['#f', '#t'];
// Fields that would assert a grade. Refused anywhere in the receipt, with a
// reason that says so (§8.4: grades are derived, not asserted; WO 2.4).
const ASSERTED = new Set(['pwg', 'grade', 'grades', 'foundation_diverse', 'foundation-diverse', 'foundationDiverse']);
const RESULTS = new Set(['pass', 'fail']);
// The longest string value. Each value goes on its own line of the projected
// deed, and a deed line is at most 998 octets (deed.abnf v1.3.0).
export const MAX_VALUE_OCTETS = 900;

export class JsonReceiptError extends Error {
  constructor(message) {
    super(message);
    this.name = 'JsonReceiptError';
  }
}
const fail = m => { throw new JsonReceiptError(m); };
const need = (ok, m) => { if (!ok) fail(m); };

// ── The schema: closed, typed, one form for each value ──────────────────────
//
// A field is [kind, required]. Kinds: 'string' (a deed string), 'symbol' (a
// deed symbol, letters, digits and hyphens), 'commit' (40 lowercase hex),
// 'hex64', 'result' (pass or fail), or a nested schema for an array of objects.
const S = (kind, required = true) => ({kind, required});
const A = (schema, required = true) => ({kind: 'array', schema, required});
const FILE = {path: S('string'), sha256: S('hex64')};
const AXIOM = {name: S('string'), disposition: S('symbol')};
// A pinned repository that the run imported, with its own manifest (§8.5.1).
const IMPORT = {repository: S('string'), commit: S('commit'), inputs_sha256: S('hex64'), files: A(FILE)};
const RECEIPT = {
  run: S('string'), commit: S('commit'), checker: S('string'), invocation: S('string'),
  inputs_sha256: S('hex64', false), state: S('symbol'), reason: S('string', false), result: S('result'),
  image: S('string', false), inputs_manifest: A(FILE, false), imports: A(IMPORT, false), axioms: A(AXIOM, false),
};
// A negative control: a file the checker must refuse (§8.5.4). Recorded, never graded.
const CONTROL = {path: S('string'), prover: S('symbol'), expect: S('symbol'), receipts: A(RECEIPT)};
const LEG = {prover: S('symbol'), route: S('symbol'), token: S('symbol', false), state: S('symbol', false),
  reason: S('string', false), receipts: A(RECEIPT)};
const CLAIM = {id: S('string'), legs: A(LEG), controls: A(CONTROL, false)};
// Optional arrays whose absence the reader reads as empty: one form only, so [] is refused.
const NONEMPTY = new Set(['imports', 'controls']);
const PRIMITIVE = {prover: S('symbol'), module: S('string'), name: S('string'), binding: S('string')};
const INPUTS = {prover: S('symbol'), sha256: S('hex64')};
const ECHO = {source: S('commit'), image: S('commit'), witness: S('symbol'), tree_sha256: S('hex64', false),
  inputs: A(INPUTS, false)};
const TOP = {profile: S('string'), schema_version: S('string'), repository: S('string'), source_commit: S('commit'),
  trusted_base: A(PRIMITIVE), echoes: A(ECHO), claims: A(CLAIM)};

// RFC 7493 §2.1: no lone surrogate and no noncharacter, in a key or a value.
function checkCodePoints(s, where) {
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdbff) {
      const d = s.charCodeAt(i + 1);
      need(d >= 0xdc00 && d <= 0xdfff, `${where}: a lone UTF-16 surrogate (RFC 7493 §2.1)`);
      const cp = 0x10000 + ((c - 0xd800) << 10) + (d - 0xdc00);
      need((cp & 0xfffe) !== 0xfffe, `${where}: a Unicode noncharacter (RFC 7493 §2.1)`);
      i++;
    } else {
      need(!(c >= 0xdc00 && c <= 0xdfff), `${where}: a lone UTF-16 surrogate (RFC 7493 §2.1)`);
      need(!(c >= 0xfdd0 && c <= 0xfdef) && (c & 0xfffe) !== 0xfffe, `${where}: a Unicode noncharacter (RFC 7493 §2.1)`);
    }
  }
}

// A value as one deed string can hold it: not empty, no control character
// (so no trailing newline, tab or carriage return), and short enough for one line.
function checkString(v, where) {
  need(typeof v === 'string', `${where} must be a string`);
  need(v.trim() !== '', `${where} is empty`);
  need(!/[\u0000-\u001f\u007f]/.test(v), `${where} holds a control character (a newline, tab or other); a value is one line`);
  need(new TextEncoder().encode(v).length <= MAX_VALUE_OCTETS, `${where} is longer than ${MAX_VALUE_OCTETS} octets`);
}

function checkValue(kind, v, where) {
  if (kind === 'string') return checkString(v, where);
  need(typeof v === 'string', `${where} must be a string`);
  if (kind === 'symbol') need(/^[A-Za-z][A-Za-z0-9-]*$/.test(v), `${where} must be a symbol (letters, digits, hyphens), got ${JSON.stringify(v)}`);
  else if (kind === 'commit') need(/^[0-9a-f]{40}$/.test(v), `${where} must be the full 40-character lowercase commit, got ${JSON.stringify(v)}`);
  else if (kind === 'hex64') need(/^[0-9a-f]{64}$/.test(v), `${where} must be 64 lowercase hex digits`);
  else if (kind === 'result') need(RESULTS.has(v), `${where} must be pass or fail, got ${JSON.stringify(v)}`);
}

// Check one object against a closed schema, then recurse into its arrays.
function checkObject(o, schema, where) {
  need(o !== null && typeof o === 'object' && !Array.isArray(o), `${where} must be an object`);
  for (const k of Object.keys(o)) {
    checkCodePoints(k, `${where}: a key`);
    need(!ASSERTED.has(k), `${where} asserts a grade (${k}); a JSON receipt carries no grade, the registry derives it (PROOF-POLICY §8.4, WO 2.4)`);
    need(k in schema, `${where}: unknown field ${k}`);
  }
  for (const [k, f] of Object.entries(schema)) {
    const at = `${where}.${k}`;
    if (!(k in o)) { need(!f.required, `${where} is missing ${k}`); continue; }
    need(o[k] !== null, `${at} is null; leave an optional field out instead`);
    if (f.kind === 'array') {
      need(Array.isArray(o[k]), `${at} must be an array`);
      need(!NONEMPTY.has(k) || o[k].length > 0, `${at} is empty; leave it out instead`);
      o[k].forEach((e, i) => checkObject(e, f.schema, `${at}[${i}]`));
    } else {
      if (typeof o[k] === 'string') checkCodePoints(o[k], at);
      checkValue(f.kind, o[k], at);
    }
  }
}

// ── The JSON layer ───────────────────────────────────────────────────────────

// Parse a JSON receipt from its bytes (a Uint8Array) or text, and refuse it
// unless it is strict UTF-8 with no byte order mark, I-JSON, byte-identical to
// its JCS form (one final LF allowed, as scripts/check-ijson-jcs.sh allows),
// and in the schema above. Returns the parsed object.
export function parseJsonReceipt(input) {
  let text = input;
  if (typeof input !== 'string') {
    try { text = new TextDecoder('utf-8', {fatal: true, ignoreBOM: true}).decode(input); }
    catch { fail('not UTF-8'); }
  }
  need(!text.startsWith('﻿'), 'a byte order mark; I-JSON text has none');
  let value;
  try { value = JSON.parse(text); } catch (e) { fail(`not JSON: ${e.message}`); }
  // Every value in the schema is a string, an array or an object, so a number,
  // a boolean or a null anywhere is refused below. Canonical form next: this
  // also refuses a duplicate key (JSON.parse keeps the last one, so the JCS
  // form is shorter), insignificant whitespace, unsorted keys and escapes JCS
  // does not use.
  const canonical = jcs(value);
  need(text === canonical || text === canonical + '\n',
    'not canonical: the bytes differ from the JCS (RFC 8785) form of the value; the sha256 pin needs one form');
  checkObject(value, TOP, 'the receipt');
  need(value.profile === PROFILE, `profile must be ${PROFILE}`);
  need(value.schema_version === SCHEMA_VERSION, `schema_version must be ${SCHEMA_VERSION}`);
  need(/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(value.repository), 'repository must be OWNER/REPO');
  const withReceipts = c => [...c.legs.map(l => [`${l.prover} leg`, l.receipts]),
    ...(c.controls ?? []).map(k => [`${k.prover} control ${k.path}`, k.receipts])];
  for (const c of value.claims) for (const [what, receipts] of withReceipts(c)) for (const r of receipts) {
    const where = `claim ${JSON.stringify(c.id)}, ${what}, receipt ${r.run}`;
    // The deed has no result field: its :state carries it. A current receipt
    // records a run that passed, and a failed run is kept only as regressed.
    if (r.state === 'current') need(r.result === 'pass', `${where}: a current receipt has result pass`);
    if (r.result === 'fail') need(r.state === 'regressed', `${where}: a receipt with result fail has state regressed`);
  }
  return value;
}

// ── The projection to §8.5.1 deed text ───────────────────────────────────────

const str = v => `"${v.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"`;

function receiptText(r, pad) {
  const out = [`${pad}(receipt :run ${str(r.run)}`, `${pad}  :commit ${str(r.commit)}`,
    `${pad}  :checker ${str(r.checker)}`, `${pad}  :invocation ${str(r.invocation)}`];
  if (r.inputs_sha256 !== undefined) out.push(`${pad}  :inputs-sha256 ${str(r.inputs_sha256)}`);
  out.push(`${pad}  :state ${r.state}`);
  if (r.reason !== undefined) out.push(`${pad}  :reason ${str(r.reason)}`);
  if (r.image !== undefined) out.push(`${pad}  :image ${str(r.image)}`);
  for (const i of r.imports ?? []) {
    out.push(`${pad}  (import :repository ${str(i.repository)} :commit ${str(i.commit)} :inputs-sha256 ${str(i.inputs_sha256)}`,
      ...i.files.map(f => `${pad}    (file :path ${str(f.path)} :sha256 ${str(f.sha256)})`), `${pad}  )`);
  }
  if (r.axioms !== undefined) {
    out.push(`${pad}  (axioms`, ...r.axioms.map(a => `${pad}    (axiom :name ${str(a.name)} :disposition ${a.disposition})`), `${pad}  )`);
  }
  if (r.inputs_manifest !== undefined) {
    out.push(`${pad}  (inputs-manifest`, ...r.inputs_manifest.map(f => `${pad}    (file :path ${str(f.path)} :sha256 ${str(f.sha256)})`), `${pad}  )`);
  }
  out.push(`${pad})`);
  return out;
}

function claimText(c, pwg, diverse) {
  const out = [`  (claim :id ${str(c.id)} :pwg ${pwg} :foundation-diverse ${diverse}`];
  for (const l of c.legs) {
    let head = `    (leg :prover ${l.prover} :route ${l.route}`;
    if (l.token !== undefined) head += ` :token ${l.token}`;
    if (l.state !== undefined) head += ` :state ${l.state}`;
    out.push(head);
    if (l.reason !== undefined) out.push(`      :reason ${str(l.reason)}`);
    for (const r of l.receipts) out.push(...receiptText(r, '      '));
    out.push('    )');
  }
  for (const k of c.controls ?? []) {
    out.push(`    (control :path ${str(k.path)} :prover ${k.prover} :expect ${k.expect}`);
    for (const r of k.receipts) out.push(...receiptText(r, '      '));
    out.push('    )');
  }
  out.push('  )');
  return out;
}

// The §8.5.1 deed text of a checked receipt, with the given grade for each
// claim (a Map id -> [pwg, diverse]). Only this file writes it, and only the
// canon reader reads it; it is never stored.
export function toDeed(r, grades, claims = r.claims) {
  const out = [';; SPDX-License-Identifier: CC-BY-SA-4.0', '(praxis-deed', '  :schema-version "1.0.0"',
    '  :canonical-name "json-proof-receipt"', '  :profile proof-receipt',
    `  :repository ${str(r.repository)}`, `  :source-commit ${str(r.source_commit)}`];
  if (r.trusted_base.length) {
    out.push('  (trusted-base', ...r.trusted_base.map(p =>
      `    (primitive :prover ${p.prover} :module ${str(p.module)} :name ${str(p.name)} :binding ${str(p.binding)})`), '  )');
  }
  for (const c of claims) out.push(...claimText(c, ...grades.get(c.id)));
  for (const e of r.echoes) {
    let head = `  (echo :source ${str(e.source)} :image ${str(e.image)} :witness ${e.witness}`;
    if (e.tree_sha256 !== undefined) head += ` :tree-sha256 ${str(e.tree_sha256)}`;
    out.push(head, ...(e.inputs ?? []).map(i => `    (inputs :prover ${i.prover} :sha256 ${str(i.sha256)})`), '  )');
  }
  out.push(')', '');
  return out.join('\n');
}

// ── Reading through the pinned canon reader ──────────────────────────────────

const refused = e => ['LintError', 'ProofReceiptError'].includes(e?.name);

// Read a JSON receipt into the canon reader's record. Each claim is tried
// alone, with each grade pair, and exactly one pair must be accepted. Then
// the whole receipt is read once with the derived pairs, so that checks
// across claims (duplicate ids, echoes) run too. Throws JsonReceiptError for
// the JSON layer, and the reader's error when the reader refuses.
export function readJsonReceipt(input, readProofReceipt) {
  const r = parseJsonReceipt(input);
  need(r.claims.length > 0, 'a proof receipt records at least one claim');
  const grades = new Map();
  for (const c of r.claims) {
    const accepted = [];
    let first = null;
    for (const pwg of GRADES) for (const diverse of DIVERSE) {
      try {
        readProofReceipt(toDeed(r, new Map([[c.id, [pwg, diverse]]]), [c]), 'json_praxis.deed');
        accepted.push([pwg, diverse]);
      } catch (e) {
        if (!refused(e)) throw e;
        first ??= e;
      }
    }
    if (accepted.length === 0) throw first;
    // The reader derives one grade, so two accepted pairs mean the oracle is broken.
    need(accepted.length === 1, `claim ${JSON.stringify(c.id)}: the reader accepted ${accepted.length} grade pairs; expected exactly one`);
    grades.set(c.id, accepted[0]);
  }
  return readProofReceipt(toDeed(r, grades), 'json_praxis.deed');
}

// ── Entry point ──────────────────────────────────────────────────────────────

async function main() {
  const [cmd, file] = process.argv.slice(2);
  if (cmd !== 'read' || !file) {
    console.error('usage: json-receipt.mjs read FILE');
    process.exit(2);
  }
  const {loadReader} = await import('./claims-registry.mjs');
  const {readFile} = await import('node:fs/promises');
  const record = readJsonReceipt(new Uint8Array(await readFile(file)), await loadReader());
  console.log(jcs(record));
}

if (process.argv[1] && import.meta.path === (await import('node:path')).resolve(process.argv[1])) {
  main().catch(e => { console.error(`REFUSED: ${e.message ?? e}`); process.exit(1); });
}
