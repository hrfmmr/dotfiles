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

  if ! command -v fzf >/dev/null; then
    echo "ERROR: 'fzf' is not installed" >&2
    return 1
  fi

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

  prefix="AWS_PROFILE=$profile "
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
  cmd="command aws sso login --profile $profile && export AWS_PROFILE=$profile"
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
# Usage: aws-live-tail [extra options for `aws logs start-live-tail`]
# Up to 10 log groups can be selected, matching the AWS Live Tail limit.
# Falls back to ap-northeast-1 when AWS_REGION / AWS_DEFAULT_REGION are unset.
function aws-live-tail() {
  local aws_region log_group_list selected
  local -a log_groups

  setopt local_options pipe_fail
  aws_region="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-1}}"

  if ! command -v fzf >/dev/null; then
    echo "ERROR: 'fzf' is not installed" >&2
    return 1
  fi

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
  command aws --region "$aws_region" logs start-live-tail --log-group-identifiers "${log_groups[@]}" "$@"
}
