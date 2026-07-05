#!/usr/bin/env bash
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/crisfeim/dotfiles/master/install.sh)"
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    exit 1
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
    git clone https://github.com/crisfeim/dotfiles.git "$DOTFILES_DIR"
fi

if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -d /opt/homebrew/bin ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

brew bundle --file="$DOTFILES_DIR/Brewfile"

link() {
    local src="$1" dest="$2"

    if [[ ! -e "$src" ]]; then
        echo "missing source: $src" >&2
        return 1
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
}

link "$DOTFILES_DIR/configs/nvim"            "$HOME/.config/nvim"
link "$DOTFILES_DIR/configs/sqliterc"        "$HOME/.sqliterc"
link "$DOTFILES_DIR/configs/zed/keymap.json" "$HOME/.config/zed/keymap.json"
link "$DOTFILES_DIR/configs/zed/tasks.json"  "$HOME/.config/zed/tasks.json"
link "$DOTFILES_DIR/configs/grayscale.xccolortheme" \
     "$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes/grayscale.xccolortheme"
link "$DOTFILES_DIR/configs/coderunner/swift.sh" \
     "$HOME/Library/Application Support/CodeRunner/Languages/Swift.crLanguage/Scripts/compile.sh"

link "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

iterm_link() {
	ITERM_PREFS_DIR="$HOME/dotfiles/configs/iterm"
 defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM_PREFS_DIR"
 defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
}


iterm_link

link "$DOTFILES_DIR/configs/.gitignore_global" "$HOME/.gitignore_global"
git config --global core.excludesFile "$HOME/.gitignore_global"
