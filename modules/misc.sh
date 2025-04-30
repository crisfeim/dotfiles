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
		lsof -ti :8080 | xargs -r kill -9
	elif [ "$1" = "hugo" ]; then
		killall -9 hugo;
		killall hugo;
		pkill hugo
	else
		echo $unhandledMsg
	fi
}

serve() {
	if [ "$1" = "php" ]; then
		php -S localhost:$2
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
