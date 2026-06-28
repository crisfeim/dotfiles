_sq() { sqlite3 -init /dev/null -list "$@"; }

_db_search() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" term="$6" cat="$7"
  local filter=""
  [[ -n "$cat" ]] && filter="AND $c1 = '$cat'"
  local cols="id"
  [[ -n "$c1" ]] && cols="$cols, $c1"
  [[ -n "$c2" ]] && cols="$cols, $c2"
  _sq "$db" -separator "  " \
    "SELECT $cols FROM $table
     WHERE ($c2 LIKE '%$term%' OR $c3 LIKE '%$term%' OR $c1 LIKE '%$term%')
     $filter ORDER BY $c2;" 2>/dev/null
}

_db_cat() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" id="$6"
  _sq "$db" "SELECT $c3 FROM $table WHERE id = $id;" 2>/dev/null
}

_db_ls() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" cat="$6"
  if [[ -n "$cat" && -n "$c1" ]]; then
    _sq "$db" -separator "  " \
      "SELECT id, $c2 FROM $table WHERE $c1 = '$cat' ORDER BY id;" 2>/dev/null
  else
    local cols="id"
    [[ -n "$c1" ]] && cols="$cols, $c1"
    cols="$cols, $c2"
    _sq "$db" -separator "  " \
      "SELECT $cols FROM $table ORDER BY $c2;" 2>/dev/null
  fi
}

_db_cats() {
  local db="$1" table="$2" c1="$3"
  if [[ -z "$c1" ]]; then echo "Esta tabla no tiene categoría."; return; fi
  _sq "$db" \
    "SELECT $c1 || '  (' || COUNT(*) || ')' FROM $table
     GROUP BY $c1 ORDER BY $c1;" 2>/dev/null
}

_db_all() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5"
  local cols="id"
  [[ -n "$c1" ]] && cols="$cols, $c1"
  [[ -n "$c2" ]] && cols="$cols, $c2"
  _sq "$db" -separator "  " \
    "SELECT $cols FROM $table ORDER BY $c2;" 2>/dev/null
}

_db_add() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5"
  shift 5
  local v1="$1" v2="$2" v3="$3"
  if [[ -z "$v3" && -n "$c3" ]]; then
    local tmp=$(mktemp)
    ${EDITOR:-vi} "$tmp"
    v3=$(cat "$tmp")
    rm "$tmp"
  fi
  local cols="$c2" vals="'$v2'"
  [[ -n "$c1" ]] && cols="$c1, $cols" && vals="'$v1', $vals"
  [[ -n "$c3" ]] && cols="$cols, $c3" && vals="$vals, '$v3'"
  _sq "$db" "INSERT INTO $table ($cols) VALUES ($vals);" 2>/dev/null
  echo "Created."
}

_db_rm() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" id="$6"
  _sq "$db" "DELETE FROM $table WHERE id = $id;" 2>/dev/null
  echo "Removed $id."
}

_db_update() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" field="$6" id="$7"
  if [[ "$field" != "$c1" && "$field" != "$c2" && "$field" != "$c3" ]]; then
    echo "Campo no válido: $field"
    [[ -n "$c1" ]] && echo "  Campos disponibles: $c1, $c2, $c3" || echo "  Campos disponibles: $c2, $c3"
    return 1
  fi
  local tmp=$(mktemp)
  _sq "$db" "SELECT $field FROM $table WHERE id = $id;" 2>/dev/null > "$tmp"
  ${EDITOR:-vi} "$tmp"
  local new=$(cat "$tmp")
  rm "$tmp"
  _sq "$db" "UPDATE $table SET $field = '$new' WHERE id = $id;" 2>/dev/null
  echo "Updated."
}

_db_rename_c1() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" old="$6" new="$7"
  if [[ -z "$c1" ]]; then echo "Esta tabla no tiene c1."; return; fi
  _sq "$db" "UPDATE $table SET $c1 = '$new' WHERE $c1 = '$old';" 2>/dev/null
  echo "Renamed '$old' → '$new'."
}

_db_help() {
  local table="$1" c1="$2" c2="$3" c3="$4"
  echo "Uso: $table <comando> [args]"
  echo ""
  echo "  $table [all]                        listar todo"
  echo "  $table search <término> [-c <$c1>]  buscar"
  echo "  $table cat <id>                     mostrar $c3"
  echo "  $table ls [<$c1>]                   listar por $c1"
  echo "  $table cats                         listar $c1 con total"
  [[ -n "$c1" ]] && \
  echo "  $table add <$c1> <$c2> [<$c3>]" || \
  echo "  $table add <$c2> [<$c3>]"
  echo "  $table rm <id>"
  echo "  $table update <campo> <id>"
  [[ -n "$c1" ]] && \
  echo "  $table move <categoría vieja> <categoía nueva>"
}

_db_dispatch() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5"
  shift 5
  case "$1" in
    search)    _db_search    "$db" "$table" "$c1" "$c2" "$c3" "$2" "$([[ "$3" == -c ]] && echo "$4")" ;;
    cat)       _db_cat       "$db" "$table" "$c1" "$c2" "$c3" "$2" ;;
    ls)        _db_ls        "$db" "$table" "$c1" "$c2" "$c3" "$2" ;;
    cats)      _db_cats      "$db" "$table" "$c1" ;;
    all)       _db_all       "$db" "$table" "$c1" "$c2" "$c3" ;;
    add)       _db_add       "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3" "$4" ;;
    rm)        _db_rm        "$db" "$table" "$c1" "$c2" "$c3" "$2" ;;
    update)    _db_update    "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3" ;;
    move)      _db_rename_c1 "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3" ;;
    help)      _db_help      "$table" "$c1" "$c2" "$c3" ;;
    *)         _db_all       "$db" "$table" "$c1" "$c2" "$c3" ;;
  esac
}

citas()      { _db_dispatch "$HOME/db/db.db" citas       "categoría" "autor"     "contenido"  "$@"; }
diccionario(){ _db_dispatch "$HOME/db/db.db" diccionario "categoría" "término"   "definición" "$@"; }
ideas()      { _db_dispatch "$HOME/db/db.db" ideas       "categoría" "título"    "contenido"  "$@"; }
notas()      { _db_dispatch "$HOME/db/db.db" notas       "categoría" "título"    "contenido"  "$@"; }
peliculas()  { _db_dispatch "$HOME/db/db.db" películas   "género"    "título"    "year"       "$@"; }
principios() { _db_dispatch "$HOME/db/db.db" principios  "categoría" "valor"     ""           "$@"; }
versiculos() { _db_dispatch "$HOME/db/db.db" versículos  "categoría" "ref"       "contenido"  "$@"; }
