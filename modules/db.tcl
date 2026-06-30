package require sqlite3

proc db_list_tables {dbfile} {
    sqlite3 conn $dbfile
    set tables [conn eval {
        SELECT name FROM sqlite_master
        WHERE type='table' AND name NOT LIKE 'sqlite_%';
    }]
    conn close
    return [join $tables "\n"]
}

proc db_create_table {dbfile args} {
    set table [lindex $args 0]
    set cols [lrange $args 3 end]

    set cols_sql "id INTEGER PRIMARY KEY AUTOINCREMENT"
    foreach col $cols {
        set parts [split $col ":"]
        set col_name [lindex $parts 0]
        set col_type [expr {[llength $parts] >= 2 ? [lindex $parts 1] : "TEXT"}]
        append cols_sql ", $col_name $col_type"
    }

    sqlite3 conn $dbfile
    conn eval "CREATE TABLE IF NOT EXISTS $table ($cols_sql);"
    conn close
}

proc db_create_column {dbfile args} {
    set col   [lindex $args 0]
    set table [lindex $args 3]

    set parts [split $col ":"]
    set col_name [lindex $parts 0]
    set col_type [expr {[llength $parts] >= 2 ? [lindex $parts 1] : "TEXT"}]

    sqlite3 conn $dbfile
    conn eval "ALTER TABLE $table ADD COLUMN $col_name $col_type;"
    conn close
}

proc db_add {dbfile args} {
    set table [lindex $args end]
    sqlite3 conn $dbfile
    set cols {}
    conn eval "PRAGMA table_info($table)" row {
        if {$row(name) ne "id"} { lappend cols $row(name) }
    }

    if {[lindex $args end-1] eq "table"} {
        set val_list [lrange $args 0 end-3]
    } else {
        set val_list [lrange $args 0 end-2]
    }

    set insert_cols {}
    set insert_vals {}
    for {set i 0} {$i < [llength $val_list]} {incr i} {
        lappend insert_cols [lindex $cols $i]
        lappend insert_vals "'[string map {' ''} [lindex $val_list $i]]'"
    }

    if {[llength $val_list] < [llength $cols]} {
        set last_col [lindex $cols end]

        if {[info exists ::edit_proc]} {
            set last_val [{*}$::edit_proc ""]
        } else {
            set tmp_file /tmp/db_edit_tmp.txt
            set f [open $tmp_file w]
            puts -nonewline $f ""
            close $f

            set editor "vi"
            if {[info exists ::env(VISUAL)]} { set editor $::env(VISUAL) }
            if {[info exists ::env(EDITOR)]}  { set editor $::env(EDITOR) }
            exec {*}$editor $tmp_file >@stdout <@stdin 2>@stderr

            set f [open $tmp_file r]
            set last_val [read $f]
            close $f
            file delete -force $tmp_file
        }

        lappend insert_cols $last_col
        lappend insert_vals "'[string map {' ''} $last_val]'"
    }

    conn eval "INSERT INTO $table ([join $insert_cols ", "]) VALUES ([join $insert_vals ", "]);"
    conn close
}

proc db_rename_column {dbfile args} {
    set old   [lindex $args 0]
    set new   [lindex $args 2]
    set table [lindex $args 5]

    sqlite3 conn $dbfile
    conn eval "ALTER TABLE $table RENAME COLUMN $old TO $new;"
    conn close
}

proc db_rename_table {dbfile args} {
    set old [lindex $args 0]
    set new [lindex $args 2]

    sqlite3 conn $dbfile
    conn eval "ALTER TABLE $old RENAME TO $new;"
    conn close
}

