// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// The theorem-level claims registry (docs/decisions/0004-claims-registry.adoc).
//
// docs/atlas/claims/claims.jsonl records only source-anchored facts about each claim:
// its home repository, its id there, the statement as the home repository
// words it, the Agda names, a full 40-character commit, and the path and
// sha256 of the home repository's machine receipt at that commit.  It never
// records a grade.  The grade is DERIVED by the canon reader of
// standards/3-practice/PROOF-POLICY.adoc §8.5.1 (`readProofReceipt` in
// 1-formats/deed/tools/deed_lint.js), from the receipt fetched at the pinned
// commit, and rendered into docs/atlas/generated/registry.adoc.  PROOF-POLICY §8.5:
// "Mathesis may catalogue grades. It derives them from those receipts and does
// not assign them."  This file holds no grading rule of its own.
//
//   bun scripts/registry/claims-registry.mjs build   fetch, derive, render
//   bun scripts/registry/claims-registry.mjs check   the same, and fail if the
//                                                     committed view differs
//
// MATHESIS_STANDARDS names a checkout of metadatastician/standards that holds
// the reader at READER.commit; the reader's sha256 must equal READER.sha256.
// --receipts-dir DIR reads receipts from DIR/<owner>__<repo>@<commit>/<path>
// instead of fetching them (the tests use it; CI fetches).
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {fileURLToPath, pathToFileURL} from 'node:url';
import path from 'node:path';
import {readJsonl} from '../atlas/census-atlas.mjs';
import {validateBridges, renderBridges} from './bridges.mjs';
import {validateAdmissions, renderTheoryIndex} from './theory.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const claimsFile = path.join(root, 'docs/atlas/claims/claims.jsonl');
const reposFile = path.join(root, 'docs/atlas/census/repos.jsonl');
const viewFile = path.join(root, 'docs/atlas/generated/registry.adoc');
const bridgesFile = path.join(root, 'docs/atlas/claims/bridges.jsonl');
const bridgesView = path.join(root, 'docs/atlas/generated/bridges.adoc');
const admissionsFile = path.join(root, 'docs/theory/admissions.jsonl');
const theoryView = path.join(root, 'docs/theory/generated/index.adoc');

const KINDS = new Set(['theorem', 'demonstration', 'assumption']);
const PWG = new Set(['PWG-1', 'PWG-2ii', 'PWG-2i', 'PWG-3', 'ungraded']);

// The canon reader, pinned by commit and by the digest of its file. A reader
// that is not this file is refused, so a grade never comes from an unpinned rule.
export const READER = {
  repository: 'metadatastician/standards',
  commit: 'be39f900665fb7c042c05d1165da018adc1860f4',
  path: '1-formats/deed/tools/deed_lint.js',
  sha256: 'f7e2b91905f0d99e5cabab59385073afb695be8b9f2d0591257a6a6fd62e25e3',
};

// ── Validation of the registry rows ──────────────────────────────────────────

