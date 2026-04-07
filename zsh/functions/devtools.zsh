function pet-select() {
  BUFFER=$(pet search --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle redisplay
}
zle -N pet-select
stty -ixon
bindkey '^x^p' pet-select

function flutter-emulator-launch() {
  local selected_emulator=$(flutter emulators | grep • | fzf --query="$LBUFFER")

  if [ -n "$selected_emulator" ]; then
    BUFFER="flutter emulators --launch ${selected_emulator}"
    zle accept-line
  fi

  zle reset-prompt
}
zle -N flutter-emulator-launch
bindkey "^f^l" flutter-emulator-launch

function launch-mitmproxy() {
    sudo networksetup -setwebproxy Wi-Fi localhost 8080
    sudo networksetup -setsecurewebproxy Wi-Fi localhost 8080
    sudo networksetup -setwebproxystate Wi-Fi on
    sudo networksetup -setsecurewebproxystate Wi-Fi on
    mitmproxy
    sudo networksetup -setwebproxystate Wi-Fi off
    sudo networksetup -setsecurewebproxystate Wi-Fi off
}
