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

vi() {
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
  command vi "${args[@]}"
}

# Lazyfica cat
# Mostrará el primer fichero que haga match con el filename independientemente de la extensión.
cat() {
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
  command cat "${args[@]}"
}

rm() {
  local args=()
  local found
  for arg in "$@"; do
    if [[ "$arg" == "." ]]; then
      local dir=$PWD; cd .. && command rm -rf "$dir"
      continue
    elif [[ "$arg" == */ ]]; then
      command rm -rf "$arg"
      continue
    elif [[ ! -e "$arg" && ! -d "$arg" ]]; then
      found=$(ls "${arg}".* 2>/dev/null | head -1)
      if [[ -n "$found" ]]; then
        args+=("$found")
        continue
      fi
    fi
    args+=("$arg")
  done
  [[ ${#args[@]} -gt 0 ]] && command rm "${args[@]}"
}

mkdir() {
	command mkdir "$@"
	[ $? -ne 0 ] && return
	local last_arg="${@[-1]}"

	if [[ "$last_arg" == */ ]]; then
		cd "$last_arg"
	fi
}
