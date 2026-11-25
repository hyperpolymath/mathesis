# Commit taxonomy: fix/repair commits across the estate

Read-only mining, 2026-11-24. Scripts: `/home/user/estate/.findings/commit-taxonomy-scripts/`
(`dump.sh` -> `classify.pl` -> `agg.pl` / `q.pl` / `chains.pl`; scratch outputs in `/tmp/ct/`:
`classified.tsv`, `agg.txt`, `fanout.tsv`, `names.txt`). Perl only, no installs.

## 0. Method and limits (read first)

* Scope: all 484 repos in `.stats.tsv`. `git log --all` over every ref gives **96,693 commits**
  (`.stats.tsv` sums to 93,345 because it counts the default branch only; `git rev-list --all --count`
  summed over the repos equals 96,693, so the dump is complete). 9,275 of them are merge commits.
* Chains use `git log HEAD --no-merges --no-renames --name-only` = **84,404 commits** (HEAD only, no renames,
  so no lazy blob fetches).
* Classification is by subject regex only, so tags are heuristic and non-exclusive. A hit means "the
  subject says so", not "verified cause". Spot checks (random 12 per tag for syntax/conflict/ai_honesty/
  drift/typo) show real precision problems: `conflict` catches "conflict resolution" features,
  `drift` catches "stale.yml", `syntax` catches "syntax extensions" in an awesome-list. Treat counts as upper
  bounds, ranks as indicative.
* `fix` = subject matches fix/fixes/fixed/bugfix/hotfix/repair; "fix/revert-worded" = fix or revert tag.
  Fix commits with no such word (e.g. "Restore canonical proof resolution") are missed. Lower bound.
* Author classes (my definitions, from `%an/%ae` and the `Co-Authored-By` trailer via
  `%(trailers:key=Co-Authored-By)`; no body sampling was needed):
  `dependabot`, `github-actions`, `ai-author` (author is Claude / anthropic.com email), `other-bot`
  (coderabbit, arena, rhodibot, hypatia, ...), `human+AI-coauthored` (owner identity plus an AI/bot trailer),
  `other-coauthored`, `owner-human(no AI trailer)` (owner identity, no trailer), `third-party-human`.
  "owner-human" means no AI trailer was found, NOT proof that no AI was involved (trailers are optional).
* Forks pollute `third-party-human`. `hyperpolymath/explore` alone is 10,752 commits (a fork of github/explore,
  remote `[blob:none]`); it contributes most third-party merges and typo fixes. Third-party rows are
  not the owner's behaviour. Per licence policy these are flag-only, I changed nothing.
* Not mined: the 48 repos that failed to clone (`.clone.log`).

## 1. Totals and author classes (denominator 96,693)

| class | commits | fix/revert-worded | share of class |
|---|---:|---:|---:|
| human+AI-coauthored | 35,684 | 9,880 | 27.7% |
| owner-human (no AI trailer) | 30,371 | 7,092 | 23.4% |
| third-party-human | 16,050 | 1,311 | 8.2% |
| dependabot | 9,897 | 0 | 0.0% |
| ai-author | 2,816 | 761 | 27.0% |
| other-bot | 750 | 285 | 38.0% |
| other-coauthored | 737 | 113 | 15.3% |
| github-actions | 388 | 1 | 0.3% |
| **total** | **96,693** | **19,443** | **20.1%** |

Of the 96,693 commits, 47,594 (49.2%) carry a Co-Authored-By trailer. Trailer names, top: dependabot[bot]
8,124; Claude Opus 4.6 (1M) 7,114; Claude Opus 4.7 (1M) 6,037; Claude 4,192; Claude Opus 5 2,998;
Claude Opus 4.8 2,650; Claude Opus 5.5 2,328; Claude Sonnet 4.6 1,900; Claude Fable 5 1,349; also
arena-agent 847, Mistral Vibe 582, rhodibot 222, stage5-sweep 289, hypatia-autofix 54.
Fix rate for AI-involved human commits (27.7%) is higher than for owner commits without trailer (23.4%);
this is confounded (AI work is concentrated in the 2026 CI/governance campaign, section 4) and is not evidence
that AI causes more fixes.

## 2. Tag counts (non-exclusive; denominator 96,693; "in-fix" = also fix/revert-worded, denominator 19,443)

