# The "missing semicolon" class: trivial mechanical-correction commits

Read-only mining, 2026-11-24. Scripts in `/home/user/estate/.findings/trivial-syntax-scripts/`
(`mech.pl` -> `strict.pl` / `groups.pl` / `union.pl` / `groups_defs.pl` for commit subjects; `scan.rb` for the
HEAD working-tree residue scan). Scratch data in `/tmp/ts/` (`mech.tsv` = one row per unique non-merge hash;
`scan/*.txt` = residue lists; `ijson_all.tsv` = per-repo output of the template's `check-ijson-jcs.sh`).
Reuses `/tmp/ct/classified.tsv` from `commit-taxonomy.md` for author class.

## 0. Method, denominators, limits (read first)

* Corpus: 484 repos, `git log --all`: **96,693 commits**, 9,275 merges, **87,418 non-merge** (pair rows);
  **82,714 unique non-merge hashes** (4,704 pairs are the same commit reachable in several repos: shared
  template history). All counts below are **unique hashes** unless "per repo" is said.
* "OWN" denominator = unique non-merge hashes not authored by dependabot and not classed `third-party-human`:
  **63,292**. Third-party (`explore` fork etc., 10,202 unique) is reported separately and is flag-only; nothing
  was changed.
* Classification is by **subject regex + a fix-verb filter**, optionally `git log --name-only` file lists (trees
  only, no blobs). I did not measure diff size (numstat would fetch blobs); `<=3 files` is the only size proxy.
  A match is "the subject says so", not "verified cause". Precision was hand-sampled per class (12-25 rows each,
  see section 7): noisy classes are marked. Counts are upper bounds for the class, lower bounds for the
  phenomenon (a commit whose subject says only "fix CI" is missed).
* "AI trailer/author" = `human+AI-coauthored` or `ai-author` in the earlier taxonomy. `owner-human (no AI
  trailer)` does NOT prove no AI was involved (trailers are optional).
* Not mined: the 48 repos that failed to clone (`.clone.log`). Six private repos are depth 50.
* Residue scan (section 5) reads the checked-out HEAD of all 484 repos, skipping `node_modules vendor target
  .lake deps _build fixtures`, and is a point-in-time snapshot.
* Evidence standard: every quoted root cause below is from a commit body I read (`git log -1 --format=%B`).
  Where I infer (e.g. "the gate did not catch X"), it is marked INFERRED.

## 1. Headline numbers

Of 63,292 OWN unique commits:

| bucket | commits | repos | distinct subjects ("incidents") |
|---|---:|---:|---:|
| any group G1-G17 (including G3b, G12, G13 which are not mechanical errors) | 4,106 | n/a | 886 |
| **core syntax/format classes (G1, G2, G4-G9)** | **1,034** | | **151** |

So the core class is about 1.6% of owner-side commits (1,034 / 63,292), but it is **extremely clustered**: 151
distinct subjects account for 1,034 commits (about 6.8 commits per incident). It is not 1,034 independent
slips. It is a handful of **estate-wide sweeps and their repair sweeps**. The classic single-developer
"forgot a semicolon" commit is nearly absent (G5+G6+G7 = 27 commits OWN).

Genuinely trivial human-scale slips (typo, bracket, code syntax): **27 OWN commits** (G5 15, G6 3, G7 9). The
dominant pain is mechanical-tool-generated structural damage to config files (YAML workflows), repaired
weeks to months later.

## 2. Table by sub-class (OWN; third-party in last column)

Columns: unique commits, distinct repos, distinct subjects, commits touching <=3 files, commits with AI
trailer/author, first..last date, third-party commits (flag only).

| id | sub-class (criterion) | commits | repos | incidents | <=3 files | AI | span | 3P |
|---|---|---:|---:|---:|---:|---:|---|---:|
| G1 | workflow/YAML parse-dead repair ("unbreak workflow YAML", "parse-dead", "GitHub cannot parse it", "permissions block indentation", "invalid timeout-minutes", ...) | 521 | 281 | 41 | 344 | 412 | 2026-04-10..11-17 | 0 |
| G2 | vacuous / could-not-fail / never-ran gate repaired | 400 | 224 | 29 | 366 | 89 | 2026-04-12..11-21 | 0 |
| G3a | phantom / nonexistent reference (dead link, phantom SHA, deleted repo) | 243 | 150 | 59 | 174 | 233 | 2022-09..2026-11 | 20 |
| G3b | repoint to a relocated/renamed target (not an error, a follow-on of a rename) | 584 | 317 | 38 | 546 | 337 | 2026-04-17..11-23 | 0 |
| G4 | trailing newline / EOL / whitespace | 42 | 39 | 15 | 40 | 35 | 2026-03-24..11-19 | 3 |
| G5 | typo / spelling | 15 | 14 | 14 | 8 | 9 | 2026-02-26..07-17 | **122** |
| G6 | bracket / quote / code-fence imbalance | 3 | 3 | 3 | 3 | 1 | 2026-09-18..10-14 | 9 |
| G7 | code-language syntax / parse error fix | 9 | 9 | 9 | 7 | 6 | 2026-03-21..10-25 | 6 |
| G8 | TOML/JSON/KYAML/deed/k9/Nickel data-file syntax | 20 | 15 | 18 | 9 | 9 | 2026-02-20..11-14 | 1 |
| G9 | encoding / invisible char / BOM | 24 | 17 | 22 | 19 | 17 | 2026-02-07..11-20 | 6 |
| G10 | formatter / indent / lint mechanical (fmt, clippy, shellcheck, unused import) | 185 | 77 | 163 | 112 | 112 | 2025-12-30..11-23 | 33 |
| G11 | SPDX header add / position / malformed (excl. licence flips) | 366 | 196 | 105 | 169 | 320 | 2025-12-13..11-20 | 2 |
| G12 | licence-identifier flip sweeps (AGPL/MPL/PMPL) -- policy churn, FLAG ONLY, not a mechanical error | 872 | 328 | 167 | 327 | 779 | 2026-01-21..11-19 | 0 |
| G13 | template-placeholder left unfilled / filled later | 515 | 262 | 91 | 256 | 243 | 2025-12-18..11-15 | 1 |
| G14 | .md <-> .adoc extension/migration/rename | 90 | 66 | 19 | 57 | 86 | 2026-03-13..11-15 | 0 |
| G15 | asciidoc/markdown render syntax (heading, tree, table, fence) | 124 | 109 | 8 | 123 | 34 | 2026-03-22..11-15 | 0 |
| G16 | path / case / capitalisation | 43 | 27 | 38 | 25 | 31 | 2025-12-17..11-12 | 18 |
| G17 | trivial compile/build/import error | 50 | 24 | 47 | 23 | 47 | 2025-11-22..11-14 | 4 |

Notes on honesty of the table:
* G12 and G13 are shown only so nobody mistakes them for "typos". Licence edits are owner-only and flag-only;
  I counted, never touched. G12 is notable only because the identifier flipped repeatedly (see section 4.6).
* G3b is dominated by three sweeps (307 + 145 + 62 commits), each one commit per repo. It is rename fallout,
  not a mechanical error.
* G15 is 8 distinct subjects; 90 of its 124 are one sweep ("render the repository-structure tree as a tree").
* G10 is the noisiest class (subjects such as "style:" can be whole-codebase `cargo fmt`). Treat as indicative.
* A commit is assigned to the first matching group in the order shown, so the table partitions (G1 wins over
  G2, etc.).

## 3. By format / language (OWN; extensions of files touched by the commits in each class)

Count = number of commits in the class touching at least one file of that extension (workflow files are also
counted under `.yml`).

| class | top formats touched |
|---|---|
| G1 YAML parse-dead (521) | `.yml` 516, `actions.lock` 133 (repaired together with the lockfile), `.sh` 4, `.yaml` 2 |
| G2 vacuous gate (400) | `.yml` 391, `.sh` 24, `.adoc` 14 |
| G3a phantom reference (243) | `.yml` 151, `.adoc` 49, `.toml` 38, `.md` 30, `.scm` 20 |
| G4 newline/whitespace (42) | `.a2ml` 26 (retired format), `.sh` 7, `.yml` 6, `.js` 2, `.json` 1 |
| G5 typo (15) | `.adoc` 7, `.md` 4, `.scm` 4, `.yml` 3 |
| G7 code syntax (9) | `.rs` 4, `.jl` 2, `.json` 2, `.idr` 1 |
| G8 data syntax (20) | `.yml` 8, `.adoc` 4, `.toml` 3, `.k9` 3, `.ncl` 3, `.jl` 3, `.a2ml` 3 |
| G9 encoding (24) | `.rs` 7, `.sh` 6, `.yml` 5, `.md` 2, `.ex` 2 |
| G10 fmt/lint (185) | `.rs` 98, `.yml` 41, `.exs` 19, `.sh` 19 |
| G11 SPDX (366) | `.yml` 129, `.md` 98, `.adoc` 68, `mustfile` 65, `.zig` 59, `.a2ml` 53, `.res` 52, `.sh` 52 |
| G14 md/adoc (90) | `.adoc` 69, `.md` 48 |
| G15 render (124) | `.md` 91, `.adoc` 33 |
| G17 compile (50) | `.rs` 18, `.res` 12, `.lock` 9, `.toml` 7 |

Reading: **YAML (GitHub Actions workflows) is the single largest syntax-failure surface by an order of
magnitude** (G1+G2 = 921 commits, vs 9 for code-language syntax). Real programming-language syntax slips are
rare in the commit record (G7 = 9 OWN, 4 in Rust); Rust trivial errors are mostly `cargo fmt`/clippy (G10).

## 4. Findings by sub-class, with root causes (all quoted from commit bodies)

### 4.1 G1: workflows that are not valid YAML and "have never run" (521 commits, 281 repos)

Timeline of repair waves (commit counts by date, OWN):
`2026-05-12: 35` (workflow-linter.yml itself had a parse error) / `06-03: 8` / `07-17: 80` / `07-28: 32` /
`08-03: 38` / `08-06: 78` / `08-27: 134` / `09-15: 33` / `09-21: 66`. After 2026-10-02: **2 commits**.

Distinct causal sweeps (each wrote broken YAML into many repos; each was repaired later):

| cause (sweep) | introduced | repaired | lag | repair size |
|---|---|---|---|---:|
| `timeout-minutes` added to jobs that call reusable workflows ("ci(workflows): timeout-minutes on all jobs + fix two malformed workflows", standards#361) | 2026-06-03 | 2026-07-17 "drop invalid timeout-minutes from reusable-workflow calls (parse-dead)" | 44 days | 79 commits |
| `permissions:` added "by line position rather than by parsing the document" | July 2026 (date not pinned) | 2026-07-28 / 08-06 / 08-24 ("blind permissions insertion") | weeks | 41+38+... |
| K9-SVC step at job-level indent, introduced by "chore: automated sync of local changes" (Cladistics.jl `f9df91b`, 2026-04-08) | 2026-04-08 | 2026-08-03 `4add27c` | **117 days** | 34 commits |
| embedded `python3 -c "` heredoc body at column 0 inside a `run: \|` scalar (dogfood-gate.yml) | by 2026-07 | 2026-07-27 "repair dogfood-gate.yml -- the workflow has never run" | | 62 |
| "caller-permission campaign": permissions block indented one level too deep | 2026-09-11..21 | 2026-09-15 "unparseable permissions scalar" (33) and 2026-09-21 "repair the permissions block indentation" (66) | **0-10 days** | 99 |

Verbatim root causes:
* `blocky-writer 4db2e32` (2026-08-06): "A sweep added permission declarations **by line position rather than by
  parsing the document**. Three invalid shapes resulted: A: a mapping indented under a scalar
  (`permissions: read-all` then `  actions: read`); B: injected inside another block; C: **a literal `\n`
  that was never interpreted**, gluing the escape's `n` to the key: `npermissions:`. Only a text-level writer
  emitting an uninterpreted escape can produce that."
* Same commit: "**67 repositories and 100 workflow files are in this state.** The most frequently broken file is
  `workflow-linter.yml`, in 22 repositories ... The workflow whose job is to lint workflows was itself
  unparseable, so it never ran, and never caught this or anything else. The check that would have found the
  damage was destroyed by the same sweep that caused it."
* Same commit: "Ordinary validation cannot see this class of fault, because `yaml.safe_load` silently accepts
  duplicate keys and only a full parse catches the malformed indentation."
* `the-nash-equilibrium` (2026-07-27): "This workflow is invalid YAML ... It produces no run, no check-run, no
  annotation and no log -- not a red X, an **absence**. Nothing on a dashboard distinguishes *'this gate
  passed'* from *'this gate does not exist'*." and the embedded-language cause: "A `run: |` literal block ends
  at the first non-empty line indented *less* than the block. The Python terminates it."
* `Cytoville 123bcaa` (2026-08-27): "`gh actions-lock` refuses to run when *any* workflow in the repo fails to
  parse, so the repo can never acquire a lockfile and can never self-heal." (a second-order failure: one
  syntax error blocks the repair tool).
* `knot-rider edb57a6` (2026-09-21): "The `permissions:` block added by the caller-permission campaign was
  indented one level too deep (appended at job-child indent + 2) ... `mapping values are not allowed here`".

AI involvement: 412 of 521 carry a human+AI/AI trailer or AI author (79%); the bodies of the sweep-repair
commits (`Co-Authored-By: Claude Opus 5`) say the original damage came from scripted text-level sweeps. I did
not identify the author of every original breaking commit (introducing commits are not retrievable cheaply by
subject), so "AI caused" is **not established**; "a line-oriented text sweep caused" is established for the
quoted cases.

Gate status (which gate exists, and did failures occur after it?):
* Template `workflow-linter.yml` (present in **369 repos**, first seen 2025-12-15): I read
  `/home/user/estate/hyperpolymath/rsr-template-repo/.github/workflows/workflow-linter.yml` (187 lines). Its
  steps are: SPDX header, a `grep -q "^permissions:"` presence check, SHA-pinned actions, duplicate workflows,
  CodeQL matrix, secrets guards. **It contains no YAML parse step** (`grep -n "yaml\|parse\|yq\|actionlint"`
  matched only comments). A `grep ^permissions:` check is exactly the line-position style that the sweep
  damage defeats (INFERRED: a mis-indented block still contains a line starting `permissions:` at some level
  in some shapes).
* `actionlint`: appears in only 3 repos, first 2026-10-24, all vendored copies (`pons-asinorum/vendor/micromap-0.3.0/...`). **Not adopted as a gate.**
* standards `scripts/check-workflow-duplicate-keys.sh` + governance-reusable duplicate-key check, 2026-08-06
  (`7b04456 feat(governance): reject workflows with duplicate YAML keys (#582)`). It detects duplicate keys, not
  mis-indentation.
* `kyaml-format.sh --check`: standards 2026-10-01 (`df20618`), template 2026-10-25 (`4e66353`); applies to
  KYAML-migrated config, and the repo guidance says workflows are left alone until the lock-coverage shim is
  required (CLAUDE.md, D280). So workflow files are **outside** the KYAML ratchet by ruling.
* Before/after counts, G1 commits (group-partition basis): before the 2026-08-06 duplicate-key gate: 201; on/after: 320; before 2026-10-01 (kyaml-format.sh): 519; on/after: 2; before/after 2026-10-25: 520 / 1. The Sept 15/21 wave (99
  commits) was **created after** the Aug-06 gate existed, which supports (INFERRED) that the duplicate-key gate
  does not cover this fault. After October the count is ~0, but this is confounded: the sweeps ended, and the
  repair campaigns completed. I cannot attribute the decline to a gate.
* Residue at HEAD (section 5): 5 workflow files still fail to parse (4 repos, 2 are third-party awesome-fsharp
  forks), **14 owner workflows carry duplicate keys** (mostly a `permissions:` block with both `contents: read`
  and `contents: write`, e.g. `vcl-ut/.github/workflows/release.yml` lines 122-126, `provenance` job; YAML
  last-wins, so the effective grant is silently `write`). 14 non-workflow `.gitlab-ci.yml` files fail to parse
  (no gate covers them).

### 4.2 G2: gates that could not fail (400 commits, 224 repos, 29 incidents)

This is the "missing semicolon in the checker" class: the check itself was syntactically/semantically vacuous.
Top incidents:
* **227 commits** "fix(ci): the invisible-character gate never matched anything" (Cytoville `91bccee`,
  2026-08-31, propagated from `empty-linter#70`). Body: "Measured 2026-08-27: this gate caught **0 of 6**
  invisible-character test cases ... The pattern used UTF-8 byte sequences (`\xc2\xa0`) while `grep -P`
  matches characters ... The gate ran, passed, and could not see what it exists to see." It also notes: "a
  stray backspace byte made a workflow unparseable in `developer-ecosystem`, so it never ran".
* **86 commits** "the Hypatia gate could never fire -- 2>&1 made it unconditionally vacuous" (2026-09-04, 69+16+1).
* **62 + 38 + 14 + 8 + 2 + 2** "has never run" workflow repairs (these overlap with G1 by construction; G1 wins
  in the table partition, the G2 count here is for non-G1-worded subjects).
* Template gates: `check-invisible-characters.sh` "the invisible-character gate never matched anything (#49)" 2026-08-31;
  `check-no-placeholders.sh` "the placeholder gate could not be satisfied, so nothing obeyed it (#146)"
  2026-07-17; "Make the template's gates able to fail, and mint the toolchain (#266)" 2026-10-31
  (`check-spdx-headers.sh`); `check-adoc-renders.sh` "an AsciiDoc render gate that can actually fail" 2026-09-03.
* Proof side (same pattern): "fix(proofs): make the proof gate able to fail -- it was certifying a broken suite
  green"; "fix(just): crg-grade and crg-badge never ran (`$$` is Make, not just)".

Relevance: this class is not prevented by any syntax gate, because the gate is the thing that is broken. It is
the empirical case for gates with a mandatory **negative test** (positive/negative conformance suite) and for
"absence is not green" semantics (the-nash-equilibrium commit: "Nothing on a dashboard distinguishes this gate
passed from this gate does not exist").

### 4.3 G3a/G3b: phantom and relocated references (243 + 584 commits)

* "repoint codeql-action at a SHA that exists": 89 + 16 commits, 2026-07-27..08-11. Same-sweep body
  (`cerro-torre da62d4d`): "Phantom codeql-action SHAs. Repinned to a verified-valid v4 SHA ... The previous
  oikosbot pin `7188fc36...597a` was also only **36 hex chars rather than 40**." A 36-char "SHA" is a
  fabricated or truncated identifier, never resolvable.
* "repoint the deleted validate-actions at the live ecosystem repos": 62+3 commits, 2026-07-29.
* Rename fallout (not errors): "repoint push-email-notify to smtp-notify-action" 307 commits (2026-09-02..04);
  "repoint references to the relocated contributing guide" 145 (2026-09-19); "repoint zig gate" 19.
* Link gates: `lychee`/`link-check` workflows appear in **5 repos** only (first 2024-01-25); `check-internal-links.sh` in
  the template is first-touched 2026-11-13 with subject "drop links to files the mint deletes or that never
  existed (#355)". Dead-link fixes continue after: "docs: fix three dead internal links" (8 repos, 2026-11-14).

### 4.4 G4: trailing newline, EOL, whitespace (42 commits, 39 repos)

* 26 commits (26 repos, 2026-08-05) "fix: restore the trailing newline". Body: "The previous commit on this
  branch was written by a script that read the file through a shell command substitution. `$(...)` strips
  trailing newlines and `printf '%s'` does not put one back, so the file lost its final newline" (a tool bug,
  `Co-Authored-By: Claude Opus 5`). 26 of 42 G4 commits touch `.a2ml` files (a retired format).
* "Fix newline at end of dependabot.yml" in `stuff-of-awe` forks (3P/owner mix).
* Gate: `.editorconfig` in 436 repos and `.gitattributes` in 441 repos (mostly boilerplate from the template);
  they do not enforce final newline in CI. No dedicated gate found. HEAD residue: **336 of 6,312 .json files**
  (77 repos) and **15 of 8,005 workflow files** lack a final newline. (JSON-POLICY.adoc contains no mention of
  "newline"; the atoma commit "end four JSON files with the final newline JCS requires (#11)" asserts a
  requirement that I did not find stated in the policy file. I did not verify RFC 8785's treatment.)

### 4.5 G5/G6/G7: typos, brackets, code-language syntax (OWN 27 commits; 3P 137)

* Typos are rare on the owner side (15 OWN, last on 2026-07-17) and common only in forks (122, mostly
  `hyperpolymath/explore`, a fork of github/explore). No typo-checker gate (`codespell`/`typos`: 1 repo,
  a third-party fork `cargo-zigbuild/.codespellrc`). Owner-side typo subjects are mostly
  **tool-generated artifacts**, not human slips: `npermissions` (a `\n` never interpreted; hypatia rule WF013
  added 2026-04-03 to detect it: "Detect 'npermissions:' typo in workflow files that GitHub silently
  ignores, causing overly broad permission defaults"; instances: boinc-boinc 8 workflow files 2026-04-03,
  branch-newspaper 2026-06-25 "repair corrupted 'npermissions:' -- ci.yml couldn't parse"), the
  `.machines_readable/` typo directory (removed in ~6 "RSR compliance" commits), and "SPDX typos".
* **80 commit subjects contain a literal backslash-n** (`\n`) in the subject line, 64 repos, all OWN, e.g.
  "feat: add stapeln.toml layer-based container definition\n\nConverted from existing Containerfile ..." (75 of
  the 80 are one sweep, 2026-03-28). Same defect family as `npermissions`: an uninterpreted escape in a
  scripted writer.
* Bracket/fence balance (G6): "repair unbalanced code fences" (CONTRIBUTING, 3 repos via the template),
  "repair the unbalanced jq filter in the Hypatia findings validator" (standards `b77c53c`). 3 OWN commits in
  total.
* Code-language syntax (G7): 9 OWN commits, e.g. "Fix Idris2 parse error: doc comment cannot precede a mutual
  block" (cleave), "two genuine bash parse errors" (ambientops #334), "fix(parser): enforce trailing semicolon
  on field_decl" (typed-wasm: a *language implementation* enforcing the semicolon, not a slip). So the literal
  missing-semicolon-in-source class is **essentially not visible** in this estate's commit subjects.

### 4.6 G11/G12: SPDX headers and licence identifiers

* G11 (header add/position/malformed): 366 commits / 196 repos. The biggest are gate-driven fix waves:
  327 commits 2026-07-21 "close the governance gate -- SPDX, permissions, SHA pins, reusable bump"; 34 commits
  "add missing SPDX headers to workflow files"; 8+ commits "SPDX identifier back to line 1, after the lockfile
  step" (2026-08-07). The last shows a **tool-interaction failure**: `gh actions-lock` prepends a banner, which
  moved the SPDX line off line 1; the template linter then had to be taught three times
  (`fix(ci): SPDX check accepts the licence after the actions-lock banner` 2026-10-20, "must scan past the
  actions-lock banner" 2026-10-31, "stop the SPDX rule at an indented workflow body (#323)" 2026-11-10).
* Gates existed throughout: workflow-linter SPDX step (369 repos, from 2025-12-15), `check-spdx-headers.sh`
  (template, 2026-10-31 first touch), `REUSE.toml`/`.reuse` in 62 repos. Missing/misplaced SPDX fixes continue
  into November (13 commits in 2026-11). HEAD residue: 36 of 8,005 workflow files (22 repos) do not begin with
  an SPDX identifier in the leading comment block (7 of those are `hyperpolymath/explore`, a fork).
* G12 (flip sweeps; FLAG ONLY, I did not touch any licence): 872 OWN commits in 328 repos over 2026-01..11.
  The identifier moved MPL-2.0 -> AGPL-3.0-or-later (2026-01-09, "security: fix SPDX headers", 3 commits) ->
  PMPL-1.0-or-later (2026-03-13..16: subject clusters of 93, 89, 71, 14 and smaller commits) -> PMPL-1.0 -> PMPL-1.0-or-later (05-19, 58 commits) ->
  MPL-2.0 + CC-BY-SA-4.0 (06-07, 06-24 "normalise to MPL-2.0 + CC-BY-SA-4.0 (canonical pair)"). Each flip is a
  repo-wide mechanical edit. For the licence/metadata drift stream, this is the largest mechanical-correction
  family; ownership of that analysis is a separate stream.

### 4.7 G13/G14/G15: template placeholders and markup syntax

* G13: 515 commits mention placeholders (e.g. "replace template placeholder in ROADMAP.adoc with project name"
  34+20, "fix SPDX typos, resolve 60+ placeholders, rewrite stale SCM files"). The template's own placeholder
  gate "could not be satisfied, so nothing obeyed it" until 2026-07-17 (#146).
* G14: policy-driven format thrash. 2026-06-25: "docs(readme): convert README.adoc -> Markdown" (77+50 commits),
  then 2026-06-29 "revert(readme): restore canonical README.adoc" (29+4 commits), then 2026-09-18/19
  "converge the root allowlist with the AsciiDoc migration" and "migrate Markdown to AsciiDoc" (338 commits,
  2026-08-24, G15-adjacent; counted in table G14/G15 only partly). Net: 161 commits in 130 repos (README.adoc -> Markdown on 2026-06-25, then restored on 2026-06-29, four days later).
* G15: "render the repository-structure tree as a tree" 90 commits (2026-09-19), "Fix EXPLAINME.adoc section
  heading quotes" 16. AsciiDoc render gate (`check-adoc-renders.sh`) first appears 2026-09-03; its first
  version is described as one that "can actually fail". `markdownlint` appears in 2 repos only.

### 4.8 G8/G9/G10: data-file syntax, encoding, formatters

* G8 (20 OWN): "repair invalid/wrong TOML repo keys" (chora-registry #46), "fix k9 syntax and allowlist"
  (recon-silly-ation: 30 files), "Fix broken TOML: remove empty key artifacts from compat conversion"
  (julia-professional-registry), "TOML parse errors now report filename:line:col" (verisimiser/iseriser: a
  tool improving its own diagnostics). By month: 2026-02:1, 03:2, 05:2, 07:1, 08:2, 09:3, 10:5, 11:3. Counts:
  12 commits before k9-validate (2026-10-04), 8 on or after it (seven weeks; deed_lint 2026-10-06 and ijson-jcs 2026-10-07 fall in the same window). The per-week rate rose after the gates (about 0.4 per week over roughly 33 weeks from 2026-02-20, versus about 1.1 per week over 7 weeks after). That is what a new
  gate producing fix commits looks like (detection starts), not evidence that the gates cause errors (small numbers, so indicative only).
* G9 (24 OWN): `kyq` "marker offsets, document-marker quoting and BOM escaping (fuzz findings)", "restore Elixir
  compile by fixing broken docblocks + em-dash chars" (hypatia `210b92a`), "fix unicode bom scan" (bqniser).
  Invisible-char gate vacuity (G2) is the major related family.
* G10 (185): `cargo fmt`/`clippy`/`shellcheck` fixes; 98 of the 185 touch `.rs`. `rustfmt.toml`/clippy config in
  191 repos (first 2025-11-22) and `rust-ci.yml` exist, yet "style: run cargo fmt" and clippy-version
  fallout (e.g. "collapsible_match rust 1.95", "clippy 1.97") recur: formatter output depends on toolchain
  version, so a pinned toolchain is the lever (INFERRED from subjects).

## 5. HEAD-of-tree residue (point-in-time scan, `scan.rb`)

Scanned: 8,005 workflow files, 11,176 other YAML files, 6,312 `.json`, 353 `.deed` (skipped vendored dirs).
Parsers: Ruby Psych 5.1.2 (YAML), Ruby JSON (strict RFC 8259, not I-JSON). Caveat: Psych is a YAML 1.1 parser
and many Helm/Jinja-templated YAMLs legitimately fail; I report counts, not verdicts.

| check | files | repos |
|---|---:|---:|
| workflow YAML fails to parse | 5 / 8,005 | 4 (`cloudguard-server` and `rrecord-verity` `dogfood-gate.yml`, `pimcore-fortress` `main-estate-audit.yml`, 2 in third-party `stuff-of-awe/awesome-fsharp`) |
| workflow YAML with a duplicate mapping key | 14 / 8,005 | 14 (13 are `contents:` read+write in one `permissions:` block) |
| workflow lacking SPDX identifier in leading comment block | 36 / 8,005 | 22 |
| workflow lacking final newline | 15 / 8,005 | 14 |
| non-workflow YAML fails to parse | 79 / 11,176 | 26 (38 in `developer-ecosystem`, 14 are `.gitlab-ci.yml`, others Helm/templated, so many are false positives) |
| `.json` fails strict parse | 24 / 6,312 | 5 (13 are 0-byte files; 9 in `gitbot-fleet/.../self-scans/*.json` are raw ANSI log output written to `.json` via `2>&1`; 1 is a `jsconfig.json` with `//` comments (JSONC); 1 cargo NDJSON `.json`) |
| `.json` lacks final newline | 336 / 6,312 | 77 (107 in `verisimdb-data`) |
| `.deed` with unbalanced parentheses (crude heuristic, not `deed_lint`) | 6 / 353 | 2 (`affinescript`: 4, `panoply`: 2). Heuristic may be fooled by char literals; confirm with `deed_lint.js` before acting |
| `^npermissions:` residue in a workflow | 0 | 0 (fixed everywhere it was found) |

See section 6 for the ijson-jcs run.

## 6. The estate gates versus this class (inventory)

Dates are first appearance in git history (blobless clones; commits with the file path in the tree).
"Fires on" is what I verified by reading the file or commit.

| gate | first seen | repos | covers | does not cover (verified/INFERRED) |
|---|---|---:|---|---|
| `workflow-linter.yml` (template) | 2025-12-15 | 369 | SPDX line, `permissions:` presence by grep, SHA pins | **no YAML parse** (verified by reading the 187-line file) |
| `check-workflow-duplicate-keys.sh` (standards) | 2026-08-06 | via reusable | duplicate keys | indentation / scalar-with-children |
| `kyaml-format.sh --check` | 2026-10-01 std / 2026-10-25 template | 39 repos with `.kyaml` | KYAML config | workflows (ruled out until D280 shim) |
| `check-ijson-jcs.sh` | 2026-10-07 std (report-only) / 2026-10-25 template | 42 | I-JSON + JCS for `.json/.jsonl` | `--enforce` is opt-in; see section 6.1 |
| `deed_lint.js` (bun port) | 2026-10-06 | 57 repos reference `deed-ecosystem` | deed grammar | |
| `k9-validate.sh` | 2026-10-04 (script elsewhere from 2026-02-22) | 191 | k9/Nickel contracts | |
| `empty-linter` | repo 2026-01-13; used in 58 repos | 58 | empty/invisible content | gate was vacuous until 2026-08-31 (G2) |
| `actionlint` | 2026-10-24 | 3 (vendored only) | | not adopted |
| `yamllint` | 2025-11-22 | 3 | | not adopted |
| link checker (`lychee`, `link-check`) | 2024-01 | 5 | | template internal-link check only from 2026-11-13 |
| typo checker (`codespell`, `typos`) | 2022-02 | 1 (third-party fork) | | none in the owner's repos |
| `markdownlint` | 2026-04-04 | 2 | | |
| AsciiDoc render gate | 2026-09-03 | template | | |
| hypatia WF013 (`npermissions:`) | 2026-04-03 | scanner | one specific uninterpreted-`\n` artifact | |
| `.editorconfig` / `.gitattributes` | 2018 / 2019 (boilerplate) | 436 / 441 | editor hints | not enforced in CI |
| pre-commit / githooks | 2025-11-13 | 239 | | |

Per sub-class, before/after the gate (only where a gate with a dated introduction exists):

| class | gate | commits before | commits on/after | reading |
|---|---|---:|---:|---|
| G1 YAML parse | duplicate-keys 2026-08-06 | 201 | 320 | faults continued (Sept wave); gate does not target them (INFERRED) |
| G1 YAML parse | kyaml-format 2026-10-01 | 519 | 2 | sweeps ended; not attributable to a gate |
| G8 data syntax | k9-validate 2026-10-04 | 12 | 8 (7 weeks) | gate introduction produces fix commits |
| G9 encoding/invisible | fixed invisible-char gate 2026-08-31 | 10 | 14 | more fix commits after the gate started working (small numbers; 24 total) |
| G11 SPDX | workflow-linter SPDX step 2025-12-15 | 1 | 365 | the gate predates almost all of the class; 355 of 366 fall before 2026-10-25 and 11 on or after (the template `check-spdx-headers.sh` was first touched 2026-10-31); waves are repairs of repo-wide edits, not slips |
| G5 typo | (no gate exists) | 15 | 0 after 2026-07-18 | owner-side typos stopped appearing in subjects with no gate; consistent with sweeps ending, not with prevention |

### 6.1 ijson-jcs report-only run (template script `check-ijson-jcs.sh`, no `--enforce`)

Run over all 484 repos on 2026-11-24 with `/home/user/estate/hyperpolymath/rsr-template-repo/scripts/check-ijson-jcs.sh .`
(report-only; the local Bun RFC 7493/8785 implementation; per repo output in `/tmp/ts/ijson_all.tsv`).
481 repos returned a summary line. (3 repos, `echidna`, `hypatia`, `verisimdb-data`, did not: their last output line was a
per-file `NOT CANONICAL ...jsonl` line, so their totals are missing; likely the 120 s per-repo timeout. They are excluded.)

| measure | value |
|---|---:|
| repos with a summary line | 481 |
| repos containing checked `.json`/`.jsonl` | 443 |
| JSON / JSON Lines files checked | 6,239 |
| canonical (I-JSON + JCS byte-identical) | 745 |
| **not canonical** | **5,431** |
| **invalid (not I-JSON)** | **63** |
| repos with at least one non-canonical or invalid file | 415 |

Reading: 5,494 of 6,239 checked JSON files (5,431 not canonical plus 63 invalid) do not satisfy the D306 ruling of 2026-10-07. This is a measure of
the **pre-ruling state against a gate that was introduced report-only**, not a measure of mistakes: JCS requires
sorted keys and no insignificant whitespace, so ordinary pretty-printed JSON is "not canonical" by construction.
Failures before the gate: effectively all of them (the gate is 7 weeks old and `--enforce` is opt-in); failures
after the gate: the new JSON written since 2026-10-25 was not separately measured. 63 invalid files are the
genuinely syntactic failures (my own Ruby strict-JSON pass found 24 parse failures, 13 of them zero-byte files,
the two scans use different definitions and scopes: I-JSON additionally rejects duplicate keys, lone surrogates
and out-of-range numbers).


## 7. Precision of the classes

I read 12-25 random subjects for each of the classes G1, G2, G4, G5, G6, G7, G8 and the large clusters of G3, G10, G11, G15, and judged them by eye; I did not keep a per-row tally, so I give a verdict, not a percentage.

* G1: high. All sampled rows were true parse repairs. G2: high for the top incidents (each quotes a measured vacuity); the long tail is proof-vacuity work, a different phenomenon, included deliberately.
* G3a: medium (some rows are feature changes that mention a link). G3b: high, but these are rename fallout, not errors.
* G4: high. G5: on the owner side most subjects are tool artifacts or sweeps that mention "typo" (npermissions, `.machines_readable/`), not human slips.
* G6: the 3 rows are real. G7: medium (some of the 9 are language-implementation features about syntax). G8: medium (a number are validator features that mention JSON/TOML).
* G10: low to medium (noisy; includes whole-codebase `cargo fmt` and clippy-version fallout). G11: high for add/position/malformed, but the waves are sweeps. G12-G14: not "errors", shown for scale.
* An earlier broad-regex pass (`/tmp/ts/cand.tsv`, 4,258 rows) was discarded for low precision ("typo dir", "feat: add SPDX", "fix formatting of README").

## 8. What the data says for the programme (grounded, with evidence level)

1. **The "missing semicolon" class in this estate is overwhelmingly a missing-parse-check on structured config
   rewritten by line-oriented scripts**, not human syntax slips. Evidence: root causes quoted in 4.1 (line
   position, `\n` literal, `$(...)` newline stripping, column-0 heredoc in a YAML block scalar, scalar with an
   indented child). 521 G1 commits in 281 repos from about 5 sweeps. STATED (commit bodies) + COUNTED.
2. **Failure is silent**: a parse-dead workflow produces no run, no check, no log. Repairs lag the cause by
   44 and 117 days in the two cases I could date. That is the cost driver (CI that never ran) rather than the
   one-line fix itself.
3. **Gates themselves carry the same class**: G2 (400 commits) shows gates that cannot fail, and the sweep
   destroyed `workflow-linter.yml` in 22 repos (verbatim). A type or schema is only worth having if it comes with
   negative fixtures; the estate learned this empirically from 2026-07 to 2026-10 (several "able to fail"
   commits).
4. **Embedded languages in YAML** (Python in `run: |`, jq filters, grep -P patterns) account for at least 3
   distinct repaired incidents (dogfood-gate 62, unbalanced jq 1, invisible-char pattern 227). Nothing in the
   estate types the embedded fragment; bytes-versus-characters in a `grep -P` pattern is exactly a string-typed
   failure.
5. **Duplicate keys are a live, silent semantic hazard**: 14 current workflow files carry two `contents:`
   entries; YAML last-wins picks `write`. A schema with unique keys (or linear field use) rejects this; the
   Aug-06 duplicate-key gate apparently did not reach these files in the Sept-21 campaign (INFERRED from
   residue created after the gate date; I did not run the gate).
6. **Fabricated identifiers**: "SHA" strings of 36 hex characters and pins to deleted repos (G3a: 243
   commits). A fixed-width hex newtype/refinement and an existence check would catch the first; the second
   needs a registry lookup.
7. **Fan-out is the shape of the data**: 151 incidents -> 1,034 commits. A fix at the origin (template,
   sweep tool) plus a typed writer for workflows would remove most of the class. Owner-side single-file
   typos are 15 commits.
8. **Not found / negative results**: no commit-subject evidence of a literal missing semicolon/brace in
   application source beyond 9 G7 and 3 G6 commits; no typo gate on owner repos; `actionlint` and `yamllint`
   not adopted; no `CLADE.deed` anything relevant; no evidence in this data of a CRLF problem (subjects mentioning CRLF/line endings with a fix verb: 4 OWN, 3 third-party).

## 9. Reproduce

```
cd /tmp/ts
perl mech.pl > mech.tsv                       # unique non-merge hashes, date, files, class
perl strict.pl < mech.tsv > strict.tsv        # strict primary class
perl groups.pl < mech.tsv                     # section 2 table (OWN and 3P)
perl union.pl < mech.tsv                      # section 1 totals
perl groups_defs.pl < mech.tsv                # section 3 format breakdown
ruby scan.rb                                  # section 5 residue (writes /tmp/ts/scan/*.txt)
```
Inputs: `/tmp/ct/classified.tsv` (commit-taxonomy), `/tmp/ts/dates.tsv`, `/tmp/ts/allfiles.tsv`
(`git log --all --no-merges --no-renames --name-only`). No file in any clone was modified.
