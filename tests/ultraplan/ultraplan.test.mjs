// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// The ultraplan generator: what it derives, and each thing it refuses.
import {test, expect, afterAll} from 'bun:test';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync, readFileSync, symlinkSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {generate, validate, derive, readSource, registryGrade, adrAccepted, context, ACTIVE_LIMIT, ROOT, VIEW, SVG, RULES}
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
  expect(out[SVG]).toContain('<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->');
  // Three eras are narrower than the legend; the canvas still holds the legend.
  expect(Number(/width="(\d+)"/.exec(out[SVG])[1])).toBeGreaterThanOrEqual(24 + 6 * 128 + 260);
  // Every edge (six in the fixture) ends in an arrowhead, gold where it leads to the frontier.
  const edges = out[SVG].match(/<path d="M[^"]*" fill="none"[^>]*\/>/g);
  expect(edges.length).toBe(6);
  expect(edges.every(e => /marker-end="url\(#arrow(-hot)?\)"/.test(e))).toBe(true);
  expect(out[SVG]).toContain('<marker id="arrow"');
  expect(out[SVG]).toContain('<marker id="arrow-hot"');
});

test('the views are deterministic', () => {
  const a = generate(fixture()), b = generate(fixture());
  expect(a[VIEW]).toBe(b[VIEW]);
  expect(a[SVG]).toBe(b[SVG]);
});

test('done needs evidence that holds', () => {
  refuses({nodes: swap('root', {evidence: []})}, /node root: done needs evidence/);
  refuses({nodes: swap('root', {evidence: [{path: 'NOPE.adoc'}]})}, /evidence path NOPE.adoc is not a file in the repository/);
  refuses({nodes: swap('root', {evidence: [{path: '../etc/passwd'}]})}, /is not a repository path/);
  refuses({nodes: swap('root', {evidence: [{path: '.'}]})}, /evidence path \. is not a file in the repository/);
  refuses({nodes: swap('root', {evidence: [{path: 'docs/decisions'}]})}, /evidence path docs\/decisions is not a file/);
  // A committed symlink to a file outside the repository is not evidence in it.
  const outside = mkdtempSync(path.join(tmpdir(), 'ultraplan-outside-'));
  roots.push(outside);
  writeFileSync(path.join(outside, 'secret.txt'), 'x\n');
  const root = fixture({nodes: swap('root', {evidence: [{path: 'link.txt'}]})});
  symlinkSync(path.join(outside, 'secret.txt'), path.join(root, 'link.txt'));
  expect(() => generate(root)).toThrow(/evidence path link.txt is not a file in the repository/);
  const inside = fixture({nodes: swap('root', {evidence: [{path: 'inner.adoc'}]})});
  symlinkSync('README.adoc', path.join(inside, 'inner.adoc'));
  expect(() => generate(inside)).not.toThrow();
  // An ADR that is a symlink to an accepted record outside the repository is not one in it.
  writeFileSync(path.join(outside, 'accepted.adoc'), '= ADR\n\n=== Status\n\n*Accepted.*\n');
  const adr = fixture({nodes: swap('tool', {evidence: [{adr: '0007'}]})});
  symlinkSync(path.join(outside, 'accepted.adoc'), path.join(adr, 'docs/decisions/0007-outside.adoc'));
  expect(() => generate(adr)).toThrow(/ADR 0007 \(docs\/decisions\/0007-outside\.adoc\) is not a file in the repository/);
  // The context reads no file outside the repository, whoever asks.
  expect(() => context(adr).read('docs/decisions/0007-outside.adoc')).toThrow(/is not a file in the repository/);
  expect(context(adr).read('README.adoc')).toBe('= Fixture\n');
  // The registry view is evidence too: one that leads outside the repository is refused.
  writeFileSync(path.join(outside, 'registry.adoc'), '|https://x/blob/c/P.adoc[o/r#T-1] at `c` |theorem |`PWG-1` |s |w\n');
  const reg = fixture({nodes: swap('root', {evidence: [{claim: 'o/r#T-1'}]})});
  rmSync(path.join(reg, 'docs/atlas/generated/registry.adoc'));
  symlinkSync(path.join(outside, 'registry.adoc'), path.join(reg, 'docs/atlas/generated/registry.adoc'));
  expect(() => generate(reg)).toThrow(/docs\/atlas\/generated\/registry\.adoc is not a file in the repository/);
  refuses({nodes: swap('tool', {evidence: [{adr: '0005'}]})}, /ADR 0005 is not Accepted/);
  refuses({nodes: swap('tool', {evidence: [{adr: '0009'}]})}, /no ADR 0009/);
  refuses({nodes: swap('root', {evidence: [{path: 'README.adoc', adr: '0004'}]})}, /exactly one of path, claim or adr/);
  refuses({nodes: swap('root', {evidence: [{path: 'README.adoc', min_pwg: 'PWG-1'}]})}, /min_pwg belongs to claim evidence only/);
  refuses({nodes: swap('tool', {evidence: [{adr: '0004', min_pwg: 'PWG-1'}]})}, /min_pwg belongs to claim evidence only/);
});

