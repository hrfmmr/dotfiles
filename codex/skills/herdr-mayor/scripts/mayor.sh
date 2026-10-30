#!/usr/bin/env bash
# Mayor side helpers. State lives in $MAYOR_HOME (default ~/.local/state/herdr-mayor):
#   inbox.md    commanders append human-todo lines here (scripts/report.sh)
#   cursor      last inbox line the Mayor has processed
#   roster.tsv  pane_id <TAB> name <TAB> issue <TAB> workspace label <TAB> priority  (# lines ignored)
#               priority is focus (escalate to the human) or pend (hold in the ledger); empty = focus
#   seen        conditions the watcher already reported (blocked / gone / name_lost)
#   config      ledger=<path to the human-facing ledger note>
#   herdr-names.tsv  every named agent ever seen: name kind ws_label tab pane pane_label cwd session last_seen
#
#   mayor.sh init [--ledger <path>]   create the state dir (keeps existing files)
#   mayor.sh survey                   every agent: ws, ws label, pane, name, label, kind, status
#   mayor.sh new                      unprocessed inbox lines as "<lineno><TAB><priority><TAB><line>", then "upto=<n>"
#   mayor.sh ack <n>                  mark inbox lines up to <n> processed
#   mayor.sh watch                    block until something needs the Mayor, print events, exit 0
#   mayor.sh relay [--until-sent [--timeout SEC]] <name> <text>
#                                     prompt a commander; refuses while it is blocked (exit 3), busy (4),
#                                     or its input box holds a human draft (5; dim text is only a suggestion).
#                                     --until-sent retries those three every MAYOR_RELAY_RETRY_SEC (15)
#                                     until sent or SEC (1800) has passed; run it through the background tool
#   mayor.sh help                     the skill's sub-command table, read from SKILL.md
#   mayor.sh status                   roster rows with live status and whether each acked; watcher state
#   mayor.sh priority <name|issue> focus|pend   set the roster priority (an issue also matches its children)
#   mayor.sh snapshot                 merge the live agent names into herdr-names.tsv
#   mayor.sh restore [--apply]        after a herdr restart, plan (or apply) the names back onto panes
#   mayor.sh forget <name>            drop a name from herdr-names.tsv
#
# Herdr keeps workspace, tab and pane labels across a server stop or reboot, but agent
# names belong to the agent process and are gone. herdr-names.tsv is the copy that
# survives; it only ever adds or updates rows, so a snapshot taken right after a
# restart (when no agent has a name) cannot wipe it.
set -u -o pipefail

home=${MAYOR_HOME:-$HOME/.local/state/herdr-mayor}
inbox=$home/inbox.md
cursor_f=$home/cursor
roster=$home/roster.tsv
seen_f=$home/seen
config=$home/config
names_f=$home/herdr-names.tsv

die() { echo "$*" >&2; exit 1; }
need_home() { [ -d "$home" ] || die "no state dir at $home; run: mayor.sh init"; }
cursor() { cat "$cursor_f" 2>/dev/null || echo 0; }
inbox_lines() { wc -l < "$inbox" | tr -d ' '; }

cmd_init() {
  local ledger=""
  [ "${1:-}" = --ledger ] && ledger=${2:-}
  mkdir -p "$home"
  touch "$inbox" "$seen_f"
  [ -f "$cursor_f" ] || echo 0 > "$cursor_f"
  [ -f "$roster" ] || printf '# pane_id\tname\tissue\tworkspace\tpriority\n' > "$roster"
  if [ -n "$ledger" ]; then
    printf 'ledger=%s\n' "$ledger" > "$config"
  fi
  echo "home=$home"
  cat "$config" 2>/dev/null || echo "ledger=(unset; pass --ledger)"
}

