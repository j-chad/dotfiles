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