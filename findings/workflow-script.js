export const meta = {
  name: 'tropes-types-pain-portfolio',
  description: 'Map estate maths and recurring engineering pain, then generate and adversarially verify type/trope-based cures',
  phases: [
    { title: 'Theory', detail: 'deep-read estate theory clusters' },
    { title: 'Pain', detail: 'mine 93k commits and 8.5k workflows for recurring failure classes', model: 'sonnet' },
    { title: 'Sweep', detail: 'catalogue every repo for unnamed maths and tooling', model: 'sonnet' },
    { title: 'External', detail: 'classical and near-range type/trope theory, AI-error typing, industry data' },
    { title: 'Generate', detail: 'one generator per ring plus a pain-first generator' },
    { title: 'Dedup', detail: 'merge candidates' },
    { title: 'Verify', detail: 'two adversarial lenses per candidate' },
    { title: 'Synthesise', detail: 'ranked portfolio and completeness critic' },
  ],
}

const E = '/home/user/estate'
const F = E + '/.findings'
const COMMON = `
CONTEXT. The owner's four GitHub organisations (hyperpolymath, metadatastician, catachresis-colloquium, stuff-of-awe) are cloned at ${E}/<owner>/<repo> (484 repos; blobless clones with full commit history, except six private ones at depth 50). mathesis (the estate's maths atlas) is also at /home/user/mathesis and the canon at /home/user/standards. ${E}/.stats.tsv lists every repo with commit count and workflow-file count. 48 repos could not be cloned (${E}/.clone.log, lines starting FAIL) - never guess their content.
RULES. This is READ-ONLY research: do not edit, commit, push, open issues or PRs anywhere. You may create files only under ${F}/ and scratch files under /tmp. Do not run 'git log -p' or 'git show' across many commits (blobs are fetched lazily and it is slow) - use --format, --name-only, --stat, and read checked-out files. Ground every claim in a file path or command output you actually saw; say "not found" rather than guess (fabrication is the estate's cardinal sin). Distinguish what is PROVED (checked proof file exists), STATED (spec/doc only) and ASPIRATIONAL (roadmap). Do not install anything that costs money.
OVERALL GOAL of the programme you are part of: find where types and tropes (the owner's own, classical, or new) could permanently prevent, cure or shrink recurring software-engineering pain: merge conflicts, clashes, regular errors, AI/LLM errors (hallucination, overclaim, fabricated structure, drift), trivial syntax failures (the "missing semicolon" class), unsafe vs safe dependency bumps, CI cost and flakiness, template drift, licence/metadata drift, and similar.
`

const THEORY_SCHEMA = { type: 'object', required: ['constructs', 'summary'], properties: {
  summary: { type: 'string' },
  constructs: { type: 'array', items: { type: 'object', required: ['name', 'repo', 'what', 'status', 'couldSolve'], properties: {
    name: { type: 'string' }, repo: { type: 'string' }, files: { type: 'string' }, what: { type: 'string' },
    status: { type: 'string', enum: ['proved', 'stated', 'aspirational', 'implemented-unproved'] },
    couldSolve: { type: 'string', description: 'which engineering pains this construct could address and how' } } } },
  gaps: { type: 'string' } } }

const PAIN_SCHEMA = { type: 'object', required: ['pains', 'summary'], properties: {
  summary: { type: 'string' },
  pains: { type: 'array', items: { type: 'object', required: ['name', 'cls', 'evidence', 'agent'], properties: {
    name: { type: 'string' }, cls: { type: 'string', description: 'failure class, e.g. merge-conflict, syntax, bump, ci-cost, ai-error, drift, signing, format' },
    evidence: { type: 'string', description: 'counts with denominators and example commit hashes/paths' },
    frequency: { type: 'string' }, cost: { type: 'string' },
    agent: { type: 'string', enum: ['human', 'ai', 'bot', 'mixed', 'unknown'] },
    rootCause: { type: 'string' } } } } } }

const EXT_SCHEMA = { type: 'object', required: ['items', 'summary'], properties: {
  summary: { type: 'string' },
  items: { type: 'array', items: { type: 'object', required: ['name', 'what', 'appliesTo'], properties: {
    name: { type: 'string' }, source: { type: 'string', description: 'paper/tool/URL' }, what: { type: 'string' },
    maturity: { type: 'string' }, appliesTo: { type: 'string' }, limits: { type: 'string' } } } } } }

