#!/usr/bin/env bash
# Watch a live Hunk session for new human (user) comments and hand them to the
# agent that is presenting the diff.
#
#   --target <pane>  submit each batch to that Herdr pane with `herdr agent prompt`
#                    (the presenting agent's $HERDR_PANE_ID). Works for any agent kind.
#   no --target      print one line per comment to stdout, for a harness monitor
#                    (e.g. Claude Code's Monitor tool) to turn into notifications.
#
# Delivered note ids are kept in a state file (one per repo or session by default).
# On the first run, comments that already exist count as seen. A restart reuses the
# state file, so comments made while no watcher was running are delivered. Use
# --include-existing to clear the state and deliver everything again.
#
# A failed delivery (e.g. the agent is `blocked` on a permission dialog) is retried
# with backoff and nothing is marked delivered until it succeeds. The watcher gives up
# after about 20 minutes of failed deliveries, and exits once the Hunk session is gone.
# Only one watcher runs per state file.
set -u -o pipefail

usage() {
  echo "usage: $0 (--repo <worktree> | --session <id>) [--target <herdr-pane-id>]" \
       "[--label <name>] [--interval <sec>] [--state <file>] [--include-existing]" >&2
  exit 2
}

REPO="" SESSION="" TARGET="" LABEL="hunk" INTERVAL=2 STATE="" INCLUDE_EXISTING=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO=$2; shift 2 ;;
    --session) SESSION=$2; shift 2 ;;
    --target) TARGET=$2; shift 2 ;;
    --label) LABEL=$2; shift 2 ;;
    --interval) INTERVAL=$2; shift 2 ;;
    --state) STATE=$2; shift 2 ;;
    --include-existing) INCLUDE_EXISTING=1; shift ;;
    *) usage ;;
  esac
done
[ -n "$REPO$SESSION" ] || usage
if [ -n "$SESSION" ]; then SELECTOR=("$SESSION"); KEY=$SESSION; else SELECTOR=(--repo "$REPO"); KEY=$REPO; fi
STATE=${STATE:-${TMPDIR:-/tmp}/hunk-watch-$(printf %s "$KEY" | shasum | cut -c1-12).seen}

# One watcher per state file; a stale lock (dead pid) is taken over.
LOCK="$STATE.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  old=$(cat "$LOCK/pid" 2>/dev/null || true)
  if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then
    echo "another watcher (pid $old) already uses $STATE" >&2
    exit 1
  fi
  rm -rf "$LOCK" && mkdir "$LOCK" || exit 1
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT

[ "$INCLUDE_EXISTING" -eq 1 ] && : > "$STATE"

# Prints the JSON on success; prints "ERR <message>" and returns 1 otherwise.
list() {
  local out
  out=$(hunk session comment list "${SELECTOR[@]}" --type user --json 2>&1)
  if printf '%s' "$out" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1; then
    printf '%s' "$out"
  else
    printf 'ERR %s' "$(printf '%s' "$out" | head -1)"
    return 1
  fi
}

# Prints "<noteId>\t<path>:<line>\t<body>" for each comment not yet in $STATE.
unseen() {
  python3 -c '
import json, sys
seen = set(open(sys.argv[1]).read().split())
for c in json.load(sys.stdin).get("comments", []):
    if c["noteId"] in seen:
        continue
    r = c.get("newRange") or c.get("oldRange") or ["?"]
    body = " ".join(c.get("body", "").split())[:300]
    print(c["noteId"] + "\t" + c["filePath"] + ":" + str(r[0]) + "\t" + body)
' "$STATE"
}

deliver() {  # $1 = message; stdout mode always succeeds
  if [ -z "$TARGET" ]; then
    printf '%s\n' "$1"
    return 0
  fi
  herdr agent prompt "$TARGET" "$1" >/dev/null 2>&1
}

# The TUI may not have registered with the daemon yet: retry for about 30s.
first=""
for _ in $(seq 1 15); do
  if first=$(list); then break; fi
  case "$first" in *"Multiple active sessions"*)
    echo "$first — restart with --session <id> (see: hunk session list)" >&2; exit 1 ;;
  esac
  first=""
  sleep 2
done
if [ -z "$first" ]; then
  echo "no live hunk session for $KEY after 30s" >&2
  exit 1
fi
touch "$STATE"
if [ ! -s "$STATE" ] && [ "$INCLUDE_EXISTING" -eq 0 ]; then
  seed=$(printf '%s' "$first" | unseen) || { echo "failed to parse hunk comments" >&2; exit 1; }
  [ -n "$seed" ] && printf '%s\n' "$seed" | cut -f1 >> "$STATE"
fi
echo "watching $KEY (target: ${TARGET:-stdout}, state: $STATE)" >&2

misses=0 failures=0 wait=$INTERVAL
while :; do
  if ! out=$(list); then
    case "$out" in *"Multiple active sessions"*)
      deliver "[$LABEL watcher] 複数の hunk session が一致したので監視を止めました。--session <id> で起動し直してください。" || true
      exit 1 ;;
    esac
    misses=$((misses + 1))
    if [ "$misses" -ge 5 ]; then
      deliver "[$LABEL watcher] hunk session が終了したので、コメントの監視を止めました。" || true
      exit 0
    fi
    sleep "$INTERVAL"
    continue
  fi
  misses=0

  new=$(printf '%s' "$out" | unseen) || { echo "failed to parse hunk comments" >&2; exit 1; }
  if [ -n "$new" ]; then
    if [ -n "$TARGET" ]; then
      count=$(printf '%s\n' "$new" | wc -l | tr -d ' ')
      items=$(printf '%s\n' "$new" | awk -F'\t' '{printf " / %s — %s", $2, $3}')
      msg="[$LABEL watcher] hunk に新しい user コメントが ${count} 件付きました。hunk-present の手順 5 で回答してください (hunk session comment list ${SELECTOR[*]} --type user)${items}"
      if deliver "$msg"; then
        printf '%s\n' "$new" | cut -f1 >> "$STATE"
        failures=0 wait=$INTERVAL
      else
        failures=$((failures + 1))
        [ $((failures % 10)) -eq 1 ] && echo "delivery to $TARGET failed ($failures); retrying" >&2
        if [ "$failures" -ge 50 ]; then
          echo "giving up after $failures failed deliveries; restart the watcher to resume from $STATE" >&2
          exit 1
        fi
        wait=$((wait * 2)); [ "$wait" -gt 30 ] && wait=30
        sleep "$wait"
        continue
      fi
    else
      printf '%s\n' "$new" | awk -F'\t' -v l="$LABEL" '{printf "[%s watcher] %s — %s\n", l, $2, $3; fflush()}'
      printf '%s\n' "$new" | cut -f1 >> "$STATE"
    fi
  fi
  sleep "$INTERVAL"
done
