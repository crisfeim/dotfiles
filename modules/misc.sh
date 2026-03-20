unhandledMsg="Unhandled command";
show() {
	if [ "$1" = "dotfiles" ]; then
		defaults write com.apple.Finder AppleShowAllFiles true;
		killall Finder
	else
		echo $unhandledMsg
	fi
}

mk() {
	if [ "$1" = "gitignore" ]; then
		cp ~/dotfiles/misc/gitignore.md .gitignore
	elif [ "$1" = "fossilignore" ]; then
		mkdir -p .fossil-settings
		cp ~/dotfiles/misc/fossilignore.txt .fossil-settings/ignore-glob
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

# Quick navigation Navigation
@() {
  local TARGET_NAME="@$1"
  local BASE_DIR="$HOME/icloud"

  if [[ ! -d "$BASE_DIR" ]]; then
    echo "❌ Directory doesn't exists: $BASE_DIR"
    return 1
  fi

  local MATCH
  MATCH=$(find -L "$BASE_DIR" -type d -iname "$TARGET_NAME" 2>/dev/null | head -n 1)

  if [[ -z "$MATCH" ]]; then
    echo "❌ Not found '$TARGET_NAME' inside '$BASE_DIR'"
    return 1
  fi

  cd "$MATCH" || return 1
}
