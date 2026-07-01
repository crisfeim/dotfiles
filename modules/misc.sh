coderunner() { open -a /Applications/Apps/dev/CodeRunner.app "$@" }
xcode() { open -a Xcode $1 }
nova() { open -a "/Applications/Apps/dev/Nova 9.6.app" "$@" }
iina() { open -a /Applications/Apps/misc/IINA.app "$@" }
zed() { open -a /Applications/Apps/dev/Zed.app "$@" }

o() {
  local app=$(find /Applications /System/Applications ~/Applications -maxdepth 3 -iname "*$1*.app" 2>/dev/null | head -n 1)

  if [[ -n "$app" ]]; then
    echo "Abriendo: $app"
    open "$app"
  else
    echo "No se encontró ninguna aplicación que coincida con '$1'"
    return 1
  fi
}

r() {
	# Wrapper around https://github.com/keith/reminders-cli/tree/main/Sources
  local default_list="rappels"
  case "$1" in
    "") reminders show "$default_list" ;;
    "all") reminders show-all ;;
    "lists") reminders show-lists ;;
    "list") reminders show "$2" ;;
    +*) reminders complete "$default_list" "${1#+}" ;;
    -*) reminders delete "$default_list" "${1#-}" ;;
    e*)
      local id="${1#e}"
      local item_info=$(reminders show "$default_list" | grep "^$id:")
      local old_text=$(echo "$item_info" | cut -d' ' -f2-)
      local tmpfile=$(mktemp)
      echo "$old_text" > "$tmpfile"
      vi "$tmpfile"
      reminders edit "$default_list" "$id" "$(cat "$tmpfile")"
      rm "$tmpfile"
      ;;
    *) reminders add "$default_list" "$*" ;;
  esac
}


k() { lsof -ti :$1 | xargs -r kill -9 }


files() {
    local target="${1:-.}"

    if [ ! -d "$target" ]; then
        echo "Error: '$target' no es un directorio válido."
        return 1
    fi

    find "$target" -not -path '*/.*' | sed \
        -e "s/[^-][^\/]*\//│  /g" \
        -e "s/│  \([^│]\)/├── \1/" \
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

# Focus
focus() {
    osascript -e 'display notification "Se ha iniciado la sesión de trabajo" with title "Sesión de trabajo"'
    osascript -e 'tell application "System Events" to set quitList to name of every application process whose background only is false and name is not "iTerm2" and name is not "Focus"' -e 'repeat with appName in quitList' -e 'tell application appName to quit' -e 'end repeat'
    open -a "IINA" /Users/cristian/Music/Music/Media.localized/Music/Focus/Youtube/Chimenea.m4a
    grayscale
}

chimenea() { iina ~/Music/Music/Media.localized/Music/Focus/Youtube/Chimenea.m4a }
anima() { iina ~/"Music/Music/Media.localized/Music/Marco Frisina/Unknown Album/Anima Christi.mp3" }
gregorian() { iina ~/"Music/Music/Media.localized/Music/Benedictine Monks/Unknown Album/Gregorian Chants of the Benedictine Monks.mp3" }
