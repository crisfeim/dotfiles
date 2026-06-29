package require tcltest
package require sqlite3
namespace import tcltest::*
source [file join [file dirname [file dirname [info script]]] modules db.tcl]

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

test get-table-schema {Get the schema of a table} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_schema.db]
    db $db_path create table notes with schema title views:INTEGER
} -body {
    db $db_path schema of notes
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {id:INTEGER title:TEXT views:INTEGER}

test copy-column-value {Copy field value to clipboard} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_copy.db]
    db $db_path create table notes with schema title content
    db $db_path add "Secret Key" "12345-ABCDE" in table notes
} -body {
    db $db_path copy content of 1 in notes
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {12345-ABCDE}

test group-by-col {Group records by column} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_group.db]
    db $db_path create table notes with schema category:TEXT title:TEXT
    db $db_path add "Work" "Task 1" in notes
    db $db_path add "Work" "Task 2" in notes
    db $db_path add "Home" "Task 3" in notes
} -body {
    db $db_path notes grouped by category
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {Home(1) Work(2)}

test list-where-filter {Filter records by column value} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_filter.db]
    db $db_path create table items with schema name:TEXT status:TEXT
    db $db_path add "Apple" "active" in table items
    db $db_path add "Banana" "inactive" in table items
} -body {
    # Filtramos por status = active
    db $db_path list items where status is active
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {id 1 name Apple status active}

test rename-table {Rename a table} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_rename_table.db]
    db $db_path create table notes with schema title
    db $db_path add "Hello" in table notes
} -body {
    db $db_path rename table notes to entries
    sqlite3 conn $db_path
    set result [conn eval {SELECT title FROM entries}]
    conn close
    set result
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {Hello}

cleanupTests
