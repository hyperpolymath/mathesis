// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell
// Engineering demonstrations have no theorem legs or PWG grade. This reader
// validates their identity, declared source binding and retained evidence, not
// the truth of an execution log or compiler correctness. See ADR 0006.
import {jcs} from './theory-ledger.mjs';
import {isGitHubRepo} from '../repo/github.mjs';

const need = (ok, message) => { if (!ok) throw new Error(`engineering receipt: ${message}`); };
const object = (v, fields) => {
  need(v !== null && typeof v === 'object' && !Array.isArray(v), 'expected object');
  need(Object.keys(v).length === fields.length && fields.every(k => Object.hasOwn(v, k)), 'unknown or missing field');
};
const string = v => {
  need(typeof v === 'string' && v.length > 0 &&
    !/[\u0000-\u001f\u007f\uD800-\uDFFF\uFDD0-\uFDEF]/u.test(v), 'invalid string');
  for (const c of v) need((c.codePointAt(0) & 0xffff) < 0xfffe, 'invalid string');
};
const list = (v, check) => {
  need(Array.isArray(v) && v.length > 0, 'expected nonempty array');
  v.forEach(check);
};
const file = v => {
  object(v, ['path', 'sha256']);
  string(v.path);
  need(/^[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.-]+)*$/.test(v.path) &&
    v.path.split('/').every(p => p !== '.' && p !== '..'), 'unsafe evidence path');
  need(/^[a-f0-9]{64}$/.test(v.sha256), 'invalid evidence digest');
};

export function parseEngineeringReceipt(text) {
  need(typeof text === 'string' && text.length <= 1_000_000, 'invalid text size');
  let r;
  try { r = JSON.parse(text); } catch { throw new Error('engineering receipt: invalid JSON'); }
  need(text === jcs(r) || text === jcs(r) + '\n', 'not canonical JCS (duplicate keys and alternate encodings refused)');
  object(r, ['profile', 'schema_version', 'repository', 'source_commit', 'claim', 'kind',
    'statement', 'status_doc', 'source_inputs', 'evidence_manifest', 'checks', 'controls',
    'trusted_base', 'open_obligations']);
  need(r.profile === 'engineering-receipt' && r.schema_version === '1.0.0', 'unsupported profile/version');
  need(r.kind === 'demonstration', 'engineering evidence is only a demonstration');
  for (const k of ['repository', 'source_commit', 'claim', 'statement', 'status_doc']) string(r[k]);
  need(isGitHubRepo(r.repository), 'invalid repository');
  need(/^[a-f0-9]{40}$/.test(r.source_commit) && !/^0+$/.test(r.source_commit), 'invalid implementation source commit');
  file(r.source_inputs);
  file(r.evidence_manifest);
  const names = new Set();
  const check = (c, control) => {
    object(c, ['name', 'checker', 'invocation', 'result', 'evidence', ...(control ? ['expect'] : [])]);
    for (const k of ['name', 'checker', 'invocation']) string(c[k]);
    need(!names.has(c.name), 'duplicate check/control name');
    names.add(c.name);
    need(c.result === 'pass', 'failed or unexecuted check/control');
    if (control) need(c.expect === 'reject', 'negative control must expect rejection');
    file(c.evidence);
  };
  list(r.checks, c => check(c, false));
  list(r.controls, c => check(c, true));
  list(r.trusted_base, string);
  list(r.open_obligations, string);
  return r;
}

export async function readEngineeringReceipt(text, loadFile) {
  const r = parseEngineeringReceipt(text);
  // loadFile verifies each reference's SHA-256 at the SAME pinned carrier.
  // Source-manifest correspondence is recorded by the producer, not re-proved
  // here. No grade or successful execution is inferred merely from these hashes.
  const refs = [r.source_inputs, r.evidence_manifest, ...r.checks.map(c => c.evidence),
    ...r.controls.map(c => c.evidence)];
  for (const ref of refs) await loadFile(ref);
  return r;
}

export function deriveEngineering(row, r) {
  need(row.kind === 'demonstration' && row.agda == null, 'cannot promote engineering evidence to a theorem');
  for (const [field, source] of [['repo', 'repository'], ['claim', 'claim'], ['statement', 'statement'], ['status_doc', 'status_doc']])
    need(row[field] === r[source], `${field} does not match the receipt`);
  return {pwg: 'ungraded', evidence: r.source_commit,
    reasons: ['demonstration, not a theorem (§8.1)', 'engineering identity, declared source binding and evidence digests checked; execution and source correspondence not re-proved']};
}
