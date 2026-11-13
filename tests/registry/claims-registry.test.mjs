// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
//
// Hermetic tests of the claims registry. The grades come from the canon reader
// (PROOF-POLICY §8.5.1), so the tests need it: set MATHESIS_STANDARDS to a
// checkout of metadatastician/standards at READER.commit. Without it they fail.
import {test, expect, beforeAll} from 'bun:test';
import {readFileSync, mkdtempSync, mkdirSync, writeFileSync, copyFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {validate, loadReader, derive, deriveAll, withGitCheck, findTool, render, READER} from '../../scripts/registry/claims-registry.mjs';
import {parseJsonl} from '../../scripts/atlas/census-atlas.mjs';

const rows = parseJsonl(readFileSync(new URL('../../docs/atlas/claims/claims.jsonl', import.meta.url), 'utf8'));
const inventory = parseJsonl(readFileSync(new URL('../../docs/atlas/census/repos.jsonl', import.meta.url), 'utf8'));

const commit = 'a'.repeat(40);
const theorem = {id: 'o/r#T-1', repo: 'o/r', claim: 'T-1', kind: 'theorem', statement: 'a statement of some length',
  status_doc: 'PROOF-STATUS.adoc', source_commit: commit, agda: {module: 'M', names: ['t']}, receipt: null};
const inv = [{full_name: 'o/r', visibility: 'public'}];

let readProofReceipt;
beforeAll(async () => { readProofReceipt = await loadReader(); });

// A receipt in the §8.5.1 shape (the proof-receipt profile of praxis-deed).
// `rocq` and `lean` are leg states, or null for no leg; `*At` is the commit of
// that leg's current receipt.
const fixture = ({repo = 'o/r', pwg = 'PWG-3', invocation = 'agda --safe --without-K --cubical-compatible M.agda',
  rocq = null, lean = null, rocqAt = commit, leanAt = commit} = {}) => {
  // Each current receipt lists its inputs (standards e5a39d7): one manifest line,
  // the digest of that manifest, and an empty axioms clause.
  const run = (prover, at, inv) => {
    const line = `${'c'.repeat(64)}  ${prover}/M\n`;
    const digest = createHash('sha256').update(line).digest('hex');
    return `      (receipt :run "ci" :commit "${at}" :checker "${prover}" :invocation "${inv}"\n` +
      `               :inputs-sha256 "${digest}" :state current (axioms)\n` +
      `               (inputs-manifest (file :path "${prover}/M" :sha256 "${'c'.repeat(64)}"))))\n`;
  };
  const leg = (prover, state, at) => state === null ? '' :
    `    (leg :prover ${prover} :route re-proved :token proven :state ${state}\n` + run(prover, at, `${prover} M`);
  return ';; SPDX-License-Identifier: CC-BY-SA-4.0\n(praxis-deed\n  :schema-version "1.0.0"\n' +
    `  :canonical-name "fixture-receipt"\n  :profile proof-receipt\n  :repository "${repo}"\n  :source-commit "${commit}"\n` +
    `  (claim :id "T-1" :pwg ${pwg} :foundation-diverse #f\n` +
    '    (leg :prover agda :route source :token proven :state AGDA-VERIFIED\n' + run('agda', commit, invocation) +
    leg('rocq', rocq, rocqAt) + leg('lean', lean, leanAt) + '))\n';
};
// Read a fixture as deriveAll does: {record} or {refusal}.
const read = text => {
  try { return {record: readProofReceipt(text, 'fixture_praxis.deed')}; } catch (e) { return {refusal: String(e)}; }
};

test('the committed registry validates against the census inventory', () => {
  expect(validate(rows, inventory).length).toBe(rows.length);
  expect(rows.every(r => !('pwg' in r) && !('grade' in r))).toBe(true); // grades are derived, never stored
});

test('validation fails closed', () => {
  expect(() => validate([theorem, theorem], inv)).toThrow(/Duplicate/);
  expect(() => validate([{...theorem, source_commit: 'abc'}], inv)).toThrow(/40 lowercase hex/);
  expect(() => validate([{...theorem, kind: 'machine-verified'}], inv)).toThrow(/Unknown kind/);
  expect(() => validate([{...theorem, agda: null}], inv)).toThrow(/Agda module/);
  expect(() => validate([{...theorem, id: 'o/r#X'}], inv)).toThrow(/repo#claim/);
  expect(() => validate([theorem], [{full_name: 'o/r', visibility: 'private'}])).toThrow(/Nonpublic/);
  expect(() => validate([{...theorem, receipt: {path: 'x', sha256: 'nope'}}], inv)).toThrow(/sha256/);
});

test('only the pinned reader is loaded', async () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'reader-'));
  mkdirSync(path.join(dir, path.dirname(READER.path)), {recursive: true});
  copyFileSync(path.join(process.env.MATHESIS_STANDARDS, READER.path), path.join(dir, READER.path));
  expect(typeof await loadReader(dir)).toBe('function');
  writeFileSync(path.join(dir, READER.path), readFileSync(path.join(dir, READER.path), 'utf8') + '\n// changed\n');
  await expect(loadReader(dir)).rejects.toThrow(/not the pinned canon reader/);
  await expect(loadReader('')).rejects.toThrow(/set MATHESIS_STANDARDS/);
});

