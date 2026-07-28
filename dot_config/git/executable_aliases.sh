#!/usr/bin/env bash
# List git aliases with the comment written above each in the config file.
# `git config` discards comments, so we read the raw file(s).
#   (no args)  human-readable, aligned, coloured on a TTY
#   --pairs    machine-readable "name<TAB>description" for shell completion
set -uo pipefail

mode=${1:-}

lib="$(dirname "$0")/_lib.sh"
# shellcheck source=./_lib.sh
[ -f "$lib" ] && . "$lib" || { echo "aliases: missing $lib" >&2; exit 1; }

mapfile -t files < <(
  git config --show-origin --get-regexp '^alias\.' 2>/dev/null \
    | awk -F'\t' '$1 ~ /^file:/ { f=$1; sub(/^file:/,"",f); if(!seen[f]++) print f }'
)
[ "${#files[@]}" -gt 0 ] || { echo "No aliases found." >&2; exit 0; }

extract() {
  awk '
    function cont(s) { return (s ~ /\\[[:space:]]*$/) }
    FNR==1 { section=""; incont=0; comment="" }
    incont==1 { incont=cont($0); comment=""; next }
    /^[[:space:]]*[#;]/ { c=$0; sub(/^[[:space:]]*[#;][[:space:]]?/,"",c); comment=c; next }
    /^[[:space:]]*\[/ { s=$0; sub(/^[[:space:]]*\[[[:space:]]*/,"",s); sub(/[]" ].*/,"",s); section=tolower(s); comment=""; next }
    section=="alias" && /^[[:space:]]*[A-Za-z][A-Za-z0-9-]*[[:space:]]*=/ {
      name=$0; sub(/^[[:space:]]*/,"",name); sub(/[[:space:]]*=.*/,"",name)
      printf "%s\t%s\n", name, comment; comment=""; incont=cont($0); next
    }
    { comment=""; incont=cont($0) }
  ' "${files[@]}" | sort
}

if [ "$mode" = --pairs ]; then
  extract
  exit 0
fi

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  name_colour=$cyn; reset=$rst
else
  name_colour=""; reset=""
fi

extract | {
  if command -v column >/dev/null 2>&1; then column -t -s $'\t'
  else awk -F'\t' '{ printf "%-20s %s\n", $1, $2 }'; fi
} | awk -v c="$name_colour" -v r="$reset" '{ rest=$0; sub(/^[^ ]+/,"",rest); printf "%s%s%s%s\n", c, $1, r, rest }'