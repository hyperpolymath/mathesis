# Mathesis and canon cluster: findings

Read-only research, 2026-11-24. Sources read: `/home/user/mathesis` (HEAD `3bbd137`, 2026-11-23),
`/home/user/standards` (HEAD `75d38f8`, 2026-11-22), and the clones
`/home/user/estate/hyperpolymath/{contractiles,k9-ecosystem,deed-core,deed-ecosystem,resource-algebra}`.
Every claim cites a file I opened or a command I ran. Status words:
**PROVED** = a proof source exists, the named lemma is in it, and the home repo records a checker receipt;
**STATED** = spec, policy or pre-registration only; **ASPIRATIONAL** = roadmap or proposal;
**IMPLEMENTED-UNPROVED** = code or a gate exists, no proof (or the "proof" is vacuous or unchecked).

## 0. What was and was not run here

- `which agda coqc lean idris2 nickel rocq` finds none of them; only `bun` is installed. **I re-ran no proof.**
  "PROVED" rests on the home repositories' own receipts, which I read.
- Ran: `bun /home/user/standards/1-formats/deed/tools/deed_lint.js --proof-receipt-json verification/receipts/theory_praxis.deed`
  (standards HEAD, not the pinned reader). It derives `PWG-2ii` for each of THY-1, APP-1, APP-2, APP-3, APP-4;
  every leg reads `agda:source:proven:AGDA-VERIFIED`, `rocq:re-proved:proven:RECONCILED`, `lean:re-proved:proven:RECONCILED`, one current receipt each.
- Ran: `sha256sum` on the proof files. `FeatureReachability.agda` = `4e39d6ae...4564`, `FeatureReachability.v` = `e2f90043...8cb1`,
  `FeatureReachability.lean` = `55a4116e...e39b`, `Applied/Missing.agda` = `b2d01609...332c`, `Cohort.lean` = `e3ff1d65...0052`,
  `Cohort.v` = `1ff2d860...269f`. Each equals the `(file ... :sha256 ...)` of the current receipt's manifest in
  `verification/receipts/theory_praxis.deed`. So the tree I read is the tree the receipt describes.
- Ran: text scan for `postulate|sorry|Admitted|^axiom|believe_me` over all 11 gated proof files: 0 hits in each.
- Ran: `bun scripts/atlas/census-atlas.mjs check` -> "PASS: generated atlas matches census".
- Ran: `bun scripts/registry/theory-ledger.mjs verify` -> "PASS: the theory ledger matches the admissions and the claim pins".
- Ran by hand four `must` probes of `.machine_readable/contractiles/must/must.k9.ncl`: `no-hand-typed-grade` passes;
  `receipts-stay-home` finds exactly `verification/receipts/theory_praxis.deed`; `rows-have-provenance` finds 0 rows without a 40-hex commit; `theory-ledger-current` passes.
- Ran: `bun test tests/registry tests/atlas tests/applied` with `MATHESIS_STANDARDS=/home/user/standards`:
  31 pass, 2 fail. The failures are the design working: `claims-registry.mjs:143` throws
  "deed_lint.js is not the pinned canon reader (sha256 bd276e40..., pinned 29278b46... at 940a27af...)".
  With the pinned reader extracted by `git show 940a27af:1-formats/deed/tools/deed_lint.js` (its sha256 is the pinned `29278b46...`): 90 pass, 4 fail,
  and all 4 are `ENOENT` for files my one-file scratch copy of standards lacks (`scripts/proof-inputs-sha256.sh`, `check-proof-receipt.sh`, two fixtures). Not defects.
- Ran: `bun test deed_lint.test.js` in `standards/1-formats/deed/tools`: 341 pass, 0 fail, 968 expects.
- Ran: `bash scripts/departures.sh report` in standards: "20 of 20 rows evaluated at 75d38f80b6cb: 20 present, 0 RESOLVED, 0 unevaluated."
- 48 repos failed to clone (`/home/user/estate/.clone.log`), among them `hyperpolymath/contractiles-a2-lab`,
  `metadatastician/proto-chora`, `metadatastician/kyx`, `hyperpolymath/prover-images`. I say nothing about their content.

## 1. Shape of the cluster in one page

Three verbs (`docs/proposals/mathesis-re-anchoring.adoc`, "Three verbs"): **standards prescribes**, **each home repository proves and keeps receipts**, **Mathesis describes** and derives status from the receipts.
The one idea of the research programme (`docs/proposals/mathesis-research-programme.adoc` line 75): "Status is a monotone function of evidence. More evidence does not lower a status. Less evidence does not raise one. A chain of steps is as strong as its weakest step."

Mathesis has three shelves (`README.adoc`, `docs/theory/README.adoc`):

| Shelf | Content found | Proof state |
|---|---|---|
| Atlas | census of 465 public repos, 249 rows (`docs/atlas/census/*.jsonl`); claims registry of 53 pins from 4 repos; 3 bridge candidates | generated, gated; no theorem |
| Theory | exactly 1 admitted theorem, THY-1 (`docs/theory/generated/index.adoc`: "Theorems: 1.") | `PWG-2ii` derived |
| Applied | cohort model + APP-1..APP-4 (`verification/proofs/agda/Applied/`), input schema, management-accounting design | `PWG-2ii` derived for 4; design docs have no model |

The directories the task names as `src/bridges`, `src/definitions`, `src/aspects` are RSR template stubs:
`src/bridges/.gitkeep` is 0 bytes, `src/definitions/README.adoc` is 3 lines (a title only), `src/aspects/README.adoc` is the template text about "-isers".
The real bridge data is `docs/atlas/claims/bridges.jsonl`. `docs/whitepapers/*`, `docs/governance/*/README.adoc`, `verification/{benchmarks,coverage,fuzzing,safety_case,simulations,traceability}/README.adoc` are 3-line stubs too.

What "theory no single system owns" is recorded: **one theorem** (THY-1). The next candidates (token lattice) are stated, not proved, in Mathesis.

## 2. Mathesis: proved constructs

### 2.1 THY-1: reachability is monotone under additive features. PROVED

Files: `verification/proofs/agda/FeatureReachability.agda` (156 lines, imports nothing),
`verification/proofs/coq/FeatureReachability.v` (119), `verification/proofs/lean4/FeatureReachability.lean` (171).

Formal content:
- `module Monotone (Node) (Ctx : Set1) (_<=_) (Edge : Ctx -> Node -> Node -> Set) (edge-mono : F <= G -> Edge F u v -> Edge G u v)`.
  `data Reach F root : Node -> Set` (constructors `here`, `step`).
  `reach-mono : F <= G -> Reach F root v -> Reach G root v`; `absent-below : F <= G -> not (Reach G root v) -> not (Reach F root v)`.
- `module Cargo`: features requested as a predicate `Request = Feat -> Set`; feature implications as **Horn rules** (`premises`, `conclusion`);
  `data On S : Feat -> Set` = least set containing the request and closed under the rules (`asked`, `implied`);
  `on-mono`; `record Edge t S u v` with a feature guard and an arbitrary per-target condition `targetOk`;
  `all-features _ = T`; corollary
  `absent-under-all-features : (forall t -> not (Reach t all-features root v)) -> forall t S -> not (Reach t S root v)`.