| tag | commits | in-fix | notes / example hashes (repo) |
|---|---:|---:|---|
| ci | 21,803 | 8,904 | 001980353 (688-attack-hub) restore reachable standards workflow pins |
| fix | 19,287 | 19,287 | |
| bump | 12,929 | 1,170 | 9,715 are dependabot |
| deps | 12,840 | 874 | |
| security | 11,888 | 4,593 | 839b0d4ce (688-attack-hub) |
| docs | 10,543 | 1,010 | |
| workflow | 9,925 | 3,265 | |
| merge | 7,877 | 570 | 5,813 are third-party-human (fork `explore`) |
| pinning | 6,134 | 2,601 | |
| a2ml_deed | 5,221 | 1,427 | 0c78d9406, a0b6e3d9e (Cytoville) |
| licence | 4,858 | 1,661 | |
| rename | 4,392 | 674 | |
| template_sync | 3,809 | 656 | 1d2f98b22 (Cytoville), d5e24a2ba (airborne-submarine-squadron) |
| proof | 2,763 | 610 | f3c9be622 (Cytoville) Agda `--without-K --cubical-compatible` |
| link_path | 2,407 | 654 | |
| placeholder | 1,790 | 884 | ce98aacf7 (688-attack-hub) |
| drift | 1,742 | 755 | 0754e147d (Cytoville) resync actions.lock |
| test_fail | 1,384 | 749 | |
| build_break | 1,358 | 832 | |
| lockfile | 1,296 | 875 | 8c5ae06cc, 0754e147d (Cytoville) |
| lint | 1,192 | 632 | |
| format | 1,144 | 409 | |
| ai_honesty | 778 | 513 | 49198f6ff, 07c44830b |
| sign | 678 | 79 | |
| syntax | 193 | 124 | db1eaf10e, 9ddfde83e (IDApTIK) |
| conflict | 186 | 69 | 4dc019e71 (Cytoville) |
| revert | 185 | 185 | 1d7322189, 05ffe3678 (Cytoville) |
| typo | 154 | 109 | 132 of 154 third-party-human (fork noise) |
| skip_ci | 10 | 1 | |

Full tag x author-class matrix: `/tmp/ct/agg.txt` section "tag x class counts". Key cells: `merge` is
third-party 5,813 vs owner 1,840 vs AI-coauthored 53; `typo` is third-party 132 of 154;
`a2ml_deed` github-actions 206 (its own bot commits); `licence` AI-coauthored 3,047 vs owner 1,561.

## 3. Top 25 recurring failure classes (fix/revert-worded commits, denominator 19,443)

Ranked by count of fix/revert-worded commits carrying the tag (non-exclusive). Sharper
sub-classes from `q.pl` (regex over all 96,693 subjects) are in the right column.

| # | class | fix-worded commits | sharper sub-signal (all commits; repos) |
|---|---|---:|---|
| 1 | CI / workflow breakage | 8,904 | startup_failure 337 commits / 219 repos (e.g. 8b7e3b538, 910d0b361); invalid YAML / parse / never-ran 645 / 288 |
| 2 | Security-gate repair (permissions, scanners, scorecard) | 4,593 | |
| 3 | Workflow files (.github) | 3,265 | |
| 4 | Pin / SHA repair | 2,601 | pin-or-sha repair wording 2,775 / 409 repos |
| 5 | Licence / SPDX | 1,661 | licence A->B flips 896 / 310 repos (e.g. 04997b916); `fix spdx headers: agpl->pmpl` 95 copies |
| 6 | a2ml / deed / contractile | 1,427 | a2ml removal/migration 573 / 266; deed grammar/lint 300 / 228 |
| 7 | Dependency bump handling | 1,170 | fix-after-bump wording 1,034 / 383; revert of bump 26; bump breaks 32 |
| 8 | Docs repair | 1,010 | |
| 9 | Placeholder / stub / unfilled template | 884 | 1,594 / 367 repos overall |
| 10 | Lockfile / actions.lock desync | 875 | regen/resync/reconcile wording 697 / 286 |
| 11 | Build broken | 832 | |
| 12 | Drift | 755 | |
| 13 | Failing tests / timeouts | 749 | flaky/timeout/retry/race 611 / 296 |
| 14 | Link / path / missing | 654 | dead/broken link, repoint 1,026 / 377 |
| 15 | Template sync | 656 | canonical/template-sync wording 3,849 / 426; RSR-compliance chore 784 / 256 |
| 16 | Rename / move / migrate | 674 | format migrations 439 / 208 |
| 17 | Lint | 632 | |
| 18 | Proof-gate repair | 610 | |
| 19 | Merge (fix-worded merges) | 570 | |
| 20 | AI-error wording (wrong/phantom/fake/honest/actually/inflated) | 513 | fabricated or non-existent refs (fake/phantom SHA, pin, action, path) 339 / 199 repos; hallucinat/fabricat/overclaim words only 31 / 21 |
| 21 | Format | 409 | |
| 22 | Revert | 185 | 139 commits start with/contain revert, 74 repos |
| 23 | Syntax | 124 | explicit missing-semicolon/paren/brace/unbalanced: 21 / 12 repos |
| 24 | Typo | 109 | mostly fork `explore` |
| 25 | Signing | 79 | signing/unverified wording 11 / 8 |
| - | Merge-conflict resolution | 69 | resolve/fix conflict or markers 123 / 73 |

