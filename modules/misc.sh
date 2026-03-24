
vi() { nvim $1 }

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
		echo "Unhandled"
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

folders() {
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
        echo "Unhandle"
    fi
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

alias t='python3 /usr/local/bin/t/t.py --task-dir ~/tasks --list tasks'

flushcache() { sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder }
coderunner() { open -a /Applications/Apps/dev/CodeRunner.app "$@" }
xcode() { open -a Xcode $1 }
nova() { open -a "/Applications/Apps/dev/Nova 9.6.app" "$@" }
anima() {
    afplay "~/Music/Music/Media.localized/Music/Marco Frisina/Unknown Album/🙏 Anima Christi_ Alma de Cristo.mp3"
}
