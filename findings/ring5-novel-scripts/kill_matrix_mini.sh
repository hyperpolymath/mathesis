#!/usr/bin/env bash
# Mini kill matrix: 10 planted error tropes x 5 estate gate scripts, on SCRATCH copies of rsr-template-repo under /tmp.
# Nothing in the estate clones is touched. A gate "kills" a mutant when its exit status differs from its clean-copy baseline.
set -u
SRC=/home/user/estate/hyperpolymath/rsr-template-repo
S=/home/user/estate/metadatastician/standards/scripts
W=/tmp/r5/km; rm -rf "$W"; mkdir -p "$W"
fresh() { rm -rf "$W/t"; mkdir -p "$W/t"; cp -r "$SRC/." "$W/t/"; rm -rf "$W/t/.git"; (cd "$W/t" && git init -q . && git add -A >/dev/null 2>&1); }
gates() { ( cd "$W/t"
  bash scripts/check-invisible-characters.sh . "$W/inv.out" >/dev/null 2>&1; a=$(tr "\0" "\n" < "$W/inv.out" | grep -c .)
  bash scripts/check-spdx-headers.sh >/dev/null 2>&1; b=$?
  bash "$S/check-workflow-duplicate-keys.sh" >/dev/null 2>&1; c=$?
  bun scripts/check-action-pinning.js >/dev/null 2>&1; d=$?
  bash scripts/check-lock-sync.sh >/dev/null 2>&1; e=$?
  echo "$a $b $c $d $e" ); }
WF=.github/workflows/mirror.yml
fresh; base=$(gates); echo "gates: 1 invisible-chars (count of flagged files) 2 spdx-headers 3 duplicate-keys 4 action-pinning 5 lock-sync"; echo "baseline (clean copy) exit codes: $base"
run() { name="$1"; fresh; ( cd "$W/t"; eval "$2"; git add -A >/dev/null 2>&1 ); got=$(gates); k=""; i=0; for x in $got; do i=$((i+1)); b=$(echo $base | cut -d' ' -f$i); [ "$x" != "$b" ] && k="$k$i"; done; printf '%-52s exits: %s   killed-by: %s\n' "$name" "$got" "${k:-NONE}"; }
run "m1 NBSP inside README.adoc"                       "printf 'a\xc2\xa0b\n' >> README.adoc"
run "m2 zero-width space inside a workflow"            "printf '# z\xe2\x80\x8bw\n' >> $WF"
run "m3 duplicate key (contents read + write)"         "sed -i '0,/^  contents: read/s//  contents: read\n  contents: write/' $WF"
run "m4 permissions child dedented (schema-dead)"      "sed -i '0,/^  contents: read/s//contents: read/' $WF"
run "m5 timeout-minutes on a reusable-call job"        "f=\$(grep -l '^    uses: ' .github/workflows/*.yml | head -1); sed -i '0,/^    uses: .*/s//&\n    timeout-minutes: 10/' \"\$f\""
run "m6 fabricated 40-hex SHA pin (real prefix)"       "sed -i 's/actions\/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1/actions\/checkout@3d3c42e5aac5ba80deadbeefdeadbeefdeadbeef/' $WF"
run "m7 conflict markers committed into LICENSE"       "printf '<<<<<<< HEAD\nx\n=======\ny\n>>>>>>> abc1234\n' >> LICENSE"
run "m8 SPDX header removed from a workflow"           "sed -i '/SPDX-License-Identifier/d' $WF"
run "m9 npermissions: (uninterpreted \\\\n artefact)"     "sed -i '0,/^permissions:/s//npermissions:/' $WF"
run "m10 action bumped without the lock (half-nucleus)" "sed -i 's/actions\/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1/actions\/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2/' $WF"
