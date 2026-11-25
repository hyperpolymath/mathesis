# External research: classical and near-classical type theory against recurring engineering pain

Scope: merge conflicts, clashes, trivial syntax failures, AI/LLM errors, unsafe dependency bumps,
CI cost and flakiness, template drift, licence/metadata drift.
Date of research: 2026-11-24. Read-only. Nothing in any repository was changed.

## 0. Method, evidence grades, limits (read first)

How this was produced: web search plus direct reads of primary pages and papers. Ten papers were
downloaded and converted with `pdftotext`, and the numbers quoted from them were read from the
extracted text (files under the session scratchpad, not kept). Everything else comes from a project's
own documentation or from a search summary; each item says which.

Evidence grades used below. They describe the *external* source, not the estate:

| Tag | Meaning |
|---|---|
| **MECH** | The source reports a machine-checked metatheory or proof (Agda, Coq/Rocq, Isabelle). I did **not** open or re-run any proof file, so in the programme's terms this is STATED-as-mechanised, not PROVED by me. |
| **PEER** | Claim made in a peer-reviewed paper that I read (text extracted) or whose abstract I read. |
| **DOC** | Claim made by the project's own documentation or announcement. Self-reported. |
| **SELF-BENCH** | Number from the project's own benchmark, not independently evaluated. |
| **MEM** | From memory. Not verified online in this session. Treat as a lead, not a fact. |
| **INFER** | My own inference connecting two verified things. Not a claim any source makes. |

Things I looked for and did **not** find or could not confirm are collected in section 15. Read that
section before relying on any single figure.

Estate facts used for mapping come only from: the sibling findings files in this directory
(`merge-drift.md`, `trivial-syntax.md`, `bumps.md`, `ci-cost.md`, `ai-errors.md`: headings and the
passages quoted below), the CLAUDE.md files shown to this session, and one `rg` scan I ran over
`/home/user/estate` (section 14.1). I did not audit the estate; other agents own that.

---

## 1. One-table overview

"Guarantee" is the strongest thing the technique actually promises. "Does not give" is the gap that
matters for the pains listed.

| # | Technique | Pain it addresses | Guarantee | Does not give | Maturity |
|---|---|---|---|---|---|
| 1 | Structured (AST) merge: Mergiraf, Spork, jDime, LastMerge, d3j | merge conflicts | Fewer spurious conflicts; result parses (when tool checks it) | Semantic compatibility; cross-file conflicts; correctness of the merge (several tools emit wrong merges) | Mergiraf usable (33 languages, DOC). Research tools Java-only. |
| 2 | Entity-level merge: Weave | merge conflicts, agent clashes | Merge by named entity; re-parse check with line fallback | Independent evaluation; anything below entity granularity | Young (v0.3.x, SELF-BENCH only) |
| 3 | Structural diff: difftastic | review noise | Never calls two syntactically different files equal (falls back to lines on parse error) | Merging; applicable patches | Mature as a viewer |
| 4 | Type-safe structural diff: Miraldo and Swierstra, truediff | merge at AST level | Patches are well-typed by construction | A practical merge tool; authors' own evaluation suggests restricting to linear patches | Research |
| 5 | Patch theory: Darcs, Pijul, categorical patches | merge order, cherry-pick, conflicts as states | Independent patches commute; merge is a pushout; conflicts are first-class objects | Token or AST granularity (line-based); semantic safety; ecosystem | Darcs mature but niche; Pijul still beta at last found release |
| 6 | Homotopical patch theory | laws of patches for free | Every operation respects patch laws by construction (functoriality) | An implementation; non-invertible patches; realistic repositories | Paper only; authors had not mechanised it |
| 7 | Tree CRDT with typed conflicts: Grove | merge conflicts, clashes | All edits commute (theorem); every state, including conflicted ones, has a static meaning | A production editor; sequence data; UX | Research, MECH (Agda) |
| 8 | Typed holes and total error recovery: Hazelnut, Hazelnut Live, marked lambda calculus | trivial syntax and type errors blocking tooling | Every editor state is well-typed-with-holes and runnable; errors localised, never cascading | Applies to Hazel, not to mainstream languages | Research, MECH (Agda) |
| 9 | Obligation-based parsing: tylr, tall tylr | "missing semicolon" class | Parse success guaranteed over all inputs, by inserting obligations | Grammar coverage beyond operator-precedence style; mainstream adoption | Research (OOPSLA 2025) |
| 10 | Error-recovering parsers: CPCT+, resilient LL, tree-sitter | same | Parser continues; minimal-cost repairs enumerated | Knowing which repair the author meant | CPCT+ in a Rust LR parser; tree-sitter ubiquitous |
| 11 | Projectional editors: JetBrains MPS | syntax errors cannot be typed | Unparseable text is unrepresentable | Text tooling (git, grep, LLMs); needs own diff/merge | Mature product, narrow adoption |
| 12 | Type-constrained LLM decoding | AI compile errors, hallucinated members | Output is well-typed on termination | Termination (generation loops); functional correctness; needs logits | Research (PLDI 2025), TypeScript only |
| 13 | Refinement and liquid types: LiquidHaskell, Flux | regular errors (bounds, invariants) | SMT-checked invariants at compile time | Anything outside decidable logic; trusted `assume`s | LiquidHaskell mature; Flux research-grade for Rust |
| 14 | Gradual typing | migrating untyped config and code | Gradual guarantee: removing annotations never breaks a working program | Performance (sound variants can be very slow) | Mature idea; Nickel uses it for config |
| 15 | Typestate and session types | protocol misuse, pipeline ordering | Illegal state transitions do not compile; deadlock freedom for well-typed sessions | Linearity in Rust (values can be dropped); no CI system found that uses them | Typestate pattern mainstream in Rust; session types research |
| 16 | Effect and capability types: Koka, Scala capture checking, Capslock | unsafe dependency bumps | An unlisted effect cannot occur; a bump that adds a capability is visible as a type or report diff | Whether an existing capability is used maliciously | Koka research language; Scala CC experimental; Capslock Go-only |
| 17 | Row types and schema compatibility: buf, Avro, Cambria | schema and metadata evolution | Mechanical classification of a schema change as compatible or breaking | Meaning changes with the same shape | buf and Avro production; Cambria research |
| 18 | Semver as a derived type: Elm, cargo-semver-checks, Unison | unsafe vs safe bumps | Version bump is computed from the API diff, not asserted | Behavioural change; type-level changes (cargo-semver-checks has no type info yet) | Elm production since 2010s; c-s-c 245 lints; Unison 1.0 (Nov 2025) |
| 19 | Build systems a la carte, hermetic builds | CI cost, flakiness | Minimality and early cutoff are definable and achievable; cache hits are sound if inputs are complete | Hermeticity of the tasks themselves; test nondeterminism | Bazel, Buck2, Shake, Nix, Guix production |
| 20 | Lenses, edit and delta lenses | template drift, config sync, metadata projection | Round-trip laws (GetPut, PutGet) hold by construction | Many real transformations are not lenses; lossy directions | Augeas production; Boomerang, Cambria research |
| 21 | Ornaments, proof repair | refactoring, datatype change, proof drift | Lifted code provably related to the original; proofs ported across type equivalences | Changes that are not ornaments or equivalences; bug fixes | Research (POPL 2018, PLDI 2021) |
| 22 | Typed config: Dhall, Nickel, CUE | config errors, drift, clashes | Dhall: total, normal forms, semantic hashes. CUE: order-independent unification. Nickel: gradual types plus contracts plus merge | Each trades expressiveness differently (section 13) | All three production-usable |

---

## 2. Merge: from lines to trees to patches to CRDTs

### 2.1 Base rates worth knowing before choosing a remedy

**Brun, Holmes, Ernst, Notkin, "Proactive detection of collaboration conflicts" (ESEC/FSE 2011).** PEER,
text read. Nine open-source systems, 3.4 million lines. From the extracted text:

- "16% of all merges required human effort to resolve textual conflicts" (table total: 3,562 merges,
  564 textual conflicts).
- For the three systems with runnable tests (Git, Perl5, Voldemort): "76% of merges completed cleanly,
  16% of merges resulted in a textual conflict, 1% of merges resulted in a build failure, and 6% of
  merges resulted in a test failure."
- "The 266 textual conflicts reported by the version control system only represent 67% of all
  conflicts." So one conflict in three was a *higher-order* conflict that the VCS merged silently.
  (The paper's next sentence words this as "33% of the 399 merges that the version control system
  reported as being a clean merge"; the arithmetic, 266 + 133 = 399, shows 399 is the count of all
  conflicts. I use the first wording.)
- Conflicts "persist, on average, for 10 days (with a median conflict persisting 1.6 days)."

Consequence for any type-theoretic remedy: **a perfect syntactic merge tool addresses at most about two
thirds of conflicts**. The remaining third needs a build or a type check or a test after the merge.

**LWN, "Mergiraf: syntax-aware merging for Git" (Daroc Alden, 31 Oct 2025).** DOC-level journalism, read.
On the Linux kernel history: 7,415 merge commits conflicted under Git's default `ort`; Mergiraf "fully
resolved 428 of them", 6,987 still conflicted; "a much larger fraction" were partly resolved. That is
5.8% fully resolved (428 / 7,415). A Mergiraf author commented that the tool often falls back to
line merging for C because macros defeat the parser.

