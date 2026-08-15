# man pages open in less
export MANPAGER="less"

# Global aliases (zsh only) — expand anywhere in the command line
# L  — pipe output into less:     kubectl get pods L
# S  — pipe output into less -S:     kubectl get pods L
# HL — pipe --help into less:     kubectl get HL
alias -g L="| less"
alias -g S="| less -S"
alias -g HL="--help 2>&1 | less"

alias -g C="2>&1 | pbcopy"
alias -g G="| grep"

alias cl="clear"
alias rmf="rm -rf"

# Print each PATH entry on its own line
function ppath(){
  echo $PATH | tr ':' "\n"
}

# Copy a file with a -2 suffix, preserving extension
# Usage: cp2 filename.txt  →  creates filename-2.txt
cp2() {
  # Split on the basename only, so a dot in a directory component or a
  # dotfile / extension-less name does not produce a bogus target.
  local src=$1 dir=${1:h} base=${1:t} name ext
  if [[ $base == ?*.* ]]; then
    name=${base%.*} ext=.${base##*.}
  else
    name=$base ext=
  fi
  cp "$src" "$dir/${name}-2${ext}"
}

# Explain what a command flag does
# Usage: wtf curl -s
#        wtf git --no-pager
wtf() {
  local cmd="$1" flag="$2" out
  if [[ -z "$cmd" || -z "$flag" ]]; then
    echo "Usage: wtf <command> <flag>"
    return 1
  fi
  # Match the flag anywhere in the option list of a man page entry
  # (e.g. "-P, --no-pager") and at end of line, not only as the first token.
  out=$(man "$cmd" 2>/dev/null | col -b \
    | grep -A 5 -E "^\s+(-[^ ]+, )*${flag}([, =]|$)" | head -20)
  if [[ -n "$out" ]]; then
    print -r -- "$out"
  else
    echo "No man page entry found for '$flag' in '$cmd'. Trying --help..."
    "$cmd" --help 2>&1 | grep -A 3 -E "(^|\s)${flag}[, =]" | head -20
  fi
}

# Kill whatever process is listening on a given port
# Usage: portkill 3000
portkill() {
  # lsof -t prints one pid per line; zsh does not word-split, so collect them
  # into an array before passing to kill.
  local -a pids
  pids=(${(f)"$(lsof -t -i :"$1" -sTCP:LISTEN)"})
  if (( ${#pids} )); then
    echo "Killing process ${pids[*]} on port $1..."
    kill -9 "${pids[@]}"
  else
    echo "Port $1 is already free."
  fi
}

# Set a key-value pair in .vscode/settings.json (creates file if missing)
_vscode_set() {
  local key=$1 value=$2
  mkdir -p .vscode
  if [[ -f .vscode/settings.json ]]; then
    local tmp=$(mktemp)
    jq --arg k "$key" --arg v "$value" '.[$k] = $v' .vscode/settings.json > "$tmp" && mv "$tmp" .vscode/settings.json
  else
    printf '{\n    "%s": "%s"\n}\n' "$key" "$value" > .vscode/settings.json
  fi
}