proc db_edit {dbfile args} {
    set col   [lindex $args 0]
    set id    [lindex $args 3]
    set table [lindex $args 5]

    sqlite3 conn $dbfile
    set current_val [conn onecolumn "SELECT $col FROM $table WHERE id = $id;"]

    if {[info exists ::edit_proc]} {
        set new_val [{*}$::edit_proc $current_val]
    } else {
        set tmp_file /tmp/db_edit_tmp.txt
        set f [open $tmp_file w]
        puts -nonewline $f $current_val
        close $f

        set editor "vi"
        if {[info exists ::env(VISUAL)]} { set editor $::env(VISUAL) }
        if {[info exists ::env(EDITOR)]}  { set editor $::env(EDITOR) }
        exec {*}$editor $tmp_file >@stdout <@stdin 2>@stderr

        set f [open $tmp_file r]
        set new_val [read $f]
        close $f
        file delete -force $tmp_file
    }

    conn eval "UPDATE $table SET $col = '[string map {' ''} $new_val]' WHERE id = $id;"
    conn close
}

proc db_delete {dbfile args} {
    if {[llength $args] == 1} {
        set table [lindex $args 0]
        sqlite3 conn $dbfile
        conn eval "DELETE FROM $table;"
        conn close
    } else {
        set ids_raw [lindex $args 0]
        set table   [lindex $args 3]

        set id_list {}
        foreach id [split $ids_raw ","] {
            lappend id_list [string trim $id]
        }

        sqlite3 conn $dbfile
        conn eval "DELETE FROM $table WHERE id IN ([join $id_list ", "]);"
        conn close
    }
}

proc db_drop_table {dbfile args} {
    set table [lindex $args 0]
    sqlite3 conn $dbfile
    conn eval "DROP TABLE IF EXISTS $table;"
    conn close
}

proc db_schema {dbfile args} {
    set table [lindex $args 1]
    sqlite3 conn $dbfile
    set schema_list {}
    conn eval "PRAGMA table_info($table)" row {
        lappend schema_list "$row(name):$row(type)"
    }
    conn close
    return $schema_list
}

proc db_copy {dbfile args} {
    set col   [lindex $args 0]
    set id    [lindex $args 2]
    set table [lindex $args 4]

    sqlite3 conn $dbfile
    set value [conn onecolumn "SELECT $col FROM $table WHERE id = $id;"]
    conn close

    set clip_cmd [expr {$::tcl_platform(os) eq "Darwin" ? "pbcopy" : "xclip -selection clipboard"}]
    set f [open "|$clip_cmd" w]
    puts -nonewline $f $value
    close $f

    return $value
}

proc db_get {dbfile args} {
    set col   [lindex $args 0]
    set id    [lindex $args 2]
    set table [lindex $args 4]

    sqlite3 conn $dbfile
    set value [conn onecolumn "SELECT $col FROM $table WHERE id = $id;"]
    conn close
    return $value
}

proc db_echo {dbfile args} {
    set id    [lindex $args 0]
    set table [lindex $args 2]

    set exclude_cols {}
    set excl_idx [lsearch $args "excluding"]
    if {$excl_idx != -1} {
        foreach c [split [lindex $args [expr {$excl_idx + 1}]] ","] {
            lappend exclude_cols [string trim $c]
        }
    }

    sqlite3 conn $dbfile
    set cols {}
    conn eval "PRAGMA table_info($table)" r {
        if {[lsearch $exclude_cols $r(name)] == -1} {
            lappend cols $r(name)
        }
    }
    set result [conn eval "SELECT [join $cols ", "] FROM $table WHERE id = $id"]
    conn close

    set lines {}
    foreach col $cols val $result {
        lappend lines "$col: $val"
    }
    return [join $lines "\n"]
}

proc db_echo_col {dbfile args} {
    set col   [lindex $args 0]
    set id    [lindex $args 2]
    set table [lindex $args 4]

    sqlite3 conn $dbfile
    set value [conn onecolumn "SELECT $col FROM $table WHERE id = $id;"]
    conn close
    return $value
}

