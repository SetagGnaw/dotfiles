# Ollama helpers. The local API listens on http://localhost:11434.
# On macOS the menu-bar app starts a server automatically; the background
# helpers below are for headless / SSH sessions.

_ollama_log=/tmp/ollama.log
_ollama_zsh=${(%):-%x}

# List all ol* commands with their one-line descriptions (parsed from this file).
olhelp() {
  awk '
    /^# / { buf = (buf ? buf " " : "") substr($0, 3); next }
    /^ol[a-zA-Z_]*\(\)/ {
      name = $1; sub(/\(\).*/, "", name)
      if (buf) printf "  %-10s %s\n", name, buf
      buf = ""; next
    }
    !/^#/ { buf = "" }
  ' "$_ollama_zsh"
}

# Fuzzy-pick a model from `ollama <list-cmd>`. First column is the model name.
_ol_pick() {
  local header=$1; shift
  "$@" 2>/dev/null \
    | awk 'NR>1 && NF { print $1 }' \
    | fzf --ansi --no-preview --height=40% --layout=reverse --border=rounded \
          --prompt="  " --pointer="▶" --header="$header"
}

# Run an `ollama <sub>` against a picked model when no arg is given;
# otherwise pass through verbatim.
_ol_call() {
  local picker_header=$1 picker_cmd=$2 sub=$3
  shift 3
  if (( $# == 0 )); then
    local m
    m=$(_ol_pick "$picker_header" ${=picker_cmd}) || return 130
    ollama "$sub" "$m"
  else
    ollama "$sub" "$@"
  fi
}

# Start the server in the foreground (Ctrl-C to stop).
olserve() { ollama serve "$@"; }

# Start the server in the background, logging to /tmp/ollama.log.
olstart() {
  if curl -fsS -m 1 http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo "ollama already running on :11434"
    return 0
  fi
  nohup ollama serve >"$_ollama_log" 2>&1 &
  echo "started ollama (pid $!), logs: $_ollama_log"
}

# Stop any local `ollama serve` process started by olstart / olserve.
olstop() {
  if pkill -f 'ollama serve'; then
    echo "stopped ollama"
  else
    echo "no ollama server running"
  fi
}

# Check whether the local API is reachable.
olping() {
  if curl -fsS -m 2 http://localhost:11434/api/tags >/dev/null; then
    echo "ollama: up"
  else
    echo "ollama: down"
    return 1
  fi
}

# Tail the background server log.
ollog() {
  if [[ ! -f $_ollama_log ]]; then
    echo "no log at $_ollama_log (run olstart first)" >&2
    return 1
  fi
  tail -f "$_ollama_log"
}

# List installed models.
ols() { ollama list "$@"; }

# List running (loaded) models and their VRAM usage.
olps() { ollama ps "$@"; }

# Run/chat with a model. No-arg form fuzzy-picks an installed model.
olrun()    { _ol_call "ollama run"    "ollama list" run    "$@"; }

# Pull a model. Usage: olpull <model[:tag]>
olpull() { ollama pull "$@"; }

# Search ollama.com's model library in the browser. Usage: olsearch [query...]
olsearch() {
  local url="https://ollama.com/search"
  if (( $# )); then
    url="$url?q=${(j:+:)@}"
  fi
  open "$url"
}

# Remove a model. No-arg form fuzzy-picks an installed model.
olrm()     { _ol_call "ollama rm"     "ollama list" rm     "$@"; }

# Show model info. No-arg form fuzzy-picks an installed model.
olshow()   { _ol_call "ollama show"   "ollama list" show   "$@"; }

# Unload a running model from memory. No-arg form fuzzy-picks from `ollama ps`.
olunload() { _ol_call "ollama stop"   "ollama ps"   stop   "$@"; }

# Load a model into memory without chatting. No-arg form fuzzy-picks an
# installed model. Optional second arg sets keep_alive (default 1h).
olload() {
  local m=$1 keep=${2:-1h}
  if [[ -z $m ]]; then
    m=$(_ol_pick "ollama load" ollama list) || return 130
  fi
  curl -fsS http://localhost:11434/api/generate \
    -d "{\"model\":\"$m\",\"keep_alive\":\"$keep\"}" >/dev/null \
    && echo "loaded $m (keep_alive=$keep)"
}
