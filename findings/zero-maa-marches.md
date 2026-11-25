# Zero / MAA / marches cluster: findings

Read-only research, 2026-11-24. Clones under `/home/user/estate/hyperpolymath/<repo>`.
Every claim cites a file I opened or a command I ran. Status words:
**PROVED** = a proof source file exists, the named lemma is in it (I grepped), and a text scan finds no escape hatch;
**STATED** = spec/doc only; **ASPIRATIONAL** = roadmap/proposal;
**IMPLEMENTED-UNPROVED** = code exists, no proof.
"Could kill" columns are **my inference**, not something the repos claim, unless a path is given.

## 0. What was and was not run

- No prover is installed here: `which agda lean lake idris2 isabelle coqc coqtop rocq z3 julia` returned only `/root/.cargo/bin/cargo`. **I re-ran no proof.** PROVED means "source exists, name present, no hole by text scan"; kernel acceptance rests on the repos' own receipts, which I did not fetch.
- Run here: `cargo test --offline` in `jtv-halting-islands-ct` -> 56 tests passed (cli 12, control_language 9, data_language 22, data_totality 1, diode_negative 4, doctests 8 of which 4 `compile_fail`), 0 failed.
  **Disclosure:** my first run wrote a `target/` directory inside that repo (it is git-ignored; `git status --short` stayed empty). I deleted it and re-ran with `CARGO_TARGET_DIR` in the scratchpad. Nothing tracked was touched.
- Hole scans run here (grep, outside comments where I could tell):
  - `absolute-zero/proofs/agda/*.agda`: 0 `postulate|TERMINATING|believe_me|trustMe|sorry` (two textual hits, both prose comments).
  - `marches/Marches/*.lean`, `Marches.lean`: 0 `sorry|admit|axiom|native_decide|implemented_by`; `marches/proofs/agda`: 0 `postulate|TERMINATING`.
  - `ordinal-notation/verification/proofs/agda`: `postulate` only at `Ordinal/Buchholz/Fidelity.agda:123,131` (the quarantined file; its OPTIONS line has no `--safe`).
  - `januskey/verification/proofs` + `src/abi`: 0 `postulate|sorry|Admitted|believe_me|assert_total|axiom`.
  - `valence-shell/proofs/agda`: 0 `postulate|TERMINATING`; every `.agda` file there contains `--safe --without-K --cubical-compatible`.
  - `frayed-knot-toolkit/verification/proofs/agda`: 0 holes, but **no file has an OPTIONS pragma at all**.
  - `zerostep/VAEDataset_Splits.thy`: 0 `sorry|oops`.
- Name-existence checks run here: absolute-zero 17/17 CNO names (`run-sound` is declared with two spaces before the colon, `CNO.agda:270`); ordinal-notation 24/24 names from its PROOF-STATUS; marches 16 headline Lean names; absolute-zero archived Coq 10 names (5 filesystem, 5 bridge).
- `frayed-knot-toolkit` is listed `FAIL` in `/home/user/estate/.clone.log:375`, yet the directory exists, `git status` is clean, HEAD `c54c8c3` (2026-10-01), 50 commits, and files read normally. I report what is on disk and cannot say whether the checkout is complete relative to the remote.
- `maa-framework/absolute-zero/` (the submodule) is an **empty directory** in this clone; I did not read the pinned copy, only the pointer (`git ls-tree HEAD absolute-zero` -> `87902bb`).

Repos (HEAD, first commit, commits): absolute-zero `1b8e546` 2022-07-31 316 · zerostep `2a77ff4` 2025-11-25 237 · maa-framework `163f8f4` 2025-12-17 373 · marches `214e177` 2026-07-07 76 · jtv-halting-islands-ct `88827d6` 2026-07-04 46 · ordinal-notation `5a4c6e9` 2026-10-26 29 · invariant-path `34221f6` 2026-04-14 91 · januskey `d71bb76` 2025-12-11 342 · valence-shell `fa4d783` 2026-01-18 387 · quandledb `0fd3d31` 2026-04-19 135 · frayed-knot-toolkit `c54c8c3` 2026-05-26 50 · HackenbushGames.jl `da6816e` 2026-03-11 146 · ZeroProb.jl `9a8b6b9` 2026-03-11 143.

## 1. The cluster at a glance

| Repo | What it actually is | Formal stack on disk | Honest one-line status |
|---|---|---|---|
| absolute-zero | Two pillars: CNO (certified null *effect*) and OND (null *disclosure*) | Active: Agda 6 files 1,335 lines, Z3 1 file, Idris2 ABI. Archived: Coq 14 theories, Lean 9, Isabelle 2, Mizar 1 | 18 Agda rows `PWG-3`, OND-6 open; no Rocq/Lean leg for the active model |
| zerostep | **Not zero theory.** README title is "VAE Dataset Normalizer" (dataset splitter, Rust + Julia) | 1 Isabelle theory, 235 lines | Theory not run in any workflow; two of its theorems are vacuous or tautological (section 2.2) |
| maa-framework | Governance hub for "Mutually Assured Accountability"; in-tree Rust `aletheia` (RSR file-presence checker) | No proof files of its own; absolute-zero pinned as submodule at `87902bb` | MAA is a paradigm stated in prose; specs "pending upload" |
| marches | Region-crossing discipline as a typing judgment on traces | Lean 15 files 2,246 lines; Agda 11 modules + 7 reject fixtures | 57 theorems `PWG-2i` (Agda + reconciled Lean, Rocq open); 158 ungraded (Lean only) |
| jtv-halting-islands-ct | Two grammatically sealed sublanguages; grammar membership = termination certificate | Rust only, zero deps | "Nothing in this repository is machine-verified" (README section 5); tested |
| ordinal-notation | Brouwer ordinals, Veblen to a defined Gamma_0, Buchholz term orders, well-foundedness | Agda 77 modules, 12,663 lines | 13 of 17 claim rows `PWG-3`; order-type fidelity open; repo frozen |
| invariant-path | "Claim-path debugger"; type/trope/sortal three-layer checker | Rust extractor + doc-claim grounder; 1 Agda file 106 lines | Layers "decided, not built"; one scoped Agda lemma |
| januskey | Reversible file operations with obliteration; home of the MAA draft | Agda 4 modules 933 lines, Rocq 4, Lean 4, Idris2 ABI; 18 reject fixtures | 5 of 5 theory rows `PWG-3` (legs exist but their receipts are superseded) |
| valence-shell | Shell with reversible filesystem ops | Agda 10 modules 2,181 lines, Coq 11, Lean 14, Idris2 5, Z3 5, archived Isabelle 9 + Mizar 9 | Agda PROVEN after PR #223; Lean/Coq "target-only"; Rust tested, no Creusot/Verus |
| quandledb | Knot database + KRL resolution language | Agda 1 file 101 lines, TLA+ 2 files, Julia implementation | Dihedral quandle axioms proved; equivalence engine is a stub |
| frayed-knot-toolkit | Agda formalisation of "frayed knot" crossing resolutions | Agda 7 files 885 lines, 6 committed `.agdai` | Proof sources with no flags and no CI job |
| HackenbushGames.jl | Julia toolkit for Hackenbush (CGT) | none | Implemented, tested; PROOF-PROGRESS is a placeholder |
| ZeroProb.jl | Julia library for measure-zero events | none | Implemented, tested; no proofs |

