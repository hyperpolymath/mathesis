#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
#
# Regression tests for the declaration comparison in check-publication-boundary.sh.
# Run directly with bash or through www/tests/run-all.sh. Each invocation uses
# an isolated bundle, so negative declarations never touch the repository.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT
REAL_SORT="$(command -v sort)"
WWW="$FIXTURE/www"
CHECKER="$WWW/tests/check-publication-boundary.sh"
DECL="$WWW/schemas/publishable-paths.txt"
mkdir -p "$WWW/schemas" "$WWW/webservers" "$FIXTURE/bin" \
    "$WWW/tests/controls/good-deploy" "$WWW/tests/controls/bad-deploy/tls"
cp "$HERE/check-publication-boundary.sh" "$CHECKER"

# Model punctuation-last collation without requiring a host-installed locale.
# Only an explicit LC_ALL=C selects byte ordering; every other setting reverses
# it. POSIX is deliberately used as the inherited value to keep Bash portable
# on hosts without en_GB.UTF-8. This models sort, not the host's POSIX locale.
cat > "$FIXTURE/bin/sort" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${LC_ALL:-}" = C ]; then
    exec "$PUBLICATION_TEST_REAL_SORT" "$@"
fi
LC_ALL=C exec "$PUBLICATION_TEST_REAL_SORT" -r "$@"
EOF
chmod +x "$FIXTURE/bin/sort"

CANONICAL=$'www/.well-known/\nwww/public/'
REVERSED=$'www/public/\nwww/.well-known/'
ACCEPTED='ok: publishable-paths.txt declares exactly www/public/ + www/.well-known/'
REJECTED='BOUNDARY FAIL: publishable-paths.txt must declare exactly the two publishable categories; found:'
cases=0

fail() {
    echo "FAIL: $*" >&2
    if [ -f "$FIXTURE/output" ]; then cat "$FIXTURE/output" >&2; fi
    exit 1
}

# Calibrate the test double: it must actually produce the differing ordering
# that made the original checker fail, and honour the explicit C override.
for setting in POSIX C; do
    ordered="$(printf '%s\n' "$CANONICAL" | env LC_ALL="$setting" \
        PUBLICATION_TEST_REAL_SORT="$REAL_SORT" "$FIXTURE/bin/sort")"
    if [ "$setting" = C ]; then expected="$CANONICAL"; else expected="$REVERSED"; fi
    [ "$ordered" = "$expected" ] || fail "sort fixture did not model $setting ordering"
done

assert_check() { # label, expected status, expected diagnostic
    local label="$1" expected_status="$2" message="$3" status=0
    "${runner[@]}" bash "$CHECKER" > "$FIXTURE/output" 2>&1 || status=$?
    [ "$status" -eq "$expected_status" ] \
        || fail "$mode: $label: expected exit $expected_status, got $status"
    grep -Fq "$message" "$FIXTURE/output" \
        || fail "$mode: $label: missing declaration diagnostic"
    # Other checker sections must succeed so a declaration rejection cannot
    # pass merely because the isolated bundle was built incorrectly.
    grep -Fxq 'ok: planted good stage accepted' "$FIXTURE/output" \
        || fail "$mode: $label: good-stage fixture failed"
    grep -Fxq 'ok: planted bad stage rejected' "$FIXTURE/output" \
        || fail "$mode: $label: bad-stage fixture failed"
    cases=$((cases + 1))
    echo "ok: $mode: $label"
}

assert_declaration() { # label, expected status; declaration on stdin
    cat > "$DECL"
    local message="$ACCEPTED"
    if [ "$2" -ne 0 ]; then message="$REJECTED"; fi
    assert_check "$1" "$2" "$message"
}

for mode in native-C simulated-collation; do
    if [ "$mode" = native-C ]; then
        runner=(env LC_ALL=C)
    else
        runner=(env LC_ALL=POSIX PATH="$FIXTURE/bin:$PATH" PUBLICATION_TEST_REAL_SORT="$REAL_SORT")
    fi

    assert_declaration 'declared order accepted' 0 <<< "$REVERSED"
    assert_declaration 'C order accepted' 0 <<< "$CANONICAL"
    assert_declaration 'comments and whitespace-only lines ignored' 0 \
        <<< $'# publication paths\n\nwww/public/\n \t\n# metadata\nwww/.well-known/'
    assert_declaration 'no final newline accepted' 0 < <(printf '%s' "$REVERSED")

    assert_declaration 'missing public rejected' 1 <<< 'www/.well-known/'
    assert_declaration 'missing well-known rejected' 1 <<< 'www/public/'
    assert_declaration 'duplicate public rejected' 1 <<< "$CANONICAL"$'\nwww/public/'
    assert_declaration 'duplicate well-known rejected' 1 <<< "$CANONICAL"$'\nwww/.well-known/'
    assert_declaration 'empty declaration rejected' 1 < /dev/null
    assert_declaration 'comment-only declaration rejected' 1 <<< $'# no paths\n\n \t'

    for category in dns tls security_headers webservers profiles schemas tests runbooks; do
        assert_declaration "extra operational category $category rejected" 1 \
            <<< "$CANONICAL"$'\n'"www/$category/"
    done
    assert_declaration 'missing trailing slash rejected' 1 <<< $'www/public\nwww/.well-known/'
    assert_declaration 'inline comment is not a path rejected' 1 <<< $'www/public/ # content\nwww/.well-known/'

    # The webservers directory keeps the boundary applicable when the
    # declaration is missing; this must fail rather than silently skip.
    rm "$DECL"
    assert_check 'missing declaration rejected' 1 'BOUNDARY FAIL: schemas/publishable-paths.txt missing'
done

# LC_ALL must also take precedence when only LANG or LC_COLLATE is inherited.
mode=simulated-LANG
runner=(env -u LC_ALL -u LC_COLLATE LANG=POSIX PATH="$FIXTURE/bin:$PATH" PUBLICATION_TEST_REAL_SORT="$REAL_SORT")
assert_declaration 'LANG ordering overridden' 0 <<< "$REVERSED"
mode=simulated-LC_COLLATE
runner=(env -u LC_ALL LANG=C LC_COLLATE=POSIX PATH="$FIXTURE/bin:$PATH" PUBLICATION_TEST_REAL_SORT="$REAL_SORT")
assert_declaration 'LC_COLLATE ordering overridden' 0 <<< "$REVERSED"

echo "PASS: $cases publication declaration cases"
