# Echo / residual-evidence / epistemic / secret / occupancy cluster: formal constructs, proof status, engineering reach

Read-only research pass, 2026-11-24. Cluster root: `/home/user/estate/hyperpolymath/`.
Repos: `echo-types`, `EchoTypes.jl`, `echobox`, `residual-evidence-types`,
`ResidualEvidenceTypes.jl`, `epistemic-types`, `EpistemicTypes.jl`, `secret-types`,
`occupancy-types`.

## 0. How to read this file

* **PROVED** = a proof source file exists in the checkout, is inside a named
  CI/typecheck root, and the repo records a receipt for it. *I did not re-run
  any prover*: `which agda julia idris2 coqc lean lake` returned nothing in
  this container. Every "proved" below is therefore "proof file read + receipt
  recorded in the repo", never "rechecked by this pass".
* **IMPLEMENTED-UNPROVED** = code or a proof-shaped file exists but is outside
  the checked closure, or is executable code with tests only.
* **STATED** = spec/doc only. **ASPIRATIONAL** = roadmap.
* The one tool I did run: `sh EchoTypes.jl/scripts/check-agda-citations.sh verify
  /home/user/estate/hyperpolymath/echo-types` -> `PASS: 62 cited Agda names match
  the fixture and are declared in echo-types`, exit 0.
* The "engineering pain" column is **my inference** unless a consumer is named
  in the repo. None of these theories is wired into git, CI, merge tooling or an
  LLM harness today (not found). Named real consumers found in the sources:
  squeakwell (`EchoPartialSection`, `EchoFibreIntersection`), verisimdb
  `formal/Recovery.v`/`Octad.v`, affinescript db-theory (`EchoAggregation`,
  `EchoTransaction`, `EchoSelectiveProjection`), 007 (`EchoResidueCell`,
  `EchoReversibilityBridge`), RapidNJ (`epistemic-types` Applications),
  absolute-zero (`EchoCNO*`), typed-wasm/resource-algebra (`occupancy-types`).

Repo facts (`/home/user/estate/.stats.tsv`, commits / workflow files):
echo-types 599/13, EchoTypes.jl 48/7, echobox 53/8, residual-evidence-types 39/5,
ResidualEvidenceTypes.jl 21/39, epistemic-types 57/8, EpistemicTypes.jl 68/38,
secret-types 48/40, occupancy-types 26/42.
`echobox` is listed `FAIL` in `.clone.log` line 433 but the directory exists with
53 commits and a clean tree; I read what is checked out.

---

## 1. echo-types (`hyperpolymath/echo-types`, head `140002f`, 2026-11-17)

Size: 152 `.agda` files under `proofs/agda` (30,451 lines incl. the Rocq/Lean
legs and the recheck record), 10 under `tutorial/`. OPTIONS census
(`grep -rh OPTIONS proofs/agda`): 150 files carry
`--safe --without-K --cubical-compatible --exact-split --no-sized-types --no-guardedness`;
1 file `--cubical --safe` (`EchoImageFactorizationPropCubical.agda`); 1 file
`--without-K` only (`EchoImageFactorizationPropPostulated.agda`, the single
quarantined `postulate` block, at line 108; `docs/proof-debt.adoc` cites `:102`,
a 6-line drift). `grep '^\s*postulate'` over `proofs/agda` finds only that one
line. No `{!`, `TERMINATING`, `believe_me`, `primTrustMe` in code.

### 1.1 What the repo itself says the object is

`docs/echo-types/what-echo-is.adoc`: "`Echo f y := Σ (x : A) , (f x ≡ y)` is the
standard dependent fibre. It is a derived Σ-type with no new type former,
judgment, or general separation from dependent pairs." The repo retracted its
own "graded comonad / universal property / conservativity / model-independence"
framing (`docs/retractions.adoc`, R-2026-05-18). `PROOF-STATUS.adoc`: "Selected
lossy-encoding examples do not separate Echo from general Σ-types, and
novelty/priority remain unresolved."

So the value to engineering is not a new type former. It is a **vocabulary and
a checked lemma library for "lossy map + what you kept"**, plus an unusually
disciplined anti-overclaim process.

### 1.2 PROOF-STATUS vs files (checked)

| Claim in `PROOF-STATUS.adoc` | What I saw |
|---|---|
| seven `--safe --without-K --cubical-compatible` roots | all seven files exist: `All`, `Smoke`, `AuditSmoke`, `characteristic/All`, `examples/All`, `experimental/echo-additive/All`, `NarrowingSmoke` |
| "main verified suite ... postulate-free"; one quarantined block | confirmed by grep (see above) |
| `EchoSearchExample` headlines `PWG-2ii`, Rocq + Lean legs, no axioms | `proofs/rocq/EchoSearchExample.v` (206 lines, ends with six `Print Assumptions`), `proofs/lean4/EchoSearchExample.lean` (177 lines, six `#print axioms`), `proofs/RECHECK-EchoSearchExample.adoc` (ledger: Coq 8.18.0, Lean 4.30.0, reconciled "by owner acceptance ... without a separate line-by-line review") |
| census "722 headline pins ... PWG-2ii 5, ungraded 717" (2026-11-09) | my rough regex count of names in `Smoke.agda` `using (...)` clauses on the current head is 761; not reconciled (regex is approximate; Smoke may have grown) |
| CI jobs: check, cold-check, experimental, narrowing, cubical, rocq-recheck, lean-recheck | all seven job keys present in `.github/workflows/agda.yml` |
| latest cold check (2026-11-16) | "No log was archived for this run. It is a local run, not a GitHub Actions receipt." (their words) |
| `EchoFidelity` unwired | confirmed: not imported by `All`, `Smoke` or `AuditSmoke`; `docs/foundation.adoc` lists it among 17 files outside the workflow roots |

### 1.3 Constructs (file, statement, status, engineering reach)

All paths relative to `echo-types/proofs/agda/` unless noted. "PROVED" here means
in the `All.agda` or `AuditSmoke.agda` closure and `ungraded` under PROOF-POLICY §8
unless stated (their own census).

**E1. `Echo`, `echo-intro`, `MapOver`, `map-over`, `map-over-id`, `map-over-comp`, `map-square`** (`Echo.agda`). The fibre and its functorial action over a fixed base and along a commuting square. PROVED.
*Reach:* typed provenance for any generated artefact: "this lockfile / rendered template / status table is `f source`, here is the source". `map-square` is the shape of "regenerate after upstream change": a commuting square carries the old witness to a witness of the new output. Template drift = an instance file with an empty fibre under the render map.

**E2. `Echo-comp-iso` and pentagon `Echo-comp-pent-Σ-assoc`** (`Echo.agda`): `Echo (g ∘ f) y ↔ Σ B (λ b → Echo f b × g b ≡ y)`, unconditional, round-trips by `refl`. PROVED.
*Reach:* provenance through multi-stage pipelines accumulates stage by stage and re-associates without loss. This is the law a multi-step generator chain (template -> repo -> workflow -> run) needs so that per-stage receipts compose.

