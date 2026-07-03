journal() {
local dir="$HOME/inbox/journal"

case "$1" in
  "last")
    local last_file=$(ls -t "$dir" | head -n 1)
    if [ -n "$last_file" ]; then
        vim "$dir/$last_file"
    else
        echo "Not found at $dir"
    fi
    ;;
  "l") ls -lt "$dir";;
  "open") open $dir ;;
  "o") open $dir ;;
  "e")
    if [ -z "$2" ]; then
      echo "Usage: journal e [date]"
      return 1
    fi

    local matches=($(find "$dir" -maxdepth 1 -type f -name "*$2*" | sort -r))

    if [ ${#matches[@]} -eq 0 ]; then
        echo "Not found: $2"
    elif [ ${#matches[@]} -eq 1 ]; then
        vim "${matches[0]}"
    else
        echo "Multiple matches:"
        select file in "${matches[@]}"; do
            if [ -n "$file" ]; then
                vim "$file"
                break
            else
                echo "Invalid selection."
            fi
        done
    fi
    ;;
  "") vim "$dir/$(date +%Y%m%d%H%M%S).txt" ;;
  *) echo "Usage: journal [last | l | e <titulo>]" ;;
esac
}

j() { journal "$@" }
