// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
import {test, expect} from 'bun:test';
import {mkdtemp, mkdir, writeFile, rm} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {derive, deriveAll} from '../../scripts/registry/claims-registry.mjs';
import {parseEngineeringReceipt} from '../../scripts/registry/engineering-receipt.mjs';
import {jcs} from '../../scripts/registry/theory-ledger.mjs';

const digest = s => createHash('sha256').update(s).digest('hex');
const carrier = 'a'.repeat(40), implementation = 'b'.repeat(40);
const evidence = 'Retained fixture evidence\n';
const ref = {path: 'evidence/run.log', sha256: digest(evidence)};
const fixture = () => ({profile: 'engineering-receipt', schema_version: '1.0.0',
  repository: 'o/r', source_commit: implementation, claim: 'D-1', kind: 'demonstration',
  statement: 'An explicitly scoped engineering demonstration.', status_doc: 'STATUS.adoc',
  source_inputs: {...ref}, evidence_manifest: {...ref},
  checks: [{name: 'implementation', checker: 'fixture-checker', invocation: 'check implementation', result: 'pass', evidence: {...ref}}],
  controls: [{name: 'mutation', checker: 'fixture-checker', invocation: 'check mutant', result: 'pass', expect: 'reject', evidence: {...ref}}],
  trusted_base: ['Compiler and runtime'], open_obligations: ['Implementation refinement unproved']});
const rowFor = text => ({id: 'o/r#D-1', repo: 'o/r', claim: 'D-1', kind: 'demonstration',
  statement: fixture().statement, status_doc: 'STATUS.adoc', agda: null, source_commit: carrier,
  receipt: {path: 'engineering.json', sha256: digest(text)}});
const noTheoremReader = () => { throw new Error('engineering evidence reached theorem reader'); };

async function withReceipt(text, action) {
  const dir = await mkdtemp(path.join(tmpdir(), 'engineering-receipt-'));
  const root = path.join(dir, `o__r@${carrier}`);
  try {
    await mkdir(path.join(root, 'evidence'), {recursive: true});
    await writeFile(path.join(root, 'engineering.json'), text);
    await writeFile(path.join(root, 'evidence/run.log'), evidence);
    return await action(dir, root);
  } finally { await rm(dir, {recursive: true, force: true}); }
}

test('actual registry dispatch validates engineering evidence and preserves distinct source/carrier', async () => {
  const text = jcs(fixture()) + '\n';
  await withReceipt(text, async dir => {
    const [d] = await deriveAll([rowFor(text)], dir, noTheoremReader);
    expect(d.pwg).toBe('ungraded');
    expect(d.evidence).toBe(implementation);
    expect(d.row.source_commit).toBe(carrier);
    expect(d.reasons.join()).toContain('not re-proved');
  });
});

test('arbitrary JSON fails registration; legacy deed refusal remains visible and ungraded', async () => {
  await withReceipt('{}\n', async dir => {
    await expect(deriveAll([rowFor('{}\n')], dir, noTheoremReader)).rejects.toThrow(/missing field/);
  });
  const legacy = derive({...rowFor('{}'), receipt: {path: 'old_praxis.deed', sha256: 'f'.repeat(64)}}, {refusal: 'invalid deed'});
  expect(legacy.pwg).toBe('ungraded');
  expect(legacy.reasons.join()).toContain('canon reader refuses the receipt: invalid deed');
});

for (const [name, mutate, message] of [
  ['wrong repository', r => {r.repository = 'o/other';}, /repo does not match/],
  ['wrong claim', r => {r.claim = 'D-2';}, /claim does not match/],
  ['changed statement', r => {r.statement = 'A different assertion.';}, /statement does not match/],
  ['changed status document', r => {r.status_doc = 'OTHER.adoc';}, /status_doc does not match/],
  ['missing implementation binding', r => {delete r.source_commit;}, /missing field/],
  ['abbreviated implementation', r => {r.source_commit = 'abc';}, /source commit/],
  ['zero implementation', r => {r.source_commit = '0'.repeat(40);}, /source commit/],
  ['failed execution', r => {r.checks[0].result = 'fail';}, /failed or unexecuted/],
  ['unrun control', r => {r.controls[0].result = 'not-run';}, /failed or unexecuted/],
  ['missing controls', r => {r.controls = [];}, /nonempty array/],
  ['accepting control', r => {r.controls[0].expect = 'accept';}, /expect rejection/],
  ['asserted grade', r => {r.grade = 'PWG-1';}, /unknown or missing/],
  ['nested grade', r => {r.checks[0].grade = 'PWG-1';}, /unknown or missing/],
  ['duplicate check name', r => {r.controls[0].name = r.checks[0].name;}, /duplicate/],
  ['evidence traversal', r => {r.controls[0].evidence.path = '../outside';}, /unsafe evidence path/],
  ['wrong evidence digest', r => {r.controls[0].evidence.sha256 = 'f'.repeat(64);}, /digest mismatch/],
]) test(`registry refuses ${name} even with a freshly matching receipt hash`, async () => {
  const r = fixture(); mutate(r); const text = jcs(r);
  await withReceipt(text, async dir => {
    await expect(deriveAll([rowFor(text)], dir, noTheoremReader)).rejects.toThrow(message);
  });
});

test('refuses absent evidence and theorem promotion through actual registry dispatch', async () => {
  const text = jcs(fixture());
  await withReceipt(text, async (dir, root) => {
    await expect(deriveAll([{...rowFor(text), kind: 'theorem', agda: {module: 'M', names: ['x']}}], dir, noTheoremReader))
      .rejects.toThrow(/cannot promote/);
    await rm(path.join(root, 'evidence/run.log'));
    await expect(deriveAll([rowFor(text)], dir, noTheoremReader)).rejects.toThrow(/ENOENT/);
  });
});

test('each cached receipt is checked against every referring row', async () => {
  const text = jcs(fixture());
  await withReceipt(text, async dir => {
    await expect(deriveAll([rowFor(text), {...rowFor(text), claim: 'D-2', id: 'o/r#D-2'}], dir, noTheoremReader))
      .rejects.toThrow(/claim does not match/);
  });
});

test('canonical form rejects duplicate keys, BOM, whitespace and invalid Unicode', () => {
  const text = jcs(fixture());
  for (const bad of ['\uFEFF' + text, ' ' + text, text.replace('{', '{"kind":"theorem",')])
    expect(() => parseEngineeringReceipt(bad)).toThrow();
  const r = fixture(); r.statement = '\uD800';
  expect(() => parseEngineeringReceipt(jcs(r))).toThrow(/invalid string/);
});