**E3. `cancel-iso`** (`Echo.agda`): `Echo (g ∘ f) y ↔ Echo f (s y)` given `s-left`, `s-right` **and both triangle identities**. PROVED.
*Reach:* exact premise list for a "lossless migration" claim (YAML -> KYAML, JSON -> JCS, A2ML -> deed): a two-sided inverse with coherence. A one-sided converter is not enough; the comment says "a bare section on g is not enough".

**E4. `A↔ΣEcho`, `encode`/`decode`** (`EchoTotalCompletion.agda`), `ofs-witness`, `projection-fibre-iso` (`EchoOrthogonalFactorizationSystem.agda`), `reversibility-via-totality` (`EchoReversibilityBridge.agda`). Any `f` factors as an equivalence followed by a projection; "irreversible computation + echo = reversible representation". PROVED (strict uniqueness/lifting only funext-qualified: `EchoOFSUnivF5*`, "existence of a comparison iso, not its uniqueness").
*Reach:* design rule for safe automation: every destructive op (squash, format, autofix, dependency bump) ships its residue so that `decode` exists. Undo for bot actions.

**E5. `no-section-of-collapsing-map`** (`EchoNoSectionGeneric.agda`): for any `lower : A → R` with `e₁ ≢ e₂` and `lower e₁ ≡ lower e₂`, `¬ Σ (R → A) (λ raise → ∀ e → raise (lower e) ≡ e)`. Three-line proof. PROVED. Caveat stated in `what-echo-is.adoc`: this negates a *left inverse*, not a categorical section.
*Reach:* the formal core of "you cannot reconstruct what was thrown away". An LLM asked to restore a file from a summary, re-derive a deleted licence header, or rebuild structure from a status line is being asked for a `raise` that provably does not exist; what it returns is a *representative choice*, which the type distinguishes from recovery. Directly addresses fabricated structure and context-compaction drift.

**E6. `EchoR`, `echo-to-residue`, `strict-weakening-collapse`** (`EchoResidue.agda`); `ResidueForm` + instances (`EchoResidueTaxonomy.agda`). A certified residue `Σ C (λ r → Cert r y)` and a sound lowering from the full echo. PROVED.
*Reach:* the type of a *receipt*: what a CI run, a merge, or an agent step must keep, with a certificate tying it to the visible result.

**E7. `ExactRecovery`, `recovery-separates`, `recovery-forbids-residue-collision`, `finite-fibre-bound : ... n ≤ k`, `no-one-symbol-for-two`** (`EchoFiniteResidue.agda`, in `AuditSmoke`). Exact recovery forces the residue to separate sources in a fibre; a fibre with `n` distinct sources needs a residue alphabet of at least `n`. PROVED ("standard finite pigeonhole argument, not a bit/entropy/physical-cost bound", `docs/audit/2026-11-06-research-cycle.adoc`).
*Reach:* lower bound on metadata. If N distinct source states collapse to one artefact, a receipt with fewer than N values cannot support exact rollback. Tells you when a commit trailer / lock hash / cache key is too small to be a key.

**E8. `DecorationStructure`** (`EchoDecorationStructure.agda`: order, refl, trans, `≤-prop`, join, join laws; instances graded/linear/access/choreo) and the per-decoration `degrade`, `degrade-comp`, `degrade-compose`, `degrade-via-join` (`EchoGraded.agda`, `EchoLinear.agda`, `EchoAccess.agda`, `EchoChoreo.agda`); abstract `Echo.Index.ThinPoset`, `Echo.Modality.Interface.EchoModality`. A thin-preorder-indexed family with unique, composable degradation. PROVED. Repo caveat: "it is a preorder-indexed diagram ... no reflector"; `EchoSeparating.sep-degrade-compose-fails` shows the composition law fails when the order is not propositional.
*Reach:* this is exactly the algebra of *status ladders*: PROVED > STATED > ASPIRATIONAL, PWG-1..3, maturity levels, trust tiers. Degrading is always available and path-independent; upgrading has no map. An overclaim is an attempted `raise`. Two status sources merge by `join` (take the weaker). Could replace hand-edited status fields with a derived, monotone one.

**E9. `LEcho`, `weaken`, `no-section-weaken`, `affine-all-equal`** (`EchoLinear.agda`); `_≡m_`, `mode-equality-strictly-finer-at-linear` (`EchoObservationalEquivalence.agda`); `affine-consumer-cannot-distinguish` (`EchoAbstractionBarrier.agda`). Two modes of the same data with different observable equality. PROVED; repo caveat: "There is no enforced barrier: `Echo` is a transparent Σ."
*Reach:* names the difference between "two things equal as far as this reviewer/checker can see" and "equal". Checker-blindness of LLM output review.

**E10. `ResidueCell` (`holding`/`spent`), `takeForReverse`, `consume`, `once-only`** (`EchoResidueCell.agda`); `Trace`, `trace-at-most-one`, `no-two-reversal-trace`, `spent-trace-zero` (`EchoResidueProtocol.agda`). An armed undo can be replayed at most once along a single state trajectory. PROVED for the Agda model. Repo caveat: "ordinary Agda values remain duplicable ... No refinement theorem connecting these Agda models to the Rust or Idris runtimes has been established."
*Reach:* exactly-once revert / rollback / retry. A CI auto-revert or a bot "undo" that fires twice is the classic flake amplifier; the trace system is the spec a real implementation must refine (needs linear types: the Idris `(1 e : Echo f y)` version is in 007, not in this cluster).

**E11. `PartialSection`, `_⊑_`, `merge resolve`, `merge-comm`/`merge-assoc`/`merge-idem` (each conditional on the same law of `resolve`), `fill`, `fill-guarded`, `fill-inflationary`, `fill-not-monotone`, `restrict`, `restrict-fibre-agree`, `restrict-blind`** (`EchoPartialSection.agda`, in `All`). Partial records over an index set, their information order, a resolver-parametric merge, a guarded fill, and the fibre of a mask. PROVED, funext-free. Header: "The Agda source of truth for the recovery invariants of hyperpolymath/squeakwell ... rechecked in Rocq as verisimdb `formal/Recovery.v`" (that Rocq file is outside this cluster; not inspected).
*Reach, the strongest merge-conflict construct in the cluster:*
 * a three-way merge of keyed metadata (deed clauses, lockfile entries, workflow `uses:` pins, label sets) is conflict-free and order-independent **iff** the per-key resolver is commutative, associative and idempotent. The theorems are implications, "not unconditional CRDT laws", so they tell you which fields may be auto-merged and which need a human.
 * `fill-guarded`: an oracle (template sync, bot, LLM) filling gaps "never overwrites a present value". That is the invariant template propagation needs to stop clobbering per-repo edits.
 * `fill-not-monotone` is a checked counter-model: the result of gap-filling depends on what was already present, so *fill then merge ≠ merge then fill*. This is a formal reason template-drift bots produce different results depending on run order.
 * `restrict-blind`: off the observed mask nothing is constrained, i.e. a check that looks at 3 fields says nothing about the 4th.

