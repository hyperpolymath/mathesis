// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// A GitHub repository named OWNER/REPO, by GitHub's own naming rules.
//
// Every generator that writes a github.com link from a repository name, or
// clones one, checks the name here first. A looser rule let "../.." through,
// and a link such as https://github.com/../../blob/c/x resolves, in a browser,
// to a page of some other repository.
// - OWNER, a user or organisation login: 1 to 39 letters, digits and single
//   hyphens, with no hyphen at either end and never two in a row.
// - REPO: letters, digits, ".", "-" and "_", 1 to 100, and not dots alone:
//   GitHub has no repository named "." or "..".
export const GITHUB_REPO = /^(?=[A-Za-z0-9-]{1,39}\/)[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*\/(?!\.+$)[A-Za-z0-9._-]{1,100}$/;
export const isGitHubRepo = s => typeof s === 'string' && GITHUB_REPO.test(s);
