
function fossil_prompt_info() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.fslckout" || -f "$dir/_FOSSIL_" ]]; then
            local branch=$(fossil branch current 2>/dev/null)
            local fossil_changes=$(fossil changes 2>/dev/null)
            local fossil_extras=$(fossil extras 2>/dev/null)
            local color="209"  # default

            if [[ -n "$fossil_extras" ]] || echo "$fossil_changes" | grep -qE '^(EDITED|DELETED|MISSING|RENAMED|CONFLICT|UPDATED)'; then
                color="220"  # yellow: there's non tracked/added changes
            elif echo "$fossil_changes" | grep -qE '^ADDED'; then
                color="076"  # green: staged changes added
            fi

            echo -n "%B%F{105}fossil:(%F{${color}}${branch}%F{105})%b%f "
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