**E12. `fibre-intersection-iso`, `forget-left-witness`, `narrow-fin-step-*`, `narrow-shrinks`** (`EchoFibreIntersection.agda`). Intersection of fibres is the fibre of the pairing; adding a constraint never changes the witness and never increases the finite count. PROVED. Repo caveat: "Nothing here claims the intersection is inhabited: observations can be jointly unsatisfiable".
*Reach:* root-cause narrowing: each additional independent signal (a second CI job, a bisect step, another log) monotonically shrinks the candidate set; and an empty intersection is the formal shape of "these two green checks contradict each other".

**E13. `Monoid`, `⊕-fold-++`, `GroupAggregator`, `aggregation-as-fold`, `no-canonical-disaggregation-of`** (`EchoAggregation.agda`). Aggregation is a monoid homomorphism over list append; there is no left inverse to an aggregate with collisions. PROVED. Scope note: "NOT full SQL GROUP-BY operational semantics"; `avg` deliberately absent ("not a monoid").
*Reach:* (a) CI sharding/matrix fan-in is sound exactly when the summary is a monoid fold (counts, max severity, set union), and unsound for averages/percentages; (b) "report a census with its denominator, never a percentage" (PROOF-POLICY §8.4) is the same theorem: a percentage has no disaggregation.

**E14. `rollback-discards-writes` / `rollback-no-recovery`** (`EchoTransaction.agda`); **`select-project-commute`, `no-column-safe-lift`** (`EchoSelectiveProjection.agda`). Rollback has no recovery map; selection commutes with projection iff the predicate factors through the projection. PROVED, with `NotProved-*` aliases for durability, isolation, runtime planner.
*Reach:* path-filtered CI and sparse checkouts: "filter then project = project then filter" holds only when the filter reads only kept columns. A `paths:` filter that depends on files outside the sparse set is the non-commuting case.

**E15. Axis-8 feasibility family: `EchoDec`, `echo-dec-compose-iso`** (`EchoDecidable.agda`); `FiberSize-fin` and its laws (`EchoFiberCount.agda`); `EchoS`, `bounded-search-is-decidable`, `echo-search-product` (`EchoSearch.agda`); `EchoC` (`EchoCost.agda`); `EchoAccess` 5-grade lattice (`EchoAccess.agda`); worked exhibit `EchoSearchExample.agda` with Rocq and Lean legs. PROVED; the five `EchoSearchExample` headlines are the only `PWG-2ii` theorems in the repo.
*Reach:* separates "a witness exists" from "a witness can be found within budget n". This is the type of a bounded CI job: `EchoS` with budget = timeout; relaxing the budget is monotone; a timeout is not a refutation. Useful for flaky-vs-failed classification.

**E16. `EchoApprox`** (`EchoApprox.agda`): `Σ A (λ x → dist (f x) y ≤ ε)`, `echo-approx-relax`, `echo-approx-compose` (additive error under non-expansive maps), Lipschitz variant. PROVED over abstract tolerance/pseudo-metric records (instances are trivial-on-`⊤`).
*Reach:* tolerance-based tests: error budgets add along a pipeline; a tolerance chosen per stage without the sum is the usual source of numerically flaky tests.

**E17. `EchoFidelity`** (`EchoFidelity.agda` + `docs/echos/FIDELITY-FIBRE-DESIGN.adoc`, `docs/echos/README.adoc`, `docs/echos/BOT-PROMPT.adoc`): `Verdict = mapped t | dropped reason`, `record Translation` with total `account : SA → Verdict TA`, `Fibre T t = Echo (account T) (mapped t)`, `dropped-not-in-fibre`, `Fabricated T t = Fibre T t → ⊥`, `same-target-same-checker-obs`, `cmp 4 5 ≡ weaker`. **IMPLEMENTED-UNPROVED**: header says "type-checks under Agda 2.6.3 ... Deliberately NOT imported from All.agda or Smoke.agda"; it is outside every CI root.
*Reach, the most direct anti-hallucination construct in the cluster:*
 * "No silent loss. `account` is total, so every source atom has a verdict."
 * "A target atom with an empty fibre has no source ... fabricated relative to this step."
 * "Two translations with the same target atoms look identical to a checker" (so a green proof check says nothing about fidelity).
 * direction check: a restatement that is *weaker* than the source is detected structurally.
 Design note is explicit about limits: "Accounting is decidable; fidelity is not"; "A trace produced by the translating process can be wrong in the same way as the translation." Their own ground-truth note: "the fibre trace described here does not exist in those tools yet" (echidna, proof-burrower).

**E18. `SourcePreserving`, `source-preserving-implies-identity`, `negation-iso-not-source-preserving`** (`EchoSourcePreserving.agda`); `pointwise-fibre-map`, `source-map-pointwise`, `pointwise-fibre-iso` (`EchoSourcePreservingComparison.agda`). `f` and `g` are pointwise equal iff there is a source-preserving fibre map; unrestricted fibre isomorphisms do not imply it. PROVED (AuditSmoke).
*Reach:* refactor / dependency-bump equivalence stated as a fibre property: "same answers on the same inputs" versus "same shape of answers". A bump that preserves counts but permutes sources is the negation example.

**E19. Measures and shadows: `OrderedCarrier`, `ResidueMeasure` (measure + monotone, "deliberately no field forcing `measure` to be injective")** (`Echo/Measure/Interface.agda`), `Echo/Measure/Composition.agda` (monoid-homomorphism measures; "Equal costs can still hide different evidence"), `entropy-shadow-blind`, `witness-distinguishes-where-entropy-cannot` (`EchoEntropy.agda`), `ll-encoding-gap` (`EchoLLEncoding.agda`), `Echo/Separation/NotResourceInstance.agda` (repo: "Conditional ... does not show every measure is lossy"). PROVED.
*Reach:* any scalar health metric (coverage %, scorecard, "N checks green") is a monotone, non-injective shadow. Formal backing for "no single scores for proofs".

**E20. Negative/limit results:** `EchoSeparating` (law fails without thinness), `EchoVariance` (`accumulate`, `no-bare-recovery`, plus `NotProved-full-min-plus-graded-monad-laws`), `EchoErasingGradedComonad`, `EchoNaturalityIndependence`, `EchoThinPreorderExample.no-antisymmetry`, `EchoTruncation.echo-not-prop`, `EchoStepNDModelF2.nd-not-graph`. PROVED. Reach is indirect: they stop over-generalisation.

**E21. `Dyadic`** (`Dyadic.agda`: `Session`, `dual-involutive`, `Compatible`, example `*-safe` lemmas) and `DyadicEchoBridge.agda`. A simplified two-party session-type core. PROVED but small ("Simplified to focus on the core dyadic session type structure").
*Reach:* caller/callee protocol clashes (reusable workflow vs caller, client vs server SDK). Thin today.

**E22. Thermodynamic cost model** (`EchoThermodynamics*.agda`): `landauer-bound`, `bennett-enumerated`, `landauer-fan-in`, `collapse-erasure-cost`. PROVED for "the defined arithmetic cost model, not measured physical energy". `bennett-reversible-arbitrary` is recorded by the repo as "*Vacuous as stated*". Low engineering reach.

