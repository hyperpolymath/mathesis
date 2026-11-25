# Sweep 0: lines 1-121 of .stats.tsv (121 repos)

Method: read README heads, `*_chora.deed` presence, top-level listings, proof-file inventories (find by extension, grep for postulate/believe_me/sorry/Admitted). No proof checker was run by me. "proof file present" means a source file exists; it does not mean I verified it.
Key: (a) formal maths/type/logic/proof content, (b) tooling aimed at an engineering pain, (c) neither.

## Cross-cutting observations (ground-truthed)

1. Template boilerplate presents as proof content. `verification/proofs/{agda/Properties.agda, lean4/ApiTypes.lean, coq/TypeSafety.v, idris2/Types.idr, idris2/ABI/*.idr}` exist in dozens of repos. `md5sum */*/verification/proofs/agda/Properties.agda` gives 63 byte-identical copies (plus 3 / 12 / 1 variants). The file header says "Agda Proof Template ... Replace with your project's domain-specific proofs" and proves list-append length. A naive census counting `.agda/.lean/.v/.idr` files would overcount proofs hugely. Same for `src/interface/Abi/{Types,Layout}.idr` (47 and 64 identical copies of Types/Layout) and `.machine_readable/coaptation/core/Coaptation.idr` (33 identical copies + variants). Real content is where these differ (e.g. evil-weevil Abi/*.idr is 5052 lines).
2. `Coaptation.idr` (e.g. hyperpolymath/anytype/.machine_readable/coaptation/core/Coaptation.idr) self-describes as SKELETON, "NOT yet wired to the runner": a dependent-typed shape for descriptile-vs-contractile face-off where "an unwitnessed Must is a compile-time error". The Nickel comparator `coapt.ncl` is "AUTHORITATIVE today". STATED, not proved. Directly aimed at metadata/template drift.
3. A pattern of negative controls: ExactCounts.jl, ExactTests.jl, CompositionalDA.jl, JuliaPackageSpitter.jl carry `proofs/agda/reject/*.agda` (e.g. `reject/Postulate.agda` with `EXPECT:` lines) and `tests/trusted-base-fixtures/` (RealPostulate, RealHole, UnsafePragma, MissingSafeOption, MentionsInComments). This is the "fail loudly, no silent green" idea made executable for the gate itself.
4. Count of this range: 121 repos, of which 31 catachresis-colloquium, 90 hyperpolymath. Zero have a `*_chora.deed` for about 60 of them (the rest have one); many still carry `.a2ml` files (e.g. 688-attack-hub 22 `.a2ml`, Exnovation.jl Adjust/Dust/Intend/Must/Trust.a2ml, bebop-ffi `*.scm` state files). Departure for the owner, not touched (read-only).

## Per-repo lines

### catachresis-colloquium
- 688-attack-hub | JS/HTML | (c) browser idle/strategy game about a rogue network repeater at real IXPs; AUDIT.adoc says no network calls. No deed.
- Cytoville | Rust (Bevy) + Idris2 ABI + Elixir | (a, thin) turn-based protist life sim. Has `cytoville_chora.deed`, `why3find.json`, `contracts/`, `src/interface/Abi/*.idr`, `verification/`. Game rules in Rust; formal content is the template ABI layer plus Why3 config; no standalone proof corpus read.
- First-Post | template | (c) un-instantiated RSR template copy (`{{PROJECT_DESCRIPTION}}`). Carries the template proof stubs only.
- IDApTIK | Rust | (a, real) asymmetric infiltration game. `verif/idaptik_kernel_rlib/**/*.coma` (Why3 coma output: contrast/luminance, contrast/meets, trace/impl_PartialEq_for_Trace/eq__refines ...), `why3find.json`, `crates/idaptik-ffi/abi/src/Idaptik/Abi/*.idr`. A Rust kernel verified through Creusot-style Why3 artefacts. Note: policy requires Creusot+Verus named; Verus not seen.
- airborne-submarine-squadron | JS/AffineScript | (c) Sopwith-style arcade game. No deed.
- befunge93-vault-cracker | JS/Vue/Zig + Idris2 ipkg | (c) satirical vault UI over a real Befunge-93 VM; has deed and `.ipkg` but the maths is a toy VM.
- blue-screen-of-app | Deno/AffineScript | (c) humorous BSOD web app.
- chronicles-of-slavia | Rust | (c) private exploratory game prototype; template proof stubs.
- dosovoi | Rust | (c) calm-attention terminal mascots, human-factors experiment.
- enaction-engine | Rust + Idris2 ABI | (a, thin) deterministic fixed-step game-engine libs; invariant "whole equal steps, render interpolation never feeds sim state" (crates `enaction-time`, trace semantics). Has deed, `abi.ipkg`, `verification/tests/EnactionEngineTests/AbiTests.idr`. Invariants stated and tested; no deep proofs seen.
- enterglide-ncc-137-k | placeholder | (c) reserved placeholder (knot topology / varying-constants idea); no implementation.
- evil-weevil | Zig + Idris2 + C ABI | (a, real) enemy-AI kernel. `src/interface/Abi/{Types,Layout,Affect,Exposure,Gen,Memory,Modes,Utility,Foreign}.idr` ~5000 lines; README: "seven ABI structs proved in Idris2", generated `ee.h`, two null hosts agree on three pinned digests. ABI-seam-sealing instance of "seams sealed and proven"; kernel behaviour itself naive.
- f117a-stealth-glider | JS | (a, bounded) Conway Life stealth puzzle; `VERIFICATION.adoc`, `KERNEL-DIVERGENCE.adoc`; checks are scripted exhaustive/bounded, not theorem-prover proofs.
- f19-stealth-glider | JS | (a, bounded) same family; `VERIFICATION.adoc` claim #4 "stream no-go lemma" via `src/verify8.mjs` (30 launch phases). Computational verification, not a prover.
- game-server-admin | Zig | (c) game-server config/admin tool; has PROOF-NEEDS.adoc only.
- hotchocolabot | Rust | (c) educational robotics platform (UAL).
- knot-rider | RSR template instance | (c) placeholder pun project; template stubs.
- megadog | Pony | (c) "ethical merge game with Mandelbrot dogtags".
- not-so-serious-software | meta repo | (c) umbrella of humour repos (submodules).
- planer-1 | placeholder | (c) reserved Stealth Glider slot (orbits on Riemann spheres), no implementation.
- pong-ping | Rust + Idris2 ABI | (a) 3D pong whose contact reverses the program direction; README argues reversibility needs an invertible metafunction (direction flip composed with integer momentum shear; `undo` computes predecessor, no snapshots). Idea documented; formal artefacts seen are the template ABI.
- pow-the-game | Rust/Idris2/Lua | (c) private research on game platforms as distributed compute; `verifier/src/{Verifier,Graph}.idr` small.
- project-ovine | template instance | (c) herding game to trial enaction-engine cognitive AI; README still the template header.
- proof-of-work | Rust (Bevy) | (c, with a) puzzle game with Z3 verification of solutions; `src/abi/ProofOfWork/ABI/Invariants.idr`. Z3 use is run-time puzzle checking, not repo verification.
- sr71-blackglider | Rust + Idris2 | (a, real-but-bounded) `MATHEMATICAL-CONTRACT.md` fixes physics as G_t = Life^t(G_0); `PROOF-ROADMAP.md` is an honest evidence ladder: all 512 local configs, all 65,536 4x4 worlds, 18 centre/count cases vs a separate Idris2 spec (exhaustive finite), Snark lane 240 generations (bounded trace). Explicitly says next gain needs a frozen mission spec. Good model of graded evidence labels.
- standard-operating-psychopathy | JS | (c) bunker sim.
- stealth-glider-ecosystem | manifest | (c) coordination hub for the seven-stage Stealth Glider chain; manifest only.
- tardis-rule-disruption | placeholder | (c) reserved slot 7.
- the-nash-equilibrium | JS/JSX | (c) 6X civilisation board game (AGPL, co-developed with son).
- thejeffparadox | Julia/Zig/HTML | (c) two AI personality fragments in structured dialogue; `papers/`, `engine/`. Not formal.
- universal-modding-studio | Rust/AffineScript/Idris2 + SPARK | (a, thin) modding toolchain; `abi/*.idr` (Level, Zones, Inventory, Multiplayer, ProvenBridge ...), `spark/src/ums_zones.ads`. 22 proof-ish files, no holes found by grep.
- x15-rocket-glider | placeholder | (c) reserved slot 4 (munitions/fuel on Conway field).

### hyperpolymath, Julia
- 0patch-lsa-sentinel | Ada SPARK/Zig/Idris2/Rust | (b)+(a) watcher for 0patch vs Windows LSA Protection conflict; `core-spark/src/sentinel-classifier.ads`; README: classifier "proved pure, total, postcondition-conforming with gnatprove", plus Idris2 totality, "SPARK anti-theatre checks". Narrow security-ops tool, not a general engineering-pain tool.
- ALDEx_bioc | R | (c) copy of ALDEx2 Bioconductor package (third-party; do not touch).
- ANCOMBC | R | (c) copy of ANCOM-BC (Huang Lin, third-party).
- AcceleratorGate.jl | Julia | (c) accelerator gating; PROOF-PROGRESS.adoc present, no proof files seen.
- Apodeixis.jl | Julia/Idris2 | (b)+(a) Julia verification toolchain, deed present. README honest: "current executable is a source-policy audit, not a formal verifier; POLICY CLEAN does not prove a contract". STATED/aspirational (Why3/SMT, Dedukti, Coq, Lean).
- Axiology.jl | Julia | (a, stated) value-theory formalism; PROOF-NEEDS/PROOF-PROGRESS, no proof files.
- Axiom.jl | Julia/Zig/Idris2 | (a/b) "provably correct ML": shape errors at compile time, `@prove` macro, certificates; 112 Julia files, 8 proof-ish files, no hole files. Concrete example of types preventing a classic ML error class (shape mismatch). Level of actual proof not verified by me.
- BowtieRisk.jl | Julia | (c) bowtie risk-analysis modelling.
- Causals.jl | Julia | (a, computational) causal inference; PROOF-NEEDS only.
- Cladistics.jl | Julia | (c) phylogenetics.
- Cliodynamics.jl | Julia | (c) cliodynamics modelling; 3 idr stubs.
- Cliometrics.jl | Julia | (c) economic-history metrics.
- CompositionalCounts.jl | Julia + Agda | (a) MN / Dirichlet-multinomial regression; `proofs/agda/{Softmax,CLR,BH,RefChange,ReferenceTaxon,Field,Vec,Fin,Nat}.agda`; no postulate found by grep. Statistical-error prevention (wrong reference taxon).
- CompositionalDA.jl | Julia + Agda | (a)+(b) native ALDEx2/ANCOM-BC; `proofs/agda/CompositionalDA/{CLR,BenjaminiHochberg/StepUp,PosteriorP,BiasModel,LogHom,DiscreteTails}.agda`, comment "no postulates anywhere in proofs/agda/CompositionalDA", `reject/{MissingReciprocal,FakeCLR,Postulate}.agda` negative controls.
- ContrastFamilies.jl | Julia | (b) parse R-style formula against column whitelist, derive tested contrasts, size the BH family so correction "cannot be run over the wrong m" (`FamilyMismatch` thrown). Types/guards against a silent statistical error.
- CoprocessorRuntime.jl | Julia/Idris2 | (a)+(b) host-side contract layer: session contracts, tropical resource grades, echo residues, epistemic receipts, CNO/OND claims; deed present. "Not a kernel runtime".
- EchoTypes.jl | Julia | (a) executable finite-domain companion to the Agda lib `hyperpolymath/echo-types` (Echo f y := Sigma(x:A), f x = y); numerically checks echo/residue/Landauer laws. The Agda claims are in another repo (not in my range).
- EpistemicTypes.jl | Julia + Idris2 | (a)+(b) per-row claims with receipts for taxonomic tables: receipt (standpoint tool/version/db/params, warrant, projection, SHA-256 digest) and status `:Factive/:Belief/:Collapsed/:SansFibre`. Direct analogue of provenance/overclaim control; deed present.
- ExactCounts.jl | Julia + Agda | (a)+(b) counts as unbounded integers, float accepted only if finite/integral/within 2^53, sums never wrap, "every rounding marked as a rounding"; 14 Agda files, `DecimalRounding(Adequacy).agda`, `reject/` controls incl. `OverflowEscapes`, `WrongDigit`. No README `docs` for ExactTests but similar.
- ExactTests.jl | Julia + Agda | (a) no README; `proofs/agda/ExactTests/{Binomial,Sums,Hypergeometric,FisherExact}.agda`, `reject/{WrongBinomial,TailIsTotal,Postulate}.agda`. Only Project.toml and proofs/ in tree: no Julia source yet.
- Exnovation.jl | Julia | (b, concept) models phasing out legacy practices; also holds legacy `Adjust/Dust/Intend/Must/Trust.a2ml`. Exnovation is the estate's drift-removal idea, but the package is modelling code (src/JSI.jl), not a drift tool.
- FirmwareAudit.jl | Julia | (c) firmware audit; skeleton.
- HackenbushGames.jl | Julia | (c, maths) combinatorial game theory toolkit (computational, tested).
- HardwareResilience.jl | Julia | (c) 10% complete per its badge.
- Hyperpolymath.jl | Julia | (c) umbrella package.
- InvestigativeJournalism.jl | Julia | (c).
- JuliaKids.jl | Julia | (c) kids coding.
- JuliaPackageSpitter.jl | Julia + Agda | (b)+(a) package skeleton generator; rule repo name = package name + ".jl" proved in `proofs/agda/PackageNaming.agda` (injective, prefix-unique, round trip), plus `CanonicalIdentity`, `IdentifierCharset`, `RetiredNames`; re-applied per PR by CI job "GATE: Package identity" (`.github/workflows/proof-gates.yml`); `tests/trusted-base-fixtures` negatives. Template/identity drift target. Real, small.
- KnotTheory.jl | Julia | (c, maths) computational knot theory (PD data, polynomial invariants, Reidemeister); tested, not formal.
- LowLevel.jl | Julia | (c).
- MacroPower.jl | Julia | (c) 20% badge.
- MetaManifold-WebUI | Julia/TS | (c) web UI for a statistics tool (fork-governance text in README is generated PR boilerplate); `proofs/` dir exists; TS present (policy departure, grandfathered category).
- PRComms.jl | Julia | (c).
- PolyglotFormalisms.jl | Julia | (b, stated) Julia reference of the aggregate-library overlap functions. README: "Nothing in this repository is formally verified yet ... tested-only". Honest labelling.
- PostDisciplinary.jl | Julia | (c).
- Protoctist.jl | Julia | (b) typed lineages for PR2 (9 ranks) / SILVA (7 ranks), refuses to mix ladders, rolls up evidence; deed present. Domain tool; uses the same type family.
- QuantumCircuit.jl | Julia | (c, maths) quantum circuit simulation.
- ResidualEvidenceTypes.jl | Julia | (a) formalises what a residual does and does not establish given worlds that could have produced it; deed present. Type-theoretic model of overclaim (nonzero residual does not equal presence).
- SMTLib.jl | Julia | (b) SMT-LIB2 interface (Z3, CVC5, Yices); utility, no proof corpus.
- ShellIntegration.jl | Julia | (c).
- SiliconCore.jl | Julia | (c).
- Skein.jl | Julia | (c, maths) knot database engine.
- SoftwareSovereign.jl | Julia | (b, weak) meta package manager over dnf/apt/flatpak/asdf enforcing policies. No README. Closest to dependency policy.
- TradeUnionism.jl | Julia | (c).
- ViableSystems.jl | Julia | (c) VSM and SSM.
- ZeroProb.jl | Julia | (a, computational) measure-zero events; PROOF-NEEDS only.

### hyperpolymath, other
- absolute-zero | Rust/Agda/Idris2/Coq/Lean | (a) CNO (certified null operations) and OND (observational null disclosure). `PROOF-STATUS.adoc` is candid: six-prover gate (Coq, Agda, Lean, Z3, Isabelle, Mizar) is HISTORICAL; now only Agda, bounded Z3 and Idris2 ABI active; `Layout.idr:254` discharge uses `believe_me` documented against a deleted unsound postulate (absolute-zero#27). Gate rule: absent prover is a failure, not a skip.
- academic-workflow-suite | Rust/Elixir | (c) academic marking assistant stack.
- accessibility-everywhere | AffineScript/JS/PHP | (c) accessibility as a ranking factor; has PMPL text while README says MPL-2.0 (licence inconsistency, flag only).
- action-trust-layers | Rust (~960 lines) | (b) DANE/TLSA-inspired layered trust for GitHub Actions pinning. Problem: a SHA-pinned composite action may reference a nested moving tag, which "all-SHA" rules reject and the consumer cannot pin (hyperpolymath/ubicity casket-pages.yml, PR #38). Layers: anchor (trust owner incl. transitive), provenance, and so on. Status: design/v0; `src/{model,parse,policy,resolve,report}.rs`. Direct CI-supply-chain, safe-vs-unsafe-bump relevance.
- aerie | Zig/Idris2 | (c) cyber-focused network diagnostic suite; `src/abi/{Forensics,Gnosis}.idr`.
- affinescript-vite | AffineScript | (c) retro driving game demo (Test Drive III style).
- affinescript | OCaml/AffineScript/Coq | (a)+(b) affine-typed language compiling to typed-wasm. `formal/*.v` 20 Coq files (QttTyping, QttDynamic, AffineUsage, P2_Progress, P3_BorrowSound, K1_CodegenPreservation, F1_TransformerPreservation, ...); docs/PROOF-NEEDS.adoc: "axiom-free Coq core ... no full-language theorem is discharged yet", CI gate `coq-proof-gate.yml` on Coq 8.20.1 vs documented 8.18 pin (unreconciled). Target of estate migration (TS/ReScript to AffineScript).
- affinescriptiser | Rust | (b, scaffold) wraps Rust/C/Zig code with affine guarantees; README "Pre-alpha / Scaffold", about 1850 lines.
- aggregate-library | Elixir/Julia/AffineScript | (b/a) methods repo: specify, test and stress-test a tiny cross-language "overlap" library; `SPEC_FORMAT.adoc`, `COMPOSITION-GUIDE.adoc`, `REVERSIBILITY.adoc`. Equivalence-as-identity testing across implementations; status experimental.
- alloyiser | Rust | (b, early) extracts entity relations from OpenAPI/GraphQL/proto into Alloy 6 models; ~2300 lines Rust; "Idris2 ABI" template.
- ambientops | Elixir/Rust/Zig | (c) hospital-model ops framework ("trustworthy system help"), hybrid monorepo; large.
- anamnesis | Julia/Elixir | (b) conversation knowledge extraction/reconciliation for multi-LLM dev workflows (mixed-project threads, lost context, artifact fragmentation). Early-stage research prototype. Relevant to AI drift/lost context.
- anvomidav | docs only | (c) language for figure-skating choreography (site/, no src).
- anvomidaviser | Rust | (c) ISU notation to Anvomidav; scaffold.
- anytype | Idris2 | (a) reference kernel for systemet (Equality Theory): parameterised type checker, "discipline chosen by choosing the algebra at the resource layer"; renamed from "EveryType" because the name over-claimed. Deed, `anytype.ipkg`, Idris2 kernel in `src/kernel`, tests in `verification/tests/kernel`. Central to the type-family idea. Extent of proofs not run by me.
- arghda-core | Rust (~47 files) | (b) Agda proof-workspace manager: four-state triage (inbox/working/proven/rejected as file moves), lint pack for "silent failure" (Agda appears to succeed but file not in verified suite), import-graph DAG, JSON event stream; "never proves anything itself". Extracted from echo-types 2026-05-30. Directly a "no silent green" tool.
- asdf-tool-plugins | Bash | (b, weak) collection of ~220 asdf plugins (tool installation/versions) incl. `asdf-control-tower`, `asdf-augmenters`; each plugin dir contains zig/idr template files (567 each).
- aspasia | Matlab/Julia/Logtalk | (b) audits StatistEase (LLM routes questions to Julia functions) by independent re-computation (`src/verification/{descriptive,inferential,nonparametric}_verify.m`), checks "was it the right test"; "a green verdict is a second opinion, not proof". Research prototype; neurosymbolic exactness idea.
- atoma | Zig/Idris2/Agda/Z3 | (a)+(b) source-bound verification for a closed Zig subset; deed; `verification/atoma/agda/{Core,Soundness,Bv}.agda`, 16 `.smt2`, Idris2 specs, ECHIDNA + coqchk replay. README: "not yet a general sound verifier ... evidence INCOMPLETE (Warrant)".
- atsiser | Rust | (b, early) analyses C for memory-critical patterns (malloc/free, buffers) toward ATS; "Codebase in progress".
- autoformal-fidelity | Agda | (a) does formal F say what informal S says? `src/Fidelity/Crossing.agda` four theorems (round trip rules out collapses, blind to additions with computed phantom witness, round trip + coverage = bijection, fidelity as mutual access); `tests/reject/`; "semantic fidelity is not decidable". Aimed at LLM autoformalisation error (fabricated structure). Deed present.
- bactrian | docs | (a, aspirational) planned verification suite for restricted OCaml, BEAM actor protocols, Idris2/Zig FFI boundaries via Why3/SMT/Apalache. README: "no proof engine ... no OCaml code, no Dune project, no Why3 file". ASPIRATIONAL.
- bebop-ffi | Zig/Idris2 | (c) stable C ABI for Bebop serialisation; still has `*.scm` state files (STATE.scm etc.) which are legacy.
- betlang | Rust/Racket | (a, stated) probabilistic/ternary language; `PROOF-STATUS.adoc`: 15 obligations, 5 done (TP), 10 remaining; `docs/proof-debt.adoc`.
- betlangiser | Rust | (b, early) wraps deterministic values in Betlang distributions; pre-alpha.
- bgp-backbone-lab | Bash/Nickel | (c) BGP lab topologies.
- bitfuckit | Ada | (c) Bitbucket CLI.
- blocky-writer | AffineScript | (c) Firefox PDF form filler.
- bofig | Elixir | (c, concept) evidence graph for investigative journalism with PROMPT epistemological scoring; Phase 1 PoC.
- bofj-kitt | Zig/Idris2 | (c) pre-alpha scaffold of BoJ developer extension kit.
- boinc-boinc | Rust/Elixir/Lean | (a, partial) Oblibeny language whose property proofs are to be crowd-sourced via BOINC; `lean-proofs/Oblibeny/{Syntax,Semantics,Properties/{Termination,PhaseSeparation,ResourceBounds}}.lean`. Proof status not run by me.
- boj-server-cartridges | Zig/JS/Elixir | (c) cartridge source tree for BoJ MCP server.
- boj-server | Elixir/Zig/JS | (b, weak) single MCP endpoint for GitHub/GitLab/Cloudflare/etc. plus multi-agent coordination (`coord_*`); `Check.idr`. Coordination is related to agent clash but not a typed merge tool.
- bqniser | Rust | (b, early) rewrites array patterns to BQN.
- branch-newspaper | docs | (c) concept with policies.
- bunsenite | Rust/Zig | (c) Nickel parser with FFI bindings.
- cafescripto | AffineScript | (c) CoffeeScript-syntax face of AffineScript; brand surface only.
- candy-crash | Gleam | (c) ambient-computing vehicle training.
- canonry | Agda | (a) calculus of strided 1D domains plus weakest-precondition core for Chapel array programs; `verification/proofs/agda/Canonry/Core.agda`, theorems `substA-sound`, `substB-sound`, `substArrA-sound`, `substArrB-sound`; M0 done, parked.
- cargo-zigbuild | Rust | (c) fork of messense's cargo-zigbuild (third party, do not touch); has empty `proofs/` dir and `pyproject.toml` (Python departure in a fork).
- casket-ssg | Haskell | (c) static site generator.
- cccp | docs | (c) Campaign for Cooler Coding: philosophy behind RSR.
- chancel | Rust placeholder | (a, aspirational) planned Chapel verifier over Canonry; "No Chapel verifier code yet; only a placeholder crate".

## Constructs list (a and b) is returned in the structured output.
