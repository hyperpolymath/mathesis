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

test('the check keeps every decision record in step, and reports one that states none', () => {
  const root = mkdtempSync(path.join(tmpdir(), 'adr-'));
  roots.push(root);
  const dir = path.join(root, 'docs/decisions');
  mkdirSync(dir, {recursive: true});
  const put = (f, s) => writeFileSync(path.join(dir, f), s);
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
  expect(checkDecisions(root).find(r => r.file === '0007-link.adoc')).toEqual({file: '0007-link.adoc', problem: 'is not a plain file'});
});

test('the decision records here are in step', () => {
  const results = checkDecisions();
  expect(results.filter(r => r.problem)).toEqual([]);
  expect(results.find(r => r.file === '0004-claims-registry.adoc')?.status).toBe('ACCEPTED');
});
