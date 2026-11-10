# SPDX-License-Identifier: MPL-2.0
# Report top-level Idris2 type signatures that have no clauses in the same
# file. Idris2 accepts such a declaration and treats it as a postulate, even
# under %default total. Input: a comment-blanked .idr file. A signature that
# follows a %foreign / %extern pragma (possibly with continuation lines and
# modifier lines in between) is an FFI boundary and is not reported.
function kw(n) { return n ~ /^(data|record|interface|implementation|module|import|namespace|parameters|mutual|total|partial|covering|public|export|private|infix|infixl|infixr|prefix|failing|using|where|let|in|do|if|then|else|case|of|with|rewrite|auto|default)$/ }
/^[ \t]*$/ { next }
/^%(foreign|extern)/ { ffi = 1; next }
/^[ \t]/ { next }                                   # continuation / nested
/^((public[ \t]+)?export|private|covering|total|partial)[ \t]*$/ { next }
{
  s = $0
  sub(/^(public[ \t]+)?export[ \t]+/, "", s); sub(/^private[ \t]+/, "", s)
  sub(/^(covering|total|partial)[ \t]+/, "", s)
  sub(/^[01][ \t]+/, "", s)
  if (match(s, /^[A-Za-z_][A-Za-z0-9_']*[ \t]*:/) && substr(s, RLENGTH + 1, 1) != ":") {
    n = s; sub(/[ \t]*:.*/, "", n)
    if (!kw(n) && !ffi) sig[n] = NR
  } else if (match($0, /^[A-Za-z_][A-Za-z0-9_']*/)) {
    def[substr($0, 1, RLENGTH)] = 1
  }
  t = $0  # infix clause: a `name` b = ...
  while (match(t, /`[A-Za-z_][A-Za-z0-9_']*`/)) { def[substr(t, RSTART + 1, RLENGTH - 2)] = 1; t = substr(t, RSTART + RLENGTH) }
  ffi = 0
}
END { for (n in sig) if (!(n in def)) print sig[n] "\t" n }
