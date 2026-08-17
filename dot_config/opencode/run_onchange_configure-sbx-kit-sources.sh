#!/bin/sh
# Allow sbx to load kits from the "oc" kit repo on GitLab, in addition to the
# default Docker Hub source. `kit.allowedSources` replaces the whole list, so
# docker.io/ has to be repeated here rather than just appended.
set -eu

command -v sbx >/dev/null 2>&1 || { echo "no sbx, skipping" >&2; exit 0; }

sbx settings set kit.allowedSources '["docker.io/","gitlab.com/j-chad/"]'
echo "configured sbx kit.allowedSources"
