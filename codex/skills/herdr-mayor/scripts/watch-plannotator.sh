#!/usr/bin/env bash
# Wait until the Plannotator Inbox gains a new message that the Mayor did not write, or an
# answer the person actually sent, then print one summary line per event (no bodies) and exit,
# so a background run wakes the Mayor. Record rewrites (read marks, draft picks) are ignored.
# usage: watch-plannotator.sh [timeout_sec=1800] [interval_sec=30]
# env:   MAYOR_SESSION  the Mayor's Claude session id (its own messages are ignored)
#        INBOX_DIR      default ~/.plannotator/inbox
set -u
timeout=${1:-1800}; interval=${2:-30}
dir=${INBOX_DIR:-$HOME/.plannotator/inbox}/projects
home=${MAYOR_HOME:-$HOME/.local/state/herdr-mayor}
state=$home/plannotator-seen.tsv       # file <TAB> line count already read
ids=$home/plannotator-seen-ids.txt     # message ids and sent answers already reported
me=${MAYOR_SESSION:-}

count() { [ -f "$1" ] && wc -l < "$1" | tr -d ' ' || echo 0; }
seen() { awk -F'\t' -v f="$1" '$1==f{print $2; found=1} END{if(!found) print ""}' "$state" 2>/dev/null; }
set_seen() {
  local tmp; tmp=$(mktemp)
  awk -F'\t' -v f="$1" '$1!=f' "$state" 2>/dev/null > "$tmp"; printf '%s\t%s\n' "$1" "$2" >> "$tmp"; mv "$tmp" "$state"
}
touch "$ids"

# Turn new records into "<event id>\t<summary>" lines; event ids dedupe rewrites of one record.
events() {
  jq -rc --arg me "$me" --arg p "$1" '
    if .kind == "message" then
      (.record.author.session // "") as $s
      | select(($me == "") or ($s != $me))
      | "msg:\(.record.id)\t\($p)\tmessage\t\(.record.author.kind // "?")\t\($s[0:8])\tthread=\(.record.thread_id)\tname=\(.record.thread_name // "")\tsubject=\(.record.subject // "")\tat=\(.at)"
    elif .kind == "question" and (.record.sent_reply_id != null) then
      "ans:\(.record.id):\(.record.sent_reply_id)\t\($p)\tanswer-sent\tmessage=\(.record.message_id)\tkey=\(.record.key)\treply=\(.record.sent_reply_id)\tat=\(.at)"
    else empty end' 2>/dev/null
}

# First run: everything already there counts as read.
if [ ! -f "$state" ]; then
  : > "$state"
  for f in "$dir"/*/messages.jsonl "$dir"/*/questions.jsonl; do
    [ -f "$f" ] || continue
    events "$(basename "$(dirname "$f")")" < "$f" | cut -f1 >> "$ids"
    set_seen "$f" "$(count "$f")"
  done
fi

deadline=$(( $(date +%s) + timeout ))
settle=${SETTLE:-45}   # after the first change, wait this long so a burst of answers wakes the Mayor once
out=""
while :; do
  for f in "$dir"/*/messages.jsonl "$dir"/*/questions.jsonl; do
    [ -f "$f" ] || continue
    n=$(count "$f"); s=$(seen "$f"); [ -z "$s" ] && s=0
    [ "$n" -gt "$s" ] || continue
    proj=$(basename "$(dirname "$f")")
    while IFS=$'\t' read -r eid rest; do
      [ -n "$eid" ] || continue
      grep -qxF "$eid" "$ids" && continue
      echo "$eid" >> "$ids"
      out="${out}${rest}"$'\n'
    done < <(tail -n "$(( n - s ))" "$f" | events "$proj")
    set_seen "$f" "$n"
  done
  if [ -n "$out" ]; then
    if [ -n "${settled:-}" ] || [ "$settle" -le 0 ]; then printf 'plannotator inbox changed\n%s' "$out"; exit 0; fi
    settled=yes; sleep "$settle"; continue
  fi
  [ "$(date +%s)" -ge "$deadline" ] && { echo "timeout: no new Inbox messages or sent answers within ${timeout}s"; exit 0; }
  sleep "$interval"
done