**E23. CNO bridge** (`EchoCNOBridge`, `EchoCNOSemantics`, `EchoCNOPackaging`): certified null operations over absolute-zero's machine. PROVED, but inherits "absolute-zero's 2026-11-09 design audit (its `IsCNO` is degenerate)". Possible reach: idempotent formatters/CI steps as certified no-ops; not developed.

**E24. Image factorisation** (`EchoImageFactorization.agda` proof-relevant; `...Prop.agda` conditional on `TruncInterface`; `...PropCubical.agda` constructs `∥_∥` as a HIT; `...PropPostulated.agda` four postulates). Mixed: the `(epi, mono)` gate "stays `open`" in the safe profile.

**E25. Application exhibits** (all PROVED, each with honest-bound notes): `EchoProvenance`, `EchoSecurity`, `EchoProbabilisticSupport`, `EchoDifferential` (each ships `NotProved-*` `⊤`-aliases), `EchoDeniability` (repo: `partial-deniable-restricted` "Restates its hypothesis"), `EchoHaplotypeCollapsing`, `EchoExampleParser` (two parses, one result), `EchoExampleAbsInt` (sign abstraction), `EchoExampleProvenance`, `EchoIndexed`, `EchoEpistemic`, `EchoChoreo`, `EchoTropical`/`AntiEcho*`, `EchoOrdinal`, tutorials under `tutorial/` (outside CI roots per `docs/foundation.adoc`).

**E26. `EchoPullback` / `EchoPullbackUnivF4` / `EchoDependentPushforward`** (pullback cone with pointwise uniqueness; push/reindex adjunction data with triangle laws). PROVED; reach is foundational only.

### 1.4 Methods in echo-types worth copying (process constructs)

* **Retraction ledger** `docs/retractions.adoc` (R-2026-05-18 + follow-up F-2026-05-27a) and `docs/retracted/`. STATED + practised.
* **Matched-negative aliases**: `NotProved-*` definitions (e.g. `NotProved-side-channel-safe`) so `grep NotProved` lists every non-claim next to the claim. PROVED trivially (they are `⊤`), value is documentary.
* **Design audit table** in `PROOF-STATUS.adoc` ("What it actually states") downgrading 10 named results.
* **Guardrail independent of import closure** `tools/check-guardrails.sh`: scans every file for flags, deny-listed pragmas and `postulate`, "so a module that no aggregator imports cannot hide a dropped flag".
* **Mutation controls**: replacing a proof with a hole must make the right aggregate exit 42 and leave the other green (`docs/receipts/agda-mutant-*.log.gz`).
* **Smoke pins**: every headline named in a `using` clause so a rename or weakening breaks the build.
* **Receipts with sha256 and "local run, not a CI receipt" labelling.**

### 1.5 Drift found inside echo-types (evidence of the pains this programme targets)

* `CLAUDE.md` is 2,855 lines (154 KB) and is what an agent reads first. Lines 148-158 still state "Pillars A–D ALL COMPLETE ... the model-independence theorem ... `docs/echo-types/conservativity.adoc`", all retracted by R-2026-05-18; that path does not exist (`ls` fails; the file is under `docs/retracted/`). It also cites `docs/echo-types/composition.md` and `taxonomy.md`, which no longer exist (now `.adoc`), and build text for "Agda 2.6.3" while CI pins 2.7.0.1. This is a concrete LLM-drift source: the agent context contradicts the proof status file.
* `docs/proof-debt.adoc` line reference `:102` vs actual `:108`.
* Pin count 722 (doc) vs ~761 (rough recount).

---

## 2. EchoTypes.jl (head `f6e7d75`, 2026-11-14)

One 1,484-line module `src/EchoTypes.jl` and 563 lines of tests. README: "It is not a proof. Julia has no proof checker ... This package can *falsify* by counterexample but it cannot *prove*." Mirrors `fiber`, `map_over`, `comp_iso_*`, `cancel_iso_*`, `EchoR`, `no_section_of_collapsing_map`, `HasInverse`, `LEcho`, Provenance/Security/Sampling/Sensitivity records, `LLShallowEncoding`, `Monoid`/`GroupAggregator`, Landauer/Bennett bound shapes.
Status: **IMPLEMENTED-UNPROVED** (finite-domain executable shadow with tests).

**J1. Agda-citation gate** (`scripts/check-agda-citations.sh`, `test/agda-citations.txt`, workflow `.github/workflows/agda-citations.yml`, and an offline testset in `test/runtests.jl` lines 540-560). Every backticked hyphenated name in `src/` must be in the fixture and must be declared in an `.agda` file of an echo-types checkout. "The check is name-level: it proves the cited lemma exists, not that the Julia shadow agrees with it." I ran it against the current echo-types head: PASS, 62 names.
*Reach:* a cheap, general cure for hallucinated references: any doc/code that cites a theorem, file, rule id or workflow by name gets a fixture plus an existence check against the cited repo. Same shape would catch the dead paths in echo-types' own `CLAUDE.md`.

Drift: README pins echo-types `eed4250` (2026-05-28); the fixture pins `dedda75`; echo-types head is `140002f`.

## 3. echobox (head `cbe78cd`, 2026-10-01)

Phoenix UI + Julia engine skeleton. `engine/src/server.jl` (96 lines) calls `EchoTypes.fiber`, `fiber_size`, `landauer_bound` over a fixed `1:1000` domain with four hard-coded projections named "linear/affine/tropical/choreographic". README: steps 0-2 done, steps 3-5 "(Planned)". Status: **ASPIRATIONAL** application; no formal content of its own. The use of sibling type-family names as "loss grades" for integer binning is a loose analogy, not a use of those theories.

---

## 4. residual-evidence-types (head `6f94640`, 2026-11-10)

1,892 lines of Agda in `src/ResidualEvidence/` (13 modules), plus tests. Flags: 24 files `--safe --without-K --cubical-compatible`, 12 `--safe --without-K` (integration modules; reason recorded). No postulates, no holes. Hosted receipts recorded: runs 41671834379 (2026-11-03) and 42637773663 (2026-11-09, new profile). Counts verified: 9 files in `tests/reject`, 8 in `tests/integration/reject`.
Self-description: "an ordinary evidence-refined fibre ... not a new primitive type".

**R1. `Candidate`, `Case` (must be `inhabited`), `Holds` (quantifies over *all* candidates), `Identified`, `actual-world-sound`, `different-candidates-refute-identification`, `refine-claim`** (`src/ResidualEvidence/Core.agda`). PROVED.
*Reach:* the cleanest statement of **presence without identification**. A red CI run proves "some candidate cause is present"; it does not identify which. A claim is licensed only if it holds for every world consistent with the evidence; "An empty candidate set is reported as inconsistent, never as vacuous truth." LLM overclaim = asserting `Identified` when only `Holds ... Present` is available. `actual-world-sound` needs both `observe actual ≡ r` and `E actual`: a claim about the real repo needs the observation to be *of* that repo.