// Throw unless every row is well formed and its repository is public in the
// census inventory (the registry never names a private repository).
export function validate(rows, inventory) {
  if (!Array.isArray(rows)) throw new Error('docs/atlas/claims/claims.jsonl must hold one claim record on each line');
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

// ── The canon reader ─────────────────────────────────────────────────────────

// Load readProofReceipt from a standards checkout, after its digest check.
export async function loadReader(standardsDir = process.env.MATHESIS_STANDARDS) {
  if (!standardsDir) {
    throw new Error(`set MATHESIS_STANDARDS to a checkout of ${READER.repository} at ${READER.commit}`);
  }
  const file = path.resolve(standardsDir, READER.path);
  const digest = createHash('sha256').update(await readFile(file)).digest('hex');
  if (digest !== READER.sha256) {
    throw new Error(`${file} is not the pinned canon reader (sha256 ${digest}, pinned ${READER.sha256} at ${READER.commit})`);
  }
  const {readProofReceipt} = await import(pathToFileURL(file).href);
  if (typeof readProofReceipt !== 'function') throw new Error(`${file} exports no readProofReceipt`);
  return readProofReceipt;
}

// ── The derivation: the canon reader, PROOF-POLICY §8.1, §8.2, §8.5.1 ────────

// Derive one row's grade from the reader's record of its receipt. `read` is
// {record} when the reader accepted the receipt, {refusal} when it refused it,
// or null when the row pins no receipt. Returns {pwg, reasons, evidence}: `reasons` say
// why the grade is not higher, and `evidence` is the commit that the receipt
// describes (its :source-commit), which can differ from the commit that holds it.
export function derive(row, read) {
  if (row.kind !== 'theorem') return {pwg: 'ungraded', reasons: [`${row.kind}, not a theorem (§8.1)`]};
  if (read === null) return {pwg: 'ungraded', reasons: ['no machine receipt in the home repository']};
  if (read.refusal) return {pwg: 'ungraded', reasons: [`the canon reader refuses the receipt: ${read.refusal}`]};
  const {record} = read;
  if (record.repository !== row.repo) {
    return {pwg: 'ungraded', reasons: [`the receipt is for ${record.repository}, not ${row.repo}`]};
  }
  const claim = record.claims.find(c => c.id === row.claim);
  if (!claim) return {pwg: 'ungraded', reasons: ['claim absent from the receipt']};
  if (!PWG.has(claim.pwg)) throw new Error(`the reader returned an unknown grade ${claim.pwg}: ${row.id}`);
  const reasons = [];
  if (claim.pwg !== 'PWG-1') reasons.push(`the reader derives ${claim.pwg} from the legs and receipts at \`${record.source_commit.slice(0, 12)}\``);
  return {pwg: claim.pwg, reasons, evidence: record.source_commit};
}

// ── Fetching receipts at their pinned commits ────────────────────────────────

// Return the receipt text for a row, verified against its sha256.
async function loadReceipt(row, receiptsDir) {
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

// Derive every row, reading each distinct receipt once. A receipt that the
// reader refuses gives `ungraded` with the reader's reason; a receipt that
// cannot be fetched or fails its digest stops the run.
export async function deriveAll(rows, receiptsDir, readProofReceipt) {
  const cache = new Map();
  const out = [];
  for (const row of rows) {
    let read = null;
    if (row.receipt !== null) {
      const key = `${row.repo}@${row.source_commit}/${row.receipt.path}`;
      if (!cache.has(key)) {
        const text = await loadReceipt(row, receiptsDir);
        try {
          cache.set(key, {record: readProofReceipt(text, path.basename(row.receipt.path))});
        } catch (e) {
          if (!['LintError', 'ProofReceiptError'].includes(e?.name)) throw e;
          cache.set(key, {refusal: String(e)});
        }
      }
      read = cache.get(key);
    }
    out.push({row, ...derive(row, read)});
  }
  return out;
}

// ── Rendering ────────────────────────────────────────────────────────────────

const cell = s => String(s).replaceAll('|', String.raw`\|`).replaceAll('\n', ' ');
const label = p => `\`${p}\``;

// Render the derived registry as AsciiDoc: a census line (§8.4.7: counts per
// grade with the denominator, never a percentage), then one row per claim.
export function render(derived) {
  for (const d of derived) if (!PWG.has(d.pwg)) throw new Error(`internal: bad pwg ${d.pwg}`);
  const theorems = derived.filter(d => d.row.kind === 'theorem');
  const count = p => theorems.filter(d => d.pwg === p).length;
  const census = ['PWG-1', 'PWG-2ii', 'PWG-2i', 'PWG-3'].map(p => `${count(p)} at \`${p}\``).join(', ') + `, ${count('ungraded')} \`ungraded\`, of ${theorems.length} theorems`;
  const ordered = [...derived].sort((a, b) => (a.row.repo + '#' + a.row.claim).localeCompare(b.row.repo + '#' + b.row.claim, 'en', {numeric: true}));
  const out = [
    '// SPDX-License-Identifier: CC-BY-SA-4.0',
    '// GENERATED by scripts/registry/claims-registry.mjs from docs/atlas/claims/claims.jsonl and',
    '// the receipts it pins; do not hand-edit.',
    '= Claims registry (pilot slice)',
    '',
    'Each row is a claim in its home repository at a pinned commit. The grade is',
    '*derived* here from that repository\'s receipt by the canon reader of',
    `PROOF-POLICY §8.5.1 (\`${READER.repository}\` at \`${READER.commit.slice(0, 12)}\`), never`,
    'assigned (§8.5). A grade is not a discharge (§8.4): `PWG-3` theorems still',
    'owe their Rocq and Lean legs. Status of this slice: accepted in',
    'link:../../decisions/0004-claims-registry.adoc[ADR 0004], ratified by the owner.',
    '',
    `Census: ${census}. ${derived.length - theorems.length} demonstrations and assumptions are listed and not graded.`,
    '',
    '[cols="2,1,1,4,3",options="header"]',
    '|===',
    '|Claim |Kind |PWG |Statement (home repository\'s wording) |Why not higher',
    '',
  ];
  for (const d of ordered) {
    const r = d.row;
    const link = `https://github.com/${r.repo}/blob/${r.source_commit}/${r.status_doc}[${r.repo}#${r.claim}]`;
    const at = `at \`${r.source_commit.slice(0, 12)}\`` + (d.evidence && d.evidence !== r.source_commit ? `; the receipt describes \`${d.evidence.slice(0, 12)}\`` : '');
    const names = r.agda ? ` (\`${cell(r.agda.module)}\`: ${r.agda.names.map(n => '`' + cell(n) + '`').join(', ')})` : '';
    const notes = d.reasons.map(cell).join('; ') || '—';
    out.push(`|${link} ${at} |${r.kind} |${label(d.pwg)} |${cell(r.statement)}${names} |${notes}`, '');
  }
  out.push('|===', '');
  return out.join('\n');
}

// ── Entry point ──────────────────────────────────────────────────────────────

async function main() {
  const [cmd, ...args] = process.argv.slice(2);
  if (cmd !== 'build' && cmd !== 'check') {
    console.error('usage: claims-registry.mjs build|check [--receipts-dir DIR]');
    process.exit(2);
  }
  const i = args.indexOf('--receipts-dir');
  const receiptsDir = i >= 0 ? path.resolve(args[i + 1]) : null;
  const inventory = await readJsonl(reposFile);
  const rows = validate(await readJsonl(claimsFile), inventory);
  const bridges = validateBridges(await readJsonl(bridgesFile), inventory);
  const admissions = validateAdmissions(await readJsonl(admissionsFile), rows, inventory);
  const derived = await deriveAll(rows, receiptsDir, await loadReader());
  const views = [[viewFile, render(derived)], [bridgesView, renderBridges(bridges)], [theoryView, renderTheoryIndex(derived, admissions)]];
  if (cmd === 'build') {
    await Promise.all(views.map(([file]) => mkdir(path.dirname(file), {recursive: true})));
    await Promise.all(views.map(([file, body]) => writeFile(file, body)));
    console.log(`WROTE ${path.relative(root, viewFile)} (${rows.length} claims) and ${path.relative(root, bridgesView)} (${bridges.length} bridges) and ${path.relative(root, theoryView)} (${admissions.length} admissions)`);
  } else {
    const committed = await Promise.all(views.map(([file]) => readFile(file, 'utf8').catch(() => '')));
    const stale = views.filter(([, body], i) => committed[i] !== body).map(([file]) => path.relative(root, file));
    if (stale.length) throw new Error(`${stale.join(', ')} stale; run: bun scripts/registry/claims-registry.mjs build`);
    console.log(`PASS: claims registry derived from ${new Set(rows.map(r => r.repo + '@' + r.source_commit)).size} pinned source(s); views match (${rows.length} claims, ${bridges.length} bridges, ${admissions.length} admissions)`);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(e => { console.error('ERROR: ' + e.message); process.exit(1); });
}
