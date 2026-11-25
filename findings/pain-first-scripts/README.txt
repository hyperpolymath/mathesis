Pain-first candidate generation: read-only pilot measurements, run 2026-11-24 over /home/user/estate (484 clones).
Nothing in any clone was edited. Scratch outputs are under /tmp/pf/. Tools fetched into /tmp only: mikefarah yq
v4.44.3 (/tmp/pf/bin/yq) and the libgmp-dev header (/tmp/pf/gmp), both needed to build and feed the proven-lock judge.

script                                    what it measures                                         result (this run)
p1_template_ancestor_identity.sh          child files byte-identical to template HEAD / an older    442 template paths in >=25 children, 45,854 instances:
                                          template version / no version (tree objects only)         14,711 HEAD, 12,582 older version, 18,561 none;
                                                                                                    workflow paths only (38 paths, 6,300): 470 / 1,512 / 4,318
p2_workflow_closed_schema.rb              workflows inhabiting a closed sum-type schema             8,005 files: 7,964 inhabit, 30 rejected, 5 do not parse,
                                                                                                    6 not a mapping (first run rejected 61: 31 used scope vulnerability-alerts,
                                                                                                    admitted to the enum afterwards; not verified against GitHub)
p3_estate_ref_resolver.sh                 sort-aware closed-world resolver for estate `uses:` refs  2,387 forty-hex estate refs: 2,149 commit, 15 BLOB ids
                                                                                                    (wrong sort), 1 names nothing, 222 to repos not cloned;
                                                                                                    1,452 written under the pre-move owner; 865 tag-name refs
                                                                                                    and 16,313 third-party refs undecided offline
p4_gate_falsifiability_census.sh          canon detector for `| grep -q`; gate scripts with a test  7,818 findings in 385 repos; 1,204 scripts/check-*.sh in
                                                                                                    164 repos, 428 named by no test file
p5_required_context_producibility.rb      required contexts in checked-in rulesets vs producers     6 repos, 17 contexts: 1 no producer, 3 if-skippable
                                          (thin offline data; live branch protection not in clones)
p5b_cigate_profile_producibility.rb      required {job, workflow} identities in the 17 shipped      258 identities: all workflow files present; 251 have a job
                                          ci-gate profiles vs the target repos at HEAD              of the required name; 7 do not (5 are matrix-expanded names
                                                                                                    the probe does not expand); 3 producers carry a job-level if:
p6_lock_judge_differential.sh             proved lock judge vs shell checkers, every actions.lock   329 repos: judge 168 CONSISTENT / 160 INCONSISTENT / 1 NOT_RUN;
                                                                                                    template script 120 pass / 209 fail; 58 disagreements;
                                                                                                    90 repos with a closure defect; own copies (80): 22 disagree
p8_claim_without_prover.sh                README verification claims vs receipts / prover in CI     101 claiming repos; 5 have a receipt deed (8 repos overall);
                                                                                                    33 have neither a prover-running workflow nor a receipt
p9_sweep_rollout_shape.sh                 how fast a sweep reaches the fleet                        410 sweeps (>=20 repos): 303 reach >=50% of their repos within
                                                                                                    1 h; 29,840 of 33,368 landings within 24 h of the first
p10_licence_carrier_agreement.sh          FLAG-ONLY: do licence carriers in one repo agree          471 repos with >=2 carriers: 442 agree, 29 differ by family
                                                                                                    (not adjudicated; includes the intended code/prose split)
p11_retired_claims_in_instructions.sh     retired canon sentences still in agent-instruction files  740 files / 339 repos: legacy descriptile .a2ml named in 281
                                                                                                    files (232 repos); old canon owner 98; gv-clade-index 73
p12_dual_carrier_accounting.sh            legacy .a2ml descriptile + deed clause both present       18 of 78 chora-deed repos; 59 pairs
p13_commit_support_classes.pl             commits by touched support (input: /tmp/ct/names.txt)     76,767 commits: 47,625 touch no code/other path
p14_both_sides_modified.sh                files modified on both sides of historical merges         4,211 merges, 1,249 contested, 9,098 file instances:
                                                                                                    2,301 workflow YAML, 1,916 other structured, 139 lockfiles,
                                                                                                    2,031 prose, 2,537 code/other
p15_template_stub_proof_surface.pl        proof-language files that are template copies             6,907 files in 285 repos: 1,011 template copies; 45 repos
                                                                                                    have only template copies (mathesis census already excludes)
Also run, not scripted here: proven-cicd-and-workflows tests/ci-gate.sh on a /tmp copy: 646 passed, 0 failed;
tests/pass-on-absence.sh: 173 passed, 10 failed, all ten in the proof-runner section with exit 127 (a command
missing from this container's stripped PATH; an environment artefact, not assessed further).
Two self-inflicted errors found and fixed while running: p4 first ended with exit 141 (`sort | head` under
pipefail, the very SIGPIPE class it counts); p10 first matched "palimpsest" inside a licence URL (26 false hits);
p13 first summed "only: code/other" into the non-code total; p15 first presented template copies as census
inflation before I read mathesis scripts/census/build-rows.sh, which already drops them.
