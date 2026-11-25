Verifier scripts for the candidate "One verdict kernel for required checks" (prior art / feasibility / effect lens).
g1g2_profile_coverage.pl   perl g1g2_profile_coverage.pl < /tmp/ct/names.txt
  (names.txt = commit-taxonomy-scripts/names.sh over every repo). Recount of G1/G2 commits with the trivial-syntax regexes,
  the workflow files they touch, and whether each file's basename is named by any of the 17 ci-gate profiles.
  Result 2026-11-24: G1 536 commits, 2,858 workflow-file touches, 850 in a profiled basename; G2 477 commits, 528 touches, 368 in.
Synthetic verdict cases (scratch copy of proven-cicd-and-workflows, ijson-jcs profile, scripts/ci-gate-verdict.sh):
  all green -> success; one required job skipped -> failure; required workflow startup_failure with zero jobs -> failure
  "never reported"; required workflow with no run -> failure; no runs at all -> failure;
  NON-profiled workflow (mirror.yml) in startup_failure with required jobs green -> success.
tests/ci-gate.sh on the scratch copy: 646 passed, 0 failed. idris2 was not available, so the Idris kernel was read, not compiled.
