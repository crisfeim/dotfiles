export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=robbyrussell
plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
)

source "$ZSH/oh-my-zsh.sh"

for module in ~/dotfiles/modules/*.sh(N); do
    source "$module"
done

alias update="source ~/.zshrc"
