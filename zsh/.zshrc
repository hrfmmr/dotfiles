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

# enable cdr
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr 
add-zsh-hook chpwd chpwd_recent_dirs 
zstyle ':chpwd:*' recent-dirs-max 500
zstyle ':chpwd:*' recent-dirs-default true
zstyle ':chpwd:*' recent-dirs-pushd true

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

# switch branch with `git checkout B`
alias g='git'
alias f='fzf'
alias ag='ag --smart-case --hidden'
alias -g B='`git branch -a | peco --prompt "GIT BRANCH>" | head -n 1 | sed -e "s/^\*\s*//g"`'
alias -g LR='`git branch -a | peco --query "remotes/ " --prompt "GIT REMOTE BRANCH>" | head -n 1 | sed "s/remotes\/[^\/]*\/\(\S*\)/\1 \0/"`'

#
# * aliases
#
alias ll='ls -alFG'
alias mkdir='mkdir -p'
alias hist='history 1'
alias zmv='noglob zmv -W'
alias brew="env PATH=${PATH/$HOME/\.pyenv\/shims:/} brew"
alias weather='curl -4 wttr.in'
alias nvim='nvim --cmd "lang en_US"'
alias v='nvim'
alias vim='nvim'
alias va='vagrant'
alias updatedb='sudo /usr/libexec/locate.updatedb'

function mkcd() {
	mkdir $1;
	cd $1;
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
# * peco
#
# https://github.com/peco/peco/releases
#
# find recent executed command
function peco-execute-history() {
    local item
    item=$(builtin history -n -r 1 | peco --query="$LBUFFER")

    if [[ -z "$item" ]]; then
        return 1
    fi

    BUFFER="$item"
    CURSOR=$#BUFFER
    # execute command immidiately
    # zle accept-line
}
zle -N peco-execute-history
bindkey '^x^b' peco-execute-history

# find recent moved directory 
function peco-cdr() {
    local item
    item=$(cdr -l | sed 's/^[^ ]\{1,\} \{1,\}//' | peco)

    if [[ -z "$item" ]]; then
        return 1
    fi

    BUFFER="cd -- $item"
    CURSOR=$#BUFFER
    zle accept-line
}
zle -N peco-cdr
bindkey '^x^d' peco-cdr

# switch peco window
function peco-tmux() {
    local i=$(tmux lsw | awk '/active.$/ {print NR-1}')
    local f='#{window_index}: #{window_name}#{window_flags} #{pane_current_path}'
    tmux lsw -F "$f" \
        | anyframe-selector-auto "" --initial-index $i \
        | cut -d ':' -f 1 \
        | anyframe-action-execute tmux select-window -t
}
zle -N peco-tmux
bindkey '^x^w' peco-tmux


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
# * docker
#
if which docker-machine > /dev/null; then eval "$(docker-machine env default)"; fi

#
# * fzf
#
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='ag --smart-case --hidden -g ""'
export FZF_DEFAULT_OPTS="--reverse --inline-info"
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

#
# * yarn
#
if hash yarn 2>/dev/null; then export PATH="$PATH:`yarn global bin`"; fi
