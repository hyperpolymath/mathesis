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
  expect(d.picks.get('me')).toBe(null);                                // no public pick (owner ruling 2026-11-24)
  expect(d.ownerTagged.map(n => n.id)).toEqual(['theorem']);            // tagged owner_value, no notes
  expect(out[VIEW]).toContain('== Research now: the frontier');
  expect(out[VIEW]).toContain('_Pick:_ xref:theorem[🔷 theorem]. The deep one.');
  expect(out[VIEW]).toContain('_No public pick:_ the owner chooses in a private GELS panel. Tagged on the frontier, in id order: xref:theorem[🔷 theorem].');
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

test('a link to a node holds any name', () => {
  // `<<id,text>>` ends at ">>"; the xref macro's text ends at "]", turns into attributes at "=",
  // and a table cell ends at "|". Those three are character references, so the link text is the name.
  const page = generate(fixture({nodes: swap('theorem', {name: 'a >> b = c ] d | e'})}))[VIEW];
  expect(page).toContain('xref:theorem[🔷 a >> b &#61; c &#93; d &#124; e]');
  expect(page).not.toContain('<<theorem,');
});

test('every value mark is shown, a 0 included', () => {
  const page = generate(fixture({nodes: swap('paper', {value: {maths: 0, publications: 3}})}))[VIEW];
  expect(page).toContain('*Value (judgement):* maths ○, publications ●●●');
  const zero = generate(fixture({nodes: swap('paper', {value: {maths: 0}})}))[VIEW];
  expect(zero).toContain('*Value (judgement):* maths ○');
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
  // Two records with one number are refused, not picked between by directory order.
  const twin = fixture();
  writeFileSync(path.join(twin, 'docs/decisions/0004-second.adoc'), '= ADR\n\n=== Status\n\n*Proposed.*\n');
  expect(() => generate(twin)).toThrow(/ADR 0004 is ambiguous: docs\/decisions\/0004-claims-registry\.adoc, docs\/decisions\/0004-second\.adoc share the number/);
  // Only the boilerplate NNNN-template.adoc is set aside: a record whose title says template counts,
  // and a template that shares a number with a record does not make it ambiguous.
  const titled = fixture({nodes: swap('tool', {evidence: [{adr: '0006'}]})});
  writeFileSync(path.join(titled, 'docs/decisions/0006-template-inheritance.adoc'), '= ADR\n\n=== Status\n\n*Accepted.*\n');
  expect(() => generate(titled)).not.toThrow();
  const boiler = fixture();
  writeFileSync(path.join(boiler, 'docs/decisions/0004-template.adoc'), '= Template\n\n=== Status\n\nProposed\n');
  expect(() => generate(boiler)).not.toThrow();
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
  // Any id the registry accepts can be cited, and only those: its rule is shared.
  const odd = '|https://x/blob/c/P.adoc[o/r#N-7.1] at `c` |theorem |`PWG-2i` |s |w\n|https://x/blob/c/P.adoc[o/r#THY-1-A] at `c` |theorem |`PWG-3` |s |w\n';
  expect(() => generate(fixture({nodes: swap('root', {evidence: [{claim: 'o/r#N-7.1'}, {claim: 'o/r#THY-1-A'}]}), registry: odd}))).not.toThrow();
  refuses({nodes: swap('root', {evidence: [{claim: 'o/r#'}]}), registry: odd}, /evidence claim "o\/r#" is not OWNER\/REPO#ID/);
  refuses({nodes: swap('root', {evidence: [{claim: 'or#N-1'}]}), registry: odd}, /evidence claim "or#N-1" is not OWNER\/REPO#ID/);
  refuses({nodes: swap('root', {evidence: [{claim: 'o/r#A]B'}]}), registry: odd}, /evidence claim "o\/r#A\]B" is not OWNER\/REPO#ID/);
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
  const key = jcs({...BASE[0], value: {maths: 1}}).replace('"maths":', '"m\uFFFEaths":');
  refuses({raw: {nodes: [key, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}, /line 1 holds a lone surrogate or a Unicode noncharacter/);
  // Each text is one line: a line break would let a text start a line of the page.
  for (const cc of ['\n', '\r', '\t', '\u0000', '\u007f', '\u0085']) {
    const line = jcs({...BASE[0], summary: `x${cc}|===`});
    refuses({raw: {nodes: [line, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}, /line 1 holds a control character; each text in the plan is one line/);
  }
  const ckey = jcs({...BASE[0], value: {maths: 1}}).replace('"maths":', '"m\\naths":');
  refuses({raw: {nodes: [ckey, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}, /line 1 holds a control character/);
});

// Asciidoctor 2.0.26 reads a line that holds "::", ":::", "::::" or ";;" before a
// blank or the end as a description-list term, wherever the marker sits, and a
// prefix such as {empty} does not stop it. So no text in the plan may hold one.
test('a description-list marker in any text is refused', () => {
  const withRoot = extra => [jcs({...BASE[0], ...extra}), ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n';
  for (const s of ['The lock:: and more', 'The lock;; and more', 'The lock::', ':: at the start', 'a ::: b', 'a:::: b'])
    refuses({raw: {nodes: withRoot({summary: s})}}, /line 1 holds a description-list marker/);
  refuses({raw: {nodes: withRoot({counsel: {maths: 'Deep;; really'}})}}, /line 1 holds a description-list marker/);
  refuses({raw: {nodes: withRoot({refs: [{at: 'Fixture::', path: 'README.adoc'}]})}}, /line 1 holds a description-list marker/);
  const mkey = jcs({...BASE[0], value: {maths: 1}}).replace('"maths":', '"m:: aths":');
  refuses({raw: {nodes: [mkey, ...BASE.slice(1).map(n => jcs(n))].join('\n') + '\n'}}, /line 1 holds a description-list marker/);
  // "::" with no blank after it marks nothing: a macro name or a URL stays text.
  for (const s of ['image::x.svg[]', 'a::b', 'See https://example.org/a::b'])
    expect(() => generate(fixture({nodes: swap('cheap', {summary: s})}))).not.toThrow();
});

test('a ref points at one place, and each ref in this repository is checked', () => {
  const page = refs => generate(fixture({nodes: swap('paper', {refs})}))[VIEW];
  const refused = (refs, re) => refuses({nodes: swap('paper', {refs})}, re);
  // A file or a directory, and a quote that occurs in its file exactly once.
  const shown = page([{path: 'README.adoc'}, {path: 'docs/decisions'}, {at: '= Fixture', path: 'README.adoc'},
    {issue: 'metadatastician/standards#1705'},
    {at: '== 5. Status vocabulary', commit: 'a'.repeat(40), path: '3-practice/PROOF-POLICY.adoc', repo: 'metadatastician/standards'}]);
  expect(shown).toContain('*See:* `README.adoc`; `docs/decisions`; `README.adoc`, at `+= Fixture+`; '
    + 'https://github.com/metadatastician/standards/issues/1705[metadatastician/standards#1705]; '
    + `https://github.com/metadatastician/standards/blob/${'a'.repeat(40)}/3-practice/PROOF-POLICY.adoc[metadatastician/standards: 3-practice/PROOF-POLICY.adoc] at \`aaaaaaaaaaaa\`, at \`+== 5. Status vocabulary+\``);
  // A quote that is gone, or that occurs more than once, names no one place.
  refused([{at: 'Gone', path: 'README.adoc'}], /node paper: ref README\.adoc holds "Gone" 0 times; a ref quotes a passage that occurs exactly once/);
  refused([{at: 'at', path: 'docs/decisions/0004-claims-registry.adoc'}], /holds "at" [2-9] times/);
  // Each part is checked: the path, what it names, the quote, the commit and the issue.
  refused([{path: 'missing.adoc'}], /node paper: ref path missing\.adoc is not in the repository/);
  refused([{at: 'x', path: 'docs/decisions'}], /ref path docs\/decisions is not a file in the repository/);
  for (const p of ['../outside', '/etc/passwd', 'a/./b', 'a b', '']) refused([{path: p}], /is not a repository path/);
  for (const q of ['with `code`', 'a + b', 'back\\slash', ' padded', 'x'.repeat(161)]) refused([{at: q, path: 'README.adoc'}], /is not a short quote/);
  refused([{at: 'x', commit: '745fc74', path: 'a.adoc', repo: 'o/r'}], /ref commit "745fc74" is not a full commit id/);
  refused([{commit: 'a'.repeat(40), path: 'a.adoc', repo: 'nobody'}], /ref repo "nobody" is not OWNER\/REPO/);
  refused([{commit: 'a'.repeat(40), path: 'a.adoc'}], /ref repo undefined is not OWNER\/REPO/);
  refused([{issue: 'standards#1705'}], /ref issue "standards#1705" is not OWNER\/REPO#N, alone/);
  refused([{issue: 'o/r#1', path: 'README.adoc'}], /is not OWNER\/REPO#N, alone/);
  refused([{line: 92, path: 'README.adoc'}], /node paper: ref: unknown field "line"/);
  refused(['README.adoc:46'], /node paper: ref: must be an object/);
});

test('a ref cannot lead out of the repository', () => {
  const outside = mkdtempSync(path.join(tmpdir(), 'ultraplan-out-'));
  roots.push(outside);
  writeFileSync(path.join(outside, 'secret.adoc'), 'only once\n');
  const root = fixture({nodes: swap('paper', {refs: [{at: 'only once', path: 'link.adoc'}]})});
  symlinkSync(path.join(outside, 'secret.adoc'), path.join(root, 'link.adoc'));
  expect(() => generate(root)).toThrow(/ref path link\.adoc is not a file in the repository/);
  const dirRoot = fixture({nodes: swap('paper', {refs: [{path: 'away'}]})});
  symlinkSync(outside, path.join(dirRoot, 'away'));
  expect(() => generate(dirRoot)).toThrow(/ref path away is not in the repository/);
});

test('a summary that looks like block syntax is text on the page', () => {
  const base = generate(fixture())[VIEW].split('\n');
  const bare = (lines, s) => lines.filter(l => l === s).length;
  for (const s of ['|===', 'image::missing.svg[]', '// a comment', 'include::x.adoc[]', '== heading', '* item']) {
    const page = generate(fixture({nodes: swap('cheap', {summary: s})}))[VIEW].split('\n');
    expect(page).toContain(`{empty}${s}`);
    expect(bare(page, s)).toBe(bare(base, s)); // the summary adds no line of its own syntax
  }
  for (const n of BASE) expect(base).toContain(`{empty}${n.summary}`);
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

test('the me advisor names no public pick, and lists the owner\'s tags unranked', () => {
  // theorem unlocks more and cheap carries the higher maths mark: neither orders the list.
  const nodes = swap('cheap', {owner_value: 'high', value: {maths: 3}}, swap('theorem', {value: {maths: 1}}));
  const out = generate(fixture({nodes}));
  expect(out.derived.picks.get('me')).toBe(null);
  expect(out.derived.ownerTagged.map(n => n.id)).toEqual(['cheap', 'theorem']);
  expect(out[VIEW]).toContain('Tagged on the frontier, in id order: xref:cheap[🔷 cheap], xref:theorem[🔷 theorem].');
  const none = generate(fixture({nodes: swap('theorem', {owner_value: undefined})}))[VIEW];
  expect(none).toContain('_No public pick:_ the owner chooses in a private GELS panel. Nothing tagged is on the frontier.');
});

test('when every active slot is taken, the frontier is ready but cannot start', () => {
  const open = generate(fixture());
  expect(open.derived.slots).toBe(ACTIVE_LIMIT);
  expect(open[VIEW]).toContain('can be started now.');
  expect(open[VIEW]).toContain('so any of them can start today.');
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
  expect(full[VIEW]).toContain('so each can start once an active slot is free.');
  expect(full[VIEW]).not.toContain('can start today');
  expect(full[VIEW]).not.toContain('can be started now');
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
  expect(adrAccepted(ctx.read(ctx.adrFiles('0004')[0]))).toBe(true);
  expect(adrAccepted(ctx.read(ctx.adrFiles('0005')[0]))).toBe(false);
  for (const n of ['0001', '0002', '0003']) expect(adrAccepted(ctx.read(ctx.adrFiles(n)[0]))).toBe(true);
});

// The status is the ADR's own text, as AsciiDoc reads it. Each of these was
// accepted when the first "Status" heading anywhere in the file was taken.
test('an ADR is accepted only by its own one Status section', () => {
  const adr = body => `= ADR\n\n${body}\n`;
  expect(adrAccepted(adr('=== Status\n\n*Accepted (ratified).*'))).toBe(true);
  // A heading that could read Status counts even inside a block, so this ADR is
  // not read. Asciidoctor finds one Status section here; the reader fails closed.
  expect(adrAccepted(adr('=== Status\n\nAccepted\n\n----\n=== Status\nProposed\n----'))).toBe(false);
  expect(adrAccepted(adr('----\nan example\n----\n\n=== Status\n\nAccepted'))).toBe(true);
  expect(adrAccepted(adr('=== Status'))).toBe(false);
  expect(adrAccepted(adr('=== Status\n\nProposed.'))).toBe(false);
  expect(adrAccepted(adr('////\n=== Status\nAccepted\n////\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(adrAccepted(adr('----\n=== Status\nAccepted\n----\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(adrAccepted(adr('....\n=== Status\nAccepted\n....\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(adrAccepted(adr('ifdef::never[]\n=== Status\nAccepted\nendif::[]\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(adrAccepted(adr('=== Status\n\nAccepted\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(adrAccepted(adr('=== Status\n// Accepted\nProposed.'))).toBe(false);
  expect(adrAccepted(adr('=== Status\n----\nAccepted\n----'))).toBe(false);
  expect(adrAccepted(adr('include::status.adoc[]\n\n=== Status\n\nAccepted'))).toBe(false);
  expect(adrAccepted(adr('// === Status\n// Accepted'))).toBe(false);
  // Each of these agrees with Asciidoctor 2.0.26: a "[discrete]" waiting above the
  // heading, across blank lines and comments, makes it a floating title, not a
  // section; a heading straight after a paragraph line belongs to the paragraph.
  for (const above of ['[discrete]\n', '[float]\n', '[discrete]\n\n', '[discrete]\n////\nx\n////\n\n', '[discrete]\n// note\n\n', 'Some text.\n'])
    expect(adrAccepted(adr(`${above}=== Status\n\nAccepted`))).toBe(false);
  expect(adrAccepted(adr('=== Status\n// a comment\nAccepted'))).toBe(true);
  // "= Status" is the document's title, not a section (Asciidoctor agrees), also
  // after leading comments, which may come before a document header.
  expect(adrAccepted('= Status\n\nAccepted\n')).toBe(false);
  expect(adrAccepted('// note\n////\nx\n////\n\n= Status\n\nAccepted\n')).toBe(false);
  expect(adrAccepted('== Status\n\nAccepted\n')).toBe(true);
  // A heading inside a block is not a section even with a blank line above it.
  for (const block of ['----\nexample\n\n=== Status\n\nAccepted\n----', '////\nold\n\n=== Status\n\nAccepted\n////', '====\n\n=== Status\n\nAccepted\n===='])
    expect(adrAccepted(adr(block))).toBe(false);
  expect(adrAccepted(adr('=== Status\n\n////\nAccepted\n////\n\nProposed.'))).toBe(false);
  // Asciidoctor reads a section here, but the reader says no: it fails closed on
  // any attribute line or block title above a Status heading.
  for (const above of ['[[status]]\n', '.A title\n']) expect(adrAccepted(adr(`${above}=== Status\n\nAccepted`))).toBe(false);
});

// Each case below was checked against Asciidoctor 2.0.26. Where the comment says
// the reader fails closed, Asciidoctor would accept and the reader refuses.
test('a Markdown fence hides what it holds, as Asciidoctor reads it', () => {
  const adr = body => `= ADR\n\n${body}\n`;
  // A heading inside a fence is not a section, blank lines around it or not.
  expect(adrAccepted(adr('```\n\n=== Status\n\nAccepted\n```'))).toBe(false);
  expect(adrAccepted(adr('```\n=== Status\nAccepted\n```'))).toBe(false);
  // A fence opens with a language after it, and only three bare backticks close it.
  expect(adrAccepted(adr('```ruby\ncode\n```\n\n=== Status\n\nAccepted'))).toBe(true);
  expect(adrAccepted(adr('```ruby\ncode\n```ruby\n\n=== Status\n\nAccepted'))).toBe(false);
  expect(adrAccepted(adr('``` ruby\ncode\n``` ruby\n\n=== Status\n\nAccepted'))).toBe(false);
  // "````" and "~~~" delimit nothing, so a later "```" opens a fence that hides the rest.
  expect(adrAccepted(adr('````\ncode\n````\n\n=== Status\n\nAccepted'))).toBe(true);
  for (const lead of ['````', '~~~', '`` `']) expect(adrAccepted(adr(`${lead}\ncode\n\`\`\`\n\n=== Status\n\nAccepted`))).toBe(false);
});

test('a second heading that could read Status leaves the ADR unread', () => {
  const adr = body => `= ADR\n\n=== Status\n\nAccepted\n\n${body}\n\nProposed.\n`;
  expect(adrAccepted(adr('=== Context'))).toBe(true);
  // Each is a second section titled Status to Asciidoctor: a later level-0 title,
  // Markdown and symmetric markers, extra blanks, an underlined title, a title that
  // a substitution spells, an attribute line above, and a heading straight after a block.
  for (const second of ['= Status', '## Status', '### Status', '== Status ==', '==  Status', '==\tStatus',
    'Status\n------', 'Status\n~~~~~~', ':s: Status\n\n== {s}', '== +Status+', '== pass:[Status]',
    '== Stat{empty}us', '== ((Status))', '[#sid]\n== Status', '[appendix]\n== Status', '----\ncode\n----\n== Status'])
    expect(adrAccepted(adr(second))).toBe(false);
  // Seven markers make no heading, so the line cannot be the Status section.
  expect(adrAccepted('= ADR\n\n======= Status\n\nAccepted\n')).toBe(false);
  for (const level of ['==', '===', '======']) expect(adrAccepted(`= ADR\n\n${level} Status\n\nAccepted\n`)).toBe(true);
});

test('the Status section opens with a paragraph that says Accepted', () => {
  const adr = body => `= ADR\n\n${body}\n`;
  // To Asciidoctor none of these opens with such a paragraph: a literal (indented)
  // line, a description-list term, an underlined title, and "///", which is text.
  for (const opening of [' Accepted', 'Accepted:: yes', 'Accepted::', 'Accepted;; yes', 'Accepted\n--------', '/// x\nAccepted', '///\nAccepted'])
    expect(adrAccepted(adr(`=== Status\n\n${opening}`))).toBe(false);
  expect(adrAccepted(adr('=== Status\n\n// a comment\nAccepted'))).toBe(true);
  // A heading inside a comment block is no section, though text follows the block.
  expect(adrAccepted(adr('////\n\n=== Status\n////\nAccepted'))).toBe(false);
  // A heading below a list continuation, or below a term with nothing after it,
  // belongs to the list. Below a term with a description the reader fails closed.
  for (const above of ['* item\n+\n\n', 'term::\n\n', 'term:: words\n\n'])
    expect(adrAccepted(adr(`${above}=== Status\n\nAccepted`))).toBe(false);
  expect(adrAccepted(adr('* item\n\n=== Status\n\nAccepted'))).toBe(true);
  // A short line over a delimiter of about its length is a two-line title, so no
  // block opens there; the reader does not read such an ADR.
  expect(adrAccepted(adr('foo\n----\n=== Status\nProposed\n----\n\n=== Status\n\nAccepted'))).toBe(false);
  // A line far from the delimiter's length leaves it a delimiter, and inside a
  // block no title is read at all, whatever the lengths.
  expect(adrAccepted(adr('A much longer paragraph line\n----\ncode\n----\n\n=== Status\n\nAccepted'))).toBe(true);
  expect(adrAccepted(adr('----\nfoo\n----\n\n=== Status\n\nAccepted'))).toBe(true);
});

test('the committed views match the committed data', () => {
  const out = generate(ROOT);
  expect(readFileSync(path.join(ROOT, VIEW), 'utf8')).toBe(out[VIEW]);
  expect(readFileSync(path.join(ROOT, SVG), 'utf8')).toBe(out[SVG]);
});
