// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// The theorem-level claims registry (docs/decisions/0004-claims-registry.adoc).
//
// docs/registry/claims.json records only source-anchored facts about each claim:
// its home repository, its id there, the statement as the home repository
// words it, the Agda names, a full 40-character commit, and the path and
// sha256 of the home repository's machine receipt at that commit.  It never
// records a grade.  The grade is DERIVED here, from the receipt fetched at the
// pinned commit, by the rules of standards/3-practice/PROOF-POLICY.adoc §8.2,
// and rendered into docs/registry/registry.adoc.  PROOF-POLICY §8.5: "Mathesis
// may catalogue grades. It derives them from those receipts and does not
// assign them."
//
//   bun scripts/registry/claims-registry.mjs build   fetch, derive, render
//   bun scripts/registry/claims-registry.mjs check   the same, and fail if the
//                                                     committed view differs
//
// --receipts-dir DIR reads receipts from DIR/<owner>__<repo>@<commit>/<path>
// instead of fetching them (the tests use it; CI fetches).
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const claimsFile = path.join(root, 'docs/registry/claims.json');
const reposFile = path.join(root, 'docs/catalogue/census/repos.json');
const viewFile = path.join(root, 'docs/registry/registry.adoc');

const KINDS = new Set(['theorem', 'demonstration', 'assumption']);
const PROVEN = new Set(['proven', 'proven-with-postulates']);
// PROOF-POLICY §2.1: the canonical invocation; every flag must be in force.
const CANONICAL_FLAGS = ['--safe', '--without-K', '--cubical-compatible'];
const PWG = new Set(['3', '2i', '2ii', '1', 'ungraded']);

// ── Validation of the registry rows ──────────────────────────────────────────

// Throw unless every row is well formed and its repository is public in the
// census inventory (the registry never names a private repository).
export function validate(rows, inventory) {
  if (!Array.isArray(rows)) throw new Error('docs/registry/claims.json must be an array');
  const visibility = new Map(inventory.map(r => [r.full_name, r.visibility]));
  const seen = new Set();
  for (const r of rows) {
    const where = r && r.id ? r.id : JSON.stringify(r);
    if (typeof r.repo !== 'string' || !/^[-\w.]+\/[-\w.]+$/.test(r.repo)) throw new Error(`Invalid repo: ${where}`);
    if (typeof r.claim !== 'string' || r.claim === '') throw new Error(`Missing claim id: ${where}`);
    if (r.id !== `${r.repo}#${r.claim}`) throw new Error(`id must be repo#claim: ${where}`);
    if (seen.has(r.id)) throw new Error(`Duplicate id: ${r.id}`);
    seen.add(r.id);
    if (!KINDS.has(r.kind)) throw new Error(`Unknown kind ${r.kind}: ${r.id}`);
    if (typeof r.statement !== 'string' || r.statement.length < 10) throw new Error(`Missing statement: ${r.id}`);
    if (typeof r.status_doc !== 'string' || r.status_doc === '') throw new Error(`Missing status_doc: ${r.id}`);
    if (typeof r.source_commit !== 'string' || !/^[0-9a-f]{40}$/.test(r.source_commit)) throw new Error(`source_commit must be 40 lowercase hex: ${r.id}`);
    if (r.kind === 'theorem') {
      if (!r.agda || typeof r.agda.module !== 'string' || !Array.isArray(r.agda.names) || r.agda.names.length === 0)
        throw new Error(`A theorem names its Agda module and names: ${r.id}`);
    }
    if (r.receipt !== null) {
      if (!r.receipt || typeof r.receipt.path !== 'string' || !/^[0-9a-f]{64}$/.test(r.receipt.sha256 ?? ''))
        throw new Error(`receipt is null or {path, sha256}: ${r.id}`);
    }
    if (visibility.get(r.repo) !== 'public') throw new Error(`Nonpublic or unlisted repository: ${r.id}`);
  }
  return rows;
}

// ── Reading a home repository's receipt ──────────────────────────────────────

