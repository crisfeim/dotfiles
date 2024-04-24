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

# Plural so it doesn't conflict with default "set" cmd
sets() {
	if [ "$1" = "screenshots" ]; then
		defaults write com.apple.screencapture location $2
	else
		echo $unhandledMsg
	fi
}

# Plural so it doesn't conflicts with default "kill" cmd
kills() {
	if [ "$1" = "simulators" ]; then
		xcrun simctl shutdown all
	elif [ "$1" = "server" ]; then
		#netstat -vanp tcp | grep $2;
		lsof -i tcp:$2;
		kill -9 $(lsof -ti:$2)
	else
		echo $unhandledMsg
	fi
}

run() {
	if [ "$1" = "php" ]; then
		php -S localhost:$2
	else
		echo $unhandledMsg
	fi
}

query() { search $1 }
search() { grep -rn $1 . }

showDotfiles() {
	defaults write com.apple.Finder AppleShowAllFiles true;
	killall Finder	
}

hideDotfiles() {
	defaults write com.apple.Finder AppleShowAllFiles false;
	killall Finder	
}

decodeProvision() { security cms -D -i  $1 }
