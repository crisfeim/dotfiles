function fossil_prompt_info() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.fslckout" || -f "$dir/_FOSSIL_" ]]; then
            local branch=$(fossil branch current 2>/dev/null)
            echo -n "%B%F{105}fossil:(%F{209}${branch}%F{105})%b%f "
            return
        fi
        dir="${dir:h}"
    done
}

setopt prompt_subst
PROMPT+='$(fossil_prompt_info)'
