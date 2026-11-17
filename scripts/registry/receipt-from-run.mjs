// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// Move the proof receipt of Mathesis to a green run of the Proof Policy Gate.
//
// PROOF-POLICY §8.4 rules 2 and 4 say a receipt moves only after CI has earned
// it, and §8.4 rule 5 keeps the lineage on the receipt. This script does that
// move for verification/receipts/theory_praxis.deed (§8.5.1, standards
// e5a39d7). It does not decide what the run proved; it copies only what the
// run's own record shows and what git holds:
//
//   * the run: a completed, successful push run of
//     .github/workflows/agda-proof-policy.yml on main, and its job "Agda, Rocq
//     and Lean in the pinned Guix" (GitHub's REST API, or --evidence DIR);
//   * the job log: for every graded root, the gate's PASS line, the file's
//     SHA-256 and the gate's axiom report, plus the checker versions and the
//     Guix commit. A graded root whose report is not a non-empty "none" is
//     refused: the script never writes an (axiom …) it cannot see;
//   * git: each manifest is written by the canon digest script
//     (standards scripts/proof-inputs-sha256.sh, pinned by its SHA-256), and
//     every file the log names must have the SHA-256 the log printed.
//
// Then it writes one new current receipt per leg, marks the old one
// superseded with the reason you give (in the shape of the earlier superseded
// receipts: no digest, manifest or axioms), and moves :source-commit. Before it
// writes anything, the result must pass the pinned canon reader (which derives
// each grade and refuses a recorded :pwg the receipts do not support) and the
// shared git checker (§8.5.3). The script never writes a grade.
//
//   bun scripts/registry/receipt-from-run.mjs receipt --run ID --why TEXT
//       [--commit SHA] [--evidence DIR | --save DIR] [--dry-run]
//   bun scripts/registry/receipt-from-run.mjs pin --at COMMIT
//
// `receipt` needs MATHESIS_STANDARDS (as claims-registry.mjs) and origin/main
// with its history. `pin` moves each claims.jsonl row that pins this receipt to
// COMMIT, which must hold the new receipt, and to that file's SHA-256.
import {readFile, writeFile, mkdir, mkdtemp, rm} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {tmpdir} from 'node:os';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {loadReader, checkerScript, findTool, CHECKER} from './claims-registry.mjs';
import {jcs} from './theory-ledger.mjs';
import {HOME} from './theory.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const DEED = 'verification/receipts/theory_praxis.deed';
export const CLAIMS = 'docs/atlas/claims/claims.jsonl';
export const WORKFLOW = '.github/workflows/agda-proof-policy.yml';
export const JOB = 'Agda, Rocq and Lean in the pinned Guix';

// The receipt's prover names, the gate's names for them, and where their
// proofs live. `config` lists the files of §8.5.1 that a run of that prover
// can read besides the proofs; any that exist at the commit join the manifest.
export const PROVERS = {
  agda: {gate: 'agda', dir: 'verification/proofs/agda', label: 'agda', config: n => n.endsWith('.agda-lib') || n === 'libraries'},
  rocq: {gate: 'coq', dir: 'verification/proofs/coq', label: 'coqc', config: n => ['_CoqProject', 'dune', 'dune-project'].includes(n)},
  lean: {gate: 'lean4', dir: 'verification/proofs/lean4', label: 'lean', config: n => ['lean-toolchain', 'lakefile.lean', 'lakefile.toml', 'lake-manifest.json'].includes(n)},
};

// The audit report the gate prints for a module that passed, per gate prover:
// only the forms of the fixed gate (hyperpolymath/mathesis#107), which audits
// definitions as well as theorems. The earlier gate's reports ("N theorem(s)"
// for Rocq, "N declared theorem(s)" for Lean) inspected no definition, so a
// receipt from them could again carry vacuous axiom evidence (audit finding
// 31); they are refused. The counts must add up to at least one: an audit that
// inspected nothing is no evidence. For Agda the count is the first-party
// modules of the import cone, and the names follow it.
export const NOTES = {
  agda: /^postulates: none in the (\d+) first-party module\(s\) of the import cone: (.*)$/,
  coq: /^Print Assumptions: closed under the global context for (\d+) declaration\(s\):/,
  lean4: /^axioms: none for (\d+) theorem\(s\) and (\d+) definition\(s\) with a source range$/,
};
const EARLIER = {
  coq: /^Print Assumptions: closed under the global context for \d+ theorem\(s\)|^no theorem declared$/,
  lean4: /^axioms: none for \d+ declared theorem\(s\)$/,
};

