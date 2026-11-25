Adversarial verification of the candidate "Template sync as a lens over the replayed mint" (2026-11-24). Read-only.
Scratch in /tmp/vl. Inputs: /tmp/ct/classified.tsv (commit-taxonomy dump), tree objects of the 484 clones, and 224
historical template blobs of five workflow paths (lazily fetched into the rsr-template-repo clone's object store).
fan.pl          rebuilds the fan-out fix set (fix/revert-worded, normalised subject in >=8 repos): 204 subjects, 10,114 commits
                (the taxonomy reports 10,095; small normalisation difference, not reconciled).
cls.pl/.out     per commit (9,662 single-parent commits with raw rows, 56,229 file changes), by blob id against the template's
                whole history: 491 commits are pure template-version propagation (old and new blob both template versions);
                6,365 touch only template-named paths but write no template version; 820 touch no template path.
                25,479 of 56,229 file changes are on a path the template ever held.
uni.pl/.out     of 20,875 writes on template paths that are no template version: 8,917 are a blob shared by >=5 repos in the
                same sweep (uniform payload that never was in the template), 8,268 are unique to one repo.
viewmatch.rb    five wrapper names, 1,915 child files, candidate's own view (pins, cron, with-values, standards owner):
                38 HEAD, 129 older version, 85 parsed-equal, 316 view-equal, 1,347 no template view.
viewmatch2.rb   same with permissions: and concurrency: also projected out: 1,230 view-equal, 433 none.
nonecluster.rb  the unmatched files cluster: e.g. governance 102/19/15, mirror 126/20/17 (shapes never in the template).
nearest.rb      dominant child shape vs nearest template version: governance and mirror differ in one leaf
                (/permissions/actions: read), hypatia-scan in the concurrency block.
Not run: the mint replay on the 12 children with (mint-answers) (needs just and nickel; neither is installed here and
fetching the binaries was not permitted), so replay determinism on real children remains untested by this verification.
