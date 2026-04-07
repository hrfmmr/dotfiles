function reflect_current_dir() {
    echo -ne "\033]0;$(pwd | rev | awk -F \/ '{print $1}'| rev)\007"
}

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

function mkcd() {
	mkdir $1;
	cd $1;
}

function ptr() {
    pt -0 -l "$1" | xargs -0 perl -pi.bak -e "s/$1/$2/g";
}

function rgr() {
    rg -0 -l "$1" | xargs -0 perl -pi.bak -e "s/$1/$2/g";
}

function restore_bak() {
    find . -type f -exec rename -fv 's/\.bak$//' {} \;
}
