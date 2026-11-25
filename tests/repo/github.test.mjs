// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// A GitHub repository named OWNER/REPO, by GitHub's own naming rules
// (scripts/repo/github.mjs). Every generator that makes a github.com link from
// a name checks it here.
import {test, expect} from 'bun:test';
import {isGitHubRepo, GITHUB_REPO} from '../../scripts/repo/github.mjs';

test('real repository names pass', () => {
  for (const r of ['hyperpolymath/mathesis', 'metadatastician/ZenodoDeposits.jl', 'a/b', 'o/.github', 'o/a.b-c_d',
    'o/..x', 'o/x..', `${'x'.repeat(39)}/r`, `o/${'r'.repeat(100)}`, 'a-b/c', 'A1/B2']) expect(isGitHubRepo(r)).toBe(true);
});

test('a name that is not a GitHub repository is refused', () => {
  // Dot segments would make a link that a browser resolves to another page.
  for (const r of ['../..', './x', 'x/.', 'x/..', 'x/...', '../x', './.']) expect(isGitHubRepo(r)).toBe(false);
  // An owner is a login: no dot, no underscore, no hyphen at either end, at most 39.
  for (const r of ['-o/r', 'o-/r', 'o.x/r', 'o_x/r', `${'x'.repeat(40)}/r`, '/r']) expect(isGitHubRepo(r)).toBe(false);
  // A repository name: at most 100 of letters, digits, ".", "-" and "_".
  for (const r of [`o/${'r'.repeat(101)}`, 'o/', 'o/r x', 'o/r/x', 'o/r#1', 'o/r?x', 'o/r%2e', 'o', 'o/r\n']) expect(isGitHubRepo(r)).toBe(false);
  for (const r of [undefined, null, 42, ['o/r'], {}]) expect(isGitHubRepo(r)).toBe(false);
  expect(GITHUB_REPO.test('o/r')).toBe(true);
});
