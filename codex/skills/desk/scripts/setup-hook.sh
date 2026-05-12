#!/usr/bin/env bash
# setup-hook.sh — vault に desk signal generation hook を登録する
#   post-commit hook (check-signals.sh) — signal generation
#
# Usage: setup-hook.sh <vault_root>
# Exit codes: 0=installed or already present, 1=error, 2=skipped by user

set -euo pipefail

VAULT_ROOT="${1:?Usage: setup-hook.sh <vault_root>}"
HOOK_DIR="${VAULT_ROOT}/.git/hooks"
HOOK_FILE="${HOOK_DIR}/post-commit"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MARKER="# desk:check-signals"

installed_any=false

# ============================================================
# post-commit hook (signal generation)
# ============================================================
if [[ -f "$HOOK_FILE" ]] && grep -qF "$MARKER" "$HOOK_FILE" 2>/dev/null; then
  echo "post-commit hook already contains check-signals.sh — skipping."
else
  SNIPPET="${MARKER}
\"${SKILL_DIR}/scripts/check-signals.sh\" \"${VAULT_ROOT}\""

  echo "The following will be added to ${HOOK_FILE}:"
  echo "---"
  echo "$SNIPPET"
  echo "---"
  read -r -p "Install post-commit hook? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    mkdir -p "$HOOK_DIR"
    if [[ ! -f "$HOOK_FILE" ]]; then
      cat > "$HOOK_FILE" <<EOF
#!/usr/bin/env bash
${SNIPPET}
EOF
    else
      printf '\n%s\n' "$SNIPPET" >> "$HOOK_FILE"
    fi
    chmod +x "$HOOK_FILE"
    chmod +x "${SKILL_DIR}/scripts/check-signals.sh"
    echo "Installed check-signals.sh into ${HOOK_FILE}."
    installed_any=true
  else
    echo "Skipped."
  fi
fi

if $installed_any; then
  echo ""
  echo "Signal generation setup complete:"
  echo "  post-commit hook -> generates .desk/signals/*.ready"
fi
