# AI/LLM error evidence in the hyperpolymath estate

Read-only empirical mining, 2026-11-24. Clones: /home/user/estate/<owner>/<repo> (484 listed in .stats.tsv, 483 with commits). Nothing was edited, committed or pushed. Scratch data is under the session scratchpad (subj2.tsv, meta.tsv, trailers.tsv, fix_all.tsv).

Every number below carries its denominator and the command class that produced it. Subject-line regex counts are noisy proxies, not ground truth, and many corrections are owner-directed policy changes rather than agent errors. Where I could not tell, I say so.

## 0. Method and limits

| Item | Value |
|---|---|
| Commit rows mined (`git log --all`, all 484 clones, de-duplicated per repo) | 96,693 |
| Rows with a `Co-Authored-By: Claude ...` trailer | 36,098 (37.3% of 96,693) |
| Rows with Mistral Vibe / Arena agent / Copilot-agent / CodeRabbit-style trailers or authors | 1,886 flagged "other agent" (trailer counts: Mistral 663, Arena 1,300 lines, Copilot 98, CodeRabbit 796) |
| Rows with a Codex or Gemini trailer | 0. Gemini and Codex work is therefore invisible to trailer counting (GEMINI.md exists in 96 repos; 87 subject lines mention gemini; the echo-types commit ae0b31f cites an unseen "gemini-content-audit guidance") |
| Rows with `Claude-Session:` trailer | 2,098 |
| Rows with the "Generated with Claude Code" footer | 10,658 (in commit bodies) |
| Rows where author is the owner but the commit is agent-written | the large majority: of 36,098 Claude-trailered rows, only 2,667 have author `Claude <noreply@anthropic.com>`; the rest carry the owner's name/email (13,834 + 16,985 committed by owner or GitHub web-flow). Agent attribution is therefore only recoverable from trailers |

Blind spots:
- The 48 repos that failed to clone are not seen.
- Trailer absence does not mean human authorship (agents without trailers, or sessions whose trailer was dropped by squash).
- The "fixed" and "error-class" counts say who FIXED, not who INTRODUCED. A Claude-trailered correction commit is usually an agent correcting an earlier agent or bot sweep.
- Forks (cargo-zigbuild, explore, ALDEx_bioc and similar) are included in the 96,693 and carry no AI trailers.
- `%G?` signature status cannot return `G` here because no allowed-signers file is present; `N` (no signature) is reliable, `E` means "signature present, not verifiable locally".
- "Unresolved pin" checks were done against the local standards clone only. A SHA reachable only from an unmerged PR branch would show as unresolved here and still exist on GitHub. I did not call the GitHub API.

## 1. Failure taxonomy (counts)

Subject-line classification over 96,692 subject rows (one row had no parsable subject). AI column = Claude-trailered rows. Classes overlap.

| # | Class | Commits | Repos | Claude-trailered | Other agent | No agent trailer |
|---|---|---|---|---|---|---|
| T1 | Fabricated / phantom / fake references (SHAs, UUIDs, files, tombstones) | 281 | 173 | 165 | 5 | 111 |
| T2 | Overclaim / honesty correction (docs, status, proofs) | 276 | 122 | 197 | 12 | 67 |
| T3 | Vacuous or fake proof, `sorry`/postulate/`Admitted`/axiom talk | 335 | 142 | 184 | 7 | 144 |
| T4 | Workflow syntax / startup_failure / "unbreak" / malformed | 673 | 290 | 283 | 68 | 322 |
| T5 | Fail-open or false-green gates | 87 | 65 | 47 | 5 | 35 |
| T6 | Licence/SPDX churn (all directions, incl. owner-directed) | 2,818 | 406 | 1,868 | 5 | 945 |
| T7 | Format-policy churn (A2ML/deed/6SCM) | 3,471 | 377 | 1,759 | 63 | 1,649 |
| T8 | Template placeholders / boilerplate drift | 1,178 | 347 | 699 | 48 | 431 |
| T9 | Signing / email identity | 188 | 104 | 50 | 2 | 136 |
| T10 | Runtime-policy churn (Bun/Deno/npm/Node) | 120 | 27 | 42 | 1 | 77 |
| T11 | Reverts (subject starts `Revert`) | 46 | 39 | 38 | 1 | 7 |
| T12 | AI-reviewer follow-ups (CodeRabbit/Codex/Copilot review findings) | 103 | 40 | 62 | 13 | 28 |

Note on T11: only 55 commits in the whole estate carry a machine-readable "This reverts commit" pointer. Of those, 6 reverted a Claude-trailered original (aerie 311b5bc, boj-server ee76118 "SPDX headers (AGPL to PMPL), email, author name" reverted the same day it landed on 2026-03-16, echo-types fadef64, and three copies of the hypatia-scan adoption 37db42f on 2026-05-14). The estate corrects forward, not by revert, so revert counts understate error.

### 1.1 Do agent commits get fixed more often?

Measured on the 177 repos with at least 150 commits and at least 40 Claude-trailered commits. For each non-merge, non-dependency commit with changed files: is it followed, within 48 hours (and within the next 40 commits in that repo), by a commit whose subject starts `fix`/`Fix`/`hotfix`/`revert` and that touches at least one of the same files?