**R2. `Ctx W = List (W → Set)`, thinnings `_⊆_`, `weaken`, `case-weaken`, `claim-strengthen`, `no-thinning-into-empty`** (`Context.agda`). PROVED.
*Reach:* assumptions as an explicit list with a direction: a case under more assumptions restricts to fewer; a claim under fewer holds under more. `FalseWeakening` fixture: "reading a thinning backwards ... would manufacture a noise bound out of no assumption".

**R3. `compose-claims` (the composed case is "an explicit argument, never derived from the two components"), `join-split`/`split-join`, `pair-from-to`, `coarsen-claim` (one direction only)** (`Composition.agda`). PROVED.
*Reach:* **semantic merge conflicts.** Two branches each green do not give a green merge: joint consistency is a separate obligation. This is the type-level reason a merge queue must re-run on the merged tree. Coarsening: a claim proved for a coarse observation transfers to the fine one, not back (a passing smoke test says nothing the full suite did not).

**R4. `Retraction`, `retract-case`, `survives-retraction : ... (dep : Dependent c P) → support dep ⊆ Δ → Holds (retract-case ret c) P`, `Revision`, `revise`, `Refuted`, `Disagreeing`** (`Revision.agda`). PROVED. Worked example: presence survives retracting `NoNoise`; identification is lost.
*Reach:* **safe vs unsafe dependency bumps and selective CI.** Record, per claim (test, proof, compatibility statement), the named assumptions it depends on (its `support`). When an assumption is retracted or replaced (a dependency version, a toolchain pin, a template revision), the claims whose support avoids it survive without re-checking; the rest must be re-established and an inhabited new case must be supplied. That is a sound test-selection rule and a sound "this bump is safe" rule, with the unsafe direction rejected by fixture (`FalseRetraction`, `FalseEpistemicRevision`).

**R5. Certified finite checker** (`Finite/Int.agda`, `Row.agda`, `Checker.agda`, `Soundness.agda`: `admits-sound`/`complete`, `enumerate-sound`/`complete`, `entailed-sound`, `refuted-sound`, `unresolved-sound`, `inconsistent-sound`, `identified-sound`, `finite-actual-sound`) over 546 configurations. PROVED.

**R6. Explorer correspondence** (`tests/correspondence/Correspondence.agda`: `checker-matches-explorer : table ≡ expected` by `refl`; `generate-table.js` regenerates `ExplorerTable.agda` and `diff -u` requires byte equality; the script "asserts exactly 11 passing tests and none failing, because `bun test` exits 0 when it finds no tests"). PROVED/TESTED.
*Reach:* the pattern "generated view must equal data, byte for byte, and the proved checker must agree with the unproved tool by `refl`" is the general cure for generated-file and template drift; the "exit 0 with zero tests" guard is a silent-green cure.

**R7. Expected-rejection controls with checked valid prefixes** (`scripts/check.sh`, `scripts/check-siblings.sh`). Each negative fixture must fail *at its intended declaration*; "A missing module, parse error, unresolved name or unresolved hole does not count as a successful expected rejection"; two fault injections tested the gate itself. TESTED.
*Reach:* anti-silent-green and anti-flake discipline for any gate.

**R8. Sibling comparisons against pinned real sources** (`tests/integration/EchoComparison.agda`, `EpistemicComparison.agda`, `EpistemicPartialRecovery*.agda`; pins in `scripts/fetch-siblings.sh`; "one commit per pin, each with its own successful run"). PROVED at the pins.
*Reach:* per-pin receipts are the proof-world version of a safe dependency bump.

Open (their list): causal models, probabilities, "Whether composition and revision add a useful interface beyond direct use of the Echo and Epistemic foundations".

## 5. ResidualEvidenceTypes.jl (head `f9b2390`, 2026-11-18)

`src/core.jl` (172 lines), `src/signed_integer.jl` (141 lines): `Case`, `candidates`, `decide` -> `ENTAILED | REFUTED | UNRESOLVED | INCONSISTENT` with a witness each way, `identify` -> `IDENTIFIED | UNIDENTIFIED | NO_CANDIDATE`, `explorer_table`. `test/cases/zz_correspondence.jl` parses a copy of `ExplorerTable.agda` pinned by SHA-256 and commit and checks row-for-row agreement. Status: **IMPLEMENTED-UNPROVED** (tests + pinned fixture).
*Reach:* a four-valued verdict type for any automated check or agent answer; "INCONSISTENT" and "UNRESOLVED" are first-class instead of being collapsed into pass/fail.
Note: 21 commits, 39 workflow files; `verification/proofs/{agda,coq,lean4,idris2}` are RSR template boilerplate (see §10).

---

## 6. epistemic-types (head `9e8be69`, 2026-11-20)

31 source modules under `src/EpistemicTypes/` (verified count), all with the full strict OPTIONS line (60 occurrences incl. tests); 24 rejection fixtures in `tests/reject` (verified count); builtins only; no postulates. `PROOF-STATUS.adoc`: 24 ledger rows, "20 are `PWG-3` ... 0 `PWG-2i`, 0 `PWG-2ii`, 0 `PWG-1`; 2 `ungraded` (K-4, `OPEN`; K-8, `ASSUMED`)"; C-1, C-2 `TESTED`. Receipt file exists: `verification/receipts/epistemic-types-proofs_praxis.deed` (source commit `bfcee6e`, run 42743187886). No Rocq or Lean leg. Their own audit note: local receipts cite logs "kept under `_build/`, which is gitignored, so those receipts cannot be retrieved from the repository".

**P1. Split modality records** (`Base.agda`): `Modality` (only `E` and `map`, "intentionally does not include return"), `LawfulModality`, `FactiveModality` (adds `reflect : E κ A → A`), `BeliefModality` ("deliberately omit reflect"), `ReturnModality`; `Access.agda` (`Preorder`, `AccessibleModality`). PROVED (L-1, PWG-3).
*Reach:* a type-level separation of "the agent holds/asserts A" from "A". An LLM answer, a status badge, a bot comment are `Belief`; nothing gives `A` from them without a `reflect` someone had to implement.

**P2. `Warrant`, `Epi`, `SoundWarrant`, `sound-epi`** (`Warrant.agda`): "There is deliberately no field `Evidence -> A` here: that would make every warrant factive." PROVED (L-2), with contradiction witnesses in `Examples.agda`.

