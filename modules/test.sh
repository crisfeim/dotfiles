test() {
    local base="${1%.test.swift}"
    base="${base%.swift}"
    local file="${base}.test.swift"

    if [[ -f "$file" ]]; then
        swift -I "$HOME/.swift_libs" -L "$HOME/.swift_libs" -lMiniTests "$file"
    else
        echo "File not found: $file"
    fi
}
