# Dependency bumps: counts, churn, breakage, and what would make a bump provably safe

Read-only mining, 2026-11-24, over the 484 clones in `/home/user/estate` (48 repos not cloned: not mined).
Scratch scripts and tables are in `/tmp/bm/` (`dump.sh`, `an.pl`, `semver.pl`, `fab2.pl`, `lock.pl`, `bump_commits.tsv`).
Nothing was edited, committed or installed.

## 0. Method and limits (read first)

* Corpus: `git log --all --no-merges --no-renames --name-only` per repo = **87,297 distinct commits** (all refs, so
  unmerged `dependabot/*` branches are included; 9,483 of the 9,840 dependabot commits are reachable from HEAD, 357 are not).
  Merge commits are excluded because dependabot squash-merges; merge commits carry no file list here.
  The earlier `commit-taxonomy.md` counts merges too (96,693); numbers here are not directly comparable.
* "dependabot" = author name or email contains `dependabot`. "renovate": **0 commits found** (no renovate config either:
  `*/*/.github/renovate*` and `*/*/renovate.json*` match nothing).
* "human-bump" = non-bot commit whose subject matches `(bump|upgrade|update)` plus a dependency-ish word (deps, version, pin, sha, crate, action, package...).
  It is a **loose heuristic**: it picks up e.g. 74 "guix" commits that are actually `chore: update guix.scm from squisher-corpus`
  (template sync, not a bump). Treat human-bump counts as upper bounds.
* Ecosystem is assigned from the **files a commit touched** (`Cargo.toml/lock`, `mix.exs/lock`, `package.json`, `bun.lock`, `deno.lock`,
  `Project/Manifest.toml`, `.github/workflows/*` or `actions.lock`, `guix.scm/manifest.scm/channels.scm`, `flake.*`, ...), not from the subject.
* `hyperpolymath/explore` is a fork of github/explore (Ruby gems, third-party). It contributes 447 of the 9,840 dependabot commits.
  It is third-party and flag-only; figures below say "excl. explore" where it matters (dependabot excl. explore = 9,393).
* Not measurable from git alone: whether a bump's CI went red (no run data in the clones), PR open/closed/unmerged outcomes,
  and anything on the 48 uncloned repos. "Breakage" below is therefore inferred from later commits, a lower bound.
* Checked by running the tool, not by trusting status docs: every number below is output of the scripts above.

## 1. Volume per author kind and ecosystem (denominator: 87,297 commits)

| kind | commits | of which on HEAD |
|---|---:|---:|
| dependabot | 9,840 | 9,483 |
| human-bump (strict heuristic) | 3,883 | 3,670 |
| human-bump-loose (mentions bump/dependabot) | 1,546 | 1,511 |
| other | 72,028 | |

Dependabot commits by ecosystem inferred from touched files (9,840; excl. explore 9,393):

| ecosystem | dependabot commits | notes |
|---|---:|---|
| github-actions (workflow files) | 6,560 (2 more mixed with cargo) | 66.7% of 9,840; 6,445 of 9,393 excl. explore |
| cargo | 2,036 | |
| nix | 270 | estate bans Nix; hypatia schema invariant B3 says nix bumps are "closed, not merged" |
| npm/bun/deno (`package.json` etc.) | 269 | |
| mix (Hex) | 259 | |
| pip (python) | 59 | Python is banned estate-wide |
| container / go / asdf / dependabot-cfg | 6 / 1 / 1 / 1 | |
| unclassified | 376 (331 are explore Ruby gems) | |
| **julia, guix, gleam, idris, zig** | **0** | no dependabot commits ever; see section 7 |

Dependabot is present in **400 of 484 repos**; 32 repos have 50 or more dependabot commits. Top: explore 447 (fork), iseriser 396,
gitbot-fleet 369, hypatia 350, academic-workflow-suite 264, ambientops 236.

Time profile (dependabot commits by year): 2018=17, 2019=45, 2020=87, 2021=91, 2022=46, 2023=52, 2024=41, 2025=384, **2026=9,076**
(2026-03=533, 04=692, 05=1,038, 06=701, 07=1,217, 08=950, 09=1,190, 10=1,432, 11 up to the 24th=940). The estate's bump noise is a
2026 phenomenon, roughly 1,000 commits/month across the clones recently.

