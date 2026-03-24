source ~/dotfiles/setup.sh

export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"
export GOPATH="$HOME/go"

add_to_path "/bin"
add_to_path "/usr/bin"
add_to_path "/usr/local/bin"
add_to_path "/usr/local/opt/ruby/bin"
add_to_path "/usr/local/lib/ruby/gems/2.7.0/bin"
add_to_path "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin"
add_to_path "/opt/homebrew/bin"
add_to_path "$BUN_INSTALL/bin"
add_to_path "/opt/homebrew/opt/openjdk/bin"
add_to_path "$PNPM_HOME"
add_to_path "$HOME/.config/emacs/bin"
add_to_path "$HOME/.local/bin"

add_to_path_end "$HOME/.composer/vendor/bin"
add_to_path_end "/usr/local/go/bin"
add_to_path_end "$GOPATH/bin"
