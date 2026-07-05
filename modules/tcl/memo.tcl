set baseDir [lindex $argv 0]
set argv [lrange $argv 1 end]
set cmd [lindex $argv 0]

file mkdir $baseDir

proc save_memo {path content} {
    set ts [clock format [clock seconds] -format "%Y%m%d%H%M%S"]
    set filename "$ts.txt"
    set f [open [file join $path $filename] w]
    foreach line [split $content \n] {
        if {[string trim $line] ne ""} { puts $f $line }
    }
    close $f
    puts "Created $filename"
}

proc show_list {path} {
    set files [lsort -decreasing [glob -nocomplain -tails -directory $path *.txt]]
    set i 1
    foreach f $files { puts "$i $f"; incr i }
}

proc show_help {} {
    set entries {
        {"<text>"       "Crea un nuevo memo."}
        {"list"         "Muestra la lista de memos."}
        {"cat <id>"     "Muestra el contenido de un memo."}
        {"copy <id>"    "Copia el contenido de un memo al portapapeles."}
        {"open <id>?"   "Abre memo o la carpeta de memos."}
        {"edit <id>"    "Abre vi para editar un memo."}
        {"rm <ids>"     "Elimina uno o varios memos (ej. 1,2,3)."}
        {"paste"        "Crea un memo desde el portapapeles."}
        {"help"         "Muestra esta ayuda."}
    }
    set max_len 0
    foreach entry $entries {
        set raw_cmd [lindex $entry 0]
        if {[string length $raw_cmd] > $max_len} { set max_len [string length $raw_cmd] }
    }
    set red "\u001b\[31m"; set grn "\u001b\[32m"; set cyn "\u001b\[36m"; set end "\u001b\[0m"; set dim "\u001b\[2m"; set rst "\u001b\[22m"
    foreach entry $entries {
        set raw_cmd [lindex $entry 0]
        set action [lindex [split $raw_cmd] 0]
        set colored_cmd $raw_cmd
        if {$action eq "rm"} {
            set colored_cmd [string map [list $action "${red}${action}${end}"] $colored_cmd]
        } elseif {$action eq "edit" || $action eq "paste" || $action eq "copy" || $action eq "open"} {
            set colored_cmd [string map [list $action "${grn}${action}${end}"] $colored_cmd]
        } else {
            set colored_cmd [string map [list $action "${cyn}${action}${end}"] $colored_cmd]
        }
        set padding [string repeat " " [expr {$max_len - [string length $raw_cmd]}]]
        puts [format "%s%s    ${dim}%s${rst}" $colored_cmd $padding [lindex $entry 1]]
    }
}

switch $cmd {
    "list" { show_list $baseDir }
    "cat" {
        set files [lsort -decreasing [glob -nocomplain -tails -directory $baseDir *.txt]]
        set target [lindex $files [expr {[lindex $argv 1] - 1}]]
        if {$target ne ""} { puts [read [open [file join $baseDir $target] r]] }
    }
    "open" {
        if {[llength $argv] > 1} {
            set files [lsort -decreasing [glob -nocomplain -tails -directory $baseDir *.txt]]
            set target [lindex $files [expr {[lindex $argv 1] - 1}]]
            if {$target ne ""} { exec open [file join $baseDir $target] }
        } else {
            exec open $baseDir
        }
    }
    "copy" {
        set files [lsort -decreasing [glob -nocomplain -tails -directory $baseDir *.txt]]
        set target [lindex $files [expr {[lindex $argv 1] - 1}]]
        if {$target ne ""} {
            set content [read [open [file join $baseDir $target] r]]
            if {[catch {exec xclip -selection clipboard << $content}]} {
                catch {exec pbcopy << $content}
            }
            puts "Copied $target"
        }
    }
    "edit" {
        set files [lsort -decreasing [glob -nocomplain -tails -directory $baseDir *.txt]]
        set target [lindex $files [expr {[lindex $argv 1] - 1}]]
        if {$target ne ""} { exec vi [file join $baseDir $target] <@stdin >@stdout 2>@stderr }
    }
    "rm" {
        set files [lsort -decreasing [glob -nocomplain -tails -directory $baseDir *.txt]]
        set ids [split [lindex $argv 1] ","]
        foreach id $ids {
            set target [lindex $files [expr {$id - 1}]]
            if {$target ne ""} {
                file delete [file join $baseDir $target]
                puts "Deleted $target"
            }
        }
    }
    "paste" {
        if {[catch {exec xclip -o} content]} {
            if {[catch {exec pbpaste} content]} { return }
        }
        save_memo $baseDir $content
    }
    "append" {
      set files [lsort -decreasing [glob -nocomplain -tails -directory $baseDir *.txt]]
      if {[llength $argv] > 1} {
          set target [lindex $files [expr {[lindex $argv 1] - 1}]]
      } else {
          set target [lindex $files 0]
      }
      if {$target ne ""} {
          if {[catch {exec xclip -o} content]} {
              if {[catch {exec pbpaste} content]} { return }
          }
          set f [open [file join $baseDir $target] a]
          puts $f $content
          close $f
          puts "Appended to $target"
      }
    }
    "help" { show_help }
    "" { show_list $baseDir }
    default { save_memo $baseDir [join $argv " "] }
}
