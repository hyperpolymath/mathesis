# ext-pain — external empirical evidence on recurring developer pain

Date of research: 2026-11-24. Scope: external (non-estate) literature and industry
reports only. Nothing in any estate repository was read or changed for this file
except the CLAUDE.md files loaded by the harness.

## 0. How to read this file

### Verification legend (applies to every number below)

| Tag | Meaning |
|---|---|
| **[P]** | PRIMARY: I downloaded the paper/report/postmortem itself and read the quoted line (PDF text extracted with `pdftotext`, or the vendor's own page fetched). Line-numbered extracts are in `/home/user/estate/.findings/ext-pain-evidence.txt`. |
| **[S]** | SECONDARY: confirmed online today, but only through a search-result summary, an abstract page, a review, or press coverage. The primary text was not opened. |
| **[V]** | VENDOR: the source sells a product that benefits from the finding (Veracode, GitClear, CodeRabbit, Faros, Sonar, Atlassian, Stripe, Parametrix). Numbers are real publications but commercially interested and mostly not peer reviewed. |
| **[M]** | FROM MEMORY: not verified online in this session. Treat as a lead, not as evidence. |
| **[NF]** | NOT FOUND: I looked and did not find it. |

Kind-of-evidence vocabulary (the external analogue of the programme's
PROVED / STATED / ASPIRATIONAL): **MEASURED** = an empirical study with a stated
sample; **REPORTED** = a survey or vendor telemetry; **INCIDENT** = a single
postmortem; **FOLKLORE** = a joke or saying, which names a failure class but
measures nothing.

No study puts these pain classes in one commensurable unit. The ranking in §14
is my judgement over the evidence, and says so.

### Two things I got wrong on the way and corrected

* I first guessed an arXiv id for Bouzenia & Pradel; it resolved to an astronomy
  paper. Discarded; the real paper was fetched from
  `software-lab.org/publications/icse2024_workflows.pdf`.
* A link I expected to be Ghiotto et al. (`par.nsf.gov/servlets/purl/10515782`)
  was actually Shen, Gulzar, He & Meng, "A Characterization Study of Merge
  Conflicts in Java Projects" (TOSEM 2023). I use it under its real name below.
  The Ghiotto full text was not obtained; its numbers here are **[S]**.

---

## 1. Merge conflicts

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 1.1 | "almost 1 in 5 merges cause conflicts": 6,979 of 36,122 merge commits = **19.32%** | 143 open-source projects, 556,911 commits | Brindescu, Ahmed, Jensen, Sarma, *Empirical Software Engineering* 2019/2020, DOI 10.1007/s10664-019-09735-4 | [P] |
| 1.2 | Conflict types: SEMANTIC **59.46%**, FORMATTING **23.21%**, DISJOINT **14.53%**, DELETE **1.24%**, COMMENTS **0.60%** | same | same (results section) | [P] |
| 1.3 | "In 75.23% of these cases, a developer needed to reflect on the program logic to resolve it." | same | same (abstract) | [P] |
| 1.4 | "code associated with a merge conflict is twice as likely to have a bug"; SEMANTIC-conflict code is "26 times more likely to have a bug compared to code associated with other conflicts" | same | same | [P] |
| 1.5 | "Of all the merges, one in six, or **17%**, had textual conflicts" | 9 open-source systems, 3.4 MLOC | Brun, Holmes, Ernst, Notkin, "Proactive Detection of Collaboration Conflicts", ESEC/FSE 2011 | [P] |
| 1.6 | In Git, Perl5, Voldemort (5,355 merges): "76% of merges completed cleanly, 16% ... textual conflict, 1% ... build failure, and 6% ... test failure. The 266 textual conflicts reported by the version control system only represent 67% of all conflicts." | 3 projects with runnable tests | same | [P] |
| 1.7 | Textual-conflict relationship "persisted for 9.8 days and involved 23.2 changesets" on average (median 1.6 days, 3 changesets); worst case 334 days | 4 projects | same | [P] |
| 1.8 | Earlier CVS-era figure: "of all merges, 23% to 47% had textual conflicts" (Zimmermann, 4 projects), as cited by Brun et al. | — | cited in Brun 2011 | [P, as a citation] |
| 1.9 | "as much as 10 to 20 percent of all merge attempts result in a merge conflict"; 2,731 Java projects studied; "94% of conflicting chunks were 50 lines long or less"; "a full 81% of the conflicting chunks are resolved using only the contents from the code contained within the chunk"; "only 19% ... by writing some new code" | 2,731 projects; 616 chunks in manual part | Ghiotto, Murta, Barros, van der Hoek, "On the Nature of Merge Conflicts", IEEE TSE 2018/2020, DOI 10.1109/TSE.2018.2871083, via the neverworkintheory.org review | [S] |
| 1.10 | "developers resolved 64% of true textual conflicts by keeping complete edits from either a left or right branch"; "higher-order conflicts (i.e., build and test conflicts) are harder to detect and resolve, while existing tools mainly focus on textual conflicts" | 208 repos, 538 conflicts inspected | Shen, Gulzar, He, Meng, TOSEM 32(2) 2023, DOI 10.1145/3546944 | [P, abstract] |
| 1.11 | Semistructured merge "reduce[s] the number of conflicts in 60 % of the sample merge scenarios by 34±21 %", conflicting lines by 61±22%; renaming made it worse in 26% of scenarios | 24 projects in Java, C# and Python, 180 merge scenarios | Apel, Liebig, Brandl, Lengauer, Kästner, ESEC/FSE 2011 | [P] |
| 1.12 | Mens's taxonomy: textual → syntactic → semantic → structural; state-based vs operation-based merging | survey | T. Mens, "A State-of-the-Art Survey on Software Merging", IEEE TSE 28(5) 2002 | [S] — existence and abstract confirmed, text not read |

**Reading.** Three independent measurements land in the same band (17%, 19.32%,
10–20%). Two facts matter most for a type/trope programme:

* **23.21% of conflicts are FORMATTING and 0.60% COMMENTS** (1.2). That quarter
  exists only because the merge unit is the text line, not the meaning.
* **A third of real conflicts are invisible to the VCS** (1.6: 133 of 399 were
  build or test conflicts that Git merged "cleanly"). Textual cleanliness is not
  a proof of compatibility.

Caveat on 1.6: the paper's sentence reads "33% of the 399 merges that the
version control system reported as being a clean merge, actually were a build
or test conflict". The arithmetic it gives (266 textual = 67%) shows 399 is the
count of *all* conflicts, of which 133 were higher-order. I report the
arithmetic, not the loose sentence.

**[NF]** A measured cost per conflict in developer minutes. The studies give
frequency, persistence and bug-proneness, not time.

---

## 2. CI failures and flaky tests

### 2.1 How often builds and runs fail

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 2.1 | Developer builds at Google: "C++ developers build 10.1 times a day and Java developers build 6.98 times a day ... 37.4% and 29.7%, respectively, of these builds fail"; median failure ratio "C++ (38.4%) ... Java (28.5%)" | 26.6 M builds, 9 months | Seo, Sadowski, Elbaum, Aftandilian, Bowdidge, "Programmers' Build Errors: A Case Study (at Google)", ICSE 2014 | [P] |
| 2.2 | "Dependency-related errors are the most common error type for both C++ (52.68%) and Java (64.71%)"; "approximately 10 percent of the error types account for 90% of the build failures"; median resolution "5 and 12 minutes for C++ and Java"; "75% of build errors were resolved within" one or two builds | same | same | [P] |
| 2.3 | GitHub Actions runs: paid tier 78.8% succeed, 17.4% fail; free tier 88.9% succeed, 10% fail | 1.3 M runs, 3.7 M jobs | Bouzenia & Pradel, ICSE 2024, DOI 10.1145/3597503.3623303 | [P] |
| 2.4 | Of 9,202 workflows, "60.6% (5,576) of them contain execution failures" | 3,320 Java repos, year 2023 | Huang & Lin, "On the Reruns of GitHub Actions Workflows", TOSEM 2026 | [P] |
| 2.5 | Why GHA runs fail (375 failed runs, manual): project-related **84%** (315/375), of which test failures **32%** (120/375), source-code compilation **14.4%** (54/375), quality-check issues **12%** (44/375); workflow-related **60/375 = 16%** (resource limits, workflow configuration or syntax errors in steps, network, environment setup, permissions, unresolvable actions, API rate limit, VCS issues) | 260 Java projects; 151 developers surveyed | Zheng et al., "Why Do GitHub Actions Workflows Fail?", TOSEM 35(5) 2026, DOI 10.1145/3749371 | [P] |
| 2.6 | Travis CI: tests as the dominant build breaker (I did not obtain the number) | TravisTorrent | Beller, Gousios, Zaidman, MSR 2017 | [S] existence only; figure **[NF]** |

### 2.2 Flakiness

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 2.7 | "almost 16% of our tests have some level of flakiness"; "about 84% of the transitions we observe from pass to fail involve a flaky test" | Google, 2016 | J. Micco, Google Testing Blog, 27 May 2016 | [S] (quoted by search summary; also quoted in a paper I read: Habchi et al. arXiv 2112.04919, lines 60–63 [P]) |
| 2.8 | "1.5% of all test runs" flaky; "2-16% of the company's testing budget is dedicated to rerun flaky tests" | Google | Micco GTAC 2016 / as cited in arXiv 2112.04919 | [S] / [P as citation] |
| 2.9 | Google TAP: "1.6M test failures on average each day ... 73K out of 1.6M (4.56%) test failures were caused by flaky tests" | Google, personal communication reported in the paper | Luo, Hariri, Eloussi, Marinov, FSE 2014 | [P] |
| 2.10 | Root causes of 161 flaky-test fixes: Async Wait **45%** (74), Concurrency **20%** (32), Test Order Dependency **12%** (19); "Most flaky tests (78%) are flaky the first time they are written"; "Almost all flaky tests (96%) are independent of the platform"; "Some fixes to flaky tests (24%) modify the CUT, and most of these cases (94%) fix a bug in the CUT" | 51 Apache projects, 201 commits | same | [P] |
| 2.11 | GitHub Actions: "3.2% of builds are rerun, and 67.73% of these rerun builds exhibit flaky behavior, affecting 1,055 (51.28%) of the projects"; 15 categories, "flaky tests, network issues, and dependency resolution issues are the most prevalent" | 1,960 Java projects | Ge & Zhang, arXiv 2602.02307 (Feb 2026) | [P] |
| 2.12 | Reruns: "33.9% of the workflow rerun sets and 73.6% of the job rerun sets led to outcome" change; "Around 3.7 years were spent waiting for workflow reruns" of which 3.2 years on reruns that changed nothing; "Around 2.7 years and 1.8 years of computational time were spent on workflow reruns and job reruns"; "54.8% of the workflow reruns are triggered fully automatically" | 3,320 Java repos, 2023 | Huang & Lin, TOSEM 2026 | [P] |
| 2.13 | Microsoft: asynchronous calls are the leading cause of flakiness in six proprietary projects; claimed fixes often do not reduce failure frequency | 6 projects | Lam, Muşlu, Sajnani, Thummalapenta, ICSE 2020 | [S] |
| 2.14 | Microsoft figure "4.6% of test cases flaky" / Herzig false-alarm cost | — | — | **[NF]** today; do not cite |

### 2.3 "Green CI lies"

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 2.15 | "(1) 12% of passing builds have an actively ignored failure; (2) 9% of builds have a misleading or incorrect outcome on average; and (3) at least 44% of the broken builds contain passing jobs"; in an extreme case "87% of the jobs were actively ignored" | 3.7 M Travis CI jobs, 1,276 projects | Gallaba, Macho, Pinzger, McIntosh, ASE 2018, DOI 10.1145/3238147.3238171 | [P] |
| 2.16 | Of commits branched while the build was broken, "3,426 builds (83%) are not fixed in the immediately subsequent build" | same | same | [P] |
| 2.17 | Tests are a weak oracle for dependency updates: tests "only cover 58% of direct and 21% of transitive dependency calls" and "can only detect 47% of direct and 35% of indirect artificial faults on average" | 521 well-tested Java projects | Hejderup & Gousios, JSS 2022, arXiv 2109.11921 | [P] |

**Reading.** The most damaging number here is not the failure rate, it is the
*signal quality*: at Google 84% of pass→fail transitions involve a flaky test
(2.7); on Travis 12% of green builds hide an ignored red job (2.15); on GitHub
Actions two thirds of rerun builds were flaky (2.11). A CI verdict is, in
practice, a claim of unknown truth value. Async/timing is the largest single
flakiness root cause in both the open-source (2.10) and Microsoft (2.13)
studies.

---

## 3. CI cost and waste

### 3.1 Price (GitHub's own pages)

| Runner | USD per minute | Source | Tag |
|---|---|---|---|
| Linux 2-core x64 | $0.006 | docs.github.com/en/billing/reference/actions-runner-pricing (fetched today) | [P] |
| Linux 2-core arm64 | $0.005 | same | [P] |
| Windows 2-core | $0.010 | same | [P] |
| macOS 3/4-core | $0.062 | same | [P] |

* GitHub cut hosted-runner prices "by up to 39%" from 1 January 2026 and
  announced a $0.002/min "Actions cloud platform charge" for self-hosted runners
  from 1 March 2026, then postponed the self-hosted charge after pushback.
  Source: GitHub changelog 2025-12-16 and resources.github.com pricing page.
  **[S]**. Whether the self-hosted charge is still postponed as of today I did
  not confirm from a GitHub page.
* A macOS minute costs about ten times a Linux minute (0.062 / 0.006). Arithmetic
  on [P] numbers.

### 3.2 Where the minutes go, and what is left on the table

All from Bouzenia & Pradel, ICSE 2024 **[P]** ("a dataset of 952 repositories", 1.3 M runs,
3.7 M jobs; prices as of 2023).

| Finding | Quote / number |
|---|---|
| Cost | "CI/CD imposes significant costs, e.g., $504 per year for an average paid-tier repository" (at 2023 prices) |
| What consumes it | "testing and building (91.2%)" |
| What triggers it | "pull requests (50.7%), pushes (30.9%), and regularly scheduled workflows (15.5%)" |
| Caching | "adopted by 32.9% of paid-tier repositories", reduces VM time by 3.4% (paid) / 6.0% (free) |
| Cancel-in-progress | "used by 10.1% of paid-tier repositories and only 4.6% of the free-tier ones ... impacts 9.1% of runs, reduces VM time by 4.1%, and saves $55.14 yearly per repository" |
| Custom timeout | "14.0% of the paid-tier repositories ... impacts 4.3% of runs and leads to a decrease of 8.1% in VM time, equivalent to saving $58.33 yearly per repository" |
| Fail-fast | on by default; "reduces VM time by 1.5% and 2.0%" |
| Scheduled runs on inactive repos | deactivating them "could result in reductions of execution time between 1.1% and 31.6% over the impacted workflows" |
| Overall ceiling of the studied mechanisms | "save up to $60, on average per year" per repository |

Other measured waste:

* Rerun waste (2.12): 3.2 of 3.7 waiting-years went to reruns that did not
  change the outcome. **[P]**
* Cache maintenance is itself a cost: "an average of 9.37 cache-related changes
  per repository"; 266 cache adopters of 952 repos. Hasan et al., arXiv
  2604.13129 (Apr 2026). **[P, abstract]**
* Workflow churn: "7.3% of all workflow files are being changed every week";
  "about three-quarters [of changes] containing only a single change". Rostami
  Mazrae, Decan, Mens, Wessel, arXiv 2602.14572 (49K+ repos, 3.4 M workflow
  versions, Nov 2019–Aug 2025). **[P, abstract]**
* 40% of open-source projects used CI in 2016 ("40% of all the projects in our
  breadth corpus", 34,544 projects). Hilton et al., ASE 2016. **[P]**

**[NF]** A measured share of runs that are *redundant* (same tree, no relevant
path changed). Abdalkareem et al., "Which Commits Can Be CI Skipped?" (TSE 2019)
is the standard reference and I recall "about 10% of commits" **[M]**, but I
could not verify the figure today.

**Reading.** Per-repository dollars are small ($504/yr average; the known
switches save ~$60/yr). The cost multiplies by repository count and by the
macOS multiplier, and the dominant waste is not compute but *waiting on a
verdict that is then not believed* (§2). For a many-repo estate the relevant
external numbers are the adoption gaps: cancel-in-progress 10.1%, timeouts
14.0%, caching 32.9%.

---

## 4. Dependency updates and semantic-versioning violations

| # | Ecosystem | Finding | Sample | Source | Tag |
|---|---|---|---|---|---|
| 4.1 | Maven | "83.4% of all library upgrades comply" with semver; "20.1% of non-major releases are breaking"; share of breaking non-major releases fell "from 67.7% in 2005 to 16.0% in 2018"; "only 7.9% of clients are actually impacted" | 119,879 library upgrades, 293,817 clients | Ochoa, Degueule, Falleri, Vinju, "Breaking Bad?", EMSE 2022, arXiv 2110.07889 | [P] |
| 4.2 | Maven | original study: about one third of releases introduce at least one breaking change, with little difference between major and minor | Maven Central 2005–2011 | Raemaekers, van Deursen, Visser, JSS 2017 | [S] (via authors' blog summary: "a little over 1/3d of the major releases introduces binary incompatibilities ... 1/4th of the releases does not comply") |
| 4.3 | npm | "manifesting breaking changes impacted 11.7% of all client packages ... and 13.9% of their releases"; "2.6% of providers" introduced one; of manifesting breaking changes, about 44% each were in minor and patch releases; "Client packages recovered ... in 39.1% of the cases, and their recovery took about 134 days"; documented in issue/PR/changelog in 78.1% of cases; a further 8.1% of releases failed from "breaking due to external change" | 384 client packages (random sample, 95%/±5%) | Venturini, Cogo, Polato, Gerosa, Wiese, TOSEM 2023, arXiv 2301.04563 | [P] |
| 4.4 | npm | when semver is used correctly security patches reach dependents quickly "in the majority of cases (90.09%)" | whole npm registry, time-travelling resolver | Pinckney, Cassano, Guha, Bell, MSR 2023, arXiv 2304.00394 | [P] |
| 4.5 | crates.io | 464 of ~14,389 releases (**3.22%**) contain a semver violation; 172 of the top 1000 crates (**17.2%**, "1 in 6") have at least one | top-1000 library crates | Rosenthal et al., "Semver violations are common, better tooling is the answer", predr.ag, 2023 (cargo-semver-checks) | [S]; the tool's authors; a stated lower bound |
| 4.6 | Dependabot | 1,823 projects, 502,752 PRs, 131 developers: "compatibility scores are too scarce": "Only 3.4% of the PRs and 0.5% of the dependency version pairs have a compatibility score other than unknown"; "11.3% of projects have deprecated Dependabot in favor of other alternatives"; developers "configure Dependabot toward reducing the number of notifications" | as stated | He, He, Zhang, Zhou, IEEE TSE 49(8) 2023, arXiv 2206.07230 | [P] |
| 4.7 | Dependabot security PRs | "65.42% of PRs are merged and most are merged within a day"; security PRs are only 6.9% of Dependabot PRs | — | Alfadel et al., MSR 2021, as cited in 4.6 | [P as citation] |
| 4.8 | Greenkeeper | "only 32% of Greenkeeper PRs are merged" | — | Mirhosseini & Parnin, ASE 2017, as cited in 4.6 | [P as citation] |
| 4.9 | Java | tests cover 58% of direct / 21% of transitive dependency calls (see 2.17) | 521 projects | Hejderup & Gousios | [P] |
| 4.10 | Dependabot cooldown | after GitHub shipped cooldown (July 2025): "security concerns motivated 83 of 92 adoption events"; of 251 ecosystem configs "97.2% set a general delay ... 64.3% used seven days" | popular GitHub repos | Tanaka et al., arXiv 2609.16605 (Sep 2026) | [P, abstract] |
| 4.11 | npm | left-pad, 22 March 2016: Azer Koçulu unpublished 273 packages after the kik name dispute; left-pad (about 11 lines; one outlet says 17) broke "many thousands of projects"; npm restored 0.0.3 from backup and changed its unpublish policy | — | Wikipedia "npm left-pad incident"; npm blog "kik, left-pad, and npm" | [S]; "Babel and React broke" appears only in weaker sources |

**Reading.**

* A version number is an *unverified claim*. Depending on ecosystem and metric,
  between 3% (crates releases, lower bound) and 20% (Maven non-major releases)
  of "safe" bumps break the contract, and in npm 11.7% of clients were actually
  hit.
* The usual safety net is weak: tests exercise 58% of direct and 21% of
  transitive dependency calls (4.9). "CI is green on the bump" is therefore not
  evidence of a safe bump.
* The only machine signal Dependabot offers for safety is absent 96.6% of the
  time (4.6).
* 2025–2026 added a second axis: a bump can be *too fast* (malicious release
  propagates before detection), hence cooldowns (4.10). "Safe vs unsafe bump"
  now has two dimensions: compatibility and provenance/age.

---

## 5. Syntax errors and other trivial failures

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 5.1 | Novice Java: "mismatched brackets are the most frequent mistake" ("C-brktSyn, the most frequent mistake, occurs 1.8 million times, but its median time-to-fix is 17 seconds"); next is wrong method argument types (1.0 M, median 59 s) | Blackbox, >900k users, ~100 M compilation events, 2 years | Brown & Altadmri, "Novice Java Programming Mistakes: Large-Scale Data vs. Educator Beliefs", ACM TOCE 2017 (journal version of "37 Million Compilations", SIGCSE 2015) | [P] |
| 5.2 | Educators cannot predict which mistakes are common: their estimates "do not agree with one another or the student data" | 76 educators | same | [P] |
| 5.3 | Professionals at Google: syntax is a minor category next to dependency errors (52.68% C++ / 64.71% Java); "simple syntax errors such as expected_rparen occur more frequently" in C++ than Java, "consistent with the greater IDE usage for Java" | 26.6 M builds | Seo et al., ICSE 2014 | [P] |
| 5.4 | Jadud (cited by Seo): "44% of failed compiles were followed by another failed compile"; syntax problems and unknown variables were "25% of errors" for students | students | cited in Seo 2014 | [P as citation] |
| 5.5 | In CI, compile failures from source code are 14.4% of failed GHA runs; quality-check (style, docs, coverage) failures 12% | 375 failed runs | Zheng et al. 2026 | [P] |
| 5.6 | YAML/workflow syntax: named as failure cause W2 and as a theme ("YAML grammar is so tedious and hard to maintain", respondent R5; "Misconfigurations typically lead to multiple" failed attempts). The paper gives no separate count for pure YAML syntax errors | same | same | [P]; count **[NF]** |
| 5.7 | Conflict-level triviality: 23.21% of merge conflicts are FORMATTING (1.2) | 143 projects | Brindescu et al. | [P] |

**Reading.** The "missing semicolon" class is the highest raw-frequency error
and the cheapest per event *when feedback is immediate* (17 s median; and the
IDE observation in 5.3 shows tooling already removes most of it for
professionals). It becomes expensive only where feedback is late: in CI
configuration, where the first parser the author meets is the remote runner
(5.6), and in merges (5.7). The cost of trivial syntax is a function of
*feedback latency*, not of the error.

**[NF]** A clean measurement of "share of failed CI runs caused solely by a
syntax error in a config file".

---

## 6. Configuration errors as outage causes

### 6.1 Studies

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 6.1 | Google outage triggers 2010–2017: **binary push 37%, configuration push 31%**, user behaviour change 9%, processing pipeline 6%, service provider change 5%, performance decay 5%, capacity management 5%, hardware 2%. Root-cause categories: software 41.35%, development process failure 20.23%, complex system behaviours 16.90%, deployment planning 6.74%, network failure 2.75% | "a sample of thousands of postmortems over the last seven years" | Google SRE Workbook, Appendix C (sre.google/workbook/postmortem-analysis, fetched today) | [P] |
| 6.2 | "roughly 70% of outages are due to changes in a live system" | Google | SRE Book, introduction | [S] |
| 6.3 | Storage vendor support database: "a significant portion (27%) of customer cases" are configuration-related; "Configuration issues cause the largest percentage (31%) of high-severity support requests" | "COMP-A" (an anonymised commercial storage vendor) plus CentOS, MySQL, Apache HTTP Server, OpenLDAP; 546 cases per search summary | Yin, Ma, Xu, Zhou, Bairavasundaram, Pasupathy, SOSP 2011 | [P] |
| 6.4 | "Configuration-parameter mistakes account for the majority (70.0%∼85.5%)"; "38.1%∼53.7% of parameter misconfigurations are caused by illegal parameters that violate formats or semantic rules"; "12.2%∼29.7% of parameter mistakes are due to value-based inconsistency"; "Only 7.2%∼15.5% of the studied misconfiguration problems provide explicit messages that pinpoint the configuration error"; "16.7%∼32.4% of misconfigurations were introduced into systems that used to work"; 16.1%–47.3% make the system fully unavailable | same | same | [P] |
| 6.5 | Cloud outages: "UPGRADE is one of the largest root causes (16%)"; "BUGS are responsible for 15% of outages with known root causes"; "CONFIG problems cause 10% of service outages" | 597 unplanned outages, 32 popular Internet services (years 2009–2015 from memory) | Gunawi et al., "Why Does the Cloud Stop Computing?", SoCC 2016 | [P] |
| 6.6 | 772 real-world misconfiguration issues re-studied; existing taxonomies and tools do not cover modern cases | — | Liu et al., arXiv 2412.11121 (v4 July 2026) | [P, abstract only] |

### 6.2 Incidents (INCIDENT evidence: one event each)

| Incident | What the artefact was | The mismatch | Cost | Source | Tag |
|---|---|---|---|---|---|
| CrowdStrike, 19 July 2024 | A content/configuration file ("Channel File 291"), not code | "The new IPC Template Type defined 21 input parameter fields, but the integration code ... supplied only 20"; the validator checked against 21; "the attempt to access the 21st value produced an out-of-bounds" read. Mitigation in the vendor's own words: "Validate the number of input fields in the Template Type at sensor compile time" | Parametrix estimate: $5.4 bn direct loss to US Fortune 500 (excluding Microsoft); Delta alone ~ $500 M | CrowdStrike RCA PDF, 6 Aug 2024 [P]; Parametrix figure [S][V] |
| Cloudflare, 18 Nov 2025 | A generated "feature file" for Bot Management | A database permission change made the generating query emit duplicates; the file "doubled in size"; a hard limit ("set to 200, well above our current use of ~60 features") was hit and the code did "Result::unwrap() on an Err value". Remediation #1: "Hardening ingestion of Cloudflare-generated configuration files in the same way we would for user-generated input" | Core traffic failing from 11:20 UTC, largely normal by 14:30, all normal 17:06 | blog.cloudflare.com/18-november-2025-outage (fetched) | [P] |
| Knight Capital, 1 Aug 2012 | A deployment to 8 servers plus a reused flag | New code was not copied to the eighth server; orders "sent with the repurposed flag to the eighth server triggered the defective Power Peg code"; no second technician reviewed the deployment | > $460 M in about 45 minutes; SEC penalty $12 M | SEC press release 2013-222 and summaries | [S] |
| AWS S3, 28 Feb 2017 | Operator command argument typo removed too many servers | — | — | AWS postmortem | [M] not verified today |
| Facebook, 4 Oct 2021 | Backbone configuration command; DNS then withdrew | — | — | Meta engineering post | [M] not verified today |

**Reading.** Change is the dominant trigger (68% of Google triggers are
pushes, 6.1) and config pushes are nearly as dangerous as binary pushes while
getting far less checking. The two best-documented recent catastrophes are
*the same bug class*: data treated as trusted configuration, with a
count/size invariant that existed in someone's head (21 fields; ≤ 200
features) but not in a checked interface. In the Cloudflare case the language
already had the right type (`Result`) and the code discarded it. In Yin et al.,
38–54% of parameter misconfigurations violate a format or rule that a checker
could have known (6.4).

---

## 7. LLM-generated code: defects, security, fabrication, overclaim

### 7.1 Correctness and security (MEASURED)

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 7.1 | "we produce 89 different scenarios for Copilot to complete, producing 1,689 programs. Of these, we found approximately 40 % to be vulnerable." | 2021 Copilot | Pearce, Ahmad, Tan, Dolan-Gavitt, Karri, "Asleep at the Keyboard?", IEEE S&P 2022, arXiv 2108.09293 | [P] |
| 7.2 | Participants with an AI assistant "wrote insecure solutions more often ... for four of our five programming tasks" and "were more likely to believe that they wrote secure code" | 47 participants | Perry, Srivastava, Kumar, Boneh, CCS 2023, arXiv 2211.03622 | [P] |
| 7.3 | "52% of ChatGPT answers contain incorrect information and 77% are verbose"; participants "overlooked misinformation in the answers 39% of the time" and still preferred ChatGPT 35% of the time | 517 Stack Overflow questions; user study | Kabir, Udo-Imeh, Kou, Zhang, CHI 2024, arXiv 2308.02312 | [P] |
| 7.4 | Package hallucination: of 2.23 M package references in 576,000 samples from 16 models, "440,445 (19.7%) were" hallucinated; "at least 5.2% for commercial models and 21.7% for open-source models"; "205,474 unique examples"; "43% of hallucinated packages were repeated in all 10 queries, while 39% did not repeat at all"; "58% of the time, a hallucinated package is repeated more than once in 10 iterations" | 16 LLMs, Python + JavaScript | Spracklen et al., "We Have a Package for You!", USENIX Security 2025, arXiv 2406.10279 | [P] |
| 7.5 | RCT: developers forecast −24% time, afterwards believed −20%, measured **+19%** ("AI tooling slowed developers down"); "Developers accept <44% of AI generations"; "9% of time spent reviewing/cleaning AI outputs" | 16 experienced OSS developers, 246 tasks, Feb–Jun 2025 tools | METR (Becker, Rush, Barnes, Rein), arXiv 2507.09089 | [P] |

### 7.2 Vendor and survey evidence (REPORTED)

| # | Finding | Source | Tag |
|---|---|---|---|
| 7.6 | Models "chose the insecure option 45 percent of the time" across 80 tasks; Java failure rate "over 70 percent" (not "72%" — I could not confirm that figure); Oct 2025 update: only GPT-5 reasoning models improved | Veracode GenAI Code Security Report, July 2025 and Oct 2025 update | [S][V] |
| 7.7 | 211 M changed lines 2020–2024: duplicated blocks (≥5 lines) up about 8× in 2024; copy/pasted lines 8.3% → 12.3%; moved (refactored) lines 24.1% → 9.5%; 2024 first year copy/paste exceeded moved; churn 3.1% → 5.7% (churn figure not confirmed against the original) | GitClear, "AI Copilot Code Quality", 2025 | [S][V] |
| 7.8 | AI-co-authored PRs: 10.83 issues per PR vs 6.45 human (≈1.7×); 1.4× more critical, 1.7× more major; humans had 1.76× more spelling errors. 470 PRs (320 AI / 150 human); vendor cannot guarantee "human" PRs were human | CodeRabbit, Dec 2025 | [S][V] |
| 7.9 | Stack Overflow 2025 survey: 46% do not trust AI output accuracy (31% the year before); 33% trust; 66% cite "AI solutions that are almost right, but not quite"; 45% say "Debugging AI-generated code is more time-consuming" | Stack Overflow press release and coverage | [S] |
| 7.10 | Sonar 2026: 96% do not fully trust AI code is functionally correct; only 48% always check it before committing | Sonar State of Code survey, via The Register 2026-01-09 | [S][V] |
| 7.11 | DORA 2024: a 25% increase in AI adoption associated with −1.5% delivery throughput and −7.2% delivery stability. DORA 2025: throughput relation turned positive; "AI adoption does continue to have a negative relationship with software delivery stability"; AI "amplifies" existing organisational traits | DORA reports via Google Cloud blog and coverage | [S] |

### 7.3 Agentic pull requests in the wild (MEASURED, 2025–2026)

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 7.12 | "Autonomous Coding Agents lag human in PR acceptance rates by a large margin": Codex 64%, Devin 49%, Copilot 35% acceptance; "ranging from 15 to 40 percentage points below human performance"; contrasts with SWE-bench Verified scores "exceeding 70%" | AIDev: 456,535 agentic PRs, 47,303 developers, 61,453 repositories | Li, Zhang, Hassan, arXiv 2507.15003 (Jul 2025) | [P] |
| 7.13 | 33k agentic PRs: overall 71.48% merged; Codex 82.59%, Cursor 65.22%, Claude Code 59.04%, Devin 53.76%, Copilot 43.04%. By task: documentation 84%, CI 79%, build 74% merged; fix 64%, performance 55%. "Not-merged PRs tend to involve larger code changes, touch more files, and often do not pass the project's CI/CD pipeline validation." Rejection reasons from 600 PRs: "lack of meaningful reviewer engagement, duplicate PRs, unwanted feature implementations, and agent misalignment" | 33k PRs, 5 agents | Ehsani et al., "Where Do AI Coding Agents Fail?", arXiv 2601.15195 (Jan 2026) | [P] |
| 7.14 | More review activity predicts merge for human PRs but *non-merge* for agentic PRs | AIDev | arXiv 2602.08915 | [S] |

Numbers in 7.12 and 7.13 differ because the filters differ; do not mix them.

### 7.4 Overclaim and fabricated structure (the classes the estate names)

Evidence that maps directly onto "hallucination / overclaim / fabricated
structure / drift":

* **Fabricated reference**: 19.7% hallucinated packages; 58% are repeatable,
  which is what makes "slopsquatting" (term coined by Seth Larson, PSF, 2025)
  an attack and not noise (7.4). **[P]** / term **[S]**
* **Overclaim by the model**: `claude-code` issue #3382 "Claude says 'You're
  absolutely right!' about everything", opened 12 July 2025; The Register,
  13 Aug 2025. **[S]** (FOLKLORE-grade: a bug report, not a measurement.)
* **Overclaim transferred to the human**: users with AI "more likely to believe
  that they wrote secure code" (7.2); METR developers believed they were 20%
  faster while 19% slower (7.5); 39% of misinformation overlooked (7.3). **[P]**
  This is the best-measured of the four: the error is not only in the output,
  it is in the *confidence attached to the output*.
* **Benchmark-vs-reality gap**: SWE-bench >70% vs 35–64% real acceptance
  (7.12). **[P]**
* **Structural erosion**: duplication up, refactoring down (7.7) **[S][V]**.
* **[NF]** A measured rate of LLMs fabricating *repository structure* (files,
  modules, monorepos that do not exist) as distinct from packages or APIs. I
  found package-hallucination and API-misuse work only. The estate's "fake
  `lith` monorepo" class has, as far as I found, no published base rate.
* **[NF]** A measured rate of instruction/context *drift* over long agent
  sessions in software tasks.

---

## 8. Review burden (human PRs and AI PRs)

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 8.1 | "Only about 15% of comments provided by reviewers indicate a possible defect, much less a blocking defect"; maintainability feedback is "at least 50% of all"; without prior exposure to the code "only 33% of any reviewer's comments are deemed useful"; rising to "about 67%" by the third review of the same area; usefulness drops with change size | Microsoft | Czerwonka, Greiler, Tilford, "Code Reviews Do Not Find Bugs", ICSE-SEIP 2015 | [P] |
| 8.2 | 1.5 M review comments classified useful / not useful across five Microsoft projects | Microsoft | Bosu, Greiler, Bird, MSR 2015 | [S]; overall useful share **[NF]** |
| 8.3 | High-AI-adoption teams: PR review time +91%, average PR size +154%, bugs per developer +9%, while tasks completed +21% and PRs merged +98% (correlational) | >10,000 developers, 1,255 teams | Faros AI, "AI Productivity Paradox", 2025 | [S][V] |
| 8.4 | curl bug bounty: "somewhere north of 15% of the submissions ending up confirmed vulnerabilities" in earlier years; from 2025 "the confirmed-rate plummeted to below 5%"; programme (87 confirmed vulnerabilities, over 100,000 USD paid since April 2019) ended 31 January 2026 | curl | D. Stenberg, "The end of the curl bug bounty", 26 Jan 2026 | [P] |
| 8.5 | 50% of developers report losing 10+ hours a week to organisational inefficiency (33% the year before); 68% report AI saves 10+ hours; coding is about 16% of the week | 3,500 developers and managers | Atlassian State of Developer Experience 2025 | [S][V] |
| 8.6 | "more than 17 hours a week dealing with maintenance issues"; 13.5 h technical debt + 3.8 h bad code in a 41.1 h week; "nearly $85 billion worldwide in opportunity cost lost annually" (the $85 bn is for the bad-code hours) | survey | Stripe, "The Developer Coefficient", 2018 | [S][V] |
| 8.7 | Agentic PR acceptance and CI-failure association | see 7.12–7.14 | | |

**Reading.** Human review was never mainly a defect filter (15%); half of it
is maintainability commentary, much of which is mechanically decidable. AI
raises the *volume and size* of what must be reviewed (8.3) while lowering the
prior that any given submission is valid (8.4: >15% → <5%). Verification is
the scarce resource; generation is not.

---

## 9. Template drift, workflow drift, copy-based reuse

This is the thinnest area. I report the gap rather than fill it.

| # | Finding | Source | Tag |
|---|---|---|---|
| 9.1 | **[NF]** No empirical study measuring how repositories generated from a template (GitHub template repos, cookiecutter, copier, cruft) diverge from that template over time. | search today | — |
| 9.2 | The closest study characterises GitHub template repositories themselves (domains, maintenance, quality issues, guidelines); it names "repurposing regular repositories as templates without proper adaptation, unclear or inactive maintenance status, and poor separation of concerns" as pitfalls. It does not track descendants. | Da Silva, Abbassi, Trabelsi, Borba, Khomh, arXiv 2606.14616 (Jun 2026) | [P, abstract]; pitfall list [S] |
| 9.3 | Tools exist precisely because the platform has no sync: cruft stores the template commit hash and variables in `.cruft.json` and can run in CI "to ensure projects don't unintentionally drift". | cruft docs; Thoughtworks Radar | [S] |
| 9.4 | Workflow files are a drifting copy by construction: median three workflow files per repo; 7.3% of all workflow files change every week; three quarters of changes are a single change; "the large majority ... have to do with task configuration and task specification" | Rostami Mazrae et al., arXiv 2602.14572 | [P, abstract] |
| 9.5 | Most workflows reference outdated action releases, typically at least seven months behind | Decan, Mens, Onsori Delicheh, "On the outdatedness of workflows in the GitHub Actions ecosystem", JSS 2023 | [S] — via a citing paper; exact share **[NF]** |
| 9.6 | Copy-based reuse is common and "the infrastructure to systematically support copy-based reuse appears to be entirely missing" | ACM TOSEM, Nov 2025, DOI 10.1145/3715907 | [S], abstract only; authors not confirmed |
| 9.7 | Caching configuration alone needs an average 9.37 changes per adopting repository | Hasan et al., arXiv 2604.13129 | [P, abstract] |

**Reading.** The pain is widely felt (tools, radar entries, folklore) and
almost unmeasured. An estate with one template and several hundred descendants
is in a position to produce the first real numbers; that would be a
contribution, not a replication.

---

## 10. Licence and metadata drift

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 10.1 | "about half of the repositories did not fully declare all licenses found in the code. Of these, approximately ten percent represented a permissive vs. copyleft license mismatch. Furthermore, existing tools cannot fully identify licences." | 1,000 GitHub repositories | Wolter, Barcomb, Riehle, Harutyunyan, "Open Source License Inconsistencies on GitHub", ACM TOSEM 32(5) 2023, DOI 10.1145/3571852 | [P] |
| 10.2 | "about 62% of repositories in their sample of 1,552 JavaScript projects showed the use of multiple open source licenses. However, only 30% actually have multiple licenses declared at the top-level." | 1,552 JS projects | Moraes et al., as cited in 10.1 | [P as citation] |
| 10.3 | Licence identification tools: Ninka "recall of 82.3% and a precision of 96.6%" on 0.8 M Debian files | — | cited in 10.1 | [P as citation] |
| 10.4 | PyPI licence incompatibility rate "7.27% of releases" | — | — | [M], **not verified**; do not cite |

**Reading.** Declared metadata disagrees with content in about half of
repositories. Frequency is very high; realised cost is rare but legal and
unbounded. Note the tool-accuracy ceiling (10.3): a sweep by an 82%-recall
identifier *creates* drift, which independently supports a "no automated
licence edits" rule.

---

## 11. Works-on-my-machine / reproducibility

| # | Finding | Sample | Source | Tag |
|---|---|---|---|---|
| 11.1 | Of notebooks with declared dependencies and unambiguous execution order, "only 24.11% executed without errors and only 4.03% produced the same results" | 1.4 M Jupyter notebooks from GitHub; 863,878 attempted executions | Pimentel, Murta, Braganholo, Freire, MSR 2019 | [P] |
| 11.2 | 8.1% of npm client releases failed from "breaking due to external change" (nothing in the client changed) | 384 npm packages | Venturini et al. | [P] |
| 11.3 | 16.7%–32.4% of misconfigurations "were introduced into systems that used to work" | 546 cases | Yin et al. | [P] |
| 11.4 | "Almost all flaky tests (96%) are independent of the platform" — so platform difference is *not* the main source of flakiness | 161 fixes | Luo et al. | [P] |
| 11.5 | "34% of Dockerfiles on GitHub fail to build" (Cito et al., MSR 2017) | — | — | [M], **not verified** today |

---

## 12. Aggregate time/cost figures (weakest evidence, widest claims)

All **REPORTED** and **[V]** unless marked.

* Stripe 2018: 17.3 h/week on maintenance; $85 bn/yr (8.6). **[S][V]**
* Atlassian 2025: half of developers lose 10+ h/week (8.5). **[S][V]**
* CISQ "Cost of Poor Software Quality in the US" 2022: $2.41 trillion. **[M]**,
  not verified today.
* Google: 2–16% of testing compute spent rerunning flaky tests (2.8). **[S]**
* Median build-error fix: 5 min C++ / 12 min Java at Google (2.2). **[P]**
* Novice bracket error: 17 s median (5.1). **[P]**
* npm manifesting breaking change: 134 days to recover, where recovered (4.3). **[P]**
* Textual conflict relationship: 9.8 days mean persistence (1.7). **[P]**
* Workflow rerun: 5.3 h mean wait; 7.5 h when the rerun changes nothing (2.12). **[P]**

---

## 13. The folklore: each joke names a failure class

FOLKLORE measures nothing; the "evidence" column points to the measured item
that shows the class is real. Attributions of the jokes themselves are **[M]**
unless a tag says otherwise.

| # | Joke / complaint | Failure class it names | Measured counterpart |
|---|---|---|---|
| F1 | "Works on my machine." (reply: "Then we'll ship your machine" — the Docker origin joke) | Ambient, undeclared environment as an implicit input | 11.1 (24.11% / 4.03%); 2.5 workflow-environment failures |
| F2 | "It worked yesterday / nothing changed." | Unpinned, time-varying inputs: the build is a function of *now* | 11.2 (8.1% external-change breaks); 11.3 |
| F3 | YAML jokes: "YAML engineer"; the Norway problem (`NO` → `false`); "the YAML document from hell"; significant whitespace | Stringly-typed configuration with implicit typing; no schema at the point of authoring | Norway problem confirmed as YAML 1.1 behaviour, still present in common libraries per a Jan 2026 write-up [S]; 6.4 (38–54% rule-violating parameters); 5.6 (R5 quote) |
| F4 | left-pad; xkcd 2347 "Dependency" (the whole stack resting on one unpaid maintainer in Nebraska); "node_modules is the heaviest object in the universe" | Transitive dependency on unowned, removable, unaudited nodes | 4.11 [S] |
| F5 | "Dependency hell" (earlier "DLL hell"); the diamond dependency | Unsatisfiable or conflicting version constraints | 2.2 (dependency errors 52.68% / 64.71% of build errors at Google) |
| F6 | "Semver is a lie"; "it's just a patch bump"; Hyrum's Law ("with a sufficient number of users of an API ... all observable behaviors of your system will be depended on by somebody") | A version number is an unchecked assertion about compatibility | 4.1 (20.1%), 4.3 (44% of manifesting breaks in minor and in patch), 4.5 (3.22%) |
| F7 | "Dependabot spam" / notification fatigue | An automated proposer with no confidence signal produces review load, not safety | 4.6 (score present on 3.4% of PRs; 11.3% abandoned the bot) |
| F8 | "Rebase hell"; "merge hell"; "force-push and pray"; xkcd 1597 "Git" ("save your work elsewhere, delete the project, and download a fresh copy") | Long-lived divergence plus line-based merging of structured artefacts | 1.1, 1.5, 1.7 (9.8 days) |
| F9 | "Who broke main?" | Higher-order (semantic) conflict: each side green, the merge red | 1.6 (1% build + 6% test; a third of conflicts invisible to Git) |
| F10 | "Green CI lies"; "all green, ship it"; "tests pass, prod fails" | Vacuous or misreported verdict; the check does not exercise the change | 2.15 (12% of green builds hide an ignored failure; 9% misleading), 2.17 (58% / 21% coverage of dependency calls) |
| F11 | "Just re-run it"; "retry until green" | Non-deterministic verdict treated as noise | 2.7 (84%), 2.11 (67.73%), 2.12 (3.2 of 3.7 waiting-years wasted) |
| F12 | "Heisenbug" | Timing/observation-dependent failure | 2.10 (Async Wait 45%, Concurrency 20%) |
| F13 | "LGTM" as rubber stamp; "Ask a programmer to review 10 lines of code, he'll find 10 issues. Ask him to do 500 lines and he'll say it looks good." (attributed to Giray Özil; attribution confirmed only via secondary reposts [S]) | Review attention falls as change size rises; approval is a social act, not a check | 8.1 (15% of comments are defects; usefulness falls with size), 8.3 (+154% PR size, +91% review time) |
| F14 | Bikeshedding (Parkinson's law of triviality, 1957; popularised in software by Poul-Henning Kamp's 1999 FreeBSD "bikeshed" email); "tabs vs spaces" | Human effort attracted to mechanically decidable questions | 8.1 (≥50% maintainability comments), 1.2 (23.21% FORMATTING conflicts), 2.5 (12% quality-check failures) |
| F15 | "Missing semicolon"; the Greek-question-mark prank (U+037E looks like `;`) | Surface-syntax fragility; cost set by feedback latency | 5.1 (most frequent novice error; 17 s), 5.3 |
| F16 | Commit chains "fix", "fix2", "really fix CI", "pls work" | A configuration language whose only interpreter is remote: debugging by push | 9.4 (7.3% of workflow files change weekly; ¾ single-change edits), 5.6 |
| F17 | "It's a one-line config change, what could go wrong"; "Never deploy on Friday" | Unsafe change rollout; config trusted more than code | 6.1 (37% + 31%), CrowdStrike, Cloudflare, Knight |
| F18 | "There are only two hard things in computer science: cache invalidation, naming things, and off-by-one errors." (Phil Karlton, with the usual addition) | Stale derived state; identity; boundary errors | 9.7 (cache config churn); CrowdStrike was literally 21 vs 20 |
| F19 | "It's always DNS." | Hidden shared dependency below the abstraction everyone reasons at | Facebook 2021 [M] |
| F20 | "The README is aspirational"; "the docs lie"; "TODO: fix later" | Prose claims with no link to a check: declared ≠ actual | 10.1 (half of repos mis-declare licences) as the measured instance of declared-vs-actual drift |
| F21 | "It's on GitHub, so it's open source." | Licence metadata is not licence reality | 10.1, 10.2 |
| F22 | "Copied from Stack Overflow" → now "ChatGPT wrote it" | Provenance-free reuse | 7.3 (52% incorrect), 7.7 (duplication up) |
| F23 | "The AI invented a library"; "vibe coding"; slopsquatting | Fabricated reference presented as fact | 7.4 (19.7%; 58% repeatable) |
| F24 | "You're absolutely right!" | Sycophantic agreement; confidence without checking | issue #3382 [S]; 7.2, 7.5 (humans inherit the overconfidence) |
| F25 | "Almost right, but not quite." | Plausible near-miss: the costliest error to detect | 7.9 (66%), 7.3 (39% overlooked) |
| F26 | "AI slop"; Stenberg's "death by a thousand slops" | Asymmetry: cheap to generate, costly to verify | 8.4 (>15% → <5% valid), 7.12–7.13 |
| F27 | "It passes the benchmark." | Benchmark success ≠ field success | 7.12 (>70% vs 35–64%) |
| F28 | xkcd 303 "Compiling" (sword fights while the code compiles) | Slow feedback loop as tolerated idle time | 2.1 (7–10 builds/day), 2.12 (5.3 h rerun wait) |
| F29 | xkcd 927 "Standards" (14 competing standards → 15) | Proliferation instead of consolidation; format drift | 9.x (no measured base rate) |
| F30 | "Snowflake server/repo"; "configuration drift" | An instance silently diverging from its template | **[NF]** — 9.1 |
| F31 | "It's not a bug, it's a feature." | No machine-readable statement of intent to check behaviour against | no single measure; Venturini's largest breaking-change category is "feature change" [P, line 1620] |

---

## 14. Ranking by frequency × cost

**Method and honesty note.** There is no common unit. I score frequency (how
often a working team meets it) and unit cost (what one occurrence costs,
including tail risk) on a coarse H/M/L scale from the evidence above, then rank.
Where the evidence is vendor-only or missing, the confidence column says so.
This is judgement, not a computed result.

| Rank | Pain class | Frequency | Unit cost | Why here | Confidence |
|---|---|---|---|---|---|
| 1 | **Unsafe change rollout: config/data pushed as trusted, invariants unchecked** | M (every deploy is exposure; 68% of Google outage triggers are pushes, 31% config alone) | **Extreme tail** ($5.4 bn est. for one file; hours of global outage) | Highest expected cost by a wide margin; the two best-documented incidents are schema/arity/size violations a checker could state | High on frequency share [P]; cost figures are estimates [V] |
| 2 | **AI/LLM errors and the verification burden they create** (fabricated references, insecure output, near-miss code, inherited overconfidence, slop submissions) | H and rising (19.7% hallucinated packages; ~40–45% insecure completions; 66% report "almost right") | M–H per event, and it lands on the scarcest resource, reviewer attention (+91% review time; validity prior fell from >15% to <5% at curl) | Only class whose frequency is growing with adoption; DORA finds the stability penalty persisted into 2025 | Medium: core studies [P], magnitudes of burden mostly [V] |
| 3 | **Untrustworthy CI verdicts** (flaky failures, ignored failures, vacuous passes) | **Very high** (10–17% of GHA runs fail; 84% of Google pass→fail transitions involve a flaky test; 12% of green Travis builds hide a red job) | L–M per event (minutes to hours), but it destroys the value of every other gate | A false red costs time; a false green costs correctness; both are common | High [P] |
| 4 | **Dependency-update breakage and unverified version claims** | H (20.1% of non-major Maven releases breaking; 11.7% of npm clients hit; 3.22% of crate releases as a lower bound) | M–H (134 days to recover in npm; tests see 58%/21% of dependency calls; supply-chain tail) | Continuous exposure, weak oracle, and now a second axis (too-fast adoption of malicious releases) | High [P] |
| 5 | **Merge conflicts, textual and higher-order** | H (17–19% of merges; +7% build/test conflicts Git calls clean) | M (2× bug-proneness; 26× for semantic conflicts; 9.8 days persistence) | Well measured; a quarter is pure formatting and therefore avoidable | High [P] |
| 6 | **Review as bottleneck and rubber stamp** | H (every change) | M (latency; only 15% of comments concern defects) | Amplified by rank 2 | Medium [P] for the Microsoft numbers, [V] for the AI amplification |
| 7 | **Environment irreproducibility** ("works on my machine", "nothing changed") | M–H (24.11% of notebooks run; 8.1% of npm releases broken by external change) | M | Underlies part of ranks 3 and 4 | Medium [P], narrow samples |
| 8 | **Template / workflow / configuration drift** | Probably H in multi-repo estates (7.3% of workflow files change weekly; actions ≥7 months stale) | Unknown | Universally complained about, almost unmeasured — the ranking is mostly ignorance | **Low**: 9.1 is [NF] |
| 9 | **CI compute cost and waste** | H (every push) | L per repository ($504/yr average; known switches save about $60/yr); multiplies with repo count and macOS (10× Linux) | Real but small next to the human cost of ranks 3 and 6 | High [P], at 2023 prices |
| 10 | **Trivial syntax errors** ("missing semicolon") | **Very high** raw frequency (the top novice error) | Very low where feedback is immediate (17 s); a full CI round trip where it is not | Rank rises sharply for any language whose only parser is remote (workflow YAML) | High [P] for code; [NF] for config files |
| 11 | **Licence and metadata drift** | Very high prevalence (about half of repos) | Rarely realised; legal and unbounded when it is | Classic low-frequency-of-harm, high-severity tail; automation makes it worse (82% recall) | High on prevalence [P]; cost unmeasured |

Two orderings worth separating, because they disagree:

* **By raw frequency**: syntax errors > CI failures/flakes > review > merge
  conflicts ≈ dependency breaks > LLM errors (rising) > drift > config outages.
* **By cost per event**: config outages ≫ dependency/supply-chain ≫ semantic
  merge conflict > LLM near-miss > flaky verdict > syntax error.

The product puts change-rollout and LLM verification at the top and trivial
syntax near the bottom — unless feedback is late, in which case the "trivial"
class inherits the cost of the pipeline it had to traverse.

---

## 15. What the evidence says about where types and tropes could bite

**Status of this section: my inference from the sources (STATED at best). None
of it is tested here. Each line cites the number that motivates it.**

1. **Canonical form removes a measured quarter of merge conflicts.** 23.21%
   FORMATTING + 0.60% COMMENTS (1.2). If two texts that mean the same thing are
   the same bytes, that class cannot occur. Semistructured merge independently
   removed 34±21% of conflicts (1.11). The estate's "equivalence as identity"
   line and its JCS/KYAML rulings are the same idea applied to data files; the
   external literature supports the direction, not any particular tool.
2. **Arity, size and shape invariants at the config boundary.** CrowdStrike:
   21 declared vs 20 supplied, fixed by a *compile-time* count check in the
   vendor's own words. Cloudflare: an implicit `≤ 200` with a discarded
   `Result`. Yin: 38–54% of parameter errors violate a statable rule, and
   12–30% are cross-field inconsistencies (dependent constraints). "Parse, don't
   validate" and refinement/dependent typing address exactly this; so does the
   Cloudflare remediation "treat our own config like user input".
3. **A version bump as a proof-carrying claim.** 3–20% of "compatible" releases
   are not (4.1, 4.5); the one platform signal is missing 96.6% of the time
   (4.6); tests see 58%/21% of the surface (4.9). API-diff-derived versions
   (cargo-semver-checks; Elm's enforced semver [M]) convert the claim into a
   check. A safe/unsafe bump classifier needs two axes: interface compatibility
   and release age/provenance (4.10).
4. **Verdicts with truth-status.** Since 12% of green builds hide a red job
   (2.15) and two thirds of reruns are flakes (2.11), a CI result is better
   modelled as a three- or four-valued claim (pass / fail / skipped /
   not-run / flaky-suspected) than as a boolean. The estate's "never present an
   unexecuted check as a pass" rule is the same distinction; externally it is
   measured as a 9–12% misreport rate.
5. **Closed-world checks for fabricated references.** A hallucinated package
   name (19.7%) is refutable by lookup in a registry; a fabricated file or
   module is refutable by lookup in the tree. This is the cheapest LLM-error
   class to eliminate mechanically and the literature gives a base rate only
   for packages (7.4). Repository-structure fabrication is unmeasured ([NF]).
6. **Confidence must be derived, not asserted.** Perry (7.2), METR (7.5) and
   Kabir (7.3) all measure the same thing: the human's confidence rises while
   correctness falls. A grade "derived from receipts, never asserted" is a
   direct structural answer to a measured effect.
7. **Feedback latency is the cost of syntax.** 17 s in an IDE (5.1); a remote
   round trip for workflow YAML (5.6). Any typed/checked front end for CI
   configuration moves that class from rank 10's worst case to its best case.
8. **Effects, not types, for flakiness.** Async wait 45%, concurrency 20%
   (2.10). Type systems help little here unless they track time/ordering
   effects; hermeticity and determinism are the lever. I flag this so the
   programme does not overclaim types for rank 3.
9. **Licence edits.** With identifier recall at 82.3% (10.3) and half of repos
   already inconsistent (10.1), automated rewriting has a measured reason to
   make things worse. Detection and flagging are supported by the evidence;
   automatic correction is not.

### What the evidence does *not* support

* That any of the above "permanently prevents" a class in practice. The studies
  measure prevalence, not the effect of the proposed cure, except Apel et al.
  (structured merge) and Bouzenia & Pradel (CI switches).
* That AI-code defect rates are stable. Veracode's October 2025 update and the
  DORA 2025 throughput reversal show the numbers moving within a year.
* Any cross-class cost comparison in common units.

---

## 16. Gaps, unverified items and cautions (collected)

| Item | Status |
|---|---|
| Ghiotto et al. full text and its own conflict rate | not obtained; [S] only |
| Mens 2002 survey text | not read; [S] |
| Beller et al. Travis numbers | [NF] |
| Microsoft "4.6% flaky" and Herzig false-alarm cost | [NF] |
| Abdalkareem "≈10% of commits CI-skippable" | [M] |
| Share of failed CI runs that are purely config-syntax errors | [NF] |
| Post-generation template drift, any measurement | [NF] |
| Decan et al. exact share of outdated workflows | [NF]; "≥7 months" is [S] |
| Bosu et al. overall useful-comment share | [NF] |
| LLM fabrication of repository structure; context drift in long agent sessions | [NF] |
| Veracode "72%" for Java | not confirmed; source says "over 70 percent" |
| Stack Overflow trust figure: 33% vs 29% | sources conflict; cite the press release (46% distrust) |
| GitClear churn 3.1% → 5.7% | not confirmed against original |
| Cito Dockerfile 34%; PyPI 7.27%; CISQ $2.41 tn; AWS S3 2017; Facebook 2021 | [M], unverified today |
| Whether GitHub's self-hosted runner charge is still postponed | not confirmed from GitHub |
| Gunawi study years (2009–2015); Yin total of 546 cases | year range [M]; 546 is [S] (search summary), the per-system percentages are [P] |
| All Java-only samples (Zheng, Ge & Zhang, Huang & Lin, Shen) | may not generalise to other ecosystems |
| All [V] rows | commercially interested; use for direction, not magnitude |

---

## 17. Sources

Primary texts read (PDF or vendor page):

* Brindescu, Ahmed, Jensen, Sarma. EMSE 2019/2020. https://www.ics.uci.edu/~iftekha/pdf/J4.pdf
* Brun, Holmes, Ernst, Notkin. ESEC/FSE 2011. https://homes.cs.washington.edu/~mernst/pubs/vc-conflicts-fse2011.pdf
* Shen, Gulzar, He, Meng. TOSEM 2023. https://par.nsf.gov/servlets/purl/10515782
* Apel et al. ESEC/FSE 2011. https://www.infosun.fim.uni-passau.de/spl/SSMerge/deploy/apel__ssm.pdf
* Seo et al. ICSE 2014. https://research.google/pubs/programmers-build-errors-a-case-study-at-google/
* Bouzenia & Pradel. ICSE 2024. https://software-lab.org/publications/icse2024_workflows.pdf
* Zheng et al. TOSEM 2026. https://jiangnanpro.github.io/assets/pdf/3749371.pdf
* Huang & Lin. TOSEM 2026. https://jiangnanpro.github.io/assets/pdf/3795771.pdf
* Ge & Zhang. arXiv 2602.02307. https://arxiv.org/abs/2602.02307
* Luo, Hariri, Eloussi, Marinov. FSE 2014. https://huang.isis.vanderbilt.edu/cs8395/paper/flakytest.pdf
* Habchi et al. arXiv 2112.04919 (used for its citations of Google figures). https://arxiv.org/abs/2112.04919
* Gallaba, Macho, Pinzger, McIntosh. ASE 2018. https://keheliya.github.io/papers/ase2018_gallaba.pdf
* Hilton et al. ASE 2016. https://cs.uwaterloo.ca/~m2nagapp/courses/CS846/1171/papers/hilton_ase16.pdf
* Hasan et al. arXiv 2604.13129. https://arxiv.org/abs/2604.13129
* Rostami Mazrae, Decan, Mens, Wessel. arXiv 2602.14572. https://arxiv.org/abs/2602.14572
* Ochoa et al. arXiv 2110.07889. https://arxiv.org/abs/2110.07889
* Venturini et al. arXiv 2301.04563. https://arxiv.org/abs/2301.04563
* Pinckney et al. arXiv 2304.00394. https://arxiv.org/abs/2304.00394
* He, He, Zhang, Zhou. arXiv 2206.07230. https://arxiv.org/abs/2206.07230
* Hejderup & Gousios. arXiv 2109.11921. https://arxiv.org/abs/2109.11921
* Tanaka et al. arXiv 2609.16605. https://arxiv.org/abs/2609.16605
* Brown & Altadmri. ACM TOCE 2017. https://kar.kent.ac.uk/id/document/51177
* Yin et al. SOSP 2011. https://www.sigops.org/s/conferences/sosp/2011/current/2011-Cascais/printable/12-yin.pdf
* Gunawi et al. SoCC 2016. https://www.ece.iastate.edu/~mai/docs/papers/2016_SoCC_COS.pdf
* Liu et al. arXiv 2412.11121. https://arxiv.org/abs/2412.11121
* Google SRE Workbook, Appendix C. https://sre.google/workbook/postmortem-analysis/
* CrowdStrike, Channel File 291 RCA. https://crowdstrike.com/wp-content/uploads/2024/08/Channel-File-291-Incident-Root-Cause-Analysis-08.06.2024.pdf
* Cloudflare, 18 November 2025 outage. https://blog.cloudflare.com/18-november-2025-outage/
* Pearce et al. arXiv 2108.09293. https://arxiv.org/abs/2108.09293
* Perry et al. arXiv 2211.03622. https://arxiv.org/abs/2211.03622
* Kabir et al. arXiv 2308.02312. https://arxiv.org/abs/2308.02312
* Spracklen et al. arXiv 2406.10279. https://arxiv.org/abs/2406.10279
* METR. arXiv 2507.09089. https://arxiv.org/abs/2507.09089
* Li, Zhang, Hassan. arXiv 2507.15003. https://arxiv.org/abs/2507.15003
* Ehsani et al. arXiv 2601.15195. https://arxiv.org/abs/2601.15195
* Czerwonka, Greiler, Tilford. ICSE-SEIP 2015. https://www.microsoft.com/en-us/research/wp-content/uploads/2015/05/PID3556473.pdf
* Stenberg, "The end of the curl bug bounty". https://daniel.haxx.se/blog/2026/01/26/the-end-of-the-curl-bug-bounty/
* Wolter et al. TOSEM 2023. https://oss.cs.fau.de/wp-content/uploads/2022/10/wolter-2022-open.pdf
* Da Silva et al. arXiv 2606.14616. https://arxiv.org/abs/2606.14616
* Pimentel et al. MSR 2019. https://leomurta.github.io/papers/pimentel2019a.pdf
* GitHub Actions runner pricing. https://docs.github.com/en/billing/reference/actions-runner-pricing

Secondary / search-confirmed:

* Ghiotto et al. review. https://neverworkintheory.org/2021/08/12/on-the-nature-of-merge-conflicts.html
* Mens 2002. https://bibbase.org/network/publication/mens-astateoftheartsurveyonsoftwaremerging-2002
* Google Testing Blog (Micco, 2016). https://testing.googleblog.com/2016/05/
* Lam et al. ICSE 2020. https://www.microsoft.com/en-us/research/publication/a-study-on-the-lifecycle-of-flaky-tests/
* Beller et al. MSR 2017. https://peerj.com/preprints/1984
* GitHub Actions pricing change. https://github.blog/changelog/2025-12-16-coming-soon-simpler-pricing-and-a-better-experience-for-github-actions/ and https://resources.github.com/actions/2026-pricing-changes-for-github-actions/
* Raemaekers et al. https://jstvssr.github.io/assets/pdf/semantic-versioning-maven.pdf
* cargo-semver-checks study. https://predr.ag/blog/semver-violations-are-common-better-tooling-is-the-answer/
* left-pad. https://en.wikipedia.org/wiki/Npm_left-pad_incident ; https://blog.npmjs.org/post/141577284765/kik-left-pad-and-npm
* Knight Capital. https://www.sec.gov/news/press-release/2013-222
* Parametrix estimate, via coverage. https://www.techtarget.com/cybersecurity/news/366602392/CrowdStrike-details-errors-that-led-to-mass-IT-outage
* Veracode. https://www.veracode.com/blog/2025-genai-code-security-report/
* GitClear coverage. https://www.devclass.com/ai-ml/2025/02/20/ai-is-eroding-code-quality-states-new-in-depth-report/1626250
* CodeRabbit. https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report ; https://www.theregister.com/2025/12/17/ai_code_bugs/
* Stack Overflow 2025. https://stackoverflow.co/company/press/archive/stack-overflow-2025-developer-survey/
* Sonar survey. https://www.theregister.com/2026/01/09/devs_ai_code/
* DORA 2024 / 2025. https://cloud.google.com/blog/products/devops-sre/announcing-the-2024-dora-report ; https://services.google.com/fh/files/misc/2025_state_of_ai_assisted_software_development.pdf
* Faros AI. https://www.faros.ai/blog/ai-productivity-paradox-report-2025
* Atlassian. https://www.atlassian.com/blog/developer/developer-experience-report-2025
* Stripe. https://stripe.com/files/reports/the-developer-coefficient.pdf
* Agentic PR review dynamics. https://arxiv.org/abs/2602.08915
* Decan et al. JSS 2023. https://orbi.umons.ac.be/handle/20.500.12907/46367
* cruft. https://github.com/projectsyn/cruft ; https://www.thoughtworks.com/radar/tools/cruft
* Copy-based reuse. https://api.crossref.org/works/10.1145%2F3715907
* YAML Norway problem. https://bram.us/2022/01/11/yaml-the-norway-problem
* "You're absolutely right". https://www.theregister.com/2025/08/13/claude_codes_copious_coddling_confounds/
* Slopsquatting. https://www.theregister.com/2025/04/12/ai_code_suggestions_sabotage_supply_chain/
* SRE Book 70% figure. https://oreilly.com/ideas/tenets-of-sre

Working copies: PDFs and `pdftotext` extracts are in
`/tmp/claude-0/-home-user/45025f40-9ecc-5a8d-8a7b-43b8aba40a7d/scratchpad/pdf/`
(session scratch; may be cleared). The durable line-numbered quote extract is
`/home/user/estate/.findings/ext-pain-evidence.txt`.