test('the grade is the one the reader derives (§8.2)', () => {
  expect(derive(theorem, read(fixture())).pwg).toBe('PWG-3');
  expect(derive(theorem, read(fixture({pwg: 'PWG-2i', rocq: 'RECONCILED'}))).pwg).toBe('PWG-2i');
  // Both legs current, but one receipt names another commit: not PWG-1.
  const two = derive(theorem, read(fixture({pwg: 'PWG-2ii', rocq: 'RECONCILED', lean: 'RECONCILED', leanAt: 'b'.repeat(40)})));
  expect(two.pwg).toBe('PWG-2ii');
  expect(two.reasons.join()).toContain('the reader derives PWG-2ii');
  const one = derive(theorem, read(fixture({pwg: 'PWG-1', rocq: 'RECONCILED', lean: 'RECONCILED'})));
  expect(one).toEqual({pwg: 'PWG-1', reasons: [], evidence: commit});
});

test('a receipt the reader refuses is ungraded, with the reader\'s reason', () => {
  // A recorded grade the legs do not support (§8.4 drift).
  const drift = derive(theorem, read(fixture({pwg: 'PWG-2i'})));
  expect(drift.pwg).toBe('ungraded');
  expect(drift.reasons.join()).toMatch(/^the canon reader refuses the receipt: .*records :pwg PWG-2i, but its legs and receipts support PWG-3/);
  // The pre-§8 shape is not a proof receipt.
  const legacy = derive(theorem, read(';; SPDX-License-Identifier: CC-BY-SA-4.0\n(praxis-deed\n  :schema-version "1.0.0"\n  (claim :id "T-1" :token "proven" :grade "grade-3"))\n'));
  expect(legacy.pwg).toBe('ungraded');
  expect(legacy.reasons.join()).toContain('the canon reader refuses the receipt');
  // Without the canonical invocation the Agda leg does not count.
  const noFlag = derive(theorem, read(fixture({pwg: 'ungraded', invocation: 'agda --safe --without-K M.agda'})));
  expect(noFlag.pwg).toBe('ungraded');
});

test('each other reason a grade is withheld', () => {
  expect(derive(theorem, null).reasons.join()).toContain('no machine receipt');
  expect(derive({...theorem, claim: 'T-9'}, read(fixture())).reasons.join()).toContain('absent');
  expect(derive({...theorem, kind: 'demonstration'}, read(fixture())).pwg).toBe('ungraded');
  expect(derive(theorem, read(fixture({repo: 'o/other'}))).reasons.join()).toContain('for o/other, not o/r');
});

