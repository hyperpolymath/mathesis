# Affine / linear / resource / choreographic / session cluster — formal constructs and proof status

Read-only survey, 2026-11-24. Repos (all under `/home/user/estate/hyperpolymath/`):
affinescript, ephapax, resource-algebra, choreographic-types, my-lang, wokelang, eclexia,
betlang, jtv-lang, gnpl, tangle, pseudoscript, lucidscript, phronesis, krl. All 15 were cloned
(none appear as FAIL in `/home/user/estate/.clone.log`).

Method and limits:

* No prover is installed in this session (`which agda coqc rocq lean lake idris2` found
  none), so nothing was re-checked here. "PROVED" below means: a proof file exists, a text
  scan found no `Admitted`/`sorry`/`postulate`/hole in it, and the repo's own status
  document says it checks. Where a CI workflow runs the prover I name it; where none does
  I say so.
* Status vocabulary used here: PROVED (proof file exists), STATED (spec/doc or statement
  only, or proof relative to stub axioms), ASPIRATIONAL (roadmap), IMPLEMENTED-UNPROVED
  (code exists, no proof).
* The "pain it could kill" column is my inference, not a claim made by the repos.
* Every Proof Witness Grade in this cluster that I could find is `ungraded`, except
  jtv-lang, whose STATUS claims a grade for four Agda modules (see section 9).

## 0. Headline findings

