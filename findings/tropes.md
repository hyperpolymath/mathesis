# Tropes cluster: findings

Read-only research, 2026-11-24. Clones under `/home/user/estate/<owner>/<repo>`.
Every claim below cites a file I opened or a command I ran. Status words:
**PROVED** = a proof file exists and the named lemma is in it (I grepped for it);
**STATED** = spec/doc only; **ASPIRATIONAL** = roadmap/proposal;
**IMPLEMENTED-UNPROVED** = code exists, no proof.

## 0. What was and was not run

- No prover is installed here (`which agda lean lake idris2 isabelle coqc` returned nothing). **I re-ran no proof.** "PROVED" means "the proof source exists, the named lemma is present, and a text scan finds no escape hatch"; kernel acceptance rests on the repos' own CI receipts (e.g. `proofs.yml` run 42623339243 cited in `trope-checker/docs/status/PROOF-STATUS.adoc`), which I did not fetch.
- Run here: hole scan over `trope-checker/verification/proofs` and `src/idris2` for `postulate|sorry|believe_me|assert_total|Admitted|axiom|TERMINATING` outside comments: **0 hits**. Same scan over `tropical-types` Lean: 0 hits; its 9 `.thy` files have 4 textual matches of `sorry`/`oops`, all four in prose comments (`Tropical_CNO.thy:29`, `Tropical_Kleene.thy:663`, `Tropical_Matrices_Clean.thy:24`, `Tropical_Ordinal.thy:15`).
- Run here: `bash scripts/pwg-derive.sh --census` in trope-checker (jq only) -> "of 24 theory obligations ... PWG-3 17, PWG-2i 0, PWG-2ii 0, PWG-1 0, ungraded 7", identical to the census line in PROOF-STATUS.adoc. (`verification/pwg.json` holds 25 theorem rows; one is `not-applicable`.)
- Run here: `tests/check-vocabulary.sh` (workbench) -> pass, nine effects consistent. `tests/check-stack-coherence.sh` with `STACK_ROOT=/home/user/estate/hyperpolymath` -> **4 of 10 checks found a disagreement** (details in section 9).
- Name-existence check: I took 44 Agda, 41 Lean and 37 Idris2 lemma names from PROOF-STATUS.adoc and the spec. All 44 Agda names have a type signature (`^name :`) in `TB/*.agda`; all 41 Lean names appear after `theorem|lemma|def|instance` in the cited file; all 37 Idris2 names have a top-level signature in `Trope/*.idr`. A few further names PROOF-STATUS cites (e.g. the `*.leftCancelWitness` family, `bondFamily_coord`) I did not check individually.

Repos: trope-checker 126 commits (first 2026-06-22, HEAD `0dceab6`), trope-particularity-workbench 90 commits (first 2026-06-21, HEAD `ae66b4a`), tropical-types 120 commits (first 2026-03-26, HEAD `f2e465c`).

## 1. What the owner means by "trope"

Not one thing. I found **six** distinct uses. The calculus itself warns of three (`trope-checker/spec/calculus.adoc` section 1: "The word *trope* carries three distinct meanings across this programme, and conflating them is itself a modelling error this calculus exists to forbid"); three more live in other repos.

