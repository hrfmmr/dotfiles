#!/usr/bin/env bash
# setup-hook.sh — vault の post-commit hook に check-signals.sh を登録する
#
# Usage: setup-hook.sh <vault_root>
# Exit codes: 0=installed or already present, 1=error, 2=skipped by user

set -euo pipefail

VAULT_ROOT="${1:?Usage: setup-hook.sh <vault_root>}"
HOOK_DIR="${VAULT_ROOT}/.git/hooks"
HOOK_FILE="${HOOK_DIR}/post-commit"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MARKER="# desk:check-signals"

# --- Already installed? ---
if [[ -f "$HOOK_FILE" ]] && grep -qF "$MARKER" "$HOOK_FILE" 2>/dev/null; then
  echo "post-commit hook already contains check-signals.sh — skipping."
  exit 0
fi

# --- Show what will be added ---
SNIPPET="${MARKER}
\"${SKILL_DIR}/scripts/check-signals.sh\" \"${VAULT_ROOT}\""

echo "The following will be added to ${HOOK_FILE}:"
echo "---"
echo "$SNIPPET"
echo "---"
read -r -p "Install post-commit hook? [y/N] " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
  echo "Skipped."
  exit 2
fi

# --- Install ---
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
