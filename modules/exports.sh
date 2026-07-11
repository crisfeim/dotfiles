path() {
  if [ -d "$1" ]; then
    PATH_CLEAN=$(echo "$PATH" | sed -E "s|:$1:|:|g; s|^$1:||g; s|:$1$||g")
    export PATH="$1:$PATH_CLEAN"
  fi
}

path_end() {
    if [ -d "$1" ]; then
        case ":$PATH:" in
            *":$1:"*) ;;
            *) export PATH="$PATH:$1" ;;
        esac
    fi
}

export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_AUTO_ANALYTICS=1
export HOMEBREW_NO_EMOJI=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_UPDATE_REPORT_ONLY_INSTALLED=1