const CAND_SCHEMA = { type: 'object', required: ['candidates'], properties: { candidates: { type: 'array', items: { type: 'object',
  required: ['title', 'ring', 'pain', 'mechanism', 'estateAssets', 'experiment', 'scope'], properties: {
    title: { type: 'string' },
    ring: { type: 'string', enum: ['1-estate-maths', '2-near-estate', '3-classical', '4-near-classical', '5-novel'] },
    pain: { type: 'string' }, mechanism: { type: 'string', description: 'the precise type/trope/logic mechanism and why it prevents, cures or shrinks the pain; state the theorem or invariant' },
    estateAssets: { type: 'string', description: 'existing estate repos/files it builds on, with paths, or "none"' },
    externalBasis: { type: 'string' }, novelty: { type: 'string' },
    effect: { type: 'string', enum: ['prevents', 'cures', 'reduces-impact', 'detects-earlier'] },
    effort: { type: 'string', enum: ['days', 'weeks', 'months', 'research'] },
    payoff: { type: 'string' }, experiment: { type: 'string', description: 'smallest empirical test/bench that would confirm or kill it, in which repo' },
    scope: { type: 'string', enum: ['one-repo', 'estate-wide', 'industry-wide'] },
    aspects: { type: 'string', description: 'cross-cutting notes: security, privacy, accessibility, performance, cost, dependability' } } } } } }

const VERDICT_SCHEMA = { type: 'object', required: ['survives', 'confidence', 'reasons'], properties: {
  survives: { type: 'boolean' }, confidence: { type: 'string', enum: ['low', 'medium', 'high'] },
  reasons: { type: 'string' }, corrections: { type: 'string', description: 'what must change for it to be right' },
  priorArt: { type: 'string' }, checked: { type: 'string', description: 'what you actually opened/ran to reach this verdict' } } }

const out = (key) => `Write your full detailed findings (with paths, quotes, counts) to ${F}/${key}.md, then return the structured summary.`

// ---------- Phase A: understanding (theory, pain, sweep, external all run concurrently) ----------
const THEORY = [
  ['tropes', 'hyperpolymath/trope-checker, hyperpolymath/trope-particularity-workbench, hyperpolymath/tropical-types, plus any other repo where grep -ril trope finds substantive content. Establish precisely what the owner means by "trope" (metaphysical particularised property? rhetorical figure? both?), the formal calculus, what the checker checks, and what is proved.'],
  ['echo-residual', 'hyperpolymath/echo-types, EchoTypes.jl, echobox, residual-evidence-types, ResidualEvidenceTypes.jl, epistemic-types, EpistemicTypes.jl, secret-types, occupancy-types. Loss-with-residue (Echo f y), evidence, epistemic and occupancy typing.'],
  ['nextgen-typing', 'hyperpolymath/nextgen-typing (the type-family map and glossary), typell, anytype, typed-wasm, typefix-zero, typesnake, system-et, cut-calculus, hottchpotch, nextgen-languages, kategoria.'],
  ['affine-resource-choreo', 'hyperpolymath/affinescript, ephapax, resource-algebra, choreographic-types, my-lang, wokelang, eclexia, betlang, jtv-lang, gnpl, tangle, pseudoscript, lucidscript, phronesis, krl. Affine/linear/resource/choreographic/session typing and what is mechanised.'],
  ['zero-maa-marches', 'hyperpolymath/absolute-zero, zerostep, maa-framework, marches, jtv-halting-islands-ct, ordinal-notation, invariant-path, januskey, valence-shell, quandledb, frayed-knot-toolkit, HackenbushGames.jl, ZeroProb.jl. The no-op/absolute-zero theory, MAA, marches (boundaries), halting islands (decidable fragments), ordinals/termination, reversibility.'],
  ['mathesis-canon', '/home/user/mathesis in full (docs/theory ledger and admissions, src/bridges, src/definitions, src/aspects, applied-systems methods, docs/proposals/mathesis-research-programme.adoc, verification) and /home/user/standards 3-practice/PROOF-POLICY.adoc, STANDING-RULES.adoc, DEPARTURES.adoc, 1-formats/deed and k9, contractiles (hyperpolymath/contractiles, k9-ecosystem, deed-core). What theory "no single system owns" is recorded, the bridges between repos, and methods applying maths to decisions.'],
  ['ai-error-tooling', 'metadatastician/hvn-dehallucinator, hyperpolymath/autoformal-fidelity, llm-grace, nesy-solver, echidna, echidnabot, proof-burrower, arghda-core, panic-attack, vexometer, session-sentinel, conative-gating, social-media-polygraph, stateful-artefacts, palimpsest-license (AFFIRMATION ethos), metadatastician/ai-skills. What mechanisms already exist for catching/limiting AI errors, what formal basis each has, and what is still neural/unproved.'],
  ['ops-tooling', 'hyperpolymath/hypatia, gitbot-fleet, cicd-squabbler, proven-cicd-and-workflows, proven, proven-tests-and-benches, patch-bridge, polysafe-gitfixer, reposystem, sholes (what was it meant to cure and did it?), action-trust-layers, protocol-squisher, recon-silly-ation, hybrid-automation-router, work-queue, coord-tui, conflow, ijson-jcs, metadatastician/kyq, rsr-template-repo, chora-registry. What each claims to fix, the formal content behind it (if any), and where the mechanism is ad hoc and a type/logic would make it final.'],
]

