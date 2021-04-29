typeset -U path cdpath fpath manpath

#
# homebrew
#
export HOMEBREW_NO_AUTO_UPDATE=1

#
# Locale
#
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
#
# XDG
#
export XDG_CONFIG_HOME=$HOME/.config

#
# * go
#
export GOPATH=$HOME
export GO111MODULE=on
export GOENV_DISABLE_GOPATH=1

#
# * postgresql
#
export PGDATA=/usr/local/var/postgres
export PGHOST=localhost

#
# * android
#
export ANDROID_HOME=~/Library/Android/sdk
export JAVA_HOME=`/usr/libexec/java_home -v "1.8" -F`

#
# * Flutter
#
export FLUTTER_SDK=~/src/github.com/flutter/flutter
export DART_SDK=$FLUTTER_SDK/bin/cache/dart-sdk

path=(    
    $HOME/bin(N-/)
    $HOME/.local/bin(N-/)
    $HOME/.pyenv/bin(N-/)
    $HOME/.pyenv/shims(N-/)
    $HOME/.rbenv/bin(N-/)
    $HOME/.rbenv/shims(N-/)
    $HOME/.goenv/bin(N-/)
    $HOME/.goenv/shims(N-/)
    $HOME/.nodebrew/current/bin(N-)
    $HOME/bin/FDK/Tools/osx(N-/)
    $GOPATH/bin(N-/)
    $FLUTTER_SDK/bin(N-/)
    $DART_SDK/bin(N-/)
    $ANDROID_HOME/platform-tools(N-/)
    $ANDROID_HOME/ndk-bundle(N-/)
    $JAVA_HOME/bin(N-/)
    /usr/local/Cellar/git/2.3.0/share/git-core/contrib/workdir(N-/)
    /usr/local/Cellar/rsync/3.1.2/bin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    /usr/local/mysql/bin(N-/)
    /Applications/Vagrant/bin(N-/)
    $path
)
