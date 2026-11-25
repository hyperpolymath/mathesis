// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// What the generators may read from the repository: a file that git tracks, at
// its own path, with no link along it (scripts/repo/files.mjs).
import {test, expect, afterAll} from 'bun:test';
import {mkdtempSync, mkdirSync, writeFileSync, rmSync, symlinkSync, chmodSync} from 'node:fs';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {repoFiles, findProgram} from '../../scripts/repo/files.mjs';

const dirs = [];
afterAll(() => { for (const d of dirs) rmSync(d, {recursive: true, force: true}); });
const temp = prefix => { const d = mkdtempSync(path.join(tmpdir(), prefix)); dirs.push(d); return d; };
const git = (root, ...args) => {
  const r = Bun.spawnSync(['git', '-C', root, '-c', 'init.defaultBranch=main', ...args]);
  if (r.exitCode !== 0) throw new Error(`git ${args.join(' ')}: ${r.stderr}`);
};
// A checkout: README.adoc, docs/a.adoc and docs/sub/b.adoc tracked, docs/loose.adoc and the
// directory doc/ (a prefix of docs) holding only an untracked file.
function checkout() {
  const root = temp('repo-files-');
  mkdirSync(path.join(root, 'docs/sub'), {recursive: true});
  mkdirSync(path.join(root, 'doc'));
  mkdirSync(path.join(root, 'empty'));
  writeFileSync(path.join(root, 'README.adoc'), 'r\n');
  writeFileSync(path.join(root, 'docs/a.adoc'), 'a\n');
  writeFileSync(path.join(root, 'docs/sub/b.adoc'), 'b\n');
  git(root, 'init', '-q');
  git(root, 'add', '-A');
  writeFileSync(path.join(root, 'docs/loose.adoc'), 'loose\n');
  writeFileSync(path.join(root, 'doc/x.adoc'), 'x\n');
  return root;
}

test('a file counts when git tracks it and it stands at its own path', () => {
  const root = checkout();
  const files = repoFiles(root);
  expect(files.isFile('docs/a.adoc')).toBe(true);
  expect(files.read('docs/sub/b.adoc')).toBe('b\n');
  expect(files.bytes('docs/a.adoc')).toEqual(Buffer.from('a\n'));
  // Untracked, in .git, absent, or not a path at all: not a file of the repository.
  for (const p of ['docs/loose.adoc', '.git/HEAD', '.git/config', 'docs/none.adoc', '', 42, undefined]) {
    expect(files.isFile(p)).toBe(false);
    expect(files.exists(p)).toBe(false);
  }
  expect(() => files.read('docs/loose.adoc')).toThrow(/^docs\/loose\.adoc is not a file that git tracks in the repository$/);
  // A tracked path that is now a directory is not a file.
  rmSync(path.join(root, 'docs/a.adoc'));
  mkdirSync(path.join(root, 'docs/a.adoc'));
  writeFileSync(path.join(root, 'docs/a.adoc/inner'), 'x\n');
  expect(files.isFile('docs/a.adoc')).toBe(false);
});

test('a directory counts when it stands at its own path and holds a tracked file', () => {
  const root = checkout();
  const files = repoFiles(root);
  expect(files.isDir('docs')).toBe(true);
  expect(files.isDir('docs/sub')).toBe(true);
  expect(files.exists('docs/sub')).toBe(true);
  // An empty directory, one holding only untracked files, and one whose name is a
  // prefix of a tracked directory's (doc, beside docs) hold no tracked file.
  for (const p of ['empty', 'doc', 'docs/sub/b.adoc']) {
    expect(files.isDir(p)).toBe(false);
    if (p !== 'docs/sub/b.adoc') expect(files.exists(p)).toBe(false);
  }
  // A tracked directory gone from the checkout is not one.
  rmSync(path.join(root, 'docs/sub'), {recursive: true});
  expect(files.isDir('docs/sub')).toBe(false);
  expect(files.exists('docs/sub')).toBe(false);
  expect(files.under('docs')).toEqual(['docs/a.adoc', 'docs/sub/b.adoc']);
});