const HEX40 = /^[0-9a-f]{40}$/;
const sha256 = data => createHash('sha256').update(data).digest('hex');
const fail = m => { throw new Error(m); };

// ── The run ──────────────────────────────────────────────────────────────────

// Check that `run` (GET /actions/runs/ID) and `jobs` (GET …/jobs) describe a
// green push run of the gate on main, at `commit` when one is given. Returns
// {commit, job}.
export function checkRun(run, jobs, commit = null) {
  const no = m => fail(`run ${run?.id}: ${m}`);
  if (run?.repository?.full_name && run.repository.full_name !== HOME) no(`is a run of ${run.repository.full_name}, not ${HOME}`);
  if (String(run?.path ?? '').split('@')[0] !== WORKFLOW) no(`is a run of ${run?.path}, not ${WORKFLOW}`);
  if (run.event !== 'push' || run.head_branch !== 'main') no(`is a ${run.event} run on ${run.head_branch}, not a push run on main`);
  if (run.status !== 'completed' || run.conclusion !== 'success') no(`is ${run.status}/${run.conclusion}, not completed/success`);
  if (!HEX40.test(run.head_sha ?? '')) no('names no full head commit');
  if (commit !== null && run.head_sha !== commit) no(`ran on ${run.head_sha}, not ${commit}`);
  const named = (jobs?.jobs ?? []).filter(j => j.name === JOB);
  if (named.length !== 1) no(`has ${named.length} jobs named "${JOB}", not one`);
  const [job] = named;
  if (job.status !== 'completed' || job.conclusion !== 'success') no(`job ${job.id} is ${job.status}/${job.conclusion}`);
  if (job.head_sha !== run.head_sha) no(`job ${job.id} ran on ${job.head_sha}, not ${run.head_sha}`);
  if (job.run_attempt !== undefined && run.run_attempt !== undefined && job.run_attempt !== run.run_attempt) {
    no(`job ${job.id} is from attempt ${job.run_attempt}, not the run's attempt ${run.run_attempt}`);
  }
  if (!/^https:\/\/github\.com\/[^/]+\/[^/]+\/actions\/runs\/\d+\/job\/\d+$/.test(job.html_url ?? '')) no(`job ${job.id} has no job URL`);
  return {commit: run.head_sha, job};
}

// ── The log ──────────────────────────────────────────────────────────────────

