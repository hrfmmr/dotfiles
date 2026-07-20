# ============ local overlay ==============
if [ -d "$HOME/.zsh.local.d" ]; then
    for _zsh_local_file in "$HOME"/.zsh.local.d/*.zsh(N); do
        source "$_zsh_local_file"
    done
    unset _zsh_local_file
fi
# ============ local overlay ==============

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
KEYTIMEOUT=40

# NOTE: prompt is managed by Starship (see the end of this file)

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

ZSH_CONFIG_DIR="${${(%):-%N}:A:h}"
source "$ZSH_CONFIG_DIR/functions/shell.zsh"

# hooks
autoload -Uz add-zsh-hook
autoload -Uz chpwd_recent_dirs cdr 
add-zsh-hook chpwd chpwd_recent_dirs 
add-zsh-hook precmd reflect_current_dir
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
# * aliases
#
alias e='exa'
alias l='exa -algh'
alias ll='ls -alFG'
alias mkdir='mkdir -p'
alias hist='history 1'
alias zmv='noglob zmv -W'
alias weather='curl -4 wttr.in'
alias v='nvim'
alias vim='nvim'
alias va='vagrant'
alias updatedb='sudo /usr/libexec/locate.updatedb'
alias g='git'
alias -g B='`git branch -a | fzf --prompt "GIT BRANCH>" | head -n 1 | sed -e "s/^\*\s*//g"`'
alias -g LR='`git branch -a | fzf --query "remotes/ " --prompt "GIT REMOTE BRANCH>" | head -n 1 | sed "s/remotes\/[^\/]*\/\(\S*\)/\1 \0/"`'
alias f='fzf'
alias fe='file=$(fd -t f | fzf +m) && nvim "$file"'
alias fcd='dir=$(fd -t d| fzf +m) && cd "$dir"'
alias rg='rg --smart-case --hidden'
alias be='bundle exec'
alias d='docker'
alias dc='docker compose'
alias lzd='lazydocker'
alias gg='lazygit'
alias gd='gh dash'
alias tf='terraform'
alias py='poetry'
alias ecs='ecspresso'
alias gg='lazygit'
alias gd='gh dash'
alias codex='EDITOR=nvim codex'
alias claude='EDITOR=nvim claude'
for zsh_function_file in git.zsh navigation.zsh github.zsh devtools.zsh media.zsh; do
    source "$ZSH_CONFIG_DIR/functions/$zsh_function_file"
done

#
# * mise
#
eval "$(mise activate zsh)"

#
# * direnv
#
if which direnv > /dev/null; then eval "$(direnv hook zsh)"; fi

#
# * z
#
if brew --prefix z > /dev/null; then source $(brew --prefix)/etc/profile.d/z.sh; fi

#
# * fzf
#
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude ".git" ""'
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude ".git" ""'
export FZF_DEFAULT_OPTS="--reverse --inline-info"
[ -n "$NVIM_LISTEN_ADDRESS" ] && FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --no-height"

#
# * yarn
#
if hash yarn 2>/dev/null; then export PATH="$PATH:`yarn global bin`"; fi

#
# * pet
#

#
# * Plugins (antidote)
#
antidote_home="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote"
zsh_plugins="${ZDOTDIR:-$HOME}/.zsh_plugins"
if [[ -e "$antidote_home/antidote.zsh" ]]; then
  if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
    source "$antidote_home/antidote.zsh"
    if antidote bundle <"${zsh_plugins}.txt" >| "${zsh_plugins}.zsh.tmp"; then
      mv -f "${zsh_plugins}.zsh.tmp" "${zsh_plugins}.zsh"
    else
      rm -f "${zsh_plugins}.zsh.tmp"
    fi
  fi
fi
[[ -r "${zsh_plugins}.zsh" ]] && source "${zsh_plugins}.zsh"
unset antidote_home zsh_plugins

if (( ${+widgets[history-substring-search-up]} )); then
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
fi

#
# * Starship prompt
#
eval "$(starship init zsh)"
