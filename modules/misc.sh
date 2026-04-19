
e() { nvim $1 }
k() { lsof -ti :$1 | xargs -r kill -9 }


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

alias t='python3 ~/dotfiles/misc/t/t.py --task-dir ~/tasks --list tasks'
alias tf='python3 ~/dotfiles/misc/tf.py'

anima() { iina ~/"Music/Music/Media.localized/Music/Marco Frisina/Unknown Album/Anima Christi.mp3" }
gregorian() { iina ~/"Music/Music/Media.localized/Music/Benedictine Monks/Unknown Album/Gregorian Chants of the Benedictine Monks.mp3" }
