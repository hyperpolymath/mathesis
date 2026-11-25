# CI inventory, cost and breakage (estate mining, read-only)

Method: shell/perl/ruby scripts over `/home/user/estate/<owner>/<repo>/.github/workflows/*`, plus `git log --format` / `--name-only` (no `-p`, no `show`) over all 484 clones. Scratch: `/tmp/claude-0/-home-user/45025f40-9ecc-5a8d-8a7b-43b8aba40a7d/scratchpad/` (`feat.tsv`, `norm.tsv`, `byname.tsv`, `perrepo.tsv`, `subj.tsv`, `wfcommits.tsv`, `parse.out`).
All numbers are from files/commands I actually ran. Heuristics are flagged. Nothing was edited, committed or pushed.

## 0. Denominators and caveats

- `.stats.tsv` column 3 sums to 8,466 (the figure in the brief). Files at exactly `<owner>/<repo>/.github/workflows/*` number 8,556. That set is 8,084 `.yml` + 3 `.yaml` = **8,087 workflow files**, plus 332 `actions.lock`, 77 `README.adoc`, 54 `*.template`, and 6 other (json/md/a2ml/tsv). All "workflow" numbers below use the **8,087 yml/yaml files in 462 repos** (hyperpolymath 6,476; metadatastician 945; catachresis-colloquium 550; stuff-of-awe 116). A further 5,953 `.github/workflows` files sit in nested paths (e.g. `asdf-augmenters/asdf-plugin-collection/plugins` 714, `rescript-ecosystem/packages/*`, `9-archive/...`, `vendor/`); GitHub does not run those, so they are excluded.
- Trigger/matrix/runner/cache fields come from a line-oriented perl parser (`feat.pl`), not a YAML engine. Matrix size is an approximate product of inline or `- ` lists and ignores `include`/`exclude`. Treat to within a few percent. A Ruby `Psych` parse of all 8,087 (section 8) is the only strict check.
- Commit subjects: 87,418 non-merge commits over `--all` refs in 484 repos. Forks and shared history may count a commit once per clone. Classification is by subject regex only (no diff content), so it is a heuristic.
- No runner-minute logs, billing data, or GitHub run history were available. **Real runner-minutes are not measured here.** Structural job counts are measured; minutes require an assumed duration per job and are labelled as such.
- 48 repos could not be cloned. Their workflows are not counted.

## 1. Clustering by filename

- 556 distinct filenames across 8,087 files. 390 filenames occur exactly once. 55 filenames occur in 20 or more repos and account for **7,284 files (90%)**.
- Top names (files / distinct byte-variants / largest byte-identical group):
  secret-scanner.yml 450/281/25 · labels.yml 427/28/154 · label-triage.yml 427/27/154 · hypatia-scan.yml 388/223/30 · governance.yml 382/221/35 · codeql.yml 373/302/11 · push-email-notify.yml 364/71/54 · scorecard.yml 358/221/23 · mirror.yml 354/187/28 · dogfood-gate.yml 278/253/6 · instant-sync.yml 261/139/20 · pages.yml 250/101/28 · boj-build.yml 236/116/22 · casket-pages.yml 199/109/20 · dependabot-automerge.yml 177/83/20 · release.yml 177/121/22 · workflow-linter.yml 175/101/18 · rust-ci.yml 137/91/17 · static-analysis-gate.yml 137/78/17 · quality.yml 98/52/19 · ci.yml 95/89/4 · e2e.yml 46/45/2.
- The estate has a small template/bundle vocabulary (about 55 names) copied into hundreds of repos, and a long tail of 390 single-use names.

## 2. Clustering by content hash (how many are copies, how many drifted)

| Normalisation | Distinct contents | Files in groups of 2 or more | Number of such groups |
|---|---|---|---|
| Raw sha256 | 4,358 | 4,389 (54%) | 660 |
| Comments and blank lines stripped | 3,409 | 5,333 (66%) | 655 |
| Also `uses: x@<pin>` stripped to `@PIN` | 2,616 | 6,011 (74%) | 540 |

