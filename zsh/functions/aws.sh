# Path to this file, captured while it is being sourced (%x), so aws-help can
# read its own doc comments back out.
_AWS_UTILS_FILE="${${(%):-%x}:A}"

# Print the region to operate in. Falls back to ap-northeast-1 when
# AWS_REGION / AWS_DEFAULT_REGION are unset.
function _aws-region() {
  print -r -- "${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-1}}"
}

# Fail with a message unless fzf is available.
function _aws-require-fzf() {
  if ! command -v fzf >/dev/null; then
    echo "ERROR: 'fzf' is not installed" >&2
    return 1
  fi
}

# Print the profile names defined in ~/.aws/config, one per line.
# `[default]` carries no `profile ` prefix, so it is matched separately.
# Usage: _aws-config-profiles [--sso-only]
#   --sso-only: keep only the profiles that reference an sso_session.
function _aws-config-profiles() {
  local config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  if [[ ! -f "$config" ]]; then
    echo "no config: $config" >&2
    return 1
  fi

  if [[ "$1" == "--sso-only" ]]; then
    awk '
      /^\[/ { p = "" }
      /^\[profile / { p = substr($0, 10, length($0) - 10) }
      /^[[:space:]]*sso_session[[:space:]]*=/ { if (p != "") print p }
    ' "$config"
    return 0
  fi

  awk '
    /^\[default\]/ { print "default" }
    /^\[profile / { print substr($0, 10, length($0) - 10) }
  ' "$config"
}

# Select a profile from ~/.aws/config with fzf and print the chosen name.
# Usage: _aws-select-profile <fzf header> [--sso-only]
function _aws-select-profile() {
  local header="$1" profile

  _aws-require-fzf || return 1

  profile="$(_aws-config-profiles "$2" | fzf --height 40% --reverse --header "$header")" || return 1

  if [[ -z "$profile" ]]; then
    echo "cancelled" >&2
    return 1
  fi

  print -r -- "$profile"
}

# Pick a profile from ~/.aws/config with fzf and expand `AWS_PROFILE=<profile> `
# onto the command line, so the next command runs against that profile without
# exporting anything into the current shell.
# Usage: aws-profile-prefix [--print]
#   --print: emit the prefix to stdout instead of pushing it onto the buffer
#            (used by the ZLE widget below).
function aws-profile-prefix() {
  local profile prefix
  profile="$(_aws-select-profile 'Select AWS profile')" || return 1

  prefix="AWS_PROFILE=${(q-)profile} "
  if [[ "$1" == "--print" ]]; then
    print -r -- "$prefix"
    return 0
  fi
  print -z "$prefix"
}

# `^j r`: insert `AWS_PROFILE=<profile> ` at the head of the current buffer.
# fzf reads /dev/tty, so it stays interactive inside $(...) within a widget.
function _aws-profile-prefix-widget() {
  local prefix
  prefix="$(aws-profile-prefix --print)" || { zle reset-prompt; return 1; }
  if [[ -n "$prefix" ]]; then
    BUFFER="${prefix}${BUFFER}"
    CURSOR=$(( CURSOR + ${#prefix} ))
  fi
  zle reset-prompt
}
zle -N _aws-profile-prefix-widget
bindkey '^j^r' _aws-profile-prefix-widget

# Pick a profile from ~/.aws/config with fzf and export AWS_PROFILE for the
# current shell.
function aws-switch-profile() {
  local profile
  profile="$(_aws-select-profile 'Select AWS profile')" || return 1

  export AWS_PROFILE="$profile"
  echo "AWS_PROFILE=$AWS_PROFILE" >&2
}

# Pick an SSO profile from ~/.aws/config with fzf and expand
# `aws sso login --profile <profile> && export AWS_PROFILE=<profile>`
# onto the command line, so the export lands in the current shell on Enter.
# Usage: aws-sso [--print]
#   --print: emit the command to stdout instead of pushing it onto the buffer
#            (used by the ZLE widget below).
function aws-sso() {
  local profile cmd
  profile="$(_aws-select-profile 'Select SSO profile' --sso-only)" || return 1

  # `command aws` bypasses any `aws` alias/wrapper defined in the shell.
  cmd="command aws sso login --profile ${(q-)profile} && export AWS_PROFILE=${(q-)profile}"
  if [[ "$1" == "--print" ]]; then
    print -r -- "$cmd"
    return 0
  fi
  print -S "$cmd"
  print -z "$cmd"
}

# `^j s`: expand the login command onto the command line (the user presses Enter).
function _aws-sso-widget() {
  local cmd
  cmd="$(aws-sso --print)" || { zle reset-prompt; return 1; }
  if [[ -n "$cmd" ]]; then
    BUFFER="$cmd"
    CURSOR=${#BUFFER}
  fi
  zle reset-prompt
}
zle -N _aws-sso-widget
bindkey '^j^s' _aws-sso-widget

# Select multiple CloudWatch Logs log groups and start a Live Tail session.
# Usage: aws-live-tail [--print] [extra options for `aws logs start-live-tail`]
#   --print: emit the command to stdout instead of running it
#            (used by the ZLE widget below).
# Up to 10 log groups can be selected, matching the AWS Live Tail limit.
# Falls back to ap-northeast-1 when AWS_REGION / AWS_DEFAULT_REGION are unset.
function aws-live-tail() {
  local arg aws_region log_group_list selected cmd
  local -a log_groups extra_args
  local print_only=0

  for arg in "$@"; do
    if [[ "$arg" == "--print" ]]; then
      print_only=1
    else
      extra_args+=("$arg")
    fi
  done

  setopt local_options pipe_fail
  _aws-require-fzf || return 1
  aws_region="$(_aws-region)"

  log_group_list="$(command aws --region "$aws_region" logs describe-log-groups \
    --query 'logGroups[].[logGroupName, logGroupArn]' \
    --output text)" || return 1

  if [[ -z "$log_group_list" ]]; then
    echo "No CloudWatch log groups found" >&2
    return 1
  fi

  selected="$(print -r -- "$log_group_list" | fzf \
    --delimiter=$'\t' \
    --with-nth=1 \
    --multi=10 \
    --height 40% \
    --reverse \
    --header 'Select up to 10 log groups (Tab to toggle, Enter to start)' | cut -f2)" || return 1
  [[ -n "$selected" ]] || return 1

  log_groups=("${(@f)selected}")

  if (( print_only )); then
    # (@q-) quotes each element on its own (minimal quoting) before (j) joins
    # them: log group ARNs end in `:*`, which the shell would otherwise try to
    # glob once the user hits Enter.
    cmd="aws --region $aws_region logs start-live-tail --log-group-identifiers ${(j: :)${(@q-)log_groups}}"
    (( ${#extra_args} )) && cmd="$cmd ${(j: :)${(@q-)extra_args}}"
    print -r -- "$cmd"
    return 0
  fi
  command aws --region "$aws_region" logs start-live-tail --log-group-identifiers "${log_groups[@]}" "${extra_args[@]}"
}

# `^j l`: expand the Live Tail command onto the command line (the user presses Enter).
function _aws-live-tail-widget() {
  local cmd
  cmd="$(aws-live-tail --print)" || { zle reset-prompt; return 1; }
  if [[ -n "$cmd" ]]; then
    BUFFER="$cmd"
    CURSOR=${#BUFFER}
  fi
  zle reset-prompt
}
zle -N _aws-live-tail-widget
bindkey '^j^l' _aws-live-tail-widget

# Pick a CloudWatch Logs log group with fzf and expand
# `aws logs tail <log group> --follow --since <since>` onto the command line,
# leaving room to append --filter-pattern and friends before pressing Enter.
# Usage: aws-logs-tail [since] [--print]
#   since  : anything `aws logs tail --since` accepts (10m, 3h, 1d, ISO 8601).
#            When omitted, pick one from a preset list with fzf.
#   --print: emit the command to stdout instead of pushing it onto the buffer
#            (used by the ZLE widget below).
# The region resolved for the log group listing is pinned into the expanded
# command, so the tail cannot end up pointed at a different region.
function aws-logs-tail() {
  local arg since aws_region log_group_list log_group cmd
  local print_only=0

  for arg in "$@"; do
    if [[ "$arg" == "--print" ]]; then
      print_only=1
    else
      since="$arg"
    fi
  done

  setopt local_options pipe_fail
  _aws-require-fzf || return 1
  aws_region="$(_aws-region)"

  log_group_list="$(command aws --region "$aws_region" logs describe-log-groups \
    --query 'logGroups[].logGroupName' \
    --output text)" || return 1

  if [[ -z "$log_group_list" ]]; then
    echo "No CloudWatch log groups found" >&2
    return 1
  fi

  # `--output text` returns the names tab-separated on a single line.
  log_group="$(print -r -- "$log_group_list" | tr '\t' '\n' | fzf \
    --height 40% \
    --reverse \
    --header 'Select a log group')" || return 1

  if [[ -z "$log_group" ]]; then
    echo "cancelled" >&2
    return 1
  fi

  if [[ -z "$since" ]]; then
    since="$(print -l 5m 15m 30m 1h 3h 1d | fzf \
      --height 40% \
      --reverse \
      --header 'Select the --since window')" || return 1

    if [[ -z "$since" ]]; then
      echo "cancelled" >&2
      return 1
    fi
  fi

  cmd="aws --region $aws_region logs tail ${(q-)log_group} --follow --since ${(q-)since}"
  if (( print_only )); then
    print -r -- "$cmd"
    return 0
  fi
  print -S "$cmd"
  print -z "$cmd"
}

# `^j t`: expand the tail command onto the command line (the user presses Enter).
function _aws-logs-tail-widget() {
  local cmd
  cmd="$(aws-logs-tail --print)" || { zle reset-prompt; return 1; }
  if [[ -n "$cmd" ]]; then
    BUFFER="$cmd"
    CURSOR=${#BUFFER}
  fi
  zle reset-prompt
}
zle -N _aws-logs-tail-widget
bindkey '^j^t' _aws-logs-tail-widget

# List the aws-cli utility functions defined in this file, with their
# keybinding and the first line of their doc comment.
# The listing is parsed out of this file at call time, so it cannot drift from
# the definitions. Internal helpers (leading `_`) are omitted.
function aws-help() {
  local file="${_AWS_UTILS_FILE:-${(%):-%x}}"
  if [[ ! -f "$file" ]]; then
    echo "cannot locate aws.sh (got: ${file:-empty})" >&2
    return 1
  fi

  print -r -- "aws-cli utility functions ($file)"
  print -r --

  # \047 is a single quote; it keeps the awk program itself quote-free.
  awk -v cols="${COLUMNS:-100}" '
    # Join the wrapped doc-comment lines up to the end of the first sentence.
    /^# / {
      line = substr($0, 3)
      if (!blk) { blk = 1; sum = ""; done = 0 }
      if (!done) {
        if (line ~ /^Usage:/) {
          done = 1
        } else {
          sum = (sum == "" ? line : sum " " line)
          if (sum ~ /\.$/) done = 1
        }
      }
      next
    }
    /^function [a-z]/ {
      name = $2
      sub(/\(\)$/, "", name)
      order[++n] = name
      summary[name] = sum
      if (length(name) > width) width = length(name)
      blk = 0; sum = ""
      next
    }
    /^bindkey / {
      key = $2
      gsub(/\047/, "", key)
      fn = $3
      sub(/^_/, "", fn)
      sub(/-widget$/, "", fn)
      keys[fn] = key
      next
    }
    { blk = 0; sum = "" }
    END {
      room = cols - (width + 14)
      for (i = 1; i <= n; i++) {
        fn = order[i]
        sum = summary[fn]
        if (room > 1 && length(sum) > room) sum = substr(sum, 1, room - 1) "…"
        printf "  %-*s  %-6s  %s\n", width, fn, (fn in keys ? keys[fn] : "-"), sum
      }
    }
  ' "$file"
}
