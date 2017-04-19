typeset -U path cdpath fpath manpath

#
# XDG
#
export XDG_CONFIG_HOME=$HOME/.config

#
# * go
#
export GOPATH=$HOME/go

path=(    
    /usr/local/Cellar/git/2.3.0/share/git-core/contrib/workdir(N-/)
    /usr/local/Cellar/rsync/3.1.2/bin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    /usr/local/mysql/bin(N-/)
    /Applications/Vagrant/bin(N-/)
    $HOME/bin/FDK/Tools/osx(N-/)
    $HOME/.pyenv/bin(N-/)
    $HOME/.rbenv/bin(N-/)
    $HOME/.nodebrew/current/bin(N-)
    $GOPATH/bin(N-/)
    $HOME/bin(N-/)
    $path
)
