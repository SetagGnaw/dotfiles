cdpath=(. ..)

_find_upward() {
  local target=$1 dir=$PWD
  while [[ $dir != "/" ]]; do
    if [[ -e "$dir/$target" ]]; then
      echo "$dir"
      return
    fi
    dir=${dir:h}
  done
  return 1
}

function mkcd (){
	mkdir $1
	cd $1
}

function mkcd.. (){
	mkdir ../$1
	cd ../$1
}

# _qcd_resolve <key> — print the directory for a qcd key, non-zero if unknown
_qcd_resolve(){
	case "$1" in
	repos)    print -r -- /Users/gateswang/Programming/repos/ ;;
	learning) print -r -- /Users/gateswang/Programming/repos/learning ;;
	k8s)      print -r -- /Users/gateswang/Programming/repos/learning/02-tools/infra/k8s ;;
	argo)     print -r -- /Users/gateswang/Programming/repos/learning/02-tools/infra/argo ;;
	config)   print -r -- /Users/gateswang/Config ;;
	projects) print -r -- /Users/gateswang/Programming/repos/projects ;;
	go)       print -r -- /Users/gateswang/Programming/repos/projects/go ;;
	claude)   print -r -- /Users/gateswang/.claude ;;
	resume)   print -r -- /Users/gateswang/Documents/job/resume ;;
	jobs)     print -r -- /Users/gateswang/Programming/repos/projects/jobs-project ;;
	vsext)    print -r -- /Users/gateswang/Programming/vscode-extensions ;;
	mcp)      print -r -- /Users/gateswang/Programming/repos/mcp/ ;;
	leetcode) print -r -- /Users/gateswang/Programming/repos/leetcode ;;
	ai)       print -r -- /Users/gateswang/.ai-shared ;;
	*)        return 1 ;;
	esac
}

# _qcd_help — usage and the list of available keys
_qcd_help(){
	echo "usage: qcd <key>   (qcdc <key> opens it in a new VS Code window)"
	echo ""
	echo "keys:"
	echo "  repos     ~/Programming/repos"
	echo "  learning  ~/Programming/repos/learning"
	echo "  k8s       ~/Programming/repos/learning/02-tools/infra/k8s"
	echo "  argo      ~/Programming/repos/learning/02-tools/infra/argo"
	echo "  config    ~/.config (Config)"
	echo "  projects  ~/Programming/repos/projects"
	echo "  go        ~/Programming/repos/projects/go"
	echo "  claude    ~/.claude"
	echo "  resume    ~/Documents/job/resume"
	echo "  jobs      ~/Programming/repos/projects/01-old_projects"
	echo "  vsext     ~/Programming/vscode-extensions"
	echo "  mcp       ~/Programming/repos/mcp/"
	echo "  leetcode  ~/Programming/repos/leetcode"
	echo "  ai        ~/.ai-shared"
}

# quick cd
function qcd(){
	if [[ -z $1 || $1 == help ]]; then
		_qcd_help
		return 0
	fi
	local dir
	dir=$(_qcd_resolve "$1") || {
		echo "qcd: unknown key '$1'"
		echo "run 'qcd' to see available keys"
		return 1
	}
	cd "$dir"
	pwd
	ls
}

# quick cd + open in a new VS Code window
function qcdc(){
	if [[ -z $1 || $1 == help ]]; then
		_qcd_help
		return 0
	fi
	local dir
	dir=$(_qcd_resolve "$1") || {
		echo "qcdc: unknown key '$1'"
		echo "run 'qcd' to see available keys"
		return 1
	}
	code -n "$dir"
}

# TODO: fix
# complete -W "pl pst" qcd

# Override oh-my-zsh's `d`: bare number jumps to that dir-stack slot.
#   d         -> show top 10 entries of the dir stack
#   d 2       -> jump to stack slot 2 as numbered by `dirs -v`
#   d -v ...  -> pass flags through to `dirs`
# Uses `cd -N` because oh-my-zsh sets PUSHD_MINUS, which swaps the meaning of
# `+` and `-`; `-N` is what actually matches the indices in `dirs -v`.
d() {
  if [[ -n $1 ]]; then
    if [[ $1 =~ ^[0-9]+$ ]]; then
      cd "-$1"
    else
      dirs "$@"
    fi
  else
    dirs -v | head -n 10
  fi
}
compdef _dirs d 2>/dev/null
