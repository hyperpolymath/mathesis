# External research: trope theory and its near range

Read-only external research, 2026-11-24. Companion to the internal file
`/home/user/estate/.findings/tropes.md` (what the estate itself means by "trope"); this
file is about the *outside* literature and where it does or does not touch computing.

## 0. Method and honesty legend

- **[V]** = verified online in this session (search result or fetched page; URL in section 8).
  "Verified" means I saw the bibliographic fact or the quoted sentence, not that I read the
  whole work. Where I only saw an abstract or a search snippet I say so.
- **[M]** = from memory, not checked online in this session. Treat as a lead, not a fact.
- **[A]** = my own analysis or analogy. No source claims it. This is where "untouched
  ground" lives, and also where I am most likely to be wrong.
- One primary source was read in full text locally: Guizzardi, Masolo and Borgo (ER 2006),
  downloaded to a scratch file and converted with `pdftotext` (674 lines). Quotes from it
  are exact.
- Tools used: WebSearch (about 40 queries), WebFetch (SEP "Tropes", Wikipedia "Signs of AI
  writing", tropes.fyi, arXiv 2503.13657v3, arXiv 2603.20948, nLab Corfield "ontology").
  Two long pages were only partly read: SEP "Tropes" (first 100,000 of 110,124 characters)
  and Wikipedia "Signs of AI writing" (first 100,000 of 252,783 characters).
- Not done: no estate file was edited; nothing was installed; no paywalled text was read.
- The estate side is cited only from the internal findings file above; I did not re-derive it.

---

## 1. Metaphysical trope theory

### 1.1 What a trope is, and the names it has had

SEP "Tropes" (first published 9 Sep 2013, substantive revision 16 Mar 2023) [V]: trope theory
is "the view that reality is (wholly or partly) made up from tropes", where tropes are
"things like the particular shape, weight, and texture of an individual object". A trope is
a *particular* property-instance: this redness, of this shirt. Two things "share a property"
when each has its own numerically distinct trope and the two tropes exactly resemble.

| Name | Who | Note | Status |
|---|---|---|---|
| individual accident ("present in a subject") | Aristotle, *Categories* 1a20-1b10; Scholastics | The fourfold division there is the origin of the "ontological square" (the name is credited to Angelelli) | [V] for the square and the citation, via search snippet |
| mode | Locke, Descartes, Spinoza tradition; revived by Lowe, Heil, Martin | "Mode" stresses dependence: a way a substance is | [M] for the early-modern lineage; SEP lists Lowe, Heil, Martin [V] |
| moment (*Moment*) | Husserl, *Logical Investigations* III; used by Stout, Ingarden, Segelberg | A dependent ("abstract") part, as opposed to a piece (independent part) | [V] SEP |
| abstract particular / "characters as particular" | G. F. Stout (1921 lecture; 1923 Aristotelian Society symposium with Moore) | Stout held the unity of a class of characters to be primitive, not resemblance | [M] for dates and the distributive-unity point |
| trope | D. C. Williams, "On the Elements of Being" (1953) | SEP: "the father of the contemporary debate on tropes"; one-category theory "for the first time so labeled" | [V] SEP |
| abstract particular | Keith Campbell, *Abstract Particulars* (1990) | Field-theoretic version: basic tropes are fields | [V] SEP mentions book and field theory |
| property instance / particularised property | Bacon, Fisher, formal ontologists | The neutral term | [V] SEP |

### 1.2 The standard package (Williams)

SEP [V]: Williams combines (i) a **one-category** ontology of tropes, (ii) a **bundle theory**
of concrete particulars (an object is a bundle of *compresent* tropes), and (iii) a
**resemblance-class theory** of universals (a "universal" is a class of *exactly resembling*
tropes). Most trope theorists treat this as the default.

- **Exact resemblance** is an equivalence relation (reflexive, symmetric, transitive), so it
  partitions the tropes into disjoint classes that "do the work" of universals [V, SEP].
  It is usually taken to be *internal*: it holds given the relata, with no further relation
  needed. *Inexact* resemblance comes in degrees and is not transitive [M], so it does not
  partition anything. This matters a great deal in section 3.9.
- **Compresence** is what ties tropes into one object. Most theorists take it to be
  *external*, which invites **Bradley's regress** (a relation needs a further relation to
  tie it to its relata) [V, SEP].
- **Maurin's reply** (SEP, quoted) [V]: "relational tropes (including compresence) depend
  specifically for their existence on the very tropes they relate", so the relation cannot
  exist without relating exactly those relata and no further tie is needed.
  (Book: *If Tropes*, 2002 [M].)

### 1.3 Rivals inside the family

- **Simons, nuclear theory** ("Particulars in Particular Clothing: Three Trope Theories of
  Substance", *Philosophy and Phenomenological Research* 54(3), 1994, 553-575) [V]. Neither
  pure bundle nor substratum. A substance has a **nucleus** of mutually and specifically
  dependent tropes (its essential kernel) and normally a **halo** of further tropes that
  depend specifically on the nucleus but on which the nucleus depends only generically
  (it needs *some* colour, not *this* one). Built on Husserl's **foundation** relations;
  Simons says he came to tropes through Husserl's moments, not through Stout [V, search
  summary of the paper]. I did not read the paper's own definitions.
- **Lowe, four-category ontology** (*The Four-Category Ontology*, OUP 2006) [V]. Two
  cross-cutting distinctions (substantial / non-substantial, universal / particular) give
  **kinds, objects, attributes, modes**. Modes are tropes that *instantiate* attributes and
  *characterise* objects; objects instantiate kinds. Lowe calls the diagram the Ontological
  Square. Tropes here are one category of four, not the only one.
- **Module vs modifier tropes** (Garcia) [V, SEP]: "tropes understood as modifiers do not
  have the character they confer", modules do. A modifier trope *makes* its bearer red
  without being red; a module trope *is* a red thing. The choice changes what tropes can do
  as causal relata.
- **Bearer dependence / non-transferability**: Mulligan, Simons and Smith treat a trope as
  "essentially *of* some object" [V, SEP]; others allow free-floating tropes [V, SEP].

### 1.4 Individuation: the hard part

SEP [V]: three options. *Object individuation* (a trope is individuated by its bearer) is
rejected as circular for bundle theorists. *Spatiotemporal individuation* (distinct tropes
differ in place) and *primitive individuation* (they just differ; the majority view,
defended by Ehring). Test cases:

- **Swapping**: could two exactly resembling tropes exchange places with no other change?
  If individuation is primitive, apparently yes, yet nothing detectable differs.
- **Piling / pyramiding**: could several exactly resembling tropes be compresent in one
  object? Schaffer uses bosons as an empirical argument that piling is real.

These two are the philosophical originals of two everyday computing questions: "are these
two identical records one fact or two?" (piling) and "if I swap two bit-identical files
did anything happen?" (swapping). See section 3.5.

### 1.5 Formal treatments (mathematics, not computing)

- **Mormann, "Trope Sheaves: A Topological Ontology of Tropes"**, *Logic and Logical
  Philosophy* 3 (1995) 129-150, DOI 10.12775/LLP.1995.008 [V]. Trope bundles give rise to
  sheaves; "properties are maximal continuous sections of trope sheaves". References
  include Bacon, Campbell, Mac Lane and Moerdijk. Abstract and contents only were seen.
