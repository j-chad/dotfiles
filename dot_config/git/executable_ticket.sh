#!/usr/bin/env bash
# Pick a Jira ticket assigned to you, then create a branch off an up-to-date
# default branch, named <key>-<slug> (e.g. KEK-1599 "Sale date change" ->
# kek-1599-sale-date-change). Offers to reuse an existing branch for the ticket
# and to move the ticket to In Progress.
#   git ticket
# Requires: acli (Atlassian CLI; run `acli jira auth login --web` once) and fzf.
set -uo pipefail

lib="$(dirname "$0")/_lib.sh"
# shellcheck source=./_lib.sh
[ -f "$lib" ] && . "$lib" || { echo "git ticket: missing $lib" >&2; exit 1; }

MAX_SLUG_WORDS=6

for tool in acli fzf; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "git ticket: '$tool' is required (see setup notes)." >&2; exit 1; }
done

# lower-case, non-alphanumerics -> single hyphen, trim leading/trailing hyphens
slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# --- authentication -------------------------------------------------------
if ! acli jira auth status >/dev/null 2>&1; then
  if [ -t 0 ] && [ -t 2 ]; then
    echo "Not authenticated with Jira - starting browser login..." >&2
    acli jira auth login --web || { echo "git ticket: login failed." >&2; exit 1; }
    acli jira auth status >/dev/null 2>&1 || { echo "git ticket: still not authenticated." >&2; exit 1; }
  else
    echo "git ticket: not authenticated. Run:  acli jira auth login --web" >&2
    exit 1
  fi
fi

# --- fetch open tickets as KEY<TAB>SUMMARY<TAB>STATUS ---------------------
# CSV fields are ordered key,status,summary so the only field that can contain a
# comma (summary) is last; key and status are comma-free, so splitting on the
# first two commas is safe. The key-pattern filter also drops the header row.
tmp=$(mktemp)
{
  acli jira workitem search \
    --jql "assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC" \
    --fields "key,status,summary" --csv --limit 100 2>/dev/null \
  | awk '
      { sub(/\r$/, "") }
      {
        c1 = index($0, ","); if (c1 == 0) next
        key = substr($0, 1, c1 - 1)
        if (key ~ /^".*"$/) key = substr(key, 2, length(key) - 2)
        if (key !~ /^[A-Z][A-Z0-9]*-[0-9]+$/) next
        rest = substr($0, c1 + 1)
        c2 = index(rest, ","); if (c2 == 0) next
        st = substr(rest, 1, c2 - 1)
        if (st ~ /^".*"$/) { st = substr(st, 2, length(st) - 2); gsub(/""/, "\"", st) }
        sum = substr(rest, c2 + 1)
        if (sum ~ /^".*"$/) { sum = substr(sum, 2, length(sum) - 2); gsub(/""/, "\"", sum) }
        print key "\t" sum "\t" st
      }' > "$tmp"
} &
fetch_pid=$!
spin "$fetch_pid" "Fetching your tickets..."
wait "$fetch_pid" 2>/dev/null || true
tickets=$(cat "$tmp"); rm -f "$tmp"

[ -n "$tickets" ] || { echo "git ticket: no open tickets assigned to you." >&2; exit 0; }

# --- pick a ticket --------------------------------------------------------
sel=$(printf '%s\n' "$tickets" | fzf \
        --delimiter='\t' --with-nth=1,2 \
        --layout=reverse --height=50% \
        --prompt='ticket > ' \
        --preview='acli jira workitem view {1}' \
        --preview-window=right:55%)
[ -n "$sel" ] || { echo "No ticket selected." >&2; exit 0; }

key=$(printf '%s' "$sel" | cut -f1)
summary=$(printf '%s' "$sel" | cut -f2)
status=$(printf '%s' "$sel" | cut -f3)
key_lc=$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')

# --- reuse an existing branch for this ticket? ----------------------------
existing=()
while IFS= read -r b; do
  [ -n "$b" ] && existing+=("$b")
done < <(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -Ei "^${key_lc}(-|\$)")

if [ "${#existing[@]}" -gt 0 ]; then
  echo "Existing branch(es) for $key:" >&2
  printf '  %s\n' "${existing[@]}" >&2
  read -e -p "[s]witch / [c]ontinue new / [a]bort [s]: " choice || exit 0
  case "${choice:-s}" in
    s|S)
      if [ "${#existing[@]}" -eq 1 ]; then
        target=${existing[0]}
      else
        target=$(printf '%s\n' "${existing[@]}" | fzf --height=30% --prompt='switch to > ')
      fi
      [ -n "$target" ] || { echo "No branch selected." >&2; exit 0; }
      git switch "$target"
      prompt_jira_transition "$key" "In Progress" "$status"
      exit 0 ;;
    c|C) : ;;  # fall through and create a new branch
    *) echo "Aborted." >&2; exit 0 ;;
  esac
fi

# --- description (title-derived placeholder, capped to MAX_SLUG_WORDS) ----
capped=$(printf '%s' "$summary" | awk -v n="$MAX_SLUG_WORDS" '
  { m = (NF > n ? n : NF); out = ""; for (i = 1; i <= m; i++) out = out (i > 1 ? " " : "") $i; print out }')
default_slug=$(slugify "$capped")
read -e -p "Description for $key [$default_slug]: " desc || exit 0
desc=$(slugify "${desc:-$default_slug}")
[ -n "$desc" ] || { echo "git ticket: empty description, aborting." >&2; exit 1; }

branch="${key_lc}-${desc}"

# --- create off an up-to-date default branch (mirrors `git new`) ----------
if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "Branch $branch already exists - switching to it." >&2
  git switch "$branch"
else
  default=$(git symbolic-ref --quiet refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
  if [ -n "$default" ]; then
    git switch "$default" || { echo "git ticket: couldn't switch to $default (uncommitted changes?)." >&2; exit 1; }
    git pull --ff-only  || echo "${ylw}git ticket: couldn't fast-forward $default; branching off local $default.${rst}" >&2
  else
    echo "${ylw}git ticket: origin/HEAD unknown; branching off the current commit.${rst}" >&2
  fi
  git switch -c "$branch"
fi

prompt_jira_transition "$key" "In Progress" "$status"