| # | Sense | Where | Formal content |
|---|---|---|---|
| 1 | **trope-the-particular** (primary). A property-instance: "a property considered as a non-repeatable, situated instance - *this* quality, here, borne by *this* bearer" (Williams 1953, Campbell 1990). Metaphysical, particularised property. **Deliberately enriched**: four fields `quality, bearer, context, record`; "that enrichment is a deliberate departure from the classical notion, recorded explicitly so that downstream readers do not attribute it to Williams." | `trope-checker/spec/calculus.adoc` sections 1-2; `trope-particularity-workbench/docs/background.adoc`; `vocarium/README.adoc`; `catachresis-colloquium/enaction-engine/crates/enaction-trace/src/lib.rs` (Rust `struct Trope`) | The object of the calculus. |
| 2 | **trope-the-residual**: "A residual treated as a sum-typed object rather than a scalar error term, with a veridicality axis" - reused as the *grade*. | calculus section 1 | The loss-shape grade. |
| 3 | **trope-the-valuation**: "bottleneck (max-min) grading of a path by its weakest link, with the argmin locating the edge to repair. (The *invariant-path* sense.)" Used only by analogy for the verdict witness. | calculus section 1, section 6.2 | Min-max semiring; cf. `tropical-types/TropicalAdapterPath.lean`. |
| 4 | **trope = finite typestate machine on a type**: "A *trope* is a finite transition machine attached to a type", `T(A) = (S, s0, F, delta)`, values typed `A@s`, ops `A@s -> A@s'`; replaces System FC roles/coercions. **Not listed among the calculus's three senses.** | `system-et/docs/theory/07-tropes.adoc`; `system-et/verification/proofs/agda/Wager/L2/{Term,Typing,Signature}.agda`; `anytype/README.adoc:182` | Typestate. ET-12/ET-13 obligations. |
| 5 | **trope = Layer 2 of a three-layer claim checker "type / trope / sortal"**: "Does this particular evidence survive the leap to this conclusion *for this use*? Purpose-indexed warrant." Same machinery as sense 1+2, re-read as warrant for arguments. | `invariant-path/README.adoc`, `ARCHITECTURE.adoc`, `docs/decisions/0001-the-sortal-layer.adoc` | Decided, not built (in invariant-path). |
| 6 | **trope = recurring figure / pattern** (the colloquial and rhetorical-adjacent sense): "the invariant / equivalence-class (the recurring *trope*)"; owner's framing "types -> carrier, tropes -> recurring equivalence-figures, knot theory -> certificate"; and section headings "Type, logic and proof tropes worth pursuing". | `nextgen-language-evangeliser/CLAUDE.md:17`, `docs/theory/CORRESPONDENCE-MODEL.adoc:108`, `src/interface/Abi/Correspondence.idr:22` (`data Stratum = Surface | Structure | Intention | Trope | Invariant`); `jtv-lang/docs/architecture/LANGUAGE-SYSTEM-ARCHITECTURE.adoc:759`; `valence-shell/docs/plans/VSH-ROUTE-PLAN-2026-11-04.adoc:664`; `affinescript/docs/COMPLETION-PLAN.adoc:701` | A stratum label / a list of design patterns. No calculus. |

**Rhetorical figure (metaphor, metonymy, catachresis)?** Not found as a defined sense. A grep for `rhetoric|figure of speech|metaphor|metonym|catachres` across the trope specs returned only `vocarium/README.adoc:64` (an example `context` string "de Man / rhetoric / Romantic irony") and three uses of the ordinary word "metaphor" in the invariant-path ADR. Sense 6 ("recurring equivalence-figure") is the nearest; it is a pattern/figure sense, not a theory of rhetorical tropes. So: **metaphysical particular is the defined, formal sense; the rhetorical sense is not formalised anywhere I read.**

The canon reserves a slot for it: `metadatastician/standards/2-protocols/chora/CHORA-SPEC.adoc:125` allows vocabulary terms with `:kind` = `type`, `trope`, `lattice`, `invariant`, and line 32 says "A later trope format adds term kinds and no grammar". `1-formats/deed/spec/DEED-GRAMMAR-SPEC.adoc:556`: "Vocabulary - types, tropes, lattices - is declared in `estate_chora.deed` and nowhere else." A grep for `:kind +trope` across all 484 clones returned **no hit**, and `estate_chora.deed` exists only as two conformance fixtures (`deed-ecosystem/conformance/valid/`, `deed-core/actions/validate/conformance/valid/`). So tropes-as-estate-vocabulary is STATED, not instantiated. `0-canon/constitution/KNOWN-TENSIONS.adoc:16` lists "Type abstraction vs trope particularity" as an architectural tension, status "known incomplete work".

The owner's own research note on the relation is `vcl-ut/docs/research/TYPE-TROPE-IDENTITY-SPACES.adoc` (status "EXPLORATORY"): "Type formalisms *can* encode individual records ...; tropes *can* have rigorous operations and checkers. The distinction is about what a judgement asserts and its evidence, not that one side is mathematics and the other is metaphor." It states "No type-trope equivalence or general triangulation theorem is claimed" and "A general construction of types <-> tropes <-> sortals has not been located in the inspected repositories".

## 2. The calculus (trope-checker `spec/calculus.adoc` v0.2, 828 lines)

**Object.** `Trope[S]`, `S` a subset of `Phi = {quality, bearer, context, record}`; `FloatingQuality` (no bearer); collapse codomain (e.g. `Bool`).

**Trope-particularity** (working definition): "The *recoverable individuating content* of a property-instance ... *graded and use-relative*, not binary and absolute."

