_sq() { sqlite3 -init /dev/null -list "$@"; }

_db_search() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" term="$6" cat="$7"
  local filter=""
  [[ -n "$cat" ]] && filter="AND $c1 = '$cat'"
  local cols="id"
  [[ -n "$c1" ]] && cols="$cols, $c1"
  [[ -n "$c2" ]] && cols="$cols, $c2"
  _sq "$db" -separator "|" \
    "SELECT $cols FROM $table
     WHERE ($c2 LIKE '%$term%' OR $c3 LIKE '%$term%' OR $c1 LIKE '%$term%')
     $filter ORDER BY $c1, $c2;" 2>/dev/null | column -t -s "|"
}

_db_cat() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" id="$6"
  _sq "$db" "SELECT $c3 FROM $table WHERE id = $id;" 2>/dev/null
}

_db_ls() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" cat="$6"
  if [[ -n "$cat" && -n "$c1" ]]; then
    _sq "$db" -separator "|" \
      "SELECT id, $c2 FROM $table WHERE $c1 = '$cat' ORDER BY id;" 2>/dev/null | column -t -s "|"
  else
    local cols="id"
    [[ -n "$c1" ]] && cols="$cols, $c1"
    cols="$cols, $c2"
    _sq "$db" -separator "|" \
      "SELECT $cols FROM $table ORDER BY $c2;" 2>/dev/null | column -t -s "|"
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
  _sq "$db" -separator "|" \
    "SELECT $cols FROM $table ORDER BY $c1, $c2;" 2>/dev/null | column -t -s "|"
}

_db_add() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5"
  shift 5
  local v1="$1" v2="$2" v3="$3"

  if [[ -n "$c3" && -z "$v3" ]]; then
    local tmp=$(mktemp)
    ${EDITOR:-vi} "$tmp"
    v3=$(cat "$tmp")
    rm "$tmp"
  fi

  local cols="$c2" vals="'$v2'"
  [[ -n "$c1" ]] && cols="$c1, $cols" && vals="'$v1', $vals"
  [[ -n "$c3" ]] && cols="$cols, $c3" && vals="$vals, '$(echo "$v3" | sed "s/'/''/g")'"
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

_db_move() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5" old="$6" new="$7"
  if [[ -z "$c1" ]]; then echo "Esta tabla no tiene categoría."; return; fi
  _sq "$db" "UPDATE $table SET $c1 = '$new' WHERE $c1 = '$old';" 2>/dev/null
  echo "Moved '$old' → '$new'."
}

_db_help() {
  local table="$1" c1="$2" c2="$3" c3="$4"
  {
    echo "Uso: $table <comando> [args]"
    echo ""
    echo "  $table||listar todo"
    echo "  $table|<id>|mostrar $c3"
    [[ -n "$c1" ]] && \
    echo "  $table|<$c1>|listar por categoría"
    echo "  $table|search <término> [-c <$c1>]|buscar"
    echo "  $table|cats|listar $c1 con total"
    [[ -n "$c1" ]] && \
    echo "  $table|add <$c1> <$c2> [<$c3>]|crear" || \
    echo "  $table|add <$c2> [<$c3>]|crear"
    echo "  $table|rm <id>|eliminar"
    echo "  $table|update <campo> <id>|editar campo"
    [[ -n "$c1" ]] && \
    echo "  $table|move <vieja> <nueva>|mover categoría"
  } | column -t -s "|"
}

_db_dispatch() {
  local db="$1" table="$2" c1="$3" c2="$4" c3="$5"
  shift 5
  case "$1" in
    search)     _db_search "$db" "$table" "$c1" "$c2" "$c3" "$2" "$([[ "$3" == -c ]] && echo "$4")" ;;
    cats)       _db_cats   "$db" "$table" "$c1" ;;
    categories) _db_cats   "$db" "$table" "$c1" ;;
    categorías) _db_cats   "$db" "$table" "$c1" ;;
    add)        _db_add    "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3" "$4" ;;
    new)        _db_add    "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3" "$4" ;;
    create)     _db_add    "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3" "$4" ;;
    rm)         _db_rm     "$db" "$table" "$c1" "$c2" "$c3" "$2" ;;
    remove)     _db_rm     "$db" "$table" "$c1" "$c2" "$c3" "$2" ;;
    delete)     _db_rm     "$db" "$table" "$c1" "$c2" "$c3" "$2" ;;
    update)
      if [[ "$2" =~ ^[0-9]+$ ]]; then
        _db_update "$db" "$table" "$c1" "$c2" "$c3" "$c3" "$2"
      else
        _db_update "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3"
      fi
      ;;
    move)       _db_move   "$db" "$table" "$c1" "$c2" "$c3" "$2" "$3" ;;
    help)       _db_help   "$table" "$c1" "$c2" "$c3" ;;
    "") _db_cats "$db" "$table" "$c1" ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        _db_cat "$db" "$table" "$c1" "$c2" "$c3" "$1"
      else
        _db_ls  "$db" "$table" "$c1" "$c2" "$c3" "$1"
      fi
      ;;
  esac
}

db() {
  if [[ -z "$1" ]]; then
    _sq "$HOME/db/db.db" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" 2>/dev/null
    return
  fi
  local table="$1"
  shift
  local info
  info=$(_sq "$HOME/db/db.db" "PRAGMA table_info($table);" 2>/dev/null)
  if [[ -z "$info" ]]; then
    echo "Tabla '$table' no existe."
    return 1
  fi
  local cols
  cols=($(echo "$info" | awk -F'|' '{print $2}' | grep -v '^id$'))
  local c1="${cols[1]}" c2="${cols[2]}" c3="${cols[3]}"
  _db_dispatch "$HOME/db/db.db" "$table" "$c1" "$c2" "$c3" "$@"
}

_db_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "$prev" == "db" ]]; then
    # completar nombres de tablas
    local tables
    tables=$(sqlite3 -init /dev/null -list "$HOME/db/db.db" \
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" 2>/dev/null)
    COMPREPLY=($(compgen -W "$tables" -- "$cur"))
  elif [[ COMP_CWORD -eq 2 ]]; then
    # completar comandos o categorías
    local table="${COMP_WORDS[1]}"
    local cats
    cats=$(sqlite3 -init /dev/null -list "$HOME/db/db.db" \
      "SELECT DISTINCT $(sqlite3 -init /dev/null "$HOME/db/db.db" \
        "PRAGMA table_info($table);" 2>/dev/null | awk -F'|' 'NR==2{print $2}') \
       FROM $table ORDER BY 1;" 2>/dev/null)
    local cmds="search cats add new rm remove update move help"
    COMPREPLY=($(compgen -W "$cats $cmds" -- "$cur"))
  fi
}

complete -F _db_complete db
