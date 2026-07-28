#!/usr/bin/env bash
# List git aliases together with the comment written on the line above each
# one in the config file. `git config` discards comments, so we read the raw
# file(s) where the aliases are defined (which also covers included configs).
set -uo pipefail

# Every file that actually defines an alias, de-duplicated, file: origins only.
mapfile -t files < <(
  git config --show-origin --get-regexp '^alias\.' 2>/dev/null \
    | awk -F'\t' '$1 ~ /^file:/ { f=$1; sub(/^file:/,"",f); if(!seen[f]++) print f }'
)
[ "${#files[@]}" -gt 0 ] || { echo "No aliases found." >&2; exit 0; }

# Colour the alias name, but only on a terminal (and unless NO_COLOR is set),
# so piping into grep / a file / a pager stays clean.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  name_colour=$'\033[1;36m'   # bold cyan
  reset=$'\033[0m'
else
  name_colour=""; reset=""
fi

awk '
  FNR==1 { section = "" }                      # reset section per file

  /^[[:space:]]*[#;]/ {                         # comment line -> remember it
    c = $0; sub(/^[[:space:]]*[#;][[:space:]]?/, "", c); comment = c; next
  }
  /^[[:space:]]*\[/ {                           # section header
    s = $0; sub(/^[[:space:]]*\[[[:space:]]*/, "", s); sub(/[]" ].*/, "", s)
    section = tolower(s); comment = ""; next
  }
  section == "alias" && /^[[:space:]]*[A-Za-z][A-Za-z0-9-]*[[:space:]]*=/ {
    name = $0; sub(/^[[:space:]]*/, "", name); sub(/[[:space:]]*=.*/, "", name)
    printf "%s\t%s\n", name, comment; comment = ""; next
  }
  { comment = "" }                              # any other line: drop pending comment
' "${files[@]}" | sort | {
  if command -v column >/dev/null 2>&1; then
    column -t -s $'\t'
  else
    awk -F'\t' '{ printf "%-20s %s\n", $1, $2 }'   # fallback if column is absent
  fi
} | awk -v c="$name_colour" -v r="$reset" '
  { rest = $0; sub(/^[^ ]+/, "", rest);            # split name from padding+desc
    printf "%s%s%s%s\n", c, $1, r, rest }'