pastein() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  pbpaste > "$dest"
}
