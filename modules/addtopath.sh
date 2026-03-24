add_to_path() {
    if [ -d "$1" ]; then
        case ":$PATH:" in
            *":$1:"*) ;;
            *) export PATH="$1:$PATH" ;;
        esac
    fi
}

add_to_path_end() {
    if [ -d "$1" ]; then
        case ":$PATH:" in
            *":$1:"*) ;;
            *) export PATH="$PATH:$1" ;;
        esac
    fi
}
