unhandledMsg="Unhandled command";
show() {
	if [ "$1" = "dotfiles" ]; then
		showDotfiles
	else
		echo $unhandledMsg
	fi
}

hide() {
	if [ "$1" = "dotfiles" ]; then
		hideDotfiles
	else
		echo $unhandledMsg
	fi
}

showDotfiles() {
	defaults write com.apple.Finder AppleShowAllFiles true;
	killall Finder
}

hideDotfiles() {
	defaults write com.apple.Finder AppleShowAllFiles false;
	killall Finder
}

# Plural so it doesn't conflict with default "set" cmd
sets() {
	if [ "$1" = "screenshots" ]; then
		defaults write com.apple.screencapture location $2
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

query() { search $1 }
search() { grep -rn $1 . }

downloadYT() {
	yt-dlp -f 'bestvideo[height<=720]+bestaudio' --merge-output-format mp4 -o '~/Downloads/%(title)s.%(ext)s' $1
}

decodeProvision() { security cms -D -i  $1 }

@() {
  local TARGET_NAME="@$1"
  local BASE_DIR="$HOME/icloud"

  if [[ ! -d "$BASE_DIR" ]]; then
    echo "❌ La carpeta base no existe: $BASE_DIR"
    return 1
  fi

  local MATCH
  MATCH=$(find -L "$BASE_DIR" -type d -iname "$TARGET_NAME" 2>/dev/null | head -n 1)

  if [[ -z "$MATCH" ]]; then
    echo "❌ No se encontró ninguna carpeta llamada '$TARGET_NAME' en '$BASE_DIR'"
    return 1
  fi

  cd "$MATCH" || return 1
}
