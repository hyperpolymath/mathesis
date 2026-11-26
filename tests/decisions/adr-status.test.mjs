// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// The status of a decision record: the Status section (read so that it never
// names a word where Asciidoctor finds no such section), the header attribute
// (read so that it never names a status Asciidoctor would not set), and the
// check that keeps the two in step (owner ruling 2026-11-25).
import {test, expect, afterAll} from 'bun:test';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync, symlinkSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {sectionStatus, headerStatus, adrStatus, adrAccepted, checkDecisions} from '../../scripts/decisions/adr-status.mjs';

const roots = [];
afterAll(() => { for (const r of roots) rmSync(r, {recursive: true, force: true}); });
const sectionAccepted = t => sectionStatus(t) === 'ACCEPTED';


// The status is the ADR's own text, as AsciiDoc reads it. Each of these was
// accepted when the first "Status" heading anywhere in the file was taken.
test('an ADR is accepted only by its own one Status section', () => {
  const adr = body => `= ADR\n\n${body}\n`;
  expect(sectionAccepted(adr('=== Status\n\n*Accepted (ratified).*'))).toBe(true);
  // A heading that could read Status counts even inside a block, so this ADR is
  // not read. Asciidoctor finds one Status section here; the reader fails closed.
  expect(sectionAccepted(adr('=== Status\n\nAccepted\n\n----\n=== Status\nProposed\n----'))).toBe(false);
  expect(sectionAccepted(adr('----\nan example\n----\n\n=== Status\n\nAccepted'))).toBe(true);
  expect(sectionAccepted(adr('=== Status'))).toBe(false);
  expect(sectionAccepted(adr('=== Status\n\nProposed.'))).toBe(false);
  expect(sectionAccepted(adr('////\n=== Status\nAccepted\n////\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(sectionAccepted(adr('----\n=== Status\nAccepted\n----\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(sectionAccepted(adr('....\n=== Status\nAccepted\n....\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(sectionAccepted(adr('ifdef::never[]\n=== Status\nAccepted\nendif::[]\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(sectionAccepted(adr('=== Status\n\nAccepted\n\n=== Status\n\nProposed.'))).toBe(false);
  expect(sectionAccepted(adr('=== Status\n// Accepted\nProposed.'))).toBe(false);
  expect(sectionAccepted(adr('=== Status\n----\nAccepted\n----'))).toBe(false);
  expect(sectionAccepted(adr('include::status.adoc[]\n\n=== Status\n\nAccepted'))).toBe(false);
  expect(sectionAccepted(adr('// === Status\n// Accepted'))).toBe(false);
  // Each of these agrees with Asciidoctor 2.0.26: a "[discrete]" waiting above the
  // heading, across blank lines and comments, makes it a floating title, not a
  // section; a heading straight after a paragraph line belongs to the paragraph.
  for (const above of ['[discrete]\n', '[float]\n', '[discrete]\n\n', '[discrete]\n////\nx\n////\n\n', '[discrete]\n// note\n\n', 'Some text.\n'])
    expect(sectionAccepted(adr(`${above}=== Status\n\nAccepted`))).toBe(false);
  expect(sectionAccepted(adr('=== Status\n// a comment\nAccepted'))).toBe(true);
  // "= Status" is the document's title, not a section (Asciidoctor agrees), also
  // after leading comments, which may come before a document header.
  expect(sectionAccepted('= Status\n\nAccepted\n')).toBe(false);
  expect(sectionAccepted('// note\n////\nx\n////\n\n= Status\n\nAccepted\n')).toBe(false);
  expect(sectionAccepted('== Status\n\nAccepted\n')).toBe(true);
  // A heading inside a block is not a section even with a blank line above it.
  for (const block of ['----\nexample\n\n=== Status\n\nAccepted\n----', '////\nold\n\n=== Status\n\nAccepted\n////', '====\n\n=== Status\n\nAccepted\n===='])
    expect(sectionAccepted(adr(block))).toBe(false);
  expect(sectionAccepted(adr('=== Status\n\n////\nAccepted\n////\n\nProposed.'))).toBe(false);
  // Asciidoctor reads a section here, but the reader says no: it fails closed on
  // any attribute line or block title above a Status heading.
  for (const above of ['[[status]]\n', '.A title\n']) expect(sectionAccepted(adr(`${above}=== Status\n\nAccepted`))).toBe(false);
});

// Each case below was checked against Asciidoctor 2.0.26. Where the comment says
// the reader fails closed, Asciidoctor would accept and the reader refuses.
test('a Markdown fence hides what it holds, as Asciidoctor reads it', () => {
  const adr = body => `= ADR\n\n${body}\n`;
  // A heading inside a fence is not a section, blank lines around it or not.
  expect(sectionAccepted(adr('```\n\n=== Status\n\nAccepted\n```'))).toBe(false);
  expect(sectionAccepted(adr('```\n=== Status\nAccepted\n```'))).toBe(false);
  // A fence opens with a language after it, and only three bare backticks close it.
  expect(sectionAccepted(adr('```ruby\ncode\n```\n\n=== Status\n\nAccepted'))).toBe(true);
  expect(sectionAccepted(adr('```ruby\ncode\n```ruby\n\n=== Status\n\nAccepted'))).toBe(false);
  expect(sectionAccepted(adr('``` ruby\ncode\n``` ruby\n\n=== Status\n\nAccepted'))).toBe(false);
  // "````" and "~~~" delimit nothing, so a later "```" opens a fence that hides the rest.
  expect(sectionAccepted(adr('````\ncode\n````\n\n=== Status\n\nAccepted'))).toBe(true);
  for (const lead of ['````', '~~~', '`` `']) expect(sectionAccepted(adr(`${lead}\ncode\n\`\`\`\n\n=== Status\n\nAccepted`))).toBe(false);
});

test('a second heading that could read Status leaves the ADR unread', () => {
  const adr = body => `= ADR\n\n=== Status\n\nAccepted\n\n${body}\n\nProposed.\n`;
  expect(sectionAccepted(adr('=== Context'))).toBe(true);
  // Each is a second section titled Status to Asciidoctor: a later level-0 title,
  // Markdown and symmetric markers, extra blanks, an underlined title, a title that
  // a substitution spells, an attribute line above, and a heading straight after a block.
  for (const second of ['= Status', '## Status', '### Status', '== Status ==', '==  Status', '==\tStatus',
    'Status\n------', 'Status\n~~~~~~', ':s: Status\n\n== {s}', '== +Status+', '== pass:[Status]',
    '== Stat{empty}us', '== ((Status))', '[#sid]\n== Status', '[appendix]\n== Status', '----\ncode\n----\n== Status'])
    expect(sectionAccepted(adr(second))).toBe(false);
  // A title is read whole, past a line separator (which the earlier pattern's "."
  // stopped at), and a long run of blanks before one costs no backtracking.
  for (const title of ['Status ', 'x Status']) expect(sectionAccepted(adr(`== ${title}`))).toBe(false);
  const started = performance.now();
  expect(sectionAccepted(adr(`=${' '.repeat(50000)} `))).toBe(true);
  expect(performance.now() - started).toBeLessThan(200);
  // Seven markers make no heading, so the line cannot be the Status section.
  expect(sectionAccepted('= ADR\n\n======= Status\n\nAccepted\n')).toBe(false);
  for (const level of ['==', '===', '======']) expect(sectionAccepted(`= ADR\n\n${level} Status\n\nAccepted\n`)).toBe(true);
});

test('the Status section opens with a paragraph that says Accepted', () => {
  const adr = body => `= ADR\n\n${body}\n`;
  // To Asciidoctor none of these opens with such a paragraph: a literal (indented)
  // line, a description-list term, an underlined title, and "///", which is text.
  for (const opening of [' Accepted', 'Accepted:: yes', 'Accepted::', 'Accepted;; yes', 'Accepted\n--------', '/// x\nAccepted', '///\nAccepted'])
    expect(sectionAccepted(adr(`=== Status\n\n${opening}`))).toBe(false);
  expect(sectionAccepted(adr('=== Status\n\n// a comment\nAccepted'))).toBe(true);
  // A heading inside a comment block is no section, though text follows the block.
  expect(sectionAccepted(adr('////\n\n=== Status\n////\nAccepted'))).toBe(false);
  // A heading below a list continuation, or below a term with nothing after it,
  // belongs to the list. Below a term with a description the reader fails closed.
  for (const above of ['* item\n+\n\n', 'term::\n\n', 'term:: words\n\n'])
    expect(sectionAccepted(adr(`${above}=== Status\n\nAccepted`))).toBe(false);
  expect(sectionAccepted(adr('* item\n\n=== Status\n\nAccepted'))).toBe(true);
  // A short line over a delimiter of about its length is a two-line title, so no
  // block opens there; the reader does not read such an ADR.
  expect(sectionAccepted(adr('foo\n----\n=== Status\nProposed\n----\n\n=== Status\n\nAccepted'))).toBe(false);
  // A line far from the delimiter's length leaves it a delimiter, and inside a
  // block no title is read at all, whatever the lengths.
  expect(sectionAccepted(adr('A much longer paragraph line\n----\ncode\n----\n\n=== Status\n\nAccepted'))).toBe(true);
  expect(sectionAccepted(adr('----\nfoo\n----\n\n=== Status\n\nAccepted'))).toBe(true);
});

// The opening word ends where no letter, number, mark or "_" of any script
// follows: "Acceptedé" is not "Accepted", though \b would say it is.
test('the opening word of the Status section ends at a Unicode word boundary', () => {
  const doc = w => `= A\n:status: ACCEPTED\n\n=== Status\n\n${w} by the owner.\n`;
  for (const w of ['Accepted\u00e9', 'Accepted\u03b2', 'Accepted\u0301', 'Accepted\u0663', 'Accepted_x', 'Accepted2']) {
    expect(sectionStatus(doc(w))).toBe(null);
    expect(adrAccepted(doc(w))).toBe(false);
  }
  for (const w of ['Accepted', '*Accepted*', 'Accepted.', 'Accepted\u2014', 'Accepted (ratified)']) expect(sectionStatus(doc(w))).toBe('ACCEPTED');
});

test('the Status section names its opening word, whatever the status', () => {
  const adr = body => `= ADR\n\n=== Status\n\n${body}\n`;
  for (const [opening, word] of [['Accepted', 'ACCEPTED'], ['*Proposed. Not yet.*', 'PROPOSED'], ['Superseded by 0007.', 'SUPERSEDED'], ['Deprecated', 'DEPRECATED']])
    expect(sectionStatus(adr(opening))).toBe(word);
  // A word is a whole word: "Acceptedly" is not "Accepted".
  expect(sectionStatus(adr('Acceptedly'))).toBe('ACCEPTEDLY');
  expect(sectionStatus(adr('Accepted2'))).toBe(null);
  expect(sectionStatus(adr('`Accepted`'))).toBe(null);
});

// Each case below was checked against Asciidoctor 2.0.26's own status attribute.
test('the header states the status once, as the ADR template words it', () => {
  const doc = (head, body = '') => `= ADR\n${head}\n\n${body}`;
  for (const v of ['PROPOSED', 'ACCEPTED', 'DEPRECATED', 'SUPERSEDED', 'SUPERSEDED by 0007', 'REJECTED'])
    expect(headerStatus(doc(`:status: ${v}`))).toBe(v);
  // Leading comments and blank lines before the title, and comments and other
  // attribute entries in the header, are allowed.
  expect(headerStatus(`// SPDX\n// x\n\n= ADR\n// note\n:revdate: 2026-11-25\n:status: ACCEPTED\n\nBody.\n`)).toBe('ACCEPTED');
  // Other spellings and values are refused: the template's words, written exactly.
  // A blank after the value is no difference: Asciidoctor, like the reader, drops it.
  expect(headerStatus(doc(':status: ACCEPTED  '))).toBe('ACCEPTED');
  for (const v of ['Accepted', 'accepted', ' ACCEPTED', 'ACCEPTED, really', 'SUPERSEDED by 7', 'DONE'])
    expect(headerStatus(doc(`:status: ${v}`))).toBe(null);
  // Not a document title, or no header at all.
  expect(headerStatus('== ADR\n:status: ACCEPTED\n')).toBe(null);
  expect(headerStatus('Text first.\n\n= ADR\n:status: ACCEPTED\n')).toBe(null);
  // Below a blank line the entry is in the body, not the header.
  expect(headerStatus('= ADR\n\n:status: ACCEPTED\n')).toBe(null);
});

test('nothing but the one header entry can set or unset the status', () => {
  const doc = (head, body = '') => `= ADR\n${head}\n\n${body}`;
  // A second entry, an unset, an inline set or a conditional anywhere.
  for (const body of [':status: PROPOSED\n', ':status!:\n', ':!status:\n', 'Text {set:status:PROPOSED} here.\n', 'ifdef::x[]\n:status: PROPOSED\nendif::[]\n'])
    expect(headerStatus(doc(':status: ACCEPTED', body))).toBe(null);
  // Asciidoctor lowercases an entry's name: ":Status: PROPOSED" sets "status"
  // (probed with 2.0.26), so an entry in any letter case counts.
  for (const body of [':Status: PROPOSED\n', ':STATUS: PROPOSED\n', ':Status!:\n', ':!Status:\n', ':sTaTuS: REJECTED\n'])
    expect(headerStatus(doc(':status: ACCEPTED', body))).toBe(null);
  // The one header entry is written exactly as the template writes it.
  expect(headerStatus(doc(':Status: ACCEPTED'))).toBe(null);
  // A counter changes the attribute it names (Asciidoctor 2.0.26 turns ACCEPTED
  // into ACCEPTEE), so any inline reference that changes an attribute, whichever
  // it names and in whatever case, leaves the header unread.
  for (const ref of ['{counter:status}', '{counter2:status}', '{counter:status:A}', '{counter:other}', '{COUNTER:status}', '{Set:status:x}'])
    expect(headerStatus(doc(':status: ACCEPTED', `Accepted ${ref}\n`))).toBe(null);
  // A brace that changes nothing is plain text.
  expect(headerStatus(doc(':status: ACCEPTED', 'A {status} and a {counterpart}.\n'))).toBe('ACCEPTED');
  expect(headerStatus(doc(':status: ACCEPTED\n:status: ACCEPTED'))).toBe(null);
  // An included file could set the status where no line here does.
  expect(headerStatus(doc(':status: ACCEPTED', 'include::more.adoc[]\n'))).toBe(null);
  // A header line that is neither a comment nor an entry could change what the
  // header holds (an author line, a comment block), and a continuation joins
  // the next line to an entry's value; each is refused.
  for (const head of ['Ann Author\n:status: ACCEPTED', '////\n:status: ACCEPTED\n////', ':foo: bar \\\n:status: ACCEPTED', ':foo: bar +\n:status: ACCEPTED', ':status: ACCEPTED \\'])
    expect(headerStatus(doc(head))).toBe(null);
});

test('an ADR is accepted only when its header and its Status section both say so', () => {
  const adr = (head, opening) => `= ADR\n${head}\n\n=== Status\n\n${opening}\n`;
  expect(adrAccepted(adr(':status: ACCEPTED', '*Accepted (ratified).*'))).toBe(true);
  expect(adrStatus(adr(':status: ACCEPTED', 'Accepted'))).toEqual({header: 'ACCEPTED', section: 'ACCEPTED', inStep: true});
  // Out of step either way, or half stated: not accepted.
  expect(adrStatus(adr(':status: ACCEPTED', 'Proposed.'))).toEqual({header: 'ACCEPTED', section: 'PROPOSED', inStep: false});
  expect(adrAccepted(adr(':status: ACCEPTED', 'Proposed.'))).toBe(false);
  expect(adrAccepted(adr(':status: PROPOSED', 'Accepted'))).toBe(false);
  expect(adrAccepted(adr(':revdate: x', 'Accepted'))).toBe(false);
  expect(adrAccepted(`= ADR\n:status: ACCEPTED\n\nNo Status section.\n`)).toBe(false);
  // In step, but not accepted.
  expect(adrStatus(adr(':status: SUPERSEDED by 0007', 'Superseded by ADR 0007.'))).toEqual({header: 'SUPERSEDED by 0007', section: 'SUPERSEDED', inStep: true});
  expect(adrAccepted(adr(':status: PROPOSED', 'Proposed.'))).toBe(false);
});

// git, run in a fixture: the check reads only the records git tracks there.
const git = (root, ...args) => {
  const r = Bun.spawnSync(['git', '-C', root, '-c', 'init.defaultBranch=main', ...args]);
  if (r.exitCode !== 0) throw new Error(`git ${args.join(' ')}: ${r.stderr}`);
};

test('the check keeps every decision record in step, and reports one that states none', () => {
  const root = mkdtempSync(path.join(tmpdir(), 'adr-'));
  roots.push(root);
  const dir = path.join(root, 'docs/decisions');
  mkdirSync(dir, {recursive: true});
  git(root, 'init', '-q');
  // Each record is written and tracked, as a commit would track it.
  const put = (f, s) => { writeFileSync(path.join(dir, f), s); git(root, 'add', '-A'); };
  put('0001-a.adoc', '= A\n:status: ACCEPTED\n\n=== Status\n\nAccepted\n');
  put('0002-b.adoc', '= B\n\n== Scope\n\nNo status yet.\n');
  put('0003-template.adoc', '= Template\n:status: PROPOSED\n');
  put('README.adoc', '= Decisions\n');
  expect(checkDecisions(root)).toEqual([{file: '0001-a.adoc', status: 'ACCEPTED'}, {file: '0002-b.adoc', status: null}]);
  put('0004-c.adoc', '= C\n:status: ACCEPTED\n\n=== Status\n\nProposed.\n');
  put('0005-d.adoc', '= D\n\n=== Status\n\nAccepted\n');
  put('0006-e.adoc', '= E\n:status: PROPOSED\n\nNo section.\n');
  const problems = checkDecisions(root).filter(r => r.problem).map(r => `${r.file}: ${r.problem}`);
  expect(problems).toEqual([
    '0004-c.adoc: its header says ACCEPTED but its Status section says PROPOSED',
    '0005-d.adoc: its header says nothing readable but its Status section says ACCEPTED',
    '0006-e.adoc: its header says PROPOSED but its Status section says nothing readable',
  ]);
  // A record that is a link is not read.
  const other = mkdtempSync(path.join(tmpdir(), 'adr-out-'));
  roots.push(other);
  writeFileSync(path.join(other, 'x.adoc'), '= X\n:status: ACCEPTED\n\n=== Status\n\nAccepted\n');
  symlinkSync(path.join(other, 'x.adoc'), path.join(dir, '0007-link.adoc'));
  git(root, 'add', '-A');
  expect(checkDecisions(root).find(r => r.file === '0007-link.adoc')).toEqual({file: '0007-link.adoc', problem: 'is not a file that git tracks in the repository, at its own path'});
  // A record git does not track is not one, nor is a file in a directory named like one.
  writeFileSync(path.join(dir, '0008-draft.adoc'), '= D\n:status: ACCEPTED\n\n=== Status\n\nProposed.\n');
  mkdirSync(path.join(dir, '0009-notes'));
  writeFileSync(path.join(dir, '0009-notes/x.adoc'), '= N\n:status: ACCEPTED\n\n=== Status\n\nProposed.\n');
  git(root, 'add', 'docs/decisions/0009-notes');
  expect(checkDecisions(root).map(r => r.file)).toEqual(['0001-a.adoc', '0002-b.adoc', '0004-c.adoc', '0005-d.adoc', '0006-e.adoc', '0007-link.adoc']);
  // A record whose status the readers refuse is refused, not reported as unset:
  // a directive, a mutating reference or a heading that could read Status beside
  // an otherwise sound status makes it unreadable, never silently empty.
  const unreadable = 'it states a status that cannot be read soundly (see docs/decisions/README.adoc)';
  for (const [f, body] of [
    ['0010-include.adoc', '= J\n:status: ACCEPTED\n\n=== Status\n\nAccepted\n\ninclude::more.adoc[]\n'],
    ['0011-ifdef.adoc', '= K\n:status: ACCEPTED\n\nifdef::x[]\n\n=== Status\n\nAccepted\nendif::[]\n'],
    ['0012-quo.adoc', '= L\n\n== Status quo\n\nNothing is decided.\n'],
    ['0013-counter.adoc', '= M\n\nA {counter:status} count.\n'],
    ['0014-entry.adoc', '= N\n\nBody.\n\n:Status: ACCEPTED\n'],
    ['0016-set.adoc', '= P\n\nText {set:Status:ACCEPTED} here.\n'],
    // Nothing here names a status, but the included file could set one.
    ['0017-include-only.adoc', '= Q\n\ninclude::decision.adoc[]\n'],
    // A two-line title, "Status" over an underline, is a Status heading too.
    ['0018-underlined.adoc', '= R\n\nStatus\n------\n\nAccepted\n'],
    // An underlined title that cannot read Status leaves the record unset.
    ['0019-context.adoc', '= S\n\nContext\n-------\n\nNothing is decided.\n'],
    ['0015-plain-counter.adoc', '= O\n\nA {counter:n} count and the word status in prose.\n'],
  ]) put(f, body);
  const byFile = new Map(checkDecisions(root).map(r => [r.file, r]));
  for (const f of ['0010-include.adoc', '0011-ifdef.adoc', '0012-quo.adoc', '0013-counter.adoc', '0014-entry.adoc', '0016-set.adoc', '0017-include-only.adoc', '0018-underlined.adoc'])
    expect(byFile.get(f)).toEqual({file: f, problem: unreadable});
  // A record that states nothing about status, in any form, is still listed as
  // unset, though it counts something else or says "status" in its prose.
  expect(byFile.get('0002-b.adoc')).toEqual({file: '0002-b.adoc', status: null});
  expect(byFile.get('0015-plain-counter.adoc')).toEqual({file: '0015-plain-counter.adoc', status: null});
  expect(byFile.get('0019-context.adoc')).toEqual({file: '0019-context.adoc', status: null});
  // A decisions directory that is a link out of the repository is refused, and
  // nothing through it is read, though git tracks the link.
  const linked = mkdtempSync(path.join(tmpdir(), 'adr-linked-'));
  roots.push(linked);
  mkdirSync(path.join(linked, 'docs'));
  symlinkSync(dir, path.join(linked, 'docs/decisions'));
  git(linked, 'init', '-q');
  git(linked, 'add', '-A');
  expect(checkDecisions(linked)).toEqual([{file: 'docs/decisions', problem: 'is not a directory in the repository that holds a file git tracks'}]);
});

test('the decision records here are in step', () => {
  const results = checkDecisions();
  expect(results.filter(r => r.problem)).toEqual([]);
  expect(results.find(r => r.file === '0004-claims-registry.adoc')?.status).toBe('ACCEPTED');
});