**Grade = loss-shape carrier**, six slots over three coordinate kinds, "not a scalar":
- `fate` per field: chain `Falsified < Dropped < Predicated(P) < Attenuated(top) < Attenuated(inf) < ... < Attenuated(1) < Present`. Fidelity `delta` in `N u {inf, top}`, tropical (min-plus) order; `top` = "loss of unknown amount".
- `bond`: `Intact > Withheld > Severed > Misbound`. Fibred over the bearer's fate (HC-4): incoherent combinations unrepresentable at the validation boundary.
- `merge`: `Single > Fused(tau) > Conflated`.
- Unit `eps = (all Present, Intact, Single)`.
- Exactly three **deceptive duals**: `Falsified` (false value), `Misbound` (false bearer), `Conflated` (false singleness).

**Nine effects** (vocabulary), six writable (`preserve, project, collapse, detach, attenuate, fuse`), three faults (`falsify, misbind, conflate`). Five atomic moves `attenuate, predicate, drop, sever, fuse`.

**Judgement.** `Gamma |- e : A ! g`; function types carry latent grade `A -g-> B`. Rules T-Preserve, T-Project, T-Collapse, T-Detach, T-Attenuate, T-Fuse (meet of inputs, then label; **tag required** - "a fusion term with no tag does not parse"), T-Sub (one-sided: "you MAY always claim more loss than occurred").

**Laws** (on the label-erased carrier): L1 assoc, L2 unit, L3 deceptive bottoms are two-sided zeros, L4 monotone in both args, L5 deception infectious, L6 commutative; C1 conical; C2 cancellation only on the finite-fidelity core; C3 honest-absorbing vs deceptive partition; tropical factorisation `pi_R`.

**Verdict.** `p-sufficient(g, U) iff floor(U) <= g` (retention order); otherwise `p-insufficient` with a **witness edge**: first edge in topological order (ties by edge ID, document order must not matter) whose accumulated grade violates the floor. Use-model floor is a partial per-slot demand.

**Recursion.** T-Fix-Decl: author declares `gamma`; accept iff `gamma <= F(gamma)`. "No fixed point is ever computed." Unbounded lossy recursion gets `top`, "an honest answer".

**Profiles.** *prevent* (shipped): deceptive grades and untagged merges are schema-invalid, rejected with the coordinate named. *detect* (documented only): admitted and caught at the verdict.

**Three firewalls** (README, calculus section 8): soundness not completeness; relative to faithful lowering (O2 per front end, none discharged); veridicality declared and propagated, not checked (Remark O5-a: undecidable relative to the IR).

## 3. What the checker checks (`src/idris2/Checker/Check.idr`, 132 lines; Rust twin `src/rust/src/lib.rs`, 1204 lines)

It checks **composition of declared claims**, nothing else:
1. JSON well-formedness and IR decode (`Checker/Json.idr`, `Decode.idr`), A3 normalisation, HC-4 coherence, rejection of deceptive values, graph validity (duplicate node/edge ids, undeclared refs, duplicate producers, cycles).
2. `accFuel`: `eps` at roots, `gradeCompose` along edges, `gradeMeet` at a two-input fuse, fuel = edges+1.
3. `violations floor final`; if non-empty, `witnessOf` over `topoOrder` (Kahn, smallest-ID ready edge).

It does **not** check: that a source construct really is the effect claimed (O2); that a claimed-faithful value is true (O5); anything about source code (HC-1: "MUST NOT parse, import, execute, or depend on any source language").

Corpus counted here: `tests/conformance/cases.json` 15 cases, `fixtures/` 15 files, `schema-invalid/` 9, `graph-invalid/` 8. CI: `.github/workflows/trope-check.yml` also validates the schema with ajv against draft 2020-12 and requires every schema-invalid fixture to be rejected **by the schema**.

**Reference and fast core differ outside the schema (read, not run).** The schema caps `inputs` at `maxItems: 2` (`schemas/trope-ir.schema.json:439-440`) and enumerates the effects. But:
- Idris2 `accFuel` on an edge with 3+ inputs takes `(g :: _) => gradeCompose g e.egrade`, i.e. ignores every input after the first. Rust `acc` (`src/rust/src/lib.rs:910-921`) folds `grade_meet` over **all** inputs.
- Idris2 `decodeEdge` (`Checker/Decode.idr:118-127`) reads `effect` as any string and `inputs` as any list; I found no arity or effect whitelist in that file. Rust `dec_edge` (`lib.rs:706-736`) rejects unknown effects but also has no arity check.
- None of the 9 `schema-invalid/` or 8 `graph-invalid/` fixtures covers a 3-input edge or an unknown effect.

