// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
//
// The files of the repository, as the generators may read them.
//
// A generator that checks evidence, or copies a file into the site, reads only
// what a reviewer can read in the commit: a file that git tracks, at its own
// path. So a path counts only when
//   - git tracks it (it is in the index): nothing untracked, nothing in .git;
//   - no part of it is a link: the file system holds, at that very path, what
//     the path names, so nothing is read from outside the repository;
//   - it is a regular file, or, where a directory may be named, a directory that
//     holds a tracked file.
// The answer is the same in a clone and in a linked worktree, where .git is a file.
//
// The generated views are the one exception: a generator writes them before git
// tracks them, so `local` reads and checks a path with the same link rule but
// without asking git.
import {readFileSync, realpathSync, statSync, lstatSync, accessSync, constants} from 'node:fs';
import {spawnSync} from 'node:child_process';
import path from 'node:path';

// Find a program in the absolute directories of PATH, and run it by that absolute
// path, so no relative PATH entry (such as ".") can pick the program. As a shell
// does, it passes over anything there by that name that is not a regular file
// it may run (a directory, a plain file without the execute bit).
const runnable = f => {
  try {
    accessSync(f, constants.X_OK);
    return statSync(f).isFile();
  } catch { return false; }
};
export function findProgram(name, env = process.env) {
  for (const d of (env.PATH || '').split(path.delimiter)) {
    if (path.isAbsolute(d) && runnable(path.join(d, name))) return path.join(d, name);
  }
  throw new Error(`${name} not found in an absolute directory of PATH`);
}

// The paths git tracks in the checkout at `base`, which must be the top of its
// work tree, relative to it. Only git's closing newline is cut from the path it
// prints: a directory name may itself end in white space.
function trackedPaths(base) {
  const git = args => spawnSync(findProgram('git'), ['-C', base, ...args], {encoding: 'utf8', maxBuffer: 1 << 28});
  const top = git(['rev-parse', '--show-toplevel']);
  if (top.error || top.status !== 0 || realpathSync(top.stdout.replace(/\n$/, '')) !== base) {
    throw new Error(`${base} is not the top of a git checkout; the files read here are the files git tracks`);
  }
  const ls = git(['ls-files', '-z', '--full-name']);
  if (ls.error || ls.status !== 0) throw new Error(`git ls-files failed in ${base}`);
  return new Set(ls.stdout.split('\0').filter(Boolean));
}

// Repository text is UTF-8, decoded strictly: a malformed byte is an error, never
// a silent U+FFFD, so what a generator reads is exactly what is committed. A byte
// order mark is kept as a character, so a check sees it.
const UTF8 = new TextDecoder('utf-8', {fatal: true, ignoreBOM: true});
const decode = (buf, p) => {
  try { return UTF8.decode(buf); } catch { throw new Error(`${p} is not valid UTF-8`); }
};

export function repoFiles(root) {
  const base = realpathSync(root);
  // git is asked once, when a check first needs the answer.
  let tracked = null;
  const trackedSet = () => {
    if (tracked === null) tracked = trackedPaths(base);
    return tracked;
  };
  const isTracked = p => trackedSet().has(p);
  const holdsTracked = p => [...trackedSet()].some(t => t.startsWith(`${p}/`));
  // The full path of p when p is a relative path to something inside the
  // checkout, below its top: "", ".", "..", an absolute path, or a path that
  // climbs out is null.
  const within = p => {
    if (typeof p !== 'string' || p === '' || path.isAbsolute(p)) return null;
    const full = path.join(base, p);
    const rel = path.relative(base, full);
    return rel !== '' && rel !== '..' && !rel.startsWith(`..${path.sep}`) ? full : null;
  };
  // What stands at the path itself, inside the checkout, when no part of it is a
  // link; else null.
  const at = p => {
    const full = within(p);
    if (full === null) return null;
    try { return realpathSync(full) === full ? statSync(full) : null; } catch { return null; }
  };
  const isFile = p => isTracked(p) && at(p)?.isFile() === true;
  const isDir = p => at(p)?.isDirectory() === true && holdsTracked(p);
  const bytes = p => {
    if (!isFile(p)) throw new Error(`${p} is not a file that git tracks in the repository`);
    return readFileSync(path.join(base, p));
  };
  const localFile = p => at(p)?.isFile() === true;
  return {
    root: base,
    isFile,
    isDir,
    // A file or a directory: a ref may name either.
    exists: p => isFile(p) || isDir(p),
    bytes,
    read: p => decode(bytes(p), p),
    // The tracked paths under a directory, in the order git lists them (sorted).
    under: dir => [...trackedSet()].filter(t => t.startsWith(`${dir}/`)),
    local: {
      isFile: localFile,
      isDir: p => at(p)?.isDirectory() === true,
      // Nothing at all stands at the path, not even a link that leads nowhere. A
      // path outside the checkout is never absent: nothing may be made there.
      isAbsent: p => {
        const full = within(p);
        if (full === null) return false;
        try { lstatSync(full); return false; } catch { return true; }
      },
      read: p => {
        if (!localFile(p)) throw new Error(`${p} is not a plain file inside the repository`);
        return decode(readFileSync(path.join(base, p)), p);
      },
    },
  };
}