// Read a job log into {gates, versions, guix}. `gates[gateProver]` maps each
// module "<root>/<rel>" to {status, sha256, note}. The gate runs twice (its
// lane, then the golden path); every run must end in RESULT: PASS and all runs
// must agree, or the log is refused.
export function parseGateLog(text) {
  const lines = text.split(/\r?\n/).map(l => l
    .replace(/^\uFEFF/, '')
    .replace(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z ?/, '')
    .replace(/\x1b\[[0-9;]*[A-Za-z]/g, ''));
  const runs = [];
  let cur = null, last = null;
  for (const line of lines) {
    let m;
    if ((m = /^=== (agda|coq|lean4|idris2) proof check ===$/.exec(line))) {
      cur = {prover: m[1], modules: new Map(), result: null, coverage: false};
      runs.push(cur);
      last = null;
      continue;
    }
    if (!cur) continue;
    if (/^=== manifest coverage /.test(line)) { cur.coverage = true; last = null; continue; }
    if ((m = /^RESULT: (PASS|FAIL)\b/.exec(line))) { cur.result = m[1]; cur = null; last = null; continue; }
    if (cur.coverage) continue;
    if ((m = /^ {2}(\S+)\s+(\S+)\s+(PASS|FAIL|PASS -- UNEXPECTED.*|fail \(quarantined, expected\))$/.exec(line))) {
      last = {status: m[3], sha256: null, note: null};
      cur.modules.set(`${m[1]}/${m[2]}`, last);
      continue;
    }
    if (last && (m = /^ {8}sha256 ([0-9a-f]{64})$/.exec(line))) { last.sha256 = m[1]; continue; }
    if (last && last.sha256 && last.note === null && /^ {8}\S/.test(line)) { last.note = line.trim(); continue; }
  }
  const gates = {};
  for (const r of runs) {
    if (r.result !== 'PASS') fail(`the ${r.prover} gate run in the log ends in ${r.result ?? 'no RESULT line'}, not RESULT: PASS`);
    const seen = gates[r.prover];
    if (!seen) { gates[r.prover] = r.modules; continue; }
    const key = mods => JSON.stringify([...mods].sort(([a], [b]) => (a < b ? -1 : a > b)));
    if (key(seen) !== key(r.modules)) fail(`the ${r.prover} gate ran more than once in the log, and the runs disagree`);
  }
  const one = (re, what) => {
    const found = new Set(lines.map(l => re.exec(l)?.[1]).filter(Boolean));
    if (found.size !== 1) fail(`the log shows ${found.size === 0 ? 'no' : `${found.size} different`} ${what}`);
    return [...found][0];
  };
  const versions = {
    agda: one(/^Agda version (\S+)$/, 'Agda version'),
    rocq: one(/^The (?:Coq Proof Assistant|Rocq Prover), version (\S+)/, 'Rocq version'),
    lean: one(/^Lean \(version ([^,\s]+),/, 'Lean version'),
  };
  const guix = one(/^\s+commit: ([0-9a-f]{40})$/, 'Guix channel commit');
  return {gates, versions, guix};
}

// ── The deed, as spans ───────────────────────────────────────────────────────

// Read the deed's lists and atoms with their byte offsets, so that an edit
// touches only the bytes it means to and every comment and layout survives.
// This locates spans only; the canon reader decides whether the result is valid.
export function parseSpans(text) {
  const top = [], stack = [];
  const push = node => (stack.length ? stack.at(-1).items : top).push(node);
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (c === ';') { while (i < text.length && text[i] !== '\n') i++; continue; }
    if (c === '(') { const n = {type: 'list', start: i, end: -1, items: []}; push(n); stack.push(n); i++; continue; }
    if (c === ')') { const n = stack.pop() ?? fail(`unbalanced ) at offset ${i}`); n.end = i + 1; i++; continue; }
    if (/\s/.test(c)) { i++; continue; }
    const s = i;
    const q = /^#?[A-Za-z0-9]*"/.exec(text.slice(i, i + 8));
    if (q && (c === '"' || c === '#')) {
      i += q[0].length;
      while (i < text.length && text[i] !== '"') i += text[i] === '\\' ? 2 : 1;
      if (i >= text.length) fail(`unterminated string at offset ${s}`);
      i++;
      const raw = text.slice(s + q[0].length, i - 1);
      push({type: 'atom', start: s, end: i, text: text.slice(s, i), value: raw.replace(/\\(.)/g, '$1')});
      continue;
    }
    while (i < text.length && !/[\s();"]/.test(text[i])) i++;
    push({type: 'atom', start: s, end: i, text: text.slice(s, i), value: text.slice(s, i)});
  }
  if (stack.length) fail('unbalanced ( in the deed');
  return top;
}
const headOf = n => (n.type === 'list' && n.items[0]?.type === 'atom' ? n.items[0].value : null);
const children = (n, head) => n.items.filter(x => headOf(x) === head);
const keyAtom = (n, key) => n.items.find(x => x.type === 'atom' && x.value === `:${key}`);
const valueAtom = (n, key) => { const i = n.items.indexOf(keyAtom(n, key)); return i < 0 ? null : n.items[i + 1]; };
const value = (n, key) => valueAtom(n, key)?.value ?? null;
const column = (text, offset) => offset - (text.lastIndexOf('\n', offset - 1) + 1);
const quote = s => {
  if (/["\\\n\r\t]/.test(s) || s.trim() === '') fail(`refusing a deed string with a quote, backslash, control character or nothing in it: ${JSON.stringify(s)}`);
  return `"${s}"`;
};

// The legs of the deed with a current receipt: [{claim, prover, leg, receipt}].
export function currentReceipts(text) {
  const deed = parseSpans(text).find(n => headOf(n) === 'praxis-deed') ?? fail('no (praxis-deed …) in the receipt');
  if (children(deed, 'echo').length) fail('the receipt has (echo …) records; moving them is not this script\'s job');
  const out = [];
  for (const claim of children(deed, 'claim')) {
    for (const leg of children(claim, 'leg')) {
      const cur = children(leg, 'receipt').filter(r => value(r, 'state') === 'current');
      if (cur.length > 1) fail(`claim ${value(claim, 'id')}: the ${value(leg, 'prover')} leg has ${cur.length} current receipts`);
      if (cur.length) out.push({claim: value(claim, 'id'), prover: value(leg, 'prover'), leg, receipt: cur[0]});
    }
  }
  return {deed, legs: out};
}

// The text of a new current receipt, laid out as the existing ones are.
export function receiptText({run, commit, checker, invocation, digest, manifest}, fieldIndent) {
  const f = ' '.repeat(fieldIndent);
  const files = manifest.map(m => `${f}  (file :path ${quote(m.path)} :sha256 ${quote(m.sha256)})`).join('\n');
  return [
    `(receipt :run ${quote(run)}`,
    `${f}:commit ${quote(commit)}`,
    `${f}:checker ${quote(checker)}`,
    `${f}:invocation ${quote(invocation)}`,
    `${f}:inputs-sha256 ${quote(digest)}`,
    `${f}:state current`,
    `${f}(axioms)`,
    `${f}(inputs-manifest`,
    `${files}))`,
  ].join('\n');
}

// Whether text[start, end) holds a comment (a ";" outside a string).
const hasComment = (text, start, end) => {
  for (let i = start, inString = false; i < end; i++) {
    if (inString) { if (text[i] === '\\') i++; else if (text[i] === '"') inString = false; } else if (text[i] === '"') inString = true; else if (text[i] === ';') return true;
  }
  return false;
};

// The old current receipt as a superseded one, in the shape of the receipts
// superseded before it (owner ruling 2026-11-17): :run, :commit, :checker and
// :invocation as they were written, then :state superseded and :reason. Its
// :inputs-sha256, (axioms …) and (inputs-manifest …) are dropped; §8.5.1 lets a
// receipt that is not current omit them, and git keeps them at the receipt's
// earlier commit. A comment inside it would be lost, so it is refused.
export function supersededText(text, receipt, fieldIndent, reason) {
  if (hasComment(text, receipt.start, receipt.end)) fail(`the receipt at offset ${receipt.start} holds a comment, which superseding it would drop`);
  const f = ' '.repeat(fieldIndent);
  const field = k => valueAtom(receipt, k)?.text ?? fail(`the receipt at offset ${receipt.start} has no :${k}`);
  return [
    `(receipt :run ${field('run')}`,
    `${f}:commit ${field('commit')}`,
    `${f}:checker ${field('checker')}`,
    `${f}:invocation ${field('invocation')}`,
    `${f}:state superseded`,
    `${f}:reason ${quote(reason)})`,
  ].join('\n');
}

// Apply the move to the deed text: a new current receipt before each old one,
// the old one superseded with `reason` (supersededText), :source-commit moved,
// and the old run, commit and Guix named in the header comment replaced by the
// new ones. `receipts` maps "claim prover" to the fields of receiptText.
// Returns {text, header}, where `header` lists the header replacements made.
export function rewriteDeed(text, {commit, runId, receipts, reason, guix}) {
  const {deed, legs} = currentReceipts(text);
  const old = value(deed, 'source-commit');
  if (old === commit) fail(`the receipt already describes ${commit}`);
  const edits = [];
  const runs = new Set(), guixes = new Set();
  for (const {claim, prover, receipt} of legs) {
    const fields = receipts.get(`${claim} ${prover}`) ?? fail(`no new receipt for claim ${claim}, ${prover} leg`);
    if (value(receipt, 'commit') !== old) fail(`claim ${claim}, ${prover} leg: the current receipt is at ${value(receipt, 'commit')}, not the :source-commit ${old}`);
    runs.add(/\/actions\/runs\/(\d+)/.exec(value(receipt, 'run'))?.[1] ?? fail(`claim ${claim}, ${prover} leg: the current :run is not a CI run`));
    const g = /\(Guix ([0-9a-f]{7,40})\)/.exec(value(receipt, 'checker'))?.[1];
    if (g) guixes.add(g);
    const indent = column(text, receipt.start);
    const fieldIndent = column(text, keyAtom(receipt, 'commit').start);
    edits.push({at: receipt.start, del: receipt.end - receipt.start,
      ins: receiptText(fields, fieldIndent) + '\n' + ' '.repeat(indent) + supersededText(text, receipt, fieldIndent, reason)});
  }
  if (legs.length === 0) fail('the receipt has no current receipt to move');
  if (receipts.size !== legs.length) fail(`${receipts.size} new receipts for ${legs.length} legs`);
  const src = valueAtom(deed, 'source-commit');
  edits.push({at: src.start, del: src.end - src.start, ins: `"${commit}"`});
  // The header comment names the current run, commit and Guix: move those words.
  const header = [];
  const swaps = [...runs].map(r => [r, String(runId)]);
  swaps.push([old, commit], [old.slice(0, 7), commit.slice(0, 7)]);
  for (const g of guixes) if (g !== guix.slice(0, g.length)) swaps.push([`Guix ${g}`, `Guix ${guix.slice(0, g.length)}`]);
  let head = text.slice(0, deed.start);
  for (const [from, to] of swaps) {
    const re = new RegExp(`(?<![0-9A-Za-z])${from.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(?![0-9A-Za-z])`, 'g');
    const n = (head.match(re) ?? []).length;
    if (n) { head = head.replace(re, to); header.push(`${from} -> ${to} (${n}x)`); }
  }
  let out = text;
  for (const e of edits.sort((a, b) => b.at - a.at)) out = out.slice(0, e.at) + e.ins + out.slice(e.at + e.del);
  return {text: head + out.slice(deed.start), header};
}

// ── Inputs: what each prover's run read at the commit (§8.5.1) ──────────────

// The input paths of each receipt prover, from the log and the tree at the
// commit. Agda: the first-party files of the import cones of the graded
// roots, as the gate printed them. Rocq and Lean: every module the gate
// compiled. Each: the config files of PROVERS that exist. `files` is the set of
// paths at the commit; `roots` maps each receipt prover to its graded roots
// (paths). Throws if a graded root did not pass with a non-empty no-axiom
// report, or if a cone's file count differs from the gate's.
export function inputPaths(gates, files, roots) {
  const out = {}, notes = {};
  for (const [prover, spec] of Object.entries(PROVERS)) {
    if (!roots[prover]?.length) continue;
    const mods = gates[spec.gate] ?? fail(`the log has no ${spec.gate} gate run`);
    const set = new Set();
    for (const r of roots[prover]) {
      const m = mods.get(r) ?? fail(`the ${spec.gate} gate in the log did not check ${r}`);
      if (m.status !== 'PASS') fail(`the ${spec.gate} gate reports ${r} as ${m.status}`);
      if (!m.sha256) fail(`the ${spec.gate} gate printed no sha256 for ${r}`);
      const n = NOTES[spec.gate].exec(m.note ?? '');
      if (!n && EARLIER[spec.gate]?.test(m.note ?? '')) {
        fail(`the ${spec.gate} gate's report for ${r} is from the gate before #107, which audits no definition: ${JSON.stringify(m.note)}`);
      }
      if (!n) fail(`the ${spec.gate} gate's report for ${r} is not a no-axiom report: ${JSON.stringify(m.note)}`);
      if (Number(n[1]) + Number(spec.gate === 'lean4' ? n[2] : 0) < 1) fail(`the ${spec.gate} gate's audit of ${r} inspected nothing: ${JSON.stringify(m.note)}`);
      notes[r] = m.note;
      if (prover === 'agda') {
        const cone = n[2].trim().split(/\s+/).map(name => `${spec.dir}/${name.replaceAll('.', '/')}.agda`).filter(f => files.has(f));
        if (cone.length !== Number(n[1])) fail(`the gate counts ${n[1]} first-party modules in the cone of ${r}, but ${cone.length} of its names are files at the commit`);
        cone.forEach(f => set.add(f));
      }
    }
    if (prover !== 'agda') for (const k of mods.keys()) set.add(k);
    // Agda looks for its library files in the directory it runs in and in
    // every parent; the other provers read their config beside the proofs.
    const dirs = new Set([spec.dir]);
    if (prover === 'agda') for (let d = spec.dir; d !== '.'; d = path.posix.dirname(d)) dirs.add(path.posix.dirname(d));
    for (const f of files) if (dirs.has(path.posix.dirname(f)) && spec.config(path.posix.basename(f))) set.add(f);
    out[prover] = [...set];
  }
  return {paths: out, notes};
}

// ── Git and the pinned canon scripts ─────────────────────────────────────────

const run = (cmd, args, opts = {}) => spawnSync(findTool(cmd), args, {encoding: 'utf8', maxBuffer: 1 << 26, ...opts});
const git = (repo, ...args) => {
  const r = run('git', ['-C', repo, ...args]);
  if (r.status !== 0) fail(`git ${args.join(' ')}: ${(r.stderr || r.error?.message || '').trim()}`);
  return r.stdout;
};
const isAncestor = (repo, a, b) => run('git', ['-C', repo, 'merge-base', '--is-ancestor', a, b]).status === 0;

// The manifest of PATHS at COMMIT, from the pinned canon digest script.
export async function canonManifest(repo, commit, paths, standardsDir = process.env.MATHESIS_STANDARDS) {
  await checkerScript(standardsDir); // checks the reader, the checker and the digest script against their pins
  const script = path.resolve(standardsDir, CHECKER.digest);
  const r = run('bash', [script, '-C', repo, '--manifest', commit, ...paths]);
  if (r.status !== 0) fail(`proof-inputs-sha256.sh at ${commit}: ${(r.stdout + r.stderr).trim()}`);
  const manifest = r.stdout.trimEnd().split('\n').map(l => {
    const m = /^([0-9a-f]{64}) {2}(.+)$/.exec(l) ?? fail(`unexpected manifest line: ${l}`);
    return {sha256: m[1], path: m[2]};
  });
  return {manifest, digest: sha256(r.stdout)};
}

// ── Evidence: the run, its jobs and the log ──────────────────────────────────

async function fetchEvidence(runId) {
  const headers = {Accept: 'application/vnd.github+json', 'User-Agent': 'mathesis-receipt-from-run'};
  if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  const get = async url => {
    const res = await fetch(url, {headers, redirect: 'follow'});
    if (!res.ok) fail(`GET ${url}: HTTP ${res.status}`);
    return res;
  };
  const api = `https://api.github.com/repos/${HOME}/actions`;
  const runJson = await (await get(`${api}/runs/${runId}`)).json();
  const jobsJson = await (await get(`${api}/runs/${runId}/jobs?filter=latest&per_page=100`)).json();
  const job = (jobsJson.jobs ?? []).find(j => j.name === JOB);
  const log = job ? await (await get(`${api}/jobs/${job.id}/logs`)).text() : '';
  return {run: runJson, jobs: jobsJson, log};
}

async function readEvidence(dir) {
  return {
    run: JSON.parse(await readFile(path.join(dir, 'run.json'), 'utf8')),
    jobs: JSON.parse(await readFile(path.join(dir, 'jobs.json'), 'utf8')),
    log: await readFile(path.join(dir, 'job.log'), 'utf8'),
  };
}

async function saveEvidence(dir, ev) {
  await mkdir(dir, {recursive: true});
  await writeFile(path.join(dir, 'run.json'), JSON.stringify(ev.run, null, 2) + '\n');
  await writeFile(path.join(dir, 'jobs.json'), JSON.stringify(ev.jobs, null, 2) + '\n');
  await writeFile(path.join(dir, 'job.log'), ev.log);
}

// ── The move ─────────────────────────────────────────────────────────────────

// Plan and check the move. Returns {text, report}; writes nothing. `repo` is
// a clone of Mathesis whose `branch` holds the run's commit.
export async function planMove({repo = root, deedPath = DEED, evidence, why, commit = null, branch = 'origin/main', standardsDir = process.env.MATHESIS_STANDARDS}) {
  if (!why || !why.trim()) fail('--why is required: say why the new receipt replaces the old one');
  const {commit: at, job} = checkRun(evidence.run, evidence.jobs, commit);
  const log = parseGateLog(evidence.log);
  const text = await readFile(path.join(repo, deedPath), 'utf8');
  const {legs, deed} = currentReceipts(text);
  const old = value(deed, 'source-commit');
  if (old === at) fail(`the receipt already describes ${at}`);
  if (!isAncestor(repo, old, at)) fail(`${at} does not descend from the receipt's :source-commit ${old}; a receipt moves forward only`);
  if (!isAncestor(repo, at, branch)) fail(`${at} is not on ${branch}`);
  const channels = git(repo, 'show', `${at}:build/channels.scm`);
  if (!channels.includes(`(commit "${log.guix}")`)) fail(`the log's Guix commit ${log.guix} is not the one build/channels.scm pins at ${at}`);

  // The graded roots of each prover, from the invocations of the current receipts.
  const roots = {};
  for (const l of legs) {
    const spec = PROVERS[l.prover] ?? fail(`claim ${l.claim}: no gate lane for prover ${l.prover}`);
    const file = value(l.receipt, 'invocation').trim().split(/\s+/).at(-1);
    (roots[l.prover] ??= new Set()).add(`${spec.dir}/${file}`);
  }
  for (const p of Object.keys(roots)) roots[p] = [...roots[p]];
  const files = new Set(git(repo, 'ls-tree', '-r', '--name-only', '--full-tree', at).split('\n').filter(Boolean));
  const {paths, notes} = inputPaths(log.gates, files, roots);

  // One manifest per prover (§8.5.1: one digest for one commit and one prover),
  // each file checked against the SHA-256 that the log printed for it.
  const inputs = {};
  for (const [prover, list] of Object.entries(paths)) {
    const m = await canonManifest(repo, at, list, standardsDir);
    for (const f of m.manifest) {
      const seen = log.gates[PROVERS[prover].gate].get(f.path);
      if (seen && seen.sha256 !== f.sha256) fail(`${f.path}: the log printed sha256 ${seen.sha256}, git has ${f.sha256} at ${at}`);
    }
    inputs[prover] = m;
  }
  const checker = p => `${PROVERS[p].label} ${log.versions[p]} (Guix ${log.guix.slice(0, 7)})`;
  const receipts = new Map(legs.map(l => [`${l.claim} ${l.prover}`, {
    run: job.html_url, commit: at, checker: checker(l.prover), invocation: value(l.receipt, 'invocation'),
    digest: inputs[l.prover].digest, manifest: inputs[l.prover].manifest,
  }]));
  const reason = `replaced by the CI receipt of run ${evidence.run.id} on ${at.slice(0, 7)}, ${why.trim()}`;
  const moved = rewriteDeed(text, {commit: at, runId: evidence.run.id, receipts, reason, guix: log.guix});
  const out = moved.text;

  // The canon reader must accept the result, and derives each grade.
  const readProofReceipt = await loadReader(standardsDir);
  const record = readProofReceipt(out, path.basename(deedPath));
  // The shared git checker (§8.5.3) must pass on the result.
  const work = await mkdtemp(path.join(tmpdir(), 'mathesis-receipt-'));
  try {
    const file = path.join(work, path.basename(deedPath));
    await writeFile(file, out);
    const r = run('bash', [await checkerScript(standardsDir), '--branch', branch, file, repo]);
    if (r.status !== 0) fail(`check-proof-receipt.sh refuses the new receipt (exit ${r.status}):\n${(r.stdout + r.stderr).split('\n').filter(l => !l.startsWith('ok ')).join('\n')}`);
  } finally {
    await rm(work, {recursive: true, force: true});
  }

  const oldPaths = p => [...new Set(legs.filter(l => l.prover === p).flatMap(l =>
    children(children(l.receipt, 'inputs-manifest')[0] ?? {items: []}, 'file').map(f => value(f, 'path'))))];
  const report = [
    `run      ${job.html_url}`,
    `commit   ${at} (was ${old})`,
    `toolchain Guix ${log.guix}; ${Object.keys(PROVERS).map(checker).join('; ')}`,
    ...Object.entries(inputs).map(([p, m]) => {
      const before = new Set(oldPaths(p)), now = new Set(m.manifest.map(f => f.path));
      const delta = [...now].filter(x => !before.has(x)).map(x => `+${x}`).concat([...before].filter(x => !now.has(x)).map(x => `-${x}`));
      return `inputs   ${p}: ${m.digest} (${m.manifest.length} files${delta.length ? `; ${delta.join(' ')}` : '; same paths as before'})`;
    }),
    ...Object.entries(notes).map(([r, n]) => `audit    ${r}: ${n}`),
    `header   ${moved.header.join('; ') || 'no change'}`,
    `reason   ${reason}`,
    `reader   accepts; derived: ${record.claims.map(c => `${c.id} ${c.pwg}`).join(', ')}`,
    `checker  check-proof-receipt.sh --branch ${branch}: every check holds`,
  ];
  return {text: out, report, record};
}

// ── The claim pins ───────────────────────────────────────────────────────────

// Move every claims.jsonl row that pins the receipt at `deedPath` to `at`, with
// the SHA-256 of that file at `at`. Each claim pinned must be in that receipt,
// and the canon reader must accept it. Returns {text, moved, notOnMain}.
export async function planPin({repo = root, claimsPath = CLAIMS, deedPath = DEED, at, branch = 'origin/main', standardsDir = process.env.MATHESIS_STANDARDS}) {
  const commit = git(repo, 'rev-parse', '--verify', `${at}^{commit}`).trim();
  const receipt = git(repo, 'show', `${commit}:${deedPath}`);
  const readProofReceipt = await loadReader(standardsDir);
  const ids = new Set(readProofReceipt(receipt, path.basename(deedPath)).claims.map(c => c.id));
  const digest = sha256(receipt);
  const text = await readFile(path.join(repo, claimsPath), 'utf8');
  if (!text.endsWith('\n')) fail(`${claimsPath}: the last line has no LF`);
  const moved = [];
  const lines = text.slice(0, -1).split('\n').map(line => {
    const row = JSON.parse(line);
    if (row.repo !== HOME || row.receipt?.path !== deedPath) return line;
    if (!ids.has(row.claim)) fail(`${row.id} pins ${deedPath}, but the receipt at ${commit} has no claim ${row.claim}`);
    moved.push(`${row.claim}: ${row.source_commit.slice(0, 7)} -> ${commit.slice(0, 7)}`);
    return jcs({...row, source_commit: commit, receipt: {...row.receipt, sha256: digest}});
  });
  if (moved.length === 0) fail(`no row of ${claimsPath} pins ${deedPath}`);
  return {text: lines.join('\n') + '\n', moved, digest, commit, notOnMain: !isAncestor(repo, commit, branch)};
}

// ── Entry point ──────────────────────────────────────────────────────────────

function flags(args, spec) {
  const out = {};
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (!a.startsWith('--') || !(a.slice(2) in spec)) fail(`unknown argument ${a}`);
    const k = a.slice(2);
    if (spec[k] === 'bool') out[k] = true;
    else if (i + 1 < args.length) out[k] = args[++i];
    else fail(`${a} needs a value`);
  }
  return out;
}

async function main() {
  const [cmd, ...args] = process.argv.slice(2);
  if (cmd === 'receipt') {
    const o = flags(args, {run: 'v', why: 'v', commit: 'v', evidence: 'v', save: 'v', 'dry-run': 'bool'});
    if (!/^\d+$/.test(o.run ?? '')) fail('--run needs the numeric id of a Proof Policy Gate run');
    if (o.commit && !HEX40.test(o.commit)) fail('--commit needs a full 40-character commit');
    const evidence = o.evidence ? await readEvidence(path.resolve(o.evidence)) : await fetchEvidence(o.run);
    if (String(evidence.run.id) !== o.run) fail(`the evidence is for run ${evidence.run.id}, not ${o.run}`);
    if (o.save) await saveEvidence(path.resolve(o.save), evidence);
    const {text, report} = await planMove({evidence, why: o.why, commit: o.commit ?? null});
    console.log(report.join('\n'));
    if (o['dry-run']) { console.log(`DRY RUN: ${DEED} not written`); return; }
    await writeFile(path.join(root, DEED), text);
    console.log(`WROTE ${DEED}. Commit it, then pin the claims to that commit: bun scripts/registry/receipt-from-run.mjs pin --at <commit>`);
    return;
  }
  if (cmd === 'pin') {
    const o = flags(args, {at: 'v', 'dry-run': 'bool'});
    if (!o.at) fail('--at needs the commit that holds the new receipt');
    const {text, moved, digest, commit, notOnMain} = await planPin({at: o.at});
    console.log(`receipt  ${DEED} at ${commit}: sha256 ${digest}`);
    console.log(`moved    ${moved.join(', ')}`);
    if (notOnMain) console.log(`NOTE     ${commit} is not on origin/main; the registry fetches it by its id while GitHub keeps it (a PR head ref does)`);
    if (o['dry-run']) { console.log(`DRY RUN: ${CLAIMS} not written`); return; }
    await writeFile(path.join(root, CLAIMS), text);
    console.log(`WROTE ${CLAIMS}. Then regenerate the views: bun scripts/registry/claims-registry.mjs build`);
    return;
  }
  console.error('usage: receipt-from-run.mjs receipt --run ID --why TEXT [--commit SHA] [--evidence DIR | --save DIR] [--dry-run]\n' +
    '       receipt-from-run.mjs pin --at COMMIT [--dry-run]');
  process.exit(2);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(e => { console.error('ERROR: ' + e.message); process.exit(1); });
}
