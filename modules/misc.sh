unhandledMsg="Unhandled command";
show() {
	if [ "$1" = "dotfiles" ]; then
		defaults write com.apple.Finder AppleShowAllFiles true;
		killall Finder
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

alias .='marta .'

rm() {
		for arg in "$@"; do
				if [[ "$arg" == "." ]]; then
						local dir=$PWD; cd .. && command rm -rf "$dir"
				elif [[ "$arg" == */ ]]; then
						command rm -rf "$arg"
				else
						command rm "$arg"
				fi
		done
}

mkdir() {
		command mkdir "$@"
		[ $? -ne 0 ] && return
		local last_arg="${@[-1]}"

		if [[ "$last_arg" == */ ]]; then
				cd "$last_arg"
		fi
}


files() {
		local target="${1:-.}"

		if [ ! -d "$target" ]; then
				echo "Error: '$target' no es un directorio válido."
				return 1
		fi

		find "$target" | sed \
				-e "s/[^-][^\/]*\//  |/g" \
				-e "s/|\([^ ]\)/|-\1/"
}

folders() { lt $1 }

lt() {
		local target="${1:-.}"

		if [ ! -d "$target" ]; then
				echo "Error: '$target' is not a valid directory."
				return 1
		fi

		ls -R "$target" | grep ":$" | sed \
				-e 's/:$//' \
				-e 's/[^-][^\/]*\//  /g' \
				-e 's/^/   /'
}

clean() {
		if [[ "$1" == "xcode" ]]; then
				 ~/Library/Developer/Xcode/DerivedData
				 ~/Library/Caches/org.swift.swiftpm
				 ~/Library/Caches/com.apple.dt.Xcode

				for pkg in ~/Library/Developer/Xcode/DerivedData/*/SourcePackages(/N); do
						 "$pkg"
				done

				xcrun simctl delete unavailable
		else
				echo $unhandledMsg
		fi
}

# Fast rm
frm() {
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

zap() { frm $1 }
