apppath() {
  if [ -z "$1" ]; then
    echo "Usage: app-path <AppName>" >&2
    return 1
  fi

  local result
  result=$(find /Applications -iname "$1.app" -maxdepth 3 2>/dev/null | head -1)

  if [ -z "$result" ]; then
    echo "App not found: $1" >&2
    return 1
  fi

  echo "$result"
}