**Cavalcanti, Borba, Seibt, Apel, "The Impact of Structure on Software Merging" (ASE 2019).** PEER, via
search summary only. Over 40,000 merge scenarios from over 500 projects: semistructured merge reports
more false positives, structured merge has more false negatives.

**Duarte, Borba, Cavalcanti, "LastMerge" (arXiv 2507.19687, July 2025).** PEER preprint, text read.
5,983 merge scenarios from 1,116 projects. "LastMerge reports 15% fewer false positives than jDime
while Mergiraf misses 42% fewer false negatives than Spork." Generic (tree-sitter) tools differ from
Java-specific ones in about 10% of scenarios, mostly from configuration. But LastMerge "exhibits
nearly three times more aFNs than jDime" (added false negatives: conflicts silently missed).

**Mori and Hashimoto, "On the Correctness of Software Merge" (arXiv 2607.07987, July 2026).** PEER
(states it is an accepted manuscript), text read. This is the most relevant recent paper for the
programme because it gives merge a *checkable correctness criterion*:

- A conflict-free merge is correct iff it is **parsable** and **universal**: it "incorporates all and
  only the edit operations occurring in each branch while ensuring that edits common to both branches
  are applied only once. This requirement can be precisely defined using the notion of pushouts in
  category theory."
- 43,774 file merge scenarios from 76 Java projects. Table I (conflict-free merges / not well-parsed /
  non-universal):

  | Tool | CFM | non-WP | non-Univ |
  |---|---:|---:|---:|
  | git-merge | 31,533 | 0 | 40 |
  | jfstmerge | 31,680 | 76 | 171 |
  | jdime | 36,992 | 89 | 128 |
  | automergeptm | 38,586 | 597 | 1,080 |
  | intellimerge | 37,541 | 19,565 | 5,265 |
  | spork | 39,361 | 213 | 1,573 |
  | mastery | 39,098 | 9 | 270 |
  | d3j (theirs) | 39,541 | 0 | 0 |

- Even plain `git merge` produced 40 non-universal conflict-free merges (duplicated code where both
  sides inserted text that happened to match).
- Against 2,582 developer-resolved merges: "711 merge results recorded in the repositories were judged
  incorrect according to our correctness criteria. Fifteen were syntactically invalid, such as cases
  where conflict markers were left unerased."
- Limit they state: conflict rules are "deliberately conservative"; the criterion is purely syntactic.
  Mergiraf and Weave are not in this comparison. d3j is Java-only.

Takeaway: "structured merge" is not automatically safer. Several structured tools emit *more* silently
wrong merges than line merge. The gain comes from pairing the merge with a checkable criterion.

### 2.2 Tools

**Mergiraf** (mergiraf.org architecture page, read; DOC).
- What: Git merge driver in Rust over tree-sitter. "broadly follows the architecture of" Spork. Matching
  by "the GumTree classic algorithm"; trees encoded as parent-child-successor triples and merged.
- Fast mode: line merge first; only the remaining conflict hunks are re-solved structurally.
- "Commutative parents": per-language declarations that a node's children are order-free (Rust struct
  fields yes, C struct members no, per LWN). Children with the same *signature* are grouped and marked
  as a conflict.
- Fallbacks: "If a parsing error occurs in any of the three revisions, the algorithm aborts and falls
  back on line-based merging."
- Stated hazards: left-right matching kept conservative because "any false positive in this matching
  can have quite detrimental effects on the merged result"; delete/modify needs an explicit check
  because "it could be that the deleted elements have actually been moved elsewhere". LWN reports a
  known bug with Rust `#[repr(...)]` (field order matters there but the parent is declared commutative).
- No formal correctness statement on the page. Licence GPL-3 per LWN. 33 languages per LWN.
- Limit: per-file. A reader comment on LWN makes the point that logical conflicts span files.

**Weave** (Ataraxy-Labs, README via search summary; DOC and SELF-BENCH).
- What: entity-level merge (functions, classes) by identity "name + type + scope", tree-sitter via
  `sem-core`; re-parses the result and falls back to line merge if the AST is invalid. Also offers
  agents an entity "claim" layer through an MCP server, with the merge driver as fallback.
- Claimed: 31/31 clean on its own 31 synthetic scenarios versus 15/31 for git. Synthetic, self-run.
- Limit: no independent evaluation found. Identity by name means a rename plus an edit is the hard case
  (INFER). Version found 0.3.6.

**difftastic** (README via search; DOC). A viewer, not a merger: "AST merging is a hard problem that
difftastic does not address." Output "does not generate patches that you can apply later". Falls back
to line diff on parse error so it "never claims that two syntactically different files are the same".
Treats order as significant.

**GumTree** (Falleri et al., ASE 2014). MEM. The matching heuristic under Mergiraf and Spork. It is a
heuristic: no optimality or correctness guarantee.

### 2.3 Type-safe structural diffing

**Miraldo and Swierstra, "An Efficient Algorithm for Type-Safe Structural Diffing" (ICFP 2019)**, tool
`hdiff`. PEER via abstract and author's page. Patches are typed by the datatype they change, so an
ill-formed tree cannot result. Abstract: patches "can often be merged automatically, even when
existing technology has failed". The author's own later note: the "empirical evaluation ... over a
dataset of real conflicts suggests a good line of future work is to restrict hdiff to handle only
linear patches". **Erdweg, Szabo, Pacak, "Concise, Type-Safe, and Efficient Structural Diffing"
(PLDI 2021)**, `truediff`: PEER, title and venue only.
Limit: these are diff algorithms with merge as a secondary use; no maintained merge driver was found.

### 2.4 Patch theory

**Darcs.** PEER and MEM mixed. Patches have inverses and a partial *commutation* operation; merge and
cherry-pick are derived from commutation. Formalisations: Sittampalam et al. 2005 (axioms), Roundy 2009,
Jacobson 2009 (inverse semigroups), Dagit 2009 (Haskell types enforce some patch-theory properties),
Camp (Coq, Lynagh 2012). All of these are listed in the related-work section of the homotopical paper,
which I read. Known cost: Darcs 1's merge "could take exponential time in the number of conflicting
patches"; Darcs 2 reduced it, "although not resolved completely" (Wikibooks and Wikipedia via search).

**Mimram and Di Giusto, "A Categorical Theory of Patches" (arXiv 1311.3903, ENTCS 2013).** PEER, text
read. "we introduce a theoretical model, which is defined abstractly by the universal property that it
should satisfy". Files and patches form a category; merge of two coinitial patches is a **pushout**;
"Since two patches can be incompatible, such a pushout does not necessarily exist"; the fix is the
**free completion under finite colimits**, whose objects are "finite sets labeled by lines equipped
with a transitive relation". A conflict is therefore an *object* (a file in a conflicted state), not a
failure. Stated future work: multiple files, moves, structured data ("xml trees"), cherry-picking,
branches, inverses, and "algorithmic issues". So the theory as published covers one text file with
line insertion and deletion.

**Pijul** (manual theory page, read; DOC). A repository is a directed graph of lines; changes add
vertices or relabel edges alive to dead; "this system is append-only". Independent changes commute.
Conflicts are graph shapes (two alive vertices with no order; cycles; "zombie" vertices) and survive
in the repository until a later change resolves them. The page says "Pijul implements a conflict-free
replicated datatype (CRDT)". A Pijul forum post (via search) says Pijul does not literally use the
free cocompletion of the paper. Maturity: last release I could find is 1.0.0-beta.9 (Feb 2024, via a
package listing); beta announced Jan 2022 with "the formats won't change". A stable 1.0 was not found.
Limits: line granularity (INFER: it removes order-dependence of merges, not the adjacent-line false
conflicts that structured merge targets); Git interop and hosting ecosystem are thin (MEM).

**Angiuli, Morehouse, Licata, Harper, "Homotopical Patch Theory" (JFP 26, 2016).** PEER, text read.
- Idea: a patch theory is a higher inductive type: "points represent patch contexts, ... paths
  represent patches ..., paths between paths represent patch laws". Interpretations are maps out of
  the HIT; "Because all functions in homotopy type theory respect paths, such implementations, indeed,
  all patch operations, like optimizations or merges, automatically satisfy the patch laws."
- Merge: takes a span `(f1, f2)` and returns a cospan `(g1, g2)` with `g1 . f1 = g2 . f2`, required
  to be symmetric. Honest remark: "It is always possible to define a total merge function, since for
  any span we may give merge(f1, f2) = (!f1, !f2), the reconciliation that undoes both changes." The
  laws alone do not make a merge *good*.
- Limits the authors state: "we have not yet implemented the examples in this paper in a proof
  assistant"; "Because a computational interpretation of homotopy type theory is work in progress,
  there is no complete operational semantics that can evaluate the programs in this paper". All
  patches are invertible (paths), so information-losing edits need indexed contexts or histories; the
  paper says functoriality "complicates the definitions of patch histories".
- MEM: Cubical Agda has since given univalence and HITs computational content, so the "no operational
  semantics" limit is weaker today. I did not find a cubical mechanisation of this paper.