So "agrees with the Idris2 reference ... bit-for-bit over the conformance corpus" is true of the corpus only, and ADR 0002's sentence "the decoder is the executable reference validator; they encode the same rules" is not what the two decoders do for these two inputs. A caller that skips JSON-Schema validation and feeds a 3-input edge to the Idris2 `tropecheck` would, by my reading, get a grade that ignores the later inputs - the unsound direction. I did not execute either binary.

## 4. Proof status, checked against the files

`docs/status/PROOF-STATUS.adoc` (448 lines) matches the sources on every name I checked. Summary by prover:

| Result | Agda (`--safe --without-K --cubical-compatible --exact-split`, `TB/*.agda`, 1830 lines) | Lean 4 + Mathlib (`lean4/`) | Idris2 (`%default total`, `Trope/*.idr`, 1792 lines) |
|---|---|---|---|
| L1 assoc | `gmonoid-assoc` | `GradeR.instCommMonoid`, `FateA.comp_assoc` | `gradeAssoc` |
| L2 unit | `gmonoid-unit{L,R}` | not stated | `gradeUnit{L,R}` |
| L3 two-sided zeros | `falsified-absorb{L,R}`, `misbound-absorbL`, `conflated-absorbL`, `deceptive-absorbs-▷` (right forms for Misbound/Conflated not separate lemmas) | `falsified_two_sided_zero`, `gBotR_two_sided_zero` | not stated |
| L4 monotonicity | fate + fidelity only (`fateL4Mono{R,L}`, `dplusMono{R,L}`) | fate only (`comp_mono_{right,left}`) | fate (`fateL4Mono{R,L}`), bond, merge (`bondComposeMono`, `mergeComposeMono`); **no grade-level lifting** |
| L5 infectious | `deceptive-absorbs-▷`, `{attenuate,project}-stays-deceptive` | not stated | not stated |
| L6 commutative | `grade-comm` | `instCommMonoid`, `comp_comm` | not stated |
| Fate chain A2 | `fateDroppedLtePredicated`, `fatePredicatedNotLteDropped` | (PROVEN-WITH-AXIOMS per ledger) | same names |
| Veridicality Derivation (exactly 3 deceptive duals) | `TB.Honest.*DeceptiveUnique`, `deceptiveDuals` | not stated | same names |
| Honest Generation (5 atoms never produce a dual; closed under ▷) | `genFate/genBond/genMerge`, `honest-closed-▷` | not stated | `genFate/genBond/genMerge` |
| C1 conical | `grade-conical` | `GradeR.conical` | not stated |
| C2 cancellation boundary | six `*-not-cancel` + `Q-cancelʳ`; **no exhaustive iff** | `gradeR_leftCancel_iff` | not stated |
| O1-carrier atom factorisation | none | `GradeR.atom_factorization`; `nine_families`, `family_realized`, `families_disjoint`; **bridge between them not a theorem** (`emb*_one` lemmas "used by nothing") | none |
| Tropical factorisation (B') | none | `piR_hom`, `piR_sighted`, `phiId_not_hom`, `sighted_forces_squash` | none |
| Theorem B T1 intrinsic calculus | `TB.Syntax` (no `fuse`, no `fix`, coarse presence) | - | - |
| Theorem B T2 grade-exact substitution | `cut-preserves-grade`, `cut-grade-comm` | - | - |
| Theorem B T3 subject reduction | `β-app`, `β-let` only; "preservation holds by construction"; **no progress theorem; `fix` NOT-REACHED, not postulated** | - | - |
| Grade soundness, exact lowering | none | none | `soundFromExact` |
| T-Sub soundness / verdict soundness | none | none | `subSound`, `verdictSound` |
| Retention order decidable preorder | reflexivity only | none | `decGradeLte`, `*LteTrans`, `gradeLteTrans` |

Proof Witness Grades (derived, not asserted; `scripts/pwg-derive.sh` + `pwg-check.sh`): 17 at `PWG-3`, 7 `ungraded`, 0 above. "No Rocq development exists in this repository at all." Lean legs are `BRIDGE-PENDING` and do not count: owner ruling 2026-11-09 "**Lean is a generator, not a leg**" (Mathlib cone violates PROOF-POLICY section 2).

**Open (named, not asserted):** CO-1 mechanisation (operational model for `fix`, conservative grade soundness) - DESIGNED in `spec/notes/2026-07-07-co1-operational-model.adoc`; O1-coord (are fate/bond/merge exhaustive? live probe: bond-transfer / swapping as a candidate tenth family); O2 lowering correctness ("no producer has discharged it"); O3 produce/demand adjunction (conjecture); O5 veridicality oracle (PROPOSED, ADR 0005 still "Proposed - owner to accept"); O6 ceiling verdict (privacy direction).

**Rust fast core** "is not a proof; it agrees with the Idris2 reference over the whole conformance corpus". No Creusot/Verus development was found in `src/rust/`.

### Discrepancies I found

1. **ROADMAP overclaims relative to PROOF-STATUS.** `docs/status/ROADMAP.adoc` "Shipped (v0.2)": "[x] L4 monotonicity in full, both arguments, every coordinate (Idris2, Lean, Agda)" and "[x] Atom factorisation - O1-carrier proved". PROOF-STATUS (and the files) say Agda and Lean cover fate only, bond/merge are Idris2-only, the grade-level lifting is mechanised nowhere, and the factorisation-to-nine-families bridge is not a theorem. The README's Status section agrees with PROOF-STATUS ("*L4 in full* is proved by none of the three"). The spec's own L4 row says "*Holds in full on the ratified carrier*" and O1-carrier row says "PROVED" - same overstatement as the ROADMAP.
2. **Known false acceptance (predicate labels erased).** `trope-particularity-workbench/docs/theory/formalisms/grades-as-abstractions-of-transformations.adoc` section 2: with floor `Predicated(isQuack)`, an edge recording `Predicated(isLoud)` returns `p-sufficient` on the Rust checker ("Reproduced on 2026-11-17"; Idris2 "Not run"). The survey note calls this "Issue 125" ("Until predicate labels are compared or refused, experiment 1c stays a false acceptance"). I found no reference to that issue number inside trope-checker's own `.adoc` files.
3. **Retired claim still in README.** `trope-checker/README.adoc:33` "`Rust` (Haec) is the first front-end" is RC-3 in the workbench's retired-claims register (haec has no compiler; `haec/compiler/STATUS.adoc`: "*Not built.*").
4. **`fix` section status**: the spec says the checker "SHALL be bidirectional" at recursive boundaries; but T-Fix-Decl "is an obligation of the *front end*", and there is no front end with a compiler. So the recursion story is STATED end to end.

## 5. trope-particularity-workbench (documentation only; "This repository is documentation only")

- **Vocabulary**: 12 terms - nine `p-*` effects, `p-residual`, `use-model`, `p-sufficient`/`p-insufficient` (`README.adoc`, `vocabulary/*.adoc` 9 files, `docs/decisions/0002-nine-effects.adoc`). Gate: `tests/check-vocabulary.sh` (passes here).
- **Compatibility test** for adding a term (`docs/background.adoc`): contradicts nothing; writable bridge; conservative extension; non-redundant work.
- **Stack coherence gate** `tests/check-stack-coherence.sh` (259 lines) + **retired-claims register** `tests/stack-coherence/retired-claims.tsv` (id, regex, what superseded it, allowed paths; "never widen an allow-pattern to make the gate pass"). Ten checks S0-S9 across the five repos.
- **Three open theorems** (`grades-as-abstractions-of-transformations.adoc` section 4, all "Open. Stated, not proved"): abstraction theorem `ProducerSound(f,g) & AbstractSafe(g,u) => Suff(f,u)`; sufficiency as factorisation (`u = v . f`); coherence-preserving atom factorisation.
- **Three-outcome verdict proposal**: certified sufficient / certified insufficient / indeterminate; "A failed check is not a proved failure."
- **Warrant-level theorem** W-1/W-2/W-3 (`vocarium-survey.adoc` section 6, "Stated, not proved"): a verdict computed over an edge held only at `epi` is itself at most `epi`; along a path the level is the least among edges. Leans on `palimpsest-license/proofs/agda/Provenance/Warrant.agda` (`no-signature-sound` at line 98, `no-consent-sound` at line 136; file exists, `--safe --without-K`) and `epistemic-types/src/EpistemicTypes/Warrant.agda`.
- **O5 definition** (`defining-o5-veridicality-oracle.adoc`), carried upstream as PROPOSED.
- **WP-1 notes** (philosophy; "a proposal, not a theorem about the world"): swapping = commutativity of ▷; piling = merge coordinate; resemblance regress relocated to the `record` axis; synthesis `whitepapers/academic/separating-the-axes.adoc` with an exhaustiveness *conjecture*.
- **Neural representation** (`docs/theory/computing/trope-theory-and-neural-representation.adoc`): learned features as tropes; superposition/polysemanticity as `p-fusing` vs `p-conflating`. "Every hypothesis above is unfalsified *and untested*."
- Four survey experiments with fixtures (`examples/survey/*.jsonl`), run 2026-11-17 on `voc` + `tropecheck-rs` per the note; not re-run here.

## 6. tropical-types ("tropical" = max-plus/min-plus/min-max semirings; the word "trope" does not occur in the repo - grep over `.adoc`/`.lean` returned nothing)

Relevance to tropes: it supplies sense 3 (bottleneck valuation) and the fidelity carrier's algebra; ADR 0005 D6 (recorded, not decided) would make the trope fidelity carrier a parameter instantiated from `hyperpolymath/resource-algebra`.

Lean 4 v4.35.0, **no Mathlib** (`lakefile.lean`, `PROOF-STATUS.adoc`: "Build completed successfully - 21/21 targets (2026-11-09)"; I did not re-run). 133 `theorem`/`lemma` lines counted across the Lean files; no `sorry`/`axiom`/`Classical` outside comments.

- `TropicalSessionTypes.lean`: max-plus grading of speculative session types; `soundness : grade s = .val (Span s)`; `tropical_grade_le_sequentialTotal` (max <= sum).
- `TropicalAdapterPath.lean`: min-max bottleneck; `pathCost_mono`, `pathCost_append`, `minimax_path_optimal`, `dualGrade_invol`, `dual_tcAdd_is_max`, `dual_tcMul_is_min`; **`hub_ceiling`** (`grade e <= pathCost path` whenever `e ∈ path`): "One hub therefore caps the fidelity of every format that must pass through it."
- `Resource/Algebra/*`: `ResourceSemiring`, ordered `ResourceAlgebra` (preorder, monotone ops); `parametric_resource_transport`, `resource_laws_sufficient_for_consumers`.
- `Resource/Instances/*`: Linear, Affine ({0,1,omega}), MaxPlus, MinPlus, MinMax.
- `Resource/Closure.lean`: matrix layer, `matStar_mono`, `id_le_star`, `allPairs_bound_of_refine`.
- `Resource/HubCeiling.lean`: `single_hub_ceiling`, `single_hub_star_ceiling`, `reachGrade_mono_*`, `weightedMeasure_append`, `maxplus_not_one_top`.
- `Resource/Stress.lean`: `infinite_{maxPlus,minPlus,minMax}`.
- `Resource/EchoBridge.lean`: `ResidueMeasure` structure; direction resource algebra -> residue measure only.
- Isabelle/HOL: 9 theories, 284 `theorem|lemma|corollary` lines counted; "present, CI-gated, NOT re-verified here"; "cross-prover *equivalence* is not mechanically established".

Metadata observations (not my task to fix): the repo still tracks `0-AI-MANIFEST.a2ml`, `audits/assail-classifications.a2ml`, three `tests/*.a2ml`, `LICENSES/AGPL-3.0-or-later.txt`, and its README cites `FOUNDATION_CONTRACT.md` while the tracked file is `FOUNDATION_CONTRACT.adoc`.

## 7. Other repos with substantive trope content

- **system-et / anytype** (sense 4). `docs/theory/07-tropes.adoc`: ET-12 trope preservation "Status: specified"; ET-13 per-API machines "instances 0/5"; file-handle exemplar "unproven today". The Agda `Wager` development (96 files with `{-# OPTIONS --cubical --safe #-}`, no `postulate` found outside comments) models trope transitions (`t-step`) with preservation and progress; `Wager/ASSESSMENT.adoc`: "W does not hold as written"; "A newtype with a parameter needs trope states with an index, not 2 states" (`no-two-state-translation`); "That is evidence toward ET-12. It is not a proof of ET-12."
- **invariant-path** (senses 3, 5). Three-layer claim checker; **doubling attack** ("one derivation presented twice, paraphrased, under distinct labels ... corroboration weight is two instead of one") forces `Layer 1 (type) -> Layer 3 (sortal) -> Layer 2 (trope)`. "*These layers are decided, not built.*" `docs/DEBT.adoc` A3: Layer-2 vocabulary in circulation does not match the implementation; "`p-residue` does not exist in any repository in the estate." `proofs/SameCube.agda` (`--safe --without-K --cubical-compatible`, 0 `postulate`): statement-vs-tail lowering equal for unit-returning actions; `nonUnitResultCounterexample`.
- **hermeneia** (`docs/THEORY.adoc`): trichotomy *retrieved / interpretable / licensed*; licensing = `floor(U) <= acc(v)`; `revoke` as contraction over a warrant graph, "recomputed, not chosen". Implemented: `invoke` only; six other vokes "refused as unimplemented".
- **vocarium**: Zig store. `src/store/store.zig:167-170` refuses an edge with a missing or empty `warrant_id` ("a stored loss-shape is a claim; every claim needs a warrant"). The workbench survey (section 6, its own run) adds: the store refuses a revocation record, and the IR that `voc invoke` emits carries no warrant. I did not build or run `voc`.
- **haec**: design only; `design/elaboration.adoc` gives an O2 obligation per construct; PROOF-STATUS "0 done ... 7 remaining".
- **hypatia** `docs/design/2026-11-14-merge-honesty.adoc`: applies `Single / Fused(tau) / Conflated` to Hypatia's finding-merging; five current merges classified `Conflated`; **RULED by owner 2026-11-14**: label the merge now (E0-18), merged matches reach `review` at most (E0-19), untrained novelty network means novel / fail closed (E0-24). "No proof connects them."
- **error-lang** `docs/Trope-Particularity-Integration.adoc`: design (not implemented) for a second front end; replaces a scalar `calculateStability` with the three-coordinate grade.
- **enaction-engine** (Rust): `Trope` as abstract particular with id, `resembles`, `holders` ascription path (`crates/enaction-trace/src/lib.rs`). Code exists; I looked for no proof there and found none cited in the module header.
- **vcl-ut** research note: obligations X-01..X-09 ("open obligations, not statements of proved results"), e.g. X-07 "honest fusion is distinguishable from conflation", X-08 "Combined typed and trope verdicts do not imply one another".
- **nextgen-language-evangeliser**: strata surface/structure/intention/trope/invariant; six relation classes (cognate, false-friend, antonym, alien-realization, novel, vanished).
- **jtv-lang**, **valence-shell**, **affinescript**: lists of "type, logic and proof tropes" (sense 6) mapped to specific issues - e.g. "Parse, don't validate (typestate)", "Normal forms in free models (equivalence as identity)", "Non-vacuity as a mandatory pattern", "Affine types for undo payloads", "de Bruijn criterion / LCF kernel".

## 8. Where these constructs could kill recurring engineering pain

Each row: construct -> pain -> honest caveat. None of these applications is proved; they are my reading unless a repo says otherwise (hypatia's is the owner's).

| Construct (status) | Pain | How | Caveat |
|---|---|---|---|
| `merge` coordinate: `Fused(tau)` vs `Conflated`, tag mandatory, `Conflated` a two-sided zero (PROVED algebra) | Merge conflicts / silent merges; bot finding dedup; squash merges losing authorship; LLM summaries blending sources | Make every N-into-1 step carry a provenance label or be rejected at a schema boundary; an unlabelled merge cannot be "repaired" downstream (L3/L5) | Says nothing about *which* things are alike; hypatia note: "The trope repositories have no resemblance relation and no metric on tropes." |
| Prevent profile: deceptive states schema-unrepresentable (IMPLEMENTED, conformance-tested) | Trivial syntax / malformed-config class; fabricated structure | "Door too small": the bad state has a name in the semantics but no well-formed document reaches it; validator names the coordinate | Only as strong as the schema boundary; O2 remains |
| Three firewalls + O5-3 "an oracle verdict upgrades confidence, never grade" (STATED) | LLM overclaim, "verified" without receipts | A claim is a claim; composition is checked, origin is not; attestation goes in `record`, never upgrades the grade | O5 is PROPOSED, unmechanised |
| W-2 "a verdict over an `epi` edge is at most `epi`" (STATED, unproved) | LLM/CI "green" laundering an unverified input into a verified output | Level of a pipeline verdict = least level on the path | Not proved; depends on `no-transfer` reading |
| Use-model floor + `p-sufficient` verdict with witness edge (IMPLEMENTED; verdict soundness PROVED in Idris2 given exact grades) | Safe vs unsafe dependency bumps; template drift; lossy migrations (A2ML -> deed, YAML -> KYAML) | Each consumer declares the minimum it needs; a transformation is graded; the checker names the first edge that broke it | Grades must be supplied by someone (O2). Predicate-label false acceptance is open |
| `Withheld` vs `Severed` (recoverable vs irrecoverable drop), O6 ceiling verdict (OPEN) | Licence / metadata / SPDX drift; redaction | Distinguish "field dropped by projection, recoverable" from "constitutively cut"; ceiling for privacy | O6 unproved; T-Sub is one-sided |
| `Attenuated(top)`: honest "unknown amount" that fails every finite floor (PROVED absorbing) | Flaky CI, "probably fine" | Force unknowns to be declared and to poison quantified claims rather than be rounded up | "top poisons paths" (hermeneia limitations): costly in practice |
| T-Fix-Decl: check a declared post-fixed point, never compute (STATED; mechanisation OPEN) | Undecidable analyses in CI; cost | Declare-and-check at boundaries, infer in between | Not mechanised |
| Witness = argmin edge / `hub_ceiling` (PROVED, Lean no Mathlib) | CI cost; "universal converter" designs; pinning through a hub | A path is no better than its worst link; one hub caps everything through it; tells you *which* link to fix | Worst-case only |
| Retired-claims register + stack-coherence gate (IMPLEMENTED; currently reports 4 failures) | Doc/status drift, LLM-restated stale facts | A superseded sentence is a regex with a citation; any repo still asserting it fails | Regex-based; needs humans to add rows |
| PWG derived-from-receipts ledger + census-with-denominator (IMPLEMENTED) | Overclaim in status docs | "No grade is written there"; table regenerated and diffed | Only covers theory theorems |
| Canary / falsifiability fixtures (`scripts/test-gate-falsifiability.sh`) (IMPLEMENTED) | Gates that cannot fail (silent green) | "A gate that has never failed is indistinguishable from a gate that CANNOT fail." | Per-gate effort |
| Coordinate preflight (ADR 0006): canonical `full_name` equals the `uses:` coordinate | Reusable-workflow breakage on repo transfer ("zero jobs, no check run") | Resolution is not canonicality | Repo-local so far |
| Sortal layer + doubling attack (DECIDED, not built) | Duplicate bot PRs / duplicate findings counted as independent corroboration; LLM self-agreement | Settle identity before counting evidence | "Nothing in this repository implements these layers." |
| Trope-as-typestate `A@s` + affine grade (STATED; ET-12/13 open; Wager Agda evidence) | Use-after-close, protocol misuse, illegal state transitions | Local finite machines instead of global coercions | 0/5 instances; indexed states needed |
| Honest Generation + Veridicality Derivation (PROVED Agda+Idris2) | Fabricated structure | A fixed, closed generator set cannot produce a lie; the lies are exactly three and named | Grade-level only: "does not establish that every typed term has an honest grade" |
| Trichotomy retrieved / interpretable / licensed (STATED; `invoke` implemented) | RAG / LLM hallucination ("the system retrieved it" read as "licensed it") | Three separate statuses on every answer | Grades supplied, not adjudicated |
| `revoke` as recomputed contraction over a warrant graph (STATED; not implemented) | Reverting a bad dependency / withdrawn advisory and finding what rested on it | Downstream licences recomputed by the order, not chosen | Unimplemented; vocarium refuses revocation records |

## 9. Drift the stack's own gate reports today

`check-stack-coherence.sh` on the cloned `main` branches:
- S4 FAIL: RC-1 "Vocarium does not exist" still in `hermeneia/.machine_readable/descriptiles/STATE.a2ml:53` and `.../intend/Intentfile.a2ml:88`; RC-2 Predicated-incomparable-Dropped still in `haec/design/elaboration.adoc:52`; RC-3 in `trope-checker/README.adoc:33`.
- S6 FAIL: shared scan workflow pinned at two revisions (`857ff09...` in trope-checker, `58362c2...` in vocarium/hermeneia/haec).
- S8 FAIL: `{{PROJECT_KIND}}`, `{{PROJECT_DOMAIN}}` template placeholders in `haec/.machine_readable/6a2/anchors/ANCHOR.a2ml`.
- S9 FAIL: "coordination" has two values (`vocarium` vs `standards`).
- S0-S3, S5, S7 pass (schemas vendored identically; 18 IR documents at 0.2; every sibling pins trope-checker at `0dceab68459d`).

## 10. Not found / not established

- No Rocq development in trope-checker; no recheck leg counts for any theorem.
- No proof connecting trope-checker's calculus to tropical-types' `Resource` algebra (D6 is "recorded, not decided").
- No formal types <-> tropes <-> sortals construction (vcl-ut note says so).
- No `p-residue` term anywhere (invariant-path DEBT A3); the vocabulary's term is `p-residual`.
- No instance of a `:kind trope` vocabulary term in any deed.
- No formal treatment of rhetorical tropes.
- No producer has discharged O2; haec has no compiler; the only IR producers are hand-lowered fixtures and `voc invoke`.
- 48 repos failed to clone (e.g. `hyperpolymath/007-lang`, `hyperpolymath/cut-calculus`, `metadatastician/kyx`, `metadatastician/proto-chora`); nothing is claimed about them.
