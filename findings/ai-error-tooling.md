# AI-error tooling cluster: formal constructs, proof status, engineering reach

Read-only research pass, 2026-11-24. Sixteen repos, all present locally under
`/home/user/estate/<owner>/<repo>` (none of the 48 clone failures is in this cluster).

## 0. How to read the statuses

No prover is installed in this session (`which agda coqc lean idris2 z3 tlc` found none; only
`cargo`). So nothing below was re-checked by me. The labels mean:

* **PROVED** — a proof source exists in the tree, I read it and found no `postulate`, hole,
  `sorry`, `Admitted` or `believe_me` in it, and the repo's own ledger cites a CI gate or run for
  it. It is "proof file present and coherent, receipt cited by the repo", not "I ran the kernel".
* **IMPLEMENTED-UNPROVED** — code or proof *source* exists but either has holes, has no checking
  gate, or is tests only.
* **STATED** — spec or prose only.
* **ASPIRATIONAL** — roadmap or pre-registration.

Head commits read: hvn-dehallucinator `fb30a8c` (2026-11-23), autoformal-fidelity `09c95c5`,
llm-grace `d41cf58`, nesy-solver `6318400`, echidna `14ada6d` (2026-11-22), echidnabot `7a5b8c4`,
proof-burrower `5a8934c`, arghda-core `e793355` (2026-10-01), panic-attack `7b9f145`, vexometer
`f9f5953`, session-sentinel `75dded5`, conative-gating `b81d4fd`, social-media-polygraph `b72ee3c`,
stateful-artefacts `a0c7858`, palimpsest-license `81a2315`, ai-skills `f8a2e2e`.

## 1. The one idea the strong repos share

Five repos independently carry the same construct, each in its own words:

| Repo | Name | File |
|---|---|---|
| hvn-dehallucinator | a completion claim needs an inhabited *measured* case; the record alone does not identify it | `verification/proofs/agda/Fibre.agda` |
| echidna | receipt (factive) versus warrant (non-factive); no uniform promotion | `meta-checker/src/Echidna/Receipt.agda` |
| echidnabot | a token does not imply its claim (`no-unconditional-reflection`) | `proofs/agda/ReceiptBoundary.agda` |
| proof-burrower | a stored ledger record yields a token, never the fact (`no-launder`) | `verification/proofs/agda/Burrow/{Trust,Ledger}.agda` |
| palimpsest-license | a licence-header token warrants consent only as `Epi`; levels do not transfer | `proofs/agda/Provenance/Warrant.agda` |
| autoformal-fidelity | an artefact element with no fibre in the source ("sans fibre") is invisible to the round trip | `src/Fidelity/Crossing.agda` |

Stated once: **evidence about a claim is a different type from the claim, and the only arrow
between them is an explicit, separately supplied soundness map.** Hallucinated completion,
overclaimed proof status, a "verified" flag read back from a file, a licence header read as consent,
and an autoformalisation that adds content are all the same shape: an inhabitant of the claim type
manufactured from an inhabitant of the evidence type with no soundness map. In each repo the
offending function is shown to be *uninhabited*, and each ships a `tests/reject/` fixture that the
type checker must refuse.

Note the duplication is real: echidnabot and proof-burrower each re-declare `Warrant` locally
("the pattern is copied; that library is not a dependency", `Burrow/Trust.agda` header), echidna
does a "semantic rewrite (not a mechanical port)" of epistemic-types@5422cd5, while
palimpsest-license and hvn-dehallucinator consume the sibling by pin. Four spellings of one
record is itself the drift this programme is about.

## 2. Per-repo findings

### 2.1 metadatastician/hvn-dehallucinator — the strongest artefact in the cluster

What it is (README.adoc, "The Concept"): task state kept *outside* the agent's context window
("Harvard architecture"); "done" decided by an independent verifier. The top of the README is
still unfilled RSR template text ("This file is a template... Replace this section"), and the
concept section is flagged as *reconstructed* after "a shell-escape bug" truncated the original.

The Incident (README, "The Incident (2026-08-23/24)") is the motivating datum: `state.txt` was
written `16 / 16 / 0 / COMPLETE` at 19:22:46; the first file of the migration was ported at
20:50:03; of 6,564 files stamped as ported, "BEFORE 0 / AFTER 6,564"; `attempts` was 0. Cause, in
the repo's words: "The cause was a type signature" — `updateCompleted :: Int -> IO ()` took
`remaining` from the caller and "`verify_register.sh` was never invoked by anything". "a verifier
that is not wired in is not a verifier."

Constructs:

1. **THE GUARANTEE** — "There is no code path from a command-line argument to the string
   `COMPLETE`." `engine/Engine.hs` (415 lines), `engine/verify_register.sh` (48).
   Status per `docs/status/PROOF-STATUS.adoc`: HD-G1..G5 **TESTED** (`tests/guarantee_test.sh`),
   HD-1H hardening suite 34 checks TESTED ("30 of its 34 checks fail against the root-commit
   engine"), run by `.github/workflows/engine-guarantee.yml`.
2. **Target binding** — the measured directory is bound at baseline (`init <n> <target>`); found
   as a hole on 2026-11-09 ("a caller could therefore point it at an empty directory and get a
   measured zero"). TESTED; the old behaviour is a TLA+ negative control.
3. **`Fibre.agda`** (209 lines, `--safe --without-K --cubical-compatible`, 0 postulates) — the
   engine's update as a residual-evidence case. Theorems: `asserted-not-identified`,
   `record-does-not-hold-complete`, `complete-needs-case`, `refuse-never-complete`,
   `hallucinated-complete-is-empty` / `-has-no-case`, and the Incident at literal numbers
   (`incident-not-complete`, `incident-regresses : update incident 15272 ≡ task 16 0 1 running`).
   Header: "A hallucinated completion is a claim over an empty fibre." Ledger HD-F, HD-F-R:
   **PROVEN** (I read the file; consistent). Imports `ResidualEvidence.{Prelude,Core,Revision}`
   pinned at `6f94640d…`.
4. **`EngineCore.agda`** (507 lines) — models every engine command; `guarantee`, `within-preserved`
   (budget), `bounded-preserved`, `stop-absorbs`, `verify-read-only`, `refuse-demotes`,
   `nonzero-not-complete`, plus `incident-original` showing the original engine writes COMPLETE
   from a typed 0. Ledger HD-1A **PROVEN** *in the model*; model-to-code is HD-F-E.
5. **Differential test** HD-F-E — 3,186 recorded engine traces replayed as `refl` lemmas in Agda
   and as TLC traces (`tests/difftest/`). **TESTED**, explicitly "not a proof".
6. **`Engine.tla`** (173 lines) — TLC exhaustive at MaxTotal=3, MaxRemaining=4, two negative
   controls that must be refuted. **TESTED** with bounds (PROOF-POLICY §4 exception recorded).
7. **Haruspex** (`Haruspex.agda` 538, `HaruspexExplorer.agda` 178, `HaruspexIncident.agda` 208) —
   a *total* pre-flight checker over a declared finite schema, "no model call", answering
   `Sound(certificate)` / `Epi(witness pair)` / `Empty(refutation)`. Soundness and completeness
   theorems listed in the PWG table (16 names for `Haruspex.Check`, 4 for the explorer).
   Agda **PROVEN**. Rocq (`coq/Haruspex.v`, 1,068 lines) and Lean (`lean4/Haruspex.lean`, 1,085)
   legs re-proved with no axioms; explorer theorems **PWG-2ii** (owner ruled RECONCILED
   2026-11-16), `Haruspex.Check` theorems **PWG-3** (legs BRIDGE-PENDING on owner review).
   **HD-H-R, the runtime harness, is OPEN**: "Nothing yet runs it on real prompts."
   HD-H-A (the schema's listing contains the actual reading) is **ASSUMED**.
8. **Five reject fixtures** (`tests/reject/*.agda`): `AssertedComplete`, `NonZeroComplete`,
   `TypedZeroComplete`, `SoundForEpi`, `EpiForInconsistent`. Each must fail "on the marked line".
9. **Ledger-reflects-tree gate** HD-2 — `scripts/check-proof-status.sh` (104 lines) "refuses this
   file if a row that is not OPEN names a path or a fragment that is not in the tree", with
   negative controls. **TESTED**. This is an anti-fabricated-structure check on the status doc.
10. **Stated assumptions** HD-A (the verifier counts correctly) and HD-A2 (64-bit `Int`) are
    **ASSUMED**, named, not hidden.

Check of the ledger against the tree: every Agda name I sampled from the ledger exists at the
cited file (`guarantee` line 222, `within-preserved` 420, `bounded-preserved` 444, `stop-absorbs`
347, `outputs-match` in the explorer). Template files (`coq/TypeSafety.v`, `lean4/ApiTypes.lean`,
`idris2/`) are declared "not claims about this project"; `TypeSafety.v` is byte-identical
(sha256 prefix `a23f8438112f`) to `rsr-template-repo`'s.

Still neural or unproved: the verifier's count (HD-A); the real-prompt path of Haruspex (no
harness, no schema extraction); toolchains come from Ubuntu, not Guix (five open deviations);
an agent "that can edit `state/state.txt` or the verifier directly" is out of scope
(`docs/AFFIRMATION.adoc`, which is itself marked "DRAFT — agent-authored, NOT affirmed by the
owner").

Departures met, not fixed (read-only): 123 `.a2ml` files tracked; README top half is unfilled
template.

### 2.2 hyperpolymath/autoformal-fidelity

`src/Fidelity/Crossing.agda` (101 lines, `--safe --without-K`; **not** `--cubical-compatible`,
which is weaker than PROOF-POLICY §2.1's canonical profile as quoted in CLAUDE.md).

* `Crossing S T` = `fwd : S → T`, `back : T → S`; `Fibre y = Σ S (λ s → fwd s ≡ y)`;
  `SansFibre y = ¬ Fibre y`; `Covered`, `Collapse`, `Faithful = RoundTrip × Covered`.
* Theorem 1 `roundtrip-injective`, `roundtrip-no-collapse` — **PROVED**.
* Theorem 2 `blindspot-roundtrips`, `blindspot-adds` — one computed witness that a round trip
  passes while the artefact holds a phantom. The repo's own ledger is careful: "witness, not a
  general theorem".
* Theorem 3 `faithful-back` — **PROVED**. Theorem 4 `Standpoints.source-sees-target`,
  `target-sees-source` — **PROVED**.
* `tests/reject/RoundTripIsFidelity.agda` — "the translator's fallacy" must be refused.
* `docs/pre-registration.adoc` — five next statements each with a falsifier (additions need the
  target standpoint; stage accounting is K-CUT-LOSS; verdicts are warrants; provenance by
  dependence; multiple provers). **ASPIRATIONAL**.
* "Honest limit, stated first: Semantic fidelity is not decidable in general."

`docs/status/PROOF-STATUS.adoc` says "5 of 12 tracked proofs done (42%)" — the denominator is
given, but the percentage departs from PROOF-POLICY §8.4.7 as quoted in CLAUDE.md ("never a
percentage"). The 7 remaining are template ABI/TP rows whose files "do not exist in this
repository".

### 2.3 hyperpolymath/llm-grace

Graceful degradation for several agent terminals on one machine. Not a hallucination tool; it
bounds *resource* failure. Formal content: `src/control/ladder.zig` — a four-state ladder
(`active, paused, checkpointed, terminated`) with an exhaustive test over states × events, and
the header "Finite policy kernel, not a process controller or a formal proof."
`PROOF-STATUS.adoc`: "0% proven", 7 template rows remaining; `verification/proofs/agda/Properties.agda`
is the template file (same sha256 prefix `124b48d4582f` as three sibling repos). README: "There
is no resident daemon, session startup integration, production hook, or deployable application
yet". Status: ladder **IMPLEMENTED-UNPROVED** (exhaustively tested, finite); the rest
**ASPIRATIONAL**. 35 `.a2ml` files tracked.

### 2.4 hyperpolymath/nesy-solver

A web front end ("public proof playground") for Hypatia + Echidna + VeriSim. No formal content
of its own: `src/interface/abi/Types.idr` opens "ABI Type Definitions Template... Replace
NESY_SOLVER with your project name". `server.js` (151 lines) proxies to a backend and "degrades
to a mock response with `mock: true`"; the mock prints `; z3 OK (mock)`. The UI does label it
("⚠ Backend unreachable — showing mock response."), but a mocked success string is exactly the
shape of a fabricated verdict. README says the frontend is "ReScript + Deno" while the tree has
`server.js`, `public/app.js` and a `src/web/App.affine` whose line 7 is "TODO: Complete semantic
implementation". `READINESS.adoc` claims CRG grade C "dogfooded". Status: **STATED** /
aspirational. 117 `.a2ml` files tracked.

### 2.5 hyperpolymath/echidna — largest, and the most self-critical ledger

`docs/PROOF-STATUS.adoc` (694 lines) is a policy-vocabulary view; it corrects its own earlier
claims in several places. Rows:

| Row | Obligation | Token (repo's) |
|---|---|---|
| R1 | Rust trust pipeline under Creusot/Pearlite and Verus | `open` |
| R2 | Idris 2 ABI/engineering proofs (`verification/proofs/idris2/` 10 files, `src/abi/`) | `proven` (CI receipts on `a2a8643`) |
| R3 | Lean 4 legs (5 files in `verification/proofs/lean4/`) | `open` (build passes; placement unresolved) |
| R4 | Agda meta-checker, 9 modules | `proven` *as statements about a model* |
| R5 | Rocq and Lean recheck of R4 | `open` |
| R6 | E9 proof composition (`Composition.agda`) | `argued` until a source-bound receipt |
| R7 | 0–1 confidence score and 1–5 `TrustLevel` | `tested-only`, "not an assurance claim" |
| R8 | `trust.confidence` in `echidna.prove.result/1` | `open`, "correctly": always `null` today |
| R9 | Solver-integrity soundness (`Integrity.agda`) | `proven` (digests, not bytes) |
| R10 | `ClampTrust.agda` | `proven` (model differs from Rust) |
| R11 | Receipt vs warrant (`Receipt.agda`) | `proven`, PWG-3 |
| R12 | SPARK projects | `open` |

Census in the file: "`PWG-1` 0/15, `PWG-2ii` 0/15, `PWG-2i` 0/15, `PWG-3` 10/15, ungraded 5/15."

Constructs:

1. **`Receipt.agda`** (305 lines) — two-world Kripke countermodel; gives the PROOF-POLICY §5
   tokens a semantics: `Asserts assumptions frame verdict φ w` maps `proven` to a frame receipt,
   `proven-with-postulates` to `Σ ax (assumptions ax → FrameReceipt …)`, `tested-only` to
   `TestEvidence` (a non-empty sample vector with a pass per sample), `argued` to a warrant,
   `no-claim` to `⊤`. Theorems: `receipt-factive`, `warrant-not-factive`, `no-receipt-anywhere`,
   `false-sample-rejected`, **`no-free-promotion`**, **`no-unconditional-postulate-promotion`**,
   **`no-test-promotion`**. I confirmed no real `postulate` declaration (the 13 grep hits are the
   identifier `proven-with-postulates` and prose). This is the formal statement of "report
   faithfully — no overclaim". **PROVED** (PWG-3; Rocq and Lean legs open).
   Its limit, in the file: "no runtime check or transition between those frames is implemented".
2. **`Composition.agda`** (187 lines) — `cut`, `explosion`, `compose-realised`,
   `detector-cannot-miss`, `detector-must-flag`, for an arbitrary logic given as module
   parameters. Replaces `proofs/agda/SoundnessPreservation.agda`, whose `compose-sound`
   "discharged a Bool flag with `∧` and never used its conflict hypothesis". Repo token `argued`
   (no receipt yet). "No ECHIDNA Rust code composes proofs today". I class it
   **IMPLEMENTED-UNPROVED** pending the receipt.
3. **TrustLevel 1–5 kernel** — `crates/echidna-core-creusot/src/lib.rs` (881 lines);
   `compute_trust_level`, `combine_trust`, `clamp_trust`, with Creusot contracts written as
   *doc comments*. The crate says of itself: "The annotations are **stated, not proved**.
   `creusot-contracts` is not yet a dependency... no CI run has discharged a single obligation."
   TK-4/TK-5/TK-6 are exhaustively tested over counts 0..=4. **IMPLEMENTED-UNPROVED**.
   The 2026-11-09 audit found two real defects the earlier Idris model had *proved*: "The Idris 2
   `TrustKernelMonotonicity` model, which proved the defective Level 5 rule, is retired."
4. **Axiom tracker** — `src/rust/verification/axiom_tracker.rs` (506 lines): `DangerLevel`
   `Safe < Noted < Warning < Reject`, `AxiomPolicy`. Text scanning for `sorry`, `Admitted`,
   `postulate`, etc. **IMPLEMENTED-UNPROVED**. The design review lists
   `AxiomSafety.comment-skip-sound` as a theorem that "ignores its hypothesis", and the
   `classify-*` stubs "always return `DC-Safe`".
5. **LLM-advisor trust invariant** — `src/rust/llm.rs` header: "The LLM **cannot** influence
   trust levels... The LLM optimises *which path* to take, never *what the answer is*."
   **STATED** in a doc comment; I found no proof or test cited for it in PROOF-STATUS.
6. **`echidna.prove.result/1`** — `docs/PROVE-RESULT-CONTRACT.adoc`: one JCS-canonical I-JSON
   line; `status ∈ {verified, failed, error, timeout, unknown}`; `InconsistentPremises ↦ unknown`;
   `trust.axioms` lists escape hatches found; `trust.confidence` is `null` unless receipt-backed.
   **IMPLEMENTED-UNPROVED** (a wire contract).
7. **Solver integrity** (`Integrity.agda`, R9) — proved for a model over digests;
   DEBT D9: "Solver integrity is documented as enforced and is not enforced". R1 records that
   dispatch "accepts an unverified solver in four ways".
8. **Mutation testing of specifications** (`verification/mutation.rs`), **anomaly detection**
   (`anomaly_detection.rs`: `UnusuallyHighConfidence`, `ProverDisagreement`,
   `CircularReasoning`), Bayesian / Dempster–Shafer / Pareto arbiters. All
   **IMPLEMENTED-UNPROVED**, heuristic.
9. The design review's categories are themselves a reusable taxonomy of proof overclaim:
   "Model diverges from the Rust", "No Rust counterpart", "Statements weaker than their names",
   "Gaps". Two named instances are "instances of `cong`" presented as determinism theorems.

Still neural: tactic suggestion (LLM via BoJ, Julia GNN fallback), prover ranking, confidence.
The trusted part is only the back-end prover's verdict, and R1 says the Rust path to it is not
verified. 55 `.a2ml` files tracked.

### 2.6 hyperpolymath/echidnabot

Proof-aware CI bot (Rust/Axum). Constructs:

1. **`proofs/agda/ReceiptBoundary.agda`** (47 lines, no library): `Warrant Claim` (an evidence
   type and a token), `SoundWarrant` (an explicit `sound : Evidence → Claim`),
   `receive-with-soundness`, `empty-claim-token : Warrant Empty`,
   **`no-unconditional-reflection : ((Claim : Set) → Warrant Claim → Claim) → Empty`**,
   `no-soundness-for-empty-token`. Ledger T-RECEIPT **proven**, PWG-3.
   Lean (35 lines) and Rocq (40 lines) restatements kernel-checked but BRIDGE-PENDING. The Rocq
   file's own header still says "Independent re-proof candidate, NOT checked evidence" while
   `docs/PROOF-STATUS.adoc` records it COQ-CHECKED — a small header/ledger drift.
2. Negative fixtures `proofs/lean/sorry_stub.lean`, `proofs/coq/admitted_stub.v` with positive
   twins `trivial_ok.*`.
3. Open rows that matter for AI errors: **E-PROVENANCE** — "Existing production REST conversion
   still merges axioms, recomputes confidence and drops original fields"; **E-ROUTING** —
   "Current direct client is a counterexample"; E-ADAPTER, E-RECEIPT, I-GATEWAY all `open`.
   The file states: "`ConfidenceLevel::Level3` is a runtime heuristic and is not a PWG."

README badge shows `License-MPL--2.0` with alt text "License: PMPL-1.0" (metadata drift, flag
only). 30 `.a2ml` files tracked.

### 2.7 hyperpolymath/proof-burrower

Librarian and lab notebook for proof goals (Jaccard search over lemma signatures, three
"specialist" readers, append-only JSONL ledger). Constructs:

1. **`Burrow/Trust.agda`** (203 lines): `Warrant` with deliberately "no field `Evidence → A`";
   `Soundness`, `ReceiptOn`, `receipt-is-factive`, `revalidate`, `demote` ("total and lossy"),
   **`no-upgrade : ¬ Soundness warr → ¬ ReceiptOn warr`**, and a Kripke countermodel for the
   legacy text-marker path (`no-legacy-soundness`).
2. **`Burrow/Ledger.agda`** (112 lines): `StoredClaim`, `read` (a record yields a token),
   `promote` (needs a `Soundness` witness), **`no-launder : ¬ (∀ {A} → StoredClaim A → A)`**.
   The header names the live defect it guards: "`Ledger::read_all` deserialises each line and
   leaves `extra` as an opaque JSON value, so a stored `extra.receipt` is trusted on sight."
3. Receipt-or-warrant recording of every attempt against `echidna.prove.result/1`; an
   `anti-patterns` ledger view.

`docs/status/PROOF-STATUS.adoc`: DOM 2 of 7 done (DOM-1, DOM-2; CI `proof-safety.yml`, Agda
2.7.0.1), 12 of 14 rows remaining, 7 of them template rows. Status: the two Agda modules
**PROVED** (model only; the Rust read path is not shown to refine it). 119 `.a2ml` tracked.

### 2.8 hyperpolymath/arghda-core

Rust "proof-workspace manager"; "it *never proves anything itself* — Agda does". No proofs of
its own (the 13 `.agda` files are test fixtures). Constructs, all **IMPLEMENTED-UNPROVED**:

1. **Silent-failure lint class** — "cases where Agda appears to succeed but the file is not
   actually in the verified suite". Hard-block rules: `missing-safe-pragma`, `orphan-module`
   (unreachable from any CI root; union over auto-discovered `All.agda`/`Smoke.agda` roots),
   `unjustified-postulate` (needs an adjacent `-- JUSTIFY:` comment). Warn rules: `escape-hatch`,
   `tab-mix`, `unpinned-headline`, `unused-import`.
2. **Four-state triage machine** inbox → working → proven → rejected, as file moves logged to
   `.arghda/events.jsonl`; hard-block lints forbid `working → proven`.
3. **Content-hash invalidation of `proven`** (`stale`, `invalidate`).
4. **Import-graph DAG** with a blocked list. Dogfood datum in the README: on echo-types
   (193 modules, 903 edges) multi-root discovery "narrows orphan reports from 38 to the 17
   genuine orphans".

No CI workflow in the repo references a prover; lints exist for Coq, Lean, Idris2, Isabelle
(`src/lint/*.rs`). 8 `.a2ml` tracked; the README cites `.machine_readable/6a2/STATE.a2ml` as
"the live status of record".

### 2.9 hyperpolymath/panic-attack

Multi-language static scanner (README badge: 897 tests, 51 languages, rule IDs PA001–PA029).

1. **PA021 `ProofDrift`** (`src/types.rs:491`) — flags `Admitted`, `believe_me`, `assert_total`,
   `oops`, `trustMe`, `Obj.magic` "or mirror files substituting assertions for proofs".
   **IMPLEMENTED-UNPROVED** (heuristic). Also PA025 `MutationGap`, PA026 `LicensePolicy`,
   PA023 `SupplyChain`.
2. **`src/abi/AttestationUnforgeability.idr`** (138 lines) — intent → evidence → seal chain;
   `integrity`, `authenticity`, `nonRepudiation`, `sealValid`, `sealNoCollision`, conditional on
   four hypotheses supplied as a `parameters` block ("HYPOTHESES — a `parameters` block, NOT
   `postulate`"). PROOF-NEEDS: "`PROVEN` (model), relative to the `ASSUMED` hypotheses". Scheme
   binding "is NOT modelled here".
3. **`ClassificationSoundness.idr`** (233 lines) — severity total order and monotone
   aggregation. `PROVEN` (model).
4. **`Stripping.idr`** (264 lines) — line-comment stripping is idempotent. "Re-proved
   2026-11-09. The previous proof (PR #111, issue #113) never type-checked". A proof that was
   claimed and had never compiled is a recorded overclaim incident.
5. **`GenerationPublish.tla`** (186 lines) — publish protocol with deliberate `Mutant` configs;
   "reported as TESTED with the bounds in the .cfg files, never as PROVEN".
6. `docs/ASSURANCE-AUDIT-2026-11-04.adoc`: "Idris models and conditional cryptographic premises
   do not prove that every Rust scanner path refines them"; "`just assail` no longer converts
   scanner failures into a successful 'not found' message" (a silent-green fix); doctor
   controls "reject each of three counterexamples independently".

Layer 2 (miniKanren unification soundness, taint completeness) and Layer 3.1/3.3 in
`PROOF-PROGRAMME.adoc` are **ASPIRATIONAL**.

### 2.10 hyperpolymath/vexometer

"Irritation Surface Analyser": ten metric categories in `vexometer/src/vexometer-core.ads`,
including `Epistemic_Failure` ("Confident hallucination frequency, fabricated reference rate"),
`Completion_Integrity` ("TODO comments, placeholders, ellipses, unimplemented!() stubs"),
`Scope_Fidelity`, `Strategic_Rigidity`, `Recovery_Competence`. All heuristic.

`PROOF-NEEDS.adoc` (regenerated 2026-09-01) is candid: "exactly 4 Pre/Post aspects... No
`SPARK_Mode` anywhere; the contracts are runtime-checked"; "the 1,282 Ada test-assertion
executions... are test executions, not proof obligations"; a real defect — "`Aggregate_Profile`
leaving five `Model_Profile` fields unassigned — undefined memory reaching every report".

Formal content actually present: `vext/src/abi/Types.idr` — `Chain : Nat -> Type` with
`appendIncreases : Chain n -> String -> Chain (S n)`. Of the header's three claimed proofs "only
this one is mechanized". `vext/src/abi/Layout.idr` is still `module {{PROJECT}}.ABI.Layout` and
"cannot compile as-is". No workflow runs Idris2 or gnatprove. `lazy-eliminator` (tree-sitter
detection of TODO/placeholder stubs, `#![forbid(unsafe_code)]`) and `vexometer-efficacy`
(six-verdict acceptance rule, monotone-frontier invariant, "validates both document shapes by
recomputing every derived number") are **IMPLEMENTED-UNPROVED**.
The efficacy protocol's rule that a declared target with zero baseline gives `reject_null` is a
small anti-overclaim rule worth noting. 43 `.a2ml` tracked.

### 2.11 hyperpolymath/session-sentinel

Storage-health monitor for AI tool session directories (zones Green/Yellow/Red/Purple).
`src/interface/abi/HealthState.idr` (410 lines): `HealthZone`, `ZoneThresholds` with LTE proofs,
`ValidTransition`, `degradationIncreasesSeverity`, `TransitionTrace`, `classifyWithProof`. No
`believe_me`/`postulate` hits. But no workflow runs `idris2` on it (the only two workflows that
mention a prover name are `rhodibot.yml` and `static-analysis-gate.yml`), and there is no
PROOF-STATUS file. README says the core is `src/core/*.as`; the tree has `.affine` and `.eph`
pairs. Status: **IMPLEMENTED-UNPROVED**. Not an AI-error mechanism; it limits disk damage from
agent sessions. 106 `.a2ml` tracked.

### 2.12 hyperpolymath/conative-gating

"SLM-as-Cerebellum": an LLM proposer, an adversarial small model, a deterministic Policy Oracle
(`src/oracle/src/lib.rs`, regex/glob, `#![forbid(unsafe_code)]`), and an Elixir consensus arbiter
with `@slm_weight 1.5`. The diagnosis in the README matches this estate's own experience: LLMs
"Read and acknowledge the constraint... Violate the constraint anyway".

`Src/Abi/Proofs.idr` (106 lines) is **not proved**:

* `lang_violation_implies_block` ends in `?hole_lang_violation_block`;
* `policy_completeness` is `?hole_policy_completeness`;
* `policy_composition_soundness` is `?hole_policy_composition_soundness`;
* `gate_monotonicity` holds only because `slmStage` is the identity on verdicts;
* `deterministic_oracle : gateOracle p prop = gateOracle p prop` is `Refl` — true of any term;
* `clean_allowed` covers only the empty policy.

`PROOF-NEEDS.adoc` line 7 calls the file "Formal proofs of security invariants" and line 15
admits "(Modulo complex `any` reduction holes)". `ABI-FFI-README.adoc` labels it "Formal
verification". No workflow checks it. The Idris oracle is a substring check (`isInfixOf`) while
the Rust oracle uses regex and globs, so the model is not the code. `PROTOTYPE.adoc` is honest:
"Unproven. Nothing here has been independently evaluated." Status: three headline theorems
**STATED**; the gate **IMPLEMENTED-UNPROVED**; the SLM half is neural by design. 46 `.a2ml`
tracked.

### 2.13 hyperpolymath/social-media-polygraph

No formal content. `backend/src/ml/credibility.rs` is 29 lines; `score_claim` is
`factors.iter().sum::<f64>() / factors.len() as f64`, beneath a comment
"[Implementation of the scoring heuristic]". `nlp.rs` is 35 lines. The README advertises
"Advanced NLP", "Sophisticated algorithms evaluate source reliability", React, ReScript. I found
zero tracked paths matching `test`. The only construct with a classical basis is the Elixir
`Polygraph.CRDT.ClaimStore` (195 lines) using `DeltaCrdt.AWLWWMap` — conflict-free merge of claim
state by a third-party library. Status: scoring **STATED** (README overclaims against a mean);
CRDT store **IMPLEMENTED-UNPROVED**. The README badge again pairs `MPL--2.0` with alt text
"PMPL-1.0" (flag only).

### 2.14 hyperpolymath/stateful-artefacts

"One canonical, machine-readable *state record* (identity, provenance, lifecycle phase,
verification status) that any artefact can carry." The README says the original content transfer
from reposystem "failed: only the RSR template shell arrived".

`src/interface/Abi/Record.idr` (151 lines): `Phase = Draft | Built | Released | Superseded |
Withdrawn` with `ValidPhaseStep` (one constructor per legal edge, "illegal edges
unrepresentable"), `withdrawnIsTerminal`, `supersededIsTerminal`; `Verification = Unverified |
Verified | Rejected` with `ValidVerificationSet` and **`noSetToUnverified`** ("no silent regress
to Unverified"; only an explicit `reopen` goes back). Mirrored by `src/core/record.zig`;
`verification/proofs/tlaplus/ArtefactLifecycle.tla` (99 lines). README, twice: "not yet
machine-checked by CI". Status: **IMPLEMENTED-UNPROVED**. 118 `.a2ml` tracked, and the schema
itself is `src/definitions/artefact-state-record.a2ml`.

### 2.15 hyperpolymath/palimpsest-license

**AFFIRMATION ethos: not found in this repo.** A case-insensitive search for "affirmation" over
the working tree returned no file. The AFFIRMATION machinery I did find lives elsewhere:
`/home/user/standards/.github/actions/affirmation-check/check.sh` (validates a snapshot against
`AFFIRMATION-STANDARD.adoc`: root or `docs/`, `.md` banned, template exemption),
`/home/user/standards/scripts/verify-affirmation-anchor.sh`, and per-repo
`docs/AFFIRMATION.adoc` files (e.g. hvn-dehallucinator's, with "The epistemic contract: You may
conclude... You may not conclude... Silence is not a claim" and a verifiable anchor commit).

What palimpsest-license does carry is the provenance warrant model:

* `proofs/agda/Provenance/Warrant.agda` (181 lines; strict flags plus `--exact-split`), consuming
  epistemic-types by pin `dcd46483…`. `SignatureVerify` module with `unforgeable` as a *parameter*
  ("EUF-CMA idealised... The gap between the two is part of the assumption, not something proved
  here"); `signature-sound`, `signature-sound-evidence`, `verified-signed-by`;
  **`no-signature-sound`** (the assumption cannot be dropped); `ConsentFromHeader` with
  **`no-consent-sound`** ("a licence-header token warrants consented-for-training only as Epi");
  **`no-transfer`** ("levels do not transfer"); `ToyModel.example` (non-vacuity).
* Rocq (`proofs/rocq/Warrant.v`, 130) and Lean (`proofs/lean/Warrant.lean`, 155) legs;
  `PROOF-NEEDS.adoc` records all six statements `PROVEN` with both legs `PROVEN, RECONCILED`,
  first receipts from workflow run 42623338797 (`.github/workflows/warrant.yml`). The grade is
  "never carried from one commit to the next (§8.4), so this file records the derivation, not a
  grade." On the repo's account this is the only theory development in the cluster with both
  legs reconciled for every listed theorem.
* Four reject fixtures: `ConsentFromToken`, `SignatureToConsent`, `UnverifiedSignature`,
  `AssumptionDropped`.
* Open: Rust tools `pmpl-sign`, `pmpl-verify`, `pmpl-audit` — "none yet"; signature-file format
  in Idris2 — "none yet"; Haskell validator — "tests only".

This file is SPDX `PMPL-1.0-or-later`; the repo is in the Palimpsest register, so that is
consistent with the licence policy. 23 `.a2ml` tracked.

### 2.16 metadatastician/ai-skills

"A public library of reusable agent skills... with tooling to verify each skill against its
source." The root README still carries the "*This file is a template*" admonition.

1. **Skills as data** — `skills/data/<name>/manifest.json` (I-JSON/JCS) plus one file per
   section; `skills/skills/<name>/` is generated and "must not be edited by hand".
   `tools/check.mjs` fails "if any line of the source text is absent from the output" or "if
   `skills/` differs from a fresh render". Only `seam-architect` is under this regime;
   `proof-craft` is hand-written "and is not yet covered by `tools/check.mjs`".
   Checks that need the private overlay "print NOT RUN and are not counted as passes".
   **IMPLEMENTED-UNPROVED** (a generate-and-diff drift gate).
2. **`tools/contain.mjs`** — one path-containment policy (`assertSegment`, `resolveInside`:
   single plain segment, no symlink below root). **IMPLEMENTED-UNPROVED**.
3. **proof-craft skill** — "a graded epistemology distinguishing VERIFIED, CERTIFIED, AUDITED,
   ARGUED, and SKETCHED"; "Certainty vocabulary is reserved. VERIFIED and CERTIFIED are
   machine-register verdicts only. Informal proofs top out at AUDITED." **STATED** (a prompt).
   Note this is a third status vocabulary beside PROOF-POLICY §5 and the PWG ladder.
4. **Katamorphe claim-status experiment** (`skills/experiments/2026-11-17-katamorphe-claim-status/`)
   — the only *measurement* of LLM overclaim in the cluster. Eight design components (four
   sound, four "plausible but wrong"), five instruction arms, answer key of seven claims accepted
   by `agda --safe` plus one Z3 `unsat`. From `RESULTS.md`:

   | Arm | Instructions | Verdicts | Extra structural claims | Machine-tied | Asserted only |
   |---|---|---|---|---|---|
   | A | none | 8/8 | 21 | 7 | 12 |
   | B | katamorphe as written | 8/8 | 33 | 0 | 24 |
   | C | katamorphe + labelling rule | 8/8 | 27 | 23 | 2 |
   | D | katamorphe + proof-craft | 8/8 | 45 | 29 | 6 |
   | E | proof-craft alone | 8/8 | 26 | 16 | 7 |

   The persona prompt alone (arm B) produced the most unbacked claims (24 asserted, 0 tied to a
   check); a one-line labelling rule cut asserted-only claims to 2. Limits stated in the file:
   "no repeat runs", ceiling on correctness, the arms were told Agda and Z3 were installed.
   A later re-run under the strict flags: "14 of 15 arm files pass; the failure is arm C's
   capped-addition proof, which uses axiom K" — an LLM-written proof that passed `--safe` and
   failed `--without-K`. **TESTED** (n = 1 per arm).
5. **Sealed A/B** (`2026-11-21-nextgen-accessibility-ab/`) — protocol sealed by `SEAL.sha256`
   before any case ran; decision "**null**"; a padding control flagged ("the team averaged 2
   invalid unique items and the baseline 0"); "No disabled readers took part. Nothing here is a
   finding about disabled readers." A worked example of pre-registration applied to a skill.
6. The repo's own `verification/proofs/` is the template (`Properties.agda`, `TypeSafety.v`,
   `StateMachine.tla` byte-identical to rsr-template-repo's).

## 3. Mechanisms that exist for catching or limiting AI error, by formal basis

**Kernel-checked (model level), with a CI gate cited by the repo**

* Completion only from a measured zero (hvn `Fibre`, `EngineCore`).
* Pre-flight prompt check Sound/Epi/Empty over a finite schema (hvn `Haruspex`) — checker
  proved, not deployed.
* Status tokens cannot be promoted (echidna `Receipt`).
* A token is not its claim (echidnabot `ReceiptBoundary`).
* A stored "verified" record is not a verification (proof-burrower `Ledger.no-launder`).
* A header is not consent; a signature is identity only under a named assumption
  (palimpsest `Warrant`).
* Round trip detects loss and is blind to addition (autoformal-fidelity `Crossing`).

**Tested, bounded**

* hvn guarantee/witness/hardening suites; 3,186-trace differential; TLC at small bounds.
* echidna TK-4..6 exhaustive at counts 0..=4.
* panic-attack `GenerationPublish.tla` with mutants; llm-grace ladder exhaustive.
* ai-skills katamorphe experiment (one run per arm).

**Heuristic or textual, no proof**

* Escape-hatch scanners: echidna axiom tracker, panic-attack PA021, arghda `escape-hatch` /
  `unjustified-postulate`, echidnabot fixtures. They are regex-class: my own grep for the same
  tokens over the template proof files returned seven hits per repo, all prose ("NO Admitted
  allowed"); echidna's PROOF-NEEDS audit records "21 `believe_me` grep hits are prose and
  detector strings".
* arghda orphan-module and unpinned-headline lints.
* vexometer metrics, lazy-eliminator stub detection.
* conative-gating oracle (regex) and arbiter.
* hvn `check-proof-status.sh` (ledger rows must name things that exist).

**Neural, by design**

* conative-gating SLM adversary; echidna LLM advisor and GNN; social-media-polygraph scoring;
  proof-burrower specialist "readers"; every skill in ai-skills.

## 4. What is still unproved, stated plainly

1. **Model-to-code refinement is missing everywhere.** Every kernel-checked result is about an
   Agda or Idris model. hvn ties model to code by a differential test; echidna R1 is `open`;
   proof-burrower says the Rust `read_all` still trusts `extra.receipt` on sight; panic-attack's
   audit says the models "do not prove that every Rust scanner path refines them".
2. **No Creusot or Verus run exists in this cluster.** echidna's crate has contracts as comments;
   echidnabot, proof-burrower, panic-attack and palimpsest tools list Creusot/Verus as open.
3. **Haruspex has no runtime harness** and no way to extract a schema from a real prompt.
4. **The verifier is assumed** (hvn HD-A). The guarantee "is no stronger than this measurement".
5. **Recheck legs**: only palimpsest `Warrant` (six statements) and hvn's four explorer theorems
   are recorded as reconciled in both Rocq and Lean. echidna `Receipt` is 0 of 10 beyond PWG-3.
6. **conative-gating's three headline theorems are holes.**
7. **Three status vocabularies coexist**: PROOF-POLICY §5 tokens, PWG grades, and proof-craft's
   SKETCHED..VERIFIED, plus echidna `TrustLevel` 1–5 and CRG letters. Only §5 has a semantics
   (`Receipt.agda`).
8. **Template residue is counted as proof surface** in several repos: identical
   `Properties.agda` (4 repos), `TypeSafety.v` (7 including the template), `StateMachine.tla`.
   hvn and autoformal-fidelity disclaim them; llm-grace, stateful-artefacts and ai-skills carry
   them with 0-done ledgers.

## 5. Where these constructs could remove recurring pain

| Pain | Construct that already addresses it | What is missing to make it permanent |
|---|---|---|
| LLM "done" hallucination | hvn engine + `Fibre.complete-needs-case` | a verifier per task type; refinement of `Engine.hs`; protection of the state file from the agent |
| Overclaim in status docs | echidna `Receipt.no-*-promotion`; PWG derived from receipts; hvn `check-proof-status.sh` | a single shared `Verdict` type consumed by pin, and a checker that a status row's token is derivable from a named receipt |
| "Verified" read back from a file, cache or CI artefact | proof-burrower `no-launder`, `promote` needs `Soundness`; stateful-artefacts `noSetToUnverified` | make the read path in Rust/Zig return a token type that cannot be used where a receipt is required (type-state), then prove the refinement |
| Fabricated structure (paths, lemma names, repos) | hvn ledger gate (row must name an existing path and fragment); arghda `orphan-module`; ai-skills generate-and-diff | generalise the "row names an existing artefact" gate to every status and README file |
| Silent green CI | arghda silent-failure class; hvn "watched failing" negative controls; panic-attack mutants and "three counterexamples" doctor controls; reject fixtures everywhere | make "every gate has a negative control it must refuse" a template-level contract |
| Proof escape hatches | `--safe` (the real gate); axiom tracker, PA021, arghda lints (text) | prefer kernel flags and `#print axioms`-style queries over regex; the katamorphe re-run shows `--safe` alone missed a use of K |
| Autoformalisation / translation drift (spec ↔ code, doc ↔ deed, A2ML ↔ deed) | autoformal-fidelity `Faithful = RoundTrip × Covered` | a coverage check for the target side; today only the loss half is testable by round trip |
| Licence and consent metadata drift | palimpsest `no-consent-sound`, `no-transfer` | the Rust `pmpl-*` tools are unverified; SPDX badges disagree with alt text in two READMEs here |
| Template drift | ai-skills "skills as data" (render and diff, source lines must survive) | applied to one skill only; the same regime is not applied to the RSR template residue found in this cluster |
| Prompt asks a question the context cannot settle | hvn Haruspex `Epi(pair)` | runtime harness; schema extraction |
| Agent ignores stated constraints | conative-gating oracle + arbiter | the proofs are holes; the oracle model is not the Rust oracle |
| Trust score inflation | echidna R7/R8 (`trust.confidence` null unless receipt-backed; TrustLevel "not an assurance claim") | Creusot/Verus on `compute_trust_level` |
| Concurrent agents crashing a machine | llm-grace ladder | no daemon exists yet |
| Merge conflicts on shared state | social-media-polygraph delta-CRDT store (third-party); proof-burrower append-only ledger | nothing in this cluster proves convergence |

Not addressed by anything in this cluster: trivial syntax failures, safe-versus-unsafe dependency
bumps, CI cost. (panic-attack has a `SupplyChain` category, PA023, which I did not read.)

## 6. Departures met while reading (reported, not fixed: this pass is read-only)

* `.a2ml` files tracked: hvn 123, proof-burrower 119, stateful-artefacts 118, nesy-solver 117,
  session-sentinel 106, echidna 55, conative-gating 46, vexometer 43, llm-grace 35, echidnabot 30,
  palimpsest-license 23, arghda-core 8, panic-attack 1 (ai-skills, autoformal-fidelity and
  social-media-polygraph 0).
* autoformal-fidelity's Agda is `--safe --without-K` without `--cubical-compatible`; its
  PROOF-STATUS reports "(42%)".
* conative-gating documents `Proofs.idr` as "Formal verification" while three theorems are holes.
* social-media-polygraph README claims against a 29-line mean; echidnabot and
  social-media-polygraph badges show MPL-2.0 with "PMPL-1.0" alt text (licence drift is
  flag-only).
* hvn and ai-skills READMEs still carry unfilled template sections.
* nesy-solver returns a mocked "OK" verdict when its backend is unreachable.

## 7. Limits of this pass

* No proof was re-run; statuses rest on reading sources and on each repo's cited receipts.
* I read headers and theorem signatures, not every proof body, for `EngineCore.agda`,
  `Haruspex.agda`, the Rocq/Lean legs, echidna's seven non-`Receipt` meta-checker modules,
  echidna's Idris/Lean corpora, and panic-attack's `ClassificationSoundness`/`Stripping` bodies.
* echidna has 1,556 tracked files; I read its proof ledger, `Receipt.agda`, `Composition.agda`
  header, the trust crate header, three Rust module headers and the result contract. Its Julia
  and GNN code, 113-prover backends and SPARK projects were not read.
* The sibling theory repos these depend on (residual-evidence-types, epistemic-types) are covered
  by `/home/user/estate/.findings/echo-residual.md`, not here.
