#/*
#|--------------------------------------------------------------------------
#| Git functions 
#|--------------------------------------------------------------------------
#*/

# lastcommit=$(git rev-parse $branch);
updateMessage="updated from $environment at $timestamp";

currentBranch() {
	local  currentBranch=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
	echo "$currentBranch"
}

prefix() { rename $1-$(currentBranch)  }
suffix() { rename $(currentBranch)-$1 }
add () { git add $1 }
status () { git status }
pull () { git pull origin $(currentBranch) }
fetch () { git fetch -p ; pull }
append () { git add . ; git commit --amend --no-edit }
amend() { git commit --amend -m $1 }
checkout() { git checkout $1 }
squashFrom() { git rebase -i $1 }
deleteRem() { git push origin --delete $1 }
commit() { git commit -m $1 }
clone () { git clone git@github.com:"$1".git }
pick() { git cherry-pick $1 }
stash() { git stash save }
pop() { git stash pop }
restore() { git restore $1 }
rename() { git branch -M $1 }
force() { git push -f origin $(currentBranch) }
addcommit() { git add . ; git commit -m $1 }
replace () { delete $1; rename $1 }
override() { delete $1; rename $1 }
tag() { git tag $1 }
diffs() { git diff HEAD^1 }
rebase() { git rebase --$1 }
appendpush() { aforce }
appendforce() { aforce }
aforce() { append ; force }
 # Removes the specified file from Git's index, but leaves the file on disk. 
 # The --cached flag tells Git to remove the file from the index, but not from the working directory.
remove() { git rm --cached $1 }

branch() { git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))' }

squash () { 
	if [ "$1" = "from" ]; then
		 if [ -z "$2" ]; then
			 echo "Missing squash commit name"
		 else
			 squashFrom "$2"
		 fi
	else
		 git rebase -i HEAD~$1
	fi
}

makeRepo() { 
	if [ "$1" = "repo" ]; then
		gh repo create $2 $3;
	else
		echo "Unhandled"
	fi
}

create() {
		if [ "$1" = ".gitignore" ]; then
				cp ~/dotfiles/modules/gitignore.md .gitignore
		elif [ "$1" = "branch" ]; then
			git checkout -b $2
		elif [ "$1" = "repo" ]; then
			mkdir $2;
			cd $2;
			git init;
			echo "# README" > README.md;
			git add README.md;
			git commit -m "First commit 🎉";
			git branch -M main;
			gh repo create $2 $3;
			git remote add origin git@github.com:crisrojas/$2.git;
			git push -u origin main
		else
				echo "unhandled"
		fi
}

delete() { 
	if [ "$1" = "remote" ]; then
		if [ -z "$2" ]; then
			echo "Missing remote branch name"
		else
			deleteRem "$2"
		fi
	elif [ "$1" = "repo" ]; then
		gh repo delete $2 --yes
	elif [ "$1" = "deriveddata" ]; then
		rm -rf ~/Library/Developer/Xcode/DerivedData
	else 
		git branch -D $1 
	fi
}

push() {
	if [[ "$*" == *dotfiles* ]]; then
		cd ~/dotfiles;
		addcommit $updateMessage
		git push origin $(currentBranch)
	elif [[ "$*" == *bear* ]]; then
		goto bear;
		addcommit $updateMessage
		git push origin master
	elif [[ "$*" == *new* ]]; then
		addcommit $updateMessage
		git push origin $(currentBranch)
	elif [[ "$*" == *criscontent* ]]; then
		goto cristian.lat
		addcommit $updateMessage
		git push origin $(currentBranch)
		curl -X POST -d {} https://api.netlify.com/build_hooks/63531117ba64fa04d1d632a3
	else
 		 git push origin $(currentBranch)
	fi
}

log() {
	if [[ "$*" == *dotfiles* ]]
	then
		cd ~/dotfiles;
		git log
	else
		git log $1
	fi
}