// Parse a praxis-deed receipt into its flags and its claims.  Both the §8.5
// shape (`:pwg`, per-leg `(leg …)` forms) and the earlier shape (`:grade`,
// `:coq-leg`, `:lean-leg`) are read; nothing absent is invented.
export function parseReceipt(text) {
  const flags = (text.match(/:flags "([^"]*)"/) || [, null])[1];
  const claims = new Map();
  const lines = text.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/\(claim :id "([^"]+)" :token "([^"]+)"(.*)$/);
    if (!m) continue;
    const rest = m[3];
    const field = k => (rest.match(new RegExp(`:${k} "([^"]*)"`)) || [, null])[1];
    const claim = {token: m[2], pwg: field('pwg'), legacyGrade: field('grade'), legs: []};
    for (let j = i + 1; j < lines.length; j++) {
      const l = lines[j].match(/^\s*\(leg :prover "([^"]+)" :route "([^"]+)" :token "([^"]+)" :state "([^"]+)"/);
      if (!l) break;
      claim.legs.push({prover: l[1], route: l[2], token: l[3], state: l[4]});
    }
    if (claim.legs.length === 0 && field('coq-leg') !== null) {
      // The earlier shape records a route per leg and no §2.2 state.
      claim.legs.push({prover: 'rocq', route: field('coq-leg'), token: null, state: null});
      claim.legs.push({prover: 'lean', route: field('lean-leg'), token: null, state: null});
    }
    claims.set(m[1], claim);
  }
  return {flags, claims};
}

// ── The derivation: PROOF-POLICY §8.1–§8.2 ───────────────────────────────────

// Derive one row's Proof Witness Grade from its parsed receipt (or null).
// Returns {pwg, reasons, findings, legs}.  `reasons` say why the grade is not
// higher; `findings` are disagreements between the receipt and the derivation.
export function derive(row, receipt) {
  const reasons = [], findings = [];
  if (row.kind !== 'theorem') return {pwg: 'ungraded', reasons: [`${row.kind}, not a theorem (§8.1)`], findings, legs: []};
  if (receipt === null) return {pwg: 'ungraded', reasons: ['no machine receipt in the home repository'], findings, legs: []};
  const claim = receipt.claims.get(row.claim);
  if (!claim) return {pwg: 'ungraded', reasons: ['claim absent from the receipt'], findings, legs: []};
  const flags = (receipt.flags ?? '').split(/\s+/);
  const missing = CANONICAL_FLAGS.filter(f => !flags.includes(f));
  let pwg;
  if (missing.length) {
    pwg = 'ungraded';
    reasons.push(`not under the §2.1 invocation (missing ${missing.join(' ')})`);
  } else if (!PROVEN.has(claim.token)) {
    pwg = 'ungraded';
    reasons.push(`Agda token is ${claim.token}, not proven`);
  } else {
    // A leg counts only when its §2.2 state is RECONCILED (§8.2).
    const counted = claim.legs.filter(l => l.state === 'RECONCILED').length;
    pwg = counted === 0 ? '3' : counted === 1 ? '2i' : '2ii';
    if (counted < 2) reasons.push(`${2 - counted} of the Rocq and Lean legs not RECONCILED`);
    // PWG-1 needs a current per-commit receipt for every counted witness;
    // this slice does not read witness receipts, so it never derives PWG-1.
  }
  if (claim.pwg !== null && claim.pwg !== pwg)
    findings.push(`receipt asserts PWG ${claim.pwg}; derived ${pwg} (§8.4 drift)`);
  if (claim.pwg === null && claim.legacyGrade !== null)
    findings.push(`receipt uses the pre-§8 vocabulary (${claim.legacyGrade}); derived ${pwg === 'ungraded' ? 'ungraded' : 'PWG-' + pwg}`);
  return {pwg, reasons, findings, legs: claim.legs};
}

// ── Fetching receipts at their pinned commits ────────────────────────────────