const PAIN = [
  ['commit-taxonomy', 'Build a quantitative taxonomy of fix/repair commits across ALL repos in .stats.tsv. Script it: for each repo `git log --format=%H%x09%an%x09%ae%x09%s`, classify subjects by regex (fix, revert, typo, syntax, lint, format, conflict, merge, ci, workflow, bump, deps, lockfile, sign, licence/SPDX, drift, sync template, rename, a2ml/deed migration, hallucinat/fabricat/overclaim/wrong/oops/actually). Report counts with denominators, per author class (human / dependabot / github-actions / AI co-authored via Co-Authored-By trailers - use %b sparingly on a sample), the top 25 recurring failure classes with example hashes, and fix-after-fix chains (a fix commit within 3 commits of another fix touching the same path, via --name-only).'],
  ['ci-cost', 'Inventory the 8,466 workflow files: cluster by filename and by content hash (how many are byte-identical copies of a template, how many drifted variants per filename), triggers (push/pull_request/schedule/cron frequency), matrix sizes, runner types, jobs per push, whether they use reusable workflows, path filters, concurrency cancellation, caching. Estimate wasted runner-minutes structurally (e.g. N workflows x M repos firing on every push with no path filter). Count commits whose subject is about fixing CI/workflows. Identify the commonest CI breakage classes from commit subjects and from workflow diffs (--stat only).'],
  ['bumps', 'Dependency updates: count dependabot/renovate commits and bump commits per ecosystem (cargo, mix, npm/bun/deno, julia, github-actions SHA pins, guix), lockfile churn (commits touching only lockfiles), reverts or fix commits within 5 commits after a bump touching the same manifest, SHA-pin update noise for actions, grouped vs ungrouped updates, and any existing estate logic that decides a bump is safe (search for semver, cargo-semver-checks, compat, auto-merge). What information would make a bump provably safe and is it available in these ecosystems?'],
  ['merge-drift', 'Merge conflicts and drift: count merge commits, commits mentioning conflict/rebase/resolve, leftover conflict markers in checked-out files (grep for ^<<<<<<< and ^>>>>>>> outside fixtures), files that are near-duplicates across many repos (template-propagated: CLAUDE.md, Justfile, workflows, deed files, contractiles) and how far they have drifted (cluster by hash per filename), mass "sync from template" commits and how often they are followed by fixes, concurrent-agent clashes (search commit subjects and docs for clash, collision, race, duplicate PR, superseded, stale branch, coordination).'],
  ['ai-errors', 'AI/LLM error evidence: read /home/user/standards/STANDING-RULES.adoc, 3-practice/DEPARTURES.adoc, .machine_readable/departures.jsonl, audits/, every CLAUDE.md/AGENTS/GEMINI.md rule that was clearly added in reaction to an incident (e.g. the fabricated lith monorepo, licence sweep neurophone#99, Bun/Deno inversion, A2ML regeneration, overclaimed proofs, wrong-email signing). For each incident class: what the agent did, why existing checks did not stop it, how it was patched (prose rule? gate? proof?), and whether it recurred (search commit logs for repeated corrections). Also sample commits with Co-Authored-By: Claude/Codex/Gemini/Copilot trailers that were later reverted or fixed. Produce a failure taxonomy of AI agents in this estate with counts where countable.'],
  ['trivial-syntax', 'The "missing semicolon" class: commits whose whole purpose is a trivial mechanical correction (typo, missing bracket/comma/semicolon/quote, wrong indentation, YAML/TOML/JSON parse error, wrong file extension, wrong path, wrong case, trailing whitespace, line endings, encoding, SPDX header missing, broken link, asciidoc/markdown syntax). Count by format/language with denominators and examples. For each sub-class note whether a grammar/formatter/gate already exists in the estate (deed_lint, k9-validate, ijson-jcs, kyaml-format, empty-linter, hooks) and whether failures occur before or after that gate was introduced.'],
  ['forge-voice', 'Use `gh api -X GET search/issues` (a few queries a minute; add org:hyperpolymath / org:metadatastician etc.) to sample issues and PRs: most common labels, titles mentioning fail, broken, conflict, flaky, revert, stale, blocked, drift, hallucination; bot-opened vs human-opened; PRs closed unmerged and why (titles only). If the API refuses, say so and fall back to docs/status/ROADMAP.adoc blockers and CHANGELOG entries across repos. Summarise the recurrent frustrations the estate records about itself.'],
]

