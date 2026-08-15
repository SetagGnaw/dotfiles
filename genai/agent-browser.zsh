unalias ab abopen abshot absnap abchat abdash abls abp abol abkill 2>/dev/null

# agent-browser: fast browser automation CLI for AI agents.

alias ab='agent-browser'

abopen() { agent-browser open "$@"; }
abshot() { agent-browser screenshot "$@"; }
absnap() { agent-browser snapshot "$@"; }
abchat() { agent-browser chat "$@"; }

# Kill all running agent-browser processes.
abkill() { pkill -f agent-browser; }

# Observability dashboard: `abdash` to start (port 4848) and open in the
# default browser, `abdash stop`, or `abdash start --port N` for a custom port.
abdash() {
  local sub=${1:-start} port=4848 i
  for (( i = 1; i <= $#; i++ )); do
    [[ ${@[i]} == "--port" && -n ${@[i+1]} ]] && port=${@[i+1]}
  done
  agent-browser dashboard "${@:-start}"
  if [[ $sub != "stop" ]]; then
    print "→ http://localhost:$port"
    open "http://localhost:$port"
  fi
}

# Chat with agent-browser using a local ollama model instead of the Vercel AI
# Gateway. Picks $OLLAMA_MODEL or qwen3:8b by default; override with --model.
#   abol "open google.com and search for cats"
#   abol --model qwen2.5:7b "summarize this page"
abol() {
  # agent-browser appends /v1/chat/completions itself, so pass the bare host
  # (a /v1 suffix here would request /v1/v1/chat/completions, a 404 on Ollama).
  AI_GATEWAY_URL="${AI_GATEWAY_URL:-http://localhost:11434}" \
  AI_GATEWAY_API_KEY="${AI_GATEWAY_API_KEY:-ollama}" \
  AI_GATEWAY_MODEL="${AI_GATEWAY_MODEL:-${OLLAMA_MODEL:-qwen3:8b}}" \
  agent-browser chat "$@"
}

# List Chrome profiles agent-browser can reuse.
abls() { agent-browser profiles "$@"; }

# Run agent-browser bound to a Chrome profile.
#   abp                              # fuzzy pick; prints the suggested invocation
#   abp Gates open https://...       # match by display name (resolved to dir)
#   abp "Profile 2" snapshot         # or directly by directory
abp() {
  local profile dir name
  if (( $# == 0 )); then
    local pick
    pick=$(agent-browser profiles 2>/dev/null \
      | sed -nE 's/^  (.+)  \((.+)\)$/\1\t\2/p' \
      | fzf --ansi --no-preview --height=40% --layout=reverse --border=rounded \
            --prompt="  " --pointer="▶" --header="agent-browser profile" \
            --delimiter=$'\t' --with-nth=2,1) || return 130
    profile=${pick%%$'\t'*}
    print -- "agent-browser --profile \"$profile\" <command>"
    return 0
  fi
  local query=$1
  shift
  while IFS=$'\t' read -r dir name; do
    if [[ $name == $query ]]; then
      profile=$dir
      break
    fi
  done < <(agent-browser profiles 2>/dev/null | sed -nE 's/^  (.+)  \((.+)\)$/\1\t\2/p')
  profile=${profile:-$query}
  agent-browser --profile "$profile" "$@"
}