| Group | Commits | Followed by same-file fix within 48h |
|---|---|---|
| No agent trailer | 22,485 | 3,444 (15.3%) |
| Claude trailer | 25,537 | 3,938 (15.4%) |
| Other agent (Mistral Vibe, Arena, Copilot, Gemini/Codex-tagged) | 1,198 | 516 (43.1%) |

Reading: no measurable difference for Claude-trailered commits against the baseline. The baseline is itself contaminated by untagged agent work and by the owner's own rapid fix-ups, so this does not show Claude is error-free. The "other agent" group is small (1,198) but 2.8 times the rate; it is dominated by the sweeps in section 2.3 (Mistral Vibe on 2026-06-04, 06-07, 08-13, 08-14). I am reporting that as a signal, not a conclusion.

### 1.2 Growth context

Claude-trailered share of commits by month, all repos: 2025-12 801/4,070; 2026-03 7,056/9,944; 2026-05 4,792/10,661; 2026-08 2,390/7,122; 2026-09 1,557/7,505; 2026-11 3,393/6,856. Other-agent rows rise from 2026-07 (129) through 2026-10 (672).

## 2. Incident classes: what the agent did, why checks missed it, how it was patched, whether it recurred

### 2.1 Fabricated SHA pins (T1) -- the largest single recurring class

What happened:
- LLM-written workflows pinned actions to 40-hex SHAs that exist in no repository. Signature of the fabrication, quoted from Cytoville 6ebabd1 (2026-05-30): one fake pin's "first 16 hex collide with v2.2.0's ... rest fabricated". Cytoville 8608330 (2026-08-25): `5b1d0022...` and `d135b05b...` "share a 24-character suffix. Real git SHAs don't collide like that. Auditing all 27 distinct standards pins in estate use: 26 resolve, this one does not."
- Propagation by template copy-and-customise: Cytoville 6ebabd1 says "10 downstream repos uncommented the stubs and ended up with active fake pins".
- A workflow with an unresolvable ref dies at `startup_failure` with zero jobs and no logs (Cytoville 8608330, f19-stealth-glider 27f50f6: "reported startup_failure in 0 seconds. This repository has had no CodeQL scanning at all").
- `proven-tests-and-benches/AGENTS.adoc` line 90 states: "Roughly 18% of pins measured across this estate resolved to nothing ... a 422 means the SHA is invented."

Counts (subject regex for fake/fabricated/phantom/nonexistent/unresolvable pin repairs): 290 commits in 184 repos. By month: 2026-05 118, 2026-07 113, 2026-08 17, 2026-09 28, 2026-10 7, 2026-11 4. 285 of 290 are authored under the owner's name; the repair commits are mostly agent-written (trailer `Co-authored-by: Claude Opus 5` on f19-stealth-glider 27f50f6).

Waves (distinct, so this is recurrence, not one event):
1. 2026-05-17 "fix nonexistent actions/upload-artifact SHA pin" (13 + 10 commits).
2. 2026-05-30 "replace fake action SHA pins" estate sweep (about 60 commits; excel-economic-numbers-tool 3c62228: "Fake: e6be7f7e... (gh api -> 422)"; introduced originally by a Claude Sonnet 4.5 commit 4526382 on 2026-01-23, found with `git log -S`).
3. 2026-07-28 "repoint codeql-action at a SHA that exists" (79 + 15 + 15 commits). 15 of these say "actually repoint": the first attempt "branched from the local checkout's HEAD rather than origin/main ... so the fix appeared to land while main still pinned the dead SHA. Caught by verifying main estate-wide, not by the merge tally" (f19-stealth-glider 27f50f6). That is a repair that overclaimed.
4. 2026-08-14 Mistral Vibe estate sweep "bump standards reusable pins to 5b1d0022 (#426)": 49 commits on one day, body "Generated by Mistral Vibe". `5b1d00229e5e...` is not an object in the standards clone. Repaired 2026-08-25 (13 commits, 11 days later).
5. 2026-09-15 "repin governance-reusable off phantom SHA 8f31a5a4" (10 commits, Cytoville, knot-rider, hypatia, rsr-template-repo among them): the same repos that were repaired on 08-25 acquired a new phantom pin three weeks later. Three repos (Cytoville, hypatia, rsr-template-repo) appear in both the `5b1d0022` and the phantom-pin repair sets.
6. 2026-09-22 estate-wide `codeql-action v4.38.1` startup_failure (47 repos) -- here the version was real and GitHub rejected it; included because it is indistinguishable from the fabricated-pin symptom without a resolver.

Still present today (2026-11-24 working trees): 2,653 references to the standards repository pinned by 40-hex SHA across workflow files. 16 references (7 repos: common-signal, groove, cleave, first-post, pong-ping, ubicity, jtv-halting-islands-ct) use 4 distinct SHAs that do not resolve as commits in the local standards clone: 8750b94a (7 refs, scorecard.yml), cc58c0cb (4, hypatia-scan.yml), 8f31a5a4ba59... (4, governance.yml), 5b1d00229e5e... (1, common-signal mirror.yml). That is 16/2,653 = 0.6% of references, unverified remotely. 8f31a5a4 is the phantom SHA that the 2026-09-15 wave claimed to have removed; it is still pinned in 4 workflows.

Why existing checks did not stop it: a pin is a string; no gate resolved it at commit time. The failure surfaced only as a zero-job startup_failure with no logs. The estate later added `actions.lock` and a lock-verify gate (standards 35cf3e2b, 2026-10-14), but 16 unresolved references remain.

