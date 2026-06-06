source ~/dotfiles/setup.sh

export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"
export EDITOR="nvim"
path "/bin"
path "/usr/bin"
path "/usr/local/bin"
path "/usr/local/opt/ruby/bin"
path "/usr/local/lib/ruby/gems/2.7.0/bin"
path "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin"
path "/opt/homebrew/bin"
path "$BUN_INSTALL/bin"
path "/opt/homebrew/opt/openjdk/bin"
path "$PNPM_HOME"
path "$HOME/.config/emacs/bin"
path "$HOME/.local/bin"
path "$HOME/.nimble/bin"

path_end "$HOME/.composer/vendor/bin"
path_end "/usr/local/go/bin"


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/Users/cristian/.opam/opam-init/init.zsh' ]] || source '/Users/cristian/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration
