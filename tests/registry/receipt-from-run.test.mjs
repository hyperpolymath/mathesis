// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// Hermetic tests of scripts/registry/receipt-from-run.mjs. Each end-to-end
// test builds a small git repository with Agda, Rocq and Lean proofs, a
// receipt at its first commit and a gate log for its second, then moves the
// receipt. Like claims-registry.test.mjs, they need MATHESIS_STANDARDS: the
// result must pass the pinned canon reader and the shared git checker.
import {test, expect, beforeAll} from 'bun:test';
import {mkdtempSync, mkdirSync, writeFileSync, readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {checkRun, parseGateLog, parseSpans, inputPaths, currentReceipts, canonManifest, planMove, planPin, idSegment, apiUrl, JOB, WORKFLOW, DEED, CLAIMS}
  from '../../scripts/registry/receipt-from-run.mjs';
import {findTool} from '../../scripts/registry/claims-registry.mjs';
import {jcs} from '../../scripts/registry/theory-ledger.mjs';

const sha = s => createHash('sha256').update(s).digest('hex');
const GUIX = '8edb9da7052607f17f09007933275b43978fcf9d';
const git = (dir, ...args) => {
  const r = spawnSync(findTool('git'), ['-C', dir, '-c', 'user.name=t', '-c', 'user.email=t@t', '-c', 'commit.gpgsign=false', ...args], {encoding: 'utf8'});
  if (r.status !== 0) throw new Error(`git ${args.join(' ')}: ${r.stderr}`);
  return r.stdout.trim();
};
const put = (dir, file, body) => { mkdirSync(path.dirname(path.join(dir, file)), {recursive: true}); writeFileSync(path.join(dir, file), body); };

// ── A gate log in the fixed gate's format ────────────────────────────────────

const AGDA_NOTE = (n, names) => `postulates: none in the ${n} first-party module(s) of the import cone: ${names} `;
const COQCHK = 'coqchk -o: no axiom, type-in-type, unsafe (co)fixpoint or assumed positivity in the library or its import cone; ';
const ROCQ_NOTE = `${COQCHK}Print Assumptions: closed under the global context for 3 declaration(s): Not t u `;
const LEAN_NOTE = 'axioms: none for 1 theorem(s) and 4 definition(s) with a source range';
// mods: [root, rel, file text, note]; a null file text is a quarantined module
// that failed as expected, which the gate prints with no SHA-256.
const gateRun = (prover, root, mods) => [
  `=== ${prover} proof check ===`,
  ...mods.flatMap(([r, rel, body, note]) => body === null
    ? [`  ${r.padEnd(30)} ${rel.padEnd(24)} fail (quarantined, expected)`, `        reason: ${note}`]
    : [`  ${r.padEnd(30)} ${rel.padEnd(24)} PASS`, `        sha256 ${sha(body)}`, `        ${note}`]),
  '', `=== manifest coverage (${root}) ===`, `  all ${mods.length} file(s) accounted for`, '',
  'RESULT: PASS -- gated modules compile; quarantined modules still fail as recorded'];
const logFor = (files, {guix = GUIX, notes = {}, quarantined = false} = {}) => {
  const A = 'verification/proofs/agda', C = 'verification/proofs/coq', L = 'verification/proofs/lean4';
  const lines = [
    '##[group]Run guix time-machine -C build/channels.scm -- describe',
    '  guix 8edb9da', '    repository URL: https://codeberg.org/guix/guix.git', '    branch: master', `    commit: ${guix}`,
    'Agda version 2.7.0.1', 'The Coq Proof Assistant, version 8.18.0', 'Lean (version 4.29.0, x86_64-unknown-linux-gnu, Release)',
  ];
  const once = () => [
    ...gateRun('agda', A, [
      [A, 'B.agda', files[`${A}/B.agda`], notes.B ?? AGDA_NOTE(1, 'Agda.Primitive B')],
      [A, 'Top.agda', files[`${A}/Top.agda`], notes.Top ?? AGDA_NOTE(2, 'Agda.Builtin.Nat Agda.Primitive B Top')],
      // Gated, but outside every graded cone: its SHA-256 is checked, and it is in no manifest.
      [A, 'Unused.agda', files[`${A}/Unused.agda`], AGDA_NOTE(1, 'Agda.Primitive Unused')],
    ]),
    ...gateRun('coq', C, [[C, 'Top.v', files[`${C}/Top.v`], notes.v ?? ROCQ_NOTE],
      ...(quarantined ? [[C, 'Old.v', null, ' an open obligation, kept to show it still fails']] : [])]),
    ...gateRun('lean4', L, [[L, 'Top.lean', files[`${L}/Top.lean`], notes.lean ?? LEAN_NOTE]]),
  ];
  // The gate runs in its lane and again in the golden path.
  return [...lines, ...once(), 'PASS: agda clean control passes', ...once()]
    // As GitHub serves it: a timestamp on every line, colour codes on some.
    .map((l, i) => `2026-11-17T15:16:${String(i % 60).padStart(2, '0')}.0000000Z ${i % 2 ? '' : '\x1b[36;1m'}${l}${i % 2 ? '' : '\x1b[0m'}`)
    .join('\n') + '\n';
};

// ── A repository with a receipt at c1 and a run at c2 ────────────────────────

const RUN0 = 'https://github.com/hyperpolymath/mathesis/actions/runs/6000/job/60';
const deedAt = async (repo, c1, inputs) => {
  const rec = (p, inv) => {
    const m = inputs[p];
    return `      (receipt :run "${RUN0}"\n               :commit "${c1}"\n               :checker "${p} (Guix 8edb9da)"\n` +
      `               :invocation "${inv}"\n               :inputs-sha256 "${m.digest}"\n               :state current\n` +
      '               (axioms)\n               (inputs-manifest\n' +
      m.manifest.map(f => `                 (file :path "${f.path}" :sha256 "${f.sha256}")`).join('\n') + '))';
  };
  return ';; SPDX-License-Identifier: CC-BY-SA-4.0\n' +
    `;; The current receipts come from run\n;; 6000 on main ${c1.slice(0, 7)}; a comment with ( and ) and "quotes".\n` +
    '(praxis-deed\n  :schema-version "1.0.0"\n  :canonical-name "fixture-receipt"\n  :profile proof-receipt\n' +
    `  :repository "hyperpolymath/mathesis"\n  :source-commit "${c1}"\n` +
    '  (claim :id "T-1" :pwg PWG-1 :foundation-diverse #f\n' +
    '    (leg :prover agda :route source :token proven :state AGDA-VERIFIED\n' + rec('agda', 'agda --safe --without-K --cubical-compatible Top.agda') + ')\n' +
    '    (leg :prover rocq :route re-proved :token proven :state RECONCILED ; a comment ) here\n' + rec('rocq', 'coqc Top.v') + ')\n' +
    '    (leg :prover lean :route re-proved :token proven :state RECONCILED\n' + rec('lean', 'lean Top.lean') + ')))\n';
};

const PATHS = {
  agda: ['verification/proofs/agda/B.agda', 'verification/proofs/agda/Top.agda'],
  rocq: ['verification/proofs/coq/Top.v'],
  lean: ['verification/proofs/lean4/Top.lean', 'verification/proofs/lean4/lean-toolchain'],
};

async function fixtureRepo() {
  const repo = mkdtempSync(path.join(tmpdir(), 'receipt-from-run-'));
  git(repo, 'init', '-q', '-b', 'main');
  const files = {
    'build/channels.scm': `(list (channel (name 'guix) (commit "${GUIX}")))\n`,
    'verification/proofs/agda/B.agda': 'module B where\n',
    'verification/proofs/agda/Top.agda': 'module Top where\nopen import B\n',
    'verification/proofs/agda/Unused.agda': 'module Unused where\n',
    'verification/proofs/coq/Top.v': 'Theorem t : True. exact I. Qed.\n',
    'verification/proofs/lean4/Top.lean': 'theorem t : True := trivial\n',
    'verification/proofs/lean4/lean-toolchain': 'leanprover/lean4:v4.29.0\n',
  };
  for (const [f, b] of Object.entries(files)) put(repo, f, b);
  git(repo, 'add', '-A'); git(repo, 'commit', '-q', '-m', 'c1');
  const c1 = git(repo, 'rev-parse', 'HEAD');
  const inputs = {};
  for (const [p, list] of Object.entries(PATHS)) inputs[p] = await canonManifest(repo, c1, list);
  put(repo, DEED, await deedAt(repo, c1, inputs));
  files['verification/proofs/agda/Top.agda'] = 'module Top where\nopen import B\n-- a new lemma\n';
  files['verification/proofs/lean4/Top.lean'] = 'theorem t : True := trivial\ntheorem u : True := trivial\n';
  for (const f of ['verification/proofs/agda/Top.agda', 'verification/proofs/lean4/Top.lean']) put(repo, f, files[f]);
  git(repo, 'add', '-A'); git(repo, 'commit', '-q', '-m', 'c2');
  const c2 = git(repo, 'rev-parse', 'HEAD');
  return {repo, files, c1, c2, inputs};
}

const evidenceFor = (c2, log, {run = {}, job = {}} = {}) => ({
  run: {id: 7000, path: WORKFLOW, event: 'push', head_branch: 'main', status: 'completed', conclusion: 'success', head_sha: c2, run_attempt: 1, ...run},
  jobs: {jobs: [{id: 70, run_id: 7000, name: JOB, status: 'completed', conclusion: 'success', head_sha: c2, run_attempt: 1,
    html_url: 'https://github.com/hyperpolymath/mathesis/actions/runs/7000/job/70', ...job}]},
  log,
});

let fx;
beforeAll(async () => { fx = await fixtureRepo(); });

// ── The run ──────────────────────────────────────────────────────────────────

test('a green push run of the gate on main is accepted; anything else is refused', () => {
  const ev = evidenceFor('c'.repeat(40), '');
  expect(checkRun(ev.run, ev.jobs).commit).toBe('c'.repeat(40));
  const no = (run, job = {}, commit = null) => { const e = evidenceFor('c'.repeat(40), '', {run, job}); return () => checkRun(e.run, e.jobs, commit); };
  expect(no({event: 'pull_request', head_branch: 'feature'})).toThrow(/not a push run on main/);
  expect(no({conclusion: 'failure'})).toThrow(/not completed\/success/);
  expect(no({path: '.github/workflows/other.yml'})).toThrow(/not .github\/workflows\/agda-proof-policy.yml/);
  expect(no({}, {}, 'd'.repeat(40))).toThrow(/ran on c+, not d+/);
  expect(no({}, {name: 'another job'})).toThrow(/has 0 jobs named/);
  expect(no({}, {conclusion: 'cancelled'})).toThrow(/completed\/cancelled/);
  expect(no({}, {run_attempt: 2})).toThrow(/attempt 2/);
  // The job must be this run's, in this repository.
  expect(no({}, {run_id: 7001})).toThrow(/belongs to run 7001, not run 7000/);
  expect(no({}, {html_url: 'https://github.com/hyperpolymath/mathesis/actions/runs/7001/job/70'})).toThrow(/is not a job of run 7000/);
  expect(no({}, {html_url: 'https://github.com/someone/else/actions/runs/7000/job/70'})).toThrow(/is not a job of run 7000 in hyperpolymath\/mathesis/);
  expect(no({}, {html_url: 'https://example.com/x'})).toThrow(/has no job URL/);
});

// ── The log ──────────────────────────────────────────────────────────────────

test('the log is read through its timestamps and colour codes, and both gate runs must agree', () => {
  const {gates, versions, guix} = parseGateLog(logFor(fx.files));
  expect(versions).toEqual({agda: '2.7.0.1', rocq: '8.18.0', lean: '4.29.0'});
  expect(guix).toBe(GUIX);
  const top = gates.agda.get('verification/proofs/agda/Top.agda');
  expect(top).toEqual({status: 'PASS', sha256: sha(fx.files['verification/proofs/agda/Top.agda']), note: AGDA_NOTE(2, 'Agda.Builtin.Nat Agda.Primitive B Top').trim()});
  const text = logFor(fx.files);
  const i = text.lastIndexOf(sha(fx.files['verification/proofs/coq/Top.v']));
  expect(() => parseGateLog(text.slice(0, i) + '0'.repeat(64) + text.slice(i + 64))).toThrow(/ran more than once in the log, and the runs disagree/);
  expect(() => parseGateLog(text.replace(/RESULT: PASS[^\n]*\n(?![\s\S]*RESULT: PASS)/, 'RESULT: FAIL (1 failure(s))\n'))).toThrow(/ends in FAIL/);
  expect(() => parseGateLog(text + 'Lean (version 4.30.0, x86_64-unknown-linux-gnu, Release)\n')).toThrow(/2 different Lean version/);
  expect(() => parseGateLog(text.replace(/Agda version 2\.7\.0\.1/g, ''))).toThrow(/no Agda version/);
  expect(() => parseGateLog(text + `    commit: ${'e'.repeat(40)}\n`)).toThrow(/2 different Guix channel commit/);
  // A module listed twice in one gate run, a stale SHA-256 first, would be overwritten
  // by the second entry; the log is refused instead.
  const twice = text.split('\n').flatMap(l => /Unused\.agda +PASS/.test(l)
    ? [l, `        sha256 ${'0'.repeat(64)}`, `        ${AGDA_NOTE(1, 'Agda.Primitive Unused').trim()}`, l] : [l]).join('\n');
  expect(() => parseGateLog(twice)).toThrow(/lists verification\/proofs\/agda\/Unused\.agda twice/);
});

test('only a non-empty no-axiom report of the fixed gate is evidence for a graded root', () => {
  const files = new Set(Object.keys(fx.files));
  const roots = {agda: ['verification/proofs/agda/Top.agda'], rocq: ['verification/proofs/coq/Top.v'], lean: ['verification/proofs/lean4/Top.lean']};
  const read = notes => parseGateLog(logFor(fx.files, {notes})).gates;
  const {paths} = inputPaths(read({}), files, roots);
  // A quarantined module that failed as expected is not an input; a gated module outside the cones is not either.
  expect(inputPaths(parseGateLog(logFor(fx.files, {quarantined: true})).gates, files, roots).paths.rocq).toEqual(['verification/proofs/coq/Top.v']);
  expect(paths).toEqual({agda: ['verification/proofs/agda/B.agda', 'verification/proofs/agda/Top.agda'],
    rocq: ['verification/proofs/coq/Top.v'], lean: ['verification/proofs/lean4/Top.lean', 'verification/proofs/lean4/lean-toolchain']});
  // The earlier gate's reports audit no definition (audit finding 31).
  expect(() => inputPaths(read({lean: 'axioms: none for 2 declared theorem(s)'}), files, roots)).toThrow(/form of an earlier gate/);
  expect(() => inputPaths(read({v: 'Print Assumptions: closed under the global context for 1 theorem(s): t '}), files, roots)).toThrow(/form of an earlier gate/);
  // The intermediate form of #107 audits definitions but runs no kernel check (coqchk).
  expect(() => inputPaths(read({v: 'Print Assumptions: closed under the global context for 3 declaration(s): Not t u '}), files, roots)).toThrow(/form of an earlier gate/);
  expect(() => inputPaths(read({lean: 'axioms: none for 0 theorem(s) and 0 definition(s) with a source range'}), files, roots)).toThrow(/inspected nothing/);
  expect(() => inputPaths(read({v: `${COQCHK}Print Assumptions: closed under the global context for 0 declaration(s): `}), files, roots)).toThrow(/inspected nothing/);
  expect(() => inputPaths(read({lean: 'axioms: Classical.choice'}), files, roots)).toThrow(/not a no-axiom report/);
  expect(() => inputPaths(read({Top: AGDA_NOTE(3, 'Agda.Primitive B Top')}), files, roots)).toThrow(/counts 3 first-party modules/);
  expect(() => inputPaths(read({}), files, {...roots, agda: ['verification/proofs/agda/Missing.agda']})).toThrow(/did not check/);
});

test('an id goes into an API path only as a positive integer', () => {
  expect(idSegment('44105371764', 'run')).toBe('44105371764');
  expect(idSegment(134116153255, 'job')).toBe('134116153255');
  for (const bad of ['1/../../x', '../users', '%2e%2e', '-1', '0', '1e3', 1.5, '', ' 7', null, '99999999999999999999']) {
    expect(() => idSegment(bad, 'run')).toThrow(/is not a positive integer id/);
    expect(() => apiUrl('logs', bad)).toThrow(/is not a positive integer id/);
  }
  const api = 'https://api.github.com/repos/hyperpolymath/mathesis/actions';
  expect(apiUrl('run', '44105371764').href).toBe(`${api}/runs/44105371764`);
  expect(apiUrl('jobs', 44105371764).href).toBe(`${api}/runs/44105371764/jobs?filter=latest&per_page=100`);
  expect(apiUrl('logs', 134116153255).href).toBe(`${api}/jobs/134116153255/logs`);
  expect(() => apiUrl('artifacts', 1)).toThrow(/no API request of kind/);
});

test('the span reader is not misled by parentheses and quotes in comments', () => {
  const text = ';; ( a "comment" )\n(a :k "v ; not a comment )" ; ) comment\n (b #u5"x" #f))\n';
  const [a] = parseSpans(text);
  expect(text.slice(a.start, a.end)).toBe(text.slice(text.indexOf('(a'), text.lastIndexOf(')') + 1));
  expect(a.items.map(x => x.type === 'list' ? 'list' : x.value)).toEqual(['a', ':k', 'v ; not a comment )', 'list']);
  expect(() => parseSpans('(a "b)')).toThrow(/unterminated string/);
  expect(() => parseSpans('(a))')).toThrow(/unbalanced \)/);
});

// ── The move, end to end ─────────────────────────────────────────────────────

const WHY = 'whose gate audits definitions as well';

test('the move writes one new current receipt per leg and supersedes the old one; the reader and the git checker accept it', async () => {
  const before = readFileSync(path.join(fx.repo, DEED), 'utf8');
  const {text, report, record} = await planMove({repo: fx.repo, evidence: evidenceFor(fx.c2, logFor(fx.files)), why: WHY, branch: 'main'});
  expect(readFileSync(path.join(fx.repo, DEED), 'utf8')).toBe(before); // planning writes nothing
  expect(record.source_commit).toBe(fx.c2);
  expect(record.claims.map(c => [c.id, c.pwg])).toEqual([['T-1', 'PWG-1']]);
  for (const leg of record.claims[0].legs) {
    const [cur, old] = leg.receipts;
    expect(cur).toMatchObject({state: 'current', commit: fx.c2, run: 'https://github.com/hyperpolymath/mathesis/actions/runs/7000/job/70', axioms: []});
    expect(old).toMatchObject({state: 'superseded', commit: fx.c1, run: RUN0,
      reason: `replaced by the CI receipt of run 7000 on ${fx.c2.slice(0, 7)}, ${WHY}`});
    // In the shape of the earlier superseded receipts (owner ruling 2026-11-17).
    expect(old['inputs-sha256']).toBeUndefined();
    expect(old.inputs_manifest).toBeNull();
    expect(old.axioms).toBeNull();
    expect(leg.receipts.length).toBe(2);
  }
  expect(text).toContain(`               :invocation "coqc Top.v"\n               :state superseded\n` +
    `               :reason "replaced by the CI receipt of run 7000 on ${fx.c2.slice(0, 7)}, ${WHY}")`);
  const lean = record.claims[0].legs.find(l => l.prover === 'lean').receipts[0];
  expect(lean.checker).toBe('lean 4.29.0 (Guix 8edb9da)');
  expect(lean.inputs_manifest.map(f => f.path)).toEqual(PATHS.lean);
  expect(lean['inputs-sha256']).not.toBe(fx.inputs.lean.digest); // Top.lean changed between c1 and c2
  const rocq = record.claims[0].legs.find(l => l.prover === 'rocq').receipts[0];
  expect(rocq['inputs-sha256']).toBe(fx.inputs.rocq.digest); // Top.v did not
  // The header comment and every comment survive; the header names the new run and commit.
  expect(text).toContain(`;; 7000 on main ${fx.c2.slice(0, 7)}; a comment with ( and ) and "quotes".`);
  expect(text).toContain('; a comment ) here');
  expect(report.join('\n')).toMatch(/checker {2}check-proof-receipt\.sh --branch main: every check holds/);
  // Moving it again to the same commit is refused.
  writeFileSync(path.join(fx.repo, DEED), text);
  try {
    await expect(planMove({repo: fx.repo, evidence: evidenceFor(fx.c2, logFor(fx.files)), why: WHY, branch: 'main'})).rejects.toThrow(/already describes/);
  } finally {
    writeFileSync(path.join(fx.repo, DEED), before);
  }
});

test('a green run with a quarantined module that failed as expected is accepted, and the module is in no manifest', async () => {
  const {record} = await planMove({repo: fx.repo, evidence: evidenceFor(fx.c2, logFor(fx.files, {quarantined: true})), why: WHY, branch: 'main'});
  expect(record.claims[0].pwg).toBe('PWG-1');
  const rocq = record.claims[0].legs.find(l => l.prover === 'rocq').receipts[0];
  expect(rocq.inputs_manifest.map(m => m.path)).toEqual(['verification/proofs/coq/Top.v']);
});

test('the move is refused when the log, the tree or the history disagree', async () => {
  const move = (opts = {}) => planMove({repo: fx.repo, evidence: evidenceFor(fx.c2, logFor(fx.files)), why: WHY, branch: 'main', ...opts});
  await expect(move({why: ' '})).rejects.toThrow(/--why is required/);
  await expect(move({why: 'with a "quote"'})).rejects.toThrow(/refusing a deed string/);
  // The log printed a SHA-256 that git does not have at the commit.
  const stale = {...fx.files, 'verification/proofs/agda/B.agda': 'module B where\n-- not what was committed\n'};
  await expect(move({evidence: evidenceFor(fx.c2, logFor(stale))})).rejects.toThrow(/the log printed sha256 .*, git has/);
  // A logged SHA-256 outside every manifest must hold too.
  const unused = {...fx.files, 'verification/proofs/agda/Unused.agda': 'module Unused where\n-- not what was committed\n'};
  await expect(move({evidence: evidenceFor(fx.c2, logFor(unused))})).rejects.toThrow(/Unused\.agda: the log printed sha256 .*, git has/);
  // One path given two SHA-256s by two provers' gates is refused, not overwritten.
  const clash = logFor(fx.files).split('\n').flatMap(l => /Top\.v +PASS/.test(l)
    ? [`  ${'verification/proofs/agda'.padEnd(30)} ${'B.agda'.padEnd(24)} PASS`, `        sha256 ${'0'.repeat(64)}`, `        ${ROCQ_NOTE.trim()}`, l] : [l]).join('\n');
  await expect(move({evidence: evidenceFor(fx.c2, clash)})).rejects.toThrow(/B\.agda: the log prints two SHA-256s for it/);
  // The Guix of the log is not the one the commit pins.
  await expect(move({evidence: evidenceFor(fx.c2, logFor(fx.files, {guix: 'f'.repeat(40)}))})).rejects.toThrow(/is not the one build\/channels.scm pins/);
  // A receipt moves forward only.
  await expect(move({evidence: evidenceFor(fx.c1, logFor(fx.files))})).rejects.toThrow(/already describes/);
  const side = git(fx.repo, 'commit-tree', `${fx.c2}^{tree}`, '-m', 'a root commit with no history'); // same tree, unrelated history
  await expect(move({evidence: evidenceFor(side, logFor(fx.files))})).rejects.toThrow(/does not descend from/);
  // The run's commit must be on the branch.
  git(fx.repo, 'branch', '-f', 'old-main', fx.c1);
  await expect(move({branch: 'old-main'})).rejects.toThrow(/is not on old-main/);
  // Superseding drops a receipt's fields after :invocation, so a comment inside it is refused, not dropped.
  const file = path.join(fx.repo, DEED), before = readFileSync(file, 'utf8');
  writeFileSync(file, before.replace('               (axioms)\n', '               (axioms) ; seen by hand\n'));
  try {
    await expect(move()).rejects.toThrow(/holds a comment, which superseding it would drop/);
  } finally {
    writeFileSync(file, before);
  }
  // Every current receipt must describe the :source-commit; a mixed receipt is not moved.
  const parts = before.split(`:commit "${fx.c1}"`);
  writeFileSync(file, parts.slice(0, 3).join(`:commit "${fx.c1}"`) + `:commit "${'b'.repeat(40)}"` + parts.slice(3).join(`:commit "${fx.c1}"`));
  try {
    await expect(move()).rejects.toThrow(/lean leg: the current receipt is at b+, not the :source-commit/);
  } finally {
    writeFileSync(file, before);
  }
});

// ── The claim pins ───────────────────────────────────────────────────────────

test('pin moves each row that pins the receipt to the commit that holds it, with its digest', async () => {
  const {repo} = fx;
  const {text} = await planMove({repo, evidence: evidenceFor(fx.c2, logFor(fx.files)), why: WHY, branch: 'main'});
  const row = (claim, extra = {}) => JSON.stringify({claim, id: `hyperpolymath/mathesis#${claim}`, receipt: {path: DEED, sha256: '0'.repeat(64)},
    repo: 'hyperpolymath/mathesis', source_commit: fx.c1, ...extra});
  const other = JSON.stringify({claim: 'X-1', id: 'o/r#X-1', receipt: null, repo: 'o/r', source_commit: fx.c1});
  put(repo, DEED, text);
  put(repo, CLAIMS, [row('T-1'), other].join('\n') + '\n');
  git(repo, 'add', '-A'); git(repo, 'commit', '-q', '-m', 'c3: the new receipt');
  const c3 = git(repo, 'rev-parse', 'HEAD');
  const p = await planPin({repo, at: c3, branch: 'main'});
  expect(p.digest).toBe(sha(text));
  expect(p.notOnMain).toBe(false);
  const [moved, kept] = p.text.trimEnd().split('\n');
  expect(JSON.parse(moved)).toMatchObject({source_commit: c3, receipt: {path: DEED, sha256: sha(text)}});
  expect(moved).toBe(jcs(JSON.parse(moved))); // I-JSON, serialised by JCS, as claims.jsonl is
  expect(kept).toBe(other); // a row of another receipt is left byte for byte
  put(repo, CLAIMS, [row('T-1'), row('T-9')].join('\n') + '\n');
  await expect(planPin({repo, at: c3, branch: 'main'})).rejects.toThrow(/has no claim T-9/);
  await expect(planPin({repo, at: fx.c1, branch: 'main'})).rejects.toThrow(/git show/); // c1 holds no receipt
});

test('the committed receipt of Mathesis is readable by the span reader, with one current receipt per leg', () => {
  const text = readFileSync(new URL(`../../${DEED}`, import.meta.url), 'utf8');
  const {legs} = currentReceipts(text);
  expect(legs.length).toBeGreaterThan(0);
  expect(new Set(legs.map(l => `${l.claim} ${l.prover}`)).size).toBe(legs.length);
});