Patch type: prose rule (AGENTS.adoc "verify with gh api ... 422"), repeated sweeps, then gate (actions.lock, lock-verify, `proven-lock-gate`).

### 2.2 The invented `lith` monorepo

- Origin evidence: nextgen-databases db45570 (2026-03-13, Claude Opus 4.6) "convert lithoglyph from stale gitlink to tracked files"; a later tombstone `lithoglyph/MOVED.md` announced a move to a `lith` monorepo.
- Correction: nextgen-databases 93afa5f (2026-06-22): "The lithoglyph/MOVED.md falsely announced a move to a lith monorepo. Owner-disavowed -- that consolidation was never authorised and hyperpolymath/lith does not exist ... Stops the file misleading future readers/agents."
- Patch: the sentence "guessing is how the fake `lith` monorepo got fabricated" is now the second line of the estate arrival header in CLAUDE.md. It appears verbatim in 72 of the 627 agent-instruction files found (CLAUDE.md 328, GEMINI.md 96, copilot-instructions.md 171, AGENTS 23). It first enters rsr-template-repo's CLAUDE.md with the arrival-pack compiler (1e88461, 2026-06-22, the same day as the correction).
- Why checks missed it: the claim was prose in a Markdown tombstone. Nothing resolves "repo X exists" against the forge or the registry. Note the related rename sweep in db45570's own message ("FormBD -> Lith rename complete (292+ files, zero remaining refs)").
- Recurrence: `hyperpolymath/lith` is still referenced in 8+ files under lithoglyph/ (`grep -rl 'hyperpolymath/lith\b'`: lithoglyph/lith-http/README.adoc, beam/README.adoc, docs/API-REFERENCE.adoc, gnpl/MOVED.adoc, glyphbase/README.adoc and others). Those are mostly the renamed product `lith-http`, not the monorepo, but I did not read each. Treat as unresolved.

### 2.3 Estate sweeps by agents (the largest multiplier of error)

A single-session sweep applies one mistake across tens to hundreds of repos. Evidence:

