package require sqlite3
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
  } elseif {$cmd1 eq "schema" && [lindex $args 1] eq "of"} {
      set table [lindex $args 2]

      sqlite3 conn $dbfile
      set schema_list {}
      conn eval "PRAGMA table_info($table)" row {
        lappend schema_list "$row(name):$row(type)"
      }
      conn close
      return $schema_list
  } elseif {$cmd1 eq "copy" && [lindex $args 2] eq "of"} {
      set col [lindex $args 1]
      set id [lindex $args 3]
      set table [lindex $args 5]

      sqlite3 conn $dbfile
      set value [conn onecolumn "SELECT $col FROM $table WHERE id = $id;"]
      conn close

      if {$::tcl_platform(os) eq "Darwin"} {
          set clip_cmd "pbcopy"
      } else {
          set clip_cmd "xclip -selection clipboard"
      }

      set f [open "|$clip_cmd" w]
      puts -nonewline $f $value
      close $f

      return $value
    } elseif {[lindex $args 1] eq "of"} {
      set col [lindex $args 0]
      set id [lindex $args 2]
      set table [lindex $args 4]

      sqlite3 conn $dbfile
      set value [conn onecolumn "SELECT $col FROM $table WHERE id = $id;"]
      conn close
      return $value
  } elseif {$cmd2 eq "grouped" && [lindex $args 2] eq "by"} {
    set table [lindex $args 0]
    set col [lindex $args 3]

    sqlite3 conn $dbfile
    set result_list {}
    conn eval "SELECT $col, count(*) as count FROM $table GROUP BY $col ORDER BY $col ASC" row {
      lappend result_list "$row($col)($row(count))"
    }
    conn close
    return [join $result_list " "]
  } else {
  	return "Unhandled"
  }
}

set db_file [lindex $argv 0]
set cmd_args [lrange $argv 1 end]

set result [db $db_file {*}$cmd_args];

if {$result ne ""} {
    puts $result
}