- INFER, relevance to the estate's doctrine item 13 ("equivalence as identity") and its Agda proof
  policy (`--safe --without-K --cubical-compatible`): the paper's central move is exactly "a law is a
  path, so anything you can write respects it". That is the pattern to borrow, at small scale, for
  estate-specific patch kinds (a deed-clause edit, a pin bump) rather than for whole-repository VCS.

### 2.5 CRDTs, and the one that types its conflicts

**Gomes, Kleppmann, Mulligan, Beresford, "Verifying Strong Eventual Consistency in Distributed Systems"
(OOPSLA 2017).** MECH (Isabelle/HOL), via abstract. An abstract convergence theorem plus verified
RGA, OR-Set and counter. Limit (my reading, not the paper's words): convergence says replicas agree,
not that the agreed state is what anyone meant.

**Adams, Griffis, Porter, Satish, Zhao, Omar, "Grove: A Bidirectionally Typed Collaborative Structure
Editor Calculus" (POPL 2025).** MECH (Agda), text read.
- "patches are derived directly from the log of the developer's edit actions and all edits commute,
  i.e. the repository state forms a commutative replicated data type (CmRDT)". Theorem 3.2 is
  commutativity of patch commands. Mechanism: "edge deletion is permanent and vertex insertion is
  permanent"; realised edges and vertices form grow-only sets.
- Conflicts become structure: the state is a graph, decomposed into a "grove" of terms with explicit
  conflict nodes (local conflicts and relocation conflicts), and "all possible editor states,
  including editor states with various kinds of unresolved conflicts, are semantically meaningful".
  The type system (marked, bidirectional, gradual) types conflicted programs.
- Stated limits: "This paper focuses on the core theoretical underpinnings"; UX for "non-conflicted but
  heuristically attention-worthy merges" is future work; integration into Hazel has not happened
  ("its editor component has been evolving so rapidly as to prevent experimentation"); string
  literals and other sequence data need sequence CRDTs, also future work.
- Why it matters here: it is the only source found where **merge cannot fail and a conflict is a typed
  value rather than a broken file**. Compare `merge-drift.md` section 2: conflict markers committed
  into `.gitignore`, `LICENSE` and `.adoc` files and found weeks later because "nothing fails loudly".
  Conflict-as-typed-value is the principled cure for that class. Text markers in an unparsed file are
  the opposite extreme.

### 2.6 Semantic conflicts

**Sousa, Dillig, Lahiri, "Verified Three-Way Program Merge" (OOPSLA 2018)**, tool SafeMerge. PEER via
abstract. Proves *semantic conflict freedom* of a merge with a 4-way AST diff into a shared program
with holes plus compositional verification; 52 real merge scenarios. Limit: research prototype, small
evaluation, per-method reasoning.

### 2.7 What this section implies for the pains

- Syntactic merge tooling is worth having, and cheap, but bounded: about 6% of kernel conflicts fully
  resolved; about one third of real conflicts are not textual at all.
- The durable ideas are two. (a) **A merge has a specification** (pushout / universality + parsable),
  so a merge result can be *checked* after the fact, including merges made by an LLM or a human.
  (b) **A conflict is a value in the format**, not markers in text.
- For formats the estate owns (deed, k9, KYAML, I-JSON/JCS), (a) and (b) are reachable without any new
  VCS: a canonical serialisation removes formatting conflicts (JCS already does this for JSON per the
  CLAUDE.md shown to this session), and a per-format merge driver that merges the parsed value can
  refuse to emit anything unparsable. INFER; no estate code was read to check what exists.

---

## 3. The "missing semicolon" class: holes, obligations, recovering parsers, projectional editors

### 3.1 Why the problem persists

- For ordinary grammars "most textual edit states do not successfully parse" (tall tylr paper,
  introduction, citing earlier studies). PEER, text read.
- A parser must *guess* a repair, and the guess is ambiguous. Diekmann and Tratt, "Don't Panic! Better,
  Fewer, Syntax Errors for LR Parsers" (ECOOP 2020; PEER via abstract): CPCT+ finds the **complete set**
  of minimum-cost repair sequences because one repair is often not the author's intent, and a poor
  choice causes cascading errors. On 200,000 invalid Java programs it repaired 98.37% within 0.5 s
  and reported 435,812 error locations where panic mode reported 981,628.
- matklad, "Resilient LL Parsing Tutorial" (2023; read): "incomplete code is the ground truth, and only
  the user knows how to correctly complete it". Resilient parsing "is related, but distinct from error
  recovery and repair". On choosing recovery sets for general grammars: "I don't know the answer to
  this question".
- Language design is the other half. MEM: Go inserts semicolons in the lexer by a fixed rule;
  JavaScript's automatic semicolon insertion is a known hazard; canonical formatters (gofmt, rustfmt)
  remove layout as a degree of freedom. None of that helps formats with no parser at all.
- The estate-specific point, from `trivial-syntax.md` section 1: genuine typo-scale slips are "27 OWN
  commits"; "The dominant pain is mechanical-tool-generated structural damage to config files (YAML
  workflows), repaired weeks to months later." So the estate's "semicolon" problem is mostly **a
  generator writing text for a format it does not model**, and a gate that cannot fail. Editor-side
  cures below help humans; the generator-side cure is "construct the value, then print it" (section
  13) plus "parse what you printed before committing".

### 3.2 Typed holes and total recovery (Hazel family)

| Work | Venue | What is guaranteed | Grade |
|---|---|---|---|
| Hazelnut (Omar, Voysey, Hilton, Aldrich, Hammer) | POPL 2017 | Edit actions keep the program well-typed-with-holes; type-inconsistent parts are wrapped in non-empty holes | PEER via search; Agda mechanisation is MEM |
| Hazelnut Live, "Live Functional Programming with Typed Holes" | POPL 2019 | Evaluation can "continue evaluation past holes while maintaining type safety"; feedback "for every reachable editor state"; metatheory mechanised "using the Agda proof assistant" | MECH, abstract read |
| "Total Type Error Localization and Recovery with Holes" (Zhao et al.) | POPL 2024, Distinguished Paper | The marked lambda calculus: every program, however ill-typed, gets a marked, typed form; no error hides another; mechanised in Agda | MECH via programme page |
| tylr (Moon, Blinn, Omar) | TyDe 2022 | Tile-based editing with text-like flexibility | PEER via search |
| "Gradual Structure Editing with Obligations" (teen tylr) | VL/HCC 2023 | Temporary disassembly of structure with *obligations* that guarantee reassembly | PEER via search |
| "Syntactic Completions with Material Obligations" (tall tylr) | OOPSLA 2025 | A parsing calculus that "completes input tiles with additional obligations such that it can be parsed into a well-formed term, with success guaranteed over all inputs" | PEER, abstract read |

What "obligation" means: a generalisation of a hole that covers "missing operands, operators,
delimiters, and sort transitions". A missing semicolon or bracket is not an error state; it is a term
with an outstanding obligation that the tools can see, count and rank ("minimizing obligations").

Limits: all of this is Hazel (an Elm/ML-like research language). tall tylr is built on a
generalisation of operator-precedence parsing; its user study found "both points of positivity and
interesting new avenues for future work". No port to YAML, TOML, or a mainstream language was found.

INFER: obligations are a good fit for **generated config and metadata**. A generator that cannot fill a
field emits a typed obligation instead of a placeholder string. The estate's `trivial-syntax.md` lists
"template placeholders" as its own class (G13); a hole with a type is a placeholder that a gate can
count.

### 3.3 Projectional editors

JetBrains MPS stores the AST and projects it; unparseable text cannot be stored. Evidence:
- Berger, Voelter et al., "Efficiency of Projectional Editing: A Controlled Experiment" (FSE 2016; PEER
  via abstract summaries): efficient "for basic-editing tasks"; "more complex tasks require substantial
  experience and a better understanding of the abstract-syntax-tree structure"; a trade "between fewer
  typing mistakes and an increased complexity of code editing".
- Voelter et al., "Towards User-Friendly Projectional Editors" (SLE 2014): language-composition
  flexibility "comes with serious usability costs" that can be mitigated.
- Voelter, Warmer, Kolb (IEEE Software 2015): diff and merge "must be supported using the concrete,
  projected syntax"; MPS does this and is used with git.

Limits: the stored form is not human-editable text, so every text tool (grep, sed, line diff, and
today's LLM agents) is off the table unless a projection is built for it. INFER: the tylr line of work
exists precisely to get the projectional guarantee without giving up text.

---

## 4. AI/LLM errors: what types can and cannot do

**Mündler, He, Wang, Sen, Song, Vechev, "Type-Constrained Code Generation with Language Models"
(PLDI 2025).** PEER, text read.
- Observation: "on average 94% of compilation errors result from failing type checks"; only 9.0%
  (HumanEval) and 4.9% (MBPP) of non-compiling outputs were *syntax* errors.
- Method: prefix automata plus search over inhabitable types, "a sound approach to enforce
  well-typedness"; formalised on a simply-typed language, extended to TypeScript.
- Result: compilation errors reduced "by 75.3% and 52.1% on HumanEval and MBPP respectively";
  functional correctness up "relatively by 3.5% to 5.5%".
- Limits they state: "even though constrained decoding guarantees a valid result upon termination, a
  considerable amount of compilation errors remain due to non-termination within the token or time
  limit" (generation loops); needs next-token distributions, which "commercially available black-box
  LLM APIs" do not expose; they cite compile-error rates of 40% to 60% for OCaml and Haskell and note
  "low-resource languages (e.g., new DSLs)" are worst.
- Relevance: the estate writes in low-resource languages (AffineScript, Idris2, Agda, deed, k9 per the
  CLAUDE.md). The cited figures predict *high* raw agent error rates there, and constrained decoding
  is not available through a hosted API. What transfers is the architecture: **type checker in the
  loop, as a hard gate, with the error fed back** (the paper's "repair" task).

**Spracklen et al., "We Have a Package for You!" (USENIX Security 2025).** PEER via search. 576,000 code
samples from 16 LLMs: models invent package names, and the inventions repeat (secondary reports: 43%
of hallucinated names recurred in all ten reruns). The estate analogue in `ai-errors.md` section 2.1 is
"Fabricated SHA pins (T1) -- the largest single recurring class", and section 2.2 "The invented `lith`
monorepo".

**What the type-theory literature offers for fabricated references.** INFER, built from sections 13 and
9: a reference that must *resolve* is a dependent type (a SHA paired with evidence that it names a
commit in that repository; a path paired with evidence the file exists). Dhall's frozen import is the
shipped example: a reference carries the hash of the normal form of its target, and "An import frozen
in this way can never successfully return a different expression" (Dhall safety guarantees, DOC).
Unison does the same for code: "Each Unison definition is identified by a hash of its syntax tree"
(DOC). An LLM can still type a wrong hash, but it cannot make it resolve. That is "fail loudly" by
construction.

**Overclaim.** No type-theoretic work on LLM overclaim was found. The nearest classical tool is the
proof-carrying pattern: a claim is a value whose type demands its evidence (a receipt). That is the
estate's own PWG design as described in the CLAUDE.md ("A grade is derived from receipts, never
asserted"). I found nothing external to add.

MEM, not verified this session: Blinn et al., "Statically Contextualizing Large Language Models with
Typed Holes" (OOPSLA 2024) uses the Hazel hole's expected type and typing context to build the prompt
and to check completions. If confirmed, it is the closest published bridge between section 3.2 and
this section.

---

## 5. Gradual, refinement and liquid types

**Gradual typing.** Siek, Vitousek, Cimini, Boyland, "Refined Criteria for Gradual Typing" (SNAPL 2015;
PEER via search): the *gradual guarantee* relates "the behavior of programs that differ only with
respect to their type annotations"; losing precision preserves typeability and behaviour; mechanised
for the gradually typed lambda calculus. Cost: Takikawa et al., "Is Sound Gradual Typing Dead?" (POPL
2016) measured slowdowns over 100x in Typed Racket configurations; Bauman et al. (OOPSLA 2017) answer
"not yet dead", with a JIT removing over 90% of overhead on typical benchmarks (both via search).
Relevance: gradual typing is the migration discipline. It lets a schema be tightened one field at a
time without a flag day. The performance problem does not arise for config evaluated once.

**Refinement and liquid types.** Types refined by predicates "drawn from an SMT-decidable logic"
(LiquidHaskell papers via search). Liquid types (Rondon, Kawaguchi, Jhala, PLDI 2008; MEM) infer the
refinements from a fixed set of qualifiers. **Flux: Liquid Types for Rust** (Lehmann, Geller, Vazou,
Jhala, PLDI 2023; PEER via search): compared with Prusti on vector-manipulating programs, Prusti
needed hand-written loop invariants (annotation overhead "up to 24%", average reported as 9% in one
copy and 14% in another; the sources conflict), Flux infers them. Prusti's logic is more expressive
for deep functional specs.
Limits: only what the SMT logic decides; `assume` signatures are unchecked trust; laziness needed
special treatment in Haskell.
Relevance and a caution: the estate's proof policy (CLAUDE.md) fixes Rust verification on Creusot with
Pearlite and Verus. Flux is not in that policy. I mention it only as the best evidence that *inference*
of invariants cuts annotation cost; adopting it would be an owner decision under the policy's "another
tool only where it is plainly the right one" clause.

INFER: refinement types are also the natural home for the estate's small config invariants (a count in
the preamble equals the number of doctrine items; a pin is 40 hex digits; a date is not in the
future). Nickel contracts (section 13) are the run-time form of the same idea and are already an
estate format (`*.k9.ncl`, per CLAUDE.md).

---

## 6. Typestate and session types, for protocols and for CI

**Typestate.** Strom and Yemini, "Typestate: A programming language concept for enhancing software
reliability" (IEEE TSE 12, 1986; via Wikipedia reference list). Aldrich et al., typestate-oriented
programming and Plaid (2009). In Rust the *typestate pattern* encodes run-time state in a type
parameter so that "any misuse of data encoded using typestate will result in a compile-time error"
(tutorials via search). Mature and idiomatic.

**Session types.** MEM for origins (Honda 1993; Honda, Yoshida, Carbone, POPL 2008 for multiparty).
Verified this session (the claims; the author lists and venues in brackets are MEM):
- Rumpsteak (Cutner, Yoshida, Vassor; PPoPP 2022): multiparty session types in Rust, deadlock freedom
  by construction, using k-multiparty compatibility and asynchronous subtyping; "1.7 to 8.6x more
  efficient" than three earlier Rust implementations.
- Ferrite (Chen, Balzer, Toninho; ECOOP 2022): a judgmental embedding with linear and shared sessions;
  "Protocol adherence is guaranteed statically by the Rust compiler".
- "Stay Safe Under Panic" (Lagaillardie, Neykova, Yoshida; ECOOP 2022): "there is an inherent conflict
  between the affinity of Rust and the linearity of session types" (a channel can be dropped
  unfinished); they add cancellation.
- Caution on the metatheory itself: Scalas and Yoshida, "Less is More: Multiparty Session Types
  Revisited" (POPL 2019) argue that classic MPST subject-reduction proofs were flawed in several
  extensions; Yoshida and Hou, "Less is More Revisited" (2024) contest part of that. So even here
  "proved" has needed repair. Useful humility for any plan that leans on session types.

**For CI pipelines.** I searched for session-typed or typestate-typed CI systems and found none (section
15). What exists is one level down:
- **actionlint** (docs read; DOC): a static checker for GitHub Actions with a real type system for
  `${{ }}` expressions (object, array, `any` fallback), contexts, `needs` cycles, action inputs,
  cron syntax, script-injection checks, shellcheck integration. Stated limits include: step outputs
  checked only within a job; and, per the fetch summary, popular-action input checks apply to major
  version tags, **not SHA-pinned refs**. That last point needs confirming against the docs before
  anyone relies on it, because the estate SHA-pins heavily (`merge-drift.md`: 10,172 SHA-pinned
  third-party `uses:` lines).
- Typed generators that compile to YAML (gaji, ghat, gh-workflow in Rust, ghawb; via search). Pattern:
  typed source of truth, YAML as a build artefact, both committed. Most are TypeScript, which the
  estate bans; `gh-workflow` is Rust.
- MEM: Dagger and CUE-based pipeline definitions; `dhall` bindings for Actions. Not verified.

INFER, what a typestate reading of CI would buy: a job that needs `contents: write` cannot be reached
from a `pull_request_target` trigger; a `release` job cannot be scheduled unless a `signed` state was
reached; a required check cannot be configured `continue-on-error`. Those are exactly "gates that
could not fail" (`trivial-syntax.md` G2: 400 commits, 224 repos, 29 incidents). Each is a small finite
state machine, checkable with a contract over the parsed workflow. No new theory is needed; the gap is
that nothing parses the workflow as a typed value before it is committed.

---

## 7. Effect and capability types, and what they do for dependency bumps

- **Koka** (Leijen): effect types by row polymorphism; meaning, not labels: "If an expression can be
  typed without an exn effect, then it will never throw an unhandled exception" (MSR publication page
  via search). Research language.