proc db_group {dbfile args} {
    set table [lindex $args 0]
    set col   [lindex $args 2]

    sqlite3 conn $dbfile
    set result_list {}
    conn eval "SELECT $col, count(*) as count FROM $table GROUP BY $col ORDER BY $col ASC" row {
        lappend result_list "$row($col)($row(count))"
    }
    conn close
    return [join $result_list "\n"]
}

proc db_list {dbfile args} {
    set table [lindex $args 0]
    set rest  [lrange $args 1 end]

    set where_idx [lsearch $rest "where"]
    set excl_idx  [lsearch $rest "excluding"]

    set exclude_cols {}
    set where_sql ""

    if {$where_idx != -1} {
        set col [lindex $rest [expr {$where_idx + 1}]]
        # [expr {$where_idx + 2}] es la palabra "is", se ignora
        set val [lindex $rest [expr {$where_idx + 3}]]
        lappend exclude_cols $col
        set where_sql "WHERE $col = '$val'"
    }

    if {$excl_idx != -1} {
        foreach c [split [lindex $rest [expr {$excl_idx + 1}]] ","] {
            lappend exclude_cols [string trim $c]
        }
    }

    sqlite3 conn $dbfile
    set select_cols {}
    conn eval "PRAGMA table_info($table)" r {
        if {[lsearch $exclude_cols $r(name)] == -1} {
            lappend select_cols $r(name)
        }
    }

    set result [conn eval "SELECT [join $select_cols ", "] FROM $table $where_sql"]
    conn close

    set n [llength $select_cols]
    set lines {}
    for {set i 0} {$i < [llength $result]} {incr i $n} {
        lappend lines [join [lrange $result $i [expr {$i + $n - 1}]] " "]
    }
    return [join $lines "\n"]
}

