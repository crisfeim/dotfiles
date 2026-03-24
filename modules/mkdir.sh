mkdir() {
	command mkdir "$@"
	[ $? -ne 0 ] && return
	local last_arg="${@[-1]}"

	if [[ "$last_arg" == */ ]]; then
		cd "$last_arg"
	fi
}
