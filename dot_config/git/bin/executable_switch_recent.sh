#!/usr/bin/env bash
# Interactively switch to a recent local branch.
#   - branches listed newest-first; with fzf's default layout the newest sits
#     at the bottom, next to the prompt, with the cursor already on it
#   - relative dates are dimmed; typing filters on the branch name only
#   - the preview pane shows the branch's recent commits
set -uo pipefail

if ! command -v fzf >/dev/null 2>&1; then
  echo "git sw: fzf is not installed (try 'brew install fzf' or your package manager)." >&2
  exit 1
fi

current=$(git branch --show-current 2>/dev/null || true)

dim=$'\033[2m'
reset=$'\033[0m'

# "<dim>relative-date<reset><TAB>branch", newest first, minus the current branch.
list=$(git for-each-ref --sort=-committerdate refs/heads/ \
         --format="${dim}%(committerdate:relative)${reset}%09%(refname:short)" \
       | awk -F'\t' -v cur="$current" '$2 != cur')

[ -n "$list" ] || { echo "git sw: no other local branches." >&2; exit 0; }

sel=$(printf '%s\n' "$list" | fzf \
        --ansi \
        --layout=default \
        --height=40% \
        --prompt='switch to > ' \
        --delimiter='\t' \
        --nth=2 \
        --preview='git log --oneline --color=always -n 15 {2}' \
        --preview-window=right:55%)

# ESC / nothing picked -> do nothing.
[ -n "$sel" ] || exit 0

branch=$(printf '%s' "$sel" | cut -f2)
git switch "$branch"