const SWEEP = [0, 1, 2, 3].map(i => [`sweep-${i}`, `Take lines ${i * 121 + 1} to ${(i + 1) * 121} of ${E}/.stats.tsv (use sed -n). For EACH repo in that range read the README head and the *_chora.deed (identity)/(ecosystem) clauses (or top-level file list if absent) and record one line: what it is, primary language, and whether it contains (a) formal maths/type/logic/proof content, (b) tooling aimed at an engineering pain (merge, CI, deps, drift, AI error, validation), (c) neither. For (a) and (b) give two or three sentences and the key paths. Be complete: every repo in your range must appear in ${F}/sweep-${i}.md. In the structured return list only the (a) and (b) repos as constructs.`])

const EXTERNAL = [
  ['ext-types', 'Classical and near-classical TYPE theory applied to the pains above. Survey with sources (use web search): structural/semantic/AST and CRDT merge (Mergiraf, Weave, difftastic, tree-sitter based merge, semistructured merge research), patch theory (Darcs, Pijul categorical patches, homotopical patch theory by Angiuli et al., Mimram-Di Giusto), typed holes and error-tolerant structure editing (Hazel, tylr, Hazelnut), error-recovering parsers and why the semicolon problem persists, projectional editors, gradual/refinement/liquid types, typestate and session types for protocols and CI pipelines, effect and capability types, row types and schema evolution, semver as a type (Elm package diffing, cargo-semver-checks, rust RFC 1105, type-directed API compatibility, Unison content-addressed code), build systems a la carte and hermetic/incremental builds as a theory of minimal CI, lenses/bidirectional transformations and delta lenses for template drift and config sync, ornaments and refactoring-as-typed-transformation, dependent types for configuration (Dhall, Nickel, CUE lattice). For each: what it guarantees, maturity, and its known limits.'],
  ['ext-tropes', 'TROPE theory and its near range. (1) Metaphysical trope theory: Stout, D.C. Williams, Campbell, Maurin, Simons nuclear theory, Lowe four-category ontology, moments (Husserl), modes; trope bundles, exact resemblance classes, compresence, the particular/universal distinction. (2) Formal ontology uses: BFO/DOLCE/UFO qualities and modes, OntoUML, moment universals. (3) Connections to computing: nominal vs structural typing, object identity vs value equality, provenance and instance-level properties, type classes vs instances, token/type distinction, haecceity and content addressing, univalence (equivalence as identity), mereology and mereotopology of codebases, resemblance-based (similarity) classification vs universals, tropes as proof-relevant witnesses (a trope as "this particular inhabitant" - Sigma types, fibers, singleton types), copy identity and clone detection. (4) Rhetorical/literary tropes and "AI tropes" (recurring LLM stylistic and reasoning patterns) and any formal detection work. State honestly where the literature has computing applications and where it is untouched ground.'],
  ['ext-ai', 'Types, logics and proofs against AI/LLM coding errors, with sources: grammar- and type-constrained decoding (Synchromesh, monitor-guided decoding, type-constrained code generation 2025, outlines/guidance/llguidance), typed holes as LLM context (Hazel + LLM static contextualisation), proof-carrying code and proof-carrying responses, verified code generation loops (Dafny/Verus/Lean with LLMs), refinement types on tool calls, capability/effect systems and object capabilities for agents, session types/choreographies for multi-agent protocols and MCP, information-flow types for prompt injection (CaMeL, dual-LLM), hallucinated package names (slopsquatting) and content addressing, abstention/epistemic types and calibrated claims, autoformalisation fidelity, specification mining, mutation testing as a check on AI-written tests, agentic merge conflicts and locking. For each say what failure class it eliminates versus merely reduces, with evidence quality.'],
  ['ext-pain', 'Empirical evidence on industry-wide developer pain, with sources: frequency and cost of merge conflicts (Ghiotto, Brindescu, Mens studies), CI failure causes and flaky tests (Google, Microsoft studies), cost of GitHub Actions minutes and typical waste (redundant runs, no path filters, no cancellation), dependency update breakage rates (Dependabot/Renovate studies, semver violation rates in npm/crates/Maven), syntax errors as share of failed builds/novice errors, config/YAML errors as outage causes, LLM-generated code defect and security studies, review burden of AI PRs, drift in templated repos. Also the folklore: the recurring jokes and complaints (works on my machine, YAML, left-pad, rebase hell, green CI lies, "LGTM", dependency hell, bikeshedding) - each joke names a failure class; list them and the class. Rank pain classes by (frequency x cost) as best the evidence allows.'],
]

