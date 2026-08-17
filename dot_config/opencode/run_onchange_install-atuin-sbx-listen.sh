#!/bin/sh
# Installs/updates the atuin-sbx-listen host binary, which replays sandbox
# bash history events into the local atuin daemon (see
# .opencode/plans/atuin-sbx-mixin-host.md). Pinned version below; bumping it
# changes this script's content hash, which is what makes chezmoi's
# run_onchange_ re-run it.
set -eu

readonly VERSION="host/atuin-listen/v1.0.0"

command -v go >/dev/null 2>&1 || { echo "no go, skipping atuin-sbx-listen install" >&2; exit 0; }

go install "gitlab.com/j-chad/sbx/host/atuin-listen/cmd/atuin-sbx-listen@${VERSION}"
echo "installed atuin-sbx-listen@${VERSION}"
