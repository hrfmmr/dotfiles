#!/usr/bin/env bash
# setup-hook.sh — vault に desk signal chain の両フックを登録する
#   1. post-commit hook (check-signals.sh) — signal generation
#   2. Stop Hook (.claude/settings.json) — signal consumption / auto-resume
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
# Layer 1: post-commit hook (signal generation)
# ============================================================
if [[ -f "$HOOK_FILE" ]] && grep -qF "$MARKER" "$HOOK_FILE" 2>/dev/null; then
  echo "[Layer 1] post-commit hook already contains check-signals.sh — skipping."
else
  SNIPPET="${MARKER}
\"${SKILL_DIR}/scripts/check-signals.sh\" \"${VAULT_ROOT}\""

  echo "[Layer 1] The following will be added to ${HOOK_FILE}:"
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
    echo "[Layer 1] Installed check-signals.sh into ${HOOK_FILE}."
    installed_any=true
  else
    echo "[Layer 1] Skipped."
  fi
fi

# ============================================================
# Layer 2: Stop Hook (signal consumption / auto-resume)
# ============================================================
SETTINGS_FILE="${VAULT_ROOT}/.claude/settings.json"
STOP_HOOK_CMD="bash ${SKILL_DIR}/scripts/desk_stop_hook.sh ${VAULT_ROOT}"

if [[ -f "$SETTINGS_FILE" ]] && grep -qF "desk_stop_hook.sh" "$SETTINGS_FILE" 2>/dev/null; then
  echo "[Layer 2] Stop Hook already configured in ${SETTINGS_FILE} — skipping."
else
  echo "[Layer 2] The following Stop Hook will be added to ${SETTINGS_FILE}:"
  echo "---"
  echo "  hooks.Stop → ${STOP_HOOK_CMD}"
  echo "---"
  read -r -p "Install Stop Hook? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    if [[ -f "$SETTINGS_FILE" ]]; then
      # Merge into existing settings.json via python
      python3 -c "
import json, sys
with open(sys.argv[1], 'r') as f:
    data = json.load(f)
hook_entry = {'type': 'command', 'command': sys.argv[2], 'timeout': 10}
hooks = data.setdefault('hooks', {})
stop_list = hooks.setdefault('Stop', [])
# Check if already present
for group in stop_list:
    for h in group.get('hooks', []):
        if 'desk_stop_hook' in h.get('command', ''):
            print('Already present — skipping.')
            sys.exit(0)
stop_list.append({'hooks': [hook_entry]})
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
print('Merged Stop Hook into existing settings.json.')
" "$SETTINGS_FILE" "$STOP_HOOK_CMD"
    else
      cat > "$SETTINGS_FILE" <<EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${STOP_HOOK_CMD}",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
EOF
      echo "Created ${SETTINGS_FILE} with Stop Hook."
    fi
    installed_any=true
  else
    echo "[Layer 2] Skipped."
  fi
fi

if $installed_any; then
  echo ""
  echo "Signal chain setup complete. Both layers are required for async auto-resume:"
  echo "  Layer 1: post-commit hook → generates .desk/signals/*.ready"
  echo "  Layer 2: Stop Hook → consumes signals on root session idle"
fi