proc db_search {dbfile args} {
    set term [lindex $args 0]

    set in_idx [lsearch $args "in"]
    if {$in_idx == -1} {
        set exclude_cols {}
        set excl_idx [lsearch $args "excluding"]
        if {$excl_idx != -1} {
            foreach c [split [lindex $args [expr {$excl_idx + 1}]] ","] {
                lappend exclude_cols [string trim $c]
            }
        }

        sqlite3 conn $dbfile
        set tables [conn eval {SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'}]

        set result {}
        foreach table $tables {
            set all_cols {}
            conn eval "PRAGMA table_info($table)" r {
                if {$r(name) ne "id"} { lappend all_cols $r(name) }
            }
            set select_cols {}
            foreach col $all_cols {
                if {[lsearch $exclude_cols $col] == -1} { lappend select_cols $col }
            }
            set like_clauses {}
            foreach col $all_cols {
                lappend like_clauses "$col LIKE '%$term%'"
            }
            set cols_str [join [list id {*}$select_cols] ", "]
            conn eval "SELECT $cols_str FROM $table WHERE ([join $like_clauses " OR "])" row {
                set record {}
                foreach col [list id {*}$select_cols] { lappend record $row($col) }
                lappend result "$table: [join $record " "]"
            }
        }
        conn close
        return [join $result "\n"]
    }

    set table [lindex $args [expr {$in_idx + 1}]]

    sqlite3 conn $dbfile
    set all_cols {}
    conn eval "PRAGMA table_info($table)" r {
        if {$r(name) ne "id"} { lappend all_cols $r(name) }
    }

    set exclude_cols {}
    set excl_idx [lsearch $args "excluding"]
    if {$excl_idx != -1} {
        foreach c [split [lindex $args [expr {$excl_idx + 1}]] ","] {
            lappend exclude_cols [string trim $c]
        }
    }

    set select_cols {}
    foreach col $all_cols {
        if {[lsearch $exclude_cols $col] == -1} { lappend select_cols $col }
    }

    set where_idx [lsearch $args "where"]
    set extra ""
    if {$where_idx != -1} {
        set where_end [expr {$excl_idx != -1 ? $excl_idx - 1 : "end"}]
        set extra "AND ([join [lrange $args [expr {$where_idx + 1}] $where_end] " "])"
    }

    set like_clauses {}
    foreach col $all_cols {
        lappend like_clauses "$col LIKE '%$term%'"
    }

    set cols_str [join [list id {*}$select_cols] ", "]
    set result {}
    conn eval "SELECT $cols_str FROM $table WHERE ([join $like_clauses " OR "]) $extra" row {
        set record {}
        foreach col [list id {*}$select_cols] { lappend record $row($col) }
        lappend result [join $record " "]
    }
    conn close
    return [join $result "\n"]
}

proc db_help {} {
    return [string trim {
db
    List all tables in the database.

db create table <table> with schema <col:TYPE> ...
    Create a new table. Type is optional (defaults to TEXT).

db create column <col:TYPE> in table <table>
    Add a column to an existing table.

db add <val> ... in table <table>
    Insert a record. Omit last value to open editor.

db delete <table>
    Delete all records from a table.

db delete "<id, id, ...>" in table <table>
    Delete specific records by ID.

db drop table <table>
    Drop a table entirely.

db rename column <old> to <new> in table <table>
    Rename a column.

db rename table <old> to <new>
    Rename a table.

db edit <col> from record <id> in <table>
    Open a field in $VISUAL/$EDITOR for editing.

db echo <id> in <table> (excluding <col,...>)?
    Print all fields of a record.

db echo <col> of <id> in <table>
    Print a specific field.

db copy <col> of <id> in <table>
    Copy a field value to clipboard.

db schema of <table>
    Show the schema of a table.

db list <table> (excluding <col,...>)?
    List all records in a table.

db list <table> where <col> is <value> (excluding <col,...>)?
    Filter records by column value.

db group <table> by <col>
    Count and group records by column value.

db search <term> (in <table>)? (where <cond>)? (excluding <col,...>)?
    Search term across columns.
    }]
}

proc db {dbfile args} {
    set cmd1 [lindex $args 0]
    set cmd2 [lindex $args 1]

    if {[llength $args] == 0} {
        return [db_list_tables $dbfile]
    } elseif {$cmd1 eq "create" && $cmd2 eq "table"} {
        db_create_table $dbfile {*}[lrange $args 2 end]
    } elseif {$cmd1 eq "create" && $cmd2 eq "column"} {
        db_create_column $dbfile {*}[lrange $args 2 end]
    } elseif {$cmd1 eq "add"} {
        db_add $dbfile {*}[lrange $args 1 end]
    } elseif {$cmd1 eq "rename" && $cmd2 eq "column"} {
        db_rename_column $dbfile {*}[lrange $args 2 end]
    } elseif {$cmd1 eq "rename" && $cmd2 eq "table"} {
        db_rename_table $dbfile {*}[lrange $args 2 end]
    } elseif {$cmd1 eq "edit"} {
        db_edit $dbfile {*}[lrange $args 1 end]
    } elseif {$cmd1 eq "delete"} {
        db_delete $dbfile {*}[lrange $args 1 end]
    } elseif {$cmd1 eq "drop" && $cmd2 eq "table"} {
        db_drop_table $dbfile {*}[lrange $args 2 end]
    } elseif {$cmd1 eq "schema"} {
        return [db_schema $dbfile {*}[lrange $args 1 end]]
    } elseif {$cmd1 eq "copy"} {
        return [db_copy $dbfile {*}[lrange $args 1 end]]
    } elseif {$cmd1 eq "echo" && [string is integer $cmd2]} {
        return [db_echo $dbfile {*}[lrange $args 1 end]]
    } elseif {$cmd1 eq "echo"} {
        return [db_echo_col $dbfile {*}[lrange $args 1 end]]
    } elseif {$cmd1 eq "group"} {
        return [db_group $dbfile {*}[lrange $args 1 end]]
    } elseif {$cmd1 eq "list"} {
        return [db_list $dbfile {*}[lrange $args 1 end]]
    } elseif {$cmd1 eq "search"} {
        return [db_search $dbfile {*}[lrange $args 1 end]]
    } elseif {$cmd1 eq "help"} {
        return [db_help]
    } elseif {[lindex $args 1] eq "of"} {
        return [db_get $dbfile {*}$args]
    } else {
        return "Unhandled"
    }
}

set db_file [lindex $argv 0]
set cmd_args [lrange $argv 1 end]

set commands {create add rename edit delete echo copy schema list group help search drop}

# db create <table> → db create table <table> with schema category title content
if {[llength $cmd_args] == 2 && [lindex $cmd_args 0] eq "create"} {
    set cmd_args [list create table [lindex $cmd_args 1] with schema category title content]

# db <table> → db group <table> by category
} elseif {[llength $cmd_args] == 1 && [lsearch $commands [lindex $cmd_args 0]] == -1} {
    set cmd_args [list group [lindex $cmd_args 0] by category]

# db <table> <id>  → db echo <id> in <table>
# db <table> <cat> → db list <table> where category is <cat> excluding content
} elseif {[llength $cmd_args] == 2 && [lsearch $commands [lindex $cmd_args 0]] == -1} {
    if {[string is integer [lindex $cmd_args 1]]} {
        set cmd_args [list echo [lindex $cmd_args 1] in [lindex $cmd_args 0]]
    } else {
        set cmd_args [list list [lindex $cmd_args 0] where category is [lindex $cmd_args 1] excluding content]
    }

# db <table> edit <id> → db edit content from record <id> in <table>
} elseif {[llength $cmd_args] == 3
        && [lsearch $commands [lindex $cmd_args 0]] == -1
        && [lindex $cmd_args 1] eq "edit"
        && [string is integer [lindex $cmd_args 2]]} {
    set cmd_args [list edit content from record [lindex $cmd_args 2] in [lindex $cmd_args 0]]

# db <table> <cat> <id> → db echo <id> in <table>
} elseif {[llength $cmd_args] == 3
        && [lsearch $commands [lindex $cmd_args 0]] == -1
        && [lsearch $commands [lindex $cmd_args 1]] == -1
        && [string is integer [lindex $cmd_args 2]]} {
    set cmd_args [list echo [lindex $cmd_args 2] in [lindex $cmd_args 0]]

# db <table> search <term> (where <cond>)? → db search <term> in <table> (where <cond>)? excluding content
} elseif {[llength $cmd_args] >= 2
        && [lsearch $commands [lindex $cmd_args 0]] == -1
        && [lindex $cmd_args 1] eq "search"} {
    set table [lindex $cmd_args 0]
    set term  [lindex $cmd_args 2]
    set rest  [lrange $cmd_args 3 end]
    set cmd_args [list search $term in $table {*}$rest excluding content]

# db <table> <cat> search <term> (where <cond>)? → db search <term> in <table> where category = '<cat>' (AND <cond>)? excluding content
} elseif {[llength $cmd_args] >= 3
        && [lsearch $commands [lindex $cmd_args 0]] == -1
        && [lsearch $commands [lindex $cmd_args 1]] == -1
        && [lindex $cmd_args 2] eq "search"} {
    set table   [lindex $cmd_args 0]
    set cat_val [lindex $cmd_args 1]
    set term    [lindex $cmd_args 3]
    set rest    [lrange $cmd_args 4 end]
    set where_idx [lsearch $rest "where"]
    if {$where_idx != -1} {
        set rest [lreplace $rest [expr {$where_idx + 1}] [expr {$where_idx + 1}] \
            "category = '$cat_val' AND [lindex $rest [expr {$where_idx + 1}]]"]
    } else {
        lappend rest where "category = '$cat_val'"
    }
    set cmd_args [list search $term in $table {*}$rest excluding content]
}

set result [db $db_file {*}$cmd_args]
if {$result ne ""} {
    puts $result
}