- Largest byte-identical groups: labels.yml 154, label-triage.yml 154, labels.yml 125, label-triage.yml 125, push-email-notify.yml 54, rhodibot.yml 52, dot-wellknown-enforcement.yml 38, guix-policy.yml 36.
- Largest groups once comments and pins are ignored: labels.yml 350 of 427, label-triage.yml 350 of 427, push-email-notify.yml 286 of 364, mirror.yml 120 of 354, hypatia-scan.yml 86, governance.yml 86.
- Drift is mostly **pin and comment drift, not logic drift**. secret-scanner.yml has 281 byte-variants across 450 files, falling to 95 once comments and pins are ignored (largest group 50). hypatia-scan.yml goes 223 to 93. governance.yml goes 221 to 60. codeql.yml still has 153 variants in 373 files (largest group 23), so it is genuinely hand-edited per repo.
- For the 55 names with 20 or more files, the single most common pin-stripped variant covers only **2,395 of 7,284 files (33%)**. Even the "template" names are mostly variants.
- No file elsewhere is byte-identical to any of the 39 workflow files in `hyperpolymath/rsr-template-repo`. **559** files elsewhere are identical to a template file once comments and pins are ignored. The template propagates by regeneration or sweep, not by verbatim copy, and every copy freezes its own pins.
- Where a wrapper exists, it is thin: median workflow length 59 lines, p90 182, max 2,489, total 788,209 lines across the estate.

### Reusable workflows

- 1,980 workflows (24%) contain a job-level call of a reusable workflow. Callers by name: secret-scanner 407 of 450, governance 344 of 382, scorecard 319 of 358, hypatia-scan 313 of 388, mirror 281 of 354, rust-ci 94 of 137.
- Only 73 files declare `workflow_call`. The estate has few reusable producers and many consumers.
- Targets, by `uses:` count: `hyperpolymath/standards/.../governance-reusable.yml` 295, `secret-scanner-reusable` 282, `scorecard-reusable` 269, `hypatia-scan-reusable` 266, `mirror-reusable` 237, plus 133, 49, 48, 47 and 46 more of the same set via `metadatastician/standards`. The canon moved owner (`hyperpolymath/standards` to `metadatastician/standards`). **About 1,349 refs still use the old path** and rely on GitHub's transfer redirect.
- 1,984 of the 2,031 reusable refs are full-SHA-pinned. These pins have fragmented: 91 distinct SHAs for `*/standards/.github/workflows/*@<sha>`. Top: `81dbf2dd...` x250, `84355587...` x217, `8f2ee508...` x188, `571cc734...` x121, `da2c748a...` x114.
- Measured against `metadatastician/standards` HEAD (`75d38f80`, 2026-11-22): of 1,807 standards-pinned refs, **0 are at HEAD**, the weighted mean is 745 commits behind, and **1,373 are more than 500 commits behind**. 4 distinct pinned SHAs (16 refs: `8750b94a...`, `cc58c0cb...`, `8f31a5a4...`, `5b1d0022...`) are **not present in the local standards clone** (they may live only on an unmerged ref). The commit log confirms such "phantom" pins happened (section 7).
- Action refs: 10,330 sha-pinned, **8,722 tag-pinned** (`actions/checkout@v7.0.1` 4,439 times), 660 branch refs (`@main`/`@master`), 13 other. `git ls-remote` confirms `actions/checkout` tag `v7.0.1` exists and resolves to `3d3c42e5...`, the same SHA used 3,594 times. The estate's own rule says full-SHA pinning is required, so about 8,700 tag-pinned and 660 branch-pinned refs are still open departures.

## 3. Triggers, filters, concurrency, cache, runners

All counts are workflows (of 8,087) unless stated.

| Property | Count |
|---|---|
| Triggers on `push` | 6,666 |
| Triggers on `pull_request` | 4,554 |
| Triggers on both push and pull_request | 4,271 |
| push or pull_request, or both (the "auto" set) | 6,960 |
| `workflow_dispatch` | 4,351 |
| `schedule` | 1,965 (1,969 cron entries) |
| `release` | 299 |
| `issues` | 428 |
| `merge_group` | 53 |
| `workflow_run` | 47 |
| `workflow_call` | 73 |
| `pull_request_target` | 11 |

