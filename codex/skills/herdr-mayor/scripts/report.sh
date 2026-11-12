#!/usr/bin/env bash
# Commander side: append one human-todo line to the Mayor's inbox.
#
#   report.sh --issue <id> --kind <kind> --what <text> [--key <key>] [--urgent yes|no]
#             [--where <pane/url/note>] [--done-when <text>]
#             [--q <question> --options "A / B / C" [--rec A]]
#   report.sh --issue <id> --kind pr --pr <owner/repo#n|url> [--state <state>] [--slack <url>]
#
# kind: operate merge review approve answer confirm external other done cancel ack pr
#   confirm needs --q and --options (the Mayor asks the human and relays the answer).
#   pr records a PR in the Mayor's PR table (pr-status skill); needs --pr and --state or --slack.
#   state: opened agent-review agent-review-done apply-pending applied closed
#   done / cancel close an earlier line and need --key.
# The key is printed on stdout; reuse it for done / cancel.
#
# One printf with O_APPEND per line, so concurrent commanders do not interleave.
# `|` and newlines in values are replaced, because the Mayor splits fields on ` | `.
set -u -o pipefail

home=${MAYOR_HOME:-$HOME/.local/state/herdr-mayor}
inbox=$home/inbox.md

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

issue="" kind="" what="" key="" urgent="no" where="" done_when="" q="" options="" rec=""
pr="" state="" slack=""
while [ $# -gt 0 ]; do
  case "$1" in
    --issue) issue=$2; shift 2 ;;
    --kind) kind=$2; shift 2 ;;
    --what) what=$2; shift 2 ;;
    --key) key=$2; shift 2 ;;
    --urgent) urgent=$2; shift 2 ;;
    --where) where=$2; shift 2 ;;
    --done-when) done_when=$2; shift 2 ;;
    --q) q=$2; shift 2 ;;
    --options) options=$2; shift 2 ;;
    --rec) rec=$2; shift 2 ;;
    --pr) pr=$2; shift 2 ;;
    --state) state=$2; shift 2 ;;
    --slack) slack=$2; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown argument: $1" >&2; usage ;;
  esac
done

case "$kind" in
  operate|merge|review|approve|answer|confirm|external|other|done|cancel|ack|pr) ;;
  *) echo "invalid --kind: '$kind'" >&2; usage ;;
esac
case "$urgent" in yes|no) ;; *) echo "--urgent must be yes or no" >&2; exit 2 ;; esac
[ -n "$issue" ] || { echo "--issue is required" >&2; exit 2; }
if [ "$kind" = pr ]; then
  printf '%s' "$pr" | grep -Eq '^([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#[0-9]+|https://github\.com/[^/]+/[^/]+/pull/[0-9]+)' \
    || { echo "kind=pr needs --pr owner/repo#n or a GitHub PR URL" >&2; exit 2; }
  case "$state" in
    ""|opened|agent-review|agent-review-done|apply-pending|applied|closed) ;;
    *) echo "invalid --state: '$state'" >&2; exit 2 ;;
  esac
  [ -n "$state" ] || [ -n "$slack" ] || { echo "kind=pr needs --state or --slack" >&2; exit 2; }
  [ -n "$what" ] || what="PR ${state:-slack}"
fi
[ -n "$what" ] || [ "$kind" = done ] || [ "$kind" = cancel ] || { echo "--what is required" >&2; exit 2; }
if [ "$kind" = confirm ] && { [ -z "$q" ] || [ -z "$options" ]; }; then
  echo "kind=confirm needs --q and --options" >&2; exit 2
fi
if { [ "$kind" = done ] || [ "$kind" = cancel ]; } && [ -z "$key" ]; then
  echo "kind=$kind needs the --key of the line it closes" >&2; exit 2
fi
[ -d "$home" ] || { echo "no Mayor state dir at $home (is a Mayor running?)" >&2; exit 1; }

# Sender: live agent name, else pane label, else pane id.
from=""
if [ -n "${HERDR_PANE_ID:-}" ]; then
  from=$(herdr agent get "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.agent.name // empty')
  [ -n "$from" ] || from=$(herdr pane get "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.pane.label // empty')
  [ -n "$from" ] || from=$HERDR_PANE_ID
fi
[ -n "$from" ] || from=unknown

[ -n "$key" ] || key="$from:$(date +%m%d%H%M)-$$"
[ -n "$where" ] || where=${HERDR_PANE_ID:-}

clean() { printf '%s' "$1" | tr '\n|' ' /'; }

line="- $(date +%Y-%m-%dT%H:%M) | from=$(clean "$from") | issue=$(clean "$issue") | key=$(clean "$key") | kind=$kind | urgent=$urgent | where=$(clean "$where") | what=$(clean "$what")"
[ -z "$done_when" ] || line="$line | done_when=$(clean "$done_when")"
[ -z "$q" ] || line="$line | q=$(clean "$q") | options=$(clean "$options") | rec=$(clean "$rec")"
[ -z "$pr" ] || line="$line | pr=$(clean "$pr")"
[ -z "$state" ] || line="$line | state=$state"
[ -z "$slack" ] || line="$line | slack=$(clean "$slack")"

printf '%s\n' "$line" >> "$inbox"
printf '%s\n' "$key"
