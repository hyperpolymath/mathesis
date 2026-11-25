# Ops / tooling theory cluster: formal constructs, proof status, and what they could cure

Scope: hyperpolymath/{hypatia, gitbot-fleet, cicd-squabbler, proven-cicd-and-workflows, proven,
proven-tests-and-benches, patch-bridge, polysafe-gitfixer, reposystem, sholes, action-trust-layers,
protocol-squisher, recon-silly-ation, hybrid-automation-router, work-queue, coord-tui, conflow,
ijson-jcs, rsr-template-repo, chora-registry} and metadatastician/kyq, as cloned under
`/home/user/estate/<owner>/<repo>` on 2026-11-24.

## 0. Method and limits (read first)

* Read-only. Nothing was edited, committed or pushed. This file is the only thing written.
* **No prover was run.** `which agda idris2 lean coqc rocq tlc z3` found none of them in this
  environment (only `cargo` and `bun`). So every "PROVED" below means: *a proof file exists in the
  tree, a grep for escape hatches over it is clean (or the hatch is named), and the repository's own
  status document records a checker run*. It is a file-plus-receipt reading, not a re-check by me.
* Status vocabulary used here:
  * **PROVED** = checked proof file exists (as above).
  * **MODEL-CHECKED** = TLA+/TLC on a bounded instance (the repos themselves call this `tested-only`).
  * **TESTED** = executable tests/property tests only.
  * **STATED** = spec or type signature exists, no proof (or a hole).
  * **ASPIRATIONAL** = README/roadmap only.
* All 21 repos were present; none of this cluster is in the FAIL list of `.clone.log`
  (the only FAIL matching my grep was `metadatastician/proto-chora`, not in scope).
  `gv-clade-index` does not exist as a directory: it is `hyperpolymath/chora-registry` (renamed).

## 1. One-screen summary

The cluster contains three kinds of thing, and they should not be confused:

1. **Real, small, honest decision kernels with proofs** — hypatia (57-row proof ledger, 35 proven),
   proven-cicd-and-workflows (`proven-lock` and the `Assurance.Verdict` kernel), cicd-squabbler
   (Creusot contracts + SPARK spec for "green iff non-empty and all satisfied"), kyq (93 Agda theorems on
   canonicalisation/non-malleability/translation validation), sholes (line-ending quotient, Agda +
   Lean + Rocq), hybrid-automation-router (no-loss / no-duplicate / deterministic selection),
   rsr-template-repo (Coaptation hard-gate soundness), proven-tests-and-benches (warrant-carrying test
   tiers), gitbot-fleet/echidnabot (`no-unconditional-reflection`), work-queue (TLA+ contract with a
   found starvation bug), protocol-squisher (`hub_ceiling`).
2. **Ad hoc shell/Elixir/Rust mechanisms that already enforce an invariant, with no proof** —
   the mint-replay drift gate, canon lockstep, lock-sync (three disagreeing copies), actions.lock merge,
   chora-registry integrity gate, ijson-jcs canonicaliser, action-trust-layers policy engine, the licence
   refusal gate, hypatia's 44 rule files.
3. **Scaffolding and aspiration** — recon-silly-ation, patch-bridge, polysafe-gitfixer, conflow,
   reposystem's ABI, coord-tui, and the copy-pasted template "proofs" (`verification/proofs/{agda,coq,lean4,tlaplus}`)
   that several repos still carry.

The single most reusable idea, stated independently in four repos, is the **evidence/claim split**:
a token of evidence does not imply its claim; soundness is extra structure that must be supplied.
It appears as `Warrant`/`SoundWarrant` + `no-unconditional-reflection` (gitbot-fleet/echidnabot, Agda),
`Sound`/`SoundVerdict` (hypatia, Idris2), `EdgesExact`/`RefOk` certificates (proven-lock),
`List1 Witnessed` + `rung` (proven-tests), and `HardResolved` (Coaptation). That is the type-level cure
for AI overclaim, "silent green", and proof theatre.

The single biggest systemic weakness, stated by the repos themselves on almost every row:
**the proofs are about models; no runtime is shown to refine its model.** Hypatia's ledger row
`models-runtime-refinement` is `open`; kyq's `BUDGET-CORRESPONDENCE` is `OPEN`; proven-lock's extractor
is "conformance-tested, not proven".

---

## 2. Repo by repo

### 2.1 hypatia — "Neurosymbolic CI/CD Intelligence Platform"

**Claims to fix:** estate-wide CI/CD governance scanning (~400 repos), with confidence-gated dispatch of
fixes (`>= 0.95` auto, `0.85–0.94` review, `< 0.85` report) — `README.adoc`.
The README is candid that the learning loop "is the design, not yet the running code. Today the rules
are hand-written... The promotion code in `lib/rules/learning.ex` has no caller."

**Formal content (the richest in the cluster).**
Canonical ledger: `verification/proof-ledger.jsonl` (57 lines; I counted statuses with `jq`:
35 `proven`, 13 `tested-only`, 2 `argued`, 7 `open`), rendered into `verification/PROOF-STATUS.adoc`.
Every `file` named in the ledger exists (checked by loop). Grep for
`believe_me|assert_total|postulate|sorry|Admitted|idris_crash|assert_smaller` over
`src/Hypatia/ABI/*.idr`, `verification/proofs/idris2/*.idr`, `verification/proofs/agda/*.agda`,
`verify/src/*.idr` found only comment hits. 9,740 lines of proof source in those directories.

