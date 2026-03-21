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