Example hashes for each tag: `/tmp/ct/tag_examples.txt`. Concrete exemplars:

* Fabricated structure by SHA: `de23edac5` (Cytoville) "repin governance-reusable off phantom SHA 8f31a5a4";
  `839b0d4ce` (688-attack-hub) "repoint codeql-action at a SHA that exists"; `de8395e24` (PostDisciplinary.jl)
  "repin standards to a SHA that exists (5b1d0022 is nonexistent)"; `8d985ce58` (blue-screen-of-app)
  "replace fake action SHA pins"; `dba274c80` (the-nash-equilibrium) "sweep fake action SHA pins from e2e.yml template stubs".
* Overclaim / false status: `994a52ca3` (nextgen-databases) "Fix STATE.scm honesty (99->65%)"; `e36cea1c7`
  (f117a-stealth-glider) "stop 51 security policies naming the wrong repository"; `f10fbdb35` (affinescript)
  "over-claim ratchet (DOC-17)"; `9effa596f` (f19-stealth-glider) "retract the unsigned-commits deviation — it was false".
* Phantom tooling: `fd2e1d7a8`, `4a86a9bcd`, `a55b882b8` "remove 13 phantom tools and a no-op [alias] block" (same commit in 3+ repos).
* Gates that never fired (silent green): `91bcceeaf` "the invisible-character gate never matched anything"
  (251 copies); `707654659` "repair dogfood-gate.yml — the workflow has never run" (86 copies);
  `e979d1306` "the hypatia gate could never fire" (95 copies); `092ff9841` "make proof gates honest — missing toolchain is fatal, not a skip".
  "never ran / never matched / could never / no-op / silently / vacuous / false green" wording: 845 commits / 304 repos.
* Trivial syntax: `38bc2a1e8` (polyglot-i18n) "added missing semicolon" (third-party);
  workflow YAML: `57c8fdb02` "repair the permissions block indentation (invalid YAML)", 217555bd2, 9b3005780, 4dee07989, fd8d191fa
  "workflow-linter YAML parse error"; `db1eaf10e` unbalanced code fences; `9ddfde83e` (IDApTIK) "two parse errors" after a merge.
* Conflict: `4dc019e71` (Cytoville) "repair committed conflict markers"; `26efae455` (echidna) merge "resolve conflicts via ours".

## 4. The main finding: fixes are mostly estate-wide fan-out repeats, not independent bugs

Normalising fix/revert subjects (strip PR numbers, hashes, digits): 19,443 commits, **7,938 distinct subjects**.
11,959 commits (61.5%) have a subject that occurs in two or more repos; **10,095 (51.9%) occur in 8 or more
repos** (204 distinct subjects with ≥8 repos, listed in `/tmp/ct/fanout.tsv`); 6,870 (35.3%) are one-offs.
Largest repeated subjects (repos / commits):