Dependabot configuration (`*/*/.github/dependabot.yml`, 447 files; counted by grep, not YAML-parsed):
* ecosystems declared (lines): github-actions 416 (+9 variants), cargo 252, npm 205, mix 182, **pip 177, nix 107**, guix 59, gomod 4.
  Banned-language ecosystems (pip, nix, gomod) are configured in 177 / 107 / 4 files: a departure from the estate language policy
  (standards `.claude/CLAUDE.md`). Not fixed (read-only); flag for the owner.
* `groups:` present in 399 files; `open-pull-requests-limit` in 318; `ignore:` in 294; `cooldown` in **1** file (`hyperpolymath/poly-ssg`).
* schedule: weekly ~1,355 lines, daily 103.
* `ignore` holds: `dependency-name: "*"` 72, `github/codeql-action` 57, `github/codeql-action*` 39 (see section 5 for why).
* `guix` is configured in 59 files but there is not one dependabot commit touching guix files in 87,297 commits, i.e. those 59 entries have never produced a bump
  (my inference; I did not verify against GitHub's list of supported ecosystems).

## 2. Grouped vs ungrouped (dependabot, 9,840 commits)

Grouped by subject wording ("bump the X group", "group with/across N updates"): **4,108**; single-package: **5,732**.
By ecosystem: actions grouped 3,653 / single 2,907; cargo grouped 379 / single 1,657; npm grouped 35 / single 234; mix grouped 8 / single 251.
So actions are mostly grouped, while cargo, mix and npm are overwhelmingly ungrouped (one commit, one crate) despite `groups:` in 399 configs
(likely config blocks that group only some ecosystems; I did not cross-check config against behaviour per repo).
Parsed "with N updates" subjects: 3,826 grouped PRs carry 15,184 updates, mean 3.97 per PR; 80 are multi-directory ("across N directories").

## 3. Semver level of single-package dependabot bumps

Subject parsed as `from X to Y` (4,758 of the 5,732 single commits parse). Levels: major vs minor vs patch; for 0.x versions I split
because Cargo (and Hex/npm caret rules) treat `0.a -> 0.b` as breaking.

| ecosystem (parsed n) | major | 0.x minor (breaking-by-convention) | 0.x patch | minor | patch |
|---|---:|---:|---:|---:|---:|
| all (4,758) | 1,015 | 629 | 501 | 1,017 | 1,596 |
| actions (2,585) | 781 | 177 | 120 | 574 | 933 |
| cargo (1,496) | 158 | 372 | 310 | 258 | 398 |
| npm/bun/deno (128) | 59 | 3 | 1 | 23 | 42 |
| mix (228) | 2 | 26 | 43 | 63 | 94 |
| other (321) | 15 | 51 | 27 | 99 | 129 |

Reading: 30% of all parsed bumps (1,015 + 629 of 4,758 = 1,644, 34.6%) are major or 0.x-minor, i.e. presumed breaking. For cargo specifically,
372 + 158 = 530 of 1,496 (35.4%) are presumed-breaking by semver. The numeric version delta alone is therefore informative for about a third of bumps.
Actions have the highest major share: 781 of 2,585 (30.2%).

## 4. Lockfile churn

Commits whose changed files are **all** lockfiles (`Cargo.lock`, `mix.lock`, `bun.lock`, `deno.lock`, `pnpm-lock.yaml`, `package-lock.json`, `Manifest.toml`,
`actions.lock`, `flake.lock`, `go.sum`...): **2,860 of 87,297** (3.3%). By kind: dependabot 2,141, human-bump 108, bump-loose 36, other 575.
By ecosystem: cargo 1,497, actions (`actions.lock`) 460, nix 289, mix 228, npm-ish 74, julia 9, unclassified 301.
* Dependabot: 2,141 of 9,840 (21.8%) are lockfile-only, meaning the manifest range already admitted the new version (cargo, mix).
* The 575 non-bot lockfile-only commits are 457 by the owner identity, 47 `hyperpolymath`, 35 Claude; subjects such as `chore: cargo update`,
  `fix(ci): reconcile actions.lock so the lockfile validates (#89/#130/#286)`, `chore(actions): relock drifted action pins`.
  That is churn caused by a derived artefact (`actions.lock`) drifting from workflow YAML.
* Files that appear in commits (commits / repos): `Cargo.lock` 3,057 / 176; `package.json` 896 / 114; `mix.lock` 342 / 34; `Project.toml` 322 / 86;
  `deno.lock` 186 / 72; `channels.scm` 178 / 53; `mise.lock` 158 / 43; `Manifest.toml` 64 / 21; `bun.lock` 49 / 16.
* Lockfile presence, repos with the file within depth 4 (excl. explore): Cargo.toml 186 / Cargo.lock 166; mix.exs 59 / mix.lock 31 (so 28 Elixir repos have no lock);
  Project.toml 84 / Manifest.toml 19; package.json 71 / bun.lock 16 / deno.lock 54 / pnpm-lock 3 / package-lock.json **1** (policy: refused);
  guix.scm 128, manifest.scm 87, channels.scm 45; gleam.toml 16.

## 5. Action SHA pins: the noisiest and the most hazardous class

* 6,558 dependabot commits touch workflow files; 5,482 of them are in repos that, somewhere in history, carry an `actions.lock`
  (329 repos have `.github/workflows/actions.lock` now; 79 have `lock-sync-gate.yml`; `rsr-template-repo/scripts/check-lock-sync.sh` is the checker).
* Of those 5,482, **1,142 touched `actions.lock` themselves** (dependabot or a later amend kept it in sync). In another **867**, a non-dependabot commit touching
  `actions.lock` followed within the next 5 commits of that repo. That 867 is an upper bound (the lock can be touched for unrelated reasons), but explicit
  wording supports it: `fix(ci): regenerate actions.lock — Dependabot bumped uses: without repinning (#99)` (IDApTIK, f7ebdedc), `ci: regenerate lockfile after dependabot bumps
  (restores CodeQL, Scorecard, Governance) (#158)`; 243 commits mention dependabot together with a fix/revert/regen word.
* Workflow `uses:` lines in current checkouts: 19,636 total. Estate-owned reusable refs 3,248 (2,383 SHA, 652 `@main`, 212 tag). Third-party refs: 7,796 SHA-pinned vs
  8,453 tag-pinned (mutable). 10,257 `@<sha>` lines (grep over workflow yml, comment lines excluded), 7,859 carry a trailing `# vN`-style comment; 1,043 say just `# v4`.
* The comment lies, by the estate's own measurement: `hypatia/scripts/sweeps/estate-pr-automerge.sh` header says "at least two of them hide a *major* bump inside a 'grouped' chore
  (`actions/checkout` v4.1.7 -> v7.0.1, labelled `# v4` on both sides)... resolved from the action's own tag list, not from the inline comment, because the comments in this
  estate demonstrably lie". I did not re-derive that (needs the network); I report it as quoted.
* **The codeql-action v4.38.1 incident (best-evidenced unsafe bump).** `hypatia/.machine_readable/merge-orchestration/pr-automerge-policy.json` PIN-001: "GitHub rejects this commit at
  workflow start-up: `startup_failure`, zero jobs, no logs". Counted in git: **46 dependabot commits bump to 4.38.1**, **47 commits in 47 repos** with subject
  `codeql-action v4.38.1 -> v4.38.0 ... (estate-wide startup_failure)`; the policy file says 108 workflow files in 84 hyperpolymath repos (and 23 in metadatastician) carried the bad SHA
  labelled v4.38.0. The `ignore: github/codeql-action` rule was bypassed by SHA-form re-bump and by the subpath dependency names (`github/codeql-action/init`, `/analyze`)
  (`rsr-template-repo/.github/dependabot.yml` comments, "#210 bumped 4.38.0 -> 4.38.2 straight through this hold"). Neither semver nor CI-on-the-PR could have prevented
  it, because a `startup_failure` produces no job logs. A pre-merge **structural check** (does GitHub accept this ref's workflow graph) is what was missing.
* `startup_failure` appears in 342 commit subjects across the estate (e.g. Cytoville#17 `adopt the Actions lockfile — every workflow was startup_failure`).
* `actions.lock` transitive-closure check (`check-lock-sync.sh` clause 3) exists because dangling edges passed both the script and `gh actions-lock --verify-local`
  while GitHub refused the workflow (cicd-squabbler, commits fe22bbc / cfadcf9 / 5286aa5, 2026-09-22 per the script's own header). That is a real, checkable safety property for action bumps.
* Most-bumped actions (dependabot subjects): github/codeql-action 640 (+ `/init` 69, `/analyze` 67), actions/checkout 260, hyperpolymath/smtp-notify-action 217, trufflesecurity/trufflehog 180,
  dawidd6/action-send-mail 173, actions/deploy-pages 87, erlef/setup-beam 71. 76 distinct `owner/name` actions appear in "from X to Y" subjects. One upstream release fans out to many repos:
  the same action version bump recurs per repo (400 repos), which is the multiplier behind the 6,560.

## 6. Reverts, fix-after-bump, and baseline

* Reverts naming a bump or dependabot (`^Revert.*(bump|dependabot)`, case-insensitive): **8 commits** (e.g. candy-crash `Revert "chore(ci)(deps): Bump actions/checkout from 4.1.1 to 6.0.2 (#4)"`, network-dashboard `Revert "chore(deps): bump github/codeql-action from 4.35.5 to 4.36.1 (#54)" (#55)`, palimpsest-license `Revert "Bump actions/checkout from 4.1.1 to 6.0.2 in the actions group (#76)"`). Bump breakage in this estate is repaired forward, not reverted (consistent with `commit-taxonomy.md`).
* Fix-after-bump, strict definition: bump commit B touching a manifest/lockfile; within the next 5 commits of the same repo (time order, bot bump commits skipped) a non-bump commit
  whose subject has fix/repair/revert/unbreak/hotfix/broke/regress **and** which touches the same manifest/lock file. Baseline: the same measurement for non-bump commits touching those files.

| set | n | fix within next 5 | within 3 days |
|---|---:|---:|---:|
| bump commits touching manifest/lock (workflow-only excluded) | 3,178 | 115 (3.6%) | 80 |
| of which dependabot | 2,793 | 82 (2.9%) | 56 |
| non-bump commits touching manifest/lock | 5,064 | 489 (9.7%) | 405 |
| bump commits touching workflows only | 8,901 | 1,530 (17.2%) | 812 |
| non-bump commits touching workflows only | 23,054 | 6,111 (26.5%) | 4,680 |

Reading: **bumps are not followed by a same-file fix more often than ordinary edits are** (fewer, in fact); this metric does not reveal unsafe bumps in cargo/mix/npm.
The 2026 CI campaign (see `commit-taxonomy.md` section 4) makes workflow files a high-fix-rate baseline, so the 17.2% there is mostly unrelated CI repair. A first, looser
version of the script (any workflow file) gave 918 of 9,840 dependabot and 612 of 3,883 human, and was rejected as noise for exactly that reason.
Visible, specific failures I did find: codeql 4.38.1 (47 repos), lockfile desync after action bumps (IDApTIK#99 and others), `fix(deps): update Cargo.lock to resolve security advisories`
(hotchocolabot 3eac77e9, airborne-submarine-squadron 06ef8823; these are security fixes after a bump, not bump breakage).
* Interpretation limit: absence of a follow-up fix commit is not proof of safety (the PR may have been closed, never merged, or CI may have been red and ignored).
  357 of 9,840 dependabot commits sit on unmerged branches only.

## 7. Existing estate logic for deciding a bump is safe

All paths below are files I opened; counts are `grep -rIl` over the clones excluding explore.

1. `rsr-template-repo/.github/workflows/dependabot-automerge.yml` (copied to **176** repos as the same path; its test `tests/workflows/dependabot_automerge_test.sh` in 26).
   Uses `dependabot/fetch-metadata` (SHA-pinned, `update-type` output). Policy, fail-closed: PR author verified by numeric id 49699333; **only security updates with a GHSA id** whose
   advisory severity (GitHub Advisory API) is low or medium (CVSS < 7.0) and whose update type is patch or minor (never major) get `gh pr merge --auto --squash --match-head-commit`.
   Routine (non-security) updates are **never** auto-merged ("routine or non-qualifying update" -> manual review). It never uses `--admin`.
2. `rsr-template-repo/.github/dependabot.yml`: cargo is `open-pull-requests-limit: 0` (security PRs only); mix and npm group everything; github-actions group `*`, limit 2;
   explicit `ignore` hold on `github/codeql-action*` with the subpath trailing-`*` lesson documented inline.
3. `hypatia/lib/rules/dependabot_alerts.ex` (rule DA005): classifies alerts into `{:eliminate, conf}` (auto-bump), `{:substitute, reason}` (major or breaking, PR for review),
   `{:control, ...}`. `@strict_semver_ecosystems ~w(rust npm pip pypi composer nuget maven packagist)`: patch/minor on those get base 0.82-0.97 plus 0.01; other ecosystems minus 0.03.
   Thresholds are hand-set constants, not derived from outcomes. Note `hex`/`mix`, `julia`, `actions` are not in the strict list.
4. `hypatia/scripts/sweeps/estate-pr-automerge.sh` + `.machine_readable/merge-orchestration/pr-automerge-policy.json` (v1.0.0, 2026-10-19): bot-authored; every changed line a `uses:` pin, lockfile
   line or metadata path; no denylisted token (PIN-001 codeql 4.38.1 by version, SHA and ref; PIN-002 dtolnay/rust-toolchain...); pin delta resolvable from the action's own tag list and not major.
   "Cannot prove safe" and "proved unsafe" are separate verdicts. Header claims on 2026-09-26: 34 open dependabot PRs all looked safe; the classifier merges 9 and explains 25
   (24 re-introduce codeql 4.38.1; at least two hide a major). Referenced from `.github/workflows/tests.yml`; last touched 2026-11-21. Whether it runs on a schedule in production: **not found**.
5. `hypatia/docs/design/merge-orchestration/01-cve-bump-gate.adoc` (spec + schemas + fixtures only, "no runtime"): bump object `{ecosystem, package, from, to, semver_jump, bridge:{worst_classification,
   reachable_unmitigable, cve_ids}}`; invariants B1 (reachable unmitigable CVE => veto), B2 (major => never auto-arm), B3 (nix => flag, "closed, not merged"). Depends on `panic-attack bridge triage`,
   which the doc says must be built with `--features http` and needs OSV network access. **STATED, not wired.**
6. Supply-chain scanners: `cargo deny`/`cargo-deny` referenced in 678 files, `cargo audit` 992, `mix hex.audit` 31 (mostly standards CI-optimisation issue text and burble), `cargo-vet` 4, `osv-scanner` 6,
   `trivy` 1,209. These check known advisories and licences, not API compatibility.
7. `actions.lock` + `check-lock-sync.sh` (six clauses incl. transitive closure) + `lock-sync-gate.yml` (79 repos): structural validity of an action-bump state (section 5).
8. Searched and **not found** as estate logic: `cargo-semver-checks` (appears in exactly 1 file: a roadmap line in `metadatastician/burble/tools/selur-compose/docs/v0.2-roadmap.adoc`; ASPIRATIONAL),
   `cargo-machete` 0, `cargo-udeps` 2, a Hex or npm API-diff checker, a Julia `[compat]`-aware checker (CompatHelper appears in 7 repos; `[compat]`/`Pkg.compat` in 256 files), renovate (0).
   No Guix bump logic found beyond the pinned `channels.scm` (`(commit "ae77aeb9...")`) in 45 repos; Guix is not dependabot-supported in this history (0 guix dependabot commits).
   Julia bumps are human: `deps(julia): update dependencies` (10 commits), no bot.

## 8. What information would make a bump provably safe, and is it available?

"Provably safe" must be split into three claims: (A) the new version resolves and the project still builds/tests (empirical), (B) the new version's *interface* is compatible with how
we use it (checkable for typed languages), (C) the new version is *admissible* (no known vuln, licence ok, supply-chain ok, structurally valid for the host). Estate logic today covers
mainly (C) and a coarse numeric proxy for (B). The table says what exists upstream in each ecosystem. Items marked (general knowledge) were not verified in these repos.

| ecosystem | information that decides (B) | available in the estate today? |
|---|---|---|
| cargo | Public-API diff of the crate between versions (rustdoc JSON; `cargo-semver-checks` lints, general knowledge) intersected with the symbols *this* workspace actually uses; `Cargo.lock` gives the exact resolved graph in 166 repos; MSRV and feature-set deltas | Lockfiles yes (166 repos with Cargo.lock). API diff tool: **no** (1 roadmap mention). Used-symbol set: obtainable from compiling, **not computed**. Semver-based proxy exists (hypatia). |
| mix/Hex | Hex has no machine-readable API diff (general knowledge); Elixir typespecs/behaviours are partial; only `mix.lock` + compile + tests | 31 repos have `mix.lock`, 28 Elixir repos have none (no pin at all). Compile/test only. |
| npm/bun/deno | `.d.ts` or JSDoc diff; deno.lock integrity hashes | package.json in 71 repos, deno.lock 54, bun.lock 16, package-lock.json 1. Type diff: not found. Estate JS is little (269 dependabot commits). |
| Julia | `[compat]` bounds in `Project.toml` and the registry's recorded compat of the candidate; `Manifest.toml` in 19 of 84 repos | `[compat]` in 256 files; no bot, CompatHelper in 7 repos, bumps are manual. Resolver check is possible offline (general knowledge), **not run**. |
| github-actions | (1) tag-to-SHA resolution from the action's own refs (not the comment); (2) the action's nested `uses:` closure (actions.lock transitive closure); (3) `action.yml` input/output schema diff vs what the workflow passes; (4) host acceptance (startup_failure class) | (1) done in `estate-pr-automerge.sh` (needs network); (2) done in `check-lock-sync.sh` clause 3; (3) **not found**; (4) only as a hand-maintained denylist (PIN-001/002). |
| guix | Channel commit pin in `channels.scm` (45 repos) determines the closure; a bump is provable as a no-op if the derivation/store hashes for the project's manifest are unchanged (general knowledge: Guix derivations are content addressed) | Pins exist; derivation-hash comparison **not found**. 0 dependabot guix bumps ever. |
| all | Vulnerability reachability (panic-attack Patch-Bridge, OSV) | STATED in hypatia 01-cve-bump-gate.adoc; needs network and unbuilt binary. |

Observations that bear directly on type/trope design (for the programme, not conclusions about the owner's repos):
* The only two bump failure classes with *hard evidence* in these clones are (i) host-rejected action refs (codeql 4.38.1; 47 fix commits in 47 repos) and (ii) derived-artefact desync
  (`actions.lock` vs workflow YAML; 460 lockfile-only `actions.lock` commits plus 867 bounded-above follow-ups). Both are **structural** properties of a *graph of refs* (closure,
  well-formedness), not API compatibility. Neither is detectable by semver or by CI-on-PR.
* For cargo, the numeric signal says 530 of 1,496 parsed single-crate bumps (35.4%) are presumed breaking, yet the strict fix-after-bump rate for bump commits is 3.6% (115 of 3,178)
  versus 9.7% baseline. I cannot tell from git whether the presumed-breaking ones compiled, because no run data and no `cargo check` result are stored. A per-bump record of
  `(old, new, resolved-graph-hash, build result, API-diff verdict)` does not exist in these repos; that is the data that would allow a measured, rather than hand-set (0.82-0.97), confidence.
* Version labels are untrustworthy inputs in this estate (the `# v4` comments; 4.38.1 SHA labelled 4.38.0). Any proof must key on the **content address** (SHA, lock hash), not a name.
* Auto-merge scope is narrow by design: only GHSA-backed, low/medium, patch/minor updates. Routine bumps (the 9,840 commits) are manual or merged by other paths (merge path for
  non-security PRs is not visible in git; `estate-pr-automerge.sh` is the candidate). Cost/benefit of broadening is unmeasured here.

## 9. Departures and loose ends noticed (flag only; nothing changed)

* `dependabot.yml` declares `pip` (177 files), `nix` (107), `gomod` (4): banned-language ecosystems per estate policy. Dependabot did produce 59 py, 270 nix, 1 go commits.
* `dependabot.yml` declares `guix` in 59 files with zero resulting commits (inert config; also the 20 `package-ecosystem: ""  # See documentation for possible values` placeholder files).
* 1 repo carries `package-lock.json` (policy: refused). It is `hyperpolymath/Skein.jl/package-lock.json`.
* `cooldown` (delaying bumps of brand-new releases, general knowledge: Dependabot option) is configured in 1 of 447 files, although the codeql 4.38.1 incident was a brand-new release failing.
* `hyperpolymath/explore` fork: 447 dependabot commits that are not the owner's behaviour; excluded in headline counts above where stated.
* Counting caveat: 5 commits of 87,302 header lines were dropped as duplicates (same repo+hash seen twice across refs).

## 10. Reproduce

```
cd /tmp/bm
# dump.sh <owner/repo>  -> C/F lines (commit header, file names), all refs, no merges, no renames
cut -f1 /home/user/estate/.stats.tsv | xargs -P8 -I{} ./dump.sh {} > dump.tsv
git -C <repo> rev-list HEAD --no-merges  # -> head.tsv
perl an.pl        # bump_commits.tsv: repo hash onHEAD kind eco lockonly fixafter author subject
perl semver.pl    # grouped/single and semver levels
perl fab2.pl      # fix-after-bump vs baseline
perl lock.pl      # actions.lock desync after dependabot workflow bumps
```
