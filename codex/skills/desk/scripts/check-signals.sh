#!/usr/bin/env bash
# check-signals.sh — obsidian-git post-commit hook から呼ばれる
# 変更されたタスクノートに `input:: done` が含まれていれば signal file を生成し通知する
#
# Usage: check-signals.sh <vault_root>
# Environment: DESK_SIGNALS_DIR (default: <vault_root>/.desk/signals)

set -euo pipefail

VAULT_ROOT="${1:?Usage: check-signals.sh <vault_root>}"
SIGNALS_DIR="${DESK_SIGNALS_DIR:-${VAULT_ROOT}/.desk/signals}"

mkdir -p "$SIGNALS_DIR"

# 直近コミットで変更された .md ファイルを取得
changed_files=$(git -C "$VAULT_ROOT" diff-tree --no-commit-id --name-only -r HEAD -- '*.md' 2>/dev/null || true)

if [[ -z "$changed_files" ]]; then
  exit 0
fi

while IFS= read -r file; do
  filepath="${VAULT_ROOT}/${file}"
  [[ -f "$filepath" ]] || continue

  # frontmatter に status: human_response_required が含まれるか確認
  if ! grep -q 'status:.*human_response_required\|status:.*planning' "$filepath" 2>/dev/null; then
    continue
  fi

  # input:: done が新たに含まれるか確認（直近の diff で追加された行）
  diff_output=$(git -C "$VAULT_ROOT" diff HEAD~1 HEAD -- "$file" 2>/dev/null || true)
  if echo "$diff_output" | grep -q '^+.*input::.*done'; then
    task_name=$(basename "$file" .md)
    signal_file="${SIGNALS_DIR}/${task_name}.ready"

    if [[ ! -f "$signal_file" ]]; then
      echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$signal_file"

      # terminal-notifier で通知
      if command -v terminal-notifier &>/dev/null; then
        encoded_file=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "${file%.md}")
        vault_name=$(basename "$VAULT_ROOT")
        terminal-notifier \
          -title "desk: ${task_name}" \
          -message "Input received — ready to resume" \
          -open "obsidian://open?vault=${vault_name}&file=${encoded_file}"
      fi
    fi
  fi
done <<< "$changed_files"