- **Path filters:** of the 6,960 auto-triggered workflows, **1,013 have a `paths`/`paths-ignore` filter, 5,947 (85%) have none**. 425 of the 1,013 are the trivial `labels.yml` (which has a path filter and no concurrency).
- **Push without a branch filter:** 894 of 6,666 push-triggered workflows have no `branches`/`branches-ignore`, so they fire on every branch push. 275 of those also fire on `pull_request`, so each commit to a PR branch starts two runs.
- **Concurrency:** 4,115 of the 6,960 auto-triggered workflows (59%) define `concurrency`; 3,084 set `cancel-in-progress` true or an expression. **2,845 auto-triggered workflows have no concurrency.** 2,201 have neither concurrency nor a path filter.
  - By name: secret-scanner 446 of 448 have it, push-email-notify 343 of 364, codeql 308 of 368. But `dogfood-gate` 79 of 278, `boj-build` 23 of 234, `instant-sync` 15 of 260, `mirror` 77 of 354.
  - The commit "harden(ci): concurrency-cancel guard on canonical check workflows" went to 242 repos, and "ci: redistribute concurrency-cancel guard to read-only check workflows" to 190.
- **Caching:** only 655 workflows (8%) show any cache signal (`actions/cache`, `rust-cache`, `cache:` on setup-*, buildx cache). Of the roughly 986 workflows that run a package or build command (cargo build/test, npm ci/install, bun install, pnpm install, pip install, deno test/task, zig build, cabal), **542 show no cache indicator** (grep heuristic). 420 install tools at runtime (`cargo install`, `apt-get install`). 699 use `fetch-depth: 0`.
- **timeout-minutes:** 4,482 workflows have at least one. About 3,600 do not, so a hung job runs to the 6-hour default.
- **Runners (per `runs-on` line):** ubuntu-latest 4,704, ubuntu-24.04 1,386, `${{ matrix.os }}` 63, self-hosted `[self-hosted,owned,container]` 66, windows-latest 10, macos-latest 4 (macOS or Windows appear in 87 files, including matrix and language conditionals). The estate is overwhelmingly Linux, so there is no macOS/Windows minute-multiplier blow-up. `ubuntu-latest` (4,704) is a floating image, i.e. a drift source.
- **Matrix:** 105 workflows have a matrix producing more than 1 job (histogram of approximate sizes: 2 → 61, 3 → 20, 4 → 6, 5 → 2, 6 → 8, 8 → 2, 9 → 3, 10 → 1, 26 → 1, 27 → 1). Matrix inflation adds only about 1,068 job-instances (heuristic). Matrices are not the cost problem; fan-out of many small uniform workflows is.
- **Jobs:** 12,288 jobs in total; 11,036 in auto-triggered workflows.
- **Failure suppression:** `|| true` appears in 2,076 workflows and `continue-on-error: true` in 602. A green run can therefore hide a failing scanner (see the "gate that never fired" commits in section 7).

## 4. Structural cost: fan-out per push (jobs, not minutes)