| Construct | File | Status | Trust boundary (quoted from the ledger) |
|---|---|---|---|
| `Sound` indexed by `Mechanical`; `decSound`; `SoundVerdict`; `Sha256` refined by `So (isSha256Hex hex)` | `src/Hypatia/ABI/Verdict.idr` (318 l.) | PROVED (Idris2 0.7.0 `--total`) | "Over the Idris2 types; lib/hypatia/verdict.ex mirrors them by hand" |
| Retraction as thinning: `retractThin`, `survivesDependent`, `retractedSupportDies`, `noTokensNoSurvival` | `src/Hypatia/ABI/Retraction.idr` (161 l.) | PROVED; runtime wiring `open` (`retraction-runtime-wiring`: `Quarantine.retract_dependents/1` has no caller) | transcribed from `residual-evidence-types @ 97244f5`, correspondence `argued` |
| Receipt P1–P5 (unique event id; **no claim beyond evidence**; revision keeps history; fill never overwrites; `missing_evidence` exact) | `src/Hypatia/ABI/Receipt.idr` (513 l.) | PROVED over `Nat` ids; Elixir held to P1, P2, P5 only by `test/receipt_model_mirror_test.exs` | "No run-time code builds a revision, a fill or a withdrawal yet" |
| `Clean job decl` — egress declaration acceptance as a type | `src/Hypatia/ABI/Egress.idr` (150 l.) | PROVED; rejected shapes in `tests/reject/` | Elixir rule held by a mirror test on "a small domain" |
| RSR profile resolution: deed precedence, fail-closed on duplicate clause, `profilePresentAgrees` | `src/Hypatia/ABI/RsrProfile.idr` (408 l.) | PROVED over a model | "The Elixir is not extracted from this module" |
| `secret-alerts` wire contract: exit 0 iff Ok; "could not look" is never "clean"; `total` = `Vect` length | `src/Hypatia/ABI/SecretAlerts.idr` (209 l.) | PROVED | producer TESTED only |
| actions.lock closure: `closedIffNoDangling`, `danglingSound`, `danglingComplete`, `decClosed` | `verification/proofs/idris2/ActionsLockClosure.idr` (241 l.) | PROVED; agreement with `lib/rules/actions_lock.ex` and standards `close-lock.sh` on corpus rows only | parse boundary ASSUMED |
| Allow-list remediation is additive: `keepsCurrent`, `coversRequired`, `onlyAdds`, `flagsKept`, `idempotent`, `converges` | `verification/proofs/idris2/AllowlistRemediation.idr` (212 l.) | PROVED; `remediate.sh` agrees on 4 corpus rows | GitHub semantics ASSUMED |
| `batchAllOrNothing`: journal of undos gives commit-all or rollback-to-s0 | `verification/proofs/idris2/BatchRollback.idr` (288 l.) | PROVED | "lib/safety/batch_rollback.ex does not run steps... that `git revert` inverts a change... ASSUMED" |
| KYAML node budget: `withinBudgetSound`, `countBounded` (≤ 2·(limit+1)+2 calls) — billion-laughs refusal | `verification/proofs/idris2/KyamlBudget.idr` (307 l.) | PROVED (model of the algorithm) | not a refinement proof |
| Safety triangle strict total order; dispatch thresholds; confidence in [0,1]; Bayesian update; rate limiting; quarantine | `SafetyTriangle.idr`, `DispatchStrategy.idr`, `ConfidenceBounds.idr`, `BayesianUpdate.idr`, `RateLimiting.idr`, `Quarantine.idr` | PROVED over integer/Nat models | floats not modelled; "lib/safety/quarantine.ex is not called by any dispatch path" |
| E0 gate: each row in exactly one bucket, counting additive, import idempotent; model equals running Elixir on a generated table | `verification/proofs/agda/E0Model.agda` (687 l.), `E0Import.agda`, `E0ModelTables.agda` (1,320 l.), `E0Agreement.agda` | PROVED (Agda); theory rows: "PWG-3 1, ungraded 2" | table-based agreement, not refinement |
| Kin gate mutual exclusion (`KinGateSafe`, `GrantsAreWellBracketed`, `EveryRequestProcessed`) | `verification/proofs/tlaplus/KinGate.tla` (212 l.) | MODEL-CHECKED, "3 bots x 2 repos, MaxRequests = 4" | carries a PROOF-POLICY §4 exception record in the file |
| Negative-control corpus: `tests/reject/*.idr` (22 files) must fail to typecheck, `tests/accept/*.idr` (11) must pass | `tests/reject/`, `tests/accept/`, `scripts/check-verdicts.sh` | TESTED (each "one negative example") | — |

**Method worth copying: the receipt-derived ledger.** `scripts/proof-ledger.sh` (header read):
`derive LANES [RECEIPTS]` — "each row in LANES must say what the receipts make it"; `claims` — "every
census README, AFFIRMATION or EXPLAINME quotes is the ledger's"; `render --check` fails on a stale table.
A status cannot be typed in; it is computed, and an overclaim *or a stale underclaim* fails. PWG-1 is
refused because no per-commit receipt is recorded.

**Where it is ad hoc.** 45 entries under `lib/rules/` (44 rule files + README). Relevant ones read:
* `honest_completion.ex` (545 l.) — "the antidote to inflated self-assessments", but implemented as
  regexes over `STATE.a2ml` (`~r/completion[_-]percentage\s*=\s*(\d+)/i`) — reads a retired format, and is
  itself a `Pattern`-support verdict in HYP-01's own vocabulary (never `sound`).
* `disambiguation_rules.ex` DR001 — flags co-occurrence of "ephapax" and "affinescript" because
  "AI agents (and humans) have repeatedly conflated" the two. A proximity regex stands in for what a
  registry-resolved identifier type would settle.
* `structural_drift.ex` (1,349 l., SD001–SD020), `sha_bump_propagation.ex` (strategy `:review`).
* `cicd_rules.ex:1705–1736` — `license_finding_strategy → :review`, `license_finding_severity_cap → :warn`:
  licence findings are capped to flag-only by a constant function, not by a type that makes an
  auto-executing licence fix unrepresentable.

### 2.2 gitbot-fleet — "Bot orchestration hub"

**Claims to fix:** dispatching hypatia findings to 9 bots under the safety triangle.
**Actual state:** the mutation entry points are under an unconditional interlock
(`docs/AUTOMATION-QUARANTINE.adoc`, 2026-09-26: "No environment variable, confidence score, finding
payload, or missing directive can authorize these quarantined entry points";
`scripts/dispatch-runner.sh:148–151` prints `BLOCKED: ... dispatch is quarantined (including --dry-run)`).
Reason given: "The existing dry-run path can write outcome/heartbeat state", `deploy-bots` wrote "fake
readiness", `process-findings` recorded "synthetic success".

**Formal content.** `PROOF-NEEDS.adoc` (dated 2026-11-17) census: "15 rows: 0 `proven`, 0
`proven-with-postulates`, 4 `tested-only`, 4 `argued`, 7 `open`." Honest: "No checker ... was available
when this file was written, so no proof file in this repository was checked by the author of this file."

* `bots/echidnabot/proofs/agda/ReceiptBoundary.agda` (`--safe --without-K --cubical-compatible
  --exact-split ...`): `Warrant Claim` (evidence of an explicitly named type), `SoundWarrant w`
  (a function `Evidence w → Claim`), `receive-with-soundness`, and the counterexample theorem
  `no-unconditional-reflection : ((Claim : Set) → Warrant Claim → Claim) → Empty`.
  Lean and Rocq restatements at `bots/echidnabot/proofs/theory/{lean,rocq}/ReceiptBoundary.*`.
  Status here: `argued` (byte-identical to files whose receipts live in the standalone echidnabot repo;
  Lean/Rocq legs `BRIDGE-PENDING`).
* echidnabot ABI (`src/abi/{Types,Layout,Foreign}.idr`): `open` — `{{...}}` placeholders and three holes
  (`?fieldsAlignedProof`, `?exampleFieldsAligned`, `?offsetInBoundsProof`).