log('Phase A: 8 theory readers, 7 pain miners, 4 sweepers, 4 external researchers')
const understand = await parallel([
  ...THEORY.map(([k, scope]) => () => agent(`${COMMON}\nYOUR JOB: deep-read this theory cluster and extract every formal construct (type former, judgement, calculus, theorem, invariant, method) with its proof status and what recurring engineering pain it could plausibly kill.\nCLUSTER: ${scope}\nRead the actual proof and spec files, not only READMEs; check PROOF-STATUS documents against the files. ${out(k)}`,
    { label: `theory:${k}`, phase: 'Theory', schema: THEORY_SCHEMA, effort: 'high' }).then(r => r && { kind: 'theory', key: k, ...r })),
  ...PAIN.map(([k, job]) => () => agent(`${COMMON}\nYOUR JOB (empirical mining; write and run shell scripts over the clones; report numbers with denominators, never percentages alone): ${job}\n${out(k)}`,
    { label: `pain:${k}`, phase: 'Pain', schema: PAIN_SCHEMA, model: 'sonnet' }).then(r => r && { kind: 'pain', key: k, ...r })),
  ...SWEEP.map(([k, job]) => () => agent(`${COMMON}\nYOUR JOB: ${job}`,
    { label: k, phase: 'Sweep', schema: THEORY_SCHEMA, model: 'sonnet' }).then(r => r && { kind: 'sweep', key: k, ...r })),
  ...EXTERNAL.map(([k, job]) => () => agent(`${COMMON}\nYOUR JOB (external research; load web search tools via ToolSearch; cite sources; mark anything you could not verify online as from-memory): ${job}\n${out(k)}`,
    { label: k, phase: 'External', schema: EXT_SCHEMA, effort: 'high' }).then(r => r && { kind: 'ext', key: k, ...r })),
])
const got = understand.filter(Boolean)
const missing = [...THEORY, ...PAIN, ...SWEEP, ...EXTERNAL].map(x => x[0]).filter(k => !got.some(g => g.key === k))
if (missing.length) log(`Phase A agents that returned nothing: ${missing.join(', ')}`)

const digest = JSON.stringify(got.map(g => ({ kind: g.kind, key: g.key, summary: g.summary,
  items: (g.constructs || g.pains || g.items || []).map(x => ({ n: x.name, r: x.repo || x.cls || x.source, s: x.status || x.frequency || x.maturity, w: (x.what || x.evidence || '').slice(0, 260), c: (x.couldSolve || x.rootCause || x.appliesTo || '').slice(0, 220) })) })))
const BRIEF = `${COMMON}\nPhase A is complete. Detailed findings are in ${F}/*.md (read the ones relevant to you in full before generating: theory = tropes, echo-residual, nextgen-typing, affine-resource-choreo, zero-maa-marches, mathesis-canon, ai-error-tooling, ops-tooling, sweep-0..3; pain = commit-taxonomy, ci-cost, bumps, merge-drift, ai-errors, trivial-syntax, forge-voice; external = ext-types, ext-tropes, ext-ai, ext-pain).\nCompact digest of Phase A:\n${digest}\n`

// ---------- Phase B: generate ----------
const RINGS = [
  ['1-estate-maths', "RING 1: applications of the owner's OWN existing maths and types as they stand today (mathesis, tropes, echo/residual types, absolute-zero, maa-framework, marches, halting islands, ordinals, resource algebra, choreographic types, etc.). Only wiring and application, no new theory."],
  ['2-near-estate', "RING 2: the near range of the owner's maths: small extensions, compositions or bridges between two estate constructs, or finishing a stated-but-unproved construct, that would unlock a cure."],
  ['3-classical', 'RING 3: classical, established type theory and trope theory from the literature applied to estate and industry pain, where the estate has not yet used it.'],
  ['4-near-classical', 'RING 4: the near range of classical theory: recent research-grade results (last ~10 years) that are not yet mainstream practice, adapted to these pains.'],
  ['5-novel', 'RING 5: genuinely novel constructs that trope theory and type theory could reach but nobody (as far as Phase A found) has built: new type formers, new judgements, new uses of tropes (particularised properties, resemblance classes, compresence) for code, repos, patches, agents, claims. Be bold but state the conjectured theorem precisely and what would falsify it.'],
]
const genPrompt = (ring, text) => `${BRIEF}\nYOUR JOB: generate candidate cures. ${text}\nProduce 8 to 14 candidates. Each must name a specific pain evidenced in the pain findings (or in ext-pain for industry-wide ones), a precise mechanism (which type/trope/logic, what invariant or theorem, and why the failure becomes unrepresentable, mechanically repairable, or cheaper), the estate assets with paths, the smallest experiment that could kill it, and cross-cutting aspects. Prefer cures that make a failure class impossible over ones that detect it. Cover the big ones: merge conflicts and agent clashes, AI errors (fabrication, overclaim, drift from canon), the missing-semicolon class, provably safe bumps, CI cost, template and metadata drift. Do not pad: a weak candidate costs verification money. Set ring to "${ring}".`
const gens = await parallel([
  ...RINGS.map(([ring, text]) => () => agent(genPrompt(ring, text), { label: `gen:${ring}`, phase: 'Generate', schema: CAND_SCHEMA, effort: 'max' })),
  () => agent(`${BRIEF}\nYOUR JOB: pain-first generation. Take the 15 highest (frequency x cost) pain classes from the pain findings and ext-pain. For EACH, propose the single most elegant and final type/trope/logic cure you can find from any ring (label the ring honestly), plus, where it differs, the most dependable near-term one. Use the same candidate fields; the experiment must be runnable against the cloned estate data.`, { label: 'gen:pain-first', phase: 'Generate', schema: CAND_SCHEMA, effort: 'max' }),
])
const raw = gens.filter(Boolean).flatMap(g => g.candidates)
log(`${raw.length} raw candidates`)

// ---------- Dedup (barrier: needs all candidates) ----------
phase('Dedup')
const dd = await agent(`${COMMON}\nYOUR JOB: merge duplicates among these ${raw.length} candidate cures. Two candidates are duplicates only if they use the same mechanism on the same pain; keep the richer statement and graft useful detail from the other. Keep distinct mechanisms for the same pain as separate candidates. Drop nothing for being ambitious; drop only candidates with no stated mechanism. Return at most 45; if you must cut to reach 45, cut the weakest and list their titles in "dropped".\nCANDIDATES:\n${JSON.stringify(raw)}`,
  { label: 'dedup', schema: { type: 'object', required: ['candidates'], properties: { candidates: CAND_SCHEMA.properties.candidates, dropped: { type: 'array', items: { type: 'string' } } } }, effort: 'high' })