- A single push or PR event to every repo would start 6,960 workflows and 11,036 jobs, about 12,104 job-instances with matrix expansion, across 459 repos.
- Per repo (jobs x matrix, push or PR set): **median 22, p90 52, max 157**. The median repo has 16 workflow files and 14 that fire on push/PR; the p90 repo has 35 and 31; the maximum is `metadatastician/standards` (76 files, 45 firing, 68 jobs).
- 208 of 462 repos have 15 or more workflows firing on push/PR.
- The same estate-wide checks are re-run per repo on every push: secret-scanner 448 repos, hypatia-scan 388, governance 382, codeql 368, push-email-notify 364, mirror 354, dogfood-gate 278 (1,665 jobs in 278 workflows, about 6 jobs each), instant-sync 260, pages 241, boj-build 234. None of these has a path filter. `dogfood-gate` has the highest jobs per workflow (about 6).
- **4,271 workflows fire on both push and pull_request** (7,135 jobs). Of these 1,344 have no concurrency and 3,738 have no path filter. A commit pushed to an open PR branch starts both event runs.
- **Scheduled load:** 1,965 workflows have a cron, 1,969 cron entries. By shape: weekly 1,050, monthly (day-of-month) 610, daily 299, other 10. The four estate-wide names that carry schedules are labels.yml 425, hypatia-scan 384, codeql 368, scorecard 356. 1,425 workflows have both `schedule` and `push`. Estimated scheduled runs per month: about 300x30 + 1,050x4.35 + 610 = about 14,200 from regular schedules.
- **Highest-frequency schedules (10 entries at or above hourly):**
  - 7 `ci-gate.yml` callers on `7,22,37,52 * * * *` = 96 runs/day each (about 20,160 workflow runs/month for the 7 repos): `catachresis-colloquium/enaction-engine`, `hyperpolymath/mathesis`, `proven-cicd-and-workflows` (`ci-gate-caller.yml`), `resource-algebra`, `rsr-template-repo`, `tsunami-breaker`, `work-queue`. This one pattern is about 59% of all estimated scheduled runs. Each run lists open PRs and re-evaluates SHAs.
  - `metadatastician/standards/action-pins-applier.yml` (`23,53 * * * *`, 48/day), `hyperpolymath/hypatia/roadmap-sync.yml` (`*/30`, 48/day), `hyperpolymath/explore/collections-renames.yml` (`0 * * * *`, 24/day).
- **workflow_run amplification (ci-gate):** `hyperpolymath/mathesis/.github/workflows/ci-gate.yml` (88 lines) triggers on `workflow_run` of `["**", "!CI gate"]` with types `[completed, in_progress]`, plus `pull_request`, cron and dispatch. Every run of every other workflow therefore starts the gate twice (once on start, once on completion). mathesis has 32 push/PR workflows, so one push plausibly starts 64 additional gate runs on top of 32 base runs. 6 files match the `workflows: ["**"` pattern. The file comment states this is intentional (a commit status instead of a check run, deliberately no `concurrency`). **The cost is structural and intended, and the documentation does not quantify it.**
- **Illustrative minutes (assumed, not measured):** if an average job costs 1.5 billable minutes, one push to every repo is about 18,000 runner-minutes. Per-repo median is 22 job-instances, about 33 minutes per push. Scale linearly with your own measured average.
- **The owner's own spec** (`hyperpolymath/rsr-template-repo/docs/practice/ci-cost-reduction.adoc`, commit `e3fe85e`, 2026-04-17, 278 lines) is STATED, born from an Actions billing trip that took every runner-based workflow dark. It claims 60-80% savings from: (1) concurrency kills, (2) path filters, (3) lower schedule frequency, (4) overlap consolidation (trufflehog+gitleaks; rsr-antipattern+scorecard-enforcer+static-analysis-gate), and more. Measured adoption today: concurrency 59% of auto workflows (partial), path filters 15% (largely unadopted), cron mostly weekly/monthly (adopted), plus a new 15-minute sweep that adds cost. The spec's "60-80%" figure is its own estimate; I have not verified it.
- **Commits that show cost-lowering sweeps already happened:** "chore(ci): make Scorecard periodic, not per-push" in 263 repos; "harden(ci): concurrency-cancel guard" in 242.

## 5. CI-fixing commits (subject heuristics, 87,418 non-merge commits)

