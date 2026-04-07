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