**P3. Proof transport** (`ProofTransport.agda`, 231 lines): `Status = Data | Code | Claimed | Receipt | Proof | ProofUnder Mode`; `Mode = Public | Designated d | IssuerMediated | EnvironmentMediated | OpaqueReceipt`; `CertificateCheck` (a real `check : Payload → Bool` plus `sound`); `View holder a status c`; `proofSound`; `proofCannotSupportFalse`; **`transmit : (b : Boundary) → View (from b) a Proof c → View (to b) a Receipt c`**; `verify`/`tryUpgrade` returning `Either Gap ...` with gaps `MissingChecker | MissingEvidence | MissingContext | InvalidEvidence | OpaqueGap ...`; `designatedBindsHolder`; `opaqueNotCertifying`; `proofNeedsChecker`; `proofHasSuccessfulCheck`. PROVED (L-3, PWG-3).
*Reach:* the exact discipline the estate's doctrine asks for ("A 'verified' claim needs current receipts"): when a proof crosses a boundary (repo -> mathesis, CI -> README badge, agent A -> agent B, session -> next session) it arrives as a `Receipt`, and becomes `Proof` again only by running a checker the receiver holds. `LyingVerifier`, `ForgedAcceptance`, `ReplayedArtifact`, `ReplayedHolder` are rejection fixtures. This is the strongest anti-overclaim construct in the cluster.

**P4. Read consistency** (`ReadConsistency.agda`, 173 lines): `Store` as a write history, `version`, ancestor relation `_⊑_` ("Equal version numbers on unrelated branches are insufficient"), `ReadView s` (value must match `contents s`), `CachedRead`, `Fresh`, `Stale`, `writeStalesCache`, `writeInvalidatesFreshness`, `synchronize`, `syncRestoresFresh`, `retainUnchanged` (needs a real equality), `FactAt`, `transportFact`, `stableFact`. PROVED (L-4). Fixtures: `StaleSample`, `FakeFreshness`, `ForkedHistory`.
*Reach:* stale status documents, stale CI caches, stale agent context, and merge bases: a fact read at commit X is a fact *about X*; carrying it to HEAD needs `contents X ≡ contents HEAD` or an explicit preservation proof. "A version-only readIncrease ... is deliberately absent". `ForkedHistory` is the divergent-branch case.

**P5. Approval seal** (`Applications/ApprovalSeal.agda`, 175 lines; `docs/applications/approval-seal.adoc`): state `(anchor, artifact, localReference, broken)`, agent actions `writeArtifact | writeLocalReference`, `gate`. AS-1..AS-8: `accepted-matches-anchor`, `accepted-is-unbroken`, `run-preserves-anchor`, `accepted-trace-matches-original`, `run-keeps-broken`, `write-prevents-acceptance`, `local-reseal-irrelevant`, `initial-accepted`; positive attack exhibits `local-reseal-fools-local-gate`, `restoration-fools-endpoint-gate`; limit `replacement-root-is-accepted`. PROVED (hosted run 41708617511) + 4 mutants killed. "not a deployed gate, a hash implementation, a signature scheme".
*Reach:* models exactly the agent failure "edit the artefact and the baseline/golden/expected file so the gate passes" and "edit then restore". The cure is structural: the approval anchor is outside the agent's write set and any write latches a sticky flag. Maps onto doctrine 5 ("Squabble, don't bypass") and onto protected baselines in CI. The stated limit (whoever can replace the root wins) is the admin-override case.

**P6. Recovery family**: `EchoBridge.agda` (`Retention`, `Recovery`, `Migration`, `collisionForbidsMigration`, `BoundedEcho`, `weakenBound`), `PartialRecovery.agda` (`Separates`, `SuccessSound`, `ImageDecision`, mutual constructions), `QueryRecovery.agda` (`QueryConstant`, "Universal extraction without that evidence would decide every Set"), `ObserverSafety.agda` (decoder-relative NI ⇔ release invariance), `ResidueSufficiency.agda` (`relativeRefl/Trans`, `queryResidueLeast`, least "by definition" per their audit). PROVED (L-5, PR-1, PR-2, QR-1, OS-1, RS-1; PWG-3). Fixtures: `InventedMigration`, `ForgedResidue`, `QuerySuccessInventsSource`, `PartialSuccessProvesImage`, `ForgetfulResidueSufficient`.
*Reach:* format migrations (A2ML -> deed, TS -> AffineScript): a migration to target `T` exists only if the retained residue separates what `T` distinguishes; an `InventedMigration` is rejected. Gives a pre-flight question for any automated conversion: "what residue does the target need, and did we keep it?"

**P7. Kripke fragment** (`Kripke/Frame.agda` `T`, `T⁻¹`, `Four`, `Four⁻¹`, `Five`, `D`; `Belief.agda` non-reflexive counter-model; `Residual.agda` presence without identification as a `Box`; `Dependence.agda`; `Indexed.agda`). PROVED (K-1..K-3, K-5..K-7); K-4 (converse 5/D) OPEN; K-8 ASSUMED.

**P8. Bound-checked skip** (`Applications/RapidNJSkip.agda`, `QCriterion.agda`, `OrderedGroup.agda`, `IntegerModel.agda`, `SortedRow.agda`): skipping part of a search is *knowledge* only when a checked bound justifies it; fixture `UncheckedSkip`. PROVED (L-7).
*Reach:* CI cost. A skipped job (path filter, cache hit, "unchanged") is sound only with a checked warrant that the skipped part cannot change the verdict. This is the type of sound test selection; paired with R4 it gives the warrant's content.

**P9. Gate methods**: exact path manifests for 31 modules / 24 fixtures / 4 integration witnesses; "rejects additional `OPTIONS` pragmas"; "verifies a generated negative control: `--safe` must reject a planted postulate with Agda's expected diagnostic and exit code"; exact 23-span warning manifest ("A new, moved, or stale location fails the gate"); each fixture has an expected diagnostic regex; `ReplayedHolder` and `UnderstatedBound` were found to be failing for the wrong reason and rewritten. TESTED.

## 7. EpistemicTypes.jl (head `81cc600`, 2026-11-18)

`src/core/Epistemic.jl` (486 lines): `Standpoint`, `Warrant`, `ProjectionY`, `Receipt` (unkeyed sha256 digest over canonical JSON; "detects accidental edits, not deliberate ones"), `verify_receipt`, `encode_avec_fibre`/`parse_avec_fibre` (wire `echo:v2`), `passes_gates`, `highest_warranted_rank`, **`epi_status` -> `:Factive | :Belief | :Collapsed | :SansFibre`**, **`disambiguate_zero` -> `true_absence | undetected`**, `residual_info`, **`can_merge(manA, manB; collapse_to)` -> `OK | OK_COLLAPSE | REFUSE` with reasons**, `bulk_verify`. Tests in `test/cases/{merge,policy,receipts,status}.jl`. Status: **IMPLEMENTED-UNPROVED**; no link to the Agda `epistemic-types` beyond vocabulary (not found).
Provenance (`docs/recovered/README.adoc`): recovered from an AI chat thread never pushed to a forge; "`using Base64` was missing ... could not have loaded as written"; `b64url` "threw `MethodError` on every call"; three further wrong-verdict bugs fixed and "each pinned by a test" (e.g. `disambiguate_zero` "could never return true_absence for a real zero cell"). This is a documented specimen of LLM-written code that was never run.
*Reach:*
 * `epi_status` is a ready-made four-way status for machine claims: verified-and-warranted / evidence-but-below-threshold / gates failed / receipt unverifiable ("sans fibre").
 * `disambiguate_zero` is "zero findings ≠ absence": a scan with too little depth reports `undetected`, not clean. Applies to "0 test failures" when 0 tests ran.
 * `can_merge` is a manifest-level merge gate that refuses rather than guesses: "the rank is never inferred"; the caller must name the collapse level. Template for merge tooling over metadata.

