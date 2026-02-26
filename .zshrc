# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
source ~/dotfiles/config.sh

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/$USER/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME=$zshtheme

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
git
zsh-syntax-highlighting
zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

#/*
#|--------------------------------------------------------------------------
#| Constants
#|--------------------------------------------------------------------------
#*/

bearPath="~/Library/Group\ Containers/9K33E3U3T4.net.shinyfrog.bear/Application\ Data"
notabilityPath="~/Library/Mobile\ Documents/ZP9ZJ4EF3S~com~gingerlabs~Notability/Documents"


#/*
#|--------------------------------------------------------------------------
#| Alises
#|--------------------------------------------------------------------------
#*/

# For a full list of active aliases, run `alias`.
alias update="source ~/.zshrc"
#alias edit="vi ~/.zshrc"

timestamp=$(date +%Y-%m-%d-%H:%M:%S)

#/*
#|--------------------------------------------------------------------------
#| Paths
#|--------------------------------------------------------------------------
#*/


# Note adding $PATH at the beginning seems to have a priority effect.
# Which is useful if we have different versions of a binary that we want to use as default
# Add basic system routes
export PATH="/bin:/usr/bin:/usr/local/bin:$PATH"

# Add composer
export PATH="$PATH:~/.composer/vendor/bin"

# Add ruby bins
export PATH="/usr/local/opt/ruby/bin:$PATH"
export PATH="/usr/local/lib/ruby/gems/2.7.0/bin:$PATH"

# Add swift compiler binaries
export PATH="/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:$PATH"

# Add hombre bins
export PATH="/opt/homebrew/bin:$PATH"

# Add Go y GOPATH al final, ya que no son prioritarios
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$GOPATH/bin"


# Initial config commands
init() {
	ln -s ~/dotfiles/XcodeSnippets ~/Library/Developer/Xcode/UserData/CodeSnippets
}

#/*
#|--------------------------------------------------------------------------
#| Quick Navigation
#|--------------------------------------------------------------------------
#*/

# 1. Create symlinks folder: mkdir ~/.symlinks
# 2. Put there some symlinks
finder() { open ~/.symlinks/$1 }
# todo alias() up { $1 for each 0.in..$1 ../.. }
alias up='cd ../..'
edit() {
	if [[ -z "$*" ]]; then
		vi ~/.zshrc
	else
		vi ~/.symlinks/dotfiles/modules/$1.sh
	fi
}

list() {
	if [[ "$*" == *modules* ]]; then
		ls ~/.symlinks/dotfiles/modules
	else
		ls -ld .?*
	fi
}

#/*
#|--------------------------------------------------------------------------
#| Misc
#|--------------------------------------------------------------------------
#*/
code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}
mock() { fastlane testbuddy type:$1 }
killsims() { xcrun simctl shutdown all }
flushCache() { sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder }
xcode() { open -a Xcode $1 }
nova() { open -a "/Applications/Apps/dev/Nova 9.6.app" "$@" }

#/*
#|--------------------------------------------------------------------------
#| Imports
#|--------------------------------------------------------------------------
#*/

source ~/dotfiles/modules/git.sh
source ~/dotfiles/modules/brew-config.sh
source ~/dotfiles/modules/misc.sh
source ~/dotfiles/modules/emoji-mapper.sh

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
# source /Users/cpatinor/dev/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# bun completions
[ -s "/Users/cristian/.bun/_bun" ] && source "/Users/cristian/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

[[ "$TERM_PROGRAM" == "CodeEditApp_Terminal" ]] && . "/Applications/CodeEdit.app/Contents/Resources/codeedit_shell_integration.zsh"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/cristian/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
