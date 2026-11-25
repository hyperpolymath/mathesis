#!/usr/bin/env bash
# per repo: classify each HEAD non-merge commit by the set of paths it touches (names only; no blobs)
r="$1"
git -C "/home/user/estate/$r" log HEAD --no-merges --no-renames --name-only --format='@@%H' 2>/dev/null | awk -v repo="$r" '
function flush() { if (h!="") { print repo "\t" n "\t" wf "\t" docs "\t" lock "\t" meta "\t" other } }
/^@@/ { flush(); h=substr($0,3); n=0; wf=0; docs=0; lock=0; meta=0; other=0; next }
NF==0 { next }
{ n++;
  if ($0 ~ /^\.github\/workflows\//) { if ($0 ~ /actions\.lock$/) lock++; else wf++ }
  else if ($0 ~ /\.(adoc|md|txt)$/ || $0 ~ /^docs\//) docs++
  else if ($0 ~ /^\.machine_readable\// || $0 ~ /_chora\.deed$/ || $0 ~ /\.a2ml$/ || $0 ~ /^\.github\// || $0 ~ /^LICENSES?\// || $0 ~ /^LICENSE/ ) meta++
  else other++ }
END { flush() }'