| Measure | Count |
|---|---|
| Commits with scope `ci`/`workflow(s)`/`action(s)` in the Conventional-Commit prefix, or `ci:` prefix | 11,020 (12.6% of 87,418) |
| `fix(ci)` / `fix(workflow...)` style | 7,132 |
| `ci:` prefix | 6,553 |
| Loose "CI-ish term AND fix word" (bot dependabot bumps removed; 9,426 bot bump commits excluded) | 9,588 across 442 of 484 repos |
| Commits touching `.github/workflows/` in any way (`--name-only`) | **31,514 (36% of all commits)**, across 460 repos, 102,696 file-touches |
| ...of those, single-file | 17,541 |
| ...of those, 10 or more files (sweeps) | 2,572 |
| ...of those, bot-authored | 6,401 |
| ...of those, subject has fix/repair/revert/broken/failing | 7,933 |
| ...of those, subject is a version bump (Bump/chore(deps)/build(deps), or "bump ... actions") | 10,503 |
| ...of those, subject repeated in 10 or more repos (estate-wide fan-out) | 19,509 commits over 346 distinct subjects |
| All commits whose subject is repeated across 10 or more repos | 38,361 (44%) over 677 distinct subjects |

- Authors overall: Jonathan D.A. Jewell 59,149, dependabot[bot] 9,771, "hyperpolymath" 3,281, "Claude" 2,493.
- Monthly CI-scope commits (all commits in month in parentheses): 2026-03 781 (9,716); 2026-04 568 (8,340); **2026-05 5,305 (10,414)**; 2026-06 2,311 (7,915); 2026-07 2,402 (6,814); 2026-08 1,762 (6,302); 2026-09 2,759 (7,333); 2026-10 696 (4,683); 2026-11 872 (6,227). May 2026 is a CI-sweep spike (51% of commits that month).
- Highest ci-fix repos: `iseriser` 443, `standards` 263, `hypatia` 182, `developer-ecosystem` 126, `rsr-template-repo` 107, `echidna` 98, `Cytoville` 89, `asdf-tool-plugins` 87, `gitbot-fleet` 81, `boj-server` 70.

### Estate-wide repeated subjects (top; repos where the same subject appears)

379 feat(labels): estate label tooling + auto-triage for new issues · 338 refactor: migrate Markdown to AsciiDoc · **327 fix(ci): close the governance gate — SPDX, permissions, SHA pins, reusable bump** · 320 chore(ci): add dormant push-email notification workflow · 307 chore(ci): repoint push-email-notify to smtp-notify-action · **279 ci: refresh standards reusable pins to current HEAD (d7c2271)** · 263 chore(ci): make Scorecard periodic, not per-push · 262 replace per-repo governance copies with shared bundle wrapper · 260 replace mirror.yml with reusable wrapper · 248 replace secret-scanner.yml with reusable wrapper · 242 harden(ci): concurrency-cancel guard · **227 fix(ci): the invisible-character gate never matched anything** · 226 replace scorecard.yml with reusable wrapper · **223 fix(ci): pin third-party actions to full commit SHAs** · 214 convert hypatia-scan.yml to wrapper · 201 chore(deps): bump the actions group with 2 updates · 199 ci: bump actions/upload-artifact SHA to current v4 · 199 adopt standards reusable workflows · 199 ci(hypatia): standardise the wrapper caller id · 190 concurrency redistribution.

Reading: a large share of CI effort is the same edit being redone per repo. Local copies force the same change into hundreds of repos (fan-out commits), and then re-pinning (279 repos in one sweep, then more).

## 6. Commonest CI breakage classes (from subjects, loose "CI and fix" set of 9,588; priority-ordered buckets, so first-match wins and counts are approximate)

| Class | Count | Typical subject |
|---|---|---|
| Gate/lint/policy repairs (gates themselves wrong) | 3,276 | "fix(ci): canon lockstep deed discovery; per-job gate state" |
| Unclassified other | 1,690 | "fix(ci): the reusable-caller entry went into `dependencies`, not `workflows`" |
| SHA-pin / pin-actions | 1,257 | "fix(ci): pin third-party actions to full commit SHAs" |
| Permissions / token / secret | 970 | "fix: add actions: read permission to workflows with permissions blocks" |
| Toolchain / dependency / build / lockfile | 941 | "fix(ci): reconcile actions.lock so the lockfile validates" |
| YAML / syntax / parse | 579 | "fix(ci): unbreak workflow YAML and add a complete actions.lock" |
| Action version / deprecation | 434 | "chore(ci): bump standards reusable pins to fix Bug A and Bug B" |
| Triggers / paths / branch / stale refs | 200 | "fix(ci): repin cicd-suite reusable to main head — dead ref from deleted branch" |
| Cache / timeout / flaky / runner | 190 | "fix(ci): standardize oikosbot.yml timeout to 30 minutes" |
| Tests | 51 | |

Specific recurring incident signatures (subject counts across all 87,418 commits; categories overlap):

- **SHA pinning and re-pinning:** "SHA pinning" 2,110; "repin/bump reusable pins" 2,305; `actions.lock` / lock-sync 913.
- **startup_failure (workflow never starts):** 343 subjects. 208 "clear OSSF Scorecard startup_failure"; 46 "codeql-action v4.38.1 -> v4.38.0 SHA pin + dependabot hold (estate-wide startup_failure)"; 21+5 "adopt the Actions lockfile — every workflow was startup_failure". Estate-wide outages stem from one bad pin.
- **Parse-dead workflows (invalid at parse time):** 79 "drop invalid timeout-minutes from reusable-workflow calls (parse-dead)"; 60 "make OSSF Scorecard caller valid (perms / drop timeout-minutes)"; 34 "repair parse-dead workflow — K9-SVC step at job-level indent"; 67+5 "repair the permissions block indentation (invalid YAML)"; plus 6+2 "parse-dead workflows and phantom CodeQL SHAs". `timeout-minutes` on a `uses:` job is a recurring invalid construct.
- **Nonexistent / phantom / fabricated SHA pins:** 13+10 "fix nonexistent actions/upload-artifact SHA pin"; 10 "repin standards to a SHA that exists (5b1d0022 is nonexistent)"; 8+2 "repin governance-reusable off phantom SHA 8f31a5a4"; "r-lib/actions/setup-r — replace fabricated SHA pin"; 4 "repin every dead standards ref to a self-consistent commit". This is the clearest AI/LLM-fabrication signature in CI.
- **Vacuous gates (green that checked nothing):** 253 "the invisible-character gate never matched anything"; 95+16 "the Hypatia gate could never fire — ... unconditionally vacuous"; "security: fix invalid workflow file — the scanner never ran at all"; "repair non-compiling FFI, vacuous gates and three parse-dead workflows". Together with 2,076 `|| true` and 602 `continue-on-error: true`, this is "silent green".
- **Trivial syntax class (missing-semicolon analogue):** indentation and quoting fixes about 100+ ("repair the permissions block indentation" 67+5; "K9-SVC step at job-level indent" 34+3). "typo/syntax error" appears in 159 subjects (not CI-specific). Subjects mentioning `e2e.yml`/`.template` as "not a valid workflow": e2e.yml, 46 files, 45 distinct variants, 7 currently have no `jobs`.
- **Cost-related:** 377 subjects mention cost/minutes/billing/quota; 612 concurrency/cancel; 306 timeout; 248 flaky; 219 cache; only 2 mention path filters.
- **Reverts:** 136 revert commits overall, 29 revert a CI/workflow/pin change (e.g. Cytoville `1d73221 Revert "fix(ci): pin third-party actions to full commit SHAs (#182)"`, then a later re-fix).
- **Dependabot:** 9,771 dependabot commits (11% of history); 1,039 subjects mention dependabot.

Which agent: human vs AI vs bot. The author field shows human 59,149, dependabot 9,771, "Claude" 2,493, `coderabbitai[bot]` 293; subjects mentioning "Claude" 978. I cannot attribute which fix commits are AI-authored from subjects alone. The "phantom/nonexistent/fabricated SHA", "vacuous gate", "never matched anything" and "parse-dead" classes are the plausible LLM-assisted signatures (CLAIMED by the commit text, not verified per commit).

## 7. Current-state validity (post-fix) — Ruby Psych over all 8,087

- 23 files with problems (0.28%): 7 "no jobs" (e.g. `e2e.yml` stubs in `typefix-zero`, `kitchenspeak`, `nesy-solver`, `affinescript-vite`, `llm-grace`), 6 not a YAML mapping (e.g. `Hyperpolymath.jl/ci.yml`, `codeql.yml`, `Cladistics.jl/ci.yml`, `ViableSystems.jl/ci.yml`, `QuantumCircuit.jl/ci.yml`, `explore/lint.yml`), 5 job-level `uses:` mixed with `steps`/`runs-on`/`timeout-minutes` (invalid; `kitchenspeak/scorecard.yml`, `rust-ci.yml`, `mirror.yml`, `lucidscript/governance.yml`, `veridical-simulation-core/spark-theatre-gate.yml`), 3 Psych syntax errors (`cloudguard-server/dogfood-gate.yml`, `pimcore-fortress/main-estate-audit.yml`, `rrecord-verity/dogfood-gate.yml`), 2 missing `on:` (in `stuff-of-awe/awesome-fsharp`, which is third-party-looking). 12 repos affected.
- Interpretation: the parse-dead class is largely cleaned at HEAD, but it cost thousands of fix commits and survived undetected in some repos for a long time (a gate that could not run can not report itself). It would have been caught pre-merge by a schema check or a typed workflow DSL; this is a measured example of syntax-class failure at scale.

## 8. Dedup of what the data says, graded

- PROVED by running or reading files: counts in sections 1-5, 7; the existence of `ci-cost-reduction.adoc`; `actions/checkout` v7.0.1 tag existence (git ls-remote); the 4 absent SHAs in the local standards clone.
- STATED only (spec or comment, no measurement): the cost-reduction spec's 60-80% saving; ci-gate's design rationale ("a COMMIT STATUS, not a check run").
- NOT FOUND: real runner-minute or billing data; run-time history; flaky-test telemetry; per-commit AI authorship.
- Unverified: whether `.lock` (actions.lock, 332 files) is correct relative to pins, since `lock-sync-gate` commits were not diffed.

## 9. Candidate type/trope levers suggested by the data (for the programme; no work done)

1. **Workflow schema as a type** (parse-dead, startup_failure, `timeout-minutes` on `uses:` jobs, permissions-block indentation): about 1,000 subjects, and 23 live defects remain. A typed workflow generator or schema-checked caller removes the whole class before push.
2. **Pin refs as a dependency type** (phantom SHA, dead refs, 91 distinct reusable SHAs, 1,373 refs more than 500 commits stale, 8,722 tag pins, 660 branch pins): `actions.lock` already exists and is the right shape. The remaining fix is one resolvable ref plus a single update flow (about 2,300 repin commits).
3. **Thin wrappers only, single source:** 74% of files are copies once pins and comments are removed. The wrappers exist for 6 names; labels, push-email-notify, instant-sync, pages, boj-build, casket-pages, dependabot-automerge, workflow-linter, static-analysis-gate, quality, security-policy, rhodibot (all 0 reusable callers) are still copied in full (about 3,300 files, summing the per-name counts in section 2's list of names with no reusable callers).
4. **Gate liveness as a property** ("never matched anything", "could never fire"): 253+111 commits show gates that were green without effect. A negative-control test per gate (the gate must fail on a seeded violation) is the cheap formalisation; `|| true` (2,076) and `continue-on-error` (602) are the static smell.
5. **Cost as a lint:** 2,845 auto-triggered workflows without concurrency, 5,947 without path filters, 542 uncached builds, 3,600 without timeouts, and 7 ci-gate sweeps at 96/day plus workflow_run doubling are all statically detectable; a "cost budget" check (jobs per push per repo, median 22, p90 52) is a mechanical gate.

## 10. Reproduce

Scripts and intermediate TSVs are in the scratchpad path above. Key commands: file list `find ./*/*/.github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \)` (equivalently the top-level glob); hashes `sha256sum`; normalisation drops `^\s*#`, blank lines, trailing comments and `uses: x@<pin>`; commit sets `git log --all --no-merges --format='%h%x09%an%x09%ae%x09%s'`; workflow-touching commits `git log --all --no-merges --format=... --name-only -- .github/workflows`; parse check `ruby parse.rb` (`YAML.safe_load`).
