# --- Internal Support Functions ---
_vcs_type() {
	if [[ -f .fslckout || -f _FOSSIL_ ]]; then
		echo "fossil"
	elif git rev-parse --is-inside-work-tree &>/dev/null; then
		echo "git"
	else
		echo "none"
	fi
}

_currentBranch() {
	case $(_vcs_type) in
		fossil) fossil branch current 2>/dev/null ;;
		git)    git branch --show-current 2>/dev/null ;;
	esac
}

# --- Unified VCS Functions ---

prefix() { rename "$1-$(_currentBranch)" }
suffix() { rename "$(_currentBranch)-$1" }


mki() {
		if [ "$1" = "git" ]; then
				cp ~/dotfiles/misc/ignore-template.txt .gitignore
		elif [ "$1" = "fossil" ]; then
				mkdir -p .fossil-settings
				cp ~/dotfiles/misc/ignore-template.txt .fossil-settings/ignore-glob
		else
				echo $unhandledMsg
		fi
}

add() {
	case $(_vcs_type) in
		fossil) fossil add "$@";;
		git)    git add "$@";;
	esac
}

status() {
	case $(_vcs_type) in
		fossil) fossil status ;;
		git)    git status ;;
	esac
}

pull() {
	case $(_vcs_type) in
		fossil) fossil pull ;;
		git)    git pull origin $(_currentBranch) ;;
	esac
}

fetch() {
	case $(_vcs_type) in
		fossil) fossil pull ;; 
		git)    git fetch -p ; pull ;;
	esac
}

checkout() {
	case $(_vcs_type) in
		fossil) fossil update "$@" ;;
		git)    git checkout "$@" ;;
	esac
}

create() {
	case $(_vcs_type) in
		fossil) fossil branch new "$1" $(_currentBranch) ; fossil update "$1" ;;
		git)    git checkout -b "$1" ;;
	esac
}

commit() {
	case $(_vcs_type) in
		fossil) fossil commit -m "$1" ;;
		git)    git commit -m "$1" ;;
	esac
}

addcommit() {
	add .

	if [ "$1" = "." ]; then
		commit "$(date -u '+%Y-%m-%d %H:%M:%S')"
	else
		commit "$1"
	fi
}

pushcommit() {
	addcommit $1;
	push
}

push() {
	if [[ "$*" == *dotfiles* ]]; then
		cd ~/dotfiles
		addcommit "$updateMessage"
		git push origin $(_currentBranch)
	else
		case $(_vcs_type) in
			fossil) fossil push ;;
			git)    
				[[ "$*" == *new* ]] && addcommit "$updateMessage"
				git push origin $(_currentBranch) 
				;;
		esac
	fi
}

log() {
	case $(_vcs_type) in
		fossil) 
			local target=${1:-$(_currentBranch)}
			fossil timeline parents "$target" ;;
		git)    
			git log ;;
	esac
}

branch() {
	case $(_vcs_type) in
		fossil) 
			fossil branch list | while read -r line; do
				local is_current="  "
				local bname="$line"
				if [[ "$line" == "*"* ]]; then
					is_current="\033[1;38;5;62m*\033[0m "
					bname=$(echo "$line" | cut -c 3-)
				else
					bname=$(echo "$line" | sed 's/^[[:space:]]*//')
				fi
				local last_date=$(fossil timeline -n 1 -b "$bname" -t ci 2>/dev/null | grep -E '^[0-9]{2}:[0-9]{2}' | head -n 1 | awk '{print $1}')
				[[ -z "$last_date" ]] && last_date="no commits"
				echo -e "${is_current}\033[38;5;209m${bname}\033[0m \033[38;5;242m(${last_date})\033[0m"
			done
			;;
		git)    
			git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' 
			;;
	esac
}

delete() {
	if [[ "$1" == "remote" ]]; then
		[[ -z "$2" ]] && echo "Missing remote branch name" || deleteRem "$2"
	elif [[ "$1" == "repo" ]]; then
		gh repo delete "$2" --yes
	elif [[ "$1" == "deriveddata" ]]; then
		rm -rf ~/Library/Developer/Xcode/DerivedData
	else
		case $(_vcs_type) in
			fossil) fossil tag add closed "$1" --raw ; echo "Branch $1 closed in Fossil." ;;
			git)    git branch -D "$1" ;;
		esac
	fi
}

rename() {
	case $(_vcs_type) in
		fossil) 
			local old=$(_currentBranch)
			fossil branch new "$1" "$old" ; fossil update "$1"
			fossil tag add closed "$old" --raw
			echo "Renamed: $old -> $1 (previous branch closed)"
			;;
		git)    git branch -M "$1" ;;
	esac
}

squash() {
	if [[ "$1" == "from" ]]; then
		[[ -z "$2" ]] && echo "Missing squash commit name" || squashFrom "$2"
	else
		case $(_vcs_type) in
			fossil) echo "Fossil: Squash not supported (immutable history)." ;;
			git)    git rebase -i HEAD~"$1" ;;
		esac
	fi
}

append() {
	case $(_vcs_type) in
		fossil) 
			echo "Fossil: 'append' not supported (history is immutable). Please make a new commit." 
			;;
		git)    
			git add . ; git commit --amend --no-edit 
			;;
	esac
}

amend() {
	case $(_vcs_type) in
		fossil) 
			echo "Fossil: 'amend' not supported. Use 'fossil commit' for a new check-in." 
			;;
		git)    
			git commit --amend -m "$1" 
			;;
	esac
}

stash() {
	case $(_vcs_type) in
		fossil) fossil stash save "Stash $(date +%H:%M)" ;;
		git)    git stash ;;
	esac
}

extras() {
	case $(_vcs_type) in
		fossil) fossil extras;;
		git)    git ls-files --others --exclude-standard ;;
	esac
}

pop() {
	case $(_vcs_type) in
		fossil) fossil stash pop ;;
		git)    git stash pop ;;
	esac
}

# --- Direct Compatibility Aliases ---
deleteRem() { git push origin --delete "$1" }
squashFrom() { git rebase -i "$1" }
revert() { [[ $(_vcs_type) == "fossil" ]] && fossil revert "$@" || git restore "$@" }
restore() { [[ $(_vcs_type) == "fossil" ]] && fossil revert "$@" || git restore "$@" }
tag() { [[ $(_vcs_type) == "fossil" ]] && fossil tag add "$1" current || git tag "$1" }
diffs() { [[ $(_vcs_type) == "fossil" ]] && fossil diff || git diff HEAD^1 }
remove() { [[ $(_vcs_type) == "fossil" ]] && fossil forget "$@" || git rm --cached "$@" }
replace()  { delete "$1"; rename "$1" }
override() { delete "$1"; rename "$1" }
aforce() { append ; force }
appendpush() { aforce }
appendforce() { aforce }
force() { 
	case $(_vcs_type) in
		fossil) echo "Fossil: Push force not supported." ;;
		git) git push -f origin $(_currentBranch) ;;
	esac
}

createRemote() {
	case $(_vcs_type) in
		fossil) echo "Fossil: Configure remote on your Mac Mini using 'fossil remote add'." ;;
		git)    gh repo create "$1" --public --source=. --remote=origin --push ;;
	esac
}


clone() {
		if [ -z "$1" ]; then
				echo "Usage: clone crisfeim/repo[/] or clone repo[/]"
				return 1
		fi

		local input="$1"
		local clean_path="${input%/}"
		local repo_url=""
		local target_dir=""

		# if contains "/" at the midle, repo is from other user 
		if [[ "$clean_path" == */* ]]; then
				repo_url="git@github.com:${clean_path}.git"
				target_dir="${clean_path##*/}"
		else
				repo_url="git@github.com:crisfeim/${clean_path}.git"
				target_dir="$clean_path"
		fi

		if command git clone "$repo_url" "$target_dir"; then
				# Si el input original termina en /, entramos
				if [[ "$input" == */ ]]; then
						cd "$target_dir"
				fi
		else
				return 1
		fi
}