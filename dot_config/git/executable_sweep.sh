#!/usr/bin/env bash
# Delete local branches whose GitHub PR has been merged or closed.
# Asks GitHub (via gh) for each branch's PR state, so it is accurate even for
# squash/rebase merges that git itself doesn't recognise as "merged".
#
#   git sweep            # show merged/closed branches, then confirm deletion
#   git sweep -n         # dry run: only list what would be deleted
#   git sweep -y         # delete without the confirmation prompt
set -uo pipefail

command -v gh >/dev/null 2>&1 || {
  echo "git sweep: gh (GitHub CLI) is required." >&2; exit 1; }

dry_run=0; assume_yes=0
for a in "$@"; do
  case "$a" in
    -n|--dry-run) dry_run=1 ;;
    -y|--yes)     assume_yes=1 ;;
    -h|--help)    echo "usage: git sweep [-n|--dry-run] [-y|--yes]"; exit 0 ;;
    *) echo "git sweep: unknown option '$a'" >&2; exit 2 ;;
  esac
done

current=$(git branch --show-current 2>/dev/null || true)
default=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null \
          | sed 's@^refs/remotes/origin/@@')

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  grn=$'\033[32m'; red=$'\033[31m'; dim=$'\033[2m'; rst=$'\033[0m'
else
  grn=""; red=""; dim=""; rst=""
fi

echo "Checking PR status of local branches..." >&2

candidates=()   # each entry: "branch<TAB>STATE<TAB>number<TAB>title"
while IFS= read -r br; do
  [ -n "$br" ] || continue
  [ "$br" = "$current" ] && continue          # never the branch we're on
  [ "$br" = "$default" ]  && continue          # never the default branch
  # PR tied to this branch; skip branches with no PR (gh exits non-zero).
  info=$(gh pr view "$br" --json state,number,title \
           --jq '[.state,(.number|tostring),.title]|@tsv' 2>/dev/null) || continue
  IFS=$'\t' read -r state number title <<<"$info"
  case "$state" in
    MERGED|CLOSED) candidates+=("$br"$'\t'"$state"$'\t'"$number"$'\t'"$title") ;;
  esac
done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "Nothing to sweep — no branches with merged or closed PRs." >&2
  exit 0
fi

echo "Branches with merged/closed PRs:" >&2
for row in "${candidates[@]}"; do
  IFS=$'\t' read -r br state number title <<<"$row"
  if [ "$state" = "MERGED" ]; then colour=$grn; else colour=$red; fi
  printf '  %-30s %s%-7s%s %s#%s%s %s%s%s\n' \
    "$br" "$colour" "$state" "$rst" "$dim" "$number" "$rst" "$dim" "$title" "$rst" >&2
done

if [ "$dry_run" -eq 1 ]; then
  echo "(dry run — nothing deleted)" >&2
  exit 0
fi

if [ "$assume_yes" -ne 1 ]; then
  printf 'Delete these %d branch(es)? [y/N] ' "${#candidates[@]}" >&2
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted." >&2; exit 0 ;;
  esac
fi

for row in "${candidates[@]}"; do
  IFS=$'\t' read -r br _ _ _ <<<"$row"
  git branch -D "$br"
done