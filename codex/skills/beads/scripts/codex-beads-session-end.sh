#!/usr/bin/env bash
set -euo pipefail
issue_id="${1:-}"
if [[ -n "$issue_id" ]]; then
  bd show "$issue_id" --json || true
fi
# bd sync is deprecated in bd >= 0.56; push only when remote is configured.
bd dolt push || true