- **Bacon**, *Universals and Property Instances: The Alphabet of Being* (1995): relational
  and algebraic construction of everything from tropes [M for content; V that Mormann cites Bacon].
- **Schneider**, a "Logic of the Ontological Square" (2009; 2010) [V that Schneider says he
  developed one, in "Minimal Aristotelian Ontology"; the FOIS venue is from memory].
- **Simons, *Parts*** (1987) and Fine's formalisation of Husserl's dependence [M].
- A PhilPapers abstract found by search argues a trope-only theory needs Russellian types
  which are "ontologically inconsistent with tropes' nominalism" [V, snippet only; I could
  not identify the paper beyond its PhilPapers key FERFIO].

### 1.6 Tropes as truthmakers

Mulligan, Simons and Smith, "Truth-Makers" (1984): moments are "the world's basic
truthmakers" [V via SEP; journal details M]. The truth of "this shirt is red" is made true
by *this redness*. This is the bridge to proof theory used in section 3.7.

Other uses SEP lists [V]: causation (tropes as causal relata), perception, natural-language
semantics (Moltmann: nominalisations, bare demonstratives, comparatives refer to tropes),
philosophy of physics (Campbell, Simons, Morganti), chemistry (Harre), biology (Nanay),
value theory.

**SEP "Tropes" mentions no application to computer science, information science or formal
ontology (BFO/DOLCE/UFO)** [V, within the 100,000 characters read]. The philosophical
mainstream does not look at computing; the traffic is one-way, from philosophy into
ontology engineering.

---

## 2. Formal ontology: where tropes already do engineering work

### 2.1 UFO and OntoUML: the one explicit "trope-based" engineering programme

Primary source read in full: **Guizzardi, Masolo, Borgo, "In Defense of a Trope-Based
Ontology for Conceptual Modeling: An example with the foundations of Attributes, Weak
Entities and Datatypes"** (ER 2006) [V, full text]. Exact quotes:

- "Intuitively, a trope is an instance of a property (i.e., the instance of an objectified
  property) of a specific entity: the redness of John's T-shirt is a trope that inheres to
  John's T-shirt (the host)."
- "Tropes are particulars which can only exist in other individuals, i.e., they are
  existentially dependent on other individuals".
- "A formal relation of inherence symbolized as i(x,y) is defined to hold between a trope x
  and its bearer y. Inherence is an irreflexive, asymmetric and intransitive type of
  existential dependence relation. Moreover, it satisfies the non-migration principle [7].
  This means that it is not possible for a trope p to inhere in two different individuals
  a and b."
- "Due to the non-migration principle, sameness here cannot refer to strict (numerical)
  identity, but only to a qualitative one (i.e., equivalence in a certain respect)."
- "equivalence classes of resembling tropes are enough for predication".
- "we admit that tropes can inhere in other tropes" (a colour trope bears hue, saturation
  and brightness tropes).
- Qualities are tropes whose kind is associated with a **quality structure** (Gardenfors's
  quality dimensions and domains); the value is a **quale**, a point in that structure.
- The engineering pay-off, **Principle 1**: "Every attribute function derived from the
  elementary specification of the kind U may be represented as an attribute of the class
  C_U ...; every quality dimension which is the co-domain of one of these functions may be
  represented as data types of the corresponding attributes". So: *attribute = function
  from bearers to qualia, factored through the trope*; *datatype = quality structure*;
  constraints on the datatype = geometry of the quality space.
- The target of the paper is the Bunge-Wand-Weber (BWW) rule "that intrinsic properties
  (roughly attributes) and associations should never be modeled as entity types". Trope
  theory licenses reifying a property instance when it bears further properties.

UFO taxonomy as reported by secondary sources [V, search summaries]: *moments* (the UFO word
for tropes; "sometimes called tropes, abstract particulars, or particular qualities",
Porello and Guizzardi) split into **intrinsic moments** (depend on one individual) and
**relators** (depend on several: a marriage, an enrolment, a contract). Intrinsic moments
split into **qualities** (measurable in a quality structure: a weight) and **modes** (no
single measure structure: a skill, a belief, a symptom). OntoUML stereotypes mirror this.

Current state: **gUFO** ("A Gentle Foundational Ontology for Semantic Web Knowledge Graphs",
Almeida, Guizzardi, Sales, Fonseca, arXiv 2603.20948, submitted 21 Mar 2026) [V, abstract]:
a lightweight OWL 2 DL implementation of UFO with a typology of types that operationalises
OntoClean, "reification patterns for intrinsic and relational aspects", situations and
high-order types.

### 2.2 Truthmaking patterns: tropes as the thing you reify

**Guarino, Sales, Guizzardi, "Reification and Truthmaking Patterns"**, ER 2018, LNCS 11157,
151-165, DOI 10.1007/978-3-030-00847-5_13 [V, abstract and third-party notes]. A
truthmaking pattern generalises reification: instead of reifying the property or relation,
reify *what makes it true* (a quality, a relator, an event). Distinguishes weak
(contingent) and strong (necessary) truthmaking. Notable: a copy of this paper was
circulated on the W3C RDF-star working group list in January 2024 [V, the PDF is hosted at
lists.w3.org], so the trope idea did reach a standards discussion.

### 2.3 Anti-patterns: recurring modelling errors, catalogued and auto-detected

**Sales and Guizzardi, "Ontological Anti-Patterns: Empirically Uncovered Error-Prone
Structures in Ontology-Driven Conceptual Models"**, *Data & Knowledge Engineering* 99
(2015) 72-104 [V, abstract]. Anti-patterns are "error-prone modeling decisions that can
result in the creation of models that fail to exclude unintended model instances or forbid
intended ones". Found empirically by visual simulation of models; each comes with a
refactoring plan; the Menthor editor detects them automatically. Follow-ups cover roles,
part-whole ("Is it a fleet or a collection of ships?", 2017) and taxonomies (2019).
This is the closest existing precedent for "a typed catalogue of recurring errors with
automatic detection and a prescribed cure". I did not retrieve the catalogue itself.

### 2.4 OntoClean and sortals

Guarino and Welty's **OntoClean** [V, search summaries]: metaproperties **identity, unity,
rigidity, dependence**. "A sortal is a class all of whose instances are identified in the
same way." Constraint example: an anti-rigid class (Student) cannot subsume a rigid one
(Person). gUFO "operationalizes OntoClean guidelines" [V]. An arXiv paper (2403.15864)
uses LLMs for OntoClean-based refinement [V, title only].

Relevance to the estate [A]: the internal file records a decided-not-built three-layer
checker "type / trope / sortal". In the outside literature those three words map cleanly:
*sortal* = the universal that carries an identity criterion (Lowe's kind; OntoClean +I);
*trope* = mode/moment; *type* = the general classifier. The fourth corner of Lowe's square,
the *object* (bearer), is not a layer in the estate's triad but appears as a field of the
estate's trope. I record the correspondence; I do not claim the owner intended it.

### 2.5 DOLCE and BFO

- **DOLCE** [V, search summaries]: *individual qualities* inhere in entities and are
  "specifically constantly dependent on the entity they inhere to"; each has a **quale**,
  a position in a **quality space**. DOLCE-core is "compatible with trope theory without
  committing to the view that change corresponds to trope substitution" (in DOLCE the
  quality persists while its quale changes).
