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
# export JAVA_HOME=`/usr/libexec/java_home -v "1.8" -F`

#
# * Flutter
#
export FLUTTER_SDK=~/src/github.com/flutter/flutter
export DART_SDK=$FLUTTER_SDK/bin/cache/dart-sdk

#
# * OpenAI
#
# export OPENAI_API_KEY=`envchain openai env | grep OPENAI_API_KEY | sed 's/.*=//'`

path=(    
    $HOME/bin(N-/)
    $HOME/.local/bin(N-/)
    $HOME/.cargo/env(N-/)
    $HOME/.cargo/bin(N-/)
    $HOME/bin/FDK/Tools/osx(N-/)
    $GOPATH/bin(N-/)
    $FLUTTER_SDK/bin(N-/)
    $DART_SDK/bin(N-/)
    $ANDROID_HOME/platform-tools(N-/)
    $ANDROID_HOME/ndk-bundle(N-/)
    $JAVA_HOME/bin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    /opt/homebrew/opt/mysql-client/bin(N-/)
    $path
)
. "$HOME/.cargo/env"