test('deriveAll reads each receipt once, and refuses a receipt that does not match its pinned digest', async () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'registry-'));
  const text = fixture();
  mkdirSync(path.join(dir, `o__r@${commit}`), {recursive: true});
  writeFileSync(path.join(dir, `o__r@${commit}`, 'r_praxis.deed'), text);
  const good = {...theorem, receipt: {path: 'r_praxis.deed', sha256: createHash('sha256').update(text).digest('hex')}};
  expect((await deriveAll([good], dir, readProofReceipt))[0].pwg).toBe('PWG-3');
  await expect(deriveAll([{...good, receipt: {path: 'r_praxis.deed', sha256: 'b'.repeat(64)}}], dir, readProofReceipt)).rejects.toThrow(/digest mismatch/);
});

test('the view is a census with its denominator, never a percentage, and is deterministic', () => {
  const ds = [{row: theorem, pwg: 'PWG-3', reasons: []},
              {row: {...theorem, id: 'o/r#T-2', claim: 'T-2'}, pwg: 'ungraded', reasons: ['x']}];
  const v = render(ds);
  expect(v).toContain('1 at `PWG-3`');
  expect(v).toContain('1 `ungraded`, of 2 theorems');
  expect(v).not.toMatch(/\d+(\.\d+)?\s*%/);
  expect(render([...ds].reverse())).toEqual(v);
});

test('a row names the commit that its receipt describes when it differs from the pin', () => {
  const at = 'c'.repeat(40);
  const v = render([{row: {...theorem, source_commit: at}, pwg: 'PWG-1', reasons: [], evidence: commit}]);
  expect(v).toContain(`at \`${at.slice(0, 12)}\`; the receipt describes \`${commit.slice(0, 12)}\``);
  expect(render([{row: theorem, pwg: 'PWG-1', reasons: [], evidence: commit}])).not.toContain('the receipt describes');
});

test('a PWG-1 is catalogued only when the git checks of §8.5.3 hold', async () => {
  const one = derive(theorem, read(fixture({pwg: 'PWG-1', rocq: 'RECONCILED', lean: 'RECONCILED'})));
  expect(withGitCheck(one, {ok: true})).toEqual(one);
  const capped = withGitCheck(one, {ok: false, reason: 'the source commit is not on origin/main'});
  expect(capped.pwg).toBe('PWG-2ii');
  expect(capped.reasons.join()).toContain('§8.5.3 git checks: the source commit is not on origin/main; catalogued without PWG-1');
  const three = derive(theorem, read(fixture()));
  expect(withGitCheck(three, {ok: false, reason: 'x'})).toEqual(three);
  // deriveAll runs the check once per receipt, and with no check it catalogues no PWG-1.
  const dir = mkdtempSync(path.join(tmpdir(), 'registry-'));
  const text = fixture({pwg: 'PWG-1', rocq: 'RECONCILED', lean: 'RECONCILED'});
  mkdirSync(path.join(dir, `o__r@${commit}`), {recursive: true});
  writeFileSync(path.join(dir, `o__r@${commit}`, 'r_praxis.deed'), text);
  const row = {...theorem, receipt: {path: 'r_praxis.deed', sha256: createHash('sha256').update(text).digest('hex')}};
  let calls = 0;
  const ok = async () => { calls += 1; return {ok: true}; };
  const both = await deriveAll([row, {...row, id: 'o/r#T-1b'}], dir, readProofReceipt, ok);
  expect(both.map(d => d.pwg)).toEqual(['PWG-1', 'PWG-1']);
  expect(calls).toBe(1);
  expect((await deriveAll([row], dir, readProofReceipt))[0].pwg).toBe('PWG-2ii');
});

test('git and bash run only from an absolute directory of PATH', () => {
  expect(path.isAbsolute(findTool('bash'))).toBe(true);
  expect(() => findTool('bash', {PATH: 'relative/bin'})).toThrow(/not found in an absolute directory/);
});
