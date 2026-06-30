package require tcltest
namespace import tcltest::*
source [file join [file dirname [file dirname [info script]]] modules tcl counter.tcl]

test parse-entry-normal {Parsea linea con separador '. '} -body {
    counter_parse_entry "3. Sacar al perro a pasear"
} -result {3 {Sacar al perro a pasear}}

test parse-entry-no-sep {Parsea linea sin separador (defensivo)} -body {
    counter_parse_entry "texto suelto"
} -result {0 {texto suelto}}

test make-entry {Construye linea con separador '. '} -body {
    counter_make_entry 5 "Hacer ejercicio"
} -result "5. Hacer ejercicio"

test new-counter {Crea un contador nuevo a valor 0} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_new.counter]
} -body {
    counter $db_path new "Sacar al perro a pasear"
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {0 Sacar al perro a pasear}

test list-counters {Lista contadores con numero de linea} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_list.counter]
    counter $db_path new "Sacar al perro a pasear"
    counter $db_path new "Hacer ejercicio"
} -body {
    counter $db_path list
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result "0 Sacar al perro a pasear  — 1\n0 Hacer ejercicio  — 2"

test no-args-equals-list {counter sin subcomando lista igual que counter list} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_noargs.counter]
    counter $db_path new "Sacar al perro a pasear"
    counter $db_path new "Hacer ejercicio"
} -body {
    expr {[counter $db_path] eq [counter $db_path list]}
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {1}

test get-counter {Obtiene un contador por linea} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_get.counter]
    counter $db_path new "Hacer ejercicio"
} -body {
    counter $db_path 1
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {0 Hacer ejercicio}

test get-counter-missing {Falla con linea inexistente} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_get_missing.counter]
    counter $db_path new "Hacer ejercicio"
} -body {
    catch {counter $db_path 99} err
    set err
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {no existe el contador en la línea 99}

test increment-default {Incrementa en 1 por defecto} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_inc.counter]
    counter $db_path new "Hacer ejercicio"
} -body {
    counter $db_path 1 +
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {1 Hacer ejercicio}

test increment-explicit {Incrementa con valor explicito} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_inc2.counter]
    counter $db_path new "Hacer ejercicio"
} -body {
    counter $db_path 1 + 5
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {5 Hacer ejercicio}

test decrement-default {Decrementa en 1 por defecto} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_dec.counter]
    counter $db_path new "Hacer ejercicio"
    counter $db_path 1 + 3
} -body {
    counter $db_path 1 -
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {2 Hacer ejercicio}

test overwrite-value {Sobreescribe el valor con =} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_set.counter]
    counter $db_path new "Hacer ejercicio"
} -body {
    counter $db_path 1 = 42
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {42 Hacer ejercicio}

test overwrite-rejects-non-integer {Rechaza valor no entero en =} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_set_bad.counter]
    counter $db_path new "Hacer ejercicio"
} -body {
    catch {counter $db_path 1 = abc} err
    set err
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {el valor debe ser un entero: abc}

test delete-counter {Elimina un contador y reindexa} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_delete.counter]
    counter $db_path new "Sacar al perro a pasear"
    counter $db_path new "Hacer ejercicio"
} -body {
    counter $db_path delete 1
    counter $db_path list
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result "0 Hacer ejercicio  — 1"

test delete-counter-missing {Falla al borrar linea inexistente} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_delete_missing.counter]
    counter $db_path new "Hacer ejercicio"
} -body {
    catch {counter $db_path delete 99} err
    set err
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
} -result {no existe el contador en la línea 99}

proc mock_edit {current} { return "Pasear al perro por el parque" }

test edit-counter {Edita la descripcion via ::edit_proc, conserva el valor} -setup {
    set db_path [file join [tcltest::temporaryDirectory] test_edit.counter]
    counter $db_path new "Sacar al perro a pasear"
    counter $db_path 1 + 2
    set ::edit_proc mock_edit
} -body {
    counter $db_path edit 1
} -cleanup {
    if {[file exists $db_path]} { file delete -force $db_path }
    unset -nocomplain ::edit_proc
} -result {2 Pasear al perro por el parque}

cleanupTests