- **Scala 3 capture checking**: capturing types `T^{c1, ..., cn}` over-approximate the capabilities a
  value retains. Official reference: "still highly experimental and unstable"; a newer overview says
  "quite mature and we expect it to be stabilized soon". The two official pages disagree. OOPSLA 2025
  "What's in the Box" (System Capless) re-implemented it and migrated the collections library.
- **Capslock** (Google, Go): static call-graph analysis that reports which privileged capabilities a
  package can reach; ships `capslock-git-diff`, which "lists package capabilities that were added
  between two revisions" (repo README via search). This is precisely *a bump is unsafe if it widens
  the capability set*. Go-only, and Go is a banned language in the estate, so it is a design
  reference, not a tool to adopt.
- MEM: WASI component model interfaces (WIT) make a component's imports its whole authority; Rust's
  `cap-std` and `cargo-cackle` attempt per-crate capability audit. Not verified this session.

INFER for the bumps pain: a dependency update has three independently checkable deltas, in rising cost:
(1) API delta (section 9), (2) capability delta (this section), (3) behaviour delta (tests). A bump with
empty (1) and empty (2) is the class that can be auto-merged on evidence. GitHub Actions bumps are the
case where (2) is cheapest to compute and matters most: the "capability" of an action is its
`permissions`, its secrets, and its network. `bumps.md` section 5 calls action SHA pins "the noisiest
and the most hazardous class".

---

## 8. Row types and schema evolution

