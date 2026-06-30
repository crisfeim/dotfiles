# counter.tcl — mini CLI de contadores
#
# Formato del fichero de datos: una línea por contador,
#   <valor><TAB><descripcion>
# El número de línea (1-indexed) ES el id del contador.

proc counter_load_lines {dbfile} {
    if {![file exists $dbfile]} {
        file mkdir [file dirname $dbfile]
        close [open $dbfile w]
    }
    set f [open $dbfile r]
    set data [split [read $f] "\n"]
    close $f
    if {[lindex $data end] eq ""} {
        set data [lrange $data 0 end-1]
    }
    return $data
}

proc counter_save_lines {dbfile lines} {
    set f [open $dbfile w]
    foreach l $lines {
        puts $f $l
    }
    close $f
}

proc counter_parse_entry {raw} {
    if {![regexp {^(-?[0-9]+)\. (.*)$} $raw -> value desc]} {
        return [list 0 $raw]
    }
    return [list $value $desc]
}

proc counter_make_entry {value desc} {
    return "${value}. ${desc}"
}

proc counter_format {line_num value desc {show_line 0}} {
    if {$show_line} {
        return [format "%d. %s — %5d" $line_num $desc $value]
    } else {
        return "$value $desc"
    }
}

# Devuelve {value desc} de la línea dada (1-indexed) o lanza error si no existe.
proc counter_entry_or_fail {lines line_num} {
    if {![string is integer -strict $line_num] || $line_num < 1 || $line_num > [llength $lines]} {
        error "no existe el contador en la línea $line_num"
    }
    return [counter_parse_entry [lindex $lines [expr {$line_num - 1}]]]
}

# --- comandos -------------------------------------------------------------

proc counter_new {dbfile desc} {
    set lines [counter_load_lines $dbfile]
    lappend lines [counter_make_entry 0 $desc]
    counter_save_lines $dbfile $lines
    return [counter_format [llength $lines] 0 $desc]
}

proc counter_list {dbfile} {
    set lines [counter_load_lines $dbfile]
    set parsed {}
    set max_desc_len 0

    set i 1
    foreach raw $lines {
        lassign [counter_parse_entry $raw] value desc
        set desc_len [string length $desc]
        if {$desc_len > $max_desc_len} { set max_desc_len $desc_len }
        lappend parsed [list $i $value $desc]
        incr i
    }

    set out {}
    foreach item $parsed {
        lassign $item id val desc
        # Se elimina el punto tras el id y se mantiene la alineación
        lappend out [format "%d  %-*s %5d" $id $max_desc_len $desc $val]
    }
    return [join $out "\n"]
}

proc counter_get {dbfile line_num} {
    set lines [counter_load_lines $dbfile]
    lassign [counter_entry_or_fail $lines $line_num] value desc
    return [counter_format $line_num $value $desc]
}

proc counter_set {dbfile line_num new_value} {
    if {![string is integer -strict $new_value]} {
        error "el valor debe ser un entero: $new_value"
    }
    set lines [counter_load_lines $dbfile]
    lassign [counter_entry_or_fail $lines $line_num] value desc
    lset lines [expr {$line_num - 1}] [counter_make_entry $new_value $desc]
    counter_save_lines $dbfile $lines
    return [counter_format $line_num $new_value $desc]
}

proc counter_delta {dbfile line_num delta} {
    if {![string is integer -strict $delta]} {
        error "el incremento debe ser un entero: $delta"
    }
    set lines [counter_load_lines $dbfile]
    lassign [counter_entry_or_fail $lines $line_num] value desc
    set new_value [expr {$value + $delta}]
    lset lines [expr {$line_num - 1}] [counter_make_entry $new_value $desc]
    counter_save_lines $dbfile $lines
    return [counter_format $line_num $new_value $desc]
}

proc counter_edit {dbfile line_num} {
    set lines [counter_load_lines $dbfile]
    lassign [counter_entry_or_fail $lines $line_num] value desc

    if {[info exists ::edit_proc]} {
        set new_desc [{*}$::edit_proc $desc]
    } else {
        set editor "vi"
        if {[info exists ::env(VISUAL)]} { set editor $::env(VISUAL) }
        if {[info exists ::env(EDITOR)]}  { set editor $::env(EDITOR) }

        set tmp_file /tmp/counter_edit_tmp.txt
        set f [open $tmp_file w]
        puts -nonewline $f $desc
        close $f

        exec {*}$editor $tmp_file >@stdout <@stdin 2>@stderr

        set f [open $tmp_file r]
        set new_desc [read $f]
        close $f
        file delete -force $tmp_file
    }

    set lines [counter_load_lines $dbfile]
    lset lines [expr {$line_num - 1}] [counter_make_entry $value [string trim $new_desc]]
    counter_save_lines $dbfile $lines
    return [counter_format $line_num $value [string trim $new_desc]]
}