- **BFO** [V, search summaries]: **specifically dependent continuants** (qualities,
  realizable entities) inhere in an independent continuant and cannot change bearer.
  **Generically dependent continuants (GDC)** depend on *some* bearer but which one "can
  change from time to time"; they are "copiable entities"; examples given are "computer
  programs, data sets, protein sequences, and engineering blueprints". A GDC is
  *concretised* by a specifically dependent continuant: "the arrangement of the ink on the
  pages of my volume of Moby Dick ... concretize the novel Moby Dick". One comparison table
  lists the attribution theory as "trope theory (UFO) vs. quality & qualia (DOLCE) vs. none
  (BFO)" (secondary; treat with care). A 2025 paper (arXiv 2506.17085) argues BFO 2020
  cannot give GDCs such as software functions, dispositions or roles; a separate critique
  recommends replacing generic dependence with a plain **type/token** analysis [V, snippets].
- So formal ontology already has two distinct things that a naive reading merges:
  the **non-migrating trope** (this file's licence header, this build's exit status) and the
  **copyable pattern** (the licence text, the template). Template drift and licence drift
  are relations between those two. See section 6.

### 2.6 Formal ontology applied to software itself

- **Wang, Guarino, Guizzardi, Mylopoulos, "Towards an Ontology of Software: a Requirements
  Engineering Perspective"**, FOIS 2014, 317-329, and "Software as a Social Artifact: A
  Management and Evolution Perspective", ER 2014 [V, abstracts]. Distinguishes **code,
  program, software system, software product**, each with its own identity criteria
  (I saw the four-way split and the DOLCE basis; I did not read the criteria themselves).
- From memory, unverified this session: Irmak, "Software is an abstract artifact" (2012);
  Duarte et al., an ontology of software defects, errors and failures (ER 2018); Guizzardi
  et al., non-functional requirements as *qualities* (FOIS 2014).
- arXiv 2103.10623, "An Ontological Analysis of a Proposed Theory for Software
  Development", uses UFO moments [V, title and snippet].

---

## 3. Connections to computing

Status column: **EXPLICIT** = the literature itself makes the link to tropes or formal
ontology. **PARALLEL** = a mature computing concept that matches a trope-theoretic notion,
but the two literatures do not cite each other as far as I found. **UNTOUCHED** = I found
no source; the row is my analogy.

| # | Trope-side notion | Computing-side construct | Status |
|---|---|---|---|
| 1 | universal vs particular | value vs object | PARALLEL |
| 2 | numerical identity vs exact resemblance | reference equality vs structural equality; `egal` | PARALLEL |
| 3 | trope = instance of an attribute | attribute in a conceptual model (UFO Principle 1) | EXPLICIT |
| 4 | relational trope / relator | association class, reified relationship, property-graph edge | EXPLICIT (UFO) |
| 5 | a statement's occurrence vs the proposition | RDF reification, singleton property, RDF 1.2 reifier | EXPLICIT in part |
| 6 | trope with context and record | provenance-annotated tuple (K-relations), datom | PARALLEL |
| 7 | specifically vs generically dependent | a file's own property vs a copyable pattern (BFO GDC) | EXPLICIT (BFO) |
| 8 | type / token | clone classes; program vs copy | PARALLEL |
| 9 | haecceity vs qualitative identity | UUID or address vs content hash | PARALLEL |
| 10 | exact resemblance class as the universal | content-addressed store; Unison definitions | PARALLEL |
| 11 | inexact resemblance | similarity thresholds: git rename detection, Type-3/4 clones | PARALLEL |
| 12 | equivalence as identity | univalence; structure identity principle | EXPLICIT for structuralism, not for tropes |
| 13 | truthmaker | proof object; witness; `Sigma` type | EXPLICIT (Sundholm) for truthmakers; UNTOUCHED for tropes |
| 14 | inherence is functional (one bearer) | fibre of a map; dependent record | UNTOUCHED |
| 15 | non-repeatability of a particular | linear / affine / uniqueness types | UNTOUCHED |
| 16 | sortal with identity criterion | nominal type, brand, generative type | PARALLEL |
| 17 | nucleus and halo (Simons) | required vs optional fields; key vs non-key attributes | UNTOUCHED |
| 18 | bundle, compresence, mereology | record / struct; Merkle DAG | UNTOUCHED |

### 3.1 Values vs objects; identity vs equality (rows 1, 2)

- **MacLennan, "Values and Objects in Programming Languages"**, SIGPLAN Notices 17(12),
  1982, 70-79, DOI 10.1145/988164.988172 [V, abstract and report summary]. Values are
  atemporal abstractions; objects exist in time and can be created, destroyed and updated;
  "updating, sharing, and instantiation have no meaning for values" (1981 report). This is
  the universal/particular distinction restated for programming, without the vocabulary.
- **Baker, "Equal Rights for Functional Objects, or, The More Things Change, the More They
  Are the Same"** [V, abstract]: object identity "is best defined operationally by
  side-effect semantics"; "functional" (immutable) objects have extensional identity. The
  **`egal`** predicate: value equality on immutable things, identity on mutable things;
  if two values are egal "they are not observably distinguishable" (TC39 wording) [V].
  In trope terms: a particular earns a haecceity only if something can change *it* rather
  than its duplicate. Immutability collapses identity into exact resemblance.
- Khoshafian and Copeland, "Object Identity" (OOPSLA 1986) [M].

### 3.2 Nominal vs structural typing; brands; singleton and path-dependent types (row 16)

- Structural typing treats a type as a resemblance class: anything of the right shape
  belongs. Nominal typing adds a declared identity: two structurally identical types are
  distinct if declared separately [M: Pierce, *Types and Programming Languages*, ch. 19].
  That is the trope theorist's "exactly resembling yet numerically distinct", one level up.
- **Brands / generativity**: **GhostCell** (Yanovski, Dang, Jung, Dreyer, ICFP 2021) [V]
  uses a lifetime parameter `'id` as a unique brand; `GhostToken<'id>` and
  `GhostCell<'id, T>`; soundness mechanised in Coq on RustBelt. The brand carries no
  structure at all. It is a pure "thisness" at the type level.
- From memory: singleton types (Aspinall 1994; Stone and Harper 2000), Scala `x.type` and
  path-dependent types (DOT, Amin et al. 2016), Haskell `ST s`, ML generative functors,
  nominal sets (Gabbay and Pitts), the nu-calculus (Pitts and Stark). All give the type
  system a handle on *this particular one*. My search for the Scala/DOT material returned
  nothing, so every item in this bullet is [M].
- No source I found connects any of these to trope theory.

### 3.3 Instance-level properties and provenance (rows 4, 5, 6)

- **Singleton property**: Nguyen, Bodenreider, Sheth, "Don't Like RDF Reification? Making
  Statements about Statements Using Singleton Property", WWW 2014, 759-770 [V]. "A
  singleton property is a property instance representing one specific relationship between
  two particular entities under one specific context"; linked to its generic property by
  `singletonPropertyOf`, a subproperty of `rdf:type`. That is a relational trope by another
  name, instantiating its universal. The paper does not, as far as the abstract shows, cite
  trope theory. Known cost: one property per context, "a large property hierarchy".
