#!/usr/bin/env bash
# postAttach: drop host credential bridges that VS Code Dev Containers injects on attach.
# Belt-and-braces next to the host user settings:
#   "dev.containers.dockerCredentialHelper": false
#   "dev.containers.gitCredentialHelperConfigLocation": "none"
set -uo pipefail

# Forwarded host ssh-agent sockets.
rm -f /tmp/vscode-ssh-auth-*.sock 2>/dev/null

# Git credential helper pointing back to the host.
git config --global --unset-all credential.helper 2>/dev/null
git config --system --unset-all credential.helper 2>/dev/null

# Docker registry credential helper pointing back to the host (no docker CLI here anyway).
rm -f /usr/local/bin/docker-credential-dev-containers-* 2>/dev/null

echo "isolate: host ssh-agent and git credential bridges removed"
exit 0
