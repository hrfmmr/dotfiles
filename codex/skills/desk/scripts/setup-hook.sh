#!/usr/bin/env bash
# setup-hook.sh — vault に desk signal chain のフックを登録する
#   1. post-commit hook (check-signals.sh) — signal generation
#   2. Stop Hook (.claude/settings.json / .codex/hooks.json) — signal consumption / auto-resume
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
codex_stop_configured=false

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
# Layer 2a: Claude Code Stop Hook (signal consumption / auto-resume)
# ============================================================
STOP_HOOK_CMD="bash ${SKILL_DIR}/scripts/desk_stop_hook.sh ${VAULT_ROOT}"
CLAUDE_SETTINGS_FILE="${VAULT_ROOT}/.claude/settings.json"
CODEX_HOOKS_FILE="${VAULT_ROOT}/.codex/hooks.json"
CODEX_CONFIG_FILE="${CODEX_HOME:-${HOME}/.codex}/config.toml"

merge_stop_hook_json() {
  local target_file="$1"
  local target_label="$2"
  python3 - "$target_file" "$STOP_HOOK_CMD" "$target_label" <<'PY'
import json
import pathlib
import sys

target = pathlib.Path(sys.argv[1])
command = sys.argv[2]
label = sys.argv[3]

if target.exists():
    data = json.loads(target.read_text())
else:
    data = {}

hooks = data.setdefault("hooks", {})
stop_list = hooks.setdefault("Stop", [])
for group in stop_list:
    for hook in group.get("hooks", []):
        if "desk_stop_hook.sh" in hook.get("command", ""):
            print(f"{label} already present — skipping.")
            sys.exit(0)

stop_list.append(
    {
        "hooks": [
            {
                "type": "command",
                "command": command,
                "timeout": 10,
            }
        ]
    }
)

target.parent.mkdir(parents=True, exist_ok=True)
target.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
print(f"Merged Stop Hook into {target}.")
PY
}

if [[ -f "$CLAUDE_SETTINGS_FILE" ]] && grep -qF "desk_stop_hook.sh" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
  echo "[Layer 2a] Stop Hook already configured in ${CLAUDE_SETTINGS_FILE} — skipping."
else
  echo "[Layer 2a] The following Stop Hook will be added to ${CLAUDE_SETTINGS_FILE}:"
  echo "---"
  echo "  hooks.Stop → ${STOP_HOOK_CMD}"
  echo "---"
  read -r -p "Install Claude Code Stop Hook? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    merge_stop_hook_json "$CLAUDE_SETTINGS_FILE" "Claude Code Stop Hook"
    installed_any=true
  else
    echo "[Layer 2a] Skipped."
  fi
fi

# ============================================================
# Layer 2b: Codex Stop Hook (signal consumption / auto-resume)
# ============================================================
if [[ -f "$CODEX_HOOKS_FILE" ]] && grep -qF "desk_stop_hook.sh" "$CODEX_HOOKS_FILE" 2>/dev/null; then
  echo "[Layer 2b] Stop Hook already configured in ${CODEX_HOOKS_FILE} — skipping."
  codex_stop_configured=true
else
  echo "[Layer 2b] The following Stop Hook will be added to ${CODEX_HOOKS_FILE}:"
  echo "---"
  echo "  hooks.Stop → ${STOP_HOOK_CMD}"
  echo "---"
  read -r -p "Install Codex Stop Hook? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    merge_stop_hook_json "$CODEX_HOOKS_FILE" "Codex Stop Hook"
    installed_any=true
    codex_stop_configured=true
  else
    echo "[Layer 2b] Skipped."
  fi
fi

if $codex_stop_configured; then
  if [[ -f "$CODEX_CONFIG_FILE" ]] && grep -Eq '^[[:space:]]*codex_hooks[[:space:]]*=[[:space:]]*true([[:space:]]|$)' "$CODEX_CONFIG_FILE" 2>/dev/null; then
    :
  else
    echo "[Layer 2b] Note: Codex hooks require a feature flag in ${CODEX_CONFIG_FILE}:"
    echo "  [features]"
    echo "  codex_hooks = true"
  fi
fi

if $installed_any; then
  echo ""
  echo "Signal chain setup complete. Async auto-resume requires:"
  echo "  Layer 1: post-commit hook → generates .desk/signals/*.ready"
  echo "  Layer 2a: Claude Code Stop Hook → consumes signals on root session idle"
  echo "  Layer 2b: Codex Stop Hook → consumes signals on root session idle"
fi