* Report-back producer (`scripts/fleet-report-back.sh`): R-ENVELOPE ("a missing binary, a crash without
  JSON, a timeout... is an `error` envelope with a reason, never a clean `ran`") and R-SLUG
  (`^[a-z][a-z0-9-]{0,63}$`) — TESTED, 229 + 69 + 139 passes recorded.
* Licence refusal: `scripts/dispatch-runner.sh:475–488` early-exit gate; `scripts/fix-license-hygiene.sh`
  header "DISABLED 2026-06-02 per owner directive".

**Ad hoc spot:** R-ENVELOPE is exactly `SecretAlerts.idr`'s "could not look is never clean" law, but in
bash with sampled tests. One shared sum type `Ran | NotRun reason | Error reason` with no coercion to
`Clean` would make it final for every producer.
**Departure met:** 42 tracked `.a2ml` files.

### 2.3 cicd-squabbler — "wins the gate; never cheats past it"

**Claims to fix:** stuck pipelines, driven "to a *legitimate* green"; zero-job `startup_failure`
attribution; cross-repo CI chains.

**Formal content.**
* `spark/src/gate_machine.ads`: `type Check_Run is (Missing, Pending, Failed, Skipped, Passed)`;
  `function Evaluate (C : Check_Array) return Gate_State with Post => (Evaluate'Result = Green) =
  (C'Length > 0 and then (for all I in C'Range => Satisfies (C (I))))`. No parameter exists for an
  admin override. **Status: STATED with a local recipe, no receipt found.** `Justfile:94` has
  `gnatprove -P squabble_gate.gpr --level=2 --report=all`, but `grep -rn gnatprove .github/workflows`
  returns nothing, while `README.adoc:11` shows a badge "invariant-SPARK--proved" and
  `.machine_readable/descriptiles/STATE.a2ml:67` says "the SPARK gate invariant is gnatprove-checked in
  CI". I found no workflow that runs it. That is the `proof-claim-without-prover` defect class that
  proven-tests-and-benches defines (§2.6).
* `verification/squabble-creusot/src/contracts.rs`: six scalar Creusot/Pearlite contracts —
  `accepted` (`passed as u64 + skipped as u64 == total as u64`, `total > 0`), `has_evidence`
  (`passed == total`: "a gate satisfied only by skips is evidence-free"), `after_diagnosis` (the
  diagnosis is a free variable the postcondition does not mention: **no diagnosis is a green**),
  `admits`, `requires_admission` (exact complement — "never a `true` invented for an unknown"),
  `after_admission`. **Status: PROVED at one revision** — `docs/CREUSOT.adoc`: hosted run
  41909189438, Creusot 0.14.0, merge checkout `f9499a8…`; planted false control refused, true control
  proved; "`Proved (13 files)` ... counts files, not independent theorems"; "trusted axioms: 0" counts
  only literal `#[trusted]` lines. Verus: not found in this repo.
* `.machine_readable/coaptation/core/Coaptation.idr` (112 l.): **stale copy** of the template core
  (template's is 324 l. with `hardGateSound`); here `Witnesses` has a single placeholder constructor
  `Attests` that lets any fact witness any clause.
* `docs/status/PROOF-STATUS.adoc`: "Template obligations: 0 of 7 recorded complete"; the files under
  `verification/proofs/{agda,coq,lean4,tlaplus}` are template boilerplate.

**Departures met:** 123 `.a2ml` files, including `ANCHOR.a2ml`/`STATE.a2ml` that carry the SPARK claim.

### 2.4 proven-cicd-and-workflows (the renamed cicd-suite) — "atlas of composable repository assurance"

**Claims to fix:** 32 composite actions in 8 clades; a single proven verdict for lock/pin and for
"did the required checks really pass".

**Formal content.**
* `src/Assurance/Verdict.idr` (211 l., `%default total`): `Observation = (Obligation, Applicability,
  Execution, Revision, Admission)`, `decide : List Observation -> Verdict`, with theorems
  `emptyCannotPass`, `exemptionsAloneCannotPass`, `advisoryCannotDischarge`,
  `skippedRequiredCannotPass`, `neverStartedCannotPass`, `staleCannotPass`, `revokedCannotPass`,
  `unverifiedCannotPass`, `undeterminedCannotPass`, and nine advisory-sharing lemmas.
  "ExemptValidated is a claim from a trusted policy evaluator, not a string that an external JSON
  document may create by naming the constructor." **Status: PROVED kernel, adapter unpromoted** —
  README: "Its operational GitHub adapter remains unpromoted: review reproduced an invalid
  duplicate-field response becoming a false passed verdict."
* `src/Proven/Lock/{Model,Judge,Controls,Axioms}.idr`: `Reach g n k`, `Closed`, `complete`,
  `EdgesExact` (a record the judge must construct to call an entry exact), `RefOk`, 17-constructor
  `Reason`, `judge : (f : Facts) -> Outcome f` total — "returns `Consistent` only with an `EdgesExact`
  certificate for every managed workflow and a `RefOk` certificate for every record... Fuel bounds only
  how long a search runs: running out gives NOT RUN, never a pass." `relockIgnoresEntries`.
  **Status: PROVED-with-two-named-axioms** — `Axioms.idr` holds exactly two `believe_me`
  (`stringEqSound`, `stringEqRefl`), "the whole trusted base is this file". `Main.idr`'s decoder and IO
  are `covering` (trusted, not proved). A C build of the judge is committed at `dist/proven-lock/`.
* `actions/` holds 33 entries (README: "32 composite actions") including `creusot-check`, `verus-check`, `spark-check`,
  `affirmation-check`, `proof-runner-check`, `idris2-abi-check` (not read individually).

**The evidence for "ad hoc → make it final"** is in this repo's own catalogue,
`docs/proven/LOCK-PIN-CATALOGUE-2026-11-13.adoc`: "The same defect is decided by several
implementations, and they disagree. *Lock sync: three copies*... G's copy was green while five reusable
callers ended with zero jobs. *Self-SHA leaf: seven implementations with different exemptions.*"
`docs/proven/LEDGER-2026-11-13.adoc` ties this to dependency bumps: "CASE-032 ... Lock Sync Gate red
after a Dependabot action bump ... Proven content: the lock kernel names it (MissingTransitiveEdge for
the bumped key, StaleRef for the old one)".

### 2.5 proven — "Formally Verified Safety via Idris2"

**Claims to fix:** "Code that **cannot crash**" (README), 104 modules, 120+ binding targets.

**Formal content (my counts):** 237 entries under `src/Proven/`; 93 `src/Proven/*/Proofs.idr` files;
0 `postulate`, 0 non-comment `believe_me`; 2 `assert_smaller` (`SafeUnionFind.idr:213`,
`SafeInput.idr:282`); 376 lines mentioning `OWED`.
`PROOF-NEEDS.adoc` (honesty refresh 2026-05-18) says of its own earlier edition: "that framing was
*dishonest by a wide margin*... dozens of modules ship verbatim security claims in their doc headers
(`Prevents:`, `formally verified`, `guaranteed`, `cannot crash`) with *zero discharged theorem*", and
introduces the bucket "Witness-only (OVERCLAIM, marked ✗)" and the `||| OWED:` + erased-`0`
convention (250 bodyless declarations surfaced).
**Status discrepancy found:** PROOF-NEEDS still says "Safe* directories with a companion Proofs.idr | 41";
the tree has 93. `README.adoc` still carries badges "believe_me = 0 (fully eliminated)" and
"Overall 55%" (a percentage) and the headline "cannot crash".

Modules that bear on this programme's pain list (signatures read, bodies not audited):
* `SafeSemVer/Proofs.idr` (156 l., 2 OWED): `bumpMajorResetsMinor`, `bumpMinorResetsPatch`,
  `bump*ClearsPre`, `zeroMajorNotStable`. Laws of the bump *operations*; no theorem that a range
  admits only compatible versions.
* `SafeYAML/Proofs.idr` (412 l., 6 OWED): dangerous-tag rejection by `Refl`, `secureDefaultsNoAnchors`,
  depth/key/value limits. `SafeTOML/Proofs.idr` (442 l., 6 OWED), `SafeJson/Proofs.idr` (446 l., 3 OWED).
* `SafePromptInjection/Proofs.idr` (164 l., 0 OWED): per-string `Refl` facts
  (`escClosingSystemTag`, `ignorePrevDetected`…) — closed examples, not a universal theorem.
* `SafeSupplyChain.idr`, `SafeProvenance.idr`, `SafeSchema.idr`: headers say soundness /
  causality / compatibility theorems are OWED.
* `verification/header/{agda,coq,lean4,cubical}/ProvenHeader.*` imports `Sholes.Core`/`Sholes.Wire`:
  `classifies : (b : Octet) → isBreak b ≡ hasBreak (decode b ∷ [])` by exhaustive 256-case reflection
  and `scan-correct` over unbounded lists.

**Departure met:** 28 `.a2ml` files; many banned-language binding directories are consumer bindings
(carve-out) and were not assessed.

### 2.6 proven-tests-and-benches — "a test's warrant is a first-class, machine-checked value"

**Claims to fix:** tests labelled "proven" that are only examples; faked coverage.

**Formal content.** `src/ProvenTests/Types.idr`: `ProvenStatus` (ActuallyProven / ProvisionallyProven /
Unproven), `record Witnessed`, `rung : String -> Maybe String -> Maybe Nat -> Name -> (stmt : Type) ->
Elab Witnessed`, `record ActualEvidence`, `data Provenance`, `FixturePair` (silence + firing fixture).
`PROOFS.adoc`: "29 spec-suite properties are now Actually-Proven"; "Until 2026-10-06 the ladder was
`List1 ProofStep`: **metadata** only... A ladder naming a theorem that did not exist yielded a test
labelled `[Actually-Proven]` on the strength of a string." Now the typechecker rejects a rung citing a
missing theorem, or a real theorem for a property it does not prove; three `failing` blocks record this.
Stated residual: "`Witness s () ()` compiles" — a true-but-irrelevant statement is still accepted.
**Status: PROVED for the 29 laws and the rejection behaviour (as recorded); TESTED for the 115
provisional tests.**

`corpus/provenance/reflexive/` names four defect classes with paired fixtures:
`proof-claim-without-prover`, `skipped-mandatory-reported-as-pass`, `cancelled-gate-void`,
`setup-failure-reported-as-subject-failure`. The first: "A README banner that says 'formally verified
with SPARK'... with no prover event behind it is proof theatre."
The README records its own drift: the CRG badge "was hand-frozen at D for five weeks while
READINESS.adoc and STATE.a2ml both said C, because nothing tied them together."
**Departure met:** 34 `.a2ml` files; 4 `.py` files tracked (not inspected).

### 2.7 patch-bridge — "Draft CVE-mitigation design"

README: "design/research draft, not a finished standalone tool... no end-to-end Idris2 proof artefacts".
`src/interface/abi/ClassificationSoundness.idr` (68 l.): `SevLTE` ordering and `severityMonotone`,
which ends in a hole — line 68: `False => ?hole_trans`. **Status: STATED (hole).**
`PROOF-NEEDS.adoc` says "`src/abi/`... EMPTY" while files now exist at `src/interface/abi/` — stale.
Types of interest: `ReachabilityStatus = Phantom | Unreachable | Reachable`,
`Classification = Mitigable | Unmitigable | Informational_Result`. Rust: 1,306 lines in `src/bridge/`.
Pain it targets: unsafe-vs-safe dependency bumps by reachability. No theorem connects reachability to
the adoption gate. **Departure met:** 117 `.a2ml` files.

### 2.8 polysafe-gitfixer — "each component in the language with the strongest guarantees"

README draws Haskell TUI + Elixir/OTP + Idris workflow + Rust. **The tree contains only Rust**
(`git ls-files` shows no `.hs`, `.ex`, `.idr`): 1,070 lines across 5 crates. No proofs
(`PROOF-NEEDS.adoc`: "ABI layer: Missing").
Two code-level findings (read from source):
* `crates/capability/src/dir_capability.rs:134–137` — `attenuate(&self, sub_dir, permissions)` ends
  `Ok(Self { root: new_root, permissions })`. The doc comment says "Permissions can only be equal to or
  more restrictive than the parent", but nothing compares `permissions` with `self.permissions`. A
  read-only capability can attenuate to read-write-delete. The module header calls the mechanism
  "mathematically immune to traversal attacks"; no proof exists.
* `crates/fs_ops/src/transaction.rs:91–120` — `commit` is documented "Commit all pending operations
  atomically" but applies ops in a `for` loop; a failure at op k leaves ops 1..k-1 applied (the `Drop`
  rollback only removes staged temp files). Hypatia's `batchAllOrNothing` is the missing discipline.
**Status: IMPLEMENTED-UNPROVED, with a contradicted doc claim.** **Departure met:** 22 `.a2ml`.

### 2.9 reposystem — "Railway yard for your repository ecosystem"

Coordination layer: `repos.toml` generated from `.gitmodules`; "thread" runner for one logical change
across N repos (`ESTATE-ORGANIZATION.adoc`: `thread start|pr|status|land`, "`land` refuses without
`--yes` and only merges PRs GitHub reports `MERGEABLE`"). Concepts: slots, providers, switches;
`spec/DATA-MODEL.adoc` invariants: Stable IDs, Explainability ("any non-manual tag must carry
evidence"), Scenario Isolation, Reversibility ("every scenario change can be expressed as a small
delta").
**Formal content:** only `src/abi/Types.idr` (62 l.): enums and `toInt` maps. Its header says it "Proves
that... 3. Batch operations preserve ordering" — **no such theorem is in the file** (header overclaim);
`HealthScore = MkHealth (n : Fin 101)` is the only by-construction property. **Status: STATED /
ASPIRATIONAL.** `PROOF-NEEDS.adoc` names "~20+ `Obj.magic` calls" in ReScript. **Departure met:** 65
`.a2ml`; ReScript and 38 `.ex` present (grandfathered inventory, not assessed).

### 2.10 sholes — what it was meant to cure, and whether it did

**Meant to cure:** CRLF vs LF. README: "Sick of CRLF breaking your git diffs, shebangs, and CI caches?
A formally verified quotient layer that ends the 50-year typewriter war forever" — phantom whole-file
diffs, wiped blame, `bash\r` shebang failures, poisoned content-addressed caches. Design: content
addressing as the quotient Σ*/∼LE with a canonical projection, plus a "zero-allocation, Creusot-verified
streaming Rust engine" and Git driver.

**What exists (first commit 2026-10-18; proofs landed 2026-11-16, PR #15):**
`verification/proofs/agda/Sholes/{Core,Equivalence,Lens,HeaderBridge,Streaming,Wire}.agda` (461 l., all
`--safe --without-K --cubical-compatible`), `lean4/Sholes/Core.lean` (331 l.),
`coq/Sholes_{Core,Wire}.v` (229 l.), `cubical/SholesCubical.agda`. Grep for
`postulate|sorry|Admitted|Axiom|trustMe|TERMINATING` in those files: none.
Theorems read in source: `_≈_` (token equality) is an equivalence; `canon-preserves-tokens`;
`idempotent : canon (canon xs) ≡ canon xs`; `invariant`; `reflects`; `hash-coherent` (congruence for any
`H`, explicitly "not hash injectivity"); `factors`; lens laws `put-get`, `get-put-quotient`,
`get-put-normal-view`; and the impossibility result `no-raw-inverse` (canonical bytes alone cannot
restore the original spelling). `Streaming.agda`: chunked output equals the list spec across any split.
Recorded checking (`verification/proofs/SHOLES.adoc`): Agda 2.6.4.3, Lean 4.15.0, Rocq 9.2 + `coqchk`;
"hand re-proofs, not exported Agda proof objects"; "No PWG grade is asserted"; the Lean4Lean leg "is
*not passed*".

**Did it cure it? No — it proved the theory and delivered no cure.**
* The README's own banner: "The runtime, classifier, Git driver, performance numbers and Creusot
  verification described below are target design, not delivered or verified implementation in this
  tree." The four `.rs` files in the repo are template utilities (`scripts/*.rs`), not a filter.
* The body of the README still says "Agda proofs + verified Rust filter" and "exported proof objects",
  which the banner contradicts.
* `docs/status/PROOF-STATUS.adoc` is the untouched template: "*Overall*: 0% proven", "No proofs
  completed yet" — an **underclaim** against `SHOLES.adoc`, and a percentage.
* Meanwhile the estate actually prevents CRLF with the mechanism sholes set out to replace:
  `rsr-template-repo/.gitattributes` is `* text=auto eol=lf` plus per-extension `eol=lf` lines.
* It did pay off once, in an unplanned direction: the header bridge exposed a real mismatch.
  `SHOLES.adoc`: "the actual Idris `Proven.SafeHeader.Types.hasCRLF`, compiled using RefC, returns true
  on lone CR, lone LF, CRLF and embedded CR. The actual Zig export... returns false on the
  lone/embedded cases" — and "every canonical LF-only stream defeats a CRLF-pair-only check."
* `scripts/check-line-endings.sh` is referenced from the `Justfile` only; no workflow under
  `.github/workflows` mentions it (grep), so the proofs are not CI-gated here.

### 2.11 action-trust-layers — "DANE/TLSA-inspired trust model for Actions pinning"

**Claims to fix:** the brittleness of "pin every action to a full SHA, recursively" when a pinned
composite references a nested moving tag. Three layers: Anchor (trusted owner, transitive),
Provenance (attestation identity), Leaf-exact (full SHA). "degrades exactly to today's all-SHA policy
when Layers 1–2 are empty".
**Formal content:** none. 1,049 lines of Rust (`src/{model,parse,resolve,policy,report}.rs`), 2 tests in
`tests/closure.rs` (`layered_admits_transitive_nested_moving_tag`,
`flat_all_sha_policy_would_deny_the_same_nested_tag`). The README calls the test "the proven thesis";
it is a test. **Status: IMPLEMENTED-UNPROVED.** The "degrades exactly" and monotonicity-in-anchors
properties are exactly the shape of hypatia's `AllowlistRemediation` (`onlyAdds`, `keepsCurrent`) and
are unproved here. **Departure met:** 12 `.a2ml`.

### 2.12 protocol-squisher — a terminated project and a methodology case study

**Claimed:** universal high-fidelity interoperability between serialization formats.
**Outcome:** "Terminated as an active project (2026-07-06)"; the claim was *refuted* by its own algebra.
Transport classes `Concorde < Business < Economy < Wheelbarrow` compose by `max`
(`provenance/proofs/tropical/TropicalAdapterPath.lean`, 410 l.: `tcJoin_*`, `pathCost_mono`,
`minimax_path_optimal`, `hub_ceiling`), so "any route through a shared hub is capped by that hub's worst
embedding."
**Proof status (`provenance/PROOF-NEEDS.adoc`, 2026-11-18):** "10 of 10 Agda modules ... type-check
under `--safe --without-K --cubical-compatible`"; "The earlier 'ALL PROOFS COMPLETE' and '8/8 theorems
verified' claims are withdrawn: on 2026-11-17, 9 of the 10 Agda modules did not type-check." Five
statements were *false as written* and were restated (`wheelbarrow-needs-fallback`,
`compilation-implies-transport`, `class-correct`, `concorde-safe` — which "claimed every function
`Set → Set` is lossless" — and `transitive-transport`). Remaining weakness: the synthesized adapter "is
the same unit identity adapter for every field list". "No CI job or recipe checks these files." Idris2,
Lean, Coq, Isabelle, Z3 artefacts "carry no current receipt"; PROVENANCE.adoc records that under Lean
4.13.0 only `pathCost_mono` and `hub_ceiling` are machine-checked.

**`provenance/PROVENANCE.adoc` §"What went wrong" is the estate's own taxonomy of AI-assisted failure**
(quoted headings): "The validation harness was built twice and never fired"; "Hypotheses were tested
against self-authored examples"; "A contradiction was preserved across documents, with confidence
drifting and no new data to justify it" (H1 confidence 0.035 → 0.92 with no measurement); "Toy-model
proofs were presented as system verification"; "A single file asserted both a number and its negation"
(0 vs 758 `unwrap()`); "Completion was self-reported on dashboards"; "Velocity inverted"; "The prompt
pattern set the wrong success condition... A model optimising for rescue re-narrates."
**Departure met:** 25 `.a2ml`, 9 `.py` under `provenance/` (archive; not assessed).

### 2.13 recon-silly-ation — "cross-document consistency reconciler"

**Claims to fix:** unpropagated renames, changelog claims that don't match the change, credit that
expands into authorship, references to things that no longer exist, "explanations that cannot all be
true". Proposed `ForthWall` bounded rule VM.
**State (README, honest):** "does *not* contain a proven reconciliation engine or an operational
ForthWall VM. The machine-readable state records both the VM and actual `reconcile` action as 0%
complete." Present: Zig FFI seam (`src/interface/ffi/src/reconcile.zig`, 460 l.) and template proof
files. `docs/status/PROOF-NEEDS.adoc`: every ABI/TP row "Needed". **Status: ASPIRATIONAL.**
The README's delivery criteria are themselves a good spec: "idempotence, non-interference,
scope-confinement, and stale-input tests; attribution tests proving local credit cannot become global
authorship". **Departure met:** 118 `.a2ml`.

### 2.14 hybrid-automation-router (HAR)

**Claims to fix:** routing automation events to targets; Phase 2 "automation interlingua".
**Formal content** (`src/abi/*.idr`, 1,060 l.; grep for holes/escape hatches: none):
* `RoutingInvariants.idr`: `noEventLoss` (at quiescence every accepted event is Delivered or
  DeadLettered), `noDuplicateDispatch` (`LTE n 1` under a `LinearIn` premise — "Ephapax linear-token
  discipline — REUSED, not re-proved"), `deterministicSelection` + `selectionSound` (selection as a
  list fold, so "determinism holds by construction (no HashMap order to leak)").
* `MetaModel.idr`: `Step : RealisationStatus -> RealisationStatus -> Type`, `handedOffTerminal`,
  `noStepToDeclared`, `alwaysHandoffable`; "this file wins and the Rust changes" but the Rust mirror is
  "kept in sync with it by hand".
* `ProvenFSM.idr`, `ProvenQueue.idr`: tag round-trips and `Valid*Transition` relations.
`PROOF-NEEDS.adoc`: RI-1..3 "CLOSED, Machine-checked (2026-07-06)"; Rust echoes RR-1..3 are proptests.
**Status: PROVED per the repo (no receipt file found; not re-run), conditional on two named premises.**
**Departure met:** 82 `.a2ml`.

### 2.15 work-queue

`README.adoc` is still the unrendered template (`= {{PROJECT_NAME}}`). Three commits (2026-11-18).
**Formal content:** `verification/proofs/tlaplus/workqueue/WorkQueue.tla` (182 l.) models the job
contract (`docs/design/work-queue/CONTRACT.adoc`): states, leases, reservations, heavy slots,
obligations, priorities, shares, probes, preemption. `README.adoc` there records TLC 1.8.0 results:
`Safety.cfg` 70,688 distinct states pass (TypeOK, one lease per job and worker, heavy slots, "waiting is
said", reservation, probe cap, Ownership); `SharesSafety.cfg` 217,440 pass; `LiveAsDrafted.cfg` "*fails,
as expected*" — a repeatedly rejected urgent job starves everything below it, which justified adding a
reject limit; "`scripts/wq-oracle.sh` fails if this counterexample ever disappears." A mutant survived
the first model ("that is how the gap was found"). The Zig core `src/core/queue.zig` is conformance-
checked against the TLC state graph via `oracle.awk`. "Results hold for this finite model only."
**Status: MODEL-CHECKED + conformance-TESTED.** `docs/status/PROOF-STATUS.adoc` has no row for it.

### 2.16 coord-tui

Rust TUI (one `src/main.rs`) over BoJ `local-coord-mcp`: peers, task claims, peer id in the terminal
title. No formal content. The claim/peer model is the same shape as hypatia's `KinGate.tla` (one holder
per resource) but nothing links them. **Status: IMPLEMENTED-UNPROVED.** **Departure met:** 10 `.a2ml`.

### 2.17 conflow — "Configuration Flow Orchestrator" (CUE/Nickel pipelines)

No proofs. `generated/tlaiser/{StageExecution,CacheEntry}.tla` are generated state-machine skeletons
(`TypeInvariant`, transitions); no workflow or Justfile mentions `tlaiser`/`tlc` (grep) — unchecked.
`PROOF-NEEDS.adoc` contradicts itself: "Current state: `src/abi/Types.idr` (232 lines)..." and, lower,
"Template ABI removed"; no `.idr` is tracked. Wanted properties listed: DAG acyclicity, merge
determinism, rollback safety, schema-validation completeness. **Status: ASPIRATIONAL** (DAG code exists
in `src/pipeline/dag.rs`, untested by me). **Departure met:** 22 `.a2ml`.

### 2.18 ijson-jcs — I-JSON (RFC 7493) + JCS (RFC 8785)

**Claims to fix:** nondeterministic JSON bytes (hashing, signing, diff noise).
**Formal content:** none claimed — `docs/ASSURANCE.adoc`: "Native tests do not prove the implementation;
no whole-library Creusot or Verus theorem is claimed." Evidence: RFC 8785 vectors, proptest
`strict_profile_canonicalization_is_idempotent` (`tests/properties.rs:46`), CLI idempotence tests, an
interop contract with kyq (`interop/kyq/vectors/`). **Status: TESTED.**
**A mechanism worth typing:** `.ci/standards-contract.tsv` (29 lines) "records the normative sentences
this implementation is tested against, so a revision that keeps the filenames but rewords a rule is
`INCOMPATIBLE POLICY CHANGE`, not a hash diff to wave through". The README records the failure it
guards: an earlier README cited `3-practice/DATA-FORMAT-ROUTING.adoc`, "that path exists at neither the
pinned revision nor `main`" — a fabricated/stale reference. (The estate CLAUDE.md files in this session
still cite that path as canon; I did not check `/home/user/standards` for it.)
**Departure met:** `README.md` instead of `README.adoc` (not one of the two allowed exceptions).

### 2.19 metadatastician/kyq — KYAML / I-JSON / Dhall / TOML gate

**Claims to fix:** format drift and unsafe YAML; one gate for four formats. "This is the Rust migration
candidate" — the estate CLAUDE.md agrees it is not yet a working gate.

**Formal content, theory** (`docs/status/PROOF-STATUS.adoc`, 2026-11-19): "Agda (source of truth) | 93 |
93", Agda 2.7.0.1 from Guix in CI, `--safe --without-K --cubical-compatible --no-libraries`, 0
development postulates, 9 modules (2,612 l.); Rocq recheck 15 of 93 (`KyqSpine.v`, 522 l.), each
`BRIDGE-PENDING`; Lean 0 of 93; "*ungraded 93 of 93*" (no machine-readable receipt). 9 Agda + 2 Rocq
negative controls refused, 4 runner controls (e.g. `PlantedPostulate.agda`, `PlantedTerminating.agda`).
"This file proves nothing about kyq's code, the JS conformance oracle or ijson-jcs."
Key results (names from the Claims table):
* `KyqOrder`: UTF-16 code-unit member order is a total order (`leq-total/antisym/trans`).
* `KyqValue`: `canon-nf`, `nf-fixed`, `canon-idem`, `canon-not-id` — canon is a proper retraction onto
  normal forms.
* `KyqUnique`/`KyqRecursive`: `sorted-unique`; `canon-resp` (well-formed values equal up to member
  order at every depth canonicalise equally); `nf-unique`; `ker-sound`/`ker-canon` (the kernel of canon
  is exactly "same up to member order"); and necessity results `no-unique-without-distinct`,
  `canon-resp-needs-wf`.
* `KyqCodec`: two-argument translation validation `tv-iff : tv(in,out) ⇔ in ∈ Dom ∧ out = c(p in)`;
  `ref-nonmalleable`/`gate-closure` (a canonical gate accepts exactly one byte form);
  `roundtrip-compose`/`faithful-compose` (Faithful≈ composes under four side conditions; "grade
  composition open").
* `KyqModel` (counter-models): `one-arg-not-tv` (a one-argument check does not give TV);
  `loose-not-nonmalleable` (validity ⇏ non-malleability); `drop-not-faithful` /
  `coarse-not-separating` — "a constant `norm` meets every codec law and makes a document-dropping
  converter Faithful≈; NormSeparates rules it out".
* `KyqMeasure`: depth/node/byte budgets are invariant under canon. `KyqProfile`: the large-float hole
  breaks RoundTrip; ruling R3 restores it and is the largest closed domain.

**Formal content, engineering** (`verification/PROOF-STATUS.adoc`, 2026-11-16): `BUDGET-IMPL`
(`bounds/src/lib.rs::consume`, Creusot 0.14.0/Pearlite) PROVEN; `BUDGET-MODEL` (Verus, `--no-cheating`)
PROVEN; `BUDGET-CORRESPONDENCE` OPEN; `KYAML-GRAMMAR`, `KYAML-MAPS`, `KYAML-ALIASES`,
`FORMAT-CLOSURE`, `JSON-POINTER`, `CLI-IO`, `REPO-TOOLS` all OPEN. "The 118 bridge vectors, 49 fixture
contracts... are TESTED evidence. They do not change these OPEN proof rows to PROVEN."
ASSUMED: `yaml-rust2` 0.11.1, `serde_dhall` 0.13, `serde_json`, and `ijson-jcs @ 1735d68`.

### 2.20 rsr-template-repo — the template every repo is minted from

**Claims to fix:** template drift; onboarding of agents; uniform gates.

**Formal content.**
* `.machine_readable/coaptation/core/Coaptation.idr` (324 l.): `Verb = Intend | Must | Trust | Adjust |
  Dust | Bust`; `MayGap : Verb -> Type` with no constructor for `Must`/`Trust` (`mustCannotGap =
  absurd`, `trustCannotGap`); `Holds`, `Witness` (non-empty spec list), `HardResolved` (`ByWitness |
  ByDeferral`, "no gap constructor"), `hardGateSound`, `hardGateComplete`. **PROVED** per
  `verification/proofs/idris2/MANIFEST` (gated; idris2 0.8.0 on 2026-11-17). Not proved: "that the
  Idris2 model is a faithful transcription of the Nickel comparator `coapt.ncl`" (`ASSUMED`); and
  `ByDeferral` currently lets a hard clause with a runnable probe and no witness pass the Yard gate.
* `verification/proofs/idris2/MANIFEST`: per-module `gated | quarantine` — "quarantine = known-broken,
  must keep failing" — an **unexpected-pass detector** (a module was "promoted 2026-11-09 when
  check-proofs.sh reported an unexpected pass").
* ABI seam: `src/interface/Abi/Types.idr` — `fromCodeResultCode` round trip, `resultCodeInjective`.
* `docs/status/PROOF-STATUS.adoc` (template): "A freshly minted repository has no claims, so the table
  is empty. That is the honest state." and "The template's own sample proofs under
  `verification/proofs/` are boilerplate. They are never rows here".

**Mechanisms without proofs (headers read):**
* `scripts/check-mint-drift.sh` (364 l.) states an equation:
  `child ≡ repo-init(template @ :template-commit, (mint-answers))` modulo the paths the child declares
  in `(variant (paths …))`. It *replays* the real mint (`scripts/replay-mint.sh`) rather than diffing —
  "Diffing it against the template reported 101 rendered files on a fresh mint... no set of (normalise)
  rules could fold that without re-implementing the mint." Status: "tested end to end on fixtures...
  not proven".
* `scripts/check-template-conformance.sh` (274 l.): "It built the answer-file... and then built neither
  the update nor the check. Nothing in this repository read that record. It was write-only."
* `scripts/check-variant-drift.sh`: every tracked file not declared
  added/removed/diverged/pending/operational must equal the parent's at `parent-pin` modulo
  `(normalise)` rules.
* `scripts/canon-pin-check.sh` (213 l.): two-phase lockstep — the spine may pin a canon ahead of release
  by naming the open canon PR (`:proposed-by`); fails if that PR closes unmerged or is amended.
* `scripts/merge-actions-lock.rs` (228 l.): union per section; "A key present in both files must have a
  byte-identical entry, or the merge is refused"; "any line this shape does not explain, is refused
  rather than dropped". Origin: an overlay `cp -a` replaced the spine's lock and "each Julia mint
  started with Lock Sync red".
* `scripts/edict-run.rs` (320 l., "a TRIAL"): an edict has `applies-when` (a test on identity, the
  chora deed) and `requires` (a test on reality, a descriptile); four verdicts NOT-APPLICABLE / HOLDS /
  VIOLATED / UNRESOLVED; "Identity selects the edicts; a repo does not list them."
* `scripts/survey-template-damage.sh`: "Every repository minted from the template while it shipped a
  nine-runtime `mise.toml`... carries the same damage, permanently — the mint copies the files once and
  nothing goes back to fix them."

### 2.21 chora-registry (formerly gv-clade-index)

**Claims to fix:** one registry of repo identities and classification; "the map", never the territory.
**Formal content:** none (`PROOF-NEEDS.adoc`: template ABI removed). The comment in
`scripts/check-registry.sh` says the gate "Proves that the committed registry is one coherent artefact"
— it is a bash/jq gate. What it enforces (header, 7 checks): seed parses to exactly `:total-repos` rows
with unique names; generated `worker/data/*.json` is **byte-identical to a fresh export** (not stale);
counts agree; every `uuid` is the ADR-008 profile-C UUIDv8 of the repo's **recorded birth path** in the
domain that minted it (ADR 0008 "identity is minted once"; ADR 0007 "remint identity on move" is in the
tree as the superseded decision); archive generations count 1..n with no gap and no retired id is ever
reused; **nothing registered is lost** (every repo on the base branch is still listed with the same id).
**Status: IMPLEMENTED-UNPROVED (gated in bash).** **Departure met:** 3 `.a2ml` files
(`verisim/config.a2ml`, `verisim/seed/clades.a2ml`, `verisim/seed/forges.a2ml`), and the README still
opens "The *clade-index* is the central registry".

---

## 3. Constructs mapped to recurring pain

| Pain | Best existing construct (status) | What is missing to make it final |
|---|---|---|
| **AI overclaim / "verified" with nothing behind it** | `Warrant`/`SoundWarrant`, `no-unconditional-reflection` (Agda, argued here / proven upstream); `Sound`/`decSound` (hypatia, proved); `List1 Witnessed` + `rung` (proven-tests, proved); receipt P2 "no claim beyond evidence" (hypatia, proved); ledger `derive` (script) | One shared `Claim`/`Evidence`/`Receipt` schema that every status document is *rendered from*. Today five repos have five encodings, and 2 of the 21 status docs I compared were wrong in the *under*claim direction (sholes, work-queue), 3 in the overclaim direction (cicd-squabbler SPARK badge, reposystem `Types.idr` header, proven README). |
| **Fabricated structure / hallucinated references** | ijson-jcs `standards-contract.tsv` (tested); hypatia `scripts/check-sibling-citations.sh` (names cited at a pin must exist); proven-tests `rung` (a cited theorem must exist and have the stated type) | A reference type: `Ref (repo @ commit) path name` that only constructs if it resolves. `rung` already does this for Idris names via elaboration; nothing does it for file paths and cross-repo citations in prose. hypatia's DR001 regex is the ad hoc stand-in. |
| **Confidence drift without new data** | hypatia `BayesianUpdate.idr` (posterior moves only with observations, proved over Nat); receipt P3/P4 (history kept, fill never overwrites) | Runtime wiring: "No run-time code builds a revision, a fill or a withdrawal yet." |
| **Silent green: skipped / cancelled / never-started / stale read as pass** | `Assurance.Verdict` (`skippedRequiredCannotPass`, `staleCannotPass`, `emptyCannotPass`, proved); `Gate_Machine.Evaluate` (SPARK, stated); Creusot `accepted`/`has_evidence` (proved at one revision); `SecretAlerts` exit-code law (proved); R-ENVELOPE (tested) | The GitHub adapter that feeds `Assurance.Verdict` is "unpromoted" after "an invalid duplicate-field response becoming a false passed verdict". The kernel is final; the parse boundary is not. kyq's duplicate-key rejection (`KYAML-MAPS`, OPEN) is the same hole. |
| **Unsafe vs safe dependency bumps (actions)** | `proven-lock` (`EdgesExact`, `complete`, `relockIgnoresEntries`; proved with 2 named axioms); `ActionsLockClosure.idr` (proved); `AllowlistRemediation.idr` (proved additive, idempotent) | Retire the three `check-lock-sync.sh` copies and seven self-SHA implementations in favour of the one judge. The catalogue documents the disagreement; I did not verify whether the retirement has happened. |
| **Unsafe vs safe dependency bumps (packages)** | `SafeSemVer` bump laws (proved, shallow); patch-bridge reachability types (stated, hole) | No compatibility judgement exists anywhere in the cluster: nothing of the form "bump b is safe for consumer c because the changed surface is unreachable/unchanged". This is a genuine gap. |
| **Merge conflicts / diff noise** | kyq `canon-idem`, `nf-unique`, `ker-canon` (proved, theory); sholes `idempotent`, `reflects`, `no-raw-inverse` (proved, theory); ijson-jcs (tested); `merge-actions-lock.rs` (implemented: union-or-refuse) | (i) Proofs are on models; the shipped canonicalisers are TESTED. (ii) Nothing lifts "canonical form" to a *merge* law: if both sides are in normal form and edits commute on keys, the 3-way merge is the key-wise union. `merge-actions-lock.rs` is exactly that partial commutative join for one file format, hand-written. |
| **Trivial syntax failures** | kyq parse gate (tested; grammar proofs OPEN); `Sha256` by `So (isSha256Hex hex)` — a malformed literal does not typecheck (proved); R-SLUG (tested); `KyamlBudget` (proved model) | Refinement-typed literals exist only inside Idris. Workflows, deeds and lock files are still text checked after the fact. |
| **CI cost and flakiness** | work-queue TLA+ (model-checked; found a starvation loop); HAR `noEventLoss`/`noDuplicateDispatch` (proved, conditional); KinGate (model-checked); zero-job attribution in squabbler (implemented) | Nothing measures or bounds CI cost. `sha_bump_propagation.ex` is flag-only. No construct addresses flakiness (a retry is indistinguishable from a pass in `Execution`). |
| **Template drift** | mint-replay equation (implemented, tested); `check-variant-drift.sh` (implemented); canon lockstep (implemented); Coaptation `hardGateSound` (proved) | The equation is unproved and relies on mint determinism. Drift of *copied proof cores* is live: cicd-squabbler carries a 112-line Coaptation core against the template's 324; recon-silly-ation has none; work-queue's README is the unrendered template. |
| **Licence / metadata drift** | chora-registry integrity gate (implemented); `license_finding_strategy → :review` (constant function); fleet refusal gate (bash); `RsrProfile.idr` deed precedence, fail-closed on duplicates (proved model) | Licence policy is a five-way *classification* (CLAUDE.md) that no type encodes; the cap is a constant, not an uninhabited constructor. Registry identity laws (minted once, monotone, no id reuse) are bash. |
| **Partial application of multi-step fixes** | `batchAllOrNothing` (proved); `FsTransaction` (implemented, not all-or-nothing) | `git revert` inverse is ASSUMED; polysafe's `commit` contradicts its doc. |
| **Privilege creep in automation** | `DirCapability::attenuate` (implemented, **does not check subset**); K9 leash levels Kennel/Yard/Hunt (Nickel records); `Clean job decl` (proved) | A capability indexed by its permission set, with `attenuate : Cap p -> (q ⊆ p) -> Cap q`. Hypatia's `Retraction` thinning `_⊆_` is the same order relation already proved. |

---

## 4. Where a type or logic would make an ad hoc mechanism final (ranked)

1. **Lock/pin: one judge.** Evidence of need is in-repo and specific (three copies, seven
   implementations, "green while five reusable callers ended with zero jobs"). The proved kernel exists
   (`Proven.Lock.Judge`). Remaining: prove or shrink the `covering` extractor, and retire the copies.
2. **Status documents rendered from receipts, estate-wide.** Hypatia's `proof-ledger.sh derive/render
   --check` is the working instance. Applying it would have caught, in this cluster alone: sholes "0%
   proven" vs checked proofs; cicd-squabbler "SPARK-proved" with no `gnatprove` in any workflow;
   proven's "41" vs 93 `Proofs.idr`; conflow's self-contradicting PROOF-NEEDS; patch-bridge "EMPTY" vs
   three files; work-queue's missing row.
3. **Mint replay as a checked equation** with a declared variant: `child ≡ mint(template@c, answers)
   mod variant`. The gate exists; the missing theorem is determinism/idempotence of `repo-init` and
   that `variant` paths are the only allowed difference. This is the estate's "equivalence as identity"
   through-line applied to templates.
4. **Canonical-form merge.** kyq and sholes prove retraction + unique normal form on models. Lifting to
   "merge of normal forms is conflict-free when edits touch disjoint keys/lines" would turn
   `merge-actions-lock.rs` from a one-format script into an instance, and would be a real cure for
   lock-file and JSONL-ledger merge conflicts.
5. **Capability attenuation indexed by permission set** (polysafe-gitfixer bug is concrete).
6. **Registry identity as a monotone structure**: `check-registry.sh` checks 5–7 are append-only /
   injectivity / no-reuse laws — natural Idris2 engineering proofs over a `List Entry` model, in the
   style of `Receipt.idr` P1/P3.
7. **Licence classification as a closed sum** with no constructor for "auto-edit": the same trick as
   `MayGap` having no `Must` constructor.
8. **A reference type for citations** (resolves-or-does-not-construct), generalising `rung` and
   `check-sibling-citations.sh`.

---

## 5. Cross-cutting observations

* **Model/runtime gap is universal and admitted.** hypatia: `models-runtime-refinement` `open`;
  kyq: every parser row OPEN; proven-lock: facts extractor "conformance-tested, not proven"; HAR: Rust
  "kept in sync... by hand". The dominant bridge technique in practice is the *shared corpus* (model
  rows are transcribed fixtures; a test binds transcription to fixtures) — see `ActionsLockClosure.idr`,
  `AllowlistRemediation.idr`, `E0ModelTables.agda`, work-queue's `oracle.awk`.
* **Negative controls are a house method** and are well developed: hypatia `tests/reject/` (22),
  kyq `controls/` (9 Agda + 2 Rocq + 4 runner), squabbler's planted false postcondition, work-queue's
  counterexample-must-persist, the template MANIFEST's `quarantine`, proven-tests' `failing` blocks.
* **Unwired proved components.** hypatia: `lib/safety/quarantine.ex` "is not called by any dispatch
  path", `retract_dependents/1` has no caller, `learning.ex` promotion has no caller; gitbot-fleet is
  quarantined wholesale. Doctrine 8 ("unwired is not done") applies.
* **The same idea under five names** (evidence ≠ claim) with only `argued` correspondences between them
  (`verdict-epistemic-correspondence`, `retraction-residual-correspondence`). The upstream sources are
  `epistemic-types` and `residual-evidence-types`, outside this cluster.
* **Template proof boilerplate is still a hazard.** `verification/proofs/{agda/Properties.agda,
  coq/TypeSafety.v, lean4/ApiTypes.lean, tlaplus/StateMachine.tla}` are present in cicd-squabbler,
  sholes, recon-silly-ation, work-queue and the template. The template says they "are never rows";
  five repos' PROOF-NEEDS record the earlier removal of template ABI because it "was creating false
  impression of formal verification".

## 6. Departures from estate rulings met while reading (report-only; nothing changed)

* `.a2ml` files tracked (count by `git ls-files`): cicd-squabbler 123, recon-silly-ation 118,
  patch-bridge 117, hybrid-automation-router 82, reposystem 65, gitbot-fleet 42,
  proven-tests-and-benches 34, proven 28, protocol-squisher 25, polysafe-gitfixer 22, conflow 22,
  action-trust-layers 12, coord-tui 10, chora-registry 3, hypatia 1. Zero in
  proven-cicd-and-workflows, sholes, work-queue, ijson-jcs, rsr-template-repo, kyq.
* Percentages in proof status: sholes `docs/status/PROOF-STATUS.adoc` ("0% proven"), proven README
  badge ("Overall 55%").
* `hyperpolymath/ijson-jcs` has `README.md`, not `README.adoc`.
* cicd-squabbler: "SPARK-proved" badge and "gnatprove-checked in CI" with no workflow running
  `gnatprove` (grep over `.github/workflows`).
* work-queue: `README.adoc` is the unrendered template (`{{PROJECT_NAME}}`).
* Python files tracked: proven-tests-and-benches 4, protocol-squisher 9 (archive) — not inspected.

## 7. Not done / not verified

* No proof was re-checked (no provers installed). Counts of "proven" are the repos' own.
* I did not read proof *bodies* end to end except for sholes `Equivalence.agda`/`Lens.agda`,
  echidnabot `ReceiptBoundary.agda`, squabbler `contracts.rs`/`gate_machine.ads`, proven-lock
  `Axioms.idr`, and the top of several hypatia modules; elsewhere I read headers and signatures.
* proven's 93 `Proofs.idr` files were sampled (7), not audited.
* hypatia's 44 rule files: 4 headers read.
* proven-cicd-and-workflows `actions/*` (33 entries) were listed, not read.
* I did not check whether CI currently passes anywhere, nor read any GitHub issue or PR.
* Cross-repo claims about `epistemic-types`, `residual-evidence-types`, `standards` scripts and
  `echidnabot` are quoted from files in this cluster, not verified in those repos.