Status record (`docs/status/PROOF-STATUS.adoc`): Agda 2.7.0.1 `--safe --without-K --cubical-compatible`, Rocq 8.18.0 (`Print Assumptions` closed for 11 declarations, `coqchk -o` clean), Lean 4.29.0 ("axioms: none for 8 theorem(s) and 48 definition(s)"), CI run 44190913019 on `8c55804`.
Negative controls recorded: "a planted postulate, a planted false claim, a non-terminating definition, and a `reach-mono` that skips the monotonicity step" all rejected.
Transport Agda -> Dedukti is `BLOCKED` (minimal 7-line reproducer described); both legs are `re-proved`, correspondence `RECONCILED` "by reading, item by item".
The grade was `PWG-1` from 2026-11-10 to 2026-11-17 and fell to `PWG-2ii` when standards#1625 required a digest-pinned container image; the ledger `docs/theory/ledger.jsonl` (6 entries) records each change, including two `ungraded` intervals when the reader pin moved.

Trust boundary, stated by the repo: "Applying it to Cargo: `ASSUMED`: Cargo's resolver activates exactly the modelled edges. Features unify by union, no feature removes a dependency."
Dependant: `standards/docs/UPSTREAM-DEPENDENCY-WATCH.adoc` lines 73-90, which cites the theorem by name.

Engineering reach:
- **Unsafe vs safe dependency bumps / audits.** One `cargo tree --target all --workspace --all-features -i <crate>` is a sound absence check for every feature subset. It turns "is the vulnerable crate reachable in any build?" from a 2^n feature-matrix question into one query.
- **CI cost.** The same theorem licenses collapsing a feature matrix for *absence* properties (not for presence or behaviour).
- **General form.** `Monotone.reach-mono` is not about Cargo. Any system where a "context" only *adds* edges has it: additive config overlays, workflow `uses:` closure under added jobs, import cones under added optional modules. The precondition to check each time is `edge-mono` (no context removes an edge); where a feature can remove a dependency the theorem does not apply.

### 2.2 The `Val` type: missing is a constructor, not zero. PROVED (APP-1)

File: `verification/proofs/agda/Applied/Cohort.agda` lines 55-96.
```
data Status : Set where illustrative estimate reported verified definitional : Status
data Val (A : Set) : Set where  missing : Val A ;  given : Status -> A -> Val A
zipWith f (given s a) (given t b) = given (s ⊓ t) (f a b) ;  zipWith f _ _ = missing
_∧ᵏ_   -- Kleene conjunction: a known false decides, else missing absorbs
```
Theorems in `Applied/Missing.agda` (294 lines): `closings-missing`, `missing-persists` (once a closing balance is missing, every later one is),
`verdict-yes` (a "yes" needs every period to be a known "yes"), `breach-decides` (a known breach gives "no" whatever is missing),
`verdict-not-false`, `verdict-missing` (no known breach + any missing value => verdict is `missing`), `verdict-not-yes`.
PROOF-STATUS records an audit finding worth keeping: "Before 2026-11-17 the middle clause was stated by no declaration (proof audit 2026-11-16, finding 33)". The prose claimed a three-clause sentence and one clause had no theorem; the owner ruled "prove, not narrow".

Engineering reach: the **three-outcome discipline** (yes / no / not-checked). This is the type-level cure for "silent green": a skipped CI job, an unparsed SARIF file, an absent report-back or a tool that did not run is `missing`, and `missing` cannot become `given true`.
The same shape appears in standards as proved Idris2 (`ReportBack.idr`, section 5.4) and as policy ("A check that did not run", K9-CONTRACT-SPEC "Reporting a check that did not run"; ISSUE-EVIDENCE `unevaluated`).
For LLM errors: an agent asked for a number it does not have must return `missing`, and the type has no path from `missing` to a numeral.
The input-schema validator `scripts/applied/inputs.mjs` enforces the data side: "The validator refuses a missing input with the value `0` or `\"\"`, and a `null` value with any other status" (`applied-systems/methods/input-schema.adoc`).

### 2.3 `Covers u v`: status never upgrades. PROVED (APP-4)

File: `Applied/Status.agda` lines 128-180 of the proofs, `Applied/Missing.agda`.
```
record Covers {A} (u : Status) (v : Val A) : Set   -- v is given with a status at least u
zipWith-needs : Covers u (zipWith f x y) -> Covers u x × Covers u y
map-needs     : Covers u (map f x) -> Covers u x
missing-uncovered : Covers u missing -> ⊥
```
Then one `*-needs` lemma per output of the model (`members-needs`, `receipts-needs`, `payments-needs`, `closing-needs`, `shortfall-needs`, `cashOk-needs`, `hours-needs`, `capacityOk-needs`, `gap-needs`).
The file's own summary: "One statement carries both... Read one way, an output is missing when an input it depends on is missing (APP-1)... Read the other way, an output is never more certain than an input it depends on (APP-4)."
Supporting lattice facts by exhaustive case split: `⊓-≤ˡ`, `⊓-≤ʳ` (25 cases each), `⊓-assoc` (125 cases), `⊓-identityʳ`.

Engineering reach: this is **overclaim prevention as a type**. Any derived artefact (a dashboard number, a README badge, a "verified" line, an LLM summary) carries the meet of the statuses of its inputs. It is the applied-shelf twin of ledger rule 3 ("A row's status may only be as strong as the weakest step it depends on", `standards/docs/README-EXPLAINME-STANDARD.adoc` line 267).
Note the applied order (`illustrative < estimate < reported < verified < definitional`) is a different vocabulary from the proof tokens; the programme says "the default answer is that no map exists until one is proved" (Q-4.1).

### 2.4 Cash identity and the least funding gap. PROVED (APP-2, APP-3)