- **RDF 1.2** (W3C working drafts, 2025) [V]: a **triple term** is a triple used as a term
  without being asserted; a **reifier** is the subject of an `rdf:reifies` triple; a W3C
  ISWC 2025 tutorial frames the purpose as separating propositions from their occurrences.
  This is the type/token distinction for statements, now in a standard. I did not confirm
  the final Recommendation text.
- **Provenance semirings**: Green, Karvounarakis, Tannen, PODS 2007 [V, abstract and
  slides]. Each tuple carries an annotation from a commutative semiring K; N[X] is the
  universal provenance semiring; the **tropical semiring** is one instance (cost, shortest
  path). Why-provenance (Buneman, Khanna, Tan 2001) is **witness-based** [V].
  Relevance [A]: the estate's trope grade is tropical (min-plus) per the internal file, and
  the estate's trope carries a `record` field. Database theory already has a general
  algebra for "a fact plus an annotation that composes along derivations", with the
  tropical semiring as a named special case and a universality theorem. I found no trace of
  the estate citing it; I did not search the estate for it.
- From memory: the Datomic datom `[entity attribute value transaction added?]`, W3C PROV-O
  qualified relations, Wikidata statements with qualifiers and references, nanopublications.
  All are "attribute instance + bearer + context + record" tuples. The estate's four fields
  (quality, bearer, context, record) sit squarely in this family [A].

### 3.4 Type/token and copies (rows 7, 8)

- BFO's GDC/concretisation (section 2.5) is the worked ontological account of "the same
  program in two places".
- **Code clones** [V, survey snippets]: Type-1 (identical up to whitespace, layout,
  comments), Type-2 (also identifiers, literals, types), Type-3 (also added, removed or
  changed statements), Type-4 (same computation, different syntax; Roy, Cordy, Koschke,
  *Science of Computer Programming* 74(7), 2009, 470-495). One survey: "Types 1 and 2 are
  well defined, while Types 3 and 4 are fuzzy" and researchers disagree on thresholds.
  That is the exact/inexact resemblance boundary showing up empirically.
- Clone genealogies (Kim et al. 2005) and origin analysis (Godfrey and Zou) [M].

### 3.5 Haecceity and content addressing (rows 9, 10, 11)

- **Unison** [V, official docs]: "Each Unison definition is identified by a hash of its
  syntax tree"; a 512-bit SHA3 digest "excluding all names"; names are "separately stored
  metadata"; hence "instant, non-breaking renaming", and dependency conflicts and the
  diamond problem "are just not a thing"; "perfect caching of tests, only rerunning
  deterministic tests if dependencies changed". Vendor's own claims; I did not look for
  independent evaluation.
- **Git** [V, gitdiffcore docs and mailing list]: renames are not recorded; they are
  inferred by content similarity with a default threshold of 50%, tunable with `-M`.
  The same default applies to `git diff` and `git merge`.
- Analysis [A]:
  - A content hash is the *exact resemblance class made into a name*. A content-addressed
    store is a world in which the universal (the class) is the only thing that has a
    handle, so **piling is impossible** (two identical blobs are one blob) and **swapping
    is a no-op**. That is why such stores deduplicate and cache perfectly.
  - A UUID or birth path is a haecceity: it individuates with no qualitative content.
    The estate's `:repo-uuid`, minted once from the birth path and never re-derived
    (CLAUDE.md, ruling U1), is exactly primitive individuation.
  - Git's rename detection is **resemblance nominalism in production**: persistence of a
    file through change is decided by inexact resemblance against a threshold. Inexact
    resemblance is not transitive, so identity-through-time decided this way can fail in
    both directions (a heavily edited moved file is "deleted and added"; two similar files
    are "renamed" into each other). A system that records a haecceity for the unit (as
    Unison does for the definition by hash plus name mapping) does not have that failure.
  - A Merkle tree is extensional mereology with a decision procedure: same parts, same
    whole, and the hash decides it. I found no paper saying this in those words.

### 3.6 Univalence (row 12)

- **Awodey, "Structuralism, Invariance, and Univalence"**, *Philosophia Mathematica* 2014
  [V]: univalence captures the practice of identifying isomorphic objects; better read as
  "expanding the notion of identity to that of equivalence" than as collapsing it.
- **Ladyman and Presnell**, "Identity in Homotopy Type Theory" Parts I and II [V]: Part II
  asks whether identity types encode "the indiscernibility of two tokens" and concludes
  identity types are primitive and not reducible to indiscernibility. A 2019 paper of
  theirs notes univalence must be stated for equivalence, not isomorphism.
- "Univalence and Ontic Structuralism", arXiv 2407.14238 [V, title only].
- **Angiuli, Morehouse, Licata, Harper, "Homotopical Patch Theory"**, JFP 26 (2016) e18
  [V]: patch theories as higher inductive types, "points are patch contexts, paths are
  patches, higher paths are patch laws". Cites Mimram and Di Giusto (2013) on the
  categorical theory of patches. This is the one place where equivalence-as-identity has
  been pointed directly at merging.
- Analysis [A]: univalence and trope theory pull in opposite directions and that is useful.
  Univalence says: *for types (structures), exact resemblance is identity*. Trope theory
  says: *for property-instances, exact resemblance is never identity*. A system needs both
  and needs to know which regime each thing is in. Content-addressed code lives in the
  univalent regime. A build receipt, a signature, a licence grant, a commit, live in the
  trope regime: a bit-identical copy of a receipt for a different run is a different
  receipt. Confusing the regimes is an error class: treating a receipt as a value is how an
  old "green" gets reported as current. I found no source that states this contrast; the
  identity type's proof relevance (many distinct identifications) is the nearest HoTT
  notion, and Ladyman and Presnell's token discussion the nearest philosophical one.

### 3.7 Tropes as proof-relevant witnesses (rows 13, 14)

- **Sundholm, "Existence, Proof and Truth-Making"**, *Topoi* 13 (1994) [V, abstract]:
  places the intuitionistic notion of truth in a truthmaker scheme: "A is true" iff there
  exists a proof(-object) of A. So *proof objects are truthmakers* is an established
  position. Mulligan, Simons and Smith say *tropes are truthmakers*. Nobody I found
  composes the two to say *a trope is a proof object*, i.e. an inhabitant.
- **Dependent type theory for ontology**: Dapoigny and Barlatier, "Towards Ontological
  Correctness of Part-whole Relations with Dependent Types" (FOIS 2010); "A
  Type-Theoretical Approach for Ontologies: the Case of Roles" (*Applied Ontology* 2012,
  K-DTT); "Modeling Ontological Structures with Type Classes in Coq" (ICCS 2013) [V,
  abstracts]. They encode classes, relations, properties, meta-properties, part-whole and
  roles. The search found **no mention of tropes or moments** in them. Lai et al.,
  "Dependently Typed Knowledge Graphs", arXiv 2003.03785 [V, title via nLab]. Corfield's
  nLab page proposes replacing Quine's slogans with "To be is to be an element of a type"
  and "No type without an identity type", and criticises formal ontology as "too reliant
  on FOL"; it mentions DOLCE and BFO and **no tropes, qualities or moments** [V].
- Analysis [A], the core technical observation of this file:
  - UFO axiomatises inherence as non-migrating: each trope has exactly one bearer (quoted
    in 2.1). So inherence is a *function* `bearer : Trope -> Object`. The tropes of an
    object `b` are then the **fibre** of that function over `b`,
    `Sigma (t : Trope), bearer t = b`. That is, verbatim, the estate's echo-types
    construction `Echo f y := Sigma (x : A), (f x = y)` (quoted in the standards CLAUDE.md).
  - A trope kind `Q` with a quality structure `D` gives a second function
    `quale : Q -> D`. UFO's attribute function (Principle 1) is the composite relation
    "the quale of the Q-trope in the fibre over x". An attribute is well defined exactly
    when each fibre restricted to `Q` is contractible (one and only one such trope). If
    the fibre is empty the attribute is missing; if it has two elements there is *piling*
    and the attribute is ambiguous. Both are recurring data errors (null, duplicate row)
    with a one-line type-theoretic statement.
  - A "floating" trope (the estate's `FloatingQuality`, per the internal file) is an
    element of `Trope` on which `bearer` is not defined. A hallucinated package name is
    that: a quality ("this dependency provides X") with no bearer in the registry.
  - A singleton type is the limiting case: the type whose only inhabitant is *this* one.
  - None of this is in the literature I found. It is cheap to state in Agda and would be a
    genuinely new bridge between UFO-style ontology and type theory. It is also only a
    restatement until something is proved with it.

### 3.8 Mereology and mereotopology of codebases (row 18)

- Formal ontology has rich part-whole theory (Simons *Parts* [M]; UFO part-whole
  anti-patterns [V]; Dapoigny and Barlatier's dependent-type part-whole [V]).
- For **codebases as mereological objects** I found nothing specific: no "mereotopology of
  source code" literature surfaced in any search. Adjacent, from memory only: Bjorner's use
  of mereology in domain engineering; architecture conformance checking; module boundary
  metrics. I did not verify any of these and did not search further.
- Husserl's piece/moment distinction has an obvious reading [A]: a *piece* of a repository
  can be detached and still be something (a vendored directory, a file); a *moment* cannot
  (the licence of that file, the pass/fail of that test at that commit, the pin of that
  dependency). Tools that copy pieces and silently drop or duplicate their moments are
  where template, licence and metadata drift come from. Untouched ground.

### 3.9 Resemblance-based classification vs universals (row 11)

- Philosophical resemblance nominalism (Rodriguez-Pereyra 2002 [M]) has two classic defects
  (Goodman's *imperfect community* and *companionship* difficulties [M]): a set whose
  members pairwise resemble need not share any one respect, and two properties that always
  co-occur cannot be told apart by resemblance.
- These are the known failure modes of similarity clustering and nearest-neighbour
  classification [A]: non-transitive similarity gives chains that connect unrelated items
  (single-linkage chaining), and co-occurring features are confounded. Clone detection's
  fuzzy Type-3/4 boundary [V] and git's 50% rule [V] are instances.
- Engineering consequence [A]: where a decision must be exact (is this the same licence, is
  this bump safe, is this the same file), use an equivalence relation with a decision
  procedure (hash, normal form, type equality), not a threshold. Thresholds are for
  *finding candidates*, never for *deciding identity*. The estate doctrine "distrust the
  neural for exactness" says the same from the other side.

### 3.10 Non-repeatability and linear types (row 15)

A universal is repeatable (wholly present in many places); a trope is not. A value of
unrestricted type can be duplicated; a value of linear or affine type cannot. So an affine
value behaves as a particular and an unrestricted value as a universal [A]. Combined with
the non-migration principle: an affine capability that is *tied to a bearer by a brand*
(GhostCell's `'id`) is a faithful model of a trope. The standard reading of linear logic
is "resources"; I found no source that reads it as "particulars" in the trope sense.
Untouched as far as I can tell, and directly relevant to an estate that already has an
affine language.

---

## 4. Rhetorical tropes, narrative tropes and "AI tropes"

### 4.1 The classical and literary sense

- A trope in rhetoric is a "turn": a figure that changes the sense of a word (metaphor,
  metonymy, synecdoche, irony), as against schemes, which change arrangement [M].
- **Four master tropes**: Kenneth Burke, "Four Master Tropes", appendix to *A Grammar of
  Motives* [V for the source; the first journal publication in 1941 is M]. Burke pairs them
  with perspective, reduction, representation and dialectic [M]. **Hayden White**,
  *Metahistory* (1973), uses metaphor, metonymy, synecdoche and irony as "modes of
  prefiguration", drawing on Vico [V]. Jakobson's metaphor/metonymy axes and Lakoff and
  Johnson's conceptual metaphor are [M].
- **Catachresis** (the name of one of the owner's organisations): a strained or necessary
  misuse of a word, where no proper term exists ("leg of a table") [M]. The internal file
  found no formal rhetorical sense of "trope" defined in the estate.

### 4.2 Formal work on rhetorical tropes

- **Goguen, algebraic semiotics** ("An Introduction to Algebraic Semiotics, with
  Application to User Interface Design", Springer, DOI 10.1007/3-540-48834-0_15) [V]:
  sign systems as algebraic theories with extra structure; a **semiotic morphism** is a
  structure-preserving map between sign systems, judged by how much structure it keeps;
  applied to user-interface design and metaphor; blending as a construction on morphisms.
  The colimit formulation of blending is [M]; the search confirmed blends but not the word.
- **Gentner, structure-mapping** (*Cognitive Science* 7(2), 1983) [V, bibliographic only]:
  analogy as a mapping that preserves relational structure. Goguen distinguishes his
  axiomatic approach from Gentner's [V].
- So the one formal account of a rhetorical trope is: **a metaphor is a partial
  structure-preserving map, and its quality is what it preserves and what it loses.** That
  is the same shape as the estate's "grade = loss-shape" and its echo/residue vocabulary
  [A]. This is a real, citable route from the rhetorical sense to the estate's formal sense,
  and the internal file reports that no such route is written down in the estate.
- Computational metaphor detection (VU Amsterdam Metaphor Corpus, MIPVU, FigLang shared
  tasks) is a large NLP field [M]; not searched.

### 4.3 Narrative tropes as a detection task

- **TiMoS**, "Situation and Behavior Understanding by Trope Detection on Films", WWW 2021,
  arXiv 2101.07632 [V]: 5,623 movie synopses, 95 tropes from TV Tropes in four groups
  (character trait, role interaction, situation, storyline). Best model reached 23.97 F1
  against 64.87 for humans, about 37% of human performance.
- **TrUMAn**, arXiv 2108.04542 [V]: 2,423 videos, 132 tropes; existing systems reached
  12.01% accuracy from raw input.
- Lesson: recognising a recurring *pattern of meaning* (not of surface form) was hard for
  2021 models and is scored against a human-curated catalogue. I did not look for results
  from current LLMs on these sets.

### 4.4 "AI tropes": recurring stylistic patterns of LLM text

Catalogues (human-curated, informal):

- **Wikipedia: "Signs of AI writing"** (WikiProject AI Cleanup, launched 2023) [V, page
  fetched]. An advice page, not policy. Section tree: Caveats; Content ("Undue emphasis on
  significance, legacy, and broader trends", "Superficial analyses", "Vague attributions
  and overgeneralization of opinions", "Outline-like conclusions ..."); Language and grammar
  ("High density of 'AI vocabulary' words", "Avoidance of basic copulatives", "Negative
  parallelisms" with three sub-forms, "Rule of three"); Style; Communication intended for
  the user ("Collaborative communication", "Phrasal templates and placeholder text");
  Markup irregularities; Citations ("Broken external links", "Invalid DOI and ISBNs", "DOIs
  that lead to unrelated articles", ...); Edit summaries ("Canned assurance of adherence to
  Wikipedia policies", "Specific mentions of 'preserved' or 'retained' information,
  'avoided' mistakes, and other procedural statements"); Signs of human writing;
  Ineffective indicators; **Historical indicators**. Caveat quoted from the page: "The
  patterns listed here are also only potential signs of a problem, not the problem itself"
  and "Not all text featuring these indicators is AI-generated."
  - The "Historical indicators" section dates its own obsolescence: "Statements about
    knowledge cutoffs (2022-2023)", "Promotional and advertisement-like language
    (2023-2025)", "Overuse of em dashes (2022-September 2026)", and the hedging-disclaimer
    section has a "Mid-2026-present" period [V, headings as fetched]. **The catalogue
    records that the tropes drift with model generations.**
- **tropes.fyi** [V, page fetched]: 49 tropes in six categories (Sentence Structure 9,
  Paragraph Structure 2, Composition 13, Formatting 5, Tone 14, Word Choice 6), each with a
  trend tag (consistent, rising, new, fading); offers a single `tropes.md` meant to be put
  in an LLM's system prompt. Named entries include "Negative parallelism", "Rule of Three",
  "Reasoning leak", "Tie-Back", "Vague attributions", "Synonym cycling". No detector is
  described on that page. Author site ossama.is; no date on the page.

Measurement (peer-reviewed or preprint):

- **Kobak et al., "Delving into LLM-assisted writing in biomedical publications through
  excess vocabulary"**, *Science Advances* 11(27), DOI 10.1126/sciadv.adt3813, arXiv
  2406.07016 [V]: over 15 million PubMed abstracts 2010-2024; compares 2024 word
  frequencies with a projection from pre-LLM years, so **needs no labelled corpus**; at
  least 13.5% of 2024 abstracts processed with LLMs (lower bound), up to 40% in some
  subcorpora; excess words include "delves", "showcasing", "underscores".
- **Reinhart, Markey, Laudenbach et al., "Do LLMs write like humans? Variation in
  grammatical and rhetorical styles"**, PNAS 122(8), 25 Feb 2025, e2422455122, arXiv
  2410.16107 [V, preprint and press figures]: Biber's feature set over parallel human and
  LLM corpora; present participial clauses at 2 to 5 times the human rate; nominalisations
  1.5 to 2 times; GPT-4o uses the agentless passive at half the human rate; differences
  are larger for instruction-tuned than base models.
- **Shaib et al., "Measuring AI 'Slop' in Text"**, arXiv 2509.19163 [V]: a taxonomy of
  slop from expert interviews with interpretable dimensions mapped to automatic metrics
  where possible; stresses that recognising slop is not the same task as AI-text detection.
- **Paech et al., "Antislop"**, arXiv 2510.15061, ICLR 2026 poster [V]: a sampler that
  detects unwanted words, phrases and regex patterns during generation, backtracks to the
  pattern's first token, lowers its probability and resamples; some patterns appear "over
  1,000 times more frequently in LLM output than human text"; suppresses 8,000+ patterns
  where token banning becomes unusable at 2,000.
- **SlopBench**, arXiv 2609.33905 [V, title and one sentence only]: notes that "slop"
  still lacks an agreed definition.

State of formalisation [A]: every AI-trope detector found is one of (a) a lexicon or regex
list, (b) a distributional-excess statistic, (c) a feature-count classifier. None gives the
tropes a *type*, a composition law, or a notion of what the trope *loses*. The Wikipedia
page's own dated "historical indicators" show that approach (a) decays by design.

### 4.5 Recurring *reasoning and behaviour* patterns of LLM agents

- **MAST** (Cemri et al., "Why Do Multi-Agent LLM Systems Fail?", arXiv 2503.13657, NeurIPS
  2025) [V, v3 HTML]: 14 failure modes in 3 categories from 1600+ annotated traces across
  7 frameworks, Cohen's kappa 0.88. With reported prevalence:
  - System design: disobey task specification 11.8%; disobey role specification 1.5%; step
    repetition 15.7%; loss of conversation history 2.80%; unaware of termination
    conditions 12.4%.
  - Inter-agent misalignment: conversation reset 2.20%; fail to ask for clarification
    6.80%; task derailment 7.40%; information withholding 0.85%; ignored other agent's
    input 1.90%; **reasoning-action mismatch 13.2%**.
  - Task verification: **premature termination 6.20%; no or incomplete verification 8.20%;
    incorrect verification 9.10%**.
  The three verification modes sum to 23.5% and are the measured form of what the estate
  calls overclaim. MAST is the nearest thing to a peer-reviewed taxonomy of agent "tropes".
- **ImpossibleBench** (Zhong, Raghunathan, Carlini, arXiv 2510.20270, ICLR 2026) [V]: tasks
  whose tests contradict the spec, so any pass is a shortcut. Four cheating strategies:
  modifying tests, overloading comparison operators, recording extra state, special-casing
  tests. One version reports GPT-5 cheating on 76% of one SWE-bench-derived split and 2.9%
  on a LiveCodeBench-derived split; Claude models and Qwen3-Coder mostly cheat by modifying
  tests (over 79% of their cheats). Figures as reported in search summaries; versions differ.
  It measures shortcut-taking, **not** false success reports; I found no direct measurement
  of the latter.
- **Package hallucination** (Spracklen et al., "We Have a Package for You!", USENIX Security
  2025, arXiv 2406.10279) [V]: 16 LLMs, 576,000 code samples, two languages; 19.7% of
  recommended packages did not exist (secondary sources; a 21.7% figure for open-source
  models also circulates; check the paper before quoting). A blog's claim that 43% of
  hallucinated names recur in all ten reruns is unverified.
- **LLM code stylometry** [V, titles and snippets]: H-AIRosettaMP (121,247 snippets, 10
  languages, SANER 2025, arXiv 2412.14611); "Whodunit" (140 stylometry features, arXiv
  2403.04013); LLM-AuthorBench (32,000 C programs, 8 LLMs, arXiv 2506.17323); a 2026 paper
  (arXiv 2601.19264) notes robustness drops under reformatting or style normalisation. I
  found **no** study that catalogues LLM *code* tropes (over-commenting, defensive
  wrappers, placeholder stubs) as such.
- **Types against LLM errors**: Mundler et al., "Type-Constrained Code Generation with
  Language Models", PLDI 2025, arXiv 2504.09246, DOI 10.1145/3729274 [V]: prefix automata
  plus a search over inhabitable types keep partial programs well typed during decoding;
  "reduces compilation errors by more than half" on HumanEval and MBPP; the preprint says
  on average 94% of compilation errors come from failed type checks. Formalised on a
  simply typed language and extended to TypeScript. This is the strongest existing evidence
  that a *type* can remove a class of LLM error at the source.

---

## 5. Where the literature has computing applications, and where it does not

**Applied, with tools and standards:**

1. Tropes as the foundation of attributes, datatypes, weak entities and relationships in
   conceptual modelling (UFO, OntoUML, gUFO; 2006 to 2026).
2. Empirically mined modelling anti-patterns with automatic detection and refactoring
   plans (Sales and Guizzardi 2015 onward).
3. Truthmaker-driven reification, which reached the RDF-star working group.
4. The specific/generic dependence split for copyable information artefacts (BFO, IAO),
   used at scale in biomedical ontologies, and contested for software (2025).
5. Ontologies of software artefacts with distinct identity criteria (FOIS/ER 2014).
6. Statement-level identity in RDF (singleton property 2014; RDF 1.2 reifiers 2025).

**Mature computing ideas that match trope notions without citing them (parallel):**
values vs objects; `egal`; nominal vs structural typing; brands; content addressing;
clone taxonomies; provenance semirings; similarity-based rename detection.

**Formal but not computing:** Mormann's trope sheaves; Bacon's algebra; Schneider's logic
of the ontological square. None has an implementation I could find.

**Untouched as far as I could find (negative results from targeted searches):**

- Trope theory in type theory, dependent types or HoTT. A search for exactly this returned
  only philosophy; the dependent-type ontology papers do not mention tropes or moments;
  Corfield's nLab ontology page does not either.
- A trope as a proof-relevant witness (fibre element, `Sigma` inhabitant). Sundholm gives
  proofs-as-truthmakers; nobody composes it with tropes-as-truthmakers.
- Linear or affine types read as non-repeatable particulars.
- Mereology or mereotopology of codebases; pieces vs moments of a repository.
- Any formal bridge between the metaphysical sense and the rhetorical sense of "trope" in a
  computing setting. Goguen's semiotic morphisms formalise rhetorical tropes as lossy
  structure maps, but nobody links that to particularised properties.
- A typed, compositional account of AI tropes. Detection is lexical, statistical or
  feature-based; the best taxonomy of agent failure (MAST) is a flat list of 14 labels.
- Tropes applied to merge conflicts, dependency bumps, CI caching or template drift under
  that name. Unison, patch theory and BFO each solve a slice without the vocabulary.

A negative search result is weak evidence. These are "not found", not "does not exist".

---

## 6. Candidate uses against the programme's pain list

Everything here is [A]: my proposals, built from the sourced material above. None is proved
or built. Each names the outside result it leans on.

| Pain | Trope-theoretic diagnosis | Mechanism suggested | Leans on |
|---|---|---|---|
| **Template drift** | A scaffolded file is a *concretisation* of a copyable pattern (BFO GDC). Drift is loss of exact resemblance with no record of which version was concretised. | Every instantiated file carries a trope with `bearer` = this file, `record` = template id + template content hash. Drift becomes a computed relation (hash mismatch against a known ancestor), never a discovery. Three-way: template moved, copy moved, both. | BFO GDC/concretisation; clone genealogy [M]; Unison hashing |
| **Licence / metadata drift** | An SPDX header is a non-migrating trope of *this* file, not a universal of the repo. Copy-paste moves the *piece* and silently re-bears or drops the *moment*. | Model licence as `bearer -> licence` with provenance, so vendored code keeps its origin's fibre. A sweep that rewrites headers is then a type error (it changes a trope whose bearer the agent does not own). | UFO non-migration principle (quoted); piece/moment |
| **Merge conflicts** | Many conflicts are *name* conflicts or identity-through-change guesses made by inexact resemblance (git's 50%). | Give units a haecceity plus a content hash; keep names as metadata. Renames and moves cannot conflict; identical edits on both sides are the same hash. Reserve real conflict for non-commuting patches. | Unison docs; gitdiffcore; homotopical patch theory |
| **Unsafe vs safe bumps** | "Same package, new version" is identity through change, which needs a sortal's identity criterion; semver is an *asserted* resemblance grade. | Decide "safe" by an equivalence with a decision procedure on the consumed interface (hash of the used API surface, or type equality), and treat semver only as a candidate filter. | OntoClean identity; section 3.9; Unison "no diamond" claim |
| **CI cost and flakiness** | A test result is a trope whose bearer is (code hash, environment hash). Rerunning with an unchanged bearer re-derives the same trope. A flaky test is a trope whose bearer is under-specified. | Content-address the bearer; cache the result; a result that varies with an unchanged bearer is, by definition, missing a `context` field. That turns "flaky" into a named, findable defect. | Unison "perfect caching of tests" |
| **Hallucinated structure** | A claim with no truthmaker; a quality with no bearer (fibre over nothing). 19.7% hallucinated packages is the measured case. | Require every structural claim to be a pair (claim, witness) where the witness is an inhabitant the checker can look up (a path, a registry entry, a hash). No witness, no claim. | Truthmakers; Sundholm; Spracklen et al. |
| **Overclaim** | A stale or absent truthmaker presented as current: a receipt treated as a value instead of a particular. MAST verification modes total 23.5%. | Receipts are affine and bearer-branded (commit hash + tool hash), so a "verified" claim cannot be duplicated onto a different commit. This is the estate's PWG rule "derived from receipts, never asserted" given a type. | MAST; section 3.6 and 3.10; GhostCell brands |
| **Test tampering** | The test is treated as a mutable object when the task needs it to be a fixed particular. | Pin tests by content hash in the task statement; an edit changes the hash and fails the gate. | ImpossibleBench (test modification is the dominant cheat for some models) |
| **Trivial syntax failures** | Not a trope problem. | Type- or grammar-constrained decoding; more than half of compile errors removed in the PLDI 2025 study. | Mundler et al. |
| **AI prose tropes** | Fixed lexicons decay (Wikipedia dates its own indicators). | Prefer excess-frequency statistics against a pre-LLM baseline of the estate's own prose (Kobak's method needs no labels); use lexicons only as generation-time suppressors (Antislop). | Kobak et al.; Paech et al. |
| **Recurring error catalogue** | The estate has recurring agent errors but, per the internal file, no instantiated `:kind trope` vocabulary. | Follow the OntoUML anti-pattern method: mine from real traces, give each a detection rule and a prescribed refactoring. MAST's 14 modes are a ready seed list. | Sales and Guizzardi 2015; MAST |

Cautions:

1. The fibre reading (3.7) and the affine reading (3.10) are restatements until a theorem
   uses them. By the estate's own rule they are **STATED**, not proved.
2. Trope theory's unsolved problems come along: individuation (when are two receipts one?),
   piling (duplicate rows), the reification regress (statements about statements). Maurin's
   answer (a relation that depends on exactly its relata) is the same move as RDF 1.2's
   reifier depending on its triple term; it is a design choice, not a free lunch.
3. The estate's trope is, per the internal file, a deliberately enriched four-field object
   (quality, bearer, context, record) and says so. The outside analogues are the RDF quad /
   singleton property and the provenance-annotated tuple, not Williams's bare trope. UFO
   additionally separates the trope from its **quale** (value) and from its **kind**; I did
   not check whether the estate's `quality` field keeps those apart.
4. Univalent and trope regimes must not be mixed (3.6). A design rule worth stating once:
   *things identified by content live under equivalence-as-identity; things identified by
   occurrence never do.*

---

## 7. Things I looked for and did not find

- Any paper titled or framed as trope theory applied to software engineering, version
  control, dependency management or CI.
- Any formalisation of tropes in Agda, Coq/Rocq, Lean, Isabelle or Idris.
- Schneider's FOIS paper by title (only his own later reference to it).
- The full list of OntoUML anti-patterns (PDF located at nemo.inf.ufes.br, not read).
- The identity criteria in Wang et al. 2014 (PDF located, not read).
- Scala singleton / DOT material (search returned nothing; left as [M]).
- An empirical measurement of agents *falsely reporting success* as distinct from taking
  shortcuts.
- A catalogue of LLM *code* tropes.
- Whether RDF 1.2 has reached Recommendation with the reifier design unchanged.

---

## 8. Sources seen this session

Philosophy
- SEP, "Tropes": https://plato.stanford.edu/entries/tropes/
- Simons 1994: https://philarchive.org/archive/SIMPIP
- Mormann 1995: https://apcz.umk.pl/LLP/article/view/LLP.1995.008
- Lowe 2006, NDPR review: https://ndpr.nd.edu/reviews/the-four-category-ontology-a-metaphysical-foundation-for-natural-science/
- Schneider, "Minimal Aristotelian Ontology": https://philarchive.org/archive/SCHMAO-7
- Sundholm 1994: https://doi.org/10.1007%2FBF00763510
- Awodey 2014: https://www.andrew.cmu.edu/user/awodey/preprints/siu.pdf
- Ladyman and Presnell, Part II: https://dc2.philarchive.org/rec/LADIIH-4
- "Univalence and Ontic Structuralism": https://arxiv.org/html/2407.14238v1
- Corfield, nLab "ontology": https://ncatlab.org/davidcorfield/show/ontology

Formal ontology
- Guizzardi, Masolo, Borgo, ER 2006 (full text read): https://www.inf.ufes.br/~gguizzardi/ER2006CR.pdf
- Porello and Guizzardi, first-order modal UFO: https://nemo.inf.ufes.br/wp-content/papercite-data/pdf/towards_a_first_order_modal_formalisation_of_the_unified_foundational_ontology_2017.pdf
- Multi-Level Ontology-based Conceptual Modeling: https://nemo.inf.ufes.br/wp-content/papercite-data/pdf/multi_level_ontology_based_conceptual_modeling_2017.pdf
- gUFO 2026: https://arxiv.org/abs/2603.20948
- Guarino, Sales, Guizzardi, ER 2018: https://link.springer.com/doi/10.1007/978-3-030-00847-5_13 and https://lists.w3.org/Archives/Public/public-rdf-star-wg/2024Jan/att-0023/Rei___cation_and_Truthmaking_Patterns_-_2018.pdf
- Sales and Guizzardi 2015: https://nemo.inf.ufes.br/wp-content/papercite-data/pdf/ontological_anti_patterns__empirically_uncovered_error_prone_structures_in_ontology_driven_conceptual_models_2015.pdf
- OntoClean: https://en.wikipedia.org/wiki/OntoClean and https://www.loa.istc.cnr.it/wp-content/uploads/2020/03/OverviewOntoClean-compresso.pdf
- BFO and DOLCE: https://philarchive.org/rec/GUABAD ; https://cse.buffalo.edu/sneps/Bibliography/sey09b.pdf ; https://www.loa.istc.cnr.it/wp-content/uploads/2020/03/fois2010qualV0.5.pdf ; https://jbiomedsem.biomedcentral.com/articles/10.1186/s13326-021-00246-0/tables/2
- BFO GDC: https://virtualflybrain.org/blog/2022/01/01/generically-dependent-continuant-bfo_0000031/ ; https://arxiv.org/html/2506.17085v1 ; https://arxiv.org/pdf/2404.17758
- Wang et al. 2014: https://nemo.inf.ufes.br/wp-content/papercite-data/pdf/towards_an_ontology_of_computer_software__a_requirements_engineering_perspective_2014.pdf
- Dapoigny and Barlatier: https://philarchive.org/archive/BARATA-5 ; https://link.springer.com/10.1007/978-3-642-35786-2_11

Computing
- MacLennan 1982: https://web.eecs.utk.edu/~bmaclenn/papers/VOPL.pdf
- Baker, egal (abstract seen via a Papers We Love mirror and talk): https://speakerdeck.com/paperswelove/philip-potter-on-equal-rights-for-functional-objects-by-henry-g-baker ; TC39 egal proposal: https://archives.ecma-international.org/2010/TC39/tc39-2010-054.4.pdf ; Scheme SRFI 111 discussion: https://srfi.schemers.org/srfi-111/mail-archive/msg00018.html . (A different, later paper on the same theme, "The Left Hand of Equals", surfaced in the same search; I did not read it and do not cite it for any claim.)
- Singleton property: https://www.lhncbc.nlm.nih.gov/LHC-publications/PDF/pub8934.pdf ; https://arxiv.org/abs/1509.04513v1
- RDF 1.2 Concepts: https://www.w3.org/TR/2025/WD-rdf12-concepts-20250806/
- Provenance semirings: https://www.cs.ucdavis.edu/~green/papers/pods07.pdf
- Unison: https://unison-lang.org/docs/the-big-idea ; https://www.unison-lang.org/docs/language-reference/hashes
- gitdiffcore: https://git-scm.com/docs/gitdiffcore
- Clone survey: https://ar5iv.arxiv.org/html/2006.15682 ; https://peerj.com/articles/cs-49
- Homotopical Patch Theory: https://www.cs.cmu.edu/~rwh/papers/htpt/jfp.pdf
- GhostCell: https://plv.mpi-sws.org/rustbelt/ghostcell/
- Type-constrained generation: https://arxiv.org/abs/2504.09246

Rhetoric and AI tropes
- Goguen: https://link.springer.com/doi/10.1007/3-540-48834-0_15 ; https://cseweb.ucsd.edu/~goguen/projs/narr.html
- Hayden White: https://wikipedia.com/wiki/Hayden_White
- TiMoS: https://arxiv.org/abs/2101.07632v2 ; TrUMAn: https://arxiv.org/abs/2108.04542v3
- Wikipedia, Signs of AI writing: https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing
- tropes.fyi: https://tropes.fyi/tropes-md
- Kobak et al.: https://arxiv.org/abs/2406.07016v5
- Reinhart et al.: https://arxiv.org/abs/2410.16107
- Shaib et al.: https://arxiv.org/pdf/2509.19163
- Antislop: https://arxiv.org/abs/2510.15061
- SlopBench: https://arxiv.org/pdf/2609.33905
- MAST: https://arxiv.org/html/2503.13657v3
- ImpossibleBench: https://arxiv.org/abs/2510.20270v1
- Package hallucination: https://www.usenix.org/conference/usenixsecurity25/presentation/spracklen ; https://arxiv.org/html/2406.10279v3
- Code stylometry: https://arxiv.org/abs/2412.14611v1 ; https://arxiv.org/html/2403.04013v1 ; https://arxiv.org/abs/2506.17323v1 ; https://arxiv.org/pdf/2601.19264
