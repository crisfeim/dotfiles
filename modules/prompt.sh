
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

doing_prompt_info() {
  local c
  c=$(t @ 2>/dev/null | grep -c . )
  if [ -n "$c" ] && [ "$c" != "0" ]; then
    echo "[$c] "
  fi
}
PROMPT+='$(fossil_prompt_info)$(doing_prompt_info)'