---

## 8. secret-types (head `0bce5bd`, 2026-11-20)

1,143 lines of Agda in `src/SecretTypes/` (14 modules); Rocq leg `verification/legs/rocq/SecretTypes.v` (535 lines); Lean leg `verification/legs/lean/` (804 lines); receipt `verification/receipts/agda_praxis.deed` with `:source-commit "89302d2d..."` and six `(claim ... :pwg PWG-1 ...)` rows (verified by grep). `PROOF-STATUS.adoc`: N-1, N-2, N-3, N-7, N-8, N-9 are `PWG-1` (CI run 44224818557, each leg in a digest-pinned image; Coq 8.18.0, Lean 4.24.0, no axioms); N-4, N-5, N-6 `TESTED`/ungraded. This is the only repo in the cluster with `PWG-1` theorems.

**S1. `TINI`** (`Noninterference/Statement.agda`) and **`tini : (V : Observer 𝓛) → TINI (Observer.sees V)`** (`Noninterference/Generic.agda`, N-7): termination-insensitive noninterference for a while-language with Volpano-Smith typing over any `Lattice` record and any down-closed observer; two-point instance `Noninterference.tini` (N-1); `eval-low` (N-2); `confine` (N-3). PROVED, PWG-1.
*Reach:* secrets in CI. A typed discipline where a value labelled secret cannot influence anything a public observer sees (logs, artefacts, PR comments). Not in the fragment: "declassification, procedures, concurrency, timing". The integrity dual (untrusted PR input must not flow into privileged steps) is the same lattice read upside down; **that dual is my inference, not stated or proved in the repo.**

**S2. Minimal-laws certificate (N-6)** (`scripts/minimal-laws.sh`, `tests/minimal-laws/`): the generic proof is re-checked against a record with only `⊔-upper₁`, `⊔-upper₂`, down-closure; "removing any one of them is refused". TESTED. **Countermodels (N-8)** `Countermodels.NoUpper₁/NoUpper₂/NoDownClosure/NoTrans.refutes : ¬ TINI _`. PROVED, PWG-1.
*Reach:* a method for knowing which invariants of a spec/template are load-bearing (ablation with a checked counter-model per dropped law). Antidote to template bloat.

**S3. N-9 `termination-sensitive-fails : ¬ TSNI`** (`Noninterference/OutcomeVisibility.agda`). PROVED, PWG-1. A proved refutation, recorded as such.

**S4. Rejections** `tests/reject/{ExplicitFlow,ImplicitFlow,ThirdVariable,TerminationSensitiveNI}.agda` and witnesses that the refused programs really leak (`Witness.explicit-leaks`, `implicit-leaks`). TESTED.

**S5. Flag-control fixture** `tests/flag-control/IndexedMatch.agda`: "a correct proof that only `--cubical-compatible` refuses; `scripts/check.sh` fails if it is ever accepted, so dropping the flag cannot pass the gate". Flags and Agda pin live "in exactly one place, `scripts/proof-flags.sh`". TESTED.
*Reach:* config drift in CI: a canary that fails if a strictness flag is silently dropped. Generalises to linters, `--frozen-lockfile`, `set -euo pipefail`.