- Theory: row polymorphism (Wand, Rémy; MEM) versus width subtyping. A 2023 study (arXiv 2304.08267;
  via search) shows full subtyping cannot be encoded by polymorphism but restricted forms can. Practical
  difference: subtyping forgets extra fields, row polymorphism carries them through. For metadata that
  must round-trip unknown fields, rows are the right model.
- A caution from the TYPES list (via search): width subtyping is unsound for positional binary layouts
  because an added field moves later ones. Compatibility is a property of *schema plus encoding*.
- **buf breaking** (docs via search; DOC): four nested rule categories, strictest first: FILE, PACKAGE,
  WIRE_JSON, WIRE. Passing a stricter one implies the weaker ones. This is a lattice of compatibility
  notions, each a decidable check over two schema versions.
- **Avro / Confluent Schema Registry** (docs via search): BACKWARD, FORWARD, FULL, each with a
  TRANSITIVE variant (check against all prior versions, not only the last). "adding or removing a
  field with a default value is a fully compatible change".
- **Cambria** (Ink and Switch essay, read; Litt, van Hardenberg, Henry, PaPoC 2021): schema evolution
  by composing bidirectional lenses; one lens yields the conversion, the types and the JSON Schema;
  translate "on read, not on write"; path found by "the shortest available path in the lens graph".
  Stated limits: "Lens evolutions cannot magically make two incompatible pieces of software work
  perfectly together"; some lenses "can only run reliably in one direction"; the `convert` operator
  "can't guarantee a useful consistency relation"; "it does not provide a mechanism to look up missing
  data"; recursive schemas and document splitting unsolved; performance unmeasured.