## 2. Constructs, repo by repo

### 2.1 absolute-zero

Files: `proofs/agda/CNO.agda` (713 lines), `OND.agda` (159), `EchoBridgeScaffold.agda` (62), `EchoBridgeCNO.agda` (134), `CNOTests.agda`, `EchoBridgeCNOTests.agda`; `PROOF-STATUS.adoc` (639 lines); `docs/TWO-PILLARS.adoc`, `docs/OND-ROADMAP.adoc`; `proofs/z3/ond/OND_checks.smt2`; `proofs/residue/ct_select.residue`; `proofs/observation-models/O_all.model`.

**C1. `IsCNO` (Certified Null Operation).** PROVED (Agda, `PWG-3` per PROOF-STATUS ledger rows CNO-1..10).
`CNO.agda:364`:
```
record IsCNO (p : Program) : Set where
  field
    cno-terminates : ∀ s → Terminates p s
    cno-identity   : ∀ {s s'} → p ⊢ start s ⇓ s' → obs-eq s' s
```
A program on a pc-driven machine (big-step `_⊢_⇓_`, fuel interpreter `run`, related by `run-sound`/`run-complete`) that always stops and returns a state `obs-eq` to the start, where `obs-eq` is memory, registers and I/O **but not the program counter**. Witnesses that the class is neither empty nor everything: `nop-is-cno`, `jump-exit-is-cno`, `nop-nop-is-cno`, `absolute-zero-is-cno` (the empty program), `load-not-cno`, `jump-self-diverges`.
PROOF-STATUS "Design audit (2026-11-09)" is unusually candid: before that date `state-eq` included the pc so "`IsCNO` is a degenerate class" (Halt-only), `terminates` "Holds by construction; *not* a termination result", and `energy-dissipated _ _ _ = zero` so "every program, reversible or not, satisfies it". All three are recorded as resolved the same day.

**C2. Closed composition and its necessity.** PROVED.
`cno-composition : Closed p₁ → IsCNO p₁ → IsCNO p₂ → IsCNO (seq-comp p₁ p₂)` (`CNO.agda:539`) and the counterexample `closedness-needed : IsCNO jump2 × IsCNO jump2-load × ¬ Closed jump2 × ¬ IsCNO (seq-comp jump2 jump2-load)` (`:634`). Two no-ops whose concatenation is not a no-op, because the first one's jump lands inside the second.

**C3. Observational reversibility.** PROVED: `cno-left-inverse`. PROOF-STATUS: "Observational only; nothing thermodynamic."

**C4. `is-OND` (Observational Null Disclosure), relative to a declared observation model.** PROVED (Agda `PWG-3`, rows OND-2..5).
`OND.agda`: `is-OND O o = ∀ s1 s2 pub → O (run o s1 pub) ≡ O (run o s2 pub)`, with `O-out`, `O-time`, `O-all`.
- `OND2-skip-is-OND`: skip is OND under every model.
- `OND3-cno-ond-independent`: a null op that leaks through time, and a non-null op that is OND. Caveat in PROOF-STATUS: uses a local `is-null`, "The active Agda OND-3 is *not* anchored to `IsCNO`".
- `OND4-ct-select-is-OND-all`.
- `OND5-non-composition`: `(is-OND O-out p-op) × (is-OND O-out q-op) × ¬ (is-OND O-out (seq-op p-op q-op))`. Two safe operations whose sequence leaks.
- OND-6 (conditional composition): `open`, "no statement yet".

**C5. Declared observation model + residue register.** STATED (PROOF-STATUS token `argued`). `proofs/residue/ct_select.residue` lists seven channels "OUTSIDE O_all and hence OUTSIDE the proof" (power draw, EM, data-cache residency, branch trace, DRAM row-buffer, speculation, SMT port contention), each with a "discharge owner". "STATUS: consequent proved ...; antecedent OPEN." The file still cites the archived Coq theorem, not the Agda term (PROOF-STATUS says so).

**C6. Echo bridge.** PROVED (rows EB-1..4): `echo-from-cno-program-rel` needs no extensionality; the `≡` forms take `Extensionality zero zero` as an explicit argument, never a postulate.

**C7. Z3 bounded checks with expected-verdict annotations.** TESTED-ONLY. Every `(check-sat)` carries `; expect sat|unsat`; PROOF-STATUS records that an earlier `unsat` "checked nothing about the writer" (constants compared with themselves) and was rewritten with a mutation control.

**C8. Gate that cannot say green by skipping.** IMPLEMENTED (scripts; I did not run them). `proofs/verify-active-provers.sh`, `proofs/tests/gate-selftest.sh` (235 lines). PROOF-STATUS: "An absent prover is a *failure*, never a skip (since 2026-09-23 — before that Isabelle and Mizar printed "skipped" and the gate could say GREEN on four of six)"; self-test "27/27 cases".