test('a claim is evidence only at the grade the registry derives', () => {
  const registry = '|https://x/blob/c/P.adoc[o/r#T-1] at `c` |theorem |`PWG-2i` |text |why\n';
  const ok = swap('root', {evidence: [{claim: 'o/r#T-1', min_pwg: 'PWG-2i'}]});
  expect(() => generate(fixture({nodes: ok, registry}))).not.toThrow();
  refuses({nodes: swap('root', {evidence: [{claim: 'o/r#T-1', min_pwg: 'PWG-2ii'}]}), registry}, /o\/r#T-1 derives PWG-2i, below PWG-2ii/);
  refuses({nodes: swap('root', {evidence: [{claim: 'o/r#T-9'}]}), registry}, /does not list o\/r#T-9/);
  // An id mentioned inside another row's statement does not list that claim.
  const mention = '|https://x/blob/c/P.adoc[o/r#T-1] at `c` |theorem |`PWG-2ii` |Builds on [o/r#GHOST-1] |why\n';
  refuses({nodes: swap('root', {evidence: [{claim: 'o/r#GHOST-1'}]}), registry: mention}, /does not list o\/r#GHOST-1/);
});

test('a done or active node cannot rest on an unfinished need', () => {
  refuses({nodes: swap('cheap', {status: 'done', evidence: [{path: 'README.adoc'}], needs: ['theorem']})}, /node cheap: done, but its need theorem is not done/);
  refuses({nodes: swap('panel', {status: 'active'})}, /node panel: active, but its need theorem is not done/);
  expect(() => generate(fixture({nodes: swap('cheap', {status: 'active'})}))).not.toThrow();
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

test('the council is well formed', () => {
  refuses({advisors: ADVISORS.filter(a => a.id !== 'me')}, /the me advisor is required/);
  refuses({advisors: ADVISORS.map(a => a.id === 'maths' ? {id: a.id, name: a.name, glyph: a.glyph, asks: a.asks} : a)}, /advisor maths: reads is required/);
  refuses({advisors: ADVISORS.map(a => a.id === 'contrarian' ? {...a, reads: 'maths'} : a)}, /advisor contrarian: reads no value mark/);
});

test('exactly the me advisor is private', () => {
  refuses({advisors: ADVISORS.map(a => a.id === 'me' ? {...a, private: undefined} : a).map(a => JSON.parse(JSON.stringify(a)))}, /advisor me: must be private/);
  refuses({advisors: ADVISORS.map(a => a.id === 'maths' ? {...a, private: true} : a)}, /advisor maths: only the me advisor is private/);
});

test('the me advisor writes nothing into the public tree', () => {
  refuses({nodes: swap('theorem', {counsel: {me: 'personal note'}})}, /counsel\.me is refused/);
  refuses({nodes: swap('theorem', {owner_value: 'medium'})}, /owner_value is "high" or absent/);
});

test('evidence on an active node must hold too', () => {
  refuses({nodes: swap('theorem', {status: 'active', evidence: [{}]})}, /exactly one of path, claim or adr/);
  refuses({nodes: swap('theorem', {status: 'active', evidence: [{path: 'NOPE.adoc'}]})}, /is not a file in the repository/);
  expect(() => generate(fixture({nodes: swap('theorem', {status: 'active', evidence: [{path: 'README.adoc'}]})}))).not.toThrow();
  refuses({nodes: swap('paper', {evidence: [{path: 'README.adoc'}]})}, /evidence belongs to a done or active node/);
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
  // A list holding a valid place is not a place (a regular expression would read it as one).
  refuses({nodes: swap('paper', {where: ['estate:o/r']})}, /where is estate:OWNER\/REPO/);
  // A list field that is not a list is refused by name, not by a crash.
  refuses({nodes: swap('paper', {needs: {}})}, /node paper: needs must be a list/);
  refuses({nodes: swap('paper', {rivals: 'cheap'})}, /node paper: rivals must be a list/);
  refuses({nodes: swap('paper', {size: 'toString'})}, /size must be one of S, M, L, XL/);
  refuses({nodes: swap('paper', {size: 'constructor'})}, /size must be one of/);
  refuses({raw: {nodes: BASE.map(n => JSON.stringify(n, null, 0)).join('\n') + '\n'}}, /not in JCS form/);
  // A lone surrogate survives JSON.parse and JSON.stringify alike; I-JSON refuses it.
  const lone = jcs({...BASE[0], name: 'x'}).replace('"name":"x"', '"name":"\\ud800"');
  refuses({raw: {nodes: [lone, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}, /line 1 holds a lone surrogate/);
  const pair = jcs({...BASE[0], name: 'x \u{1F600}'});
  expect(() => generate(fixture({raw: {nodes: [pair, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}))).not.toThrow();
  // I-JSON refuses Unicode noncharacters too: U+FDD0 to U+FDEF and the last two code points of each plane.
  for (const nc of ['\uFFFE', '\uFDD0', '\u{1FFFF}', '\u{10FFFE}']) {
    const line = jcs({...BASE[0], name: `x${nc}y`});
    refuses({raw: {nodes: [line, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}, /line 1 holds a lone surrogate or a Unicode noncharacter/);
  }
  const key = jcs({...BASE[0], value: {maths: 1}}).replace('"maths"', '"m\uFFFEaths"');
  refuses({raw: {nodes: [key, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}, /line 1 holds a lone surrogate or a Unicode noncharacter/);
});

// Every rule in the generator's rule tables has a witness: a change to the sound
// fixture that breaks the rule and is refused with its message. A rule with no
// witness fails this test, so no rule can be vacuous, and none can be added
// without a test.
test('every rule has a witness', () => {
  const ctx = context(fixture());
  const on = (rows, id, extra) => rows.map(r => r.id === id ? strip({...r, ...extra}) : r);
  const A = (id, extra) => ({advisors: on(ADVISORS, id, extra)});
  const N = (id, extra) => ({nodes: on(BASE, id, extra)});
  const T = extra => ({expeditions: [strip({id: 'X-001', what: 'A trip', why: 'Because', size: 'S', date: '2026-11-24', status: 'out', ...extra})]});
  const witnesses = [
    A('maths', {name: ''}), A('maths', {glyph: undefined}), A('maths', {asks: ' padded'}),
    A('maths', {reads: 'poetry'}), A('me', {private: false}), A('maths', {private: true}),
    A('contrarian', {reads: 'maths'}), A('engineering', {reads: undefined}),
    N('paper', {name: 'x'.repeat(81)}), N('paper', {glyph: ''}), N('paper', {track: 'poetry'}),
    N('paper', {kind: 'novel'}), N('paper', {status: 'finished'}), N('paper', {size: 'XXL'}),
    N('paper', {summary: undefined}), N('paper', {needs: 'theorem'}), N('paper', {rivals: {}}),
    N('root', {evidence: 'README.adoc'}), N('paper', {refs: 'see'}), N('paper', {where: ['estate:o/r']}),
    N('paper', {owner_value: 'low'}), N('paper', {status: 'blocked'}), N('paper', {blocked_by: 'the owner'}),
    N('paper', {refs: ['']}),
    T({what: ''}), T({why: undefined}), T({size: 'toString'}), T({date: '2026-02-30'}), T({status: 'lost'}),
    T({status: 'grafted', graft: 'ghost'}), T({graft: 'paper'}), T({status: 'archived'}), T({lesson: 'It taught.'}),
  ];
  // Within a table each message names one rule, so (table, message) is the rule's identity.
  for (const rules of Object.values(RULES)) expect(new Set(rules.map(([, m]) => m)).size).toBe(rules.length);
  const seen = new Set();
  for (const w of witnesses) {
    let refusal = '';
    try { validate({advisors: ADVISORS, nodes: BASE, expeditions: [], ...w}, ctx); } catch (e) { refusal = e.message; }
    expect(refusal).not.toBe('');
    for (const line of refusal.split('\n')) {
      const m = /^(advisor|node|expedition) [^\s:]+: (.*)$/.exec(line);
      if (m) seen.add(`${m[1]}: ${m[2]}`);
    }
  }
  const unwitnessed = Object.entries(RULES).flatMap(([kind, rules]) => rules.map(([, m]) => `${kind}: ${m}`).filter(id => !seen.has(id)));
  expect(unwitnessed).toEqual([]);
});

test('the me advisor ranks the owner\'s tags as the council does, not by another advisor\'s mark', () => {
  // cheap carries the higher maths mark; theorem unlocks two nodes and cheap none.
  const nodes = swap('cheap', {owner_value: 'high', value: {maths: 3}}, swap('theorem', {value: {maths: 1}}));
  expect(generate(fixture({nodes})).derived.picks.get('me').id).toBe('theorem');
});

test('when every active slot is taken, the frontier is ready but cannot start', () => {
  const open = generate(fixture());
  expect(open.derived.slots).toBe(ACTIVE_LIMIT);
  expect(open[VIEW]).toContain('can be started now.');
  expect(open[VIEW]).not.toContain('active slots are full');
  expect(open[SVG]).toContain('gold border: start it now');
  // theorem and cheap are ready; with a third started node, every slot is taken and spare waits.
  const nodes = [...swap('cheap', {status: 'active'}, swap('theorem', {status: 'active'})),
    node('extra', {needs: ['root'], status: 'active'}), node('spare', {needs: ['root']})];
  const full = generate(fixture({nodes}));
  expect(full.derived.slots).toBe(0);
  expect(full.derived.frontier.map(n => n.id)).toEqual(['spare']);
  expect(full[VIEW]).toContain(`1 are ready, but all ${ACTIVE_LIMIT} active slots are full.`);
  expect(full[VIEW]).toContain(`*All ${ACTIVE_LIMIT} active slots are full.* These nodes are ready`);
  expect(full[VIEW]).toContain('A gold border marks a node\nthat is ready, once an active slot is free.');
  expect(full[SVG]).toContain('gold border: ready, once an active slot is free');
});

test('ids are slugs and unique, and counsel comes from the council', () => {
  refuses({nodes: swap('paper', {id: 'Paper X'})}, /id must be a lowercase slug/);
  refuses({nodes: swap('paper', {id: '13-week'})}, /node 13-week: id must be a lowercase slug that begins with a letter/);
  refuses({advisors: [...ADVISORS, {id: '2nd', name: 'Second', glyph: '2', asks: 'Again?', reads: 'maths'}]}, /advisor id "2nd" is missing, not a slug, or repeated/);
  refuses({nodes: [...BASE, BASE[4]]}, /node paper: repeated id/);
  refuses({advisors: [...ADVISORS, ADVISORS[0]]}, /advisor id "maths" is missing, not a slug, or repeated/);
  refuses({nodes: swap('paper', {rivals: ['paper']})}, /node paper: rivals names itself/);
  refuses({nodes: swap('theorem', {counsel: {ghost: 'Hm.'}})}, /counsel from unknown advisor ghost/);
  refuses({nodes: swap('theorem', {counsel: {maths: ''}})}, /counsel\.maths must be a short text/);
});

test('return tickets are grafted or archived honestly', () => {
  const x = {id: 'X-001', what: 'A trip', why: 'Because', size: 'S', date: '2026-11-24', status: 'out'};
  expect(generate(fixture({expeditions: [x]}))[VIEW]).toContain('|X-001 |2026-11-24 |S |A trip |Because |🎒 out');
  refuses({expeditions: [{...x, status: 'grafted', graft: 'ghost'}]}, /names the node it became/);
  refuses({expeditions: [{...x, status: 'archived'}]}, /records what it taught/);
  refuses({expeditions: [x, {...x}]}, /id is X-NNN and unique/);
  refuses({expeditions: [{...x, date: '2026-02-30'}]}, /date is a real calendar date/);
  refuses({expeditions: [{...x, date: '2026-99-99'}]}, /date is a real calendar date/);
  expect(() => generate(fixture({expeditions: [{...x, date: '2028-02-29'}]}))).not.toThrow();
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
