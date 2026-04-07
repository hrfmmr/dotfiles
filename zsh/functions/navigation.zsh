function fzf-execute-history() {
    local item
    item=$(builtin history -n -r 1 | fzf --query="$LBUFFER")

    if [[ -z "$item" ]]; then
        return 1
    fi

    BUFFER="$item"
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-execute-history
bindkey '^x^b' fzf-execute-history

function fzf-cdr() {
    local item
    item=$(cdr -l | sed 's/^[^ ]\{1,\} \{1,\}//' | fzf)

    if [[ -z "$item" ]]; then
        return 1
    fi

    BUFFER="cd -- $item"
    CURSOR=$#BUFFER
    zle accept-line
}

function fzf-z-search() {
    local res=$(z | sort -rn | cut -c 12- | fzf)
    if [ -n "$res" ]; then
        BUFFER+="cd $res"
        zle accept-line
    else
        return 1
    fi
}
zle -N fzf-cdr
bindkey '^x^d' fzf-cdr
# zle -N fzf-z-search
# bindkey '^x^d' fzf-z-search

function ghq-fzf() {
  local selected_dir=$(ghq list | fzf --query="$LBUFFER")

  if [ -n "$selected_dir" ]; then
    BUFFER="cd $(ghq root)/${selected_dir}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N ghq-fzf
bindkey "^x^h" ghq-fzf

function worktree-fzf() {
  local selected_dir=$(git worktree list | awk '{print $1}' | fzf --query="$LBUFFER")

  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N worktree-fzf
bindkey "^g^w" worktree-fzf
