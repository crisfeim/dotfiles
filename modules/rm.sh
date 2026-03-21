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