| repos | commits | normalised subject (hash examples in `/tmp/ct/agg.txt`) |
|---:|---:|---|
| 327 | 357 | fix(ci): close the governance gate — spdx, permissions, sha pins, reusable bumps (346ae5666, b260445dc) |
| 226 | 251 | fix(ci): the invisible-character gate never matched anything (91bcceeaf) |
| 222 | 247 | fix(ci): pin third-party actions to full commit SHAs (a98c4fc51) |
| 218 | 245 | fix(gates): gate on the deed grammar, per the template and standards#N (5484da577) |
| 182 | 182 | ci: bump hyperpolymath upstream reusable pins to head (342a78697) |
| 173 | 200 | fix(ci): clear ossf scorecard startup_failure (8b7e3b538) |
| 163 | 187 | fix(ci): reconcile actions.lock so the lockfile validates (8c1a25ee0) |
| 155 | 173 | chore(guix): quality pass - fix stub/invalid names (753485b33) |
| 154 | 171 | fix(ci): resolve workflow-linter self-matching and metadata issues (c82cb51d6) |
| 149 | 160 | fix(scorecard): enforce granular permissions and add fuzzing placeholder (2d9d2100b) |
| 144 | 144 | fix(docs): repoint references to the relocated contributing guide (ba518a563) |
| 139 | 164 | fix(ci): re-point validate-action references at the ecosystem repos (52d00f651) |
| 130 | 141 | fix(ci): unbreak workflow yaml and add a complete actions.lock (123bcaa83) |
| 123 | 154 | fix(ci): adopt canonical hypatia-scan.yml (618c2bc63) |
| 95 | 97 | fix: correct email jonathan.jewell -> j.d.a.jewell (b397e6068) |
| 93 | 95 | fix spdx headers: agpl-3.0-or-later -> pmpl-1.0-or-later (1d6d53787) |

Reading: a defect class is found once (often in the template or `standards`), fixed once, then re-fixed
by hand or by sweep in every downstream repo. This is template drift (and gate-before-rollout churn) being
paid per repo. By author class the repeated-subject commits are `human+AI-coauthored` or `owner-human` (sweeps),
not bots. A sweep is one author action, so these 10,095 commits are not 10,095 independent errors. Count
distinct subjects (7,938 or 204 for the large ones) when sizing the underlying failure classes.

## 5. Fix-after-fix chains (denominator: 17,534 fix/revert-worded of 84,404 HEAD non-merge commits)

Definition: a fix/revert-worded commit that has an older fix/revert-worded commit within the previous 3
commits of the same repo (HEAD history, non-merge) with at least one shared path (`--name-only`, no renames).

* **4,899 of 17,534 (27.9%)** fix commits follow another fix on the same path within 3 commits.
* By class of the later fix: human+AI-coauthored 2,762 / 9,775 (28.3%); owner-human 1,689 / 5,950 (28.4%);
  third-party 292 / 1,172 (24.9%); ai-author 68 / 329 (20.7%); other-bot 74 / 194 (38.1%); other-coauthored 14 / 113; github-actions 0 / 1.
  Chain direction (newer <- older): AI-coauth <- AI-coauth 2,146; owner <- owner 1,473; AI-coauth <- owner 591;
  owner <- AI-coauth 209. Same-class pairs dominate, so there is no sign that AI fixes mostly repair human
  fixes or vice versa; each fixes its own earlier fix.
* Linked-run lengths (commits in a run of chained fixes): 2: 2,421; 3: 486; 4: 171; 5: 70; 6: 22; 7: 7; 8: 8;
  longest runs 52, 46, 26 (x5), 25 (x4), 23, 22, 19 (x3), 18.
* Paths most often re-fixed: `.github/workflows/hypatia-scan.yml` 858, `dogfood-gate.yml` 703, `scorecard.yml` 526,
  `governance.yml` 397, `secret-scanner.yml` 397, `actions.lock` 390, `mirror.yml` 302, `codeql.yml` 289,
  `boj-build.yml` 286, `workflow-linter.yml` 243, `instant-sync.yml` 160, `push-email-notify.yml` 154,
  `static-analysis-gate.yml` 150, `rust-ci.yml` 147, `guix.scm` 112. Top 25 are almost all CI workflow files
  (plus `guix.scm`, `README.md` 55): CI configuration is where fix chains concentrate.
* Repos with most chained fixes (chained / fix-worded): iseriser 582 / 737 (example pair
  efdb516f3 <- 1de80b089 on `dogfood-gate.yml`; 905 of its 3,444 commits are `ci`-primary, 187 commits on one day, 2026-04-04),
  echidna 129 / 338 (87054ccfe <- db175ce27, `idris2-abi-ci.yml`), standards 109 / 529, hypatia 104 / 457,
  explore 103 / 549 (fork), rrecord-verity 77 / 250, rsr-template-repo 66 / 264, Cytoville 51 / 192.
  Non-CI chains exist: standards `scripts/proof-receipt.sh` + its test (146fb8f8c); hypatia `lib/neural/coordinator.ex`;
  panic-attack `src/assail/analyzer.rs`; boj-server `boj-server_chora.deed`.
