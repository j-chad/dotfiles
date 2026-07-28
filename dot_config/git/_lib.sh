# Shared helpers for the git-* helper scripts. Source this; do not run it.
#   . "$(dirname "$0")/_lib.sh"

# Colours: populated only when stdout is a terminal and NO_COLOR is unset,
# so redirected / piped output stays clean.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  grn=$'\033[32m'; red=$'\033[31m'; ylw=$'\033[33m'
  cyn=$'\033[1;36m'; dim=$'\033[2m'; rst=$'\033[0m'
else
  grn=""; red=""; ylw=""; cyn=""; dim=""; rst=""
fi

# spin <pid> <message>: animate a spinner on stderr until <pid> exits.
# No-op when stderr isn't a terminal; the caller should still `wait` on <pid>.
spin() {
  local pid=$1 msg=$2 frames='|/-\' i=0
  [ -t 2 ] || return 0
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i + 1) % 4 ))
    printf '\r%s %s' "${frames:$i:1}" "$msg" >&2
    sleep 0.1
  done
  printf '\r\033[K' >&2
}

# prompt_jira_transition <key> <target-status> [current-status]
# Offer to move the Jira ticket <key> to <target-status>. Assumes acli is
# installed -- callers for which acli is optional must check first. No-op when
# the key is empty, or when the ticket is already in <target-status> (when a
# <current-status> is passed). Fails soft if the transition itself errors.
prompt_jira_transition() {
  local k=$1 target=$2 cur=${3:-} yn
  [ -n "$k" ] || return 0
  if [ -n "$cur" ] && \
     [ "$(printf '%s' "$cur" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$target" | tr '[:upper:]' '[:lower:]')" ]; then
    return 0
  fi
  read -e -p "[JIRA] Transition $k to $target? [y/N]: " yn || return 0
  case "$yn" in
    y|Y|yes|YES)
      if acli jira workitem transition --key "$k" --status "$target" --yes >/dev/null 2>&1; then
        echo "${grn}Moved $k to $target.${rst}" >&2
      else
        echo "${ylw}Couldn't transition $k (the workflow may use a different status name).${rst}" >&2
      fi ;;
  esac
}