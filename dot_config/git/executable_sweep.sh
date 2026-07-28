#!/usr/bin/env bash
# Delete local branches whose GitHub PR has been merged or closed, and
# (optionally) old branches that have no PR at all.
#
#   git sweep               # merged/closed PR branches, then confirm
#   git sweep -n            # dry run: list only
#   git sweep -y            # skip the confirmation prompt
#   git sweep --stale       # also offer no-PR branches older than 90 days
#   git sweep --stale=30    # ...older than 30 days
set -uo pipefail

command -v gh >/dev/null 2>&1 || {
  echo "git sweep: gh (GitHub CLI) is required." >&2; exit 1; }

dry_run=0; assume_yes=0; want_stale=0; stale_days=90
for a in "$@"; do
  case "$a" in
    -n|--dry-run) dry_run=1 ;;
    -y|--yes)     assume_yes=1 ;;
    --stale)      want_stale=1 ;;
    --stale=*)    want_stale=1; stale_days=${a#--stale=} ;;
    -h|--help)    echo "usage: git sweep [-n|--dry-run] [-y|--yes] [--stale[=DAYS]]"; exit 0 ;;
    *) echo "git sweep: unknown option '$a'" >&2; exit 2 ;;
  esac
done
case "$stale_days" in *[!0-9]*|"") echo "git sweep: --stale needs a number of days" >&2; exit 2 ;; esac

current=$(git branch --show-current 2>/dev/null || true)
default=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null \
          | sed 's@^refs/remotes/origin/@@')

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  grn=$'\033[32m'; red=$'\033[31m'; ylw=$'\033[33m'; dim=$'\033[2m'; rst=$'\033[0m'
else
  grn=""; red=""; ylw=""; dim=""; rst=""
fi

# Collect branches (name<TAB>unix-committerdate), newest first, minus current/default.
branches=()
while IFS=$'\t' read -r br ts; do
  [ -n "$br" ] || continue
  [ "$br" = "$current" ] && continue
  [ "$br" = "$default"  ] && continue
  branches+=("$br"$'\t'"$ts")
done < <(git for-each-ref --sort=-committerdate refs/heads/ \
           --format='%(refname:short)%09%(committerdate:unix)')

total=${#branches[@]}
[ "$total" -gt 0 ] || { echo "No other local branches to check." >&2; exit 0; }

[ -t 2 ] || echo "Checking PR status of $total branch(es)..." >&2

now=$(date +%s); stale_secs=$(( stale_days * 86400 ))
pr_rows=()        # branch<TAB>STATE<TAB>number<TAB>title   (MERGED/CLOSED)
stale_rows=()     # branch<TAB>age-in-days                  (no PR, old)
no_pr=0; i=0
for entry in "${branches[@]}"; do
  IFS=$'\t' read -r br ts <<<"$entry"
  i=$((i+1))
  [ -t 2 ] && printf '\r\033[K[%d/%d] %s' "$i" "$total" "$br" >&2
  if info=$(gh pr view "$br" --json state,number,title \
              --jq '[.state,(.number|tostring),.title]|@tsv' 2>/dev/null); then
    IFS=$'\t' read -r state number title <<<"$info"
    case "$state" in
      MERGED|CLOSED) pr_rows+=("$br"$'\t'"$state"$'\t'"$number"$'\t'"$title") ;;
    esac
  else
    if [ "$want_stale" -eq 1 ] && [ -n "$ts" ] && [ "$(( now - ts ))" -gt "$stale_secs" ]; then
      stale_rows+=("$br"$'\t'"$(( (now - ts) / 86400 ))")
    else
      no_pr=$(( no_pr + 1 ))
    fi
  fi
done
[ -t 2 ] && printf '\r\033[K' >&2   # wipe the progress line

if [ "${#pr_rows[@]}" -eq 0 ] && [ "${#stale_rows[@]}" -eq 0 ]; then
  echo "Nothing to prune." >&2
  [ "$want_stale" -eq 0 ] && [ "$no_pr" -gt 0 ] && \
    echo "($no_pr branch(es) have no PR; re-run with --stale to include old ones.)" >&2
  exit 0
fi

to_delete=()
if [ "${#pr_rows[@]}" -gt 0 ]; then
  echo "Branches with merged/closed PRs:" >&2
  for row in "${pr_rows[@]}"; do
    IFS=$'\t' read -r br state number title <<<"$row"
    [ "$state" = "MERGED" ] && c=$grn || c=$red
    printf '  %-30s %s%-7s%s %s#%s %s%s\n' \
      "$br" "$c" "$state" "$rst" "$dim" "$number" "$title" "$rst" >&2
    to_delete+=("$br")
  done
fi
if [ "${#stale_rows[@]}" -gt 0 ]; then
  echo "Stale branches with no PR (older than ${stale_days} days):" >&2
  for row in "${stale_rows[@]}"; do
    IFS=$'\t' read -r br age <<<"$row"
    printf '  %-30s %sSTALE%s   %slast commit %sd ago%s\n' \
      "$br" "$ylw" "$rst" "$dim" "$age" "$rst" >&2
    to_delete+=("$br")
  done
fi
[ "$want_stale" -eq 0 ] && [ "$no_pr" -gt 0 ] && \
  echo "($no_pr more branch(es) have no PR; add --stale to include old ones.)" >&2

if [ "$dry_run" -eq 1 ]; then
  echo "(dry run — nothing deleted)" >&2
  exit 0
fi

if [ "$assume_yes" -ne 1 ]; then
  printf 'Delete these %d branch(es)? [y/N] ' "${#to_delete[@]}" >&2
  read -r reply || reply=""
  case "$reply" in y|Y|yes|YES) ;; *) echo "Aborted." >&2; exit 0 ;; esac
fi

for br in "${to_delete[@]}"; do
  git branch -D "$br"
done