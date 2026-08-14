# gra <url> [remote=origin] — add remote and set as upstream for pull/push
function gra(){
    local remote=${2:-origin}
    git remote add $remote $1
    git push -u $remote HEAD  # -u sets upstream so future git pull/push need no args
}

function gs(){
	git status "$@"
}

# gall — stage all, commit, and push
function gall(){
	# safe version
	# git add --all && git commit && git push

	git add --all && git commit
	git push 2> /dev/null
	# git push origin 2>&1 > /dev/null
}

# gup — stage all, commit with message "update", and push
function gup(){
	git add --all && git commit -m "update"
	git push 2> /dev/null
}

# gac — stage all and commit (no push)
function gac(){
	git add --all && git commit "$@"
}

# gcot <file> — keep their version during a merge conflict
function gcot(){
	git checkout --theirs $*
}
# gcoo <file> — keep our version during a merge conflict
function gcoo(){
	git checkout --ours $*
}

# gunlock — remove stale index.lock files (main repo + submodules) if no git process is running
function gunlock(){
	local repo_root
	repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
		echo "gunlock: not inside a git repository" >&2
		return 1
	}
	local git_dir
	git_dir=$(git -C "$repo_root" rev-parse --git-dir 2>/dev/null)
	[[ $git_dir != /* ]] && git_dir="$repo_root/$git_dir"

	local -a locks
	[[ -e "$git_dir/index.lock" ]] && locks+=("$git_dir/index.lock")
	if [[ -d "$git_dir/modules" ]]; then
		local f
		for f in "$git_dir"/modules/**/index.lock(N); do
			locks+=("$f")
		done
	fi
	if (( ${#locks} == 0 )); then
		echo "gunlock: no lock files under $git_dir"
		return 0
	fi
	local running
	running=$(pgrep -fl '(^|/)git( |$)' 2>/dev/null | grep -v "pgrep -fl")
	if [[ -n $running ]]; then
		echo "gunlock: refusing to remove locks — a git process is running:" >&2
		echo "$running" >&2
		return 1
	fi
	local lock
	for lock in "${locks[@]}"; do
		command rm -f "$lock" && echo "gunlock: removed $lock"
	done
}

# gwtls — list worktrees with colorized dir (last path component), HEAD, and branch
alias gwtls="git worktree list | awk 'BEGIN{printf \"\033[1m%-26s %-12s %s\033[0m\n\", \"WORKTREE\", \"HEAD\", \"BRANCH\"} {n=split(\$1,a,\"/\"); printf \"\033[32m%-26s\033[0m \033[33m%-12s\033[0m \033[36m%s\033[0m\n\", a[n], \$2, \$3}'"