cmd_survey() {
  local ws panes agents
  ws=$(herdr workspace list) || die "herdr workspace list failed"
  panes=$(herdr pane list) || die "herdr pane list failed"
  agents=$(herdr agent list) || die "herdr agent list failed"
  printf 'ws\tws_label\tpane\tname\tlabel\tkind\tstatus\n'
  jq -rn --argjson ws "$ws" --argjson panes "$panes" --argjson agents "$agents" '
    ($ws.result.workspaces | map({key: .workspace_id, value: .label}) | from_entries) as $wl
    | ($agents.result.agents | map({key: .pane_id, value: (.name // "")}) | from_entries) as $an
    | $panes.result.panes[]
    | [.workspace_id, ($wl[.workspace_id] // "" | .[0:40]), .pane_id,
       ($an[.pane_id] // "-" | if . == "" then "-" else . end),
       (.label // "-"), (.agent // "-"), (.agent_status // "-")]
    | @tsv'
}

# Inbox lines after cursor $1 (up to line $2) as "<lineno><TAB><priority><TAB><line>".
# Priority comes from the sender's roster row; a sender missing from the roster is "?".
inbox_with_priority() {
  awk -F'\t' -v c="$1" -v n="$2" '
    FNR == NR { if ($1 !~ /^#/ && $2 != "") prio[$2] = ($5 == "" ? "focus" : $5); next }
    FNR > c && FNR <= n {
      p = "?"
      if (match($0, /\| from=[^|]* \|/)) { f = substr($0, RSTART + 7, RLENGTH - 9); if (f in prio) p = prio[f] }
      printf "%d\t%s\t%s\n", FNR, p, $0
    }' "$roster" "$inbox"
}

cmd_new() {
  need_home
  local c n
  c=$(cursor); n=$(inbox_lines)
  [ "$n" -le "$c" ] || inbox_with_priority "$c" "$n"
  echo "upto=$n"
}

cmd_ack() {
  need_home
  local n=${1:-}
  case "$n" in ''|*[!0-9]*) die "usage: mayor.sh ack <line-number>" ;; esac
  [ "$n" -ge "$(cursor)" ] || die "cursor is already past $n"
  echo "$n" > "$cursor_f"
}

# Current conditions on roster panes, one per line: "<kind> <pane> <name>".
conditions() {
  local list pane name issue ws prio row status got
  list=$1
  while IFS=$'\t' read -r pane name issue ws prio; do
    case "$pane" in ''|\#*) continue ;; esac
    row=$(jq -r --arg p "$pane" '.result.agents[] | select(.pane_id == $p) | "\(.agent_status)\t\(.name // "")"' <<<"$list")
    if [ -z "$row" ]; then
      echo "gone $pane $name"
      continue
    fi
    status=${row%%$'\t'*}; got=${row#*$'\t'}
    # A pend commander's open question is held, not escalated, so it does not wake the Mayor.
    [ "$status" = blocked ] && [ "${prio:-focus}" != pend ] && echo "blocked $pane $name"
    [ "$got" = "$name" ] || echo "name_lost $pane $name"
  done < "$roster"
  herdr agent get mayor >/dev/null 2>&1 || echo "name_lost ${HERDR_PANE_ID:-?} mayor"
}

notify() {
  herdr notification show "$1" --body "$2" --sound request >/dev/null 2>&1 || true
}

cmd_watch() {
  need_home
  local interval=${MAYOR_WATCH_INTERVAL:-20} pidf=$home/watch.pid
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then
    die "a watcher is already running (pid $(cat "$pidf"))"
  fi
  echo $$ > "$pidf"
  trap 'rm -f "$pidf"' EXIT
  local c n list current fresh urgent
  while :; do
    fresh=""
    ( cmd_snapshot ) >/dev/null 2>&1 || true
    c=$(cursor); n=$(inbox_lines)
    if [ "$n" -gt "$c" ]; then
      fresh="inbox $((n - c)) new line(s), run: mayor.sh new"
      # Notify only for focus senders; the Mayor reads pend urgents and decides itself.
      urgent=$(inbox_with_priority "$c" "$n" | awk -F'\t' '$2 != "pend" && /\| urgent=yes \|/' | cut -f3- | head -3)
      [ -z "$urgent" ] || notify "mayor: 急ぎの human todo" "$(printf '%s' "$urgent" | sed -E 's/.*\| issue=([^|]*) \|.*\| what=([^|]*).*/\1: \2/' | head -1)"
    fi
    if list=$(herdr agent list 2>/dev/null); then
      current=$(conditions "$list")
      # Report only conditions not reported before; forget cleared ones so they can fire again.
      local new_cond
      new_cond=$(grep -vxF -f "$seen_f" <<<"$current" | sed '/^$/d')
      printf '%s\n' "$current" | sed '/^$/d' > "$seen_f"
      if [ -n "$new_cond" ]; then
        while read -r kind pane name; do
          [ "$kind" = blocked ] && notify "mayor: $name が human の回答待ち" "$pane"
        done <<<"$new_cond"
        fresh=$(printf '%s\n%s' "$fresh" "$new_cond" | sed '/^$/d')
      fi
    fi
    if [ -n "$fresh" ]; then
      printf '%s\n' "$fresh"
      exit 0
    fi
    sleep "$interval"
  done
}

# SKILL.md's Sub-commands table is the only list, so help cannot drift from it.
cmd_help() {
  awk -F' [|] ' '
    /^## Sub-commands/ { on = 1; next }
    on && /^## / { exit }
    on && /^[|] `/ { gsub(/^[|] | [|]$|`/, ""); printf "%s\n    %s\n    (%s)\n", $1, $3, $2 }
  ' "$(dirname "$0")/../SKILL.md"
}

cmd_status() {
  need_home
  local list acked pane name issue ws prio row st got a pidf=$home/watch.pid
  list=$(herdr agent list) || die "herdr agent list failed"
  acked=$(sed -nE 's/.*\| from=([^|]*) \|.*\| kind=ack \|.*/\1/p' "$inbox" | sort -u)
  printf 'name\tissue\tpriority\tstatus\tacked\n'
  while IFS=$'\t' read -r pane name issue ws prio; do
    case "$pane" in ''|\#*) continue ;; esac
    row=$(jq -r --arg p "$pane" '.result.agents[] | select(.pane_id == $p) | "\(.agent_status)\t\(.name // "")"' <<<"$list")
    if [ -z "$row" ]; then st=gone; else
      st=${row%%$'\t'*}; got=${row#*$'\t'}
      [ "$got" = "$name" ] || st="$st,name_lost"
    fi
    grep -qxF "$name" <<<"$acked" && a=yes || a=no
    printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$issue" "${prio:-focus}" "$st" "$a"
  done < "$roster"
  if [ -f "$pidf" ] && kill -0 "$(cat "$pidf")" 2>/dev/null; then
    echo "watcher=running pid $(cat "$pidf")"
  else
    echo "watcher=stopped"
  fi
}

cmd_priority() {
  need_home
  local target=${1:-} prio=${2:-}
  case "$prio" in focus|pend) ;; *) die "usage: mayor.sh priority <name|issue> focus|pend" ;; esac
  [ -n "$target" ] || die "usage: mayor.sh priority <name|issue> focus|pend"
  # A name, an exact issue, or an issue's children (0hd matches 0hd.1.8, not 0hdx).
  if awk -F'\t' -v OFS='\t' -v t="$target" -v p="$prio" '
       /^#/ { print; next }
       $2 == t || $3 == t || index($3, t ".") == 1 { $5 = p; hit = 1 }
       { print }
       END { exit hit ? 0 : 3 }' "$roster" > "$roster.tmp"; then
    mv "$roster.tmp" "$roster"
  else
    rm -f "$roster.tmp"; die "no roster row matches $target"
  fi
  awk -F'\t' -v t="$target" '!/^#/ && ($2 == t || $3 == t || index($3, t ".") == 1) { print $2 "\t" $3 "\t" $5 }' "$roster"
}

herdr_state() {
  ws=$(herdr workspace list) && panes=$(herdr pane list) && agents=$(herdr agent list) \
    || die "herdr list failed (is the server up?)"
}

cmd_snapshot() {
  need_home
  local ws panes agents cur
  herdr_state
  cur=$(jq -rn --argjson ws "$ws" --argjson panes "$panes" --argjson agents "$agents" \
          --arg now "$(date +%Y-%m-%dT%H:%M:%S)" '
    ($ws.result.workspaces | map({key: .workspace_id, value: .label}) | from_entries) as $wl
    | ($panes.result.panes | map({key: .pane_id, value: (.label // "")}) | from_entries) as $pl
    | $agents.result.agents[] | select((.name // "") != "")
    | [.name, .agent, ($wl[.workspace_id] // ""), .tab_id, .pane_id, ($pl[.pane_id] // ""),
       (.cwd // ""), (.agent_session.value // ""), $now]
    | map(tostring | gsub("\t"; " ")) | @tsv')
  touch "$names_f"
  # Live rows win by name. An old row is dropped only when another live name now holds
  # its pane in the same workspace (the pane was reused); rows for absent names stay.
  { printf '%s\n' "$cur" | sed '/^$/d; s/^/C\t/'; sed 's/^/O\t/' "$names_f"; } | awk -F'\t' '
    $1 == "C" { live[$2] = 1; held[$4 SUBSEP $6] = 1; sub(/^C\t/, ""); print; next }
    !($2 in live) && !(($4 SUBSEP $6) in held) { sub(/^O\t/, ""); print }
  ' > "$names_f.tmp" && mv "$names_f.tmp" "$names_f"
}

sync_roster() {
  [ -f "$roster" ] || return 0
  local map
  map=$(herdr agent list | jq -r '.result.agents[] | select((.name // "") != "") | [.name, .pane_id] | @tsv') || return 0
  awk -F'\t' -v OFS='\t' 'NR == FNR { p[$1] = $2; next } /^#/ || !($2 in p) { print; next } { $1 = p[$2]; print }' \
    <(printf '%s\n' "$map") "$roster" > "$roster.tmp" && mv "$roster.tmp" "$roster"
}

cmd_restore() {
  need_home
  local apply=0 ws panes agents cur live used=" "
  [ "${1:-}" = --apply ] && apply=1
  [ -s "$names_f" ] || die "no snapshot at $names_f"
  herdr_state
  # pane_id ws_label label agent_kind agent_name cwd
  cur=$(jq -rn --argjson ws "$ws" --argjson panes "$panes" --argjson agents "$agents" '
    ($ws.result.workspaces | map({key: .workspace_id, value: .label}) | from_entries) as $wl
    | ($agents.result.agents | map({key: .pane_id, value: (.name // "")}) | from_entries) as $an
    | $panes.result.panes[]
    | [.pane_id, ($wl[.workspace_id] // ""), (.label // ""), (.agent // ""), ($an[.pane_id] // ""), (.cwd // "")]
    | map(tostring | gsub("\t"; " ")) | @tsv')
  live=$(jq -r '.result.agents[] | .name // empty' <<<"$agents")
  local name kind wsl tab pane plabel cwd session seen target n row akind aname hint
  # Read on \037, not tab: tab is IFS whitespace, so `read` would collapse empty fields.
  while IFS=$'\037' read -r name kind wsl tab pane plabel cwd session seen; do
    [ -n "$name" ] || continue
    grep -qxF "$name" <<<"$live" && continue
    # Strongest key first: a label equal to the name, then the old pane id in the same
    # workspace, then the only unnamed agent in that workspace with the same cwd.
    target=$(awk -F'\t' -v n="$name" -v w="$wsl" '$3 == n && $2 == w { print $1 }' <<<"$cur")
    [ -n "$target" ] || target=$(awk -F'\t' -v n="$name" '$3 == n { print $1 }' <<<"$cur")
    [ -n "$target" ] || target=$(awk -F'\t' -v p="$pane" -v w="$wsl" '$1 == p && $2 == w { print $1 }' <<<"$cur")
    [ -n "$target" ] || target=$(awk -F'\t' -v c="$cwd" -v w="$wsl" '$2 == w && $6 == c && $4 != "" && $5 == "" { print $1 }' <<<"$cur")
    n=$(printf '%s' "$target" | grep -c .)
    if [ "$n" -ne 1 ]; then
      echo "missing $name: $n candidate pane(s) in workspace '$wsl' (last pane $pane)"; continue
    fi
    case "$used" in *" $target "*) echo "conflict $target $name: already assigned in this run"; continue ;; esac
    row=$(awk -F'\t' -v p="$target" '$1 == p' <<<"$cur")
    akind=$(cut -f4 <<<"$row"); aname=$(cut -f5 <<<"$row")
    if [ -z "$akind" ]; then
      hint=""
      [ "$kind" = claude ] && [ -n "$session" ] && hint=" (claude --resume $session)"
      echo "start $target $name: no agent running; start $kind in $cwd$hint"; continue
    fi
    if [ -n "$aname" ]; then echo "conflict $target $name: pane is held by '$aname'"; continue; fi
    used="$used$target "
    if [ "$apply" = 1 ]; then
      if herdr agent rename "$target" "$name" >/dev/null 2>&1 && herdr pane rename "$target" "$name" >/dev/null 2>&1; then
        echo "renamed $target $name"
      else
        echo "failed $target $name"
      fi
    else
      echo "rename $target $name"
    fi
  done < <(tr '\t' '\037' < "$names_f")
  if [ "$apply" = 1 ]; then sync_roster; cmd_snapshot; fi
}

cmd_forget() {
  need_home
  local name=${1:-}
  [ -n "$name" ] || die "usage: mayor.sh forget <name>"
  awk -F'\t' -v n="$name" '$1 != n' "$names_f" > "$names_f.tmp" && mv "$names_f.tmp" "$names_f"
}

# Text in the Claude Code input line (the line starting with the prompt mark) that is not dim.
# Dim (SGR 2) text is a prompt suggestion, not the human's input; reads `agent read --format ansi` on stdin.
draft_text() {
  perl -CSD -ne 'if (/^\x{276f}/) { s/^\x{276f}//; s/\x{a0}/ /g; s/\e\[2m.*?(?:\e\[0?m|\e\[22m|$)//g; s/\e\[[0-9;]*m//g; s/^\s+|\s+$//g; $r = $_ } END { print $r if defined $r }'
}

relay_once() {
  local name=${1:-} text=${2:-} status draft
  [ -n "$name" ] && [ -n "$text" ] || die "usage: mayor.sh relay [--until-sent [--timeout SEC]] <name> <text>"
  status=$(herdr agent get "$name" 2>/dev/null | jq -r '.result.agent.agent_status // empty')
  [ -n "$status" ] || { echo "agent_not_found: $name (restore the name from roster.tsv, then retry)" >&2; return 2; }
  case "$status" in
    working|unknown)
      herdr agent wait "$name" --timeout "${MAYOR_RELAY_WAIT_MS:-120000}" >/dev/null 2>&1 || true
      status=$(herdr agent get "$name" 2>/dev/null | jq -r '.result.agent.agent_status // empty') ;;
  esac
  # Herdr often reports an open question as idle/done, so read the screen for the
  # question UI itself; typing into it would select an answer on the human's behalf.
  case "$status" in
    idle|done)
      if herdr agent read "$name" --source visible --lines 60 2>/dev/null \
          | grep -qE 'Enter to select|Esc to cancel|Do you want to|Submit answers|Tab to switch questions|to navigate'; then
        status=blocked
      fi ;;
  esac
  case "$status" in
    idle|done)
      draft=$(herdr agent read "$name" --source visible --lines 8 --format ansi 2>/dev/null | draft_text)
      if [ -n "$draft" ]; then
        echo "human_draft: $name's input box holds text that is not a prompt suggestion; typing would mix with it. Not sent." >&2
        return 5
      fi
      herdr agent prompt "$name" "$text" >/dev/null || die "herdr agent prompt $name failed"
      echo "sent to $name" ;;
    blocked)
      echo "blocked: $name has an open question or approval; keys would land in it. Not sent." >&2
      return 3 ;;
    *)
      echo "busy: $name is still $status; retry later. Not sent." >&2
      return 4 ;;
  esac
}

cmd_relay() {
  local until_sent=0 timeout=1800 out rc deadline
  while [ $# -gt 0 ]; do
    case "$1" in
      --until-sent) until_sent=1; shift ;;
      --timeout) timeout=${2:-}; shift 2 || die "--timeout needs seconds" ;;
      *) break ;;
    esac
  done
  case "$timeout" in ''|*[!0-9]*) die "--timeout needs seconds" ;; esac
  if [ "$until_sent" = 0 ]; then relay_once "$@"; exit $?; fi
  deadline=$(( $(date +%s) + timeout ))
  while :; do
    out=$(relay_once "$@" 2>&1); rc=$?
    case $rc in
      3|4|5)
        if [ "$(date +%s)" -ge "$deadline" ]; then echo "$out" >&2; echo "timeout: not sent within ${timeout}s (last exit $rc)" >&2; exit "$rc"; fi
        sleep "${MAYOR_RELAY_RETRY_SEC:-15}" ;;
      *) echo "$out"; exit "$rc" ;;
    esac
  done
}

sub=${1:-}; [ $# -gt 0 ] && shift
case "$sub" in
  init) cmd_init "$@" ;;
  survey) cmd_survey ;;
  new) cmd_new ;;
  ack) cmd_ack "$@" ;;
  watch) cmd_watch ;;
  relay) cmd_relay "$@" ;;
  help) cmd_help ;;
  status) cmd_status ;;
  priority) cmd_priority "$@" ;;
  snapshot) cmd_snapshot ;;
  restore) cmd_restore "$@" ;;
  forget) cmd_forget "$@" ;;
  *) sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
esac
