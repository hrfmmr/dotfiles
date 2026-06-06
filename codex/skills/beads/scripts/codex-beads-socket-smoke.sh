#!/bin/sh
set -eu

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <socket-path> <issue-id>" >&2
  exit 1
fi

SOCKET_PATH="$1"
ISSUE_ID="$2"

export BEADS_DOLT_SERVER_SOCKET="$SOCKET_PATH"
export BEADS_DOLT_AUTO_START=0

bd show "$ISSUE_ID"
bd ready --json >/dev/null
