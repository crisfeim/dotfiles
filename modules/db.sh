_sq() { sqlite3 -init /dev/null -list "$@"; }

_db_search() {
  local db="$1" table="$2" term="$3" cat="$4"
  local filter=""
  [[ -n "$cat" ]] && filter="AND categoría = '$cat'"
  _sq "$db" -separator "  " \
    "SELECT id, categoría, título FROM $table
     WHERE (título LIKE '%$term%' OR contenido LIKE '%$term%' OR categoría LIKE '%$term%')
     $filter ORDER BY categoría, id;" 2>/dev/null
}

_db_cat() {
  local db="$1" table="$2" id="$3"
  _sq "$db" "SELECT contenido FROM $table WHERE id = $id;" 2>/dev/null
}

_db_ls() {
  local db="$1" table="$2" cat="$3"
  if [[ -n "$cat" ]]; then
    _sq "$db" -separator "  " \
      "SELECT id, título FROM $table WHERE categoría = '$cat' ORDER BY id;" 2>/dev/null
  else
    _sq "$db" -separator "  " \
      "SELECT id, categoría, título FROM $table ORDER BY categoría, id;" 2>/dev/null
  fi
}

_db_cats() {
  local db="$1" table="$2"
  _sq "$db" \
    "SELECT categoría || '  (' || COUNT(*) || ')' FROM $table
     GROUP BY categoría ORDER BY categoría;" 2>/dev/null
}

_db_all() {
  local db="$1" table="$2"
  _sq "$db" -separator "  " \
    "SELECT id, categoría, título FROM $table ORDER BY categoría, título;" 2>/dev/null
}

_db_add() {
  local db="$1" table="$2" cat="$3" title="$4" content="$5"
  if [[ -z "$content" ]]; then
    local tmp=$(mktemp)
    ${EDITOR:-vi} "$tmp"
    content=$(cat "$tmp")
    rm "$tmp"
  fi
  _sq "$db" \
    "INSERT INTO $table (categoría, título, contenido)
     VALUES ('$cat', '$title', '$content');" 2>/dev/null
  echo "Created."
}

_db_rm() {
  local db="$1" table="$2" id="$3"
  _sq "$db" "DELETE FROM $table WHERE id = $id;" 2>/dev/null
  echo "Removed $id."
}

_db_update() {
  local db="$1" table="$2" field="$3" id="$4"
  local tmp=$(mktemp)
  case "$field" in
    título|categoría|contenido)
      _sq "$db" "SELECT $field FROM $table WHERE id = $id;" 2>/dev/null > "$tmp"
      ;;
    *)
      echo "Campo no válido: $field (título, categoría, contenido)"
      rm "$tmp"
      return 1
      ;;
  esac
  ${EDITOR:-vi} "$tmp"
  local new=$(cat "$tmp")
  rm "$tmp"
  _sq "$db" "UPDATE $table SET $field = '$new' WHERE id = $id;" 2>/dev/null
  echo "Updated."
}

_db_rename_cat() {
  local db="$1" table="$2" old="$3" new="$4"
  _sq "$db" \
    "UPDATE $table SET categoría = '$new' WHERE categoría = '$old';" 2>/dev/null
  echo "Renamed '$old' → '$new'."
}

_db_help() {
  local t="$1"
  echo "Uso: $t <comando> [args]"
  echo ""
  echo "  $t [all]                         listar todo"
  echo "  $t search <término> [-c <cat>]   buscar en título, contenido y categoría"
  echo "  $t cat <id>                      mostrar contenido"
  echo "  $t ls [categoría]                listar por categoría"
  echo "  $t cats                          listar categorías con total"
  echo "  $t add <cat> <título> [contenido]"
  echo "  $t rm <id>"
  echo "  $t update <título|categoría|contenido> <id>"
  echo "  $t rename-cat <vieja> <nueva>"
}

_db_dispatch() {
  local db="$1" table="$2"
  shift 2
  case "$1" in
    search)     _db_search     "$db" "$table" "$2" "$([[ "$3" == -c ]] && echo "$4")" ;;
    cat)        _db_cat        "$db" "$table" "$2" ;;
    ls)         _db_ls         "$db" "$table" "$2" ;;
    cats)       _db_cats       "$db" "$table" ;;
    all)        _db_all        "$db" "$table" ;;
    add)        _db_add        "$db" "$table" "$2" "$3" "$4" ;;
    rm)         _db_rm         "$db" "$table" "$2" ;;
    update)     _db_update     "$db" "$table" "$2" "$3" ;;
    rename-cat) _db_rename_cat "$db" "$table" "$2" "$3" ;;
    help)       _db_help       "$table" ;;
    *)          _db_all        "$db" "$table" ;;
  esac
}

notas() { _db_dispatch "$HOME/db/db.db" notas "$@"; }
ideas() { _db_dispatch "$HOME/db/db.db" ideas "$@"; }