1. **The cluster's strongest anti-overclaim construct is resource-algebra's Evidence
   ledger** (`src/ResourceAlgebra/Instances/Evidence.agda`, `src/ResourceAlgebra/Ledger.agda`):
   a proof-ledger row's status is *derived* as the meet of its own evidence with everything
   it reaches through dependencies (`eff`), with soundness (`eff-≼-own`, `eff-≼-dep`,
   `eff-≼-reach`) and maximality (`eff-greatest`: "a recorded status above it is an
   overstatement"). PROVED in Agda, re-proved in Rocq and Lean. No reader consumes it yet
   ("no reader exists yet (the standards ledger reader is planned)").
2. **Ephapax is a worked case of overclaim being refuted by machine**: its preservation
   theorem was `Admitted`, then refuted (`formal/Counterexample.v`,
   `Theorem preservation_false : ~ preservation_stmt.`, line 264). The L1 replacement was
   also refuted. `formal/` now has 0 `Admitted.` and 0 `Axiom` commands (my count over
   `formal/*.v` and `formal/regress/*.v`), and a "no-False gate" in
   `.github/workflows/coq-build.yml` blocks new ones.
3. **my-lang has the most complete engineering bridge**: a parametric soundness functor
   `SoloCoreF (M : ORDERED_SEMIRING)`, a verified checker (`check_correct`), a session-π
   development up to n-party projection totality, and a differential conformance harness
   that runs the Rust implementation against the checker extracted from Coq
   ("25 000 random terms across 5 seeds agree", `proofs/STATUS.adoc`).
4. **choreographic-types proves K-CUT-LOSS** (`src/Choreographic/KCut.agda`, `kcut-loss`)
   for a finite, binary-choice, plain-merge fragment, parametric in any `ResourceAlgebra`,
   plus an asynchronous layer whose directional result ("sender does not know receipt",
   Y-6) is PROVED.
5. **AffineScript's own ledger downgrades most of its Coq corpus**: 20 files, 35
   `Print Assumptions` commands (my count matches the doc), all axiom-free, but
   `docs/EXPLAINME.adoc` lists P-3, P-4 typing, F-1, F-3, F-4, F-5 as `open` because the
   models are definitional or do not model the shipped code, and records a real
   counterexample to F-5.
6. **Fabricated or hollow structure still present in the cluster**:
   * `gnpl/src/GqlDt/TypeSafe.lean:194` `axiom executePreservesTypes … True  -- Placeholder`;
     `gnpl/docs/proof-debt.adoc` counts "16 … real Lean `axiom` declarations", all stubs.
   * `gnpl/MOVED.adoc` says the repo "is now part of the … `hyperpolymath/lith`" monorepo.
     No `lith` repo is among the clones (only `lithoglyph` and `glyphbase`), and the estate
     CLAUDE.md calls the `lith` monorepo fabricated.
   * `my-lang/proofs/shared/ai-semantics/` holds only `README.adoc`; it links
     `type-theory.md`, `operational.md`, `contracts.md`, `handlers.md`, `prompts.md`, none
     of which is tracked, yet `proofs/STATUS.adoc` lists "AI semantics |proved-on-paper".
   * `pseudoscript` and `lucidscript` carry byte-identical RSR template proof files
     (md5-identical across all 13 proof files), e.g. `verification/proofs/agda/Properties.agda`
     ("Replace with your project's domain-specific proofs"), and
     `src/interface/ffi/src/main.zig` still has `{{project}}` placeholders.
   * `phronesis/EXPLAINME.adoc` describes `formal/PhronesisConsensus.tla` as a "TLA+ Raft
     consensus specification"; the file and its `.cfg` are a Byzantine quorum model. The
     same file's table says ephapax uses TLA+ ("Raft consensus for linear type proofs");
     ephapax tracks no `.tla` file.
7. **Status documents that disagree with the files** (drift in both directions):
   * `krl/PROOF-STATUS.adoc` ("Overall: 0% proven", KR-1/KR-2 "remaining"/"blocked") versus
     `krl/verification/proofs/agda/PortArity.agda` and `GeneratorIndex.agda`, whose headers
     say they discharge KR-1, KR-2 and KR-7 "under `agda --safe`". No workflow in
     `krl/.github/workflows/` runs Agda; the commit that added them is titled
     "chore: preserve in-progress KRL Agda proofs".
   * `betlang/PROOF-STATUS.adoc` cites `substTop_preserves_typing` at
     `proofs/BetLang.lean:918`; it is at line 1026.
   * `tangle/PROOF-NEEDS.adoc` says "`proofs/Tangle.lean` (~1604 LoC, 22+ results, all
     `Qed`)"; the file is 2011 lines and is Lean (no `Qed`).
   * `eclexia/FORMAL_VERIFICATION.adoc` (1812 lines, "Research Preview - Formalization
     Roadmap") has a "Lean 4 Formalization" section; eclexia tracks no `.lean` file.
   * `lucidscript/README.adoc` says the compiler "proves it at compile time. No null
     pointer exceptions. No use-after-free. No silent data races", while affinescript's
     ledger lists borrow-checker soundness (P-3) as `open`.

## 1. affinescript

Paths: `formal/` (20 `.v`), `docs/PROOF-NEEDS.adoc`, `docs/EXPLAINME.adoc` (Proof Ledger),
`docs/SOUNDNESS.adoc`, `docs/CAPABILITY-MATRIX.adoc`,
`docs/academic/formal-verification/solo-core/*.idr` (8 modules),
`docs/academic/tropical-session-types/TropicalSessionTypes.lean`.
CI: `.github/workflows/coq-proof-gate.yml` (image `coqorg/coq@sha256:e50d77c4…`, Coq
8.20.1; `formal/README.adoc` documents 8.18 and says reconciling the two "is outstanding").
No workflow runs the Idris2 or Lean files (ledger: "No CI job runs it").

Counts I verified by text: 20 `.v` files in `formal/`; 35 lines starting
`Print Assumptions`; 70 line-start `Qed.`; no `Admitted.`/`Axiom` commands.

| Construct | File | Status | Repo's own caveat |
|---|---|---|---|
| QTT quantity semiring `{0,1,ω}` (`quant`, `qplus`, `qof_plus`, `qof_linear_twice`) | `formal/QttSemiring.v`; Idris2 `Quantity.idr` | PROVED | "The tables match `lib/quantity.ml` … by inspection only. The CI gate does not cover 16 of the 21 laws." |
| Solo core progress + preservation (`progress`, `preservation`, `affinePreservation`) | `docs/academic/formal-verification/solo-core/Soundness.idr` | PROVED (Idris2 0.7.0, `%default total`, local) | "A separate Solo model, not `lib/typecheck.ml` or `lib/borrow.ml`. No CI job runs it." |
| STLC progress/preservation + substitution lemma | `formal/P2_Progress.v`, `formal/P2_Stlc.v` | PROVED | "Textbook STLC with no quantities or affinity, so it is not AffineScript's calculus." |
| Borrow soundness/completeness, #554 witness rejected (`borrow_soundness`, `borrow_complete`, `rejects_554`) | `formal/P3_BorrowSound.v`, `formal/P3_BorrowGraph.v` | PROVED for a model; ledger says `open` | "`borrow_soundness` holds by definition: `borrow_ok` is defined as the negation of the dynamic oracle it is compared against." |
| Quantitative typing `usage_soundness`, `step_preserves_usage`, `affine_no_increase`, `linear_exact` | `formal/QttTyping.v`, `formal/QttDynamic.v` | PROVED for a model; ledger says `open` | "`QttTyping` is an occurrence counter presented as a judgment. `Q_App` does not scale and `Q_Var` accepts any type." |
| Record rows: progress + preservation over a `lacks`-checked row | `formal/Rows.v` | PROVED | "Rows are ordered lists with no row variables." |
| Codegen preservation ladder K-1 (`k1_preservation_holds`, `compile_program_correct`, `compile_stmt_correct`, `mexec_pair_build_proj`) | `formal/K1*.v`, `formal/Real{Wasm,Compile,Loop,Mem}.v` | PROVED for models | "A model, not the shipped compiler … Integers are unbounded `Z`, not i32 … Forward only, with nothing about traps or divergence." |
| Faces ("different faces, same cube"): F-1 transformer preservation, F-3 pragma locality, F-4 error faithfulness, F-5 render injectivity | `formal/F1_*.v`, `F3_*.v`, `F4_*.v`, `F5_*.v` | model PROVED; ledger `open` for all four | F-3 "Both theorems hold for any function and by definition." F-5: "The real `Face.render_ty` is not injective: on the Js face `List[Option[Int]]` and `Option[List[Int]]` both render as `List[Int] \| null`." F-6, F-7 `absent`. |
| Effect-row soundness (P-6) | prose `docs/academic/proofs/effect-soundness.adoc` | STATED (prose), blocked | "Effect rows are not checked against performed operations today (hole H5)". |
| HM inference soundness/principality (P-5), name-resolution determinism (P-7), parser conformance (P-8), trait coherence (P-10) | prose / none | STATED or absent | P-8: "The conformance corpus is not wired, and two valid cases fail to parse". |
| Tropical session types: `tropical_session_soundness`, `budget_strictly_bounds_billing` (max for speculative branches vs + for billing) | `docs/academic/tropical-session-types/TropicalSessionTypes.lean` (153 lines, no `sorry`) | PROVED for a 4-constructor toy `Session`; no CI job found | The file's own header calls it "THE BREAKTHROUGH"; the theorems are two inductions over a toy syntax. |
| Finality types `freeze` / `seal` / `commit` (one-way `1 → ω`, "No `thaw` exists, ever") | `docs/decisions/0023-finality-types.adoc` | ASPIRATIONAL | "Status:: Draft (stub — design-only; no implementation authorised by this document)". |
| CRDTs (`Lww<T>`, `LwwMap<V>`, `OrSet`, `PnCounter`; "`merge` is commutative, associative and idempotent") | `affinescript-crdt/src/Crdt.affine`, `test/crdt.test.js` | IMPLEMENTED-UNPROVED | Laws stated in README; tested, not proved. |
| Polonius origin variables (ADR-022) | `docs/decisions/0022-…`, `test/test_borrow_polonius.ml` | IMPLEMENTED-UNPROVED | SOUNDNESS: "implemented through M3 but … test-only/unwired". |
| Soundness ledger vocabulary (`fixed`, `loud-fail`, `removed`, `residual (pinned)`, `open (tracked)`) with a test anchoring every row | `docs/SOUNDNESS.adoc` | method, in use | — |
| Stated-obligation pattern: obligations as `Definition … : Prop` over section variables, each discharged by a `*_discharged : Siblings_Stated.<name> … := <proof>` line | `formal/Siblings_Stated.v` | PROVED (pattern) | — |

Also noted: `docs/decisions/0023-finality-types.adoc` names
`.machine_readable/descriptiles/META.a2ml` as the place for a companion entry (an A2ML
reference; affinescript tracks 0 `.a2ml` files and 31 `.deed`).

## 2. ephapax

Paths: `formal/*.v` (17 files + `formal/regress/` 4 files), `PROOF-NEEDS.adoc` (996 lines),
`STATUS.adoc`, `formal/L1-CHOREO-EXPERIMENT.adoc`, `src/formal/Ephapax/Formal/*.idr`,
`src/abi/Ephapax/ABI/Invariants.idr`,
`docs/reports/2026-11-04-v2-survey/EPHAPAX-V2-ARCHITECTURE-AND-PLAN.adoc`.
CI: `coq-build.yml` (no-False gate, with a "scanner self-test"), `status-gate.yml` ("fail
when the PROOF-NEEDS.adoc / TEST-NEEDS.adoc count markers drift from coqc/cargo ground
truth"), `abi-verify.yml`, `ffi-seams.yml`.

Counts I verified by text: 0 `Admitted.` commands, 0 `Axiom`/`Parameter`/`Hypothesis`
commands, 241 line-start `Qed.` across `formal/` and `formal/regress/`. `Echo.v` has 19
textual `Qed.` (doc says 19). I could not reproduce the "37 Qed" figure for
`Semantics_L1.v` (42 line-start, 53 textual including comments); PROOF-NEEDS itself gives
both 37 and 54 in different sections.

| Construct | File | Status |
|---|---|---|
| Refutation of legacy preservation: `preservation_stmt : Prop`, `preservation_false : ~ preservation_stmt` | `formal/Semantics.v:8556`, `formal/Counterexample.v:264` | PROVED (a refutation) |
| Refutation of unrestricted L1 preservation and step-pop disjointness | `formal/Counterexample_PreservationL1.v`, `formal/Counterexample_StepPop.v`, `formal/Counterexample_RegionShrink.v` | PROVED (refutations) |
| L2 soundness-gap witnesses (fresh-region scope crossing; nested `TFunEff`) | `formal/Counterexample_L2.v`, `formal/Counterexample_L2_nested.v` | PROVED (5 + 5 Qed) |
| v2 regression families (ClosedCex, EchoCex, PairDup, EchoCopy, EscapeCex, L2Comp, LetCheck) | `formal/regress/*.v` | PROVED ("Regressions only") |
| Sound replacement preservation theorems for L1/L2 | — | OPEN ("No unconditional theorem established") |
| Modality thin poset `Linear ≤ Affine` (`modality_le`, `linear_to_affine`) | `formal/Modality.v`, `formal/TypingL1.v` | PROVED |
| Echo / residue fiber (`Echo f y`, `LEcho`, `weaken`, `no_section_collapse_to_residue`, `degrade_mode_comp`, `mode_join`) | `formal/Echo.v` | PROVED (19 Qed); scoped `preservation_l3` for two echo-emitting rule pairs only |
| Region environment as multiset (`enterL1`/`exitL1`, `exit_comm`, `enter_comm`, `exit_enter_id`, `live_exit_other`) | `formal/RegionEnvL1.v` | PROVED |
| Choreographic reading of a region lifecycle (`open . use . close`): verdict "RELOCATES"; `close_derives_coherence` left as a bare `Prop`, "never proved" | `formal/L1ChoreoExperiment.v`, `L1ChoreoExperiment2.v` (`congruence_dichotomy`, `sibling_use_keeps_region_live`) | PROVED negative result + trace-model lemmas |
| L4 dyadic `ProgramMode` (`PModeLinear`/`PModeAffine`/`PModeBoundaryMix`) | `formal/L4.v` | STATED ("Definitions only — no theorems") |
| Linear context split coverage (`Split`, `nonDiminishment`, `splitLinearCoverage`) | `src/formal/Ephapax/Formal/Qualifier.idr` | PROVED (Idris2; not re-checked here) |
| Region outlives / no-escape narrow form (`Outlives`, `outlivesTransitive`, `noEscapeTheorem`) | `src/formal/Ephapax/Formal/Region.idr`, `RegionLinear.idr` | PROVED narrow form; general form OWED |
| ABI seam obligations (`typePreservation`, `linearConsumptionAcrossControlFlow`, …) | `src/abi/Ephapax/ABI/Invariants.idr`, `Foreign.idr` | STATED: "12 in all … they assert nothing about Ephapax" (erased postulates over empty relations) |
| Banned anti-pattern list (§3 A–F) and "Anti-pattern detector" for agent sessions | `PROOF-NEEDS.adoc` | method, prose |

Quotes worth keeping:

* "While they were `Admitted`, the build could derive `False`; CI's no-False gate
  (`coq-build.yml`) now blocks any new `Admitted`/`Axiom`/`Parameter`."
* "A refuted theorem requires an explicit redesign or restricted replacement, not an
  attempt to prove the old claim."
* "No result in this repository carries a PWG."
* §3 names PRs "#92, #102, #104, #106, #114, #116, #117, #121, #146" as "archaeology":
  repeated sessions tried to close a false theorem.

Departures seen (not touched): 29 `.a2ml` files tracked, including
`formal/PROOF-STATUS.a2ml` and `0-AI-MANIFEST.a2ml`.

## 3. resource-algebra

Paths: `src/ResourceAlgebra/*.agda` (Core, Prelude, Drift, Ledger, Separation, Morphism,
Parallel, Star, `Instances/{Loss,MaxPlus,MaxPlusTop,HWM,SignedHWM,MinMax,Questions,Evidence,Diamond}`),
`verification/proofs/coq/ResourceAlgebra.v` (1944 lines),
`verification/proofs/lean4/ResourceAlgebra.lean` (2469 lines),
`verification/bridges/tropical-types/TropicalBridge.lean`, `tests/reject/*.agda` (23 files),
`docs/status/PROOF-STATUS.adoc` (1106 lines, revdate 2026-11-19).
CI: `.github/workflows/proofs.yml`; scripts `check-agda.sh`, `check-lean-leg.sh`,
`check-lean-bridge.sh`, `proof-receipt.sh`, `scan-postulates.pl`.

Census (PROOF-STATUS): "Out of 48 theory rows: PWG-1: 0 · PWG-2ii: 0 · PWG-2i: 0 ·
PWG-3: 0 · ungraded: 48. No leg has a current receipt, so nothing is graded". The reason
given: rows D-1..D-8 changed the inputs of all three legs, so the recorded run at `201e05b`
is `superseded`. The proofs are all `PROVEN` in §5 terms; the grades wait on a receipt.

| Construct | Rows | Status |
|---|---|---|
| `record ResourceAlgebra` (`Grade`, `⊕` alternatives, `⊗` sequence, `𝟘`, `𝟙`) with layers `IsOrdered`, `IsDioid` (yields `IsOrdered` "by a proof, not a second obligation"), `IsAnnihilating`; `IsDioid` omits absorbing zero because HWM has 𝟘 ≡ 𝟙 | C-1..C-4b | PROVED (Agda `--safe --without-K --cubical-compatible … -W error`, Rocq, Lean) |
| Instances Loss (min/+), MaxPlus (max/+), MaxPlusTop, HWM (componentwise max / peak-and-drift), SignedHWM, MinMax (min/max), Questions (intersection/union of n booleans), Diamond (ordered + annihilating, not a dioid) | L-1, M-1, H-1, H-3, N-1, Q-1..Q-4, K-3, D-1..D-8 | PROVED; M-2 (agreement with tropical-types' Lean instance) is Lean-only and "stays ungraded whatever the receipts say" |
| Evidence algebra: chain `open-row < tested-only < argued < proven-with-postulates < proven`, ⊕ = stronger, ⊗ = weaker | E-1 | PROVED |
| Ledger: `eff (r ∷ L) zero = own r ⊓e ⨅ (map (eff L) (deps r))`; soundness and maximality | E-2, E-3 | PROVED. Caveat in file: a dangling dependency index "reads … as proven", so "any reader of a ledger must check each dependency … That is a precondition every reader must enforce, not a guarantee given here". |
| Morphisms `Hom` (strict) and `LaxHom`; classifications (`peak-lax`, `no-strict-from-HWM`, exactly two strict maps Loss → MaxPlus, `count-not-⊕`) | F-1..F-10 | PROVED |
| Separation witnesses (`occupancy-is-not-cost`, `alternatives-differ`, `loss-order-reversed`, `bottleneck-is-not-sum`) | S-1..S-4 | PROVED |
| Parallel composition `IsParallel` and the two exchange laws `SyncBelow`/`SyncAbove`; `MaxPlus-span-not-sync-below`, `HWM-not-sync-above` | P-1..P-4 | PROVED |
| Loop grade `IsStar`; `MaxPlus-no-star`, `HWM-no-star`, `SHWM-no-star`; star exists for Loss and MaxPlusTop | K-1..K-4, D-6 | PROVED |
| Cross-repo correspondences (Loss ≡ echo-types transcription; HWM adopted by occupancy-types; MinMax transcribed by typed-wasm) | L-2, H-2, N-2 | L-2 `ASSUMED` ("checked by eye"); H-2 "PROVEN downstream"; N-2 "TESTED downstream" |
| Transport of K-CUT-LOSS along a morphism; trough of a signed run | Open section | OPEN |

Methods implemented here (each could be reused estate-wide):

* **Expected rejections**: "Twenty-three claims must be refused, each with the message
  its `-- EXPECT:` line names." A refusal with a different message fails the gate.
* **Trusted-base scan**: the gate "allows exactly four postulates, all in
  `Agda.Primitive`"; `tests/check_agda_trusted_base_test.sh` "plants four such changes to
  show that it does".
* **Receipts**: `verification/receipts/resource-algebra-proofs_praxis.deed`; the standards
  reader "derives every grade from the legs and receipts, and refuses a recorded grade
  that differs".
* **Honest CI history**: "until 2026-10-14 that workflow called a script that does not
  exist, so a CI check is evidence only from its first green run."

## 4. choreographic-types

Paths: `src/Choreographic/*.agda` (20 modules, 3958 lines with tests), `tests/reject/*.agda`
(8 files), `PROOF-STATUS.adoc` (483 lines), `docs/pre-registration*.adoc`,
`scripts/check.sh`, `scripts/minimal-laws.sh`, `scripts/check-repository.mjs`,
`scripts/fetch-siblings.sh`. CI: `.github/workflows/proofs.yml`.
Grades: "every theorem here is `ungraded` … no Rocq or Lean leg exists."

Fragment: "Finite graded global types with message and *binary* choice; endpoint
projection with *plain merge* … *Not* in the fragment: recursion (μ-types), full merge,
delegation, n-ary choice …, queues as data, and data-dependent warrants".

| Construct | Row | Status |
|---|---|---|
| K-CUT-LOSS: `kcut-loss : ∀ p G (c : Cut G) → Consistent p c → grade↾ p (G ↾ c) ≡ lgrade (proj p G ↾ₗ cutproj p c)` | K-1 | PROVED |
| `proj-cut` (projection commutes with cutting, no algebra laws), `grade-proj`, `cut-projectable` | K-2, K-3, K-5 | PROVED |
| Minimal-laws certificate: K-CUT-LOSS "uses exactly two laws: `𝟙 ⊗ x ≡ x` and `x ⊕ x ≡ x`" | K-4 | TESTED (`scripts/minimal-laws.sh` checks KCut against a two-field Core) |
| Discharge at Loss, MaxPlus, HWM | K-6 | PROVED |
| Kripke frame over consistent cuts; `sound-warrant`, `knows-own-grade`; bound form `knows-lower-bound` / `knows-upper-bound` | W-1..W-6 | PROVED, with 2026-11-09 audit notes: "`sound-warrant p w φ` is defined for *every* φ, including `λ _ → ⊥`"; "`own-grade-warrant` warrants the tautology …" |
| "Cannot determine": a claim to know the global grade is refused | W-7 | TESTED (`tests/reject/GlobalGradeKnown`) |
| Transport: `↾ₗ-injective`, `knows-local-cut`, party access preorder `p ⊑ q`, `knows-mono` | T-1..T-6 | PROVED; T-5 negative half "rests only on that fixture … no `¬ (1 ⊑ 2)` theorem exists" |
| Asynchrony: `embed-settled`, `akcut-loss`, `flight-invisible`, `receiver-knows-sent`, `sender-cannot-know-receipt`, `reply-gives-knowledge`, `reply-in-flight-is-not-enough` | Y-1..Y-8 | PROVED ("All eight claims came out as pre-registered") |
| Swap of disjoint interactions (`swap-proj`, `swap-grade↾`), `two-thread-diamond`, `commuting-square`, shared-sender/receiver swaps change projections | A-1..A-8, I2-1..I2-4 | PROVED / TESTED; `hwm-order-sensitive` (peak 3 vs 5) TESTED |
| Precise K-CUT-WARRANT record (`KCutWarrantComplete`, `ReceiverLocalSideCondition`) | WC-1..WC-5 | PROVED (WC-4 conditional) |
| Bound propagation (`bound-step-msg`, `bound-step-choice`, `projection-theorem`) | GS-1..GS-4 | PROVED |
| Echo-additive instance equals Loss (`toLoss∘fromLoss`, …) | E-1..E-4 | PROVED |
| Whole-world partial recovery forbidden under view collision | PR-1, PR-2 | PROVED / TESTED |
| Application target `applications/rapidnj-two-thread.agda` | — | STATED: "the file's single postulate block declares 18 names … The file is outside the gate and is not type-checked." |

Methods:

* **Row-to-proof binding** (`scripts/check-repository.mjs`): "the comment directly above
  that definition … must name the row, as `-- Ledger K-1.` A row cannot outlive its proof,
  and a proof cannot be claimed by a row that does not point at it." Explicitly "does not
  typecheck a proof."
* **Pre-registration with a falsifier** (`docs/pre-registration-addendum-2026-10-19.adoc`).
* **Sibling pins by full SHA** in `scripts/fetch-siblings.sh`.
* CI honesty note: "the `proofs.yml` that merged with #23 never ran on GitHub — all eight
  runs ended in `startup_failure` … The green runs it cited were local."

## 5. my-lang

Paths: `proofs/verification/coq/solo-core/{ResourceAlgebra,Quantity,SoloCore,Tropical,Eval,SessionPi,SessionEval,EchoMode,EchoResidue,EchoMeasure,Extract}.v`,
`proofs/verification/idris/solo-core/*.idr`, `proofs/STATUS.adoc` (1105 lines; "This file
is the single authoritative source"), `conformance/`, `crates/my-qtt`.
CI: `.github/workflows/proofs.yml` greps `Print Assumptions` output for "Closed under the
global context" per theorem. Counts verified by text: 194 line-start `Qed.` in
`coq/solo-core/`, 0 `Admitted.`; 15 `Axiom` lines in `ResourceAlgebra.v`, which
`PROOF-NEEDS.adoc` explains are `Module Type` interface fields discharged by each instance.

| Construct | Status |
|---|---|
| `Module Type SEMIRING` / `ORDERED_SEMIRING`; soundness functor `SoloCoreF`; `Include SoloCoreF Linear3` gives `progress` / `preservation` / `affine_pres` | PROVED (CI) |
| Tropical instance at an infinite carrier (`SoloTropical := SoloCoreF Tropical`) | PROVED (CI) |
| Affine layer `aff_type G D t a := ∃ D0, has_type G D0 t a ∧ ule D0 D`; `aff_weaken`; `affine_pres` | PROVED |
| Verified checker: `check_correct : has_type G D t a ↔ check G t = Some (a, D)`; `typing_unique`; `aff_type_dec` | PROVED |
| Surface elaboration `me → solo`: `elab_data_check`, `me_wt_sound : me_wt G D e a → has_type G D (elab e) a` | PROVED |
| Session-π: `dual_involutive`, `wt_subst`, `sr_comm`, `config_subject_reduction`, `session_fidelity`, `config_progress` (two-party fused form), n-ary labelled choice, `wt_congr`, μ type layer (`unfold_mu`, `dual_unfold`, `guarded`), `projection_duality`, `merge_idem`, `projection_total` (n-party, plain merge) | PROVED, each with a stated fence; "Subject reduction is NOT claimed" for the open `proc` calculus; μ typing layer "NOT mechanised" |
| Functional steppers sound/complete vs relations (`step1_sound`, `step1_complete`, `cstep1`, `gstep1`, `nstep1`) | PROVED |
| Echo residue-measure seam (`RESIDUE_MEASURE`, `EchoTraceTropical`, `echo_measure_not_injective`) | PROVED |
| Rust checker and evaluator refine the Coq ones | TESTED ("conformance-checked": extracted OCaml oracle vs `crates/my-qtt`, "25 000 random terms across 5 seeds agree"; "45 000 results" for evaluation); "NOT a full Rust-in-Coq refinement proof" |
| Idris2 solo core (`Soundness.idr`, `Substitution.idr`) | PROVED per STATUS ("locally-checked"); a `proofs.yml` Idris job is named in STATUS |
| Paper proofs: type soundness, effects, ownership, sessions, agent calculus | STATED ("proved-on-paper") |
| AI as an effect (`Γ ⊢ ai query { prompt: e } : AI⟨String⟩ ! AI`; "Theorem 1 (AI Type Safety)" … "Theorem 4") | STATED in a README only; the five linked files are absent |

Departures seen: 33 `.a2ml` files tracked.

## 6. wokelang

Paths: `docs/proofs/verification/WokeLang.lean` (2148 lines), `WokeLang.v` (1658),
`WokeGrammar{,CFL,Pumping,Regular,Structure}.lean`, `WokeGrammar{Parser,Structure}.v`,
`src/abi/WokeLang/{Calculus,Typing,Reduction,Safety}.idr`. No `sorry`/`Admitted`/`axiom`
found by text scan. CI: `lean-proofs.yml` runs `lean` on all six Lean files;
`coq-proofs.yml` exists (not read).

| Construct | Status |
|---|---|
| Core type safety: `progress`, `preservation`, `type_safety`, store typing (`store_step_preservation`, `stmt_exec_preservation`) | PROVED (Lean) |
| Consent: `consent_monotonicity`, `consent_preservation` | PROVED, but thin: both are function-update facts about `grantConsent` (`ConsentState := Permission → Bool`) |
| Capability subsumption partial order (`capSubsumes_refl/trans/antisymm`, `hasCapability_mono`) | PROVED |
| Grammar: `completeness_rp : parseAll (rp e) = some e`, `parse_deterministic`, `rp_injective` | PROVED (Lean and Coq) |
| Grammar structure: `no_left_recursion`, `guard_pattern_is_left_recursive` (as written), `not_LL1`, `LL2_separates` | PROVED (Coq) |
| CFL closure (`cfl_union`, `cfl_concat`, star) and pumping | PROVED (Lean) |
| Idris2 safety with audit log (`progress`, `preservation`, `nonEvasion`, `consentBodyRequiresLog`) | file has no holes by text scan; not re-checked; `PROOF-NEEDS.adoc` calls the ABI proofs "template-level" |
| Evaluator and WASM backend match the Lean model | OPEN (`PROOF-NEEDS.adoc`) |
| Echo types in the checker, "Isabelle preferred" proof narrative | ASPIRATIONAL (README "Frontier") |

## 7. eclexia

Paths: `formal/coq/src/{Syntax,Typing,Echo,EchoThermo,ShadowPrices}.v`,
`formal/agda/ResourceTracking.agda`, `docs/proof-debt.adoc`, `FORMAL_VERIFICATION.adoc`.
CI: `verify-coq-proofs.yml` (opam `coq.8.18.0`, `make` in `formal/coq`). No Agda job
("*Not gated*: no CI job, script or recipe runs Agda here").

| Construct | Status |
|---|---|
| Dimension algebra (`dim_mul_assoc`, `dim_mul_comm`, `dim_mul_inv_l`) and `dimensional_safety` | PROVED (Coq) |
| `progress`, `preservation`, `soundness` for the core calculus | PROVED (Coq) |
| Resource-tracking soundness (`tracking-soundness'`, `usage-monotonic`, `composition-additive`) | PROVED in Agda for "the refined `ConsumesResource'` only"; manual receipt dated 2026-11-17; the original statement "is unprovable" |
| Shadow prices as LP dual variables (`dual_variables_are_shadow_prices`, `slack_implies_zero_shadow_price`) | STATED relative to 5 axioms (`weak_duality`, `complementary_slackness`, `lp_sensitivity`, `strong_duality`, `dual_simplex_converges_to_optimal`); "`ShadowPrices.v` is *not* built by CI" |
| Erasure cost (`bennett_reversible_is_free`, `irreversible_costs_at_least_one_bit`, `erasure_monotone`) | PROVED (`EchoThermo.v`, 71 lines; listed in `formal/coq/_CoqProject` line 14, so the CI `make` builds it; `# src/ShadowPrices.v` is commented out at line 22) |
| Logical relations, step-indexing, separation logic, session types, Lean leg, verified compilation | ASPIRATIONAL (`FORMAL_VERIFICATION.adoc`; no `.lean` file tracked) |

## 8. betlang

Paths: `proofs/BetLang.lean` (1280 lines, no `sorry`, no `axiom`), `PROOF-NEEDS.adoc`,
`PROOF-STATUS.adoc`, `tools/proof-scan.sh` (named, not read). CI: `proofs.yml`.

| Construct | Status |
|---|---|
| `Ty.dist`, `bet` (ternary uniform choice, three non-deterministic step rules), `sample` | — |
| `progress`, `preservation`, `type_safety`; `substTop_preserves_typing` (former axiom, now a theorem at line 1026) | PROVED |
| Distribution monad laws at the syntactic/typing level | PROVED |
| Echo intro/elim (`canonical_echo`) | PROVED |
| Measure-theoretic semantics, entropy bound, SLLN, 5 ABI obligations, TLA+ concurrency model | OPEN (10 of 15 obligations remain; the doc reports "33% proven (5 / 15)") |

## 9. jtv-lang

Paths: `jtv_proofs/*.lean` (7 libraries), `theory/agda/src/Jtv/{Core,Reversal,Echo,Conditional}.agda`,
`verification/PROOF-STATUS.adoc`, `verification/receipts/`, `verification/ledger/`,
`crates/jtv-proof-ledger`. CI: `proof-regression.yml` (`lake build`), `agda-proof-policy.yml`.

| Construct | Status |
|---|---|
| Harvard separation: Data language (total, addition-only) vs Control language; `no_control_to_data_flow`, `joinpoint_unidirectional`, `no_reverse_joinpoints`, `string_not_executable`, `owasp_code_injection_mitigated` | PROVED for the Lean model; README: "interpreter not yet wired to the proofs" |
| Data totality, determinism, termination (`data_terminates`, `data_step_deterministic`, `strong_normalization`, `confluence`, `bigstep_denotational_equiv`) | PROVED |
| Echo lattice `safe ⊑ neutral ⊑ breaking`; `blockEcho_admissible`, `breaking_blocks_reversal`, `blockEcho_admissibleWithResidue` | PROVED (Lean and Agda) |
| Reversibility with a token (`reversible_if_with_residue`) and the counterexample `tokenless_conditional_not_identity` | PROVED (Lean and Agda) |
| Number-system tiers (`float_not_safe`, `float_neutral`, `hex_binary_collapse`) | PROVED |
| Derived-grade ledger: grades "derived by `crates/jtv-proof-ledger` into `verification/ledger/PWG.adoc` (§4), and CI fails if that file drifts from the receipts" | method, implemented (not run here) |
| Lean ↔ Agda reconciliation | "every leg `BRIDGE-PENDING`"; Lean's `residue_lossy` is weaker than Agda's `loss-is-real` |
| Rocq leg; refinement to the Rust interpreter | absent ("the Lean token is a single-op `Int` residue; the runtime token is a multi-op `Vec<RecordedOp>` log, and no refinement connects them") |

`STATUS.adoc` line 192 writes "*Grade 3* held for four Agda modules" without the `PWG-`
prefix the estate rule requires; `verification/PROOF-STATUS.adoc` uses the prefix.

## 10. gnpl

Paths: `src/Gnpl/Core.lean` (172 lines), `PROOF-PROGRESS.adoc`, `docs/proof-debt.adoc`,
`src/GqlDt/**` (private substrate). CI: `lean-build.yml`.

| Construct | Status |
|---|---|
| `structure Warrant (f : Fabula) (s : Focalization) (r : AssertionRequest)`, `Narration f s rs` indexed by the requested assertion list; `checkWarrant : … Except Refusal (Warrant f s r)` | implemented; witnesses are constructed by a decidable rule |
| `withdrawn_cannot_support`, `narration_preserves_projection` | PROVED (Lean; axiom report `[propext]`, audited by `test/NarrationProofAudit.lean`); "the local Lean 4.15.0 build … not … remote CI" |
| GqlDt substrate (`executePreservesTypes`, `insertWithValidScore`, `parseToIR`, …) | STATED via stub axioms: "16 are real Lean `axiom` declarations … Every one is a *stub*"; "`executePreservesTypes` proves nothing. Its statement reduces to `… → True`" |

## 11. tangle

Paths: `proofs/Tangle.lean` (2011 lines), `proofs/TG3Differential.lean` (524 lines,
generated), `PROOF-NEEDS.adoc`, `PROOF-NARRATIVE.adoc`, `ASSUMPTIONS.adoc`.
CI: `lean-proofs.yml`, `ocaml-ci.yml`.

| Construct | Status |
|---|---|
| Types `word n`, `echo ρ τ`, `epi κ ρ τ`, products; `progress`, `preservation`, `determinism`, `type_safety`, `weakening`, `subst_preserves` | PROVED |
| Decidable typing: `infer_sound`, `infer_complete`, `infer_iff_hasType`, `type_unique` | PROVED |
| Echo capstones (`echo_lower_collapses`, `echo_residue_recovers`, `echo_distinguishes_collapsed`) and epistemic capstones (`epi_claim_is_opaque`, `epi_only_yields_evidence`, `epi_distinguishes_standpoints`) | PROVED |
| Differential certificate: 490 generated `example : infer [] … = some … := by decide` lines certifying that OCaml `infer_expr` agrees with the proven Lean `infer` | PROVED per instance (a kernel-checked test corpus, not a universal theorem) |
| `braidEquiv` decides braid-group equality (Dehornoy handle reduction, fuel 1000000) | IMPLEMENTED-UNPROVED: "TRUSTED, NOT PROVEN … The sorry/axiom gate passing does NOT mean this claim is proven" |

## 12. phronesis

Paths: `academic/formal-verification/lean4/Phronesis.lean` (884 lines),
`coq/Phronesis.v` (829), `agda/Phronesis.agda`, `agda/PhronesisEcho.agda`,
`formal/PhronesisConsensus.tla` + `.cfg`, `lib/phronesis/reflexion/`, `docs/REFLEXION.adoc`.
CI: `lean.yml`, `tla-consensus.yml`. No Coq or Agda job found.

| Construct | Status |
|---|---|
| `progress`, `preservation`, `determinism`, `subtype_trans` | PROVED (Lean) |
| Capability discipline: `capability_soundness`, `capability_soundness_ite`, `least_privilege`, `no_escalation`; `sandbox_clean` | PROVED (Lean model) |
| Policy arbitration: `bestMatch_sound`, `bestMatch_none`, `bestMatch_decisive`, `bestMatch_maximal` | PROVED |
| BFT quorum intersection `bft_no_two_quorums`, `bft_agreement`; TLA+ model with invariants `TypeOK`, `Agreement`, `Validity`, `ByzantineSafety` (N = 4, F = 1) | PROVED (Lean) and model-checked by configuration (TLC run not reproduced here) |
| Reflexion layer: `Claim`, `JudgementEvidenceGraph` (8 evidence kinds), `InvariantPath` (`principle → construct → static_rule → proof_obligation → runtime_behaviour → audit_trace`), classification taxonomy (`:equivalent`, `:refinement`, `:strengthening`, `:orthogonal_extension`, `:weakening`, `:semantic_drift`, `:contradiction`, `:unresolved`) with gate verdicts, SHA-256 hash-chained `DesignLedger` | IMPLEMENTED-UNPROVED: "The equivalence engine is heuristic. The formal invariant-path equivalence check is stubbed and currently falls through to `:unresolved`" |

## 13. krl

Paths: `verification/proofs/agda/PortArity.agda` (230 lines), `GeneratorIndex.agda` (59),
`PROOF-STATUS.adoc`, `spec/grammar.ebnf`. No Agda CI.

| Construct | Status |
|---|---|
| Arity-indexed tangles `Tangle m n` (sigma : 2 → 2, cup : 0 → 2, cap : 2 → 0, compose requires `out(a) = in(b)`); `lower-preserves-arity`, `compose-mismatch-rejected`, `close-needs-square`, `trefoil-lowers` | proof terms written under `{-# OPTIONS --safe #-}` (not the §2.1 profile: no `--without-K`); no CI, no receipt; the status doc says 0 of 8 done |
| `checkIndex`, `accepts-iff-pos`, `rejects-zero` (KR-7) | as above |
| `simplify` semantics-preserving (KR-3), R3 invariance | OPEN / blocked |

The Agda header also records a spec defect: "The narrative prose for `sigma` ('in=i,
out=i+1 (and same arity in/out)') is internally contradictory and cannot be encoded as
written". Also: `src/interface/Abi/` and `src/interface/abi/` are identical directories
differing only in case (`diff -rq` reports no difference), which collide on a
case-insensitive filesystem. 122 `.a2ml` files tracked.

## 14. pseudoscript, lucidscript

Both READMEs: "This repo is a **brand surface only**. The compiler, type checker, borrow
checker, and codegen all live in … affinescript." Each tracks 123 `.a2ml` files and an
identical set of RSR template proof files (`verification/proofs/{agda,coq,idris2,lean4,tlaplus}/`).
No domain construct lives here. The pseudo and lucid faces are AffineScript's F-family
(section 1).

## 15. Mapping to recurring engineering pains (my inference)

| Pain | Constructs that bear on it | Readiness |
|---|---|---|
| AI/LLM overclaim, status drift | Evidence ledger `eff` (resource-algebra E-1..E-3); row-to-proof binding (choreographic-types); `jtv-proof-ledger`; ephapax status-gate and no-False gate; AffineScript ledger vocabulary | Theory PROVED; the standards ledger reader that would apply `eff` to real ledgers does not exist yet. |
| AI closing false theorems / admit-shuffling | Ephapax pattern: retire a refuted `Admitted` to a `Prop`, pin a `Qed` counterexample, gate `Admitted`/`Axiom`/`Parameter` | In use in one repo. |
| Fabricated structure (theorem that says `True`, stub axioms, template proofs) | Expected-rejection controls (`tests/reject` + `-- EXPECT:`); trusted-base postulate scan with planted-violation self-test; minimal-laws certificate | In use in resource-algebra and choreographic-types; gnpl, pseudoscript, lucidscript, krl show the failure it would catch. |
| Merge conflicts / clashes | Swap / Independent₂ diamond (disjoint footprints commute at every endpoint; shared sender or receiver does not); CRDT merge laws (commutative, associative, idempotent); braid isotopy as equivalence | Diamond PROVED for the finite fragment; CRDT laws untested by proof; `braidEquiv` unproven. |
| Stale assumptions across async boundaries (webhooks, queues, CI callbacks) | Y-5 `receiver-knows-sent`, Y-6 `sender-cannot-know-receipt`, Y-8 `reply-gives-knowledge` | PROVED for first messages of a finite protocol. |
| Protocol errors between services/agents | my-lang session-π (duality, fidelity, progress, projection totality); jtv Harvard separation | PROVED on restricted fragments; not wired to a shipped runtime. |
| Trivial syntax failures | wokelang `completeness_rp`, `parse_deterministic`, `rp_injective`, `no_left_recursion`, LL(2) separation; AffineScript faces; tangle `infer_iff_hasType` | wokelang PROVED for an expression fragment; AffineScript P-8 open with two valid cases failing to parse. |
| Implementation ≠ spec | my-lang extracted-oracle differential conformance; tangle generated `by decide` corpus; `step1_sound`/`step1_complete` pattern | TESTED bridges, explicitly not refinement proofs. |
| CI cost and wall-clock | MaxPlus vs Loss vs HWM; `budget_strictly_bounds_billing`; `occupancy-is-not-cost`; `bottleneck-is-not-sum`; no-star results (loops have no finite grade in MaxPlus/HWM) | Algebra PROVED; no tool applies it to workflows. |
| Unsafe vs safe dependency bumps, template drift | Phronesis classification taxonomy (equivalent / refinement / strengthening / orthogonal extension / weakening / semantic drift / contradiction / unresolved); `Hom` vs `LaxHom` (equality-preserving vs bound-preserving change); Questions grade ("which questions were lost") | Taxonomy is heuristic Elixir with the formal check stubbed; algebra PROVED but unconnected to versioning. |
| Use-once resources (tokens, handles, one-shot migrations) | QTT `{0,1,ω}`; `aff_type`; `splitLinearCoverage`; finality `freeze` | Semiring and my-lang checker PROVED; AffineScript real-checker soundness open; finality is a draft. |
| Unit and dimension errors | eclexia `dimensional_safety`; wokelang `measured in` | eclexia PROVED for its core calculus. |
| Injection | jtv data/control grammar separation | PROVED for the model only. |
| Hallucinated claims without evidence | gnpl `Warrant` indexed by evidence snapshot, `withdrawn_cannot_support`; choreographic `WitnessedWarrant`; tangle `epi_only_yields_evidence` | Small PROVED kernels. |

## 16. Gaps and things I did not establish

* Nothing was re-checked by a prover in this session.
* I did not read every proof body; theorem lists come from declaration scans plus the
  repos' status documents. The long files `ephapax/formal/Semantics.v` (8569 lines),
  `Semantics_L1.v` (3583), `my-lang/…/SessionPi.v` (3554) and `SoloCore.v` (3106) were
  sampled, not read in full.
* wokelang's `lean-proofs.yml` runs `lean` on all six Lean files (`WokeLang`,
  `WokeGrammar`, `WokeGrammarStructure`, `WokeGrammarRegular`, `WokeGrammarCFL`,
  `WokeGrammarPumping`). I found no job that checks phronesis' Coq or Agda files.
* Idris2 files (ephapax, wokelang, my-lang, affinescript solo-core) were scanned for
  holes and escape hatches only.
* Sibling repos that this cluster leans on (echo-types, epistemic-types, tropical-types,
  occupancy-types, typed-wasm, invariant-path) are outside this brief and were not read.
* A2ML is still tracked in 12 of the 15 repos (counts: ephapax 29, my-lang 33, wokelang 27,
  eclexia 26, betlang 21, jtv-lang 32, gnpl 8, tangle 19, pseudoscript 123, lucidscript 123,
  phronesis 16, krl 122); affinescript, resource-algebra and choreographic-types track none.
