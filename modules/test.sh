test() {
    local base="${1%.test.swift}"
    base="${base%.swift}"
    local file="${base}.test.swift"

    if [[ -f "$file" ]]; then
        swift -I "$HOME/dotfiles/libs/swift/MiniTests" -L "$HOME/dotfiles/libs/swift/MiniTests" -lMiniTests "$file"
    else
        echo "File not found: $file"
    fi
}
