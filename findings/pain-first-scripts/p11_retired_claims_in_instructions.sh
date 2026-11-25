#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Read-only probe (2026-11-24). Pain class: policy/instruction drift (the file agents read first lags the ruling).
# A retired claim is a regex for a sentence the canon has since withdrawn (the pattern used by
# trope-particularity-workbench tests/stack-coherence/retired-claims.tsv). Each row below names the superseding
# ruling as recorded in /home/user/standards/.claude/CLAUDE.md. Counts are files still asserting the retired
# sentence among agent-instruction files (CLAUDE.md, GEMINI.md, AGENTS.*, copilot-instructions.md, depth <= 4).
# Regex matching: a file that QUOTES a retired sentence in order to retract it also matches (upper bound).
set -uo pipefail
EST=${EST:-/home/user/estate}; OUT=${OUT:-/tmp/pf/p11}; mkdir -p "$OUT"; cd "$EST"
find . -maxdepth 5 \( -name CLAUDE.md -o -name GEMINI.md -o -name 'AGENTS.md' -o -name 'AGENTS.adoc' -o -name copilot-instructions.md -o -name CLAUDE.adoc \) -not -path '*/node_modules/*' -not -path './.findings/*' 2>/dev/null | sort > "$OUT/files.txt"
echo "agent-instruction files scanned: $(wc -l < "$OUT/files.txt") in $(cut -d/ -f2,3 "$OUT/files.txt" | sort -u | wc -l) repos"
row() { # id  regex  superseded-by
  local n r; n=$(xargs -a "$OUT/files.txt" -d '\n' grep -lEi -- "$2" 2>/dev/null | tee "$OUT/$1.txt" | wc -l); r=$(cut -d/ -f2,3 "$OUT/$1.txt" | sort -u | wc -l)
  printf '%-6s files=%-4s repos=%-4s %s\n        superseded by: %s\n' "$1" "$n" "$r" "$2" "$3"
}
row RC-1 'Bun[^\n]{0,40}(BANNED|banned)|Use Deno instead|Deno[^\n]{0,30}replaces (Node|npm|bun)' 'LANGUAGE-POLICY 1 (Bun > Deno > pnpm > npm), corrected 2026-08-07; Deno permitted again 2026-10-14'
row RC-2 'ReScript[^\n]{0,40}(Primary application code|primary)|\| *\*\*ReScript\*\* *\| *Primary' 'ReScript banned 2026-04-30; AffineScript is the application language'
row RC-3 '(STATE|META|ECOSYSTEM|AGENTIC|NEUROSYM|PLAYBOOK|0-AI-MANIFEST)\.a2ml' 'A2ML retired (D99, D269c, D312, D313); descriptiles are clauses of <repo>_chora.deed'
row RC-4 'hyperpolymath/standards' 'canon moved to metadatastician/standards (rsr-template-repo CLAUDE.md names the new owner)'
row RC-5 'gv-clade-index' 'renamed chora-registry (references to the repository follow the rename; id domains do not)'
row RC-6 'Rust[^\n]{0,20}(always )?means Rust/SPARK|Rust/SPARK' 'withdrawn; Rust uses Creusot/Pearlite and Verus, SPARK belongs to Ada (PROOF-POLICY 1.2)'
row RC-7 'README must be (`)?\.?md|README\.md is required|README must be Markdown' 'README is .adoc by default (2026-06-26 correction)'
row RC-8 'No package\.json[^\n]{0,40}deno\.json' 'package.json + bun.lock REQUIRED (Enforcement Rule 2)'
row RC-9 'hyperpolymath/lith([^a-z-]|$)|lith monorepo' 'owner-disavowed 2026-06-22: hyperpolymath/lith does not exist (kept only as the warning sentence)'
echo "-- doctrine preamble variants: distinct sha256 of the numbered Doctrine block across root CLAUDE.md files"
for f in */*/CLAUDE.md; do awk '/^## Doctrine/{p=1;next} /^## /{p=0} p' "$f" | sha256sum | cut -c1-12; done | sort | uniq -c | sort -rn | awk '{n++; s+=$1; if(NR<=5) print "  "$0} END{print "  root CLAUDE.md files: "s"; distinct Doctrine blocks: "n}'
