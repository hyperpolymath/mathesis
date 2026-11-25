#!/bin/bash
repo="$1"; d=/home/user/estate/$repo
git -C "$d" log HEAD --no-merges --no-renames --name-only --format='@@%x09%H%x09%an%x09%s' 2>/dev/null | sed "s#^@@#@@\t$repo#"
