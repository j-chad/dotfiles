#!/usr/bin/env bash
# Invoked by:  git pr   (see [alias] pr in ~/.gitconfig)
# Pushes the current branch, then opens a PR whose title is formatted from the
# branch name and whose body has the Jira placeholder filled in.
#   Branch  abc-1234-my-change
#     title  [ABC-1234] My change
#     body   ABC-XXX in the PR template -> ABC-1234  (link text and URL)
# Extra arguments are forwarded to `gh pr create`.
set -uo pipefail

branch=$(git branch --show-current)
[ -n "$branch" ] || { echo "pr: not on a branch" >&2; exit 1; }

git push -u origin HEAD || exit 1

# [ABC-1234] My change
title=$(printf '%s' "$branch" | perl -pe \
  's/^([a-zA-Z]+)-(\d+)-(.*)$/my($p,$n,$d)=($1,$2,$3);$d=~tr|-| |;"[".uc($p)."-".$n."] ".ucfirst($d)/e')

# ABC-1234  (empty if the branch does not match)
ticket=$(printf '%s' "$branch" | perl -ne 'print uc($1)."-".$2 if /^([a-zA-Z]+)-(\d+)-/')

args=(--web)
if [ "$title" != "$branch" ]; then
  args+=(--title "$title")
fi

# Fill the ticket placeholder in the repo's PR template, if there is one.
root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$root" ] && [ -n "$ticket" ]; then
  for t in \
    "$root/.github/pull_request_template.md" \
    "$root/.github/PULL_REQUEST_TEMPLATE.md" \
    "$root/pull_request_template.md" \
    "$root/PULL_REQUEST_TEMPLATE.md" \
    "$root/docs/pull_request_template.md" \
    "$root/docs/PULL_REQUEST_TEMPLATE.md"; do
    if [ -f "$t" ]; then
      body=$(perl -pe "s/[A-Z][A-Z0-9]*-X{2,}\b/$ticket/g" "$t")
      args+=(--body "$body")
      break
    fi
  done
fi

gh pr create "${args[@]}" "$@"