// Return the receipt text for a row, verified against its sha256, or null.
async function loadReceipt(row, receiptsDir) {
  if (row.receipt === null) return null;
  let text;
  if (receiptsDir) {
    text = await readFile(path.join(receiptsDir, `${row.repo.replace('/', '__')}@${row.source_commit}`, row.receipt.path), 'utf8');
  } else {
    const url = `https://raw.githubusercontent.com/${row.repo}/${row.source_commit}/${row.receipt.path}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`could not fetch ${url}: HTTP ${res.status}`);
    text = await res.text();
  }
  const digest = createHash('sha256').update(text).digest('hex');
  if (digest !== row.receipt.sha256) throw new Error(`receipt digest mismatch for ${row.id}: pinned ${row.receipt.sha256}, got ${digest}`);
  return text;
}

// Derive every row, fetching each distinct receipt once.
export async function deriveAll(rows, receiptsDir) {
  const cache = new Map();
  const out = [];
  for (const row of rows) {
    const key = row.receipt === null ? null : `${row.repo}@${row.source_commit}/${row.receipt.path}`;
    if (key !== null && !cache.has(key)) cache.set(key, parseReceipt(await loadReceipt(row, receiptsDir)));
    out.push({row, ...derive(row, key === null ? null : cache.get(key))});
  }
  return out;
}

// ── Rendering ────────────────────────────────────────────────────────────────

const cell = s => String(s).replaceAll('|', String.raw`\|`).replaceAll('\n', ' ');
const label = p => (p === 'ungraded' ? '`ungraded`' : `\`PWG-${p}\``);

// Render the derived registry as AsciiDoc: a census line (§8.4.7: counts per
// grade with the denominator, never a percentage), then one row per claim.
export function render(derived) {
  for (const d of derived) if (!PWG.has(d.pwg)) throw new Error(`internal: bad pwg ${d.pwg}`);
  const theorems = derived.filter(d => d.row.kind === 'theorem');
  const count = p => theorems.filter(d => d.pwg === p).length;
  const census = ['1', '2ii', '2i', '3'].map(p => `${count(p)} at \`PWG-${p}\``).join(', ') + `, ${count('ungraded')} \`ungraded\`, of ${theorems.length} theorems`;
  const ordered = [...derived].sort((a, b) => (a.row.repo + '#' + a.row.claim).localeCompare(b.row.repo + '#' + b.row.claim, 'en', {numeric: true}));
  const out = [
    '// SPDX-License-Identifier: CC-BY-SA-4.0',
    '// GENERATED by scripts/registry/claims-registry.mjs from docs/registry/claims.json and',
    '// the receipts it pins; do not hand-edit.',
    '= Claims registry (pilot slice)',
    '',
    'Each row is a claim in its home repository at a pinned commit. The grade is',
    '*derived* here from that repository\'s receipt by PROOF-POLICY §8.2, never',
    'assigned (§8.5). A grade is not a discharge (§8.4): `PWG-3` theorems still',
    'owe their Rocq and Lean legs. Status of this slice: proposed in',
    'link:../decisions/0004-claims-registry.adoc[ADR 0004], not ratified.',
    '',
    `Census: ${census}. ${derived.length - theorems.length} demonstrations and assumptions are listed and not graded.`,
    '',
    '[cols="2,1,1,4,3",options="header"]',
    '|===',
    '|Claim |Kind |PWG |Statement (home repository\'s wording) |Why not higher; findings',
    '',
  ];
  for (const d of ordered) {
    const r = d.row;
    const link = `https://github.com/${r.repo}/blob/${r.source_commit}/${r.status_doc}[${r.repo}#${r.claim}]`;
    const at = `at \`${r.source_commit.slice(0, 12)}\``;
    const names = r.agda ? ` (\`${cell(r.agda.module)}\`: ${r.agda.names.map(n => '`' + cell(n) + '`').join(', ')})` : '';
    const notes = [...d.reasons, ...d.findings.map(f => `*Finding:* ${f}`)].map(cell).join('; ') || '—';
    out.push(`|${link} ${at} |${r.kind} |${label(d.pwg)} |${cell(r.statement)}${names} |${notes}`, '');
  }
  out.push('|===', '');
  return out.join('\n');
}

// ── Entry point ──────────────────────────────────────────────────────────────

async function main() {
  const [cmd, ...args] = process.argv.slice(2);
  const i = args.indexOf('--receipts-dir');
  const receiptsDir = i >= 0 ? path.resolve(args[i + 1]) : null;
  const rows = validate(JSON.parse(await readFile(claimsFile, 'utf8')), JSON.parse(await readFile(reposFile, 'utf8')));
  const derived = await deriveAll(rows, receiptsDir);
  const drift = derived.flatMap(d => d.findings.filter(f => f.includes('§8.4 drift')).map(f => `${d.row.id}: ${f}`));
  if (drift.length) throw new Error('a receipt asserts a grade its evidence does not support:\n  ' + drift.join('\n  '));
  const view = render(derived);
  if (cmd === 'build') {
    await mkdir(path.dirname(viewFile), {recursive: true});
    await writeFile(viewFile, view);
    console.log(`WROTE ${path.relative(root, viewFile)} (${rows.length} claims)`);
  } else if (cmd === 'check') {
    const committed = await readFile(viewFile, 'utf8').catch(() => '');
    if (committed !== view) throw new Error(`${path.relative(root, viewFile)} is stale; run: bun scripts/registry/claims-registry.mjs build`);
    console.log(`PASS: claims registry derived from ${new Set(rows.map(r => r.repo + '@' + r.source_commit)).size} pinned source(s); view matches (${rows.length} claims)`);
  } else {
    console.error('usage: claims-registry.mjs build|check [--receipts-dir DIR]');
    process.exit(2);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(e => { console.error('ERROR: ' + e.message); process.exit(1); });
}
