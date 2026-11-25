// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// The status of a decision record (ADR), read soundly.
//
//   bun scripts/decisions/adr-status.mjs check   every ADR's header and Status section agree
//
// An ADR states its status twice (owner ruling 2026-11-25): once as an
// attribute of its document header, `:status: ACCEPTED`, in the words of the
// estate's ADR template (docs/decisions/0001-template.adoc: PROPOSED,
// ACCEPTED, DEPRECATED, SUPERSEDED, and REJECTED from 0000-template.adoc),
// and once in its prose, as the opening word of its Status section. The header
// is what a machine reads; the section is what a person reads; `check` keeps
// the two in step. An ADR counts as ACCEPTED only when both say so.
import path from 'node:path';
import {repoFiles} from '../repo/files.mjs';

export const ROOT = path.resolve(import.meta.dir, '../..');
export const DECISIONS = 'docs/decisions';

// A description-list marker ("::", ":::", "::::" or ";;", then a blank or the
// end) makes Asciidoctor read the line that holds it as a list term, wherever
// in the line it sits.
const LIST_MARKER = /(?::{2,4}|;;)(?:[ \t]|$)/;

// ── The Status section ───────────────────────────────────────────────────────
// The word an ADR's Status section opens with, as AsciiDoc reads it, or null.
// It must never name a word where Asciidoctor finds no such section. So it does
// not try to mirror every way Asciidoctor reads a heading: it over-counts, and
// it reads one plain shape only (it fails closed).
// - Every line that could be a heading titled Status counts, inside a block or
//   not: "=" or "#" markers and a blank, then a title that holds the letters
//   "status" in any case, or a reference that could spell them. An ADR with a
//   count other than one is not read.
// - That one line is "==" to "======", one space and "Status"; it is outside any
//   delimited block; and it follows a blank line, with nothing above it, across
//   blank lines and comments, that attaches it to what came before: a block
//   attribute line, a block title, a list continuation or a description-list term.
// - The first line after it, past blank lines and comments, is text that begins
//   with a word, after any "*": not indented, and holding no description-list marker.
// - No text line stands over an underline ("-", "=", "~", "^" or "+" repeated)
//   of about its length: Asciidoctor reads such a pair as a section title.
// - A preprocessor directive could change which lines count, so an ADR that
//   holds one is not read.
// A delimiter is one of these characters four or more times, "--", or a table's "|===".
// It closes on the same line again.
const DELIMITER = /^(?:([/\-.+*=_])\1{3,}|--|[|,:!]={3,})$/;
// A Markdown fence, which Asciidoctor reads too: three backticks open it, with
// any language after them but never a fourth backtick, and only a line of
// exactly three backticks closes it. "````" and "~~~" delimit nothing.
const FENCE = /^```(?!`)/;
const opener = l => {
  if (DELIMITER.test(l)) return l;
  return FENCE.test(l) ? '```' : null;
};
const PREPROCESSOR = /^(?:ifdef|ifndef|ifeval|endif|include)::/;
// "//" begins a line comment, but "///" begins text.
const COMMENT = /^\/\/(?!\/)/;
// What each line is: inside a delimited block or one of its delimiters
// ('block'), part of a comment, which AsciiDoc drops ('comment'), or text.
const kindOf = (l, block) => {
  if (block) return block.startsWith('//') ? 'comment' : 'block';
  return COMMENT.test(l) ? 'comment' : 'text';
};
function lineKinds(lines) {
  let open = null;
  return lines.map(l => {
    const block = open ?? opener(l);
    const closes = open !== null && l === open;
    open = closes ? null : block;
    return kindOf(l, block);
  });
}
// A heading in any form AsciiDoc or Markdown gives one: its markers and a blank,
// then a title that could read "Status". The title is the rest of the line, taken
// whole, so the pattern cannot backtrack and no character of the title escapes it.
const HEADING = /^[=#]+[ \t]/;
const mayBeStatus = l => {
  const m = HEADING.exec(l);
  if (m === null) return false;
  const title = l.slice(m[0].length);
  return /\{|&#?\w+;/.test(title) || /status/i.test(title.replace(/[^\p{L}]/gu, ''));
};
// Asciidoctor reads a line over an underline within one character of its
// length as a two-line section title; two characters are allowed here.
const UNDERLINE = /^([-=~^+])\1+$/;
const width = s => [...s].length;
const overUnderline = (lines, kinds, i) => kinds[i] === 'text' && lines[i] !== '' && UNDERLINE.test(lines[i + 1] ?? '')
  && Math.abs(width(lines[i + 1]) - width(lines[i])) <= 2;
// What, standing above a heading across blank lines and comments, attaches the
// heading to it: a block attribute line, a block title, a list continuation or
// a description-list term.
const ATTACHES = /^(?:\[.*\]|\.[^.\s].*|\+)$|(?::{2,4}|;;)(?:[ \t]|$)/;
function startsSection(lines, kinds, i) {
  if (i > 0 && lines[i - 1] !== '') return false;
  let j = i - 1;
  while (j >= 0 && (lines[j] === '' || kinds[j] === 'comment')) j--;
  return j < 0 || !ATTACHES.test(lines[j]);
}
const linesOf = text => text.split('\n').map(l => l.trimEnd());
export function sectionStatus(text) {
  const lines = linesOf(text);
  if (lines.some(l => PREPROCESSOR.test(l))) return null;
  const kinds = lineKinds(lines);
  if (lines.some((_, i) => overUnderline(lines, kinds, i))) return null;
  const heads = lines.flatMap((l, i) => (mayBeStatus(l) ? [i] : []));
  if (heads.length !== 1) return null;
  const [h] = heads;
  if (kinds[h] !== 'text' || !/^={2,6} Status$/.test(lines[h]) || !startsSection(lines, kinds, h)) return null;
  // The heading is text, so the line after it is text too, unless it opens a
  // block, and no delimiter that opens one begins with a letter.
  const n = lines.findIndex((l, i) => i > h && l !== '' && kinds[i] !== 'comment');
  const word = n > h && !LIST_MARKER.test(lines[n]) ? /^\**([A-Za-z]+)\b/.exec(lines[n]) : null;
  return word ? word[1].toUpperCase() : null;
}

// ── The header attribute ─────────────────────────────────────────────────────
// The status an ADR's document header states, or null. The header is the title
// line ("= Title"), after any blank lines and line comments, and the lines that
// follow it up to the first blank line. Read strictly, so it never names a
// status Asciidoctor would not set:
// - Each header line after the title is a line comment or an attribute entry,
//   and none ends in a continuation ("\" or "+"). An author or revision line,
//   or a comment block, could change what the header holds, so it is refused.
// - Exactly one line in the whole file sets or unsets "status", and it is in
//   the header. Nothing later can change it: no ":status:", ":status!:" or
//   ":!status:", in any letter case (Asciidoctor lowercases an entry's name,
//   so ":Status: PROPOSED" sets "status"), and no inline reference that changes an attribute
//   ("{set:...}", "{counter:...}" or "{counter2:...}"; a counter turns
//   ACCEPTED into ACCEPTEE). Any such reference, to any attribute, leaves the
//   header unread.
// - Its value is one of the template's words: PROPOSED, ACCEPTED, DEPRECATED,
//   SUPERSEDED (optionally "by NNNN") or REJECTED, written exactly so.
const ENTRY = /^:!?[\w-]+!?:(?: |$)/;
// An inline reference that changes an attribute where it stands.
const MUTATES = /\{(?:set|counter2?):/i;
const STATUS_ENTRY = /^:!?status!?:/i;
const STATUS_VALUE = /^:status: (PROPOSED|ACCEPTED|DEPRECATED|SUPERSEDED(?: by \d{4})?|REJECTED)$/;
function headerRange(lines) {
  let t = 0;
  while (t < lines.length && (lines[t] === '' || COMMENT.test(lines[t]))) t++;
  if (!/^= \S/.test(lines[t] ?? '')) return null;
  let end = t + 1;
  while (end < lines.length && lines[end] !== '') end++;
  const body = lines.slice(t + 1, end);
  const plain = body.every(l => (COMMENT.test(l) || ENTRY.test(l)) && !/[\\+]$/.test(l));
  return plain ? [t, end] : null;
}
export function headerStatus(text) {
  const lines = linesOf(text);
  if (lines.some(l => PREPROCESSOR.test(l) || MUTATES.test(l))) return null;
  const range = headerRange(lines);
  if (range === null) return null;
  const entries = lines.flatMap((l, i) => (STATUS_ENTRY.test(l) ? [i] : []));
  if (entries.length !== 1 || entries[0] <= range[0] || entries[0] >= range[1]) return null;
  const m = STATUS_VALUE.exec(lines[entries[0]]);
  return m ? m[1] : null;
}

// ── Both, in step ────────────────────────────────────────────────────────────
// The header's status, the section's opening word, and whether they agree (the
// section names the header's first word: "SUPERSEDED by 0007" agrees with a
// section opening "Superseded").
export function adrStatus(text) {
  const header = headerStatus(text), section = sectionStatus(text);
  return {header, section, inStep: header !== null && header.split(' ')[0] === section};
}
// Whether a record states no status at all, as far as can be shown: no line could
// set "status" (an entry in any letter case, a {set:...} or {counter:...} that
// names it, or a preprocessor directive that could bring either in), and no line
// could be a heading titled Status. A record the readers refuse is not one of
// these: its status is there but cannot be read soundly, and that fails the check.
// ({set:Status:X} sets "status"; a counter on another attribute does not.)
const SETS_STATUS = /\{(?:set|counter2?):status(?=[:!}])/i;
export function statesNoStatus(text) {
  return !linesOf(text).some(l => STATUS_ENTRY.test(l) || SETS_STATUS.test(l) || PREPROCESSOR.test(l) || mayBeStatus(l));
}
export const adrAccepted = text => {
  const s = adrStatus(text);
  return s.inStep && s.header === 'ACCEPTED';
};

// ── The check ────────────────────────────────────────────────────────────────
// Every decision record, NNNN-title.adoc with the boilerplate NNNN-template.adoc
// set aside, states its status in both places and they agree; or it states none
// at all (a status the owner has yet to set), which is reported, not refused. A
// record whose status the readers refuse to read is refused: it is not unset.
// The records are the files git tracks in docs/decisions, read at their own path
// (scripts/repo/files.mjs): a directory or a record that is a link leads out of
// the repository, so it is refused, and never read.
export function checkDecisions(root = ROOT) {
  const files = repoFiles(root);
  if (!files.isDir(DECISIONS)) return [{file: DECISIONS, problem: 'is not a directory in the repository that holds a file git tracks'}];
  const records = files.under(DECISIONS).map(p => p.slice(DECISIONS.length + 1))
    .filter(f => /^\d{4}-[^/]+\.adoc$/.test(f) && !/^\d{4}-template\.adoc$/.test(f));
  return records.map(f => {
    const p = `${DECISIONS}/${f}`;
    if (!files.isFile(p)) return {file: f, problem: 'is not a file that git tracks in the repository, at its own path'};
    const text = files.read(p);
    const s = adrStatus(text);
    if (s.inStep) return {file: f, status: s.header};
    if (statesNoStatus(text)) return {file: f, status: null};
    if (s.header === null && s.section === null) return {file: f, problem: 'it states a status that cannot be read soundly (see docs/decisions/README.adoc)'};
    return {file: f, problem: `its header says ${s.header ?? 'nothing readable'} but its Status section says ${s.section ?? 'nothing readable'}`};
  });
}

if (import.meta.main) {
  if (process.argv[2] !== 'check') { console.error('usage: adr-status.mjs check'); process.exit(2); }
  const results = checkDecisions();
  for (const r of results) console.log(`${r.problem ? 'FAIL' : 'ok  '} ${r.file}: ${r.problem ?? r.status ?? 'no status stated (the owner sets it)'}`);
  const failed = results.filter(r => r.problem);
  if (failed.length) { console.error(`adr-status: FAIL: ${failed.length} decision record(s) out of step`); process.exit(1); }
  console.log(`PASS: ${results.length} decision records; each states its status in step, or states none`);
}