proc counter_delete {dbfile line_num} {
    set lines [counter_load_lines $dbfile]
    lassign [counter_entry_or_fail $lines $line_num] value desc
    set lines [lreplace $lines [expr {$line_num - 1}] [expr {$line_num - 1}]]
    counter_save_lines $dbfile $lines
    return "Eliminado: $value $desc"
}

proc counter_help {} {
    set entries {
        {"empty"            "Lista todos los contadores (igual que counter list)."}
        {"list"             "Lista todos los contadores."}
        {"new <texto>"      "Crea un nuevo contador a valor 0."}
        {"<linea>"          "Obtiene el contador de esa linea."}
        {"<linea> = <valor>" "Sobreescribe el valor del contador."}
        {"<linea> + <int>?" "Incrementa el contador. Si se omite <int>, suma 1."}
        {"<linea> - <int>?" "Decrementa el contador. Si se omite el <int>, resta 1."}
        {"edit <linea>"     "Abre $VISUAL/$EDITOR para editar la descripcion."}
        {"delete <linea>"   "Elimina el contador de esa linea."}
        {"help"             "Muestra esta ayuda."}
    }

    set max_len 0
    foreach entry $entries {
        set raw_cmd [string trim [lindex $entry 0]]
        if {[string length $raw_cmd] > $max_len} { set max_len [string length $raw_cmd] }
    }

    set red "\u001b\[31m"; set grn "\u001b\[32m"; set blu "\u001b\[34m"
    set yel "\u001b\[33m"; set end "\u001b\[0m"; set dim "\u001b\[2m"; set rst "\u001b\[22m"

    set out {}
    foreach entry $entries {
        set raw_cmd [string trim [lindex $entry 0]]
        set expl    [lindex $entry 1]

        set action [lindex [split $raw_cmd] 0]
        set colored_cmd $raw_cmd

        if {$action eq "delete"} {
            set colored_cmd [string map [list $action "${red}${action}${end}"] $colored_cmd]
        } elseif {$action eq "new" || $action eq "edit"} {
            set colored_cmd [string map [list $action "${grn}${action}${end}"] $colored_cmd]
        } elseif {[string index $action 0] ne "<"} {
            set colored_cmd [string map [list $action "${blu}${action}${end}"] $colored_cmd]
        }

        foreach sym {= + - ?} {
            set colored_cmd [string map [list $sym "${yel}${sym}${end}"] $colored_cmd]
        }

        set padding [string repeat " " [expr {$max_len - [string length $raw_cmd]}]]
        lappend out [format "%s%s    ${dim}%s${rst}" $colored_cmd $padding $expl]
    }
    return [join $out "\n"]
}

# --- dispatcher -------------------------------------------------------

proc counter {dbfile args} {
    if {[llength $args] == 0} {
        return [counter_list $dbfile]
    }

    set cmd [lindex $args 0]

    switch -- $cmd {
        new {
            if {[llength $args] < 2} { error "uso: counter new <texto>" }
            return [counter_new $dbfile [join [lrange $args 1 end] " "]]
        }
        list {
            return [counter_list $dbfile]
        }
        help {
            return [counter_help]
        }
        edit {
            if {[llength $args] != 2} { error "uso: counter edit <linea>" }
            return [counter_edit $dbfile [lindex $args 1]]
        }
        delete {
            if {[llength $args] != 2} { error "uso: counter delete <linea>" }
            return [counter_delete $dbfile [lindex $args 1]]
        }
        default {
            set line_num $cmd
            if {[llength $args] == 1} {
                return [counter_get $dbfile $line_num]
            } elseif {[llength $args] == 2} {
                set op [lindex $args 1]
                if {$op eq "+"} {
                    return [counter_delta $dbfile $line_num 1]
                } elseif {$op eq "-"} {
                    return [counter_delta $dbfile $line_num -1]
                } else {
                    error "operador desconocido: $op"
                }
            } elseif {[llength $args] == 3} {
                set op  [lindex $args 1]
                set arg [lindex $args 2]
                switch -- $op {
                    "+" { return [counter_delta $dbfile $line_num $arg] }
                    "-" { return [counter_delta $dbfile $line_num [expr {-1 * $arg}]] }
                    "=" { return [counter_set $dbfile $line_num $arg] }
                    default { error "operador desconocido: $op" }
                }
            } else {
                error "demasiados argumentos"
            }
        }
    }
}

# --- entrypoint cuando se invoca como script ---------------------------

set db_file [lindex $argv 0]
set cmd_args [lrange $argv 1 end]

if {$db_file ne ""} {
    if {[catch {set result [counter $db_file {*}$cmd_args]} err]} {
        puts stderr "Error: $err"
        exit 1
    }
    if {$result ne ""} {
        puts $result
    }
}
