#!/usr/bin/env bash
# Adapted from https://github.com/tj/git-extras/blob/fd2e03cf55fb1fe12a80558aea117200db232e5f/bin/git-repl
shopt -s extglob

# ---- settings --------------------------------------------------------------
prefix='git'              # leading text in the prompt; '' for none
prompt_character='>'
show_project_name=false   # true to show the repository name
use_local_history=false   # true to keep history in the repo, not $XDG_STATE_HOME
on_enter_command=''       # run this on a bare enter; '' to do nothing

# Colors.  Combine attributes by concatenating ("$bold$blue"), or set one to ''
# to leave that part of the prompt uncolored.
bold=$'\e[1m'      dim=$'\e[2m'       italic=$'\e[3m'    underline=$'\e[4m'
red=$'\e[31m'      green=$'\e[32m'    yellow=$'\e[33m'   blue=$'\e[34m'
magenta=$'\e[35m'  cyan=$'\e[36m'     white=$'\e[37m'    gray=$'\e[90m'
# 256-color and truecolor also work, e.g. orange=$'\e[38;5;208m'

c_prefix="$bold$blue"     # the leading "git"
c_project="$cyan"         # repository name, when show_project_name is true
c_branch="$green"         # (branch)
c_exit_status="$red"      # [1] after a failing command
c_character="$bold"       # the trailing prompt_character
# ----------------------------------------------------------------------------

# Every escape sequence in the prompt has to be wrapped in \001 ... \002
# (RL_PROMPT_START_IGNORE / RL_PROMPT_END_IGNORE) so readline does not count it
# towards the printed width of the prompt.  Without that, editing a long line or
# walking back through history smears the prompt across the terminal.  The
# familiar \[ ... \] spelling only works in PS1, which bash expands itself;
# `read -p` hands its argument straight to readline.  Wrapping happens here so
# the definitions above stay readable.
color_reset=$'\001\e[m\002'
if [[ -n "${NO_COLOR-}" ]] || [ ! -t 1 ]; then
  # Not a terminal, or the user asked for no color: strip it all out.
  c_prefix='' c_project='' c_branch='' c_exit_status='' c_character='' color_reset=''
else
  for _name in c_prefix c_project c_branch c_exit_status c_character; do
    if [[ -n "${!_name}" ]]; then
      printf -v "$_name" '\001%s\002' "${!_name}"
    fi
  done
  unset _name
fi

git version
echo "Type 'ls' to ls files below current directory; '!command' to execute any command or just 'subcommand' to execute any git subcommand; 'quit', 'exit', 'q', ^D, or ^C to exit the git repl."

HISTIGNORE=${HISTIGNORE:-+([[:space:]])}
HISTCONTROL=${HISTCONTROL:-ignoredups}
if [[ "$use_local_history" == true ]]; then
  HISTFILE="$(git rev-parse --show-toplevel)/.git_extras_repl_history"
else
  HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/git_extras_repl_history
fi

# file doesn't exist, is empty, or contains only whitespace
if [[ ! -f "$HISTFILE" ]] || [[ ! -s "$HISTFILE" ]] || ! grep -q '[^[:space:]]' "$HISTFILE"; then
  # `history -r` .... `history -a` are not happy with an empty initial file in bash 3.2.57, which is what MacOS 26 ships with
  echo '!echo welcome to git-repl!' >> "$HISTFILE"
fi
history -r

# The fixed ends of the prompt.  Empty segments are left unwrapped so they
# cannot leave a stray escape sequence where the trim below expects a space.
if test -n "$prefix"; then
  prefix_string="$c_prefix$prefix$color_reset"
else
  prefix_string=""
fi
character_string="$c_character$prompt_character$color_reset"

while true; do
  # Current branch
  cur=$(git symbolic-ref HEAD 2> /dev/null | cut -d/ -f3-)

  # Prompt
  if test -n "$cur"; then
    cur_string=" $c_branch($cur)$color_reset"
  else
    cur_string=""
  fi
  if test -n "$exit_status" && test "$exit_status" -ne 0; then
    es_string=" $c_exit_status[$exit_status]$color_reset"
  else
    es_string=""
  fi
  # Recomputed each time because `!cd elsewhere` can move us to another repo.
  if [[ "$show_project_name" == true ]]; then
    project_name=" $c_project$(basename "$(git rev-parse --show-toplevel)" .git)$color_reset"
  else
    project_name=""
  fi

  prompt_base="$prefix_string$project_name$cur_string$es_string$character_string"
  prompt="${prompt_base##+([[:space:]])} "

  # Use arguments as a command if any are provided.
  if [ $# -ne 0 ]; then
    cmd=$*
    set --
    echo "$prompt" "$cmd" # It is as though you had entered a command.
  else
    # Readline
    read -e -r -p "$prompt" cmd
    # Check for EOF, and end the program if so (handles ^D).
    test $? -ne 0 && break
  fi

  # Add command to history if it is not all whitespace
  if [[ ! "$cmd" =~ ^[[:space:]]*$ ]]; then
    history -s "$cmd"
  fi

  # Built-in commands
  case $cmd in
    ls) cmd=ls-files;;
    "")
      if test -n "$on_enter_command"; then
        cmd="$on_enter_command"
      else
        continue
      fi
      ;;
    quit|exit|q) break;;
  esac

  history -a

  if [[ $cmd == !*  ]]; then
    # shellcheck disable=SC2086
    eval ${cmd:1}
  elif [[ $cmd == git* ]]; then
    # shellcheck disable=SC2086
    eval $cmd
  else
    eval git "$cmd"
  fi
  exit_status=$?
done

echo