const cands = (dd && dd.candidates) || raw.slice(0, 45)
log(`${cands.length} candidates after dedup; dropped: ${((dd && dd.dropped) || []).join(' | ') || 'none'}`)

// ---------- Verify ----------
const LENSES = [
  ['grounding', 'GROUNDING AND SOUNDNESS. Open every estate file the candidate cites: does it exist, does it say what is claimed, is the construct proved or merely stated? Is the type/trope-theoretic mechanism actually sound - does the stated invariant really exclude the failure, or does the failure just move (e.g. to an unverified boundary, to the spec, to a human)? Look for the counterexample.'],
  ['reality', 'PRIOR ART, FEASIBILITY AND EFFECT. Search the web: does this already exist (then it is ring 3, not novel - say what to adopt instead of build)? Would it work on the real estate data - check the pain evidence in ' + F + ' and, where cheap, run a small script over the clones to test the premise (e.g. what fraction of the relevant commits would it actually have prevented). Is the effort estimate honest? Does it create a new recurring cost (annotation burden, slower CI, lock-in)?'],
]
const verified = await pipeline(cands,
  (c, _o, i) => parallel(LENSES.map(([k, lens]) => () => agent(`${COMMON}\nYOUR JOB: adversarially verify one candidate cure through this lens: ${lens}\nTry to refute it. If uncertain after real checking, set survives=false with confidence low and say exactly what evidence would flip it. Give corrections that would make it right.\nCANDIDATE:\n${JSON.stringify(c)}`,
    { label: `verify:${k}:${i}`, phase: 'Verify', schema: VERDICT_SCHEMA, effort: 'high' }).then(v => v && { lens: k, ...v })))
    .then(vs => ({ ...c, verdicts: vs.filter(Boolean) })))
const all = verified.filter(Boolean)

// ---------- Synthesise ----------
phase('Synthesise')
const synthIn = JSON.stringify(all)
const [portfolio, critic] = await parallel([
  () => agent(`${BRIEF}\nYOUR JOB: write the final portfolio to ${F}/PORTFOLIO.adoc (AsciiDoc) and return a short summary. Input: every candidate with its two adversarial verdicts (below). Apply corrections from the verdicts; demote or strike candidates both lenses refuted (list them in an appendix with the reason - the owner wants to see what died and why). Structure: (1) the unifying picture - which few type/trope ideas recur across many cures, stated as a small set of principles; (2) a ranked table: cure, pain, ring, effect (prevents/cures/reduces), evidence of pain size from estate data with denominators, effort, verification outcome, scope (one-repo / estate-wide / industry-wide); rank first by elegance-and-correctness, and give a second ranking by dependability-and-security; (3) for the top 12, a half-page each: mechanism with the theorem, estate assets with paths, the experiment to run first (tests/benches, in which repo), which prover per PROOF-POLICY, cross-cutting aspects, what could go wrong; (4) things doable immediately versus things needing the owner's decision, with the decision stated as a question with options; (5) what belongs outside any single repo (canon in standards, a mathesis ledger entry, a new repo) ; (6) the struck candidates. No overclaiming: nothing here has been built or tested; say so.\nCANDIDATES WITH VERDICTS:\n${synthIn}`,
    { label: 'portfolio', effort: 'high' }),
  () => agent(`${BRIEF}\nYOUR JOB: completeness critic. Given the candidates and verdicts below, what is MISSING? Pain classes in the findings with no surviving cure; estate constructs in the theory findings that no candidate uses and that look powerful; modalities not run (which data was never examined - e.g. the 48 uncloned repos, CI run logs, PR review threads); claims in the verdicts that rest on unchecked assumptions; and the three questions the owner most needs to answer before any build. Write to ${F}/CRITIC.adoc and return the text.\nCANDIDATES WITH VERDICTS:\n${synthIn}`,
    { label: 'critic', effort: 'high' }),
])
return { missingPhaseA: missing, rawCount: raw.length, candidates: all.map(c => ({ title: c.title, ring: c.ring, pain: c.pain, effect: c.effect, effort: c.effort, scope: c.scope, verdicts: c.verdicts.map(v => `${v.lens}:${v.survives ? 'survives' : 'refuted'}/${v.confidence}`) })), portfolio, critic }