test('no link along a path counts, even one git tracks that stays inside', () => {
  const root = checkout();
  const outside = temp('repo-files-out-');
  writeFileSync(path.join(outside, 'secret.adoc'), 'secret\n');
  symlinkSync(path.join(outside, 'secret.adoc'), path.join(root, 'docs/out.adoc'));
  symlinkSync('a.adoc', path.join(root, 'docs/in.adoc'));
  symlinkSync('docs', path.join(root, 'linked'));
  git(root, 'add', '-A');
  const files = repoFiles(root);
  for (const p of ['docs/out.adoc', 'docs/in.adoc', 'linked/a.adoc']) {
    expect(files.isFile(p)).toBe(false);
    expect(files.local.isFile(p)).toBe(false);
    expect(() => files.read(p)).toThrow(/is not a file that git tracks/);
    expect(() => files.local.read(p)).toThrow(/is not a plain file inside the repository/);
  }
  expect(files.isDir('linked')).toBe(false);
  expect(files.local.isDir('linked')).toBe(false);
});

test('local paths: plain files and directories inside, tracked or not', () => {
  const root = checkout();
  const files = repoFiles(root);
  expect(files.local.isFile('docs/loose.adoc')).toBe(true);
  expect(files.local.read('docs/loose.adoc')).toBe('loose\n');
  expect(files.local.isDir('empty')).toBe(true);
  expect(files.local.isDir('')).toBe(false);
  expect(files.local.isFile('empty')).toBe(false);
  expect(files.local.isAbsent('docs/none.adoc')).toBe(true);
  expect(files.local.isAbsent('docs/a.adoc')).toBe(false);
  // A link that leads nowhere is not absent: something stands at the path.
  symlinkSync(path.join(root, 'nowhere'), path.join(root, 'dangling'));
  expect(files.local.isAbsent('dangling')).toBe(false);
  expect(files.local.isFile('dangling')).toBe(false);
});

// git prints the top of the checkout with a closing newline, which is cut; white
// space that ends the directory's own name is part of the path and is kept.
test('a checkout whose name ends in white space is read like any other', () => {
  const root = path.join(temp('repo-files-ws-'), 'repo \t ');
  mkdirSync(path.join(root, 'docs'), {recursive: true});
  writeFileSync(path.join(root, 'docs/a.adoc'), 'a\n');
  git(root, 'init', '-q');
  git(root, 'add', '-A');
  expect(repoFiles(root).read('docs/a.adoc')).toBe('a\n');
});

test('only the top of a git checkout is read, and a failing git fails loudly', () => {
  const bare = temp('repo-files-nogit-');
  expect(() => repoFiles(bare).isFile('x')).toThrow(/is not the top of a git checkout/);
  const root = checkout();
  expect(() => repoFiles(path.join(root, 'docs')).isFile('a.adoc')).toThrow(/is not the top of a git checkout/);
  // An index git cannot read: git rev-parse still answers, git ls-files does not.
  writeFileSync(path.join(root, '.git/index'), 'not an index');
  expect(() => repoFiles(root).isFile('docs/a.adoc')).toThrow(/^git ls-files failed in /);
});

test('a program is found only in an absolute directory of PATH', () => {
  const bin = temp('repo-files-bin-');
  writeFileSync(path.join(bin, 'prog'), '#!/bin/sh\n');
  chmodSync(path.join(bin, 'prog'), 0o755);
  expect(findProgram('prog', {PATH: `/nonexistent${path.delimiter}${bin}`})).toBe(path.join(bin, 'prog'));
  // The same directory named relatively is passed over.
  expect(() => findProgram('prog', {PATH: path.relative(process.cwd(), bin)})).toThrow(/^prog not found in an absolute directory of PATH$/);
  expect(() => findProgram('prog', {})).toThrow(/not found/);
});
