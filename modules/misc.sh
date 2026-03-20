unhandledMsg="Unhandled command";
show() {
	if [ "$1" = "dotfiles" ]; then
		defaults write com.apple.Finder AppleShowAllFiles true;
		killall Finder
	else
		echo $unhandledMsg
	fi
}

mki() {
	if [ "$1" = "git" ]; then
		cp ~/dotfiles/misc/ignore-template.txt .gitignore
	elif [ "$1" = "fossil" ]; then
		mkdir -p .fossil-settings
		cp ~/dotfiles/misc/ignore-template.txt .fossil-settings/ignore-glob
	else
		echo $unhandledMsg
	fi
}

hide() {
	if [ "$1" = "dotfiles" ]; then
		defaults write com.apple.Finder AppleShowAllFiles false;
		killall Finder
	else
		echo $unhandledMsg
	fi
}

k() {
	if [ "$1" = "simulators" ]; then
		xcrun simctl shutdown all
	elif [ "$1" = "port" ]; then
		lsof -ti :$2 | xargs -r kill -9
	elif [ "$1" = "hugo" ]; then
		killall -9 hugo;
		killall hugo;
		pkill hugo
	else
		echo $unhandledMsg
	fi
}

rm() {
		for arg in "$@"; do
				if [[ "$arg" == */ ]]; then
						zap "$arg"
				else
						command rm "$arg"
				fi
		done
}

zap() {
		local target="${1%/}"
		if [[ -d "$target" ]]; then
				local empty
				empty=$(mktemp -d) || return 1
			
				# defers removal
				trap 'command rm -rf "$empty"' EXIT INT TERM

				rsync -a --delete "$empty/" "$target/"
				command rm -rf "$target"
		else
				echo "Error: '$target' is not a valid directory."
				return 1
		fi
}