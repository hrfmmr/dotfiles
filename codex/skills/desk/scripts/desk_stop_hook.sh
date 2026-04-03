#!/usr/bin/env bash
# desk_stop_hook.sh — Claude Code Stop Hook for desk auto-resume
#
# Runs when root session goes idle. Checks for:
#   1. .desk/signals/*.ready (human input completed)
#   2. .desk/runtime/*.lock with dead PID (agent crashed)
#   3. Heartbeat staleness > 15 min (agent hung, notify only)
#
# Returns JSON: {"decision":"block","reason":"..."} or {"decision":"approve"}
# Execution target: <1 second (no fswatch wait)
#
# Usage: desk_stop_hook.sh <vault_root>
# Install in .claude/settings.json:
#   hooks.Stop[0].hooks[0].command = "bash <path>/desk_stop_hook.sh <vault>"

set -euo pipefail

VAULT_ROOT="${1:-$(pwd)}"
SIGNALS_DIR="${VAULT_ROOT}/.desk/signals"
RUNTIME_DIR="${VAULT_ROOT}/.desk/runtime"
HEARTBEAT_THRESHOLD_SEC=900  # 15 minutes

# --- Path 1: Check for ready signals (human input completed) ---
ready_file=$(find "$SIGNALS_DIR" -name '*.ready' -type f 2>/dev/null | sort | head -1)
if [[ -n "$ready_file" ]]; then
  task_name=$(basename "$ready_file" .ready)

  # Dedup: skip if agent is already running for this task
  lock_file="${RUNTIME_DIR}/${task_name}.lock"
  if [[ -f "$lock_file" ]]; then
    pid=$(grep '^pid=' "$lock_file" 2>/dev/null | cut -d= -f2)
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      # Agent already running, skip
      echo '{"decision":"approve"}'
      exit 0
    fi
  fi

  echo "{\"decision\":\"block\",\"reason\":\"desk signal: ${task_name} has input ready. Run: \$desk run ${task_name}\"}"
  exit 0
fi

# --- Path 2: Check for dead locks (agent crashed) ---
for lock_file in "${RUNTIME_DIR}"/*.lock; do
  [[ -f "$lock_file" ]] || continue
  pid=$(grep '^pid=' "$lock_file" 2>/dev/null | cut -d= -f2)
  if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
    task_name=$(basename "$lock_file" .lock)
    echo "{\"decision\":\"block\",\"reason\":\"desk stale: ${task_name} agent (pid:${pid}) is dead. Run: \$desk run ${task_name} --force\"}"
    exit 0
  fi
done

# --- Path 3: Heartbeat staleness check (notify only, no block) ---
now_epoch=$(date +%s)
for lock_file in "${RUNTIME_DIR}"/*.lock; do
  [[ -f "$lock_file" ]] || continue
  pid=$(grep '^pid=' "$lock_file" 2>/dev/null | cut -d= -f2)
  started_at=$(grep '^started_at=' "$lock_file" 2>/dev/null | cut -d= -f2)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && [[ -n "$started_at" ]]; then
    started_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s 2>/dev/null || echo 0)
    elapsed=$(( now_epoch - started_epoch ))
    if (( elapsed > HEARTBEAT_THRESHOLD_SEC )); then
      task_name=$(basename "$lock_file" .lock)
      if command -v terminal-notifier &>/dev/null; then
        vault_name=$(basename "$VAULT_ROOT")
        encoded_file=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$task_name" 2>/dev/null || python3 -c "import urllib.parse; print(urllib.parse.quote('''${task_name}''', safe=''))" 2>/dev/null || echo "$task_name")
        terminal-notifier \
          -title "desk: ${task_name}" \
          -message "Agent (pid:${pid}) no heartbeat for ${elapsed}s. Consider: \$desk run ${task_name} --force" \
          -open "obsidian://open?vault=${vault_name}&file=${encoded_file}" &>/dev/null || true
      fi
    fi
  fi
done

# --- Nothing found ---
echo '{"decision":"approve"}'
