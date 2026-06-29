package require tcltest
package require sqlite3
namespace import tcltest::*

proc db {dbfile args} {
    set cmd1 [lindex $args 0]
    set cmd2 [lindex $args 1]

    if {$cmd1 eq "create" && $cmd2 eq "table"} {
        set table [lindex $args 2]
        set cols [lrange $args 5 end]

        set cols_sql "id INTEGER PRIMARY KEY AUTOINCREMENT"
        foreach col $cols {
            set parts [split $col ":"]
            set col_name [lindex $parts 0]

            if {[llength $parts] >= 2} {
                set col_type [lindex $parts 1]
            } else {
                set col_type "TEXT"
            }
            append cols_sql ", $col_name $col_type"
        }

        sqlite3 conn $dbfile
        conn eval "CREATE TABLE IF NOT EXISTS $table ($cols_sql);"
        conn close
    }
}

test create-table {Create table} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_literal.db]
} -body {
    db $db_path create table notes with schema title views:INTEGER price:REAL file:BLOB

    sqlite3 conn $db_path
    set schema {}
    conn eval {PRAGMA table_info(notes)} row {
        lappend schema "$row(name):$row(type)"
    }
    conn close
    set schema
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {id:INTEGER title:TEXT views:INTEGER price:REAL file:BLOB}
