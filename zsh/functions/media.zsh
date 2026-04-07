function mpv-music() {
    local PLAYLISTDIR=~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/yt-playlist
    local playlist=$(ls $PLAYLISTDIR/*.m3u | fzf-tmux -d --reverse --no-sort +m --prompt="Playlist > ")
    if [ $# = 0 ]; then
		mpv \
            --quiet \
            --no-video \
            --ytdl-format="worstvideo+bestaudio" \
            --shuffle \
            --playlist="$playlist" \
            --loop-playlist
    elif [ $# = 1 ]; then
		mpv \
            --no-video \
            --ytdl-format="worstvideo+bestaudio" \
            --quiet \
            $1 \
		cd -
    else
		echo 'usage: mpv-music [youtube-url]'
    fi
}

function mpv-video() {
    local PLAYLISTDIR=~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/ObsidianVault/yt-playlist
    local playlist=$(ls $PLAYLISTDIR/*.m3u | fzf-tmux -d --reverse --no-sort +m --prompt="Playlist > ")
	if [ $# = 0 ]; then
		mpv \
            --quiet \
            --ytdl-format="[height<=480]+bestaudio" \
            --shuffle \
            --playlist="$playlist" \
            --loop-playlist
    elif [ $# = 1 ]; then
		mpv \
            --quiet \
            --ytdl-format="[height<=480]+bestaudio" \
            $1 \
		cd -
    else
		echo 'usage: mpv-video [youtube-url]'
    fi
}

function mpv-quit() {
    pkill -SIGUSR1 -f mpv
}

function video2gif() {
    local gif=$(echo "$1" | sed -e 's/\.[^.]*$/.gif/')
    ffmpeg -i $1 -vf scale=320:-1 -r 10 "$gif"
}