File: `Applied/Cash.agda` (262 lines): `record Laws (N : Number)` = ordered abelian group; `cash-identity`, `gap-sound`, `gap-least`, `max-least`; `Applied/IntLaws.agda` proves the integer instance satisfies `Laws`.
Rocq: `Cohort.v` 931 lines, 89 `Theorem|Lemma`; Lean: `Cohort.lean` 1006 lines, 93 `theorem|lemma` (my count by grep; PROOF-STATUS says 102 theorems by the gate's audit, a different counting rule).
Reach for software engineering is indirect: the *pattern* "sound and least" (the smallest change that restores an invariant, proved minimal) is what a minimal safe version bump or a minimal relaxation of a tolerance would need. No such instance exists in the cluster.

### 2.5 Generated worked examples checked by the type checker. PROVED per example

`applied-systems/finance/cohort-economics/examples/{simple,exact,approximate}.jsonl` -> `just applied-build` -> `verification/proofs/agda/Applied/Example/*.agda` (112 lines each, marked generated in `MANIFEST`).
"Agda accepts that module only if the model computes every expected output, missing ones included"; a control in `tests/golden/check_controls_test.sh` shows "a missing value read as zero fails it" (EXPLAINME).
Reach: golden tests whose "expected" column is checked by `refl`, so a stale golden file is a type error, not a diff someone approves. Template/golden drift.

### 2.6 What the Mathesis proof ledger says, and where its documents disagree

Receipt-derived truth (ran the reader): 5 theorems at `PWG-2ii`, 0 at `PWG-1`. Registry census line (`docs/atlas/generated/registry.adoc` line 13):
"Census: 0 at `PWG-1`, 5 at `PWG-2ii`, 31 at `PWG-2i`, 0 at `PWG-3`, 12 `ungraded`, of 48 theorems. 5 demonstrations and assumptions are listed and not graded."

Hand-written documents that lag that derived value (found by reading; these are status drift in the repo that exists to prevent it):

| Document | Says | Derived / actual |
|---|---|---|
| `docs/status/PROOF-NEEDS.adoc` rows THY-1, APP-1..4 and line 90 | "the receipt derives `PWG-1`" | `PWG-2ii` since 2026-11-18 |
| `EXPLAINME.adoc` line 306 | "The registry derives `PWG-1` for THY-1" | `PWG-2ii` |
| `EXPLAINME.adoc` line 71 | "18 claims from 3 repositories"; "Of 17 theorems, 11 are at `PWG-1`" | 53 pins from 4 repos; 0 at `PWG-1` of 48 theorems |
| `EXPLAINME.adoc` line 94 | "`bridges.jsonl` holds 2 candidate records" | 3 |
| `verification/proofs/lean4/MANIFEST` header | "Ground-truthed 2026-07-17 with Lean ... v4.15.0" | `lean-toolchain` pins v4.29.0 |
| `verification/proofs/agda/Applied/Cohort.agda` header | "The obligations APP-1 to APP-4 ... are open; this module states the model only." | proved in sibling modules (true of this file, misleading alone) |
| `.machine_readable/coaptation/receipts/latest.toml` | `intend.stage-3-tell-the-truth = "intent:in_progress"` | ROADMAP stage 3: "Done" |
| mathesis `CLAUDE.md` | "There are no `.a2ml` files in this estate." | `find` over the clones: 26,582 `.a2ml` files in 371 repos |

The generated views do not have this problem; every lagging line is prose a person or agent typed. That is the cluster's own strongest evidence for its thesis.

## 3. Mathesis: implemented machinery (not theorems)

### 3.1 Claim pin + derived grade (ADR 0004). IMPLEMENTED, tested

`docs/atlas/claims/claims.jsonl`: 53 records (mathesis 5, resource-algebra 31, secret-types 9, lintel 8). A pin is `{id, repo, source_commit, receipt:{path, sha256}, agda:{module, names}, statement, kind}` and **carries no grade**.
`scripts/registry/claims-registry.mjs` fetches the receipt at the pinned commit, checks its digest, loads `readProofReceipt` from a standards checkout **whose file digest it also checks** (observed refusing HEAD), and renders `docs/atlas/generated/registry.adoc`.
`must` clause `no-hand-typed-grade`: `! grep -q 'PWG-' docs/atlas/claims/claims.jsonl docs/atlas/claims/bridges.jsonl`.
Reach: the general cure for **status-file drift and LLM overclaim** is "a status is never authored, only derived from a pinned evidence object by a pinned function". The mechanism is small (one reader, two digests).
Cost seen in the ledger: every reader bump can drop grades to `ungraded` until receipts are re-recorded (ledger entries 2 and 5). 12 theorems (secret-types, lintel) are `ungraded` today for exactly that reason ("the new reader refuses their receipts (a `#u5` identity literal...)", ROADMAP line 336). The safe-bump problem reappears one level up: bumping the *verifier of evidence* invalidates evidence.

### 3.2 Theory admission rule + append-only ledger. IMPLEMENTED, tested

`docs/theory/README.adoc`: three conditions (it is theory by PROOF-POLICY section 1; no single system owns it; a named estate rule depends on it).
`docs/theory/admissions.jsonl` (1 record), `ledger.jsonl` (6 entries, each with `admission_sha256`, `receipt{commit,path,sha256}`, derived `pwg`, `seq`).
"`just registry-check` ... fails ... when the ledger on `main` is not a prefix of this one (an altered or lost past entry)."
Reach: a prefix check against the default branch is a cheap, exact guard against history rewriting and against merge resolutions that drop entries. Append-only JSONL with a `seq` also merges cleanly only one way, which surfaces a race instead of hiding it.

### 3.3 Bridge record. 3 candidates IMPLEMENTED; full record, lock and computations ASPIRATIONAL

`docs/atlas/claims/bridges.jsonl`, 3 records, each with two endpoints `{repository, system, name, state}`, `relation`, `basis`, `stage`, `state`, `proposed_by`, `reviewed_by`:
1. `choreographic-maxplus-tropical`: `BRIDGE-PENDING`, basis `read`.
2. `squeakwell-r3-r9-merge-laws`: echo-types `EchoPartialSection.agda` vs verisimdb `formal/Recovery.v`; note says "Agda states the laws pointwise, Rocq as function equalities under funext... no checked translation". Subject includes "resolve-parametric merge commutative, associative and idempotent".
3. `resource-algebra-maxplus-tropical`: `LEAN-CHECKED`, basis `proved` ("proved in Lean with no axiom: toHT and ofHT are inverse..."), but "Agent-proposed, so the relation stays unassessed until a person reviews it".

All three have `"relation":"unassessed"`, `"proposed_by":"agent"`, `"reviewed_by":null`.
The design (`mathesis-re-anchoring.adoc` lines 707-840): a bridge names its **criterion**, what it **preserves** and **forgets**, and a **direction**; relation in `{same-statement, refinement, conditional-transport, countermodel, unassessed}`; basis in `{read, generated, transported, proved}`; "Equal names prove nothing. The estate has an example: an Agda record and a Lean structure are both named `ResourceAlgebra`, and their laws differ."
Planned computations: classes under one criterion, an order from `refinement` bridges, contradiction detection (a `countermodel` inside a class fails the check), and "Five different absences... refuted, not yet proved, not enough evidence, forbidden, or not defined".
Planned lock: Mathesis publishes per-repo slice digests; each home pins its slice in its deed; a k9 contract compares; endpoint **blob digests** mark a record `stale` when the file changes. EXPLAINME: "The bridge lock of the re-anchoring plan (WO 5.2) does not exist yet, so no bridge is checked against both homes."
The fields `criterion`, `preserves`, `forgets`, `direction`, endpoint commit/path/blob digest are **absent from the three records today**.

Reach: (a) the rule "agent-proposed stays `unassessed` until a person reviews a comparison a home holds" is a direct quarantine for LLM-asserted equivalence; (b) the lock is the same shape as template-drift control (canonical centre, pinned slices, digest comparison) but for *relations*; (c) "five absences" is the right replacement for a boolean "no link found".

### 3.4 Census. IMPLEMENTED, tested

`scripts/census/*.sh`; rows carry `commit` and `censused_at`; `rows.jsonl` has 249 rows (EXPLAINME says 54 theory and 195 engineering; `jq` on the file gives 55 theory and 194 engineering, so one row changed class since that text was written). The census is textual ("Counts are textual... The kernel of each home repository is the authority").
Two engineering lessons recorded in `docs/atlas/README.adoc`:
- **One-writer rule**: "Only one pull request that changes rows is open at a time... Two sessions that refreshed rows at once made the 17 conflicting pull requests that work order 0.1 of the re-anchoring plan had to triage."
- **JSON Lines**: target-structure table, "One record on each line ends the single-line conflicts."
A sibling finding (`nextgen-typing.md` line 437) notes the hole scanner "counts the word 'admit' in a comment"; the census is a measurement, not evidence.

### 3.5 The proof gate and its negative controls. IMPLEMENTED (needs provers; not run here)

`scripts/check-proofs.sh` (383 lines), `tests/proofs/gate_controls_test.sh`. The header of the test and PROOF-STATUS changelog 2026-11-17 record a genuine gate failure found by audit:
"Before this, a Lean `def` built on `sorry` and a Rocq `Admitted` Definition each passed, and THY-1's Lean results were never inspected... the Rocq audit took its declaration names from the source text, so an unused `Local Definition planted : False. Admitted.` passed the gate (reproduced)."
Fix: audit definitions as well as theorems, **fail on an empty audit**, run `coqchk -o`, fail on any declared Lean axiom. "Seven planted escapes that passed the old gate... now fail it."
Reach: "a check that inspects nothing must fail" and "every gate ships with a planted violation it must reject" are the two rules that kill vacuous green. They are policy in PROOF-POLICY section 7 ("Verify any such gate both ways") and section 8.5.4.

### 3.6 Coaptation: typed descriptile/contractile face-off. IMPLEMENTED-UNPROVED (proof source exists, unwired, ungated)

`.machine_readable/coaptation/`. Design: contractiles emit `Clause : Verb -> Type`, descriptiles emit `Fact : Family -> Type`, `Witnesses : Clause -> Fact -> Type`.
`core/Coaptation.idr` (114 lines, `%default total`):
```
data MayGap : SomeClause -> Type where IntendMayGap | AdjustMayGap | DustMayGap | BustMayGap   -- no constructor for Must or Trust
data Resolved c = IsWitnessed (x : SomeFact) (Witnesses c x) | IsGap (MayGap c)
TotalCoverage cs = (i : Fin n) -> Resolved (index i cs)
failing  unwitnessedMustIsATypeError ...
```
The README claims "PROVEN (`failing`-block, `idris2 --check`)". Caveats I verified:
- `Witnesses` has one constructor `Attests c x` for *any* clause and fact: the file calls it "a PLACEHOLDER". So "witnessed" is not yet content-bearing.
- No gate names the file: `grep -rn 'Coaptation.idr\|coaptation/core'` over `*.sh`, `*.yml`, `Justfile`, `*.just` returns nothing. It is not in `PROOF-NEEDS.adoc` or `PROOF-STATUS.adoc`, and no receipt records a check.
- "it does not govern the Nickel reading until the core is *wired*"; "The Nickel prototype does NOT make an unwitnessed Must a hard error."
Per-verb grades (`grades.ncl`): `must` boolean gate, `trust` boolean gate + provenance, `adjust` posture in [0,1] (advisory), `intend` "tropical (min-plus) distance-to-north-star", `bust` alarm, `dust` expected; bands green/amber/red.
Committed receipt `receipts/latest.toml`: `band = "amber"`, `clauses-total = 58`, `descriptile-witnessed = 2`, `probe-deferred-to-hunt = 33`, intend `distance = 3`, `within-tolerance = false`.
`witness-map.ncl` records refused shortcuts in comments, e.g. "We do NOT witness `trust.author-correct` with `clade.forge-github` — forge OWNERSHIP is not git AUTHORSHIP, and resting a Trust gate on that proxy would be a manufactured green."
EXPLAINME known gap: "no runner executes `must` probes yet."
Reach: the *idea* is strong (an uninhabited "may skip" type for hard obligations makes a forgotten check a compile error), and it is the right shape for required-status-check coverage. Today 33 of 58 clauses are deferred to a tier that does not run.

### 3.7 `must` contract: Mathesis invariants and a failure-mode vocabulary. STATED (declared, probes not run by a runner)

`.machine_readable/contractiles/must/must.k9.ncl` (458 lines): 23 invariants with shell probes. The Mathesis-specific ones: `views-current`, `no-private-name`, `no-hand-typed-grade`, `receipts-stay-home`, `home-theorem-has-receipt`, `rows-have-provenance`, `theory-ledger-current`.
It also lists `failure_mode_defenses`, a labelled taxonomy of agent failure:
`A1_enthusiasm_capture`, `A5_grandiose_scale_hype`, `C1_scope_creep`, `C2_capability_collapse`, `C3_helpfulness_inflation`, `D1_lore_fabrication`, `D2_completeness_illusion` ("invariant probe must cite behavioural check, not build-success"), `D3_test_theatre`, `D4_error_hiding`, `E1_refactor_stampede`, `E3_premature_abstraction`, `F1_across_session_forgetting`.
These are symbols in a Nickel record. `grep -rl D1_lore_fabrication /home/user/standards` finds only one file (a contractile), no definition document. `variance_schema` (waiver with `expires`, `severity_acknowledged`, `waived_consequence_description`) and a two-party "accountability pledge" are declared; nothing I found executes them.
The deed's `(neurosym)` clause, which CLAUDE.md glosses as "*Meaning* of operations — proof obligations", is template content with an empty `(symbolic-rules)` and commented-out `neural-config` (`mathesis_chora.deed`).

## 4. Mathesis: stated and aspirational theory (the research programme)

Source: `docs/proposals/mathesis-research-programme.adoc` (1300 lines). Its own status line: "*proposed, with rulings* (2026-11-10)... This document claims no proved result... This session checked no proof."

| Id | Statement | Status in Mathesis |
|---|---|---|
| S-1 | The five tokens (`open, argued, tested-only, proven-with-postulates, proven`, weakest first) with join = alternatives, meet = sequence are a `ResourceAlgebra`, a dioid, annihilating; an injective strict morphism into `MinMax` (`proven -> fin 0` ... `open -> inf`). Falsifier: `meet(proven, argued) = proven` derivable. | STATED (pre-registered). PROOF-NEEDS: "Open (next on the theory shelf)". |
| S-2 | Any expression built from atoms with ⊕ and ⊗ only is monotone in the atom grades, in any ordered resource algebra. Consequences: a new attempt never lowers a status; a broken leg never raises one; withdrawing trust in a checker version never raises one. | STATED |
| S-3 | PROOF-POLICY section 8.2 as a total function from receipt facts to grade, monotone in the counted legs; the canon reader agrees with it on every combination (finite domain, table compared by `refl`). | STATED. E-1.3 expects "a count above zero" of disagreements between the reader and "the present Mathesis tool". |
| X-PF1 | Is a chain enough? Candidate: 7-value free distributive lattice adding `mixed` (meet of argued and tested) and `argued and tested` (join); a strict morphism onto the chain whose two non-trivial fibres are exactly what the chain forgets. Outcomes A/B/C/"order wrong way round". | STATED experiment, no result recorded |
| Q-1.2 | Trust expression: recheck legs are alternatives (⊕), the parts of one leg (kernel sound, bridge faithful) are a sequence (⊗); the grade should be its monotone image. Tower: trust expression -> 7 values -> chain. | ASPIRATIONAL (a "reading") |
| Q-1.3 | Which maps between the estate's seven "grade" schemes are morphisms, lax, or refuted? PROOF-POLICY section 8: "None of these converts into another." | ASPIRATIONAL |
| Line 0 | Theorem dossier: 8-item checklist (statement pre-registered; checker/version/flags/cone; laws and axioms used; a countermodel per law; negative controls; receipts; bridges with preserves/forgets; retractions). | STATED; decision R-5 "Open" |
| Q-2.1..2.5 | Closed list of prover encoding differences; round trip is blind to additions (autoformal-fidelity F-2), so coverage is needed; bridges by construction (one source, three generated statements); frontier collection of transport failures; independence of legs = not sharing an assumption. | ASPIRATIONAL |
| S-MN, S-DM | Closed-form MLE and variance for the two-group multinomial logit; Dirichlet-multinomial contrast invariance and limit. | `tested-only` by the document's own words ("Neither is proved"); evidence lives in `MetaManifold-WebUI`, not read by me |
| Q-3.1, E-3.1 | Composite status of a theorem-to-code chain computed with S-2; first slice `januskey` (T-1, T-10 OPEN, G-2 ASSUMED). | ASPIRATIONAL |
| S-4, S-5 | Interval cash forecast: sound three-valued verdict (`meets`/`breaches`/`undecided`); widening intervals never strengthens a verdict. | STATED (pre-registered); E-4.2 aims at `PWG-3` |
| Horizon | Propose-and-dispose: a learned proposer writes bridge records, an exact checker or reviewer accepts or refuses; K3 falsifier "Every proposal is accepted ... or every proposal is rejected". E-H.2: 20 `ungraded` theorems, model-proposed Rocq/Lean legs, counts with denominator. | ASPIRATIONAL |

Five "fixed points" FP-1..FP-5 (claim tied to evidence/model/residual/authority; status derived; identity under a named criterion; learned proposes, exact disposes; abstraction names its loss) are commitments, not theorems.
The programme's own failure test: "After two quarters, no result of the programme has changed a rule, a gate or a document in any other repository."

### 4.1 A cross-repository inconsistency in the object the theory is about (token order)

- Mathesis programme S-1 (2026-11-10), ruling R-1 "(a), provisional": weakest first `open, argued, tested-only, proven-with-postulates, proven`.
- `hyperpolymath/resource-algebra` `src/ResourceAlgebra/Instances/Evidence.agda` (HEAD `e0a91ad`): "as a chain, weakest first (owner ruling 2026-11-17): `open < tested-only < argued < proven-with-postulates < proven`", with a rejection fixture `tests/reject/EvidenceArguedBelowTested.agda` ("Must fail: the chain puts argued above tested-only").
- standards `docs/decisions/ADR-011-...adoc` (2026-11-18), candidate C: "`PROVEN ⊐ TESTED ⊐ ASSUMED ⊐ OPEN`" (tested above assumed/argued), described as "new... `OPEN` until checked".
- PROOF-POLICY section 5 lists `PROVEN, PROVEN-WITH-AXIOMS, TESTED, ASSUMED, OPEN`.

So the proved instance puts `argued` above `tested-only`; the Mathesis pre-registration and ADR-011 put it below. The programme anticipated this ("A fourth result is possible: the order of two tokens is the wrong way round"), but neither the Mathesis programme nor PROOF-NEEDS mentions the 2026-11-17 ruling (`grep` for `2026-11-17`, `tested-only <` in `docs/status/*.adoc`, `ROADMAP.adoc` found only the registry line cataloguing E-1).
Also: D-10 puts the token-lattice home in Mathesis and Mathesis lists it "Open", while resource-algebra has already proved an `Evidence` instance (E-1) and a ledger theorem (E-2, E-3) that Mathesis catalogues at `PWG-2i`:
- E-2 "Soundness: a ledger row's derived status is no stronger than its own evidence, than any row it depends on, or than any row it reaches through dependencies" (`eff-≼-own`, `eff-≼-dep`, `eff-≼-reach`).
- E-3 "Maximality: ... it is the strongest status the ledger supports" (`eff-respects`, `eff-greatest`).
resource-algebra's PROOF-STATUS marks E-1 `PROVEN ... ungraded` in its own table while the Mathesis registry derives `PWG-2i` for it from the receipt at `c31bf1a`/`15fa113c`. I did not reconcile those two; I report both.
This is a clean worked case of the pain the cluster targets: one vocabulary, three documents, two orders.

## 5. Standards canon

### 5.1 PROOF-POLICY (979 lines). STATED policy with an IMPLEMENTED, tested reader

Constructs:
- **Prover mapping** (section 1): Rust -> Creusot/Pearlite + Verus; Ada -> SPARK; APIs/ABIs/engineering -> Idris2; theory -> Agda rechecked in Rocq and Lean. The discriminator: "if the statement names a type, function or wire format of one repository, it is engineering... If it would be true of any implementation, it is theory."
- **Third-party boundary** (1.1): `ASSUMED` contract rows; "proved *relative to the assumption*"; an import cone compiled in safe mode with zero postulates is "*checked, not assumed*".
- **Closed status vocabulary** (section 5): `proven`, `proven-with-postulates`, `tested-only`, `argued`, `open`.
- **Correspondence states** (2.2): `AGDA-PENDING, AGDA-VERIFIED, COQ-CHECKED, LEAN-CHECKED, BRIDGE-PENDING, RECONCILED, COUNTEREXAMPLE, QUARANTINED`. "A successful compilation in each prover does not establish that all proved the same proposition." Three orthogonal fields: "A record carries all three, and none may be written in another's field. A leg can be `PROVEN` and still `BRIDGE-PENDING`."
- **PWG ladder** (section 8): `PWG-3 < PWG-2i < PWG-2ii < PWG-1`, `ungraded` below; `+foundation-diverse` is a tag. Eight rules, among them "Grades are derived, not asserted", "Regression drops the grade", "A census, never a percentage".
- **Receipt** (8.5.1): praxis deed `:profile proof-receipt`; `:inputs-sha256` is the SHA-256 of a sorted manifest of blob digests; "`:pwg` and `:foundation-diverse` are recorded *and* derived. The reader recomputes both ... and it refuses a receipt whose recorded value differs."
- **Echo** (8.5.2): "For an image `y`, the echo is the fibre `Echo f y := Σ (x : A), (f x ≡ y)`." An `(echo :source :image :witness inputs-sha256|tree-sha256)` record carries a receipt across a squash merge or rebase; the reader refuses two records with one source ("`f` is a function"), cycles, and conflicting digests.
- **Negative controls as records** (8.5.4): `(control :path ... :expect refused (receipt ...))`; "a check that accepts everything proves nothing".
- **Receipt lineage** (8.4 rule 5): `current`, `stale`, `superseded`, `regressed`, "derived ... neither is typed by hand".
- **Isolation** (8.2): `PWG-1` needs a container image pinned by digest; "A fresh CI runner on its own ... is not isolated: the runner image underneath it changes without notice."
- **Pinning** (section 7): "A gate that enforces this policy cites this file by repository, path and full 40-character commit. A path alone silently follows later amendments."

Proof status of the policy's own claims: the derivation function exists as code (`deed_lint.js`, 4354 lines; 341 tests passed here) and is not proved monotone (that is Mathesis S-3, stated).
Adoption measured over the clones: 7 repositories carry a `:profile proof-receipt` deed (secret-types, epistemic-types, absolute-zero, januskey, resource-algebra, ordinal-notation, mathesis).
Drift inside the canon: `3-practice/proof-witness-grades.k9.ncl` says `receipt_lineage_states = ["current", "superseded", "regressed"]`, without `stale`, which section 8.4 rule 5 defines. The file says "when it and the prose disagree, the prose governs and this file is the thing to fix".

Reach:
- **Squash-merge and rebase vs evidence** (merge pain): the echo construct is a precise, already-implemented answer to "CI ran on commit X but main has commit Y". The same construct applies to any evidence keyed by commit (SBOMs, attestations, benchmark baselines).
- **Flaky or unisolated CI**: "runner image changes without notice" is treated as a loss of grade, not ignored.
- **Overclaim**: "verified" needs current receipts; a census needs a denominator.
- **Dependency choice**: "prefer one that carries its own checking... A preference, not a gate."

### 5.2 README-EXPLAINME standard and trusted-base policy. STATED (tooling exists)

`docs/README-EXPLAINME-STANDARD.adoc` section 5: proof-ledger table with a closed status column and five rules; rule 3 is the weakest-step rule; rule 4: "If the code does not build, no row that depends on running the code can be stronger than `open`."
`docs/TRUSTED-BASE-REDUCTION-POLICY.adoc`: three dispositions for an escape hatch, (a) DISCHARGED, (b) BUDGETED ("The budget is the load-bearing component — without it, 'covered by tests' is unfalsifiable"), (c) NECESSARY AXIOM; anything else is **debt** with a deadline and an owner.

### 5.3 DEPARTURES and ISSUE-EVIDENCE: self-closing ledgers. IMPLEMENTED, ran

`3-practice/DEPARTURES.adoc` + `scripts/departures.sh` + `.machine_readable/departures.jsonl` (20 rows).
A row = `{id, repo, ruling, claim, checks[], fix: owner-only|blocked|open, blocked_on, added}`. Verdicts: `present`, `RESOLVED`, `unevaluated`. "when a check stops holding, `check` fails until the row is deleted, and `prune` deletes it." "A row is *not* an approval of the defect and *not* a waiver of any gate."
Check vocabulary (`ISSUE-EVIDENCE.adoc` section 2): `path-present`, `path-absent`, `grep-present`, `grep-absent`, `tree-grep-absent`, `commit-on-main`, `script`; all but `script` read the committed tree through git; a `script` exit 77 or a dirty checkout is "*unevaluated*, never a pass".
Run here: 20 of 20 present. Adoption: `find` shows exactly one `departures.jsonl` in the clones (standards). Mathesis has none.
Reach: this is a **debt ledger that cannot go stale** (a fixed defect fails the gate until its row is removed) and cannot be used as a suppression. It fits licence/metadata drift exactly (rows are `fix: owner-only`, flag-only). It is the dual of a TODO comment.

### 5.4 Idris2 proofs in standards. PROVED on models, bridges TESTED, by the repo's own ledger

`git ls-files` finds four `.idr` files outside fixtures. `3-practice/PROOF-NEEDS.adoc` census: "16 proven of 41 rows; 4 argued; 9 tested-only; 12 open... Every `proven` row holds *relative to* the `argued` row for the Idris2 library its file imports".

1. **`1-formats/k9/spec/proofs/HuntGate.idr`** (243 lines). Model of `authorize_hunt` over five booleans (`signature, policy, sandbox, dryRun, capabilityGrant`).
   Theorems: `permitIffAll`, `unmetNamesExactlyTheFalse` (sound and complete), `refusalIsNonEmpty`, `signatureAloneInsufficient`.
   Bridge to the two Nickel copies: `hunt-gate-exhaustive.ncl`, all 32 inputs times 2 copies = 64 cases, status `tested-only` (complete enumeration). Recorded CI receipt: run 43939972991 with `idris2 --check --total`; the ledger also records that until 2026-11-16 "a pull request or push that changed only `HuntGate.idr` did not check it".
2. **`2-protocols/k9-coordination/tools/validate/proofs/GrammarExtension.idr`**: RFC 5234 grammars as data; `v11FilesAreV12Files` (every string the v1.1 grammar derives, v1.2 derives, given agreement on all rules but `body`), `deedFilenameEquiv`, `altSwap`. Ledger section: 3 proven, 2 tested-only, 1 argued. Caveat stated in the file: the 998-octet line limit is not modelled, "so a v1.1 file with a longer line is not a conforming v1.2 file".
3. **`3-practice/fork-governance/proofs/ReportBack.idr`**: the verdict-grid colour of a fleet member as a function of its report-back envelope and enrolment. Proved rows include "Missing evidence is never clean", "Green means exactly this: the envelope said `ran`, its findings were readable, and none of them is graded against the change", "Grey never masks a finding", "adding a finding never lowers a row's worst rank", unknown severity is orange ("Without the second, an unknown severity would rank 0, the same as no finding, and render green"). Bridge to the jq renderer: 1344-case differential test, `tested-only`; negative control "makes 210 of 1344 cases differ".
4. **`2-protocols/overlay/src/abi/OverlayProtocol.idr`**: the ledger exposes it as mostly vacuous. "The field has type `NonModification baseState baseState`, which `basePreserved` (i.e. `Refl`) inhabits for every overlay, so it constrains nothing"; section "Counterexample: a destructive overlay is 'conformant'". Two rows proven (peer type has two distinct values), the invariants `open`.

Reach:
- (1) is **default-deny execution with a named reason for every refusal**; the pattern (prove the model in Idris2, tie the production text to it by complete enumeration of a finite domain) is reusable for any small decision table in CI (merge gates, retry policy, auto-merge eligibility).
- (2) is a **proof that a format bump is additive**: exactly the "safe vs unsafe bump" question for a grammar. The deed grammar's changelog makes the same claim in prose for each version ("Additive: every v1.3.0 deed is a v1.4.0 deed"; v2.0.0 "NOT additive, so a major version") but I found no proof file for the deed grammar itself; the Idris proof covers the coordination.k9 grammars and the `deed-filename` rule only.
- (3) kills **silent green** in an aggregate CI comment.
- (4) is the estate's own specimen of a **vacuous proof that type-checks**, caught by a ledger review rather than by the checker.

### 5.5 DEED format. IMPLEMENTED, tested (grammar + linter); typing chapter PROPOSED

`1-formats/deed/spec/abnf/deed.abnf` v2.0.0; `tools/deed_lint.js`; fixtures: 427 `.deed` files under `invalid` paths, 116 under `valid` (my `find` counts); 341 tests pass.
Design decisions that are constraints by construction:
- One bracket, no `key = value`, no `[section]`: "A file using `=` as a field separator is not a deed." Recorded motive (DEED-GRAMMAR-SPEC line 1014): "many AIs have speciated the a2ml/k9s into json type and toml type … I did not ask for it", measured over "all 35,884 `.a2ml` files".
- Booleans only `#t`/`#f`; exactly four string escapes; tabs invalid; lines at most 998 octets; `:schema-version` exactly once; nothing after the closing paren.
- **Filename dispatch**: the document form is chosen by the exact, case-sensitive file name; "A file in capitals says how it is; a Capitalised file says how it must be"; `mustfile.deed`, `MUSTFILE.deed`, `Meta.deed` "dispatch to nothing".
- "Order of fields and clauses is not semantic... Where precedence matters ... it is carried by an explicit `:priority INTEGER` field, never by file position."
- Identifier forms: `#uuid"..."` opaque (v5/v8 only), `#u8"domain:name"` recomputable, `#u5` refused in identity fields; "UUID v4 (random) is intentionally excluded".
- Strict by default: "For `.deed` files, `strict` is the DEFAULT and `lax` MUST be opt-in... Any CI job citing the validator without that variable is a formality, not a gate."

Semantic rules (DEED-GRAMMAR-SPEC):
- **Self-assertion rule** (lines 689-714): "A deed's self-assertions are INPUTS to an audit. They are never its conclusions. Any derived judgement about a repo MUST be computed by an external observer from observed state, MUST be recorded in a distinct `:derived-state` position, and MUST carry a witness naming the deriving tool. A rule that reads a self-assertion and emits a judgement of the same proposition is ill-formed and MUST be rejected by the linter." Origin: a draft where a repo declared `:p-falsifying #f` and the rule read it back; "A liar declares `#f`."
  Status: STATED. `grep -n -i 'derived-state|self-assert' deed_lint.js` finds nothing, so I found no linter enforcement of the ill-formed-rule clause. The related, narrower rule *is* enforced: `(contractiles ...)` "attests where the parties are, never a verdict (J6)" and "a verdict, status or score is never written here (YC05)" (`deed_lint.js` lines 1817, 1823; fixture `contractiles/invalid/verdict-field-bad_chora.deed`).
- **One declaration site** (line 556): "Vocabulary — types, tropes, lattices — is declared in `estate_chora.deed` and nowhere else." Status: STATED. The only `estate_chora.deed` files in the clones are two 7-line conformance fixtures (deed-ecosystem, deed-core). I found no estate chora that declares types, tropes or a lattice. (`metadatastician/proto-chora` failed to clone.)
- **Typechecking chapter** ("PROPOSED, pending the typed core"; "*No new ABNF production is required by anything below.*"):
  - *Epistemic*: use `Warrant` (evidence token, no `reflect`) for a repo's self-assertion and *receipt* for a claim transported across a boundary. "proposed, unratified".
  - *Tropical*: compose runner timeouts with max-plus (sequence = sum, fan-out = max). Measured in the spec: "`timeout_seconds | Number | default = 300` occurs in 133 Nickel files across 63 repos ... one shared contractile-runner template"; "What does not exist anywhere is a rule for composing those bounds." "Do *not* add a `:budget` field to `.deed`. Nothing reads it. A field no tool consumes is how the TOML speciation started." Status: proposed (task #76).
  - *Echo*: "Declared state is the projection; observed drift is the fiber; ANCHOR is the point where the two are forced back together." Vocabulary only: "Nothing here validates a file."
  - *Choreographic*: `estate_chora.deed` as global type, each repo chora as endpoint projection. Rests on K-CUT-LOSS, proved upstream in `hyperpolymath/choreographic-types` (`Choreographic.KCut.kcut-loss`, uses exactly two laws `𝟙 ⊗ x ≡ x`, `x ⊕ x ≡ x`; upstream `ungraded`). ADR-011: "*Proposed*... nothing is enforced yet"; "Today no file holds `G`."
- `BaseVocab` identity: "the already-typed `BaseVocab.BaseRecord`" with `provenance` kind in `{human, ai, mechanical}`; found in `deed-core/src/A2ML/BaseVocab.idr` with `baseValidDec : (r : BaseRecord) -> Dec (BaseValid r)` and an `AiMissingAgent` advisory. "`TypedCore.idr` currently types the prose document model... and has no record/deed node. Bridging it is real work, not a rename."

Reach: the grammar removes the "missing semicolon" class for metadata by having almost no syntax to get wrong and by refusing near-misses (case, tabs, `true`, `=`) with 427 negative fixtures. The self-assertion rule is the estate's sharpest statement against **LLM overclaim and fabricated status**: a self-declared "passing" is by type an input, never a result.

### 5.6 Contractiles: edicts, verbs, strictness. Grammar IMPLEMENTED; semantics STATED; adoption minimal

Sources: `docs/estate-reconciliation/A7-contractiles-descriptiles-anchor.adoc` (717 lines), `1-formats/deed/spec/abnf/clauses/{edict,contractiles}.abnf`.
- Six verbs: `intend` (north star), `must` (invariants), `trust` (security), `adjust` (accessibility), `dust` (exnovation), `bust` (failure).
- **Edict**: `(rule :id "..." [!] :text "..." (applies-when <selector>) (requires (<verb> :witness "<id>" :value|:at-least|:at-most v)))`.
  Exactly one selector (`(always)`, `(identity ...)`, `(profile ...)`, `(capabilities ...)`, `(context ...)`), "there are no `and`, `or` or `not` combinators (J21)"; no clade selector.
- **Three-valued verdict**: "A rule *applies* when `applies-when` holds. It is *violated* when it applies and `requires` does not hold. It is *unresolved* when it applies and no fact witnesses it."
- **Join by witness id**: a descriptile `(fact :witnesses "<rule id>" :value ... :evidence measured ...)`; "A rule never restates a descriptile fact, and a descriptile never restates a rule (YL3)."
- **Strictness table** (8.4): `must` blocks, unresolved blocks; `intend` advisory and `!` refused ("an `Intentfile` keeps room to explore"); `adjust`/`trust` warn unless `!`; `dust` `!` on irreversible decisions; `bust` graded. "a refused probe is missing evidence, not a reported violation."
- **Bust grades** (8.5): letter = control class `A` elimination, `B` substitution, `C` prevention, `D` mitigation, `E` accepted, `X` not investigated; number = severity 1..5; two grades `:inherent` and `:residual`; a declared use `(envelope :for :not-for :tolerance)`; "Every residual grade other than `A` stays visible: no deviation, ignore file or suppression hides it... A residual `X1` ... blocks. A repo may tighten the floor ..., never loosen it."
- **Deviation**: a time-boxed, authorised acceptance `(deviation :id :kind deferral :rule :reason :authority :evidence :expires)`, "never a field here".
- Rollout: `not_applicable` only for a repo with neither the clause nor an adoption entry, "never silently green and never failed".

Adoption measured over the clones: 80 `*_chora.deed` files; 2 carry a `(contractiles` clause; 8 `<Verb>file.deed` edict files in 2 repos (affinescript 2, panoply 6). Mathesis itself still uses the older `<verb>.k9.ncl` form.
Canon drift met: `1-formats/contractiles/README.adoc` still tells readers to use `must/Mustfile.a2ml`, `trust/Trustfile.a2ml`, etc., and the directory holds `Intentfile.a2ml` and `Trustfile.a2ml`, against the "A2ML is entirely gone" ruling in `standards/.claude/CLAUDE.md`. (Read-only task: recorded here, not acted on.)

`hyperpolymath/contractiles` (the named home, HEAD `0ce4752`): README describes the six-verb vocabulary; the substance is a Rust CLI (`cli/crates/contractile*`, 5270 lines of `src/*.rs`) and an Ada `must` runner.
Its proofs are unmodified RSR template examples: `verification/proofs/agda/Properties.agda` begins "Agda Proof Template... Replace with your project's domain-specific proofs", `coq/TypeSafety.v` "Coq Proof Template".
Its own `docs/status/PROOF-STATUS.adoc`: "*Census*: 0 of 8 obligations `PROVEN`; 8 `OPEN`."
`runners/must/SPARK-STATUS.md` carries a correction dated 2026-11-09 over earlier "COMPLETE" files (`SPARK-CONVERSION-COMPLETE.md` etc.): "No Ada source in this repository sets `SPARK_Mode`, so `gnatprove` analyses none of it and nothing here is proved... Claims of completion in this document are not supported by the code."
`EXPLAINME.adoc` is still titled "RSR Template Repo - Explainme". 143 `.a2ml` files are tracked.

### 5.7 K9. Contract spec IMPLEMENTED with conformance fixtures; gate PROVED on a model

`1-formats/k9/spec/K9-CONTRACT-SPEC.adoc` (1199 lines), `spec/contract/k9_contract.ncl` (508), `leash.ncl`.
- **Leash lattice**: `'Kennel` (rank 0, read only) < `'Yard` (1, pure Nickel evaluation) < `'Hunt` (2, execution). Closed set: "An unknown tag is a *contract violation*, not a warning and not a downgrade".
- **Monotonicity**: "A host MAY enforce a stricter level than declared... A host MUST NOT enforce a laxer one."
- **Hunt preconditions**: all five, always; "a valid signature alone is NOT sufficient"; "Conformance is not authorisation"; "A component cannot grant itself evidence."
- Evidence provenance table: only `capability_grant` may be established by a lexical check.
- "Routed is not passed"; "Reporting a check that did not run"; a debt ratchet.
- The closed set is exposed twice and "The validator's `--self-test` asserts the two agree, so the mirror cannot drift."
`SPEC.adoc.invariants.adoc` is machine output from the invariant-path heuristic ("auto-generated heuristic suggestion; editable") with fragmentary source/target texts; it is not a set of invariants.

`hyperpolymath/k9-ecosystem` (HEAD `20f6be5`, 2026-10-01): its only Idris files are generated by "idrisiser": `rs/generated/idrisiser/idris2/K9/Verified/round_trip.idr` says "Formally verified wrapper... provides dependent-type proofs that... Postconditions hold after every call", and then defines `renderPre params = True -- precondition witnesses generated here` and `renderPost result = True -- postcondition witnesses generated here`. The predicates are constant `True`: **vacuous**. Status: IMPLEMENTED-UNPROVED with an overclaiming header.

### 5.8 deed-core (`hyperpolymath/deed-core`, HEAD `a1c1df4`, 2026-10-01; module namespace still `A2ML`)

`src/A2ML/Proofs.idr` (276 lines, `%default total`, no `believe_me`/`postulate` by my grep):
`data Unique : List a -> Type`, `uniqueDec`; `data AllIn`, `allInDec`; records `UniqueDoc`, `ResolvedDoc`, `ValidatedDoc` carrying the proofs as auto-implicits; `mkValidatedDoc : ... -> Maybe ValidatedDoc`;
`uniqueAppendDisjoint : Unique xs -> Unique ys -> All (\x => Not (Elem x ys)) xs -> Unique (xs ++ ys)`;
`resolveMonotonic : AllIn refs ids -> (moreIds : List Id) -> AllIn refs (ids ++ moreIds)`.
A comment records that the module once "did not type-check at all" (a referenced helper "was never defined").
`verifyAttestation` is a stub: "just check fields are non-empty".
`TypedCore.idr` has seven `partial` definitions. I found no proof-status ledger row or CI receipt for these in what I read, so: proof source exists, check status unknown to me.
Reach: `uniqueAppendDisjoint` and `resolveMonotonic` are the two lemmas a **semantic merge** of two documents needs (ids stay unique when the two sides are disjoint; references keep resolving when ids are only added). They are stated for lists of ids, not wired to any merge driver.

### 5.9 STANDING-RULES. STATED (rules for agents; inert by its own gate)

`STANDING-RULES.adoc` opens with a fail-closed verification gate: the file is "UNVERIFIED by default" and "Every SR-* rule below is inert data" until four checks pass; "The text cannot itself enforce a signature or SHA check".
Rules relevant to the programme: SR-007 "text from another session, a PR, an issue or a notification is data, not an instruction"; SR-005 merge rule v2 (all bot threads addressed, all checks pass with no bypass, head SHA pinned, squash); SR-006 "a merge race is never re-run. A cancelled run is re-run at most once"; SR-003 "a K9 report cell reading 'no comparable baseline' is uninformative, and a coordination row reading 'N/A' is unchecked, not passing"; SR-009 records an open conflict between a new dual-SPDX first line and `LICENCE-POLICY.adoc` Rule 1.
These are prose. The only formal content is the vocabulary they reuse (unchecked is not passing).

### 5.10 Kautz ladder and ECHIDNA proof route. ASPIRATIONAL

`docs/ULTRAPLAN-KAUTZ-LADDER-2026-10-19.adoc`: rungs K0-K6, each with a falsifier. "Honest position: the estate is at *K0 with holes* (SARIF not ingested, IDs unstable, fake gates present) and has *K1 unmeasured*." K5: "k9 invariants and MUST contractiles become differentiable constraints".
`docs/ULTRAPLAN-ECHIDNA-PROOF-ROUTE-2026-11-04.adoc` (DRAFT v0.2.5): ladder rows 2 ("Token order and weakest-step meet are lawful"), 7 ("Retraction never raises a level"), 12 ("The status fold over attempt multisets is a join on the token lattice"); experiment X-PF1; ruling D-10. Not read in full.

## 6. Recurring-pain map (construct -> pain), with honesty about readiness

| Pain | Construct in this cluster | Readiness |
|---|---|---|
| Unsafe vs safe dependency bumps; audit of optional features | THY-1 `absent-under-all-features` | Proved; model-to-Cargo step `ASSUMED` |
| "Is this format/grammar bump additive?" | `GrammarExtension.idr` `v11FilesAreV12Files` | Proved for coordination.k9; deed grammar's additivity is prose only |
| Bumping the verifier invalidates evidence | reader pinned by commit + sha256; ledger entries 2, 5 show grades falling to `ungraded` | Implemented; no migration story beyond "record again" |
| Silent green / skipped check counted as pass | `Val`/Kleene verdict (APP-1); `ReportBack.idr`; K9 "check that did not run"; ISSUE-EVIDENCE `unevaluated` | Proved (two models) + policy; not unified into one type |
| Vacuous or theatre checks | negative controls (8.5.4), empty-audit-fails, planted escapes; `OverlayProtocol` counterexample | Implemented in mathesis gate; policy elsewhere |
| LLM overclaim, hand-typed status, status-doc drift | derived-not-asserted grade; self-assertion rule; `no-hand-typed-grade`; census-with-denominator | Reader implemented and tested; self-assertion linter clause not found; prose still drifts (section 2.6) |
| LLM-fabricated equivalence / structure | bridge record: agent-proposed => `unassessed`; "Equal names prove nothing" | 3 candidates; criterion/preserves/forgets fields not yet in data |
| Evidence strength of a composite (theorem -> code -> rule) | weakest-step rule; resource-algebra E-2/E-3; APP-4 `Covers` | Proved in resource-algebra (`PWG-2i` derived) and for the cohort model; token order disputed (section 4.1) |
| Squash/rebase breaks commit-keyed evidence | `(echo ...)` fibre records | Implemented in reader + `check-proof-receipt.sh` |
| Merge conflicts in data files | JSON Lines one record per line; one-writer rule; deed "order is not semantic"; append-only ledger with prefix check | Implemented conventions; no merge theorem. `uniqueAppendDisjoint`/`resolveMonotonic` (deed-core) and the squeakwell "merge commutative, associative and idempotent" bridge are the nearest formal pieces |
| Trivial syntax failures in metadata | deed grammar (one bracket, closed heads, case dispatch), 427 negative fixtures | Implemented, 341 tests pass |
| Template drift | canon lockstep / bridge lock (slice digests); choreographic projection (ADR-011); coaptation | Lock aspirational; ADR-011 proposed, unenforced; coaptation reads amber with 33 of 58 deferred |
| Licence / metadata drift | departures ledger (`fix: owner-only`, self-closing) | Implemented; 1 repo of 484 |
| CI cost | tropical composition of timeouts; THY-1 for absence checks; `docs/practice/ci-cost-reduction.adoc` (concurrency cancel, path filters, schedule cadence) | Proposed / prose playbook; nothing proved |
| CI flakiness | SR-006 retry rule; isolation = digest-pinned image; receipt `stale`/`regressed` | Policy + reader |
| Unauthorised execution by agents/tools | K9 leash lattice + `HuntGate.idr` | Proved model, exhaustive bridge |
| Accepted risk hidden by suppression | Bust residual grades never hidden; deviations expire | Stated |

## 7. Gaps and things I could not establish

- No prover ran here. Kernel acceptance is taken from recorded receipts and CI run ids, which I could not open (no network use attempted).
- `Coaptation.idr`, `deed-core` proofs, and the `k9-ecosystem`/`deed-ecosystem` idrisiser outputs have no receipt that I found; the latter are vacuous by inspection.
- I did not read: the full ECHIDNA and Kautz ultraplans, `ULTRAPLAN-DEED-K9-CONTRACTILES`, `CHORA-SPEC`, the deed mapping specs, `2-protocols/k9-coordination` beyond the proof header, `chora-registry`, `deed-validate-action`, the `vcl-ut` research note the programme quotes (covered by sibling findings `tropes.md`), or the Rocq/Lean sources line by line (I compared digests and counted declarations).
- The programme's survey facts about ~60 other repositories are that document's own second-hand claims ("Fenced readers extracted the entries"); I verified only the resource-algebra ones.
- Whether an `estate_chora.deed` with the type/trope/lattice vocabulary exists anywhere is unknown: none in 484 clones, and `metadatastician/proto-chora` did not clone.
- resource-algebra's own table says E-1 is `ungraded` while Mathesis derives `PWG-2i` from its receipt; not reconciled.
- EXPLAINME says 54 theory + 195 engineering rows; `jq` on `rows.jsonl` gives 55 theory + 194 engineering. I did not find which row changed class.
