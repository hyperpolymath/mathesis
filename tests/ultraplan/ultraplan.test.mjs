// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// The ultraplan generator: what it derives, and each thing it refuses.
import {test, expect, afterAll} from 'bun:test';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync, readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {generate, validate, derive, readSource, registryGrade, adrAccepted, context, ACTIVE_LIMIT, ROOT, VIEW, SVG}
  from '../../scripts/ultraplan/ultraplan.mjs';
import {jcs} from '../../scripts/registry/theory-ledger.mjs';

const roots = [];
afterAll(() => { for (const r of roots) rmSync(r, {recursive: true, force: true}); });

const ADVISORS = [
  {id: 'maths', name: 'Mathematician', glyph: '∑', asks: 'Is it true, and is it deep?', reads: 'maths'},
  {id: 'engineering', name: 'Engineer', glyph: '⚙', asks: 'Does it run, and can it be kept?', reads: 'engineering'},
  {id: 'contrarian', name: 'Contrarian', glyph: '🦉', asks: 'What if the opposite?'},
  {id: 'me', name: 'Me', glyph: '🫶', asks: 'Does it help the owner?', private: true},
];
const node = (id, extra = {}) => ({id, name: id, glyph: '🔷', track: 'maths', kind: 'theorem', status: 'open', size: 'M', summary: `The ${id} node.`, ...extra});
const BASE = [
  node('root', {status: 'done', evidence: [{path: 'README.adoc'}]}),
  node('tool', {track: 'engineering', kind: 'tool', status: 'done', needs: ['root'], evidence: [{adr: '0004'}]}),
  node('theorem', {needs: ['root'], value: {maths: 3}, counsel: {maths: 'The deep one.'}, owner_value: 'high'}),
  node('panel', {track: 'engineering', kind: 'view', needs: ['tool', 'theorem'], value: {engineering: 2}}),
  node('paper', {track: 'publications', kind: 'paper', needs: ['theorem'], value: {publications: 3}}),
  node('cheap', {needs: ['tool'], value: {engineering: 1}, size: 'S'}),
];

// A throwaway repository root with the files the evidence checks read.
function fixture({advisors = ADVISORS, nodes = BASE, expeditions = [], registry = '', raw = {}} = {}) {
  const root = mkdtempSync(path.join(tmpdir(), 'ultraplan-'));
  roots.push(root);
  mkdirSync(path.join(root, 'docs/ultraplan'), {recursive: true});
  mkdirSync(path.join(root, 'docs/decisions'), {recursive: true});
  mkdirSync(path.join(root, 'docs/atlas/generated'), {recursive: true});
  writeFileSync(path.join(root, 'README.adoc'), '= Fixture\n');
  writeFileSync(path.join(root, 'docs/decisions/0004-claims-registry.adoc'), '= ADR\n\n=== Status\n\n*Accepted (ratified).*\n');
  writeFileSync(path.join(root, 'docs/decisions/0005-jcs.adoc'), '= ADR\n\n=== Status\n\n*Proposed. Not accepted.*\n');
  writeFileSync(path.join(root, 'docs/atlas/generated/registry.adoc'), registry);
  const jl = rows => rows.map(r => jcs(r) + '\n').join('');
  writeFileSync(path.join(root, 'docs/ultraplan/advisors.jsonl'), raw.advisors ?? jl(advisors));
  writeFileSync(path.join(root, 'docs/ultraplan/tree.jsonl'), raw.nodes ?? jl(nodes));
  writeFileSync(path.join(root, 'docs/ultraplan/expeditions.jsonl'), raw.expeditions ?? jl(expeditions));
  return root;
}
const refuses = (opts, re) => expect(() => generate(fixture(opts))).toThrow(re);
// Replace fields of one node; a field set to undefined is removed.
const strip = o => Object.fromEntries(Object.entries(o).filter(([, v]) => v !== undefined));
const swap = (id, extra, nodes = BASE) => nodes.map(n => n.id === id ? strip({...n, ...extra}) : n);

test('derives eras, the frontier, forks, confluences and each advisor\'s pick', () => {
  const out = generate(fixture());
  const d = out.derived;
  expect([...d.depth.entries()].sort()).toEqual([['cheap', 2], ['panel', 2], ['paper', 2], ['root', 0], ['theorem', 1], ['tool', 1]]);
  expect(d.frontier.map(n => n.id).sort()).toEqual(['cheap', 'theorem']);
  expect(d.forks.map(n => n.id).sort()).toEqual(['root', 'theorem', 'tool']);   // each enables nodes on two tracks
  expect(d.confluences.map(n => n.id)).toEqual(['panel']);             // engineering + maths
  expect(d.leverage('root')).toBe(5);
  expect(d.picks.get('maths').id).toBe('theorem');
  expect(d.picks.get('engineering').id).toBe('cheap');
  expect(d.picks.get('contrarian').id).toBe('cheap');                  // rated lowest by the council
  expect(d.picks.get('me').id).toBe('theorem');                        // tagged owner_value, no notes
  expect(out[VIEW]).toContain('== Research now: the frontier');
  expect(out[VIEW]).toContain('_Pick:_ <<theorem,🔷 theorem>>. The deep one.');
  expect(out[SVG].startsWith('<svg xmlns="http://www.w3.org/2000/svg"')).toBe(true);
});

test('the views are deterministic', () => {
  const a = generate(fixture()), b = generate(fixture());
  expect(a[VIEW]).toBe(b[VIEW]);
  expect(a[SVG]).toBe(b[SVG]);
});

