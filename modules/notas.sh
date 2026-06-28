notas() {
  local DB="$HOME/db/db.db"
  local SQ=(sqlite3 -init /dev/null -list)

  case "$1" in
    search)
      local term="$2"
      local cat_filter=""
      if [[ "$3" == -c ]]; then
        cat_filter="AND categoría = '$4'"
      fi
      "${SQ[@]}" -separator "  " "$DB" \
        "SELECT id, categoría, título
         FROM notas
         WHERE (título LIKE '%$term%' OR contenido LIKE '%$term%' OR categoría LIKE '%$term%')
         $cat_filter
         ORDER BY categoría, id;" 2>/dev/null
      ;;

    cat)
      "${SQ[@]}" "$DB" \
        "SELECT contenido FROM notas WHERE id = $2;" 2>/dev/null
      ;;

    ls)
      if [[ -n "$2" ]]; then
        "${SQ[@]}" "$DB" \
          "SELECT id || '  ' || título FROM notas WHERE categoría = '$2' ORDER BY id;" 2>/dev/null
      else
        "${SQ[@]}" "$DB" \
          "SELECT id || '  [' || categoría || ']  ' || título FROM notas ORDER BY categoría, id;" 2>/dev/null
      fi
      ;;

    cats)
      "${SQ[@]}" "$DB" \
        "SELECT categoría || '  (' || COUNT(*) || ')' FROM notas GROUP BY categoría ORDER BY categoría;" 2>/dev/null
      ;;

    *)
      echo "Uso:"
      echo "  notas search 'término' [-c categoría]"
      echo "  notas cat <id>"
      echo "  notas ls [categoría]"
      echo "  notas cats"
      ;;
  esac
}
