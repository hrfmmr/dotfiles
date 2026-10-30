#!/usr/bin/env bash
# Restart one Claude commander into the same session so it gains the Plannotator Inbox tool
# (tools reach only new sessions), then tell it to switch to the Inbox by commander-brief.md.
# Refuses (exit 3) unless the commander is idle, shows no question UI, and has no human draft
# in its input line. The Inbox project folder comes from inbox-projects.tsv (mayor.sh project).
# usage: switch-to-inbox.sh <agent name> <issue id>
# env:   STOP_BG=1  stop the commander's background work at exit instead of refusing
set -u
name=${1:?agent name}; issue=${2:?issue id}
S=$(cd "$(dirname "$0")" && pwd)
home=${MAYOR_HOME:-$HOME/.local/state/herdr-mayor}
brief=$HOME/.claude/skills/herdr-mayor/references/commander-brief.md
folder=$(awk -F'\t' -v n="$name" -v i="$issue" '$1 == n && $2 == i { f = $3 } END { print f }' "$home/inbox-projects.tsv" 2>/dev/null)
[ -n "$folder" ] || { echo "skip $name: no Inbox project for $issue (run: mayor.sh project $name $issue)"; exit 2; }
proj=$home/inbox-projects/$folder

info=$(herdr agent get "$name" 2>/dev/null) || { echo "skip $name: not found"; exit 2; }
status=$(jq -r '.result.agent.agent_status' <<<"$info")
kind=$(jq -r '.result.agent.agent // empty' <<<"$info")
pane=$(jq -r '.result.agent.pane_id' <<<"$info")
sid=$(jq -r '.result.agent.agent_session.value // empty' <<<"$info")
[ "$kind" = claude ] || { echo "skip $name: kind=$kind"; exit 3; }
case "$status" in idle|done) ;; *) echo "skip $name: status=$status"; exit 3 ;; esac
[ -n "$sid" ] || { echo "skip $name: no session id"; exit 3; }
screen=$(herdr agent read "$name" --source visible --lines 60 2>/dev/null | sed $'s/\xc2\xa0/ /g')
if grep -qE 'Enter to select|Esc to cancel|Do you want to|Submit answers|Tab to switch questions|to navigate' <<<"$screen"; then
  echo "skip $name: question open on screen"; exit 3
fi
draft=$(herdr agent read "$name" --source visible --lines 8 --format ansi 2>/dev/null \
  | perl -CSD -ne 'if (/^\x{276f}/) { s/^\x{276f}//; s/\x{a0}/ /g; s/\e\[2m.*?(?:\e\[0?m|\e\[22m|$)//g; s/\e\[[0-9;]*m//g; s/^\s+|\s+$//g; $r = $_ } END { print $r if defined $r }')
[ -z "$draft" ] || { echo "skip $name: human draft in input line"; exit 3; }
m=$(grep -oE 'Model: [A-Za-z]+ [0-9.]+' <<<"$screen" | tail -1 | sed 's/Model: //')
e=$(grep -oE 'Thinking: [a-z]+' <<<"$screen" | tail -1 | sed 's/Thinking: //')
case "$m" in
  "Opus 5.5") model=claude-opus-5-5 ;; "Sonnet 5.5") model=claude-sonnet-5-5 ;;
  "Haiku 5.5") model=claude-haiku-5-5 ;; "Fable 5.1") model=claude-fable-5-1 ;;
  *) model="" ;;
esac
# A narrow pane truncates the status line; fall back to the session transcript.
if [ -z "$model" ] || [ -z "$e" ]; then
  tr=$(find "$HOME/.claude/projects" -name "$sid.jsonl" 2>/dev/null | head -1)
  if [ -n "$tr" ]; then
    [ -n "$model" ] || model=$(LC_ALL=C grep -aoE '"model":"claude-[a-z0-9-]+"' "$tr" | tail -1 | sed 's/.*:"//; s/"$//')
    [ -n "$e" ] || e=$(LC_ALL=C grep -aoE '"effort":"[a-z]+"' "$tr" | tail -1 | sed 's/.*:"//; s/"$//')
  fi
fi
[ -n "$model" ] || { echo "skip $name: unknown model '$m'"; exit 3; }
[ -n "$e" ] || { echo "skip $name: effort not shown"; exit 3; }

mkdir -p "$proj"
herdr agent prompt "$name" "/exit" >/dev/null 2>&1
stopped_bg=""
for _ in $(seq 1 30); do
  sleep 1; herdr agent get "$name" >/dev/null 2>&1 || break
  # Claude Code asks before exiting while background work runs (option 1 = exit and stop tasks).
  if herdr agent read "$name" --source visible --lines 20 2>/dev/null | grep -q 'Background work is running'; then
    if [ "${STOP_BG:-0}" = 1 ] && [ -z "$stopped_bg" ]; then
      herdr agent send-keys "$name" enter >/dev/null 2>&1; stopped_bg=yes
    elif [ -z "$stopped_bg" ]; then
      herdr agent send-keys "$name" esc >/dev/null 2>&1; echo "skip $name: background work running (set STOP_BG=1 to stop it)"; exit 3
    fi
  fi
done
if herdr agent get "$name" >/dev/null 2>&1; then echo "FAIL $name: still running after /exit"; exit 1; fi
sleep 1
herdr agent start "$name" --kind claude --pane "$pane" --timeout 60000 -- --resume "$sid" --model "$model" --effort "$e" --name "$name" >/dev/null 2>&1
herdr pane rename "$pane" "$name" >/dev/null 2>&1
got=$(herdr agent get "$name" 2>/dev/null | jq -r '"\(.result.agent.pane_id) \(.result.agent.agent_session.value)"')
[ "$got" = "$pane $sid" ] || { echo "FAIL $name: after restart got '$got', want '$pane $sid'"; exit 1; }
sleep 2
"$S/mayor.sh" relay "$name" "[mayor から] focus の担当は、human への質問と報告を Plannotator Inbox に出します (human の決定)。Inbox の道具が使えるように、同じ session のまま起動し直しました。${brief} を読み、「出し先を切り替えるとき」のとおりに Inbox へ移ってください。あなたの issue の識別子は ${issue}、Inbox の project のフォルダは ${proj} です。${stopped_bg:+起動し直すときに、裏で動いていた作業 (見張りなど) は止まりました。要るものを張り直してください。}" >/dev/null \
  || { echo "WARN $name: restarted but brief not sent"; exit 4; }
echo "ok $name: $model $e session=${sid:0:8} pane=$pane project=$folder"
