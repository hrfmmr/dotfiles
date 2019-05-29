#
# * Options
#
setopt IGNORE_EOF # disable shutdown zsh with ^D
setopt NO_FLOW_CONTROL # disable ^Q/^S flow control
setopt NO_BEEP # disable beep sound

setopt AUTO_CD # enable 'cd' just input the directory's PATH (e.g. $/path/to/dir)
setopt SHARE_HISTORY # sharing command history with other zsh prompts
setopt AUTO_PUSHD # stacking 'cd' directories
setopt PUSHD_IGNORE_DUPS # ignore duplicate directory in AUTO_PUSHD

#
# * Basic Settings
#
#rendering user/host in PROMPT
PROMPT="[%n@%m]%~ $ "

# enable auto-completion
autoload -Uz compinit
compinit

# enable zmv
autoload -Uz zmv

# default completion mode
zstyle ':completion:*:default' menu select=2 # completion mode as menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # ignore case

# including '/' as a word delimiter
autoload -Uz select-word-style
select-word-style default
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

# hooks
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr 
add-zsh-hook chpwd chpwd_recent_dirs 
add-zsh-hook precmd reflect_current_dir
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-pushd true

function reflect_current_dir() {
    echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print $1}'| rev)\007"
}

#
# * History
#
# save command history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_NO_STORE
HISTFILE=~/.zsh_history
HISTSIZE=10000000
SAVEHIST=10000000

#
# * Search
#
# search command history incrementally
bindkey '^r' \
    history-incremental-pattern-search-backward
bindkey '^s' \
    history-incremental-pattern-search-forward
# search command history incrementally (in typing)
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end \
    history-search-end
bindkey "^p" history-beginning-search-backward-end

#
# * Git
#
# rendering current Git branch in RPROMPT
autoload VCS_INFO_get_data_git; VCS_INFO_get_data_git 2> /dev/null
function rprompt-git-current-branch {
        local name st color gitdir action
        if [[ "$PWD" =~ '/\.git(/.*)?$' ]]; then
                return
        fi

        name=`git rev-parse --abbrev-ref=loose HEAD 2> /dev/null`
        if [[ -z $name ]]; then
                return
        fi

        gitdir=`git rev-parse --git-dir 2> /dev/null`
        action=`VCS_INFO_git_getaction "$gitdir"` && action="($action)"

	if [[ -e "$gitdir/rprompt-nostatus" ]]; then
		echo "$name$action "
		return
	fi

        st=`git status 2> /dev/null`
	if [[ -n `echo "$st" | grep "^nothing to"` ]]; then
		color=%F{green}
	elif [[ -n `echo "$st" | grep "^nothing added"` ]]; then
		color=%F{yellow}
	elif [[ -n `echo "$st" | grep "^# Untracked"` ]]; then
                color=%B%F{red}
        else
                color=%F{red}
        fi

        echo "$color$name$action%f%b "
}
setopt prompt_subst
RPROMPT='[`rprompt-git-current-branch`]'


#
# * aliases
#
alias ll='ls -alFG'
alias mkdir='mkdir -p'
alias hist='history 1'
alias zmv='noglob zmv -W'
alias brew="env PATH=${PATH/$HOME/\.pyenv\/shims:/} brew"
alias weather='curl -4 wttr.in'
alias v='nvim'
alias vim='nvim'
alias va='vagrant'
alias updatedb='sudo /usr/libexec/locate.updatedb'
alias g='git'
alias -g B='`git branch -a | fzf --prompt "GIT BRANCH>" | head -n 1 | sed -e "s/^\*\s*//g"`'
alias -g LR='`git branch -a | fzf --query "remotes/ " --prompt "GIT REMOTE BRANCH>" | head -n 1 | sed "s/remotes\/[^\/]*\/\(\S*\)/\1 \0/"`'
alias f='fzf'
alias pt='pt --smart-case --hidden'
alias be='bundle exec'
alias d='docker'
alias d-c='docker-compose'

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

function mkcd() {
	mkdir $1;
	cd $1;
}

function ptr() {
    pt -0 -l "$1" | xargs -0 perl -pi.bak -e "s/$1/$2/g";
}

function restore_bak() {
    find . -type f -exec rename -fv 's/\.bak$//' {} \;
}

#
# * Plugins
#
# Antigen
# https://github.com/zsh-users/antigen
if [[ -f $HOME/.zsh/antigen/antigen.zsh ]]; then
    source $HOME/.zsh/antigen/antigen.zsh
    antigen bundle zsh-users/zsh-syntax-highlighting
    antigen bundle zsh-users/zsh-completions src
    antigen bundle mollifier/anyframe
    antigen apply
fi


#
# * pyenv
#
export PYENV_ROOT=~/.pyenv
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi


#
# * rbenv
#
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

#
# * goenv
#
if which goenv > /dev/null; then eval "$(goenv init -)"; fi

#
# * fzf
#
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='pt --smart-case --hidden -g ""'
export FZF_DEFAULT_OPTS="--reverse --inline-info"
[ -n "$NVIM_LISTEN_ADDRESS" ] && FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --no-height"

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  local file
  file=$(fzf --query="$1" --select-1 --exit-0)
  [ -n "$file" ] && ${EDITOR:-vim} "$file"
}

# fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-*} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# find recent executed command
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

# find recent moved directory 
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
zle -N fzf-cdr
bindkey '^x^d' fzf-cdr

# find ghq directory
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

# find git worktree directory
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

# checkout new branch related to an github issue
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

# browse github issue
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

# browse github pull request
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

#
# * yarn
#
if hash yarn 2>/dev/null; then export PATH="$PATH:`yarn global bin`"; fi

#
# * pet
#
function pet-select() {
  BUFFER=$(pet search --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N pet-select
stty -ixon
bindkey '^x^p' pet-select

#
# zplug
#
source ~/.zplug/init.zsh

# ui
zplug "chrissicool/zsh-256color"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "mafredri/zsh-async", from:github
zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme

# history
zplug "zsh-users/zsh-history-substring-search"
if zplug check "zsh-users/zsh-history-substring-search"; then
    bindkey '^P' history-substring-search-up
    bindkey '^N' history-substring-search-down
fi

# completion
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"

# notifier
zplug "marzocchi/zsh-notify"
zstyle ':notify:*' error-title "😢 Command failed... (in #{time_elapsed} seconds)"
zstyle ':notify:*' success-title "✔ Command finished! (in #{time_elapsed} seconds)"
zstyle ':notify:*' command-complete-timeout 10
zstyle ':notify:*' activate-terminal yes

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load