* Caveat: 3-commit window plus shared path catches re-edits of a hot file even when the second fix is
  unrelated; and one author batching several fixes on the same file inflates it. Upper bound.

## 6. Other counts worth keeping (all commits, 96,693; q.pl)

* Dependabot: 9,897 commits (10.2%); 0 of them fix-worded. Wording linking fixes to bumps: 1,034 commits / 383 repos
  ("fix ... dependabot/bump"); only 26 revert-of-bump and 32 bump-breaks commits, so unsafe bumps surface as forward fixes, not reverts.
  Not measured: whether a given bump broke CI (needs run data, not in git).
* Licence / SPDX wording: 4,456 commits / 417 repos; A->B flips 896 / 310; email/author identity fixes 315 / 206.
  Flip commits mix AGPL->PMPL, PMPL->MPL, MPL->PMPL (e.g. 1d6d53787 and "chore: migrate license from PMPL-1.0-or-later to MPL-2.0" in iseriser),
  which is the back-and-forth shape the estate licence rules warn about. FLAG ONLY.
* Template/RSR: canonical/template-sync wording 3,849 / 426; "RSR compliance" chores 784 / 256; placeholder/stub 1,594 / 367.
* A2ML/deed migration: 573 / 266 repos mention removing or migrating a2ml; 300 / 228 deed grammar/lint fixes;
  format migrations 439 / 208.
* CI cost wording (concurrency, cancel-in-progress, cache, paths, minutes, runner, skip ci): 1,287 / 334. Only 10 commits use `[skip ci]`
  (typesnake 48d9ccf77, paint-type 9df7f5f0f badge bot). Git history alone cannot give CI cost; workflow-file counts per repo are in `.stats.tsv` col 3.
* Signing: 678 commits mention sign/verified/gpg, only 79 fix-worded; no history-level evidence of unsigned commits was gathered (would need `%G?`, slow and keys not local). Not found.
* Merge-conflict artefacts: 123 commits / 73 repos resolve conflicts or repair conflict markers; 186 conflict-tagged overall.
  Owner-class merges are 1,840 of 9,275 merge commits; 5,813 are third-party (mostly fork history).
* Revert: 139 / 74 repos by loose match, 185 tagged; low compared with 19,443 fix-worded, i.e. the estate repairs forward.
* Self-correction vocabulary (wrong X, mistaken, forgot, oops): 51 commits / 36 repos. Rare in subjects; the AI-error signal is
  more in the structural wording (phantom, fake, nonexistent, never ran, honest) than in apologies.

## 7. What this suggests for types and tropes (tied to the evidence above; not a claim that these are built)

1. **A reference that does not exist is a type error.** 339 commits / 199 repos repair phantom/fake/non-existent SHAs, actions, paths, tools.
   A dependent "resolves-to" check on pins (SHA must exist at the upstream remote, tool must exist in the lock) would turn these into
   rejected commits. This is the clearest fabricated-structure class in the data.
2. **Gates that cannot fail.** 845 commits / 304 repos say a gate never ran, never matched, silently passed or was a no-op.
   A "vacuity" type (a check must carry a witness that it can reject) addresses silent green.
3. **Template drift is paid N times.** 10,095 of 19,443 fix-worded commits are subjects repeated in ≥8 repos. A single
   source-of-truth (the template or standards) with derived copies, and a diff-is-empty equivalence check, shrinks N to 1.
   This is the biggest quantity in the data.
4. **CI workflow files are the fix-chain hot spot** (all 25 most re-fixed paths bar a few); workflow YAML validity (645 / 288 repos) and
   actions.lock desync (697 / 286) are mechanical and checkable before push.
5. **Trivial syntax failures are rare here** (explicit semicolon/paren/brace/unbalanced 21 commits / 12 repos; syntax tag 193). The "missing semicolon"
   class is dominated by YAML/deed/workflow parse errors, not source code. Typos are fork noise (132 of 154 third-party).
6. **Dependency bumps** show up as forward fixes (1,034) rather than reverts (26); bump safety is not directly observable from git subjects.

## 8. Reproduce

```
cd /tmp/ct
./dump.sh <owner/repo>      # per-repo %H %P %an %ae trailers %s  (all refs)
perl classify.pl            # -> classified.tsv (tags, primary class, author class)
perl agg.pl > agg.txt       # tag/class matrices, top fix subjects, per-repo
perl q.pl                   # targeted sub-class counts
perl chains.pl              # fix-after-fix chains from names.txt
```
