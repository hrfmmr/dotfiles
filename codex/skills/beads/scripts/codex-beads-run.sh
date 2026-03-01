#!/usr/bin/env bash
set -euo pipefail
# Codex wrapper: preload beads context then run codex
bd prime >/dev/null || true
exec codex "$@"
