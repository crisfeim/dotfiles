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
    } elseif {$cmd1 eq "create" && $cmd2 eq "column"} {
      set col [lindex $args 2]
      set table [lindex $args 5]

      set parts [split $col ":"]
      set col_name [lindex $parts 0]
      if {[llength $parts] >= 2} {
          set col_type [lindex $parts 1]
      } else {
          set col_type "TEXT"
      }

      sqlite3 conn $dbfile
      conn eval "ALTER TABLE $table ADD COLUMN $col_name $col_type;"
      conn close
    } elseif {$cmd1 eq "add"} {
      set table [lindex $args end]
      sqlite3 conn $dbfile
      set cols {}
      conn eval "PRAGMA table_info($table)" row {
          if {$row(name) ne "id"} {
              lappend cols $row(name)
          }
      }
      set val_list [lrange $args 1 end-3]
      set insert_cols {}
      set insert_vals {}
      for {set i 0} {$i < [llength $val_list]} {incr i} {
          lappend insert_cols [lindex $cols $i]
          set escaped_val [string map {' ''} [lindex $val_list $i]]
          lappend insert_vals "'$escaped_val'"
      }
      set cols_str [join $insert_cols ", "]
      set vals_str [join $insert_vals ", "]
      conn eval "INSERT INTO $table ($cols_str) VALUES ($vals_str);"
      conn close
    } elseif {$cmd1 eq "rename" && $cmd2 eq "column"} {
      set old [lindex $args 2]
      set new [lindex $args 4]
      set table [lindex $args 7]

      sqlite3 conn $dbfile
      conn eval "ALTER TABLE $table RENAME COLUMN $old TO $new;"
      conn close
    }
}

proc get_schema {db_path table} {
  sqlite3 conn $db_path
  set schema {}
  conn eval "PRAGMA table_info($table)" row {
    lappend schema "$row(name):$row(type)"
  }
  conn close
  return $schema
}

test create-table {Create table} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_literal.db]
} -body {
    db $db_path create table notes with schema title views:INTEGER price:REAL file:BLOB
    get_schema $db_path notes
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {id:INTEGER title:TEXT views:INTEGER price:REAL file:BLOB}

test add-column {Add column to existing table} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_alter.db]
    db $db_path create table notes with schema title
} -body {
    db $db_path create column views:INTEGER in table notes
    db $db_path create column tags in table notes

    get_schema $db_path notes
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {id:INTEGER title:TEXT views:INTEGER tags:TEXT}

test add-record {Add record to table} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_add.db]
    db $db_path create table notes with schema title content
} -body {
    db $db_path add "First Note" "Some body text" in table notes

    sqlite3 conn $db_path
    set result {}
    conn eval {SELECT title, content FROM notes} {
      lappend result $title $content
    }
    conn close
    set result
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {{First Note} {Some body text}}

test rename-column {Rename a column in a table} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_rename.db]
    db $db_path create table notes with schema title content
} -body {
    db $db_path rename column content to body in table notes
    get_schema $db_path notes
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {id:INTEGER title:TEXT body:TEXT}

cleanupTests
