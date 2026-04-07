function checkout-ghissue-fzf() {
  local selected_issue=$(hub issue --format='%sC %i %t labels:%l milestone:%Mt | %as  %Nc%n' | fzf --query="$LBUFFER")

  if [ -n "$selected_issue" ]; then
    issue=$(awk '{print $1}' <<< "$selected_issue" | sed -E 's/^#([0-9]+)/\1/')
    BUFFER="git checkout -b feature/${issue}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N checkout-ghissue-fzf
bindkey "^g^b" checkout-ghissue-fzf

function browse-ghissue-fzf() {
  local selected_issue=$(hub issue --format='%sC %i %t labels:%l milestone:%Mt | %as  %Nc%n' | fzf --query="$LBUFFER")

  if [ -n "$selected_issue" ]; then
    issue=$(awk '{print $1}' <<< "$selected_issue" | sed -E 's/^#([0-9]+)/\1/')
    BUFFER="hub browse -- issues/${issue}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N browse-ghissue-fzf
bindkey "^g^i" browse-ghissue-fzf

function browse-ghpr-fzf() {
  local selected_pr=$(hub pr list --format='%sC %i %t labels:%l milestone:%Mt | author:@%au  %Nc%n' | fzf --query="$LBUFFER")

  if [ -n "$selected_pr" ]; then
    pr=$(awk '{print $1}' <<< "$selected_pr" | sed -E 's/^#([0-9]+)/\1/')
    BUFFER="hub browse -- pull/${pr}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N browse-ghpr-fzf
bindkey "^g^l" browse-ghpr-fzf

function codex-review-pr() {
  if [ $# -ne 1 ]; then
    echo "usage: codex-review-pr <pull_request_url>" >&2
    return 1
  fi

  local pr_url="$1"
  local org_name repo_name pr_number
  if [[ ! "$pr_url" =~ '^https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)([/?#].*)?$' ]]; then
    echo "invalid GitHub PR URL: $pr_url" >&2
    return 1
  fi

  org_name="${match[1]}"
  repo_name="${match[2]}"
  pr_number="${match[3]}"

  local tmux_server="review"
  local session_name="$repo_name"
  local window_name="${repo_name}#${pr_number}"
  local session_exists=0
  local window_exists=0
  if command tmux -L "$tmux_server" has-session -t "$session_name" 2>/dev/null; then
    session_exists=1
    if command tmux -L "$tmux_server" list-windows -t "$session_name" -F '#{window_name}' | grep -Fxq "$window_name"; then
      window_exists=1
    fi
  fi

  if [ "$window_exists" -eq 0 ]; then
    local repo_root="$HOME/src/github.com/${org_name}/${repo_name}"
    if ! command git -C "$repo_root" rev-parse --show-toplevel >/dev/null 2>&1; then
      echo "repository root not found: $repo_root" >&2
      return 1
    fi

    local branch_name="review-${pr_number}"
    local worktree_path
    local created_worktree=0
    worktree_path=$(command git -C "$repo_root" worktree list --porcelain | awk -v branch="refs/heads/${branch_name}" '
      $1 == "worktree" { path = $2 }
      $1 == "branch" && $2 == branch { print path; exit }
    ')

    if [ -n "$worktree_path" ] && [ ! -d "$worktree_path" ]; then
      command git -C "$repo_root" worktree prune
      worktree_path=""
    fi

    if [ -z "$worktree_path" ]; then
      local worktree_name="${branch_name}-$(command date +%Y%m%d%H%M)"
      worktree_path="${repo_root:h}/${worktree_name}"
      created_worktree=1
      command git -C "$repo_root" worktree add --detach "$worktree_path" || return 1
    fi

    if ! (
      cd "$worktree_path" || exit 1
      command gh pr checkout "$pr_url" --branch "$branch_name" --force -R "${org_name}/${repo_name}"
    ); then
      if [ "$created_worktree" -eq 1 ]; then
        command git -C "$repo_root" worktree remove -f "$worktree_path"
      fi
      return 1
    fi

    local codex_prompt="\$review --mode pr-comment --target-pr ${pr_number}"
    local shell_cmd="direnv allow . 2>/dev/null; prompt=${(q)codex_prompt}; codex \"\$prompt\""
    local terminal_cmd="terminal zsh -lc ${(q)shell_cmd}"
    local startup_cmd="nvim -c ${(q)terminal_cmd} -c startinsert"

    if [ "$session_exists" -eq 0 ]; then
      command tmux -L "$tmux_server" new-session -d -s "$session_name" -c "$worktree_path" -n "$window_name" "$startup_cmd" || return 1
    else
      command tmux -L "$tmux_server" new-window -d -t "$session_name" -n "$window_name" -c "$worktree_path" "$startup_cmd" || return 1
    fi
  fi

  local window_index
  window_index=$(command tmux -L "$tmux_server" list-windows -t "$session_name" -F '#{window_index} #{window_name}' | awk -v name="$window_name" '$2 == name { print $1; exit }')
  if [ -n "$window_index" ]; then
    command tmux -L "$tmux_server" select-window -t "${session_name}:${window_index}"
  fi

  env -u TMUX tmux -L "$tmux_server" attach-session -t "$session_name"
}