**C9. Archived multi-prover tree.** PROVED-IN-ITS-DAY, not built or gated since 2026-10-10. My grep finds 182 `Theorem|Lemma|Corollary` lines across `archive/proofs/coq/*/*.v`, equal to the "182 top-level theorems" PROOF-STATUS reports (109 closed, 73 on axioms). Contains `FilesystemCNO.v` (`mkdir_rmdir_inverse`, `create_unlink_inverse`, `rename_inverse`, `transaction_cno`, `snapshot_restore_identity`: all present) and the reversibility bridge in `common/CNO.v` (`reversible_iff_exists_reverses`, `reverses_seq_computes_identity`, `cno_equiv_seq_empty_of_reverses`, `reversible_bridge_forward`, `reversible_bridge_backward_upto`: all present).
The bridge's honesty note matters downstream: "The literal biconditional `reversible p <-> exists p_inv, is_CNO (p;;p_inv) /\ is_CNO (p_inv;;p)` is **not** provable under these definitions, and is deliberately *not* asserted."
Lessons recorded there: three axioms found false as stated (`no_cloning`, `Cconj_Cexp`, `eta_equivalence`); Lean axioms that "derive `False`" (issue #125, fixed); `prob_nonneg`/`prob_normalized` deleted as unsound.

**C10. Idris2 ABI.** PROOF-STATUS token `argued`: "type-checks, proves nothing ... carries `believe_me` escape hatches". My grep: `believe_me` appears 3 times in `Layout.idr` and 7 in `Proofs/DivMod.idr` (textual count, comments included).

**C11. "Coupling dial".** Framing only. `docs/TWO-PILLARS.adoc`: "The coupling dial is *framing, not theorem* ... no individual theorem in either pillar may be justified by appeal to 'the dial'."

### 2.2 zerostep

`README.adoc` title: "VAE Dataset Normalizer". The repo name suggests zero-step theory; nothing on disk is.

**Z1. Split partition lemmas** (`VAEDataset_Splits.thy`, 235 lines, imports `Main "HOL-Library.FuncSet"`). Proof source exists, 0 `sorry`. Not run by any workflow (no `isabelle` in `.github/workflows`; only Justfile recipes that print "Isabelle not installed" when absent), and there is no `ROOT` file although the recipe is `isabelle build -d . VAEDataset_Splits`.
- `disjoint_from_function: "disjoint_splits f"`: fibres of *any* function are disjoint. True, and useful as a design trope (assign by function, get disjointness free), but it says nothing about the Rust.
- `split_partition`, `bijection_preserved`, `stratified_maintains_ratio`: genuine but they unfold their own hypotheses.
- `ratio_correctness`: concludes `|sum of ratios - 1| ≤ 0.04` from `n_total = n_train + n_test + n_val + n_cal`; the four `ratio_in_bounds` assumptions are never used and the sum is exactly 1. Tautological.
- `locale shake256 ... assumes deterministic: "hash x = hash x"`: a reflexivity assumption; it constrains nothing.
`PROOF-NEEDS.adoc` does not mention the Isabelle theory at all, while README lists "Isabelle/HOL proofs for split property verification" as a feature.

### 2.3 maa-framework (and where MAA's formal content really lives)

**M1. MAA paradigm.** STATED. `GLOSSARY.adoc`: "for any participants A and B, A can audit B *and* B can audit A. No participant holds a privileged audit position." README: "Symmetric accountability enforcement | **Novel** (paradigm definition) | Specifications (pending)". No formal object for symmetric accountability exists in this repo.

**M2. RMR / RMO / MPR (the MAA primitives).** STATED, in `januskey/draft-hyperpolymath-maa-framework-00.txt` (251 lines; marked "EXPIRED DRAFT ... Read it as a design note", corrected in place 2026-11-09).
- RMR-L (left inverse): "for every s in D_F and saved output (t, r), s F (t, r) implies F^-1(t, r) ~ s."
- RMR-R (right inverse): re-execution from the restored state gives `t' ~ t`. "No ledger row. Not proved, not tested: OPEN."
- Every statement is "an equality up to an equivalence ~ on states", with two named ones: `~tree` (same relative paths and bytes; permissions, owner, timestamps, symlink and inode identity **not** compared) and `~model` (propositional equality in the Agda model; "Nothing links that type to the filesystem mechanically").
- RMO (obliterative wipe): "It is not a certificate that the data is gone."
- MPR (Maximal Principle Reduction): "a design philosophy; no tool in this repository enforces it."
The revision note lists what the -00 text had overclaimed (Isabelle and Z3 named as tools the repo does not have; RMR "proved and unconditional"; RMO "proves the non-existence of the data"; Oblíbený toolchain "structurally guarantees" primitives though no Oblíbený source exists).

**M3. `IsReversible(op) ↔ ∃ op_inv, (op ;; op_inv) ≡ CNO ∧ (op_inv ;; op) ≡ CNO`.** STATED in `maa-framework/aletheia/README.adoc:47-53`, attributed to absolute-zero. absolute-zero's own PROOF-STATUS says this biconditional "is **not** provable under these definitions, and is deliberately *not* asserted" (only a forward direction with a two-sided inverse, and a backward direction up to `=st=`). The aletheia README has not caught up. It also still shows "Phase 1: 100% │ Phase 2-4: 70%".

**M4. Aletheia RSR checker.** IMPLEMENTED-UNPROVED. `aletheia/src/{checks,config,main,output,types}.rs`, 4,274 lines; README: "26 checks: 13 Bronze, 12 Silver, 1 Gold ... The hypatia `rsr-conformance` oracle stays normative — aletheia evaluates only the offline subset". `ComplianceLevel` with `rank`, `ComplianceReport::compliant_at`.

**M5. Submodule disposition "(e) SUBMODULE — estate-sibling"** in `docs/proof-debt.adoc`: proof-debt markers under a pinned sibling are delegated to the sibling's ledger to avoid double counting. A bookkeeping rule, STATED.

Engineering evidence in this repo (all from `docs/STATE-OF-PLAY-2026-07-29.adoc`), relevant to the programme's pain list:
- "Commit `b5322c2` (2026-06-17) dropped a brace in `aletheia/src/config.rs`; `main` did not compile *for over a month* and nothing noticed, because nothing was compiling it."
- "The 16 workflow files under `aletheia/.github/workflows/` have therefore *never executed, not once*".
- "Before #144 every one of those recipes printed `"… not configured yet"` and exited 0."
- The submodule pin `87902bb` is dated 2026-07-19; `git rev-list --count 87902bb..HEAD` in absolute-zero is 73, and upstream moved its Coq/Lean trees to `archive/` on 2026-10-10. `PROOF-NEEDS.adoc` is "Re-measured 2026-07-27 against the `absolute-zero` submodule at `87902bb7`" and cites `proofs/coq/...` paths that no longer exist upstream.

### 2.4 marches

Files: `Marches/*.lean` (15), `proofs/agda/Marches/*.agda` (10) + `All.agda`, `tests/reject-agda/` (7), `PROOF-STATUS.adoc`, `FALSIFIERS.adoc`, `LIMITATIONS.adoc`, `ROADMAP.adoc`, `docs/agda-lean-correspondence.adoc`, `docs/kcut-correspondence.adoc`, `scripts/check-correspondence.sh`.

**R1. Path algebra + strict inflation.** PROVED `PWG-2i`. `Basic.agda`: `record PathAlgebra` (Carrier, Label, `better`, `ext`, `trans`, `irrefl`); `StrictlyInflationary A = ∀ l a → better A a (ext A l a)`. Kernel: `run-worsens`, `no-return : ¬ (run A (l ∷ ls) a ≡ a)`. Sobrinho's strict monotonicity; the repo says so ("marches adds nothing at the algebra level").

**R2. Typed crossing judgment (the core idea).** PROVED `PWG-2i`. `Compose.agda`: `data Step` has exactly three constructors (`la` inside A, `lb` inside B, `cross` from A to B) and `data Trace` is the typing judgment on label words. Ill-typed moves "have NO constructor: they are unconstructible, not detected":
`no-back-cross ... → ¬ Step A B I cross (inB x) q` and `no-a-label-in-B`, both proved by the absurd pattern `()`.
Headlines: `trace-worsens` and `wt-cycles-are-empty : Trace A B I p ls p → ls ≡ []` ("No well-typed routing loop exists — by construction").

**R3. Gao–Rexford as a typing judgment.** PROVED `PWG-2i`. `gr_inflationary`, `gr_not_strict` (strictness fails exactly at `(fromCust, c)`), `valley_dies`, `gtrace_iff_valley_free`, `valley_free_iff_gwalk`, `no_valley_step`, `no_peer_reexport_up`, `no_second_peer`, `no_step_from_bot`; `gr_loop_free` is conditional on `Acyclic`, which "stays `ASSUMED`".

**R4. Negative artefacts.** PROVED `PWG-2i`. `BadGadget`: DISAGREE "both violates the discipline *and* demonstrably oscillates" (`disagree_not_inflationary`, `disagree_two_cycle`). `Freewheel.f2_discharged`: drop strictness and a non-empty well-typed returning trace exists, so the hypothesis is load-bearing.

**R5. `Discipline`, `DiscSys.compose` (reassembly).** PROVED in Lean only (ungraded: Agda `OPEN`). `Reassembly.lean`: loop-freedom proved once (`Discipline.no_loop`); "a finite acyclic DAG of disciplines is itself a discipline" (`compose`, `compose_no_loop`), composites nest (`nestedComposed`); `no_foreign_local`, `no_self_cross`. `birrefl`: "Composite preference is irreflexive EXACTLY because the DAG is acyclic".

**R6. A crossing is a cut.** PROVED in Lean only (ungraded). `Cut.lean`: `edge_crosses_past`, `path_back_crosses_no_cut`, `DiscSys.no_reentry`, `trace_cross_crosses_cut`; `composeCut` + `composeCut_trace_embed` / `composeCut_trace_reflect`: the composite restricted to a cut prefix is a discipline whose traces are exactly the composite's traces that end in the prefix.

**R7. Provenance as graded accumulation.** PROVED in Lean only (ungraded). `Provenance.lean`: `structure Grade`, `accum`, `accum_append`, `run_eq_seq_carried`, `carried_cons_ne_one`; `Interface.fibre`; exhibits `id_carries`, `zero_forgets`, `zero_fibre_distinguishes` (what a crossing carries versus forgets).

**R8. Tropical instance and adapter.** Lean only; adapter is `PROVEN-WITH-AXIOMS` (`propext`, `Quot.sound` inherited from tropical-types).

Census per PROOF-STATUS: "denominator 215 theorems ... `PWG-2i` 57 ... `ungraded` 158". My grep counts 128 explicit `theorem` lines in `Marches/*.lean`; the document itself explains the denominator includes compiler-generated equation lemmas ("`gext.eq_9` to `gext.eq_12`"). Not a contradiction, but the denominator is not "theorems a human wrote".

**Process constructs in marches (these are the reusable anti-drift tricks):**
- **Reject fixtures.** `tests/reject-agda/BackCross.agda` etc.; each has an `-- expect:` line and the receipt prints "[PASS] refused as expected: ... (!= inB x of type Pos A B)". The gate fails if a fixture starts passing *or fails for a different reason*.
- **Name-existence checker with fabricated-name control.** `scripts/check-correspondence.sh`: every Lean identifier the table cites must `#check`; every sibling identifier must exist at its pinned commit; "one fabricated Lean name and one fabricated Agda name are run through the same checks and must be refused". Header: "It checks NAMES, not meanings."
- **Falsifier table.** `FALSIFIERS.adoc` F1–F6 with statuses held / held-but-untested / open; F6 records that the falsifier "already FIRES on one proposed row" and the `Acyclic ↔ Consistent` pairing "is withdrawn (KC-3)".
- **Residual assumptions of a cross-prover reconciliation** written down (R1 Prop vs Set, R2 equality, R3 independent kernels, R4 index matching) in `docs/agda-lean-correspondence.adoc`.
- **Receipt with input digest**, echo across squash merges (PROOF-STATUS "Agda leg receipt").

### 2.5 jtv-halting-islands-ct

**J1. Grammar membership as termination certificate.** STATED + TESTED, explicitly not proved. `GRAMMAR.ebnf`: DATA is addition-only (`+ | plus | added_to | with`), comparisons, `and|or|not`; "Membership in this grammar IS the termination certificate ... (This is an informal argument, not a machine-checked proof)". README limits it: "holds *only* for a suitably restricted (decidable-recognition) grammar class".

**J2. The diode: one-way DATA → CONTROL bridge, enforced twice.** IMPLEMENTED + TESTED. (1) Grammar: "The DATA parser has no production for any control token". (2) Types: "`DataExpr` has no variant that can hold a `ControlStmt`", pinned by four `compile_fail` doctests, each "paired with an identical example that compiles once the `ControlStmt` is replaced by a `DataExpr`, so the failure is attributable to the type mismatch" (`src/lib.rs`).

**J3. Totality is not resource-boundedness.** IMPLEMENTED: `MAX_DATA_DEPTH` 1024, `MAX_DATA_NESTING` 128, `MAX_CONTROL_NESTING` 256 are parse errors, not crashes.

**J4. An overclaim that was removed.** README section 5: "An earlier revision annotated `eval_data` with the Creusot contract `ensures(true)` and described it as formally verifying totality. That postcondition is vacuous ... The annotation, the feature, and the `creusot-contracts` dependency have been removed." Also section 4: the Rust rewrite "changed DATA numbers to `i64` without saying so, and its README and grammar kept describing rationals".

### 2.6 ordinal-notation

`docs/status/PROOF-STATUS.adoc`: "Census of the 17 claim rows below: 13 `PWG-3`, 0 `PWG-2i`, 0 `PWG-2ii`, 0 `PWG-1`, 4 `ungraded`". Receipt `verification/receipts/ordinal-notation-proofs_praxis.deed` (exists), import cone 209 modules.

**O1. Well-founded orders.** PROVED `PWG-3`: `wf-<′` (Brouwer), `wf-<ᵇ` (Buchholz core, "structural, no rank"), `wf-<ᵇ²` with `rank2-mono-<ᵇ²` (sound doubled ladder), `wf-<ᵇʳᶠ²`, `wf-<ᵇʳᶠᵇ` (budgeted).
**O2. Veblen ladder and fixed-point engine.** PROVED `PWG-3`: `ε₀-ε-number`, `ω^^-infl`, `φ₁-ε-number`, `next-ε-least`, `φ₁-strict-mono`, `φ-mono₂`, `φ-infl`, `φ-cont`, `nextFix-least`, `nextFix-mono-in-g`, `Γ₀-prefixed`. PROOF-STATUS on ON-4: "Strict monotonicity of the binary levels is *not* proved, so "normal function" holds only in the weak sense."
**O3. Checked refutations.** PROVED `PWG-3`: `Brouwer/StrictLeftMonoRefuted.agda` ("promotes that prose claim into a CHECKED REFUTATION ... `strict-left-mono-refuted : ¬ StrictLeftMonoSum`"), `AdditivePrincipalGenericRefuted.agda`, `Buchholz/RankPowMonoRefuted.agda`. "Promoting prose to a named theorem makes the closure-decision auditable."
**O4. Open rows.** ON-7 (`φ_Γ₀(0) ≤′ Γ₀`, reduced to a closure obligation), ON-12, ON-13, ON-17 (order type ψ₀(Ω_ω)). ON-17 is carried by `Fidelity.agda` with two postulates, quarantined: MANIFEST marks it `quarantine` = "must keep failing under" `--safe`. "The 2026-11-09 audit found the earlier specification jointly inconsistent; it was restated the same day".
**O5. Quarantine manifest.** `verification/proofs/agda/MANIFEST`: per-module `gated|quarantine`. Known weakness recorded by the repo itself: "The quarantine check passes if `Fidelity.agda` fails `--safe` for any reason".

Note: README says that as of 2026-11-16 "`main` has no green run of that job" (quality.yml `startup_failure`); PROOF-STATUS says the job was moved to `agda-proofs.yml` (file exists) and "passed on `main` at `de05422`". The README is stale relative to PROOF-STATUS. The repo is frozen and carries 37 workflow files.

### 2.7 invariant-path

**I1. The invariant.** STATED (`README.adoc`): "The invariant is not 'the claim is true here and true there' — it is *'the claim is the same claim here and there.'*" and "cross-domain equality is not expressible from inside either domain."
**I2. Three-layer claim checker: type / trope / sortal.** ASPIRATIONAL: "*These layers are decided, not built.*" Layer 1 (type): form-only admissibility incl. "a forward-only ordering on evidence — 'the diode'". Layer 2 (trope): purpose-indexed warrant. Layer 3 (sortal): "Are these two presentations *the same argument*? Identity, and therefore counting."
**I3. The doubling attack** (`docs/decisions/0001-the-sortal-layer.adoc`): one derivation presented twice under distinct labels has "*identical* pass/fail profiles over *every* subdiagram" as a genuine two-witness web, "Yet corroboration weight is two versus one." Hence identity must be settled before accounting. STATED (argued in an ADR, no mechanisation).
**I4. Equivalence certificate / obstruction certificate.** STATED. "a sequence of moves, every intermediate of which passes Layers 1 and 2" versus "an invariant separating the two under the same quotient"; "the untangling witness — the refactoring whose every intermediate state remains green — is what the user wanted".
**I5. `same-cube`.** PROVED (single file, `--safe --without-K --cubical-compatible`, no stdlib): `same-cube : (a : Obs ⊤) → stmt a ≡ tail a`, `unitResultCorrespondence`, and `nonUnitResultCounterexample`. `proofs/README.adoc`: "Neither result establishes general AffineScript transformer correctness". The machine-readable `examples/same-cube/correspondence.json` carries scope, witness file digests and an `excluded_generalisation` block; a Rust test "checks that the record has not quietly acquired a stronger claim".
**I6. Same-cube by hash.** IMPLEMENTED: faces compiled to typed-wasm and compared by sha256; `greet` "genuinely splits into" two classes.
**I7. Doc-claim grounding.** IMPLEMENTED-UNPROVED. `crates/invariant-path-core/src/doc_claims.rs` (551 lines): `Predicate { FileExists, PathContainsRegex, A2mlKeyPresent, CommandCleanClaim, Unknown }`, `ground_claim`, `scan_corpus`; "panic-attack for prose".
**I8. Claim-transition classifier.** IMPLEMENTED (heuristic): `Classification { ValidPath, Overextended, Conflation, Incomplete, Abstain }`, `InvariantType` with 8 variants (`model.rs`).
**I9. "A profile does not vendor the corpus it examines"**: STATED rule; the repo records its own violation (`examples/same-cube/` vendors an AffineScript corpus).

The ADR's cross-repo survey is directly about this cluster:
- absolute-zero's CNO "refuted as a substrate": "`is_CNO` is nullity against one hard-coded projection that deliberately excludes the program counter ... the widen-the-invariant-until-your-moves-are-null circularity". It cites an axiom-free `any_jump_is_cno`; **I could not find that name anywhere in absolute-zero at HEAD** (grep, 0 hits), and the Lean files it warns about are now under `archive/`.
- "QuandleDB is a homonym": "The equivalence engine is a GROUP BY, and the certificate-shaped parts are stubs."
- `docs/DEBT.adoc` A1: "Layer 1 has no substrate anywhere ... no syntax of claims, premises, steps or evidence in any repository".

### 2.8 januskey

`docs/theory/PROOF-GRADES.adoc`: "PWG census, theory theorems of this repository (denominator 5): `PWG-1` 0 · `PWG-2ii` 0 · `PWG-2i` 0 · `PWG-3` 5 (G-1, T-1, T-2, T-3, E-1m)". Rocq and Lean legs exist on disk for G-1, T-2, T-3, E-1m and T-1, but their receipts are `superseded` because the checker script changed ("a changed checker re-earns the receipt"), "so the reader derives `PWG-3` (Agda only)".

**K1. Reversibility as a Loss grade.** PROVED (`Reversibility.agda`, 170 lines; imports resource-algebra's `Loss`). Steps carry `grade`; `traceGrade` is the sequence product.
- `all-lossless-trace`: all steps lossless ⇒ trace lossless.
- `lossless-trace-all : traceGrade ts ≡ fin 0 → AllLossless ts`: "a hidden loss cannot be papered over by composition."
- `obliterate-absorbs`, `obliterated-not-lossless`: one `inf` step makes the whole trace `inf`.
- `ReversiblePair` carries `cancels : ∀ x → unwrap (wrap x) ≡ x` as a *premise*; the file is explicit that "Both steps are *assigned* grade 𝟙 ... the kernel does not tie the two", and "It does not derive a step's grade from its code".
**K2. Single-active log.** PROVED (`SingleActiveLog.agda`, 240 lines, builtins only): invariant `Good` preserved by `begin`/`modify`/`finish`; `begin-refused-while-active`, `modify-refused-when-idle`, `finish-refused-when-idle`; `at-most-one-active : Good L → countActive (txs L) ≡ expected (activeId L)`. Abstract over "any record type with a key and an active or settled phase". That januskey's Rust refines it is row T-10, `OPEN`.
**K3. Rollback restores.** PROVED: `TransactionAtomicity.rollback-restores : Executed os x z → rollback os z ≡ x`, given each step's undo restores its execute (T-6, `ASSUMED`).
**K4. Epistemic model.** PROVED at model level (E-1m): `Knows a P x` over observation-indistinguishable worlds; `adversary-ignorant`, `obliterate-cuts-recovery`, `rotate-forgets-old`. The implementation claim E-1 is `OPEN`, and the ledger notes the Idris `adversaryCannotKnow` "holds only because `Knows` has no Adversary constructor" (vacuous truth, `src/abi/JanusKey/ABI/Types.idr:415`).
**K5. Linear handles in the Idris2 ABI.** IMPLEMENTED/type-checked: `Handle : ResourceState → Type → Type`, `obliterateLinear : (1 _ : LinearFile) → ObliterationProof`, `zeroize : (1 _ : LinearKey) → KeyId`; reject fixtures `DoubleClose.idr` ("expect: There are 2 uses of linear name h"), `ForgottenClose.idr`, `UnknownStatusIsOk.idr`.
**K6. Five-status claims ledger.** STATED + used: `PROVEN`, `TESTED`, `ASSUMED`, `DESIGNED`, `OPEN` in `PROOF-NEEDS.adoc`, one row per claim with the artefact and the command (e.g. T-9 `OPEN`: "a crash or failed save between the two leaves a change the log does not know about"; T-7 `ASSUMED`: UUID freshness "probabilistic, not checked").
**K7. Receipt-derived grades.** IMPLEMENTED (not run here): `scripts/proof-receipt.sh`; CI "regenerate the receipt and refuse any difference ... run the pinned reader, which derives every grade and refuses one the receipts do not support, with a negative control."
**K8. Probe audit.** `docs/reports/audit/proof-statement-audit-2026-10-27.adoc`: before proving, seven probe tests asserted what the code *does*; "Attestation chain 'unforgeable' | *False as written*: three gaps confirmed by test".

### 2.9 valence-shell

`PROOF-NEEDS.adoc` "Reproduction state (2026-11-09)": Agda "`PROVEN`; `PWG-3` once CI is green on the merge head" (10/10 modules after PR #223); Lean "target-only, `AGDA-PENDING`" with four libraries that do not build; Coq "133 theorems, 98 closed under the global context, 35 on standard-library axioms only"; Z3 "`ASSUMED`"; Idris2 "`PROVEN-WITH-AXIOMS`" (2 `believe_me`-backed primitive-equality axioms); Isabelle and Mizar "unchecked"; Rust "`TESTED`; Creusot/Pearlite and Verus `OPEN`" ("827 passed, 0 failed, 15 ignored").

**V1. Sequence reversibility up to pointwise equality.** PROVED (Agda). `FilesystemComposition.agda:182`: `operationSequenceReversible : AllReversibleDP ops fs → applySequence (reverseSequence ops) (applySequence ops fs) ≗ fs`. Single-op lemmas `mkdir-rmdir-reversible`, `rmdir-mkdir-reversible`, `createFile-deleteFile-reversible`, `deleteFile-createFile-reversible`; the reverse direction needs a default-permissions witness (`ReversibleDP.permsWitness`).
**V2. Filesystem equivalence as a congruence.** PROVED (Agda `FilesystemEquivalence.agda`): `fsEquivIsEquivalence`, `applyOpPreservesEquiv`, `equivCongApplyOp`, `cnoIdentityElement`, `sequenceCnoIdentity`.
**V3. Precondition non-vacuity witnesses.** PROVED (Agda `PreconditionWitnesses.agda`, 206 lines; Lean twin). "If `Pre` is uninhabited the theorem says nothing." Added after the audit found, in Lean, "`RmdirPrecondition` was uninhabited: `isEmptyDir` quantified over ancestors ... Every Lean theorem with that hypothesis was vacuous" (`docs/audits/2026-11-09-proof-ground-truth.adoc`).
**V4. RMO model.** PROVED (Agda `RMOOperations.agda`): `obliterate-leaves-no-logical-trace`, `obliterate-preserves-other-paths`, `overwrite-equalizes`. Logical trace only; nothing physical.
**V5. Crash and path lemmas.** Lean only, target-only evidence: `crash_atomic_within_op_mkdir`, `crash_state_no_third_value` (`CrashConsistency.lean`), `path_traversal_containment` (`PathTraversal.lean`). 0 `sorry` in `proofs/lean4`.
**V6. Model oracle.** IMPLEMENTED: `proofs/lean4/ModelOracle.lean` (`applyOp`, `probe`, `main`) — an executable model the Rust can be compared against.
**V7. The route plan's own trope list** (`docs/plans/VSH-ROUTE-PLAN-2026-11-04.adoc` section 10, ASPIRATIONAL): event sourcing ("One append-only log, with state as a fold"), transparency-log Merkle tree, "Affine types for undo payloads ... a non-`Clone` `UndoToken`", "Loss-graded resource algebra", "Refinement with a runtime-discharged abstraction hypothesis", "*Non-vacuity as a mandatory pattern.* ... This turns a whole defect class into build failures", choreographic `two-thread-diamond`, noninterference "Combined with absolute-zero's `OND5-composition-leaks`", and "Grammar membership as a termination certificate (jtv-halting-islands-ct pattern)".

`PROOF-NEEDS.adoc` stacks three dated "state" blocks (2026-11-09, 2026-11-01 "superseded", 2026-06-02 "Current State") whose claims conflict if read without dates: the oldest still says "6 closed-core" proof systems and "~478" named theorems; the newest audit said that at `2d798b8` "0 of 9 Agda modules check under §2.1".

### 2.10 quandledb

**Q1. Dihedral quandle axioms.** PROVED (`verification/proofs/agda/DihedralQuandle.agda`, 101 lines, strict flags): `idempotent`, `self-distrib`, `right-involutive`, `right-injective`, `right-surjective`.
**Q2. Merge-order confluence, model-checked.** `verification/proofs/tlaplus/EGraphConfluence.tla`: "TLC explores EVERY interleaving of merge order; the property `Confluent` asserts every terminal partition equals the order-independent target `Saturated`". Bounded model check, not a proof; the workflow `krl-verification.yml` says it runs TLC (not run here). The engine it models does not exist in code (invariant-path ADR: zero hits for egraph/egglog; I did not re-run that search).
**Q3. Confidence lattice.** IMPLEMENTED: `server/krl/Ast.jl:68-73` `ConfExact | ConfSufficient | ConfNecessary | ConfHeuristic`.
**Q4. Assurance boundary.** IMPLEMENTED behaviour per README: "Requests for exact, sufficient or necessary assurance fail until the required evidence checker exists. An absent target is unresolved, not unequal." "`find_path` ... does not produce a checked Reidemeister path."
**Q5. Obligations M1–M4, S1–S3** (`PROOF-NEEDS.adoc`): Reidemeister invariance "property-tested for R1 and R2 ... R3: not yet covered"; ABI layout agreement "declared, not proved".
**Q6. AFFIRMATION file.** `AFFIRMATION.adoc`: "the No-Bullshit file: what we affirm was true and checkable at this moment"; three tenses (README future, EXPLAINME descriptive, AFFIRMATION "a frozen instant, falsifiable"); states its own caveats ("`julia` is not present").

### 2.11 frayed-knot-toolkit

**F1. Crossing resolution lemmas.** Proof sources exist, 0 holes, but no OPTIONS pragma in any file, no `agda` job in `.github/workflows`, and six compiled `.agdai` files are committed. `FrayedKnot.agda`: `fray-is-binary`, `positive-A-is-split`, `negative-B-is-split`, `split-count-equals-preserve-count`, `diagram-balance`. `FrayedKnotExamples.agda`: `profiles-differ` over "explicit toy signatures". `FrayedKnotUniformity.agda`: `Uniform` / `NonUniform`. `ChoreographicFrayedKnot.agda`: `Distinct`, `project-over`, `project-under`.
`Properties.agda` is the unmodified RSR template ("Agda Proof Template ... Replace with your project's domain-specific proofs").
The repo has 92 `.a2ml` files and 100 `.adoc`.

### 2.12 HackenbushGames.jl

**H1.** IMPLEMENTED-UNPROVED (`src/HackenbushGames.jl`, 403 lines): `mex`, `nim_sum`, `green_grundy`, `stalk_value` (dyadic values), `simplest_dyadic_between`, `game_sum`, `canonical_game`, `simplify_game`. Classical Sprague–Grundy / surreal-number machinery, no novel construct.
README badge says "Completion-100%"; `PROOF-PROGRESS.adoc` says "Status: PLACEHOLDER ... Author | Mistral Vibe". `REQUIRES_INITIALISATION.adoc`: "This repository is not finished being set up." Twelve accelerator extension modules (`ext/HackenbushGamesQPUExt.jl` "Grover search for optimal moves" etc.) sit beside a 403-line core.

### 2.13 ZeroProb.jl

**P1.** IMPLEMENTED-UNPROVED (3,181 lines in `src/`): `ZeroProbEvent` hierarchy, `AlmostSureEvent` vs `SureEvent` (`types.jl:120,133`), `density_ratio`, `hausdorff_measure`, `epsilon_neighborhood_prob`, `radon_nikodym_derivative`, `almost_surely`, `measure_zero_test`, `handles_zero_prob_event(model, event)`; paradox demonstrations (Borel–Kolmogorov, Vitali, Banach–Tarski as narrative functions). Numerical, not formal.
`PROOF-NEEDS.adoc`: "Template ABI removed – was creating false impression of formal verification." Badge "Completion-95%"; PROOF-PROGRESS rows are "🟡 TBC".

## 3. Cross-cutting methods found in this cluster

These recur and are, in my reading, the most transferable output of the cluster. Each exists as a working script or fixture somewhere.

| Method | Where it works today | What it defends against |
|---|---|---|
| **Reject fixture with expected message** | marches `tests/reject-agda` (7); januskey `tests/reject-{agda,idris,lean,rocq}` (7+3+4+4); jtv `compile_fail` doctests paired with a compiling twin | Vacuous negations; a gate that passes because nothing was checked |
| **Non-vacuity witness per precondition** | valence-shell `PreconditionWitnesses.agda` + Lean twin; absolute-zero `nop-is-cno`/`load-not-cno`/`jump-self-diverges` | Theorems true because the hypothesis is empty (found for real: Lean `RmdirPrecondition`; januskey `adversaryCannotKnow`; jtv `ensures(true)`; zerostep `hash x = hash x`) |
| **Checked refutation of a tempting lemma** | ordinal-notation `*Refuted.agda` (3); marches `Freewheel`, `BadGadget`; absolute-zero `closedness-needed`, `OND5-non-composition`; invariant-path `nonUnitResultCounterexample` | Re-deriving a false generalisation; "it obviously composes" |
| **Absent tool is a failure, never a skip** | absolute-zero gate + 27-case self-test; ordinal-notation MANIFEST | Silent green |
| **Quarantine that must keep failing** | ordinal-notation `Fidelity.agda` | Postulates leaking into the checked cone |
| **Receipt with input digest; grade derived by a reader** | januskey, absolute-zero, ordinal-notation `verification/receipts/*_praxis.deed`; marches by hand | Asserted "verified"; stale receipts (januskey's grade *dropped* when the checker script changed) |
| **Name-existence check with fabricated-name control** | marches `scripts/check-correspondence.sh` | Citing identifiers that do not exist |
| **Closed claim vocabulary, one row per claim with artefact and command** | januskey ledger; absolute-zero ledger; ordinal-notation claims table | Percentages; flattened status |
| **Falsifier table** | marches `FALSIFIERS.adoc` | Claims with no stated way to be wrong |
| **Dated, self-caveating snapshot** | quandledb `AFFIRMATION.adoc`; maa `STATE-OF-PLAY` ("marked *FALSIFIED* rather than quietly dropped") | README drift |
| **Statement audit before proving** | januskey probe audit; absolute-zero design audit; valence-shell ground-truth audit | Proving the wrong statement |
| **Hypothesis threaded, never discharged silently** | marches `Acyclic`; absolute-zero funext as an argument; januskey `cancels` premise | Hidden assumptions |

## 4. Pain → construct map (my inference; nothing below is claimed by the repos unless cited)

**"Each change is fine, the combination is not" (merge conflicts, semantic clashes).**
Three machine-checked theorems in this cluster have exactly this shape: `closedness-needed` (two no-ops compose to a non-no-op), `OND5-non-composition` (two non-leaking ops compose to a leak), `Freewheel.f2_discharged` (drop strictness and loops return). And two give the positive side with the needed side-condition named: `cno-composition` needs `Closed p₁`; `DiscSys.compose` needs `Acyclic`. A merge gate built on this would ask each change for its closure condition (what it jumps into / depends on outside itself) rather than re-testing every pair. Not built anywhere.
`SingleActiveLog.at-most-one-active` is a ready, implementation-independent statement of "one writer at a time" for any claim/lock/transaction log (bot coordination, PR ownership, release trains). Proved in Agda; refinement to any real system is open (T-10).
quandledb's `Confluent` TLA+ property is the statement "merge order does not matter" for union-style merges; it is a bounded model, and holds for equivalence closure because that operation is a join. It would not hold for arbitrary edits.

**Unsafe vs safe dependency bumps.**
- A bump is "safe" when the diff is a CNO *relative to a declared observation* (`IsCNO` up to `obs-eq`; `is-OND O`). The residue register is the part most tools lack: a list of what the certificate does not cover.
- januskey's Loss grade gives a three-valued label (lossless `fin 0`, lossy `fin n`, obliterating `inf`) with the two theorems one wants for a chain of bumps: `lossless-trace-all` (no hidden lossy step inside a chain certified lossless) and `obliterate-absorbs` (one irreversible step taints the chain). The grade is an annotation, not derived from code; deriving it is open (G-3).
- Rollback: `rollback-restores`, `operationSequenceReversible`, and the MAA RMR-L/RMR-R laws "up to a named equivalence" tell you what "revert" must mean and which direction is unproved (RMR-R has no ledger row).

**AI/LLM errors (hallucination, overclaim, fabricated structure, drift).**
Section 3 is the answer this cluster gives, and the cluster's own history is the evidence base: jtv's `ensures(true)` "formally verifying totality"; the MAA draft naming Isabelle/Z3 the repo never had; HackenbushGames "Completion-100%" beside a placeholder by "Mistral Vibe"; aletheia's unprovable biconditional; absolute-zero's Z3 `unsat` that "checked nothing"; Lean axioms deriving `False` while "`lake build` reports success".
invariant-path's doubling attack names a failure I saw in the estate docs themselves: the same count restated in several files reads as corroboration (absolute-zero's axiom count is "61" in its historical headline, "23" in maa's PROOF-NEEDS at the old pin, 35 by my `^Axiom|^Parameter` grep at HEAD, and 87 "axioms" in mathesis's census row at `ad69ddf`; four numbers, four counting rules). The sortal layer (identity before counting) is the stated cure and is unbuilt.
invariant-path `doc_claims.rs` is the only *implemented* tool here that grounds prose claims (file exists, path contains regex) against a tree.

**Trivial syntax failures.**
jtv's point is that a sufficiently weak language makes "parses" equal "is safe to evaluate", and that a second AST type makes the forbidden embedding a compile error. Estate metadata and CI configuration are data, not control; putting them in a DATA-class grammar would make the class "config that loops, shells out or half-parses" unconstructible. maa-framework's month-long dropped brace is the counter-lesson: a syntax gate only helps if something compiles the file ("nothing was compiling it").
marches R2 is the same idea one level up: the ill-formed move has no constructor.

**CI cost and flakiness.**
- A change certified CNO on the observed surface needs no re-test of that surface (C1 + C5). Honest limit: the certificate is relative to `O`; flakiness that lives in the residue (timing, cache, network) is exactly what OND says it cannot see.
- marches `composeCut_trace_embed/reflect`: restricting an acyclic composite to a cut prefix is sound and complete for traces ending in the prefix. For a build/dependency DAG this is the correctness statement behind "only re-check downstream of the change". Lean only, ungraded.
- `wt_cycles_are_empty` / `Discipline.no_loop`: if every automated step strictly inflates a measure, no bot ping-pong or retry loop exists. ordinal-notation supplies well-founded measures far beyond what any such loop needs.
- Totality islands (J1, J3): a hook or check written in a total fragment cannot hang; depth bounds turn stack exhaustion into a parse error.

**Template drift.**
invariant-path's "different faces, same cube" (I5, I6) is the statement template drift needs: many presentations, one canonical object, compared by hash, with the *scope of equivalence written into the record* and a guard that the record "has not quietly acquired a stronger claim". Its rule "a profile does not vendor the corpus it examines" is the anti-drift rule; maa-framework's vendored `aletheia/` with 16 never-run workflows, and its submodule 73 commits behind, are the cost of breaking it. aletheia itself (M4) is an implemented offline drift checker for RSR file presence.

**Licence / metadata drift.**
No construct in this cluster addresses licences formally. What transfers: a metadata migration (e.g. A2ML → deed) should be an RMR-L claim "up to a named equivalence on facts", and `lossless-trace-all` is the statement that a multi-step migration certified lossless has no lossy step. Observed drift, flagged only (section 6).

## 5. PROOF-STATUS documents checked against files

| Repo | Check | Result |
|---|---|---|
| absolute-zero | 17 CNO names, OND/EB names in the Agda | all present; flags as stated; receipt file exists |
| absolute-zero | "182 top-level theorems" (archived Coq) | my grep: 182 |
| absolute-zero | `docs/TWO-PILLARS.adoc`, `README.adoc` | still describe CNO as "thermodynamically reversible" and "Formalised across six proof systems"; both carry warnings pointing at PROOF-STATUS. README has an OpenSSF badge linking `projects/XXXX` |
| marches | 16 Lean headline names; Agda files; reject fixtures | all present; README and PROOF-STATUS agree |
| ordinal-notation | 24 names | all present (`ω^^-infl` at `OrdinalExp.agda:143`) |
| ordinal-notation | README CI paragraph vs PROOF-STATUS | README stale (says no green run; PROOF-STATUS cites one on the moved job) |
| januskey | `lossless-trace-all`, `at-most-one-active`, `rollback-restores`; fixtures | present; PROOF-GRADES explains why legs on disk do not count |
| valence-shell | Agda flags and postulates at HEAD | consistent with the 2026-11-09 block; older blocks in the same file contradict it unless read by date |
| zerostep | README "Isabelle/HOL proofs" vs PROOF-NEEDS | PROOF-NEEDS omits the theory; theory not in CI |
| maa-framework | PROOF-NEEDS vs upstream | measured at a pin 73 commits old; cited paths since archived |
| frayed-knot-toolkit | README "formally verify" | no strict flags, no CI job |
| HackenbushGames.jl / ZeroProb.jl | completion badges vs PROOF-PROGRESS | badges 100% / 95%; PROOF-PROGRESS placeholder / "TBC" |
| invariant-path ADR-0001 | `any_jump_is_cno` in absolute-zero | not found at HEAD |
| mathesis census (`/home/user/mathesis/docs/atlas/census/rows.jsonl`) | rows for the 13 repos | 9 have a row; none for jtv-halting-islands-ct, frayed-knot-toolkit, HackenbushGames.jl, ZeroProb.jl. Row commits are older than the HEADs here (e.g. marches `466e8bc`) |

## 6. Departures met (flag only; nothing edited)

- `.a2ml` files still tracked: frayed-knot-toolkit 92, maa-framework 41, valence-shell 30, januskey 29, ZeroProb.jl 27, HackenbushGames.jl 22, zerostep 19, quandledb 7, invariant-path 1 (`git ls-files | grep -c '\.a2ml$'`). Only absolute-zero and ordinal-notation have a `*_chora.deed`.
- Licence badge mismatch (flag only, not touched): `quandledb/README.adoc:12`, `zerostep/README.adoc:5`, `frayed-knot-toolkit/README.adoc:4` show an MPL-2.0 badge whose alt text is "PMPL-1.0" and whose link is palimpsest-license. zerostep's README and theory carry "SPDX-FileCopyrightText: 2024 Joshua Jewell", which bears on which licence class applies; that is an owner question.
- zerostep README build instructions include `nix build` (Nix is denied estate-wide) and CUE.
- frayed-knot-toolkit commits compiled `.agdai` files and runs no proof under the §2.1 flags.
- Percentages in status text: aletheia README "Phase 1: 100% │ Phase 2-4: 70%"; completion badges in the two Julia repos.
- invariant-path `doc_claims.rs` has a `Predicate::A2mlKeyPresent` variant (reads A2ML).

## 7. Gaps

- No proof was re-run; every PROVED rests on source reading plus the repos' receipts.
- I did not read every Lean/Coq leg line by line (valence-shell Coq and Lean, januskey Rocq/Lean, absolute-zero archive) and did not read most of the 77 ordinal-notation modules beyond names, headers and one refutation module.
- maa-framework's submodule content was not available; statements about it come from the pointer and from the upstream repo's history.
- frayed-knot-toolkit's clone status is ambiguous (section 0).
- I did not open the Julia test suites, the valence-shell Rust (73 files) or the quandledb Julia evaluator beyond the lines cited.
- "Could kill" mappings in section 4 are my own; none has been prototyped.