test('done needs evidence that holds', () => {
  refuses({nodes: swap('root', {evidence: []})}, /node root: done needs evidence/);
  refuses({nodes: swap('root', {evidence: [{path: 'NOPE.adoc'}]})}, /evidence path NOPE.adoc does not exist/);
  refuses({nodes: swap('root', {evidence: [{path: '../etc/passwd'}]})}, /is not a repository path/);
  refuses({nodes: swap('tool', {evidence: [{adr: '0005'}]})}, /ADR 0005 is not Accepted/);
  refuses({nodes: swap('tool', {evidence: [{adr: '0009'}]})}, /no ADR 0009/);
  refuses({nodes: swap('root', {evidence: [{path: 'README.adoc', adr: '0004'}]})}, /exactly one of path, claim or adr/);
});

test('a claim is evidence only at the grade the registry derives', () => {
  const registry = '|https://x/blob/c/P.adoc[o/r#T-1] at `c` |theorem |`PWG-2i` |text |why\n';
  const ok = swap('root', {evidence: [{claim: 'o/r#T-1', min_pwg: 'PWG-2i'}]});
  expect(() => generate(fixture({nodes: ok, registry}))).not.toThrow();
  refuses({nodes: swap('root', {evidence: [{claim: 'o/r#T-1', min_pwg: 'PWG-2ii'}]}), registry}, /o\/r#T-1 derives PWG-2i, below PWG-2ii/);
  refuses({nodes: swap('root', {evidence: [{claim: 'o/r#T-9'}]}), registry}, /does not list o\/r#T-9/);
});

test('a done node cannot rest on an unfinished need', () => {
  refuses({nodes: swap('cheap', {status: 'done', evidence: [{path: 'README.adoc'}], needs: ['theorem']})}, /node cheap: done, but its need theorem is not done/);
});

test('the needs form a DAG over known nodes', () => {
  refuses({nodes: swap('tool', {status: 'open', evidence: undefined}, swap('root', {status: 'open', evidence: undefined, needs: ['paper']}))}, /cycle/);
  refuses({nodes: swap('theorem', {needs: ['root', 'ghost']})}, /needs names unknown node ghost/);
  refuses({nodes: swap('theorem', {needs: ['root', 'root']})}, /needs names root twice/);
});

test('rivals name each other back', () => {
  refuses({nodes: swap('paper', {rivals: ['cheap']})}, /rival cheap does not name paper back/);
  const both = BASE.map(n => n.id === 'paper' ? {...n, rivals: ['cheap']} : n.id === 'cheap' ? {...n, rivals: ['paper']} : n);
  expect(generate(fixture({nodes: both})).derived.rivalries).toEqual([['cheap', 'paper']]);
});

test('the me advisor writes nothing into the public tree', () => {
  refuses({nodes: swap('theorem', {counsel: {me: 'personal note'}})}, /counsel\.me is refused/);
  refuses({nodes: swap('theorem', {owner_value: 'medium'})}, /owner_value is "high" or absent/);
});

test(`at most ${ACTIVE_LIMIT} nodes are active`, () => {
  const busy = BASE.map(n => ['theorem', 'paper', 'cheap', 'panel'].includes(n.id) ? {...n, status: 'active'} : n);
  refuses({nodes: busy}, new RegExp(`4 nodes are active .* at most ${ACTIVE_LIMIT}`));
});

test('closed schema, blocked reasons and canonical lines', () => {
  refuses({nodes: swap('paper', {colour: 'red'})}, /node paper: unknown field "colour"/);
  refuses({nodes: swap('paper', {status: 'blocked'})}, /says what blocks it/);
  refuses({nodes: swap('paper', {track: 'poetry'})}, /track must be one of/);
  refuses({nodes: swap('paper', {value: {maths: 4}})}, /value\.maths must be 0, 1, 2 or 3/);
  refuses({nodes: swap('paper', {where: 'elsewhere'})}, /where is estate:OWNER\/REPO/);
  refuses({raw: {nodes: BASE.map(n => JSON.stringify(n, null, 0)).join('\n') + '\n'}}, /not in JCS form/);
});

test('return tickets are grafted or archived honestly', () => {
  const x = {id: 'X-001', what: 'A trip', why: 'Because', size: 'S', date: '2026-11-24', status: 'out'};
  expect(() => generate(fixture({expeditions: [x]}))).not.toThrow();
  refuses({expeditions: [{...x, status: 'grafted', graft: 'ghost'}]}, /names the node it became/);
  refuses({expeditions: [{...x, status: 'archived'}]}, /records what it taught/);
  refuses({expeditions: [x, {...x}]}, /id is X-NNN and unique/);
});

test('the evidence parsers read the real registry view and ADRs', () => {
  const ctx = context(ROOT);
  expect(registryGrade(ctx.registry, 'hyperpolymath/mathesis#THY-1')).toMatch(/^PWG-/);
  expect(adrAccepted(ctx.read(ctx.adrFile('0004')))).toBe(true);
  expect(adrAccepted(ctx.read(ctx.adrFile('0005')))).toBe(false);
});

test('the committed views match the committed data', () => {
  const out = generate(ROOT);
  expect(readFileSync(path.join(ROOT, VIEW), 'utf8')).toBe(out[VIEW]);
  expect(readFileSync(path.join(ROOT, SVG), 'utf8')).toBe(out[SVG]);
});