Relevance: `merge-drift.md` records ".a2ml files: 26,582 across 371 repos ... versus `.deed` 1,041 in
90 repos; 38 repos hold both. The retirement is ruled ... but not executed; two grammars coexist." A
format retirement is a schema evolution. The literature's advice is uniform: write the mapping once as
data (the estate's mapping specs are that, per CLAUDE.md), classify each field as lossless, lossy or
dropped, and check the round trip mechanically. Cambria's finding that some directions are lossy is
the reason a deletion rule needs the per-fact check the standards CLAUDE.md already demands.

---

## 9. Semver as a type

**Rust RFC 1105, API evolution** (read; DOC). Definitions: major change "requires a major semver bump";
breaking change "strictly speaking, can cause downstream code to fail to compile". Principle: "all
major changes are breaking, but not all breaking changes are major." Adding public items is breaking
"due to glob imports" yet minor. Type inference failures from new generics "are considered
acceptable". And the boundary: "This RFC does not attempt to provide a comprehensive policy on
behavioral changes, which would be extremely difficult." So even the reference policy is a
*convention about which breakages count*, not a soundness theorem.

**cargo-semver-checks** (Rust project goals 2026 page, read; DOC). "currently ships with 245 lints".
Works over rustdoc JSON. Remaining blockers for merging into cargo: **type-checking in lints** ("our
most commonly requested feature today"; changing `i64` to `String` in a signature is not caught) and
**cross-crate linting** ("the largest remaining class of false-positive bugs"). Funding is named as
"the main blocker". Design stance from the repository: prefer false negatives to false positives.

**How often semver is violated.** Nowak, Gruevski et al., "Semver violations are common, better tooling
is the answer" (blog, 7 Sep 2023; read). Top 1000 crates, 14,389 releases: "More than 1 in 6 crates
violated semver at least once" (172 of 1000); "Around 1 in 31 releases had at least one semver
violation" (464 of 14,389, 3.22%); 3,062 verified violations, each confirmed by a generated *witness*
program that compiles against the old version and fails against the new. About 10,000 reports were
discarded (over 6,000 were `#[doc(hidden)]` false positives). Only default features; only a subset of
violation kinds.
For Java: Ochoa, Degueule, Falleri, Vinju, "Breaking Bad?" (EMSE 2022; abstract read): of 119,879
library upgrades, "83.4% of these upgrades do comply with semantic versioning", and "7.9% of clients
are affected by breaking changes".

**Elm** (compiler docs, read; DOC). "All packages start at "1.0.0" and from there, Elm automatically
enforces semantic versioning by comparing API changes." `elm bump` computes the version; publishing a
version that disagrees with the API diff is rejected. Limit, in Elm's community's own words (Elm Radio,
via search): it "only applies to the API itself, not to the actual code". Same signature, different
behaviour, no bump.

**Unison** (the-big-idea and 1.0 pages, read; DOC). "Each Unison definition is identified by a hash of
its syntax tree"; "names are just separately stored metadata"; two versions of a type coexist under
different hashes so diamond dependency conflicts "are just not a thing"; typecheck results are cached
and "never invalidated"; "merge conflicts only happen when two people actually modify the same
definition". 1.0 released November 2025 ("the language, distributed runtime, and developer workflow
have stabilized"). Conceded costs: cached test results only for deterministic tests without I/O;
duplicates can accumulate; a C FFI is "underway". Limit (INFER): you must live inside the Unison
codebase manager; it does not help a polyglot Git estate directly.

Synthesis. "Semver as a type" means: **the version delta is a function of the interface delta, and a
machine computes it.** Shipped twice (Elm fully, Rust partially). It is sound only for the part of
compatibility that the interface language can express. The witness-program technique is the portable
trick: to show a change is breaking, exhibit a client that compiles before and not after. The dual, to
show a bump is safe *for you*, is to recompile *your* client against the new version, which is what CI
on a bump PR already does. The estate has no cargo-semver-checks use (section 14.1).

For GitHub Actions specifically (the estate's largest bump class): an action's `action.yml` (inputs,
outputs, `runs.using`) is an interface. Diffing it across two SHAs gives an Elm-style classification.
No tool doing exactly this was found; the typed generators in section 6 parse `action.yml` to generate
wrappers, so the parsing half exists.

---

## 10. Build systems a la carte and hermeticity: a theory of minimal CI

**Mokhov, Mitchell, Peyton Jones, "Build Systems a la Carte" (ICFP 2018; JFP 2020).** PEER, text read.
- "Definition 2.1 (Minimality). A build system is minimal if it executes tasks at most once per build
  and only if they transitively depend on inputs that changed since the previous build." Called "their
  raison d'etre".
- Correctness (section 3.6): the result agrees with the store on inputs, and for every non-input key
  recomputing its task reproduces the stored value. "correct only under the assumption that the given
  task description is acyclic"; needs adjusting for "non-deterministic tasks and shallow cloud builds".
- Two orthogonal choices: scheduler (order) and rebuilder (whether to rebuild). **Early cutoff**: stop
  propagating when a rebuilt result is unchanged (their example: adding a comment to `main.c`).
  **Cloud build**: share results through a content-addressed cache. "Bazel is not minimal in the sense
  that it may restart a task multiple times ... but it supports the early cutoff optimisation."
- Make's own caveat applies everywhere: it "is therefore minimal only under the assumption that you do
  not" touch timestamps. Minimality is always relative to honest inputs.

**Hermeticity** (Bazel docs, read; DOC). "a hermetic build system always returns the same output by
isolating the build from changes to the host system." Two aspects: isolation ("treat tools as source
code") and source identity. Sources of non-hermeticity listed: arbitrary `.mk` processing, timestamps
and build IDs, host binaries, "Writing to the source tree during the build".

**Does it work at scale?** Malka, Zacchiroli, Zimmermann, "Does Functional Package Management Enable
Reproducible Builds at Scale? Yes." (MSR 2025, Distinguished Paper; text read). Over 709,000 nixpkgs
package builds: bitwise reproducibility "between 69 and 91% with an upward trend" (2017 to 2023) and
"rebuildability rates, over 99%"; "about 15% of failures are due to embedded build dates". So the
functional model gives near-total *rebuildability* and high but not total *bit-for-bit* identity.
The estate uses Guix, not Nix (CLAUDE.md); the model is the same (MEM), the numbers are Nix's.

**Flakiness.** Luo et al., "An Empirical Analysis of Flaky Tests" (FSE 2014; via search): 201 fixing
commits across 51 Apache projects, a root-cause taxonomy; it cites 73K of 1.6M (4.56%) test failures
at Google as flaky. Later surveys quote "around 16%" of Google's tests showing some flakiness; I did
not retrieve the Google source.

Translation to CI (INFER, but each step is one of the paper's definitions):
1. A CI job is a build task: inputs are the files it reads, the tool versions, the action SHAs.
2. A CI system is *minimal* if a job runs only when something it transitively depends on changed.
   `paths:` filters are a hand-written, unchecked approximation of the dependency relation.
3. *Early cutoff* for CI: if a generated artefact (a lockfile, a rendered workflow, a normal form) is
   byte-identical after a change, downstream jobs need not run. A canonical serialisation (JCS, KYAML
   formatter, Dhall or Nickel normal form) is what makes "unchanged" detectable. Whitespace-only and
   comment-only changes then cost nothing, by theorem rather than by filter.
4. The soundness condition is hermeticity: a cached "pass" may be reused only if the job's declared
   inputs are all of its inputs. A job that reads the network, the clock or an unpinned tag is not a
   function of its key, and caching it is unsound. That is the same boundary as "flaky".
5. So "minimal CI" decomposes into: (a) make jobs functions (pin and declare), (b) key them by content
   hash, (c) cut off early on unchanged outputs. `ci-cost.md` section 4 measures "fan-out per push
   (jobs, not minutes)", which is the quantity (b) and (c) reduce.

Limits: the theory says nothing about *which* checks are worth having; a test with hidden inputs
breaks it; and GitHub Actions has no native content-addressed job cache, so this needs either a build
tool inside one job or a skip-if-key-seen step (MEM).

---

## 11. Lenses, edit lenses, delta lenses: template drift and config sync

**The laws.** Foster, Greenwald, Moore, Pierce, Schmitt, "Combinators for Bidirectional Tree
Transformations" (POPL 2005; TOPLAS 2007; via abstract and the group's slides). A lens is `get : S ->
V` and `put : V x S -> S`. Well-behaved means **GetPut** (put the unmodified view back and nothing
changes) and **PutGet** (what you put is what you get). **PutPut** is optional and many useful lenses
fail it. The slides say the two laws "have proved strong enough in practice to place useful
constraints on the design of lens primitives".

**Edit lenses.** Hofmann, Pierce, Wagner (POPL 2012; via abstract): lenses that take *descriptions of
changes*; an "editable structure" is a set of states with a monoid of edits acting partially; every
state-based lens induces an edit lens over an overwrite-only edit language.

**Delta lenses.** Diskin, Xiong, Czarnecki, "From State- to Delta-Based Bidirectional Model
Transformations: the Asymmetric Case" (JOT 10, 2011; via abstract): model spaces are categories
(models as objects, deltas as arrows) and propagation maps deltas to deltas. The motivation (MEM): a
state-based `put` must *guess* the alignment between old and new view, and guesses wrong on renames
and reorders. Passing the delta removes the guess.

**Shipped lens systems.**
- **Augeas** (augeas.net and Wikipedia via search; DOC): edits `/etc` files through a tree; each lens
  pairs a parser (get) with a writer (put); lenses are type-checked with finite automata "ensuring
  they don't contain ambiguities"; the put direction "works very hard to preserve comments and
  formatting details". Descends from Harmony and Boomerang. Production tool, years of use.
- **Boomerang** ("Boomerang: Resourceful Lenses for String Data", Bohannon et al., POPL 2008; MEM for
  details): dictionary lenses that keep reorderable chunks aligned by key.
- **Cambria**: section 8.

**Template update tools as untyped lenses** (via search; DOC). Copier stores the template version and
answers in `.copier-answers.yml` and on update does "a three-way diff between the previous template
version, the new template version, and your local modifications"; conflicts land as `.rej` files or
inline markers; `copier check-update` reports staleness. Cruft and Flexlate are similar. All three are
Python, which the estate bans as an authored language; whether running one as a tool is acceptable is
an owner question I am only flagging. No peer-reviewed study of template drift was found.

**The mapping to template drift.** INFER, and I think the most useful single idea in this report:

- A repo generated from a template is `put(answers, template)`. The template is the *view* shared by
  all repos; each repo's local edits are the *complement* (what `get` forgets).
- Line-level three-way merge (Copier) is a state-based put that guesses alignment. That is why it
  produces conflicts and why `merge-drift.md` finds "Justfile 400/391/6 (essentially every copy
  unique)" and 47 common workflow paths with "7,423 file instances, 3,722 distinct hashes".
- A lens makes drift *definable*: a file has drifted iff `get(repo_file)` differs from the current
  template view. Local customisation is whatever the lens assigns to the complement. Without a lens
  there is no way to tell customisation from drift, and the hash counts above cannot be interpreted.
- A delta lens makes update *conflict-free where it should be*: a template change is a delta on the
  view; put translates it to a delta on each repo, leaving the complement alone. Conflict arises only
  when the template delta touches something the repo overrode, and that is detectable from the lens.
- GetPut is the property the estate wants from a sync tool and currently cannot state: "re-syncing an
  up-to-date repo changes nothing". A sync that violates GetPut generates churn commits.
  `merge-drift.md` section 4 is titled "Mass sync/sweep commits (same subject in >=20 repos)".
- The cheapest realisation is not a lens library. It is to stop copying: a reusable workflow called by
  a thin wrapper is `get` computed at run time, with the complement reduced to the wrapper's `with:`
  inputs. `merge-drift.md` shows the estate has already done this for several workflows ("hypatia-scan
  346 of 386 files reference `reusable`") and that the residual drift moved into the pin: "1,795
  standards-workflow pins in 411 repos, 92 distinct SHAs". So the remaining complement is a single
  value per repo, and its drift is a number (commits behind), which is easy to gate.
- Connection to the estate's own formalism, stated carefully. The CLAUDE.md describes echo-types as
  formalising `Echo f y := Sigma (x : A), (f x = y)`, the fibre of `f` over `y`, "loss-with-residue".
  Taking `f = get`, the fibre over a view `v` is exactly the set of sources that project to `v`, and a
  `put` is a choice of a point in that fibre given the old source. So a lens complement is a residue
  in that sense. I did not read the echo-types sources; a sibling report (`echo-residual.md`) covers
  them. If the correspondence holds there, the estate already owns the theory in which "template plus
  residue" is the type of a repo file. MEM: Johnson and Rosebrugh relate delta lenses to split
  opfibrations, which is the same fibre picture one level up.

Limits of the lens approach: many real edits are not lens-expressible (Cambria's findings); writing
lenses is work per file kind; free-text files (README) have no useful structure, so only
data-like files and config benefit.

---

## 12. Ornaments and refactoring as typed transformation

- McBride, "Ornamental Algebras, Algebraic Ornaments" (MEM; the paper was not surfaced by search;
  Williams and Rémy's slides confirm that "ornaments have been introduced by Conor McBride and explored
  widely with Pierre-Evariste Dagand in the context of Agda, and also by Jeremy Gibbons and Hsiang-Shang
  Ko").
- Williams and Rémy, "A Principled Approach to Ornamentation in ML" (POPL 2018). PEER, text read.
  "Ornaments are a way to describe changes in datatype definitions reorganizing, adding, or dropping
  some pieces of data so that functions operating on the bare definition can be partially and sometimes
  totally lifted". "We use logical relations to closely relate the lifted code to the bare code."
  Motivation in their words: after changing a datatype the type checker lists the broken sites, but the
  fixes "have to be manually performed ... boring, time consuming, and error prone. Worse, changes that
  do not lead to type errors will be left unnoticed." Stated limits: "fixing a bug cannot just be done
  by ornamentation"; the input language is restricted to top-level polymorphism; lifting is sometimes
  only partial and asks the user for the new pieces.
- Ringer, Porter, Yazdani, Leo, Grossman, "Proof Repair across Type Equivalences" (PLDI 2021), tool
  Pumpkin Pi for Coq. PEER via abstract. Repairs proofs after a type changes, by a configurable proof
  term transformation plus a decompiler back to tactics; eight case studies; search procedures for
  "four different classes of changes". A later paper notes it handled only a limited class of changes.

Relevance: ornaments are the typed account of "add a field everywhere" and "split this record", the
commonest schema change in metadata. A deed clause gaining a field is an ornament of the old clause;
the forgetful map (drop the field) is the migration's `get`. Proof repair is directly relevant to an
estate with Agda theory rechecked in Rocq and Lean: a datatype change in the Agda source invalidates
the rechecks, and transport across the equivalence is the principled way to port them. Both are
research-grade; neither has an Agda tool that I found.

---

## 13. Typed configuration: Dhall, Nickel, CUE

| | Dhall | Nickel | CUE |
|---|---|---|---|
| Core idea | Total, strongly normalising typed lambda calculus for config | Gradually typed, lazy, with run-time contracts and a built-in record merge | One lattice of values; types are values; unification |
| Headline guarantee | "if a Dhall configuration file type checks then program evaluation/normalization will never fail"; every expression has a normal form | "You get to chose when to use static typing or not"; contracts check what types cannot | Unification is order-independent: "we could always unambiguously merge two such configurations independently of order" |
| Identity and integrity | Semantic integrity check: hash of the *normal form*; "An import frozen in this way can never successfully return a different expression"; refactoring and whitespace do not change the hash | Not found | Not found |
| Merge and override | Record operators; no lattice | Merge with metadata, defaults and priorities; recursive records, "lazy and recursive by default" | No overrides at all: "if one sees a concrete value for a field, it is guaranteed that this will be the final result"; conflict is bottom |
| Turing-complete | No | Yes (RATIONALE: the other listed languages "forbid general recursion") | No |
| Stated costs | "a finite amount of time can still be very long"; "expressive but complex type system" (Nickel's view) | Contracts fail at run time, not check time | "heavily constrained, which might be limiting" (Nickel's view); "Detection of structural cycles ... is not yet implemented"; conflicting defaults leave no value |
| Sources | dhall-lang wiki "Safety guarantees" (read; the page says it is a stale copy) | tweag/nickel RATIONALE.md (read); Tweag blog (via search) | cuelang.org "The Logic of CUE" (read); tutorial (via search) |

Why each matters to the pains:

- **CUE and merge clashes.** CUE's unification is the greatest lower bound in a lattice, so combining
  constraints from N sources is commutative, associative and idempotent (stated in the tutorial; the
  logic page states order-independence). Two agents adding *different* fields never conflict; adding
  *contradictory* values yields bottom with both sources named. That is a merge that cannot silently
  pick a winner. It is the config-level analogue of Grove (section 2.5): conflict as a value. It also
  means "last writer wins" overrides are inexpressible, which is the price.
- **Dhall and fabricated or drifting references.** Normal forms plus semantic hashes give
  content-addressed, behaviour-indexed config. A hash changes iff the meaning changes. That is the
  right notion of "pin" and of "has this template instance drifted". Dhall is already one of kyq's
  four formats per the CLAUDE.md.
- **Nickel and gradual tightening.** Contracts attach to fields and travel through merge. This is the
  estate's k9 substrate (`*.k9.ncl`). Gradual typing is what lets a contract start permissive and be
  tightened without a flag day; the gradual guarantee (section 5) is the property to preserve.
- **All three and the YAML-generation damage.** Each builds a value and then prints YAML or JSON. A
  generator written in any of them *cannot* emit an unparsable file. `trivial-syntax.md` G1 ("workflows
  that are not valid YAML and "have never run"": 521 commits, 281 repos) is the class this removes.
  Text templating with string substitution is what produces it.

Limits common to all three: they validate shape, not truth. A well-typed config can name a SHA that
does not exist unless resolution is part of evaluation (Dhall imports do this; plain strings do not).

---

## 14. Synthesis for the programme

### 14.1 One estate scan I ran (so the mapping is not guesswork)

`rg` over `/home/user/estate` restricted to `*.yml`, `*.yaml`, `justfile`, `Justfile`, `*.toml`,
`.gitattributes`, `*.kyaml` (fixed-string, case-sensitive):

| Pattern | Files |
|---|---:|
| `.gitattributes` containing `merge=` | 8 (drivers named: `merge=union` 8 uses, `merge=lfs` 4, `merge=ours` 1, `merge=binary` 1) |
| `mergiraf` | 0 |
| `difftastic` | 0 |
| `cargo-semver-checks` / `semver-checks` | 0 |
| `actionlint` | 3 (`metadatastician/paint-type/.coderabbit.yaml`, `hyperpolymath/verisimdb/.coderabbit.yaml`, `hyperpolymath/verisimdb/Justfile`) |
| `copier` | 0 |
| `buf breaking`, `elm diff` | 0 |

Limits: these globs miss shell scripts, workflows that call a wrapper script, and docs. `cruft` matched
82 files, all named `Justfile`, on lines ending `rm .machine_readable/ai/PLACEHOLDERS.adoc"` (48) or
`rm PLACEHOLDERS.md"` (34). That is the ordinary word in a template recipe, not the Cruft tool. Zero hits means "not wired in these file kinds", not "never considered".

### 14.2 What the literature says types *can* do for each pain

| Pain | Strongest available lever | Kind of guarantee | External maturity |
|---|---|---|---|
| Merge conflicts in owned data formats | Canonical form + merge on the parsed value; conflict as a value (CUE lattice, Grove) | Order-independence; no unparsable output | CUE production; Grove research |
| Merge conflicts in code | Structured merge driver, with a parsable-and-universal check after | Fewer false conflicts; checkable result | Mergiraf usable; check is research (d3j) |
| Conflict markers committed | Parse every file kind that has a grammar; treat markers as a lexical error in the rest | Fail loudly | Trivial to gate; no theory needed |
| Agent clashes | Commutative edits (CRDT) or entity claims | All edits commute (Grove, theorem) | Research; Weave's claim layer is self-reported |
| Trivial syntax in generated config | Build a typed value, print it; holes or obligations instead of placeholders | Unparsable output unrepresentable | Dhall, Nickel, CUE production |
| Trivial syntax while editing | Obligation-based parsing | Total parse | Research |
| LLM compile-level errors | Type checker as a hard gate with error fed back; constrained decoding where logits exist | Well-typed on termination | Research; not available via hosted APIs |
| LLM fabricated references | References as content hashes that must resolve | Cannot resolve if invented | Dhall, Unison, Nix, Guix production |
| LLM overclaim | Claims typed by their evidence (receipts) | Claim without receipt does not type-check | Nothing external found beyond proof-carrying patterns |
| Unsafe vs safe bumps | Interface delta (semver as a computed type) + capability delta | Sound for the expressible part of the interface | Elm full; Rust partial (no type info yet); Capslock Go-only |
| CI cost | Content-keyed jobs + early cutoff on canonical outputs | Minimality (definition 2.1) given hermetic tasks | Build tools production; not native to Actions |
| CI flakiness | Hermeticity: declare and pin every input | Same inputs, same result | Bazel, Nix, Guix production; 69 to 91% bitwise in nixpkgs |
| Template drift | Lens view: drift = `get(file) != template`; complement = sanctioned customisation; reusable workflows shrink the complement to a pin | GetPut, PutGet | Augeas production; rest research |
| Licence and metadata drift | Single source value projected to each file (a lens, one direction); semantic hash per projection | Projection is a function, so copies cannot disagree | Mechanism mature. Note: the estate forbids automated licence edits, so for licences this can only ever be a *detector* |

### 14.3 What types cannot do (recurring across every section)

1. **Behaviour behind an unchanged interface.** Elm, RFC 1105, cargo-semver-checks and Brun's one-third
   all hit the same wall. Only running something (tests, a client build, a proof) crosses it.
2. **Intent.** Every recovering parser, every merge tool and every CRDT must choose among repairs. CPCT+
   enumerates them; Grove and CUE keep them as conflicts. None can know which the author meant.
3. **Truth of the trusted base.** Refinement `assume`s, hermeticity declarations, lens definitions and
   schema mappings are all axioms supplied by a person or a model. A wrong axiom gives a confident
   wrong answer. This is the estate's `ASSUMED` boundary in other words.
4. **Formats with no grammar.** `.gitignore`, `LICENSE`, prose. Nothing here applies until there is a
   parser. `merge-drift.md` makes the same observation ("have no parser, so nothing fails loudly").
5. **Adoption cost.** Projectional editing, Unison and Pijul each demand leaving the text-plus-Git world.
   The successful deployments (Elm's semver, buf, Augeas, actionlint, typed config) all *keep* the
   incumbent format and add a typed layer beside it.

### 14.4 Ordering by expected leverage, with the reasoning shown

This is my judgement (INFER throughout), offered for the programme to weigh, not a finding.

1. **Generate owned config from typed values; never by text substitution.** Removes the largest
   measured class (`trivial-syntax.md` G1, 521 commits) by construction. Tools are production-grade and
   two are already estate formats (Nickel for k9, Dhall via kyq).
2. **Make references resolve-or-fail.** A pin or path is a pair (value, evidence it resolves). Targets
   the largest AI error class (`ai-errors.md` 2.1 fabricated SHA pins). Mechanism is a gate, not a
   research project.
3. **Shrink template complements and gate the residue as a number.** The lens analysis says the estate
   is one step from this for workflows: the residue is the standards pin, 92 distinct SHAs.
4. **Classify bumps by computed deltas.** Interface diff of `action.yml`, permission and secret diff,
   then tests. Elm shows the interface part is tractable; nobody has shipped it for Actions.
5. **Canonical forms for early cutoff in CI.** Cheap where a canonical serialiser already exists (JCS).
6. **A structured merge driver for code plus `merge=union`-style drivers replaced by value merges for
   data.** Modest gain (single-digit percent of conflicts fully resolved on the kernel); the estate
   mostly squashes, so conflicts are under-recorded (`merge-drift.md` section 1).
7. **Research watch, not adoption:** Grove (typed conflicts), tall tylr (obligations), proof repair
   across equivalences, homotopical patch theory as a pattern for estate-specific patch laws.

---

## 15. Not found, not confirmed, or conflicting

Stated plainly so nobody downstream cites these as facts.

- **Session types or typestate applied to CI pipelines as a system:** searched, not found. Section 6's
  CI reading is my inference.
- **Typed GitHub Actions in Dhall; Dagger's typing:** not surfaced by search. From memory only.
- **Pijul stable 1.0:** not found. Latest release found is 1.0.0-beta.9, dated Feb 2024, from a package
  listing. The pijul.org manual footer reads "2016 to 2026".
- **Darcs 3 patch format and its status:** not found.
- **Weave's benchmark:** self-reported, 31 synthetic scenarios. No independent evaluation found.
- **Mergiraf versus d3j, or Mergiraf under the parsable-and-universal criterion:** not found. The d3j
  paper does not include Mergiraf or Weave.
- **actionlint and SHA-pinned actions:** the statement that popular-action input checks do not apply to
  SHA-pinned refs comes from a model-generated summary of the docs page. Confirm in the docs.
- **"19.7% of packages hallucinated"** (Spracklen et al.): the figure I had in mind was not in the
  retrieved results. Not cited above.
- **"One third of Maven releases break" (Raemaekers et al.):** not confirmed. Only Ochoa et al.'s
  83.4% compliance and 7.9% of clients affected were read from an abstract.
- **Flux annotation overhead versus Prusti:** two copies of the paper give the average as 9% and 14%.
- **Scala 3 capture checking status:** two official pages disagree (highly experimental versus mature
  and near stabilisation).
- **Google "16% of tests flaky":** quoted by later surveys; the Google source was not retrieved.
- **Brun et al. wording:** the abstract-level sentence about "33% of merges reported clean" does not
  match the body's arithmetic; the body supports "33% of all conflicts were higher-order".
- **Homotopical Patch Theory mechanised in Cubical Agda:** not found.
- **McBride's original ornaments paper:** not surfaced by search; cited from memory and from Williams
  and Rémy's slides.
- **Peer-reviewed work on template drift:** not found.
- **Unison performance limits:** a secondary article quotes the team on runtime performance; I could
  not confirm it from an official page and did not use it.
- **Hazelnut (2017) Agda mechanisation, GumTree details, Boomerang details, Liquid Types (2008), row
  polymorphism origins, session type origins, Go and JavaScript semicolon rules, WASI/cap-std, Dagger:**
  all from memory, marked MEM where used.
- **Author lists and venues** for Hazelnut, truediff, Cavalcanti et al. (ASE 2019), Rumpsteak, Ferrite,
  "Stay Safe Under Panic", Luo et al. and Voelter et al. (SLE 2014) are from memory or inferred from a
  URL; the titles, arXiv numbers and quoted claims are what the search returned.
- I did not open any external proof artefact. Every MECH tag is the authors' report.

---

## 16. Sources

Papers read from extracted text (pdftotext):
- Angiuli, Morehouse, Licata, Harper. Homotopical Patch Theory. JFP 26, 2016. https://www.cs.cmu.edu/~rwh/papers/htpt/jfp.pdf
- Mimram, Di Giusto. A Categorical Theory of Patches. arXiv 1311.3903. https://arxiv.org/abs/1311.3903
- Brun, Holmes, Ernst, Notkin. Proactive detection of collaboration conflicts. ESEC/FSE 2011. https://homes.cs.washington.edu/~mernst/pubs/vc-conflicts-fse2011.pdf
- Mokhov, Mitchell, Peyton Jones. Build Systems a la Carte. ICFP 2018. https://www.microsoft.com/en-us/research/uploads/prod/2018/03/build-systems-a-la-carte.pdf
- Adams et al. Grove: A Bidirectionally Typed Collaborative Structure Editor Calculus. POPL 2025. https://thomasporter522.github.io/pdfs/Grove.pdf
- Duarte, Borba, Cavalcanti. LastMerge. arXiv 2507.19687. https://arxiv.org/abs/2507.19687
- Mori, Hashimoto. On the Correctness of Software Merge. arXiv 2607.07987. https://arxiv.org/abs/2607.07987
- Moon, Blinn, Porter, Omar. Syntactic Completions with Material Obligations. OOPSLA 2025. https://arxiv.org/abs/2508.16848
- Malka, Zacchiroli, Zimmermann. Does Functional Package Management Enable Reproducible Builds at Scale? Yes. MSR 2025. https://arxiv.org/abs/2501.15919
- Mündler et al. Type-Constrained Code Generation with Language Models. PLDI 2025. https://arxiv.org/abs/2504.09246
- Williams, Rémy. A Principled Approach to Ornamentation in ML. POPL 2018. https://gallium.inria.fr/~remy/ornaments/Williams-Remy:ornaments@popl2018.pdf

Pages read directly:
- Mergiraf architecture. https://mergiraf.org/architecture.html
- LWN, Mergiraf: syntax-aware merging for Git. https://lwn.net/Articles/1042355/ (comments: https://lwn.net/Articles/1044609/)
- Pijul manual, theory. https://pijul.org/manual/theory.html
- Rust RFC 1105. https://rust-lang.github.io/rfcs/1105-api-evolution.html
- Rust project goals 2026, cargo-semver-checks. https://goals.rust-lang.org/2026/cargo-semver-checks.html
- Semver violations are common. https://predr.ag/blog/semver-violations-are-common-better-tooling-is-the-answer/
- Elm package docs. https://github.com/elm/compiler/blob/master/docs/elm.json/package.md
- Unison, the big idea. https://www.unison-lang.org/docs/the-big-idea/ ; Unison 1.0. https://www.unison-lang.org/unison-1-0/
- Bazel hermeticity. https://bazel.build/basics/hermeticity
- Dhall safety guarantees. https://github.com/dhall-lang/dhall-lang/wiki/Safety-guarantees
- The Logic of CUE. https://cuelang.org/docs/concept/the-logic-of-cue/
- Nickel RATIONALE. https://github.com/tweag/nickel/blob/master/RATIONALE.md
- Project Cambria. https://www.inkandswitch.com/cambria/
- matklad, Resilient LL Parsing Tutorial. https://matklad.github.io/2023/05/21/resilient-ll-parsing-tutorial.html
- actionlint checks. https://github.com/rhysd/actionlint/blob/main/docs/checks.md
- arXiv abstracts: 1805.00155 (Hazelnut Live), 2110.07889 (Breaking Bad?)

Via search summaries only (not opened):
- Weave. https://github.com/Ataraxy-Labs/weave
- difftastic. https://github.com/Wilfred/difftastic
- Cavalcanti et al., ASE 2019. https://www.se.cs.uni-saarland.de/publications/docs/CBS+19.pdf
- Miraldo, Swierstra, ICFP 2019. https://icfp19.sigplan.org/details/icfp-2019-papers/19/An-Efficient-Algorithm-for-Type-Safe-Structural-Diffing ; author note https://victorcmiraldo.github.io/posts/2020-09-28-struct-diff.html
- truediff, PLDI 2021. https://pldi21.sigplan.org/details/pldi-2021-papers/27/Concise-Type-Safe-and-Efficient-Structural-Diffing
- Darcs: https://en.wikibooks.org/wiki/Understanding_Darcs/Patch_theory_and_conflicts ; https://en.wikipedia.org/wiki/Darcs ; Jacobson https://ww3.math.ucla.edu/camreport/cam09-83.pdf
- Pijul releases: https://pijul.org/posts/2022-01-08-beta ; forum https://discourse.pijul.org/t/is-the-category-of-patches-a-groupoid/293
- Gomes et al., OOPSLA 2017. https://arxiv.org/abs/1707.01747
- Sousa, Dillig, Lahiri, OOPSLA 2018. https://www.cs.utexas.edu/~isil/verified-merge.pdf
- Total Type Error Localization and Recovery with Holes, POPL 2024. https://popl24.sigplan.org/details/POPL-2024-popl-research-papers/70/Total-Type-Error-Localization-and-Recovery-with-Holes
- Gradual Structure Editing with Obligations, VL/HCC 2023. https://conf.researchr.org/details/vlhcc-2023/vlhcc-2023-research-papers/8/Gradual-Structure-Editing-with-Obligations
- tylr, TyDe 2022. https://icfp22.sigplan.org/details/tyde-2022-papers/6/tylr-a-tiny-tile-based-structure-editor
- Diekmann, Tratt, ECOOP 2020. https://arxiv.org/abs/1804.07133
- Berger et al., FSE 2016. https://gsd.uwaterloo.ca/projectional-workbenches.html ; Voelter et al. SLE 2014 https://link.springer.com/doi/10.1007/978-3-319-11245-9_3
- Spracklen et al., USENIX Security 2025. https://www.usenix.org/conference/usenixsecurity25/presentation/spracklen
- Siek et al., SNAPL 2015. https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.SNAPL.2015.274
- Takikawa et al., POPL 2016. https://users.cs.northwestern.edu/~dmf082/papers/popl16-tfgnvf.pdf
- Flux, PLDI 2023. https://arxiv.org/abs/2207.04034
- Rumpsteak https://arxiv.org/abs/2112.12693 ; Ferrite https://arxiv.org/abs/2009.13619 ; Stay Safe Under Panic https://drops.dagstuhl.de/opus/volltexte/2022/16250/
- Less is More https://mrg.cs.ox.ac.uk/publications/less-is-more-multiparty-session-types-revisited/preprint.pdf ; Less is More Revisited https://arxiv.org/abs/2402.16741
- Typestate: https://en.wikipedia.org/wiki/Typestate_analysis
- Koka. https://www.microsoft.com/en-us/research/publication/koka-programming-with-row-polymorphic-effect-types/
- Scala capture checking. https://scala-lang.org/api/3.x/docs/experimental/capture-checking/overview.html ; https://arxiv.org/abs/2509.07609
- Capslock. https://security.googleblog.com/2023/09/capslock-what-is-your-code-really.html
- buf breaking. https://buf.build/docs/breaking/rules/
- Confluent schema evolution. https://docs.confluent.io/platform/current/schema-registry/fundamentals/schema-evolution.html
- Structural subtyping vs polymorphism. https://arxiv.org/abs/2304.08267
- Lenses: https://www.cis.upenn.edu/~bcpierce/papers/lenses-toplas-final.pdf ; Edit lenses https://dx.doi.org/10.1145/2103656.2103715 ; Diskin et al. https://gsd.uwaterloo.ca/publications/view/354.html
- Augeas. https://augeas.net/docs/lenses.html
- Copier updating. https://copier.readthedocs.io/en/latest/updating/
- Proof Repair across Type Equivalences. https://arxiv.org/abs/2010.00774
- Luo et al. flaky tests and later surveys. https://arxiv.org/abs/1907.01466
- CUE unification tutorial. https://cue.googlesource.com/cue/+/v0.0.3/doc/tutorial/basics/unification.md
- Typed Actions generators: https://docs.rs/crate/gh-workflow/0.8.1/source/README.md