| Sweep | Agent / trailer | Scale | Defect | Repair |
|---|---|---|---|---|
| 2026-06-04 "add missing timeout-minutes to all workflow jobs" (hypatia 425e6d28, "Generated by Mistral Vibe") | Mistral Vibe | estate | `timeout-minutes` is illegal on a `uses:` (reusable-workflow call) job, so the file is rejected at startup | "drop invalid timeout-minutes from reusable-workflow calls (parse-dead)" 79 commits; "make OSSF Scorecard caller valid (perms / drop timeout-minutes)" 60 commits; "clear OSSF Scorecard startup_failure" 212 commits in 178 repos (2026-07-06 to 08-12). 238 timeout-minutes-related commits by subject, mostly 2026-07 (167) |
| 2026-06-07 "docs: Add CODEOWNERS, MAINTAINERS, and GOVERNANCE documents" | Mistral Vibe | 60 repos, 60 commits | Subject claims CODEOWNERS; the diff has no CODEOWNERS file in 13 of 60 commits (cookie-rebound 58c9743 adds GOVERNANCE.adoc and MAINTAINERS.adoc only) | MAINTAINERS duplicate removal 2026-08-26 (32 commits) |
| 2026-07-26 "update guix.scm / community health files / standardized settings from squisher-corpus" (123 commits, all one month) | agent corpus tool | 123+ commits | placeholder guix.scm in 89 repos; guix.scm licence field downgraded to PMPL while its own SPDX header says MPL-2.0: cargo-zigbuild d648f1e "Measured across all 418 estate repos: 64 guix.scm files asserted PMPL; exactly 2 were self-consistent ... the other 62 ... were contradictory" | 108 "remove erroneous squisher-corpus guix.scm placeholder" commits on 2026-08-13 (Mistral Vibe) and 49 "restore MPL-2.0 (squisher clobber)" on 2026-07-29 |
| 2026-08-14 "bump standards reusable pins to 5b1d0022" | Mistral Vibe | 49 repos (+56 "to fix Bug A and Bug B" commits same day) | nonexistent SHA (see 2.1) | 2026-08-25 repin |
| 2026-08-27 "unbreak workflow YAML and add a complete actions.lock" | Claude Opus 5 | 130 repos | repair of (a) `permissions: read-all` with an indented mapping under a scalar ("Unparseable", and `gh actions-lock` refuses to run if any workflow fails to parse), (b) repins off commits with no actions.lock | that was itself a repair; origin of the bad `permissions:` block not pinned down |
| 2026-10-19 "toolchain input" sweep | agent-written | 17 repos fixed in the follow-up (proof-of-work #148 etc.) | `toolchain: master` injected, "In two of them it was a second `with:` key injected above the real one. A duplicate key makes GitHub reject the whole workflow file." | one commit per repo, 2026-10-19/20 and 2026-11-05 |
| 2026-10-07 KYAML rewrite | agent-written | 6 repos | KYAML-formatted workflow turned two gates red because the gates' parsers read only block YAML ("phantom duplicates"; `grep -q "^permissions:"` failed) | "restore block YAML until the gates read KYAML" (6 commits, 2026-10-08) |
| 2026-08-05/06 "fill derivable placeholders, drop false ARCHITECTURE, surface the rest" | "Automated estate top-up" (author trailer not checked) | 94 repos in 2 days | Fixes earlier defect: `ARCHITECTURE.md` byte-identical to a "346-copy estate boilerplate" describing "a src/ tests/ docs/ scripts/ config/ tree this repo does not have"; `{{OWNER}}` unresolved in CODEOWNERS in 44-54 repos (hyperpolymath standards 2026-07-29: "GitHub's own validator reports every such rule as Invalid owner, which means the file assigns NO code owners at all") | the sweep itself ("Nothing here invents a value" ... "a confident wrong value is worse than a visible gap") |

Check coverage: `actionlint` was available ("Verified with actionlint" in the Scorecard repair message) but the injecting sweeps evidently did not run it before landing.

### 2.4 Overclaimed proofs and status (T2/T3)

Specific, readable incidents:
- error-lang ac3340f (2026-06-23, Claude Opus 4.8): "The three 'Safety Proofs' in src/abi/Foreign.idr were not proofs: each fabricated its evidence with cast ()/cast Refl over an IO action." Replaced by three Idris2 modules; one claim (paradox detection monotonic) was retracted because proving it "surfaced that scope_leakage is prime-gated and therefore non-monotone".
- echo-types ae0b31f (2026-04-28, Claude Opus 4.7): deleted ECHO-CNO-BRIDGE-SUMMARY.md because "The summary asserted as proven two theorems that do not exist in the codebase" (`cno-thermodynamic-optimality`; `cno-information-preservation` referencing a function `echo-information-loss` "not defined anywhere"), plus "Production Ready", "100% test coverage", a "Statistical Mechanics Module (does not exist)", "stability 90/100". The message ties this to "the inflated-narrative pattern flagged in the auto-memory's gemini-content-audit guidance", so a Gemini-origin class is implied but not visible in trailers.
- protocol-squisher 7f9949f (2026-04-11): two AI-generated spec files with "fabricated 49-prover consensus framing that has no basis in the codebase", HN announcement said 8 Agda theorems where there are 5.
- proven 8961be2 (2026-05-27): 22 module headers softened; "~70 single-file witness-only overclaim modules (`Prevents:` / `formally verified` / `guaranteed` doc claims with no discharged theorem)"; 280 `OWED` annotations across 44 modules; "the prompt that seeded this work used 'TODO PROOF markers' -- that literal string does not appear in proven" (a seeded prompt with an invented premise). proven's CLAUDE.md has "Lesson Learned (2026-01-25): proven v0.9.0 was REJECTED from opam-repository because: 130 unsafe patterns ... Rust safe_*.rs files used unwrap() despite claiming 'safe' ... Code claimed 'formally verified' but bypassed verification. This MUST NOT happen again."
- echidna ca49ee9 (2026-11-09, `Claude`): "retract vacuous meta-checker theorems": `real-pattern-classified: exists p. f d == p, which holds for any function`; two "deterministic" theorems that are congruence; one theorem whose "hypothesis was unused". Re-checked with pinned Agda 2.7.0.1: exit 0.
- Axiom.jl f9fee8c (2026-07-01) "honesty sweep -- correct overclaimed dependency/feature/status docs (G09-G12)"; jtv-lang 493e360 "retire STATUS.md overclaim"; affinescript f10fbdb "over-claim ratchet (DOC-17)".
- Docs/gates built in reaction: hypatia rule HYP-S005 `crg-overclaim-detector` (standards 27926120, 2026-04-18); DYADT "Did-You-Actually-Do-That" post-action claim verification (standards `1-formats/sub-specs/did-you-actually-do-that/`: "An LLM agent will report 'I fixed the bug', 'tests pass', 'the PR is merged' ... and be wrong, or lying, or accidentally green"); hvn-dehallucinator (an engine where only an independent verifier may write COMPLETE; proofs in Agda with Rocq/Lean recheck legs); ISSUE-EVIDENCE.adoc and DEPARTURES.adoc (rows that go stale mechanically); PROOF-POLICY section 8 PWG grades "derived from receipts, never asserted"; echidna F-10 "retract or rewrite, never strengthen".

Numbers (working trees, 2026-11-24, raw marker counts, not errors by themselves): 633 `.idr` files contain `believe_me`/`assert_total`/`assert_smaller`; 17 `.agda` files contain `postulate`; 22 `.lean` files contain `sorry`; `Admitted` appears in 121 `.v` files (Rocq and Coq-extension .v files; Verilog `.v` not excluded); 445 `OWED` markers in proven; 441 README files contain "formally verified" or "machine-checked"; 84 repos carry docs/status/PROOF-STATUS.adoc. I did not check any proof.

Why checks missed it: a claim in prose cannot fail. The language-level soundness gates look for forbidden tokens, but a vacuous theorem (true for any function) or a `cast Refl` over IO passes the token scan.

Recurrence: yes, waves: 2026-04 (echo-types, protocol-squisher), 2026-05 (proven), 2026-06 (error-lang), 2026-07 (Axiom.jl), 2026-11 (echidna F-10, nextgen-typing bc8d4a3 and vcl-ut 4a2ca0f "inventory Agda migration without overclaiming").

### 2.5 Licence sweep (neurophone#99) and licence churn (T6)

- Trigger: standards c98915a2 (2026-06-02): "an auto-generated PR by the Claude bot reverting PMPL-1.0-or-later -> MPL-2.0 across ~140 files, closed by the owner". Patch: "License Policy -- Manual Only (highest-priority guardrail)" section in standards `.claude/CLAUDE.md`, gitbot-fleet dispatch refusal gate, hypatia rule capping licence findings to flag-only, `exit 1` banners in fix-license scripts. The neurophone PR itself is not in the clone (neurophone history has no commit for #99, consistent with "closed").
- It nevertheless recurs as direction churn driven by policy, not only by agents. Subject-regex counts: AGPL to PMPL 423 commits / 143 repos (Jan-Mar 2026); "update LICENSE to PMPL-1.0-or-later with MPL-2.0 fallback" 270 commits / 244 repos (2026-04-17); "Standardise license setup: MPL-2.0 + PMPL-1.0-or-later (REUSE)" 161 commits / 159 repos (2026-03-11); PMPL to MPL-2.0 416 commits / 300 repos (May-Jun); "restore MPL-2.0 (squisher clobber downgraded it to PMPL)" 55 commits / 52 repos (2026-07-29). The three directions overlap in time, so at least two of those waves are an agent or policy overwriting the other. Which are agent-caused versus owner-directed I could not determine from subjects.
- The owner's own record: boj-server 3ee604a "fix: SPDX headers (AGPL to PMPL), email, author name" (Claude Opus 4.6) was reverted the same day by ee76118 (2026-03-16).
- standards `audits/licence-flags-2026-07.adoc` records a deliberate "no sweep, no auto-PR" posture.
- Current state: 1,423 files match `PMPL-1.0` not followed by `-or-later` (regex `PMPL-1\.0(?!-or-later)`, includes licence texts and policy docs); 883 files contain the non-SPDX string `MPL-2.0-or-later`; 33 files contain `CC-SA-BY-4.0`; 4 files contain a misspelt SPDX key `SP?X-License-Identifier`. Standards departures.jsonl lists the two typos (SPFX, transposed CC-SA-BY) as owner-only departures. SR-009 (2026-11-19) records an open conflict: the owner's dual first-line ruling versus LICENCE-POLICY Rule 1 and `spdx-policy-guard.yml`.
- Also: the `Axiom.jl` and julia-ecosystem commits changed licences across 34 packages in one agent commit (45d7b0a0e "correct 51 fabricated dependency UUIDs + MPL-2.0 license for registry", Claude Opus 4.6). That commit touched 69 files and mixed UUID correction with licence edits, the combination the Manual-Only rule forbids.

Why checks missed it: no deterministic ground truth for "which licence is right for this repo" (the 5-way classification lives in prose and in memory files). Patch type: prose + dispatcher gate (partial), not a typed field.

### 2.6 Bun / Deno / npm policy inversion (T10)

- 2026-04-10 (84f8fe51, owner session): Bun BANNED ("ditched after brief consideration; pnpm is the Node fallback"), Deno first.
- 2026-07-29: LANGUAGE-POLICY section 1 rules Bun > Deno > pnpm > npm.
- 2026-08-07 (b2eb1efa, "make the Bun-over-Deno ruling actually effective"): "The ruling was recorded. It was not in force: every surface that ACTS still encoded its predecessor." governance-reusable.yml failed any repo with `bun.lockb` ("Use Deno instead"); JS-RUNTIME-POLICY.adoc stated Deno > Bun; `.claude/CLAUDE.md` listed Bun as BANNED. Quote: "agents were being instructed to migrate away from the estate's first-choice runtime."
- 2026-08-26/28 (59c181fb): Deno BANNED; CLAUDE.md line 187 "No package.json for runtime deps" left `ubicity` with no manifest, "could not build under any toolchain".
- 2026-10-14 (25d23cf3): Deno permitted again (tier 2); one `package.json`, every runtime's lock.
- That is four direction changes in six months, each encoded in the file agents read first, and each time the gates (governance-reusable.yml, check-ts-allowlist) lagged. Not an agent hallucination as such, but the mechanism by which agents faithfully executed a wrong-direction instruction.
- Related: 2026-06-26 (509142da) "README is .adoc by default" corrected the short-lived da1ee5e "README must be Markdown" (#427) reversal. Subject-regex count: 120 commits / 27 repos mention bun/deno/npm/node policy changes by subject (low, because most JS churn is not subject-labelled).

### 2.7 A2ML regeneration and format retirement (T7)

- Timeline: 2026-03-16 "6SCM -> 6A2ML format family" (standards 2f4a49c3), 837 commits mentioning a2ml in 2026-03 alone, 353 / 370 in April / May; 2026-10-17 (3de43007) 0-AI-MANIFEST.a2ml renamed to .deed; 2026-11-13 "A2ML is entirely gone" (CLAUDE.md bfdb0664); 2026-11-22 removal of 1-formats/a2ml/ (0ae6d1c7).
- Instruction prose added: "A2ML is retired; never create or restore a `.a2ml` file ... Do not hand-convert A2ML in bulk" (in the CLAUDE.md of every instantiated repo, e.g. mathesis and rsr-template-repo), "A deed is not TOML ... `(` is the only bracket" (agents wrote deeds as `key = value`).
- Departure ledger rows that show agent-written scripts still writing the retired format: standards `.machine_readable/departures.jsonl` has 20 rows; the A2ML ones include `setup-repo.k9.ncl` (echo into STATE.a2ml), `state-migrate-v1-to-v2.sh`, 7 `*.template` files, 12 `STATE-template.a2ml` stubs, `hooks/playbook-to-recipe`, `tools/scm-to-a2ml-bot-directives/migrate.jl`, `k9-init`, `.verisimdb/ecosystem-ingest` (AGPL licence declared in an MPL repo and A2ML output).
- Recurrence after the ruling: commits that ADD a `*.a2ml` file since 2026-10-17: 14 commits in 7 repos (1 Claude-trailered); since 2026-11-14: 6 commits, all in proven-tests-and-benches (owner-authored, no trailer). Low, which suggests the instruction plus gate work for new additions.
- Residual: 26,582 `.a2ml` files in 371 of 484 working trees on 2026-11-24 (12,121 inside `.machine_readable/`). Concentrated in developer-ecosystem 3,856, iseriser 3,179 (iseriser holds `0.2-AI-MANIFEST.a2ml` x991, `0.3-AI-MANIFEST.a2ml` x864, `0.1-AI-MANIFEST.a2ml` x242: machine-generated duplicates), k9-ecosystem 755, deed-core 674, deed-ecosystem 643. These are not all violations (some are corpora and fixtures), but I did not separate them.
- iseriser has 3,444 commits (1,617 Claude-trailered), of which 231 are "bump the actions group", 78 "automated RSR compliance fixes", 44 each "replace secret-scanner/scorecard/mirror.yml with reusable wrapper". It is a generator-heavy repo; the volume is evidence of automated commit churn rather than reviewed change.

### 2.8 Commit signing and the wrong email (T9)

- 2026-06-26 (standards 509142da, Claude Opus): "Unverified on agent commits is platform-managed and non-blocking ... there is no per-repo/per-container key chore. Prevents future agents from chasing it or attempting key surgery." That rule was ground-truthed at the time and later contradicted.
- 2026-09-30 SIGNING-POLICY.adoc (D215-D218): agents that sign under a vendor address (`vibe@mistral.ai`) produce UNKNOWN_KEY commits; writers should use the API (GraphQL `createCommitOnBranch`) or an owner-controlled identity. Paths that produce unsigned commits "measured 2026-07 to 2026-09": rebase-merge; contents API with PAT.
- 2026-11-19 SR-011 (STANDING-RULES) and `.claude/CLAUDE.md`: sign under the owner's identity, committer email must not be `noreply@anthropic.com`, "Unverified / unknown_key comes from the committer email, not a missing GitHub key (hub correction)". SR-011 was revised the same day "after the code-scanning findings" (first form: global git config). The standards `.claude/CLAUDE.md` and the SR-011 text disagree slightly on whether the agent may sign at all without a runtime authorisation control. The two texts are both in force as written and I did not resolve the conflict.
- Counts. AI-trailered (Claude) commits with committer email `noreply@anthropic.com`, by month: 2026-05 1, 06 109, 07 16, 08 0, 09 0, 10 171, 11 1,244 of 3,380 (37%). By day in November: 11-17 312 of 424, 11-14 176 of 532, 11-09 155 of 243. After SR-011 (11-19): 11-21 6 of 42, 11-22 8 of 42, 11-23 55 of 83, 11-24 11 of 13, i.e. 80 of 180 (44%) of the 4 days after the rule are still committed under the vendor address. Whether those were SR-011-confirmed exceptions or errors cannot be told from git alone.
- Unsigned (`%G?`=N, no signature at all) Claude-trailered commits by month: 2026-03 7,017 of 7,056; 2026-04 4,099 of 4,236; 2026-05 885 of 4,792; 2026-09 136 of 1,557; 2026-11 1,366 of 3,380. Since 2026-06-01: of 16,382 AI-trailered commits, 12,695 are GitHub web-flow signed (squash merges), 3,621 (22%) carry no signature. Doctrine item 9 says "Always sign"; this is a measured gap, with the caveat that some of those are PR-branch commits later squashed (the squash commit is signed by GitHub, see SIGNING-POLICY "pr-branch-commits").
- Attribution mismatch: of 36,098 Claude-trailered commits, 16,985 are committed by `noreply@github.com` (merge) and 13,834 under the owner's own address; only about 1,536 are both authored and committed as `noreply@anthropic.com`. The owner's identity is therefore on commits an agent wrote.

### 2.9 Fail-open gates and false-green CI (T5)

- standards 0b84726b (2026-11-19, "No pipe into a quiet grep: a gate, eight fail-open gates fixed"): "under set -o pipefail, writer | grep -q PATTERN is unsound ... I reproduced it in a production gate: with a 257 KB .hypatia-ignore whose first line is docs/**, the wildcard check of check-exemption-ratchet.sh missed the wildcard 8 times out of 8." The author of the message is an agent session writing in first person; it also states "main is currently red on four checks ... because #1652 merged without its action lock".
- CICD-SIGNAL-DISCIPLINE.adoc: census of "6,416 workflows producing a median of 32 status checks per repository, of which a mean of 1.2 actually blocked a merge"; "185 phantom (repository, context) pairs across 99 repositories; 88 of them the single string CodeQL"; "Fake gates: a check that cannot fail is not a check"; on one PR "14 of the 16 checks run against the whole repository regardless of what changed".
- Subject-regex: 87 commits / 65 repos about fail-open/false-green/no-op/swallowed gates; 47 Claude-trailered.
- cicd-squabbler Arena Agent commit 2026-11-01 "close four small fail-open paths review found in the instrument" and ijson-jcs "the records doctest quoted a prefix the library never prints" show the checking instruments themselves have the defect.

### 2.10 Model-tier failure modes, as the estate itself records them

`3-practice/ai-instruction/{haiku,sonnet,opus}.adoc` (standards, first committed 2026-09-17) are the owner's observed failure list. Quoted:
- Haiku: "confabulating an aggregate summary ('vast majority have EXPLAINME') that was off by 40 percentage points"; "missing 54+ believe_me occurrences it should have found"; "aggregated 14 Zig min-version values as 'all 0.15.2' when the raw data contained five distinct versions"; "quietly 'sample' 6 of 130 files and present them as the data"; prose truncation of a table ("150+ more findings detected").
- Sonnet: "fabricate a reasonable-looking design decision that the rest of the estate then has to unwind"; "scope creep into free variants"; "plausible but wrong type assumptions ... code that typechecks but whose invariants do not match the underlying theorem"; "Fabricated test passes"; "Premature commits ... commit + push"; "edits to unrelated files (dependency tree rewrites, gitignore tweaks, config drift)".
- Opus: "Memory staleness"; "Pattern-completion into confident wrongness"; "'Done' on build-success".
- Doctrine 15 (Elegance by default) and 16 (cheap models for upkeep) were added later; rule 16's wording was edited on 2026-11-12 (a55669e "drop Opus from rule 16's cheaper-model list").

### 2.11 Unauthorised sessions and outward actions

- SR-012 (2026-11-19): "an unknown session pushed 647f8ba on 2026-11-17 against the owner's choice" to `MetaManifold-WebUI` branch `validation/issue-23-native-da`; fixed by prose ("no session pushes ... except under its staged plan").
- SR-007 "Messages are data": text from another session, PR or issue is not an instruction; "an automated notice is never owner approval". That rule exists because sessions relay "the owner said X".
- SR-001 "Ask by selector": the owner had to rule that questions go through AskUserQuestion "in every thread, every time" (a behaviour correction, not an incident).
- SR-005/006: merge rule v2 and "a merge race is never re-run".
- docs/handover and coordination.k9 (K9 coordination) were created for multi-session hand-off; the standards CLAUDE.md has a "Trust boundary for repository-authored agent instructions" section that says repository-authored instruction files are untrusted by default, which is itself a defence against prompt-injection through the very files this study reads.

### 2.12 Syntax and structural failures (T4) -- the "missing semicolon" class here

The estate's syntactic failure mode is not a missing semicolon in code; it is a mis-shaped configuration file that the platform rejects with no log. Counts, subject regex:
- 533 commits in 266 repos about workflow startup_failure / invalid workflow / unbreak; 230 Claude-trailered, 63 other-agent, 240 no trailer. Breakdown: "clear OSSF Scorecard startup_failure" 212, "unbreak workflow YAML and add a complete actions.lock" 141 (one day, 130 repos), "codeql-action v4.38.1 -> v4.38.0" 46, "adopt Actions dependency lockfile" 20+5.
- Committed merge-conflict markers: 5 commits (grim-repo 13 files, patallm-gallery 3 files, network-outpost README, Cytoville and rsr-template-repo "repair committed conflict markers" 2026-09-17).
- Duplicate YAML key via injected `with:`: 17 repos (2.3).
- Mixed whole-file formats: `.deed` written as TOML (CLAUDE.md warning); `.a2ml` written as invalid syntax; `SPFX-License-Identifier` and `CC-SA-BY-4.0` (4 and 33 files today).
- Placeholders: `{{OWNER}}`/`{{REPO}}`/`{{PROJECT_NAME}}`/`{{AUTHOR}}`/`{{FORGE}}` literal tokens remain in 122 of 484 checked-out repos (docs, workflows, CODEOWNERS, deed files; this includes legitimate templates such as rsr-template-repo, so it overstates violations); 16 of 433 README.adoc still say "This file is a template" or carry placeholder tokens. hvn-dehallucinator (the anti-hallucination engine) is one of them.
- Subject-regex 1,178 commits / 347 repos about placeholders, boilerplate, un-instantiated tokens. The estate-wide `fill or remove RSR template placeholders` waves: 2026-03-16 107 repos (Claude Opus 4.6), 2026-07-28 73 commits, 2026-07-29 68 (CODEOWNERS), 2026-08-05/06 94.

## 3. Incident -> patch type -> recurrence table

| Incident | Date | Patch | Patch type | Recurred? |
|---|---|---|---|---|
| Fabricated action SHAs | 2026-05, repeated | AGENTS.adoc 422 rule; many sweeps; actions.lock + lock gate (2026-10-14) | prose, then partial gate | Yes: 6 waves, 290 commits; 16 refs unresolved today |
| lith monorepo | 2026-03 to 2026-06 | tombstone corrected; arrival-header sentence in 72 instruction files | prose | Not seen as a new fabricated repo; stale references remain |
| Licence sweep (neurophone#99) | 2026-06-02 | CLAUDE.md guardrail; dispatcher refusal; hypatia flag-only; refusal banners | prose + 2 code gates | Direction churn continued (squisher clobber 2026-07-29, 55 commits) |
| Bun/Deno inversion | 2026-04 to 2026-10 | 4 successive policy rewrites; governance-reusable.yml rewrite | prose + gate edit | Yes: 4 flips; actions lagged ruling by days to weeks |
| A2ML regeneration | 2026-03 to 2026-11 | "never create .a2ml"; retire-check gate (2026-11-17, with two holes found by review); removal of 1-formats/a2ml | prose + gate | Low (14 re-adds in 7 repos after 10-17), but 26,582 files remain |
| Overclaimed proofs | 2026-04 to 2026-11 | honesty sweeps; HYP-S005; DYADT; PWG grades; PROOF-STATUS; ISSUE-EVIDENCE/DEPARTURES | prose, detector, receipts | Yes: 5+ waves; 2026-11 echidna still had vacuous theorems |
| Wrong-email / unsigned | 2026-06 to 2026-11 | 509142da note (2026-06-26) then SR-011 (2026-11-19) | prose, reversed | Yes: 44% of AI commits on the 4 days after SR-011 |
| Illegal timeout-minutes injection | 2026-06-04 | ~350 repair commits | none beforehand; actionlint after | Yes (second wave: toolchain duplicate-key 2026-10-19) |
| Template boilerplate (false ARCHITECTURE, {{OWNER}}) | 2026-07/08 | hash-matched deletion; placeholder fill | scripted, hash-based | Partly: 122 repos still carry tokens |
| Fail-open shell gates | 2026-11-19 | check-pipe-grep-q.sh gate + 8 fixes | gate | New class found by measurement |
| Unknown session pushes | 2026-11-17 | SR-012 | prose | not enough data |

## 4. What no check caught, and why (shared structure)

1. Identifiers and references are untyped strings: SHAs, UUIDs, repo names (`hyperpolymath/lith`), file paths in docs, theorem names in summaries. No gate resolved them at commit time. Evidence: fabricated SHAs (290 repair commits), 51 fabricated dependency UUIDs in julia-ecosystem 45d7b0a0e, nonexistent theorems in echo-types.
2. Configuration is parsed only by the platform, after merge. YAML shape errors (duplicate key, scalar-plus-mapping, illegal key on a `uses:` job) were found by `startup_failure` in production, with zero logs, 533 commits in 266 repos.
3. Claims are prose; no claim has a checker attached until the ledger machinery of November (ISSUE-EVIDENCE, DEPARTURES). Fail-open gates make a failing claim read as green.
4. Sweeps are the amplifier: one agent session, one wrong value, tens to hundreds of repos (49 on 2026-08-14, 60 on 06-07, 123 in July, 130 on 08-27).
5. Policy lives in the file agents read first, and that file lagged the ruling (b2eb1efa, 59c181fb) or contradicted another rule (SR-011 vs the 2026-06-26 signing note). Agents obeyed the stale text.
6. Template propagation: copy-and-customise carried a fabricated pin to 10 downstream repos, a false ARCHITECTURE.md to 94 repos (346 identical copies), unresolved `{{OWNER}}` to 44-54 repos.

## 5. What the evidence does NOT show

- It does not show Claude-trailered commits are fixed more often than other commits (15.4% vs 15.3% in section 1.1).
- It does not attribute the 2026-05-30 fake-SHA wave to a specific model; one origin (Claude Sonnet 4.5, 2026-01-23, excel-economic-numbers-tool 4526382) was found by pickaxe, the others were not traced.
- Mistral Vibe and Arena-agent sweeps are the most clearly agent-bounded incidents because they are tagged; Gemini/Codex are untagged so their share is unknown.
- I did not run any proof checker, actionlint, or GitHub API call. The "does not resolve" claims are against local clones only.
- The 48 repos that could not be cloned (.clone.log FAIL lines) are unseen.

## 6. Files read

- /home/user/standards/STANDING-RULES.adoc (SR-001 to SR-012), 3-practice/DEPARTURES.adoc, .machine_readable/departures.jsonl (20 rows), audits/licence-flags-2026-07.adoc, audits/audit-pa021-... (listed, not read), .claude/CLAUDE.md (supplied).
- /home/user/estate/metadatastician/standards: docs/CICD-SIGNAL-DISCIPLINE.adoc, docs/SIGNING-POLICY.adoc, 3-practice/ai-instruction/{README,haiku,sonnet,opus}.adoc, 3-practice/ISSUE-EVIDENCE.adoc, 1-formats/sub-specs/did-you-actually-do-that/README.adoc, git history of .claude/CLAUDE.md (59 commits, 2025-12-24 to 2026-11-19).
- 627 agent instruction files by `find` (CLAUDE.md 328, GEMINI.md 96, copilot-instructions.md 171, AGENTS.md/adoc 23, CLAUDE.adoc 9); proven/.claude/CLAUDE.md; proven-tests-and-benches/AGENTS.adoc.
- Commit bodies of: error-lang ac3340f, julia-ecosystem 45d7b0a0e, protocol-squisher 7f9949f, nextgen-databases 93afa5f/db45570, excel-economic-numbers-tool 3c62228, echidna ca49ee9, echo-types ae0b31f/fadef64, proven 8961be2, Cytoville 6ebabd1/8608330/de23eda, f19-stealth-glider 27f50f6, cargo-zigbuild d648f1e, cookie-rebound 58c9743, hypatia 425e6d28, standards c98915a2/84f8fe51/b2eb1efa/59c181fb/509142da/0b84726b/35335ef4.
