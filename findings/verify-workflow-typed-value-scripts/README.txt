[prior-art-feasibility-effect lens; the files pre_repair_blobs_vs_closed_schema.out and scorecard_wave_sample40.txt in this directory were written by another verifier, not by these scripts]
Adversarial check of candidate "Workflow as a typed value, never text" (prior art / feasibility / effect), 2026-11-24.
Read-only. Scripts refer to /tmp/wfv (scratch: lazily fetched pre/post-repair blobs) and /tmp/ts/mech.tsv (trivial-syntax run).
gate.rb        three layers on one blob: L1 Psych parse, L2 duplicate key, L3 closed sum-type schema (p2 key sets; scopes = GitHub docs list of 2026-11-24)
fetch*.sh      save parent (pre) and commit (post) blobs of workflow files modified by sampled repair commits (14 commits per wave, distinct repos, sorted by hash)
percommit.rb   per-commit verdict: does any pre-repair file get rejected, and by which layer
gate2.rb       same, all modified workflow files, for commits the 4-file sample missed
gate3.rb       same for the two OSSF Scorecard startup_failure waves
shape.rb/runs.rb/head.rb  HEAD census: comments, anchors, run-scalar volume, gate verdicts, permission scopes in use
Results: prerepair_gate.out, head_census.out. Sample sizes are 11-14 commits per wave; treat shares as estimates.
