package require tcltest
package require sqlite3
namespace import tcltest::*

proc db {dbfile args} {
    set cmd1 [lindex $args 0]
    set cmd2 [lindex $args 1]

    if {[llength $args] == 0} {
      sqlite3 conn $dbfile
      set tables [conn eval {
          SELECT name FROM sqlite_master
          WHERE type='table' AND name NOT LIKE 'sqlite_%';
      }]
      conn close
      return $tables
    }

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
    } elseif {$cmd1 eq "edit"} {
      set col [lindex $args 1]
      set id [lindex $args 4]
      set table [lindex $args 6]

      sqlite3 conn $dbfile
      set current_val [conn eval "SELECT $col FROM $table WHERE id = $id;"]

      set tmp_file [file join [tcltest::temporaryDirectory] "db_edit_tmp.txt"]
      set f [open $tmp_file w]
      puts -nonewline $f $current_val
      close $f

      set editor "vi"
      if {[info exists ::env(VISUAL)]} {
        set editor $::env(VISUAL)
      } elseif {[info exists ::env(EDITOR)]} {
        set editor $::env(EDITOR)
      }

      exec {*}$editor $tmp_file

      set f [open $tmp_file r]
      set new_val [read $f]
      close $f
      file delete -force $tmp_file

      set escaped_new_val [string map {' ''} $new_val]
      conn eval "UPDATE $table SET $col = '$escaped_new_val' WHERE id = $id;"
      conn close
  } elseif {$cmd1 eq "delete"} {
    if {[llength $args] == 2} {
        set table [lindex $args 1]
        sqlite3 conn $dbfile
        conn eval "DELETE FROM $table;"
        conn close
    } elseif {[llength $args] == 5} {
        set ids_raw [lindex $args 1]
        set table [lindex $args 4]

        set id_list {}
        foreach id [split $ids_raw ","] {
            lappend id_list [string trim $id]
        }
        set ids_str [join $id_list ", "]

        sqlite3 conn $dbfile
        conn eval "DELETE FROM $table WHERE id IN ($ids_str);"
        conn close
    }
  } elseif {[lindex $args 1] eq "of"} {
      set col [lindex $args 0]
      set id [lindex $args 2]
      set table [lindex $args 4]

      sqlite3 conn $dbfile
      set value [conn onecolumn "SELECT $col FROM $table WHERE id = $id;"]
      conn close
      return $value
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


test edit-record-content {Edit a record field using an external editor mockup} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_edit.db]
    db $db_path create table notes with schema title content
    db $db_path add "Original Title" "Original Content" in table notes

    set ::env(VISUAL) {printf "Updated Content" >}
} -body {
    db $db_path edit content from record 1 in notes

    sqlite3 conn $db_path
    set result [conn onecolumn {SELECT content FROM notes WHERE id = 1}]
    conn close
    set result
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
    unset -nocomplain ::env(VISUAL)
} -result {Updated Content}


test delete-records {Delete multiple records by IDs} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_delete.db]
    db $db_path create table notes with schema title
    db $db_path add "Note 1" in table notes
    db $db_path add "Note 2" in table notes
    db $db_path add "Note 3" in table notes
} -body {
    db $db_path delete "1, 3" in table notes

    sqlite3 conn $db_path
    set result [conn eval {SELECT title FROM notes}]
    conn close
    set result
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {{Note 2}}

test delete-all-records {Delete entire table content} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_delete_all.db]
    db $db_path create table notes with schema title
    db $db_path add "Note 1" in table notes
    db $db_path add "Note 2" in table notes
} -body {
    db $db_path delete notes

    sqlite3 conn $db_path
    set count [conn onecolumn {SELECT count(*) FROM notes}]
    conn close
    set count
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result 0

test list-tables {List user-created tables} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_list.db]
    db $db_path create table notes with schema title
    db $db_path create table tasks with schema description
} -body {
    db $db_path
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {notes tasks}

test get-column-value {Get a specific field value from a record} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_get.db]
    db $db_path create table notes with schema title content
    db $db_path add "My Title" "My Content" in table notes
} -body {
    db $db_path title of 1 in notes
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {My Title}

cleanupTests