**S6. Proof receipt as data** (`verification/receipts/agda_praxis.deed`, `scripts/grade-receipt.sh`, standards' `check-proof-receipt.sh` pinned by sha256): per-leg `:inputs-sha256` with an `(inputs-manifest ...)`; `(axioms ...)`; lineage states current/superseded/regressed; **one `(echo ...)` per history rewrite of a commit a receipt names** ("the source commit, its image on main, and the inputs digest of each leg, equal at both"); "the grade is the one the reader derives, never a value typed here"; negative control: "the same receipt with a wrong `:pwg` must be refused"; "`--check` fails when a leg's inputs change after the run that its current receipt names". IMPLEMENTED and CI-gated (not a theorem).
*Reach:* this is the working end-to-end cure for status overclaim and for provenance lost on squash/rebase: status is derived from receipts, receipts are bound to input digests, and a history rewrite must carry an "echo" record tying old commit to new. Note the name: the residue idea of §1 applied to git history.

**S7. Honest template-debris note**: "`verification/proofs/coq/TypeSafety.v`, `verification/proofs/lean4/ApiTypes.lean` and the other skeletons ... are RSR template boilerplate ... They prove nothing ... and their `MANIFEST` lines claiming `gated` are false: no workflow invokes `scripts/check-proofs.sh`."

Separation claim (their text): "Noninterference is a property of *two* runs. Echo grades, tropical grades and occupancy grades are accumulations over *one* run". The Echo connection ("a well-typed program's low observer has an Echo fibre that does not separate secret inputs") "is a CONJECTURE, recorded in the README, not claimed here."
Open: termination-sensitive typing, coalition observers, declassification.

---

## 9. occupancy-types (head `59b8c37`, 2026-11-22)

Agda: `src/OccupancyTypes/{Order,Timeline,Reclaim,Witness,All}.agda` (154 lines total; file pragmas are `--safe --without-K`, `--cubical-compatible` is added on the command line by `scripts/check-agda.sh` per the status doc). Root `PROOF-STATUS.adoc` (88 lines):

**O1. High-water-mark algebra** (peak, drift, sequence = `max (peak a) (drift a + peak b)`): "PROVEN in resource-algebra (`Instances/HWM.agda`)", a sibling repo outside this cluster that I did not inspect; adopting it here is `ASSUMED` (O-2).

**O2. `cut-factor : grade (xs ++ ys) ≡ grade xs ⊗ grade ys`** (`Timeline.agda`, any resource algebra); **`reclaim-law`, `occupancy-at-cut`, `occupancy≤cost`, `no-reclaim`, `reclaimed`, `protocol-occupancy≤cost`** (`Reclaim.agda`); witness "occupancy 4, cost 7" (`Witness.agda`); rejections `tests/reject/{CostIsOccupancy,DriftIsPeak}.agda`. R-1..R-5 PROVED, "`PWG-3` at a commit whose `proofs.yml` job `agda` passed, and `ungraded` at any commit without that receipt"; Rocq and Lean legs "OPEN ... not started".
*Reach:* CI and build cost with two different readings: *cost* (sum, runner-minutes) versus *occupancy* (peak concurrent runners, peak disk/cache, peak memory). `occupancy≤cost` with equality iff nothing is released at the cut is the algebra for placing cuts (job boundaries, cache evictions, `needs:` edges) to lower peak without changing total. `cut-factor` is compositionality of pipeline grading.

**O3. `Occ : (pre, post, peak : Nat) -> Type -> Type`** (`src/occ/Occ.idr`, 109 lines) with four expected-rejection files `RejectDoubleFree`, `RejectLeak`, `RejectOverCapacity`, `RejectUseAfterFree`. Header: "Locally checked with Idris 2 v0.7.0 ... The hosted workflow remains advisory until its first green CI run." Status: **IMPLEMENTED-UNPROVED** by a hosted receipt (local only).
*Reach:* resource-handle discipline (leak / double release / over capacity) as indexed types; analog for CI locks, concurrency groups, temp resources.

**O4. `StackcertCore.cert_sound`** (`src/stackcert/StackcertCore.lean`, 257 lines; "Zero imports (no Mathlib), no admitted lemmas"; `#print axioms` at the end): if `check` accepts a certificate, every call path's stack cost is bounded by it. "Locally checked with source-built Lean 4.15.0 on 2026-10-05 ... not a hosted CI receipt". Status: proof file exists, local receipt only.
*Reach:* the **certifying pattern**: an untrusted producer (compiler, tool, LLM) emits a certificate; a small verified checker accepts or rejects. This is the general architecture for trusting AI output without trusting the AI.

**O5. `verification/proofs/lean4/CostStateSeparation.lean`** (82 lines; `same_cost_different_hwm`, ends with `#print axioms`). Proof file exists; no receipt seen.

**O6. SessionIR v0 stepper** (`src/julia/src/*.jl`, about 800 lines; "ported 2026-10-12 and verified against the Python on all 14 pinned fixtures"). IMPLEMENTED; "the operational stepper's counted bytes shown to be bounded by the typed peak (the v0 → typed bridge)" is OPEN.

---

## 10. Cross-cutting drift and gaps observed (evidence for the programme)

1. **Two PROOF-STATUS files per repo.** `occupancy-types/PROOF-STATUS.adoc` lists R-1..R-6, while `occupancy-types/docs/status/PROOF-STATUS.adoc` (template) says "No claims yet" and "The estate census (hyperpolymath/mathesis) reads this file". `secret-types/docs/status/PROOF-STATUS.adoc` still lists template rows ABI-1..TP-2. Which file is canonical is not machine-decidable from the repo.
2. **Identical boilerplate "proofs" in four repos**: `verification/proofs/coq/TypeSafety.v`, `lean4/ApiTypes.lean`, `agda/Properties.agda` have the same md5 prefix (`5a330d09`, `cfbc70d7`, `42c4796f`) in secret-types, occupancy-types, ResidualEvidenceTypes.jl and EpistemicTypes.jl. secret-types documents that they "prove nothing".
3. **Template copies diverge**: `.machine_readable/coaptation/core/Coaptation.idr` is 114 lines in secret-types and 324 lines in occupancy-types; `docs/practice/ci-cost-reduction.adoc` differs between the two from line 217.
4. **Workflow weight vs activity**: ResidualEvidenceTypes.jl 21 commits / 39 workflow files; occupancy-types 26 / 42; secret-types 48 / 40; EpistemicTypes.jl 68 / 38, versus echo-types 599 / 13 and residual-evidence-types 39 / 5. The template-instantiated repos carry roughly 40 workflows regardless of content. `ci-cost-reduction.adoc` itself says "~10-15 workflows fire in parallel" on a push.
5. **mathesis lag** (`/home/user/mathesis/docs/atlas/claims/claims.jsonl`): only secret-types has claim rows (10 lines match), pinned at `source_commit 4ed06722...` while the repo's receipt names `89302d2d...`. echo-types' five `PWG-2ii` theorems and epistemic-types' 20 `PWG-3` rows have no claim rows there (0 matches each).
6. **Agent context contradicts proof status** (echo-types `CLAUDE.md`, §1.5).
7. **Receipts that cannot be retrieved**: epistemic-types' local receipts under gitignored `_build/`; echo-types' 2026-11-16 cold check has no archived log.
8. **No Rocq/Lean legs** for residual-evidence-types, epistemic-types, occupancy-types R-1..R-5; echo-types has legs for 5 of ~722 pins.
9. **No engineering wiring**: I found no git merge driver, CI action, linter or agent harness in these nine repos that consumes any of the theorems. `EchoFidelity`, the one module aimed at AI translation errors, is deliberately unwired.

---

## 11. Ranked shortlist: constructs with the most plausible payoff

| Pain | Best construct(s) | Status | What is missing |
|---|---|---|---|
| AI overclaim ("verified", "done") | P3 `ProofTransport` (Proof becomes Receipt across a boundary), P1/P2 Belief vs Factive, S6 receipts-as-data | PROVED (PWG-3) / implemented + CI | a harness that types agent reports as `View ... Claimed` and upgrades only via a checker |
| AI fabricated structure / hallucinated references | E17 `EchoFidelity` (`Fabricated`, total `account`), J1 citation gate, E5 no-section | unwired draft / implemented, ran PASS / PROVED | wire E17; generalise J1 to paths, rule ids, workflow names |
| Agent bypasses a gate by editing the baseline | P5 `ApprovalSeal` | PROVED + mutants | a real gate that refines it (anchor outside the write set, sticky write flag) |
| Stale context / stale status docs | P4 `ReadConsistency` (`Fresh`/`Stale`, ancestor on this history) | PROVED | bind every status line to the commit it was read at |
| Merge conflicts in structured metadata | E11 `merge resolve` laws, `fill-guarded`, `fill-not-monotone`; R3 `compose-claims`; J-side `can_merge` | PROVED / PROVED / implemented | a merge driver whose per-field resolvers are checked comm/assoc/idem |
| Semantic conflict (both branches green, merge red) | R3 (joint case must be supplied) | PROVED | none conceptually; it justifies merge-queue re-runs |
| Safe vs unsafe dependency bump | R4 `survives-retraction` (support ⊆ kept context), E18 source-preserving comparison, R8 per-pin receipts | PROVED | a `support` annotation per test/proof |
| CI cost | P8 warranted skip, R4 selective re-run, O2 occupancy vs cost, E13 monoid fan-in, E15 budgets | PROVED | mapping from workflow graph to these algebras |
| Silent green / flaky gates | R7 and P9 expected-rejection with valid prefix, S5 flag canary, E1.4 mutation controls, `disambiguate_zero` | TESTED / implemented | adoption outside the proof repos |
| Template / generated-file drift | R6 regenerate-and-diff + `refl` correspondence, E1 fibre of the render map, E11 guarded fill | PROVED/TESTED | a render map with recorded residue per repo |
| Status ladders and metric abuse | E8 thin-preorder degrade, E19 measures are lossy shadows, E13 no disaggregation | PROVED | derive status instead of typing it |
| Lossless migrations | E3 `cancel-iso` premises, P6 `Migration`/`collisionForbidsMigration` | PROVED | per-format inverse + coherence evidence |
| Exactly-once undo / retry | E10 `ResidueCell`, trace-at-most-one | PROVED (model only) | linear runtime refinement |
| Secrets in CI | S1 TINI over any lattice | PROVED, PWG-1 | a workflow language to type; integrity dual not proved |

"Missing semicolon"-class syntax failures: **not addressed** by anything in this cluster (not found). The closest items are gate hygiene (R7, P9), which make a parse error fail loudly instead of counting as an expected rejection.
