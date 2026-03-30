#!/usr/bin/env bash

run() {
    local file="$1"

    if [[ -z "$file" ]]; then
        echo "Usage: run <file>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "Error: file '$file' not found"
        return 1
    fi

    local ext="${file##*.}"

    case "$ext" in
        swift)        swift "$file" ;;
        js|mjs)       bun "$file" ;;
        ts)           bun "$file" ;;
        py)           python3 "$file" ;;
        rb)           ruby "$file" ;;
        lua)          lua "$file" ;;
        tcl)          tclsh "$file" ;;
        php)          php "$file" ;;
        sh|bash)      bash "$file" ;;
        zsh)          zsh "$file" ;;
        pl)           perl "$file" ;;
        ex|exs)       elixir "$file" ;;

        go)
            go run "$file"
            ;;

        c)
            local out=$(mktemp)
            gcc -o "$out" "$file" && "$out"
            rm "$out"
            ;;

        cpp|cc|cxx)
            local out=$(mktemp)
            g++ -std=c++17 -o "$out" "$file" && "$out"
            rm "$out"
            ;;

        m)
            local out=$(mktemp)
            gcc -o "$out" "$file" -framework Foundation && "$out"
            rm "$out"
            ;;

        java)
            local dir=$(dirname "$file")
            local classname="$(basename "$file" .java)"
            javac "$file" && java -cp "$dir" "$classname"
            rm "$dir/$classname.class"
            ;;

        rs)
            local out=$(mktemp)
            rustc -o "$out" "$file" && "$out"
            rm "$out"
            ;;

        *)
            echo "Error: unknown extension '.$ext'"
            return 1
            ;;
    esac
}
