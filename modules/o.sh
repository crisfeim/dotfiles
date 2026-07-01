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
