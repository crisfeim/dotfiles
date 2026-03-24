function fossil_prompt_info() {
	if [[ -f .fslckout || -f _FOSSIL_ ]]; then
		local branch=$(fossil branch current 2>/dev/null)
		# %F{62} -> Índigo
		# %F{209} -> Salmón
		echo -n "%B%F{105}fossil:(%F{209}${branch}%F{105})%b%f "
	fi
}

setopt prompt_subst
PROMPT+='$(fossil_prompt_info)'
