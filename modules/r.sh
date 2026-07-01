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
