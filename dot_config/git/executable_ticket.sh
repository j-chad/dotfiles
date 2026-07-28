#!/usr/bin/env bash
# Pick a Jira ticket assigned to you, then create a branch named
# <key>-<slug>, e.g. KEK-1599 "Sale date change" -> kek-1599-sale-date-change.
#   git ticket
# Requires: acli (Atlassian CLI; run `acli jira auth login` once) and fzf.
set -uo pipefail

for tool in acli fzf; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "git ticket: '$tool' is required (see setup notes)." >&2; exit 1; }
done

# Make sure we're authenticated with Jira. If not, start the browser login when
# we're interactive; otherwise explain how to log in.
if ! acli jira auth status >/dev/null 2>&1; then
  if [ -t 0 ] && [ -t 2 ]; then
    echo "Not authenticated with Jira — starting browser login..." >&2
    acli jira auth login --web || { echo "git ticket: login failed." >&2; exit 1; }
    acli jira auth status >/dev/null 2>&1 || { echo "git ticket: still not authenticated." >&2; exit 1; }
  else
    echo "git ticket: not authenticated. Run:  acli jira auth login --web" >&2
    exit 1
  fi
fi

# Open tickets assigned to me as KEY<TAB>SUMMARY, fetched in the background so we
# can show a spinner (acli's search can take a second or two).
# acli emits CSV; the key is always the first column and never contains a comma
# or quote, so we split on the first comma and CSV-unquote the summary. Filtering
# on the key pattern also drops the CSV header row.
tmp=$(mktemp)
{
  acli jira workitem search \
    --jql "assignee = currentUser() AND statusCategory != Done" \
    --fields "key,summary" --csv --limit 100 2>/dev/null \
  | awk '
      { sub(/\r$/, "") }                       # strip CR from CSV
      {
        ci = index($0, ","); if (ci == 0) next
        key = substr($0, 1, ci - 1)
        if (key ~ /^".*"$/) key = substr(key, 2, length(key) - 2)
        if (key !~ /^[A-Z][A-Z0-9]*-[0-9]+$/) next   # skip header/junk
        sum = substr($0, ci + 1)
        if (sum ~ /^".*"$/) { sum = substr(sum, 2, length(sum) - 2); gsub(/""/, "\"", sum) }
        print key "\t" sum
      }' > "$tmp"
} &
fetch_pid=$!
if [ -t 2 ]; then
  frames='|/-\'; fi=0
  while kill -0 "$fetch_pid" 2>/dev/null; do
    fi=$(( (fi + 1) % 4 ))
    printf '\r%s Fetching your tickets...' "${frames:$fi:1}" >&2
    sleep 0.1
  done
  printf '\r\033[K' >&2
fi
wait "$fetch_pid" || true
tickets=$(cat "$tmp"); rm -f "$tmp"

[ -n "$tickets" ] || { echo "git ticket: no open tickets assigned to you." >&2; exit 0; }

sel=$(printf '%s\n' "$tickets" | fzf \
        --delimiter='\t' --with-nth=1,2 \
        --layout=reverse --height=50% \
        --prompt='ticket > ' \
        --preview='acli jira workitem view {1}' \
        --preview-window=right:55%)
[ -n "$sel" ] || { echo "No ticket selected." >&2; exit 0; }

key=$(printf '%s' "$sel" | cut -f1)
summary=$(printf '%s' "$sel" | cut -f2)

# lower-case, non-alphanumerics -> single hyphen, trim leading/trailing hyphens
slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

default_slug=$(slugify "$summary")
# Prompt pre-filled with the title-derived slug; edit it down to something short.
read -e -i "$default_slug" -p "Description for $key: " desc || exit 0
desc=$(slugify "$desc")
[ -n "$desc" ] || desc=$default_slug
[ -n "$desc" ] || { echo "git ticket: empty description, aborting." >&2; exit 1; }

branch="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]')-$desc"

if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "Branch $branch already exists — switching to it." >&2
  git switch "$branch"
else
  git switch -c "$branch"
fi