# Lazyfica e
# Editará el primer fichero que haga match con el filename independientemente de la extensión.
e() {
  local args=()
  for arg in "$@"; do
    if [[ -e "$arg" ]]; then
      args+=("$arg")
    else
      local match
      match=($(ls "${arg}".* 2>/dev/null | head -1))
      if [[ -n "$match" ]]; then
        args+=("$match")
      else
        args+=("$arg")
      fi
    fi
  done
  nvim "${args[@]}"
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

alias t='python3 ~/dotfiles/misc/t/t.py --task-dir ~/tasks --list tasks'
alias tf='python3 ~/dotfiles/misc/tf.py'
