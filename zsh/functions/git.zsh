function git-checkout() {
    g checkout B;
    zle reset-prompt
}
zle -N git-checkout
bindkey '^g^o' git-checkout

function git-pull() {
    g pull origin B;
    zle reset-prompt
}
zle -N git-pull
bindkey '^g^p' git-pull

function git-rebase() {
    g rebase B;
    zle reset-prompt
}
zle -N git-rebase
bindkey '^g^r' git-rebase
