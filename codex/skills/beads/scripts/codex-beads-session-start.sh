#!/usr/bin/env bash
set -euo pipefail
# Pull if a Dolt remote is configured; ignore if not configured.
bd dolt pull || true
bd prime
bd ready --json
