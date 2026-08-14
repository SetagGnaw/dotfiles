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
  cp "$1" "${1%.*}-2.${1##*.}"
}

# Explain what a command flag does
# Usage: wtf curl -s
#        wtf git --no-pager
wtf() {
  local cmd="$1" flag="$2"
  if [[ -z "$cmd" || -z "$flag" ]]; then
    echo "Usage: wtf <command> <flag>"
    return 1
  fi
  # Strip leading dashes for grep pattern, keep original for matching
  local pattern="${flag#-}"
  pattern="${pattern#-}"
  man "$cmd" 2>/dev/null | col -b | grep -A 5 -E "^\s+${flag}[, ]" | head -20
  if [[ $? -ne 0 ]]; then
    echo "No man page entry found for '$flag' in '$cmd'. Trying --help..."
    "$cmd" --help 2>&1 | grep -A 3 -E "(^|\s)${flag}[, =]" | head -20
  fi
}

# Kill whatever process is listening on a given port
# Usage: portkill 3000
portkill() {
  local pid=$(lsof -t -i :$1 -sTCP:LISTEN)
  if [ -n "$pid" ]; then
    echo "Killing process $pid on port $1..."
    kill -9 $pid
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
