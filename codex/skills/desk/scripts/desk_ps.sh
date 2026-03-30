#!/usr/bin/env bash
# desk_ps.sh — Show desk-managed task status with liveness checks
#
# Usage: desk_ps.sh <vault_root> [--all|--inactive]
#
# Scans *.md at vault root for desk frontmatter, cross-references
# .desk/runtime/*.lock for PID liveness, and prints a table.

set -euo pipefail

VAULT_ROOT="${1:-$(pwd)}"
FLAG="${2:-}"
RUNTIME_DIR="${VAULT_ROOT}/.desk/runtime"
HEARTBEAT_THRESHOLD_SEC=900  # 15 minutes
now_epoch=$(date +%s)

# Print header
printf "%-35s | %-25s | %-11s | %-9s | %s\n" "task" "status" "agent" "heartbeat" "alive?"
printf "%-35s-+-%-25s-+-%-11s-+-%-9s-+-%s\n" "-----------------------------------" "-------------------------" "-----------" "---------" "------"

# Scan task notes — use grep -l to pre-filter (fast on large vaults)
grep -l '^status:' "${VAULT_ROOT}"/*.md 2>/dev/null | while IFS= read -r note; do
  [[ -f "$note" ]] || continue

  # Extract frontmatter fields (simple grep, no YAML parser needed)
  task_status=$(grep -m1 '^status:' "$note" | sed 's/^status:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/' || true)
  [[ -z "$task_status" ]] && continue

  # Filter based on flag
  case "$FLAG" in
    --all) ;;
    --inactive)
      case "$task_status" in
        plan_ready|planning|in_progress|human_response_required|in_review) ;;
        *) continue ;;
      esac
      ;;
    *)
      [[ "$task_status" == "done" || "$task_status" == "not_started" ]] && continue
      ;;
  esac

  task_name=$(basename "$note" .md)
  runtime_status=$(grep -m1 '^runtime_status:' "$note" 2>/dev/null | sed 's/^runtime_status:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/' || true)
  subagent_id=$(grep -m1 '^runtime_subagent_id:' "$note" 2>/dev/null | sed 's/^runtime_subagent_id:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/' || true)
  heartbeat=$(grep -m1 '^runtime_heartbeat_at:' "$note" 2>/dev/null | sed 's/^runtime_heartbeat_at:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/' || true)

  # Compute heartbeat age
  heartbeat_display="—"
  if [[ -n "$heartbeat" ]]; then
    hb_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$heartbeat" +%s 2>/dev/null || echo 0)
    if (( hb_epoch > 0 )); then
      age=$(( now_epoch - hb_epoch ))
      if (( age < 60 )); then
        heartbeat_display="${age}s"
      elif (( age < 3600 )); then
        heartbeat_display="$(( age / 60 ))m"
      else
        heartbeat_display="$(( age / 3600 ))h"
      fi
    fi
  fi

  # Check lock file + PID liveness
  lock_file="${RUNTIME_DIR}/${task_name}.lock"
  agent_display="—"
  alive_display="—"

  if [[ -n "$subagent_id" && "$subagent_id" != '""' ]]; then
    agent_display="$subagent_id"
  fi

  if [[ -f "$lock_file" ]]; then
    pid=$(grep '^pid=' "$lock_file" 2>/dev/null | cut -d= -f2)
    if [[ -n "$pid" ]]; then
      agent_display="pid:${pid}"
      if kill -0 "$pid" 2>/dev/null; then
        alive_display="✓"
        # Check heartbeat staleness
        if [[ -n "$heartbeat" ]]; then
          hb_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$heartbeat" +%s 2>/dev/null || echo 0)
          if (( hb_epoch > 0 && (now_epoch - hb_epoch) > HEARTBEAT_THRESHOLD_SEC )); then
            alive_display="? hung"
          fi
        fi
      else
        alive_display="✗ stale"
      fi
    fi
  fi

  # Inactive filter
  if [[ "$FLAG" == "--inactive" ]]; then
    case "$runtime_status" in
      ""|idle|stale) ;;
      *) [[ "$alive_display" != "✗ stale" ]] && continue ;;
    esac
  fi

  # Truncate task name
  display_name="$task_name"
  if (( ${#display_name} > 35 )); then
    display_name="${display_name:0:32}..."
  fi

  printf "%-35s | %-25s | %-11s | %-9s | %s\n" "$display_name" "$task_status" "$agent_display" "$heartbeat_display" "$alive_display"
done
