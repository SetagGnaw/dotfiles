# LiteLLM helpers. The CLI runs an OpenAI-compatible proxy that fronts any
# provider (OpenAI, Anthropic, Bedrock, Vertex, Ollama, HF, ...).
# Docs: https://docs.litellm.ai/
#
# Store the master key (used to gate the proxy + admin UI) in
# ~/.litellm_master_key:
#   echo 'sk-...' > ~/.litellm_master_key
#   chmod 600 ~/.litellm_master_key

_litellm_log=/tmp/litellm.log
_litellm_zsh=${(%):-%x}
_litellm_port=4000

if [[ -r "$HOME/.litellm_master_key" ]]; then
  export LITELLM_MASTER_KEY="$(<$HOME/.litellm_master_key)"
fi

# Admin UI login. Defaults to admin / $LITELLM_MASTER_KEY; override by writing
# the desired values to ~/.litellm_ui_username and ~/.litellm_ui_password.
if [[ -r "$HOME/.litellm_ui_username" ]]; then
  export UI_USERNAME="$(<$HOME/.litellm_ui_username)"
fi
if [[ -r "$HOME/.litellm_ui_password" ]]; then
  export UI_PASSWORD="$(<$HOME/.litellm_ui_password)"
fi

# Extra env (DATABASE_URL, LITELLM_SALT_KEY, provider keys, etc.). Format is
# plain shell — put `export FOO=bar` lines in there. chmod 600. Loaded into
# the proxy's subshell only (see _litellm_env) so DB_* etc. don't leak into
# the interactive shell.
_litellm_env() {
  [[ -r "$HOME/.litellm.env" ]] && source "$HOME/.litellm.env"
}

# List all lit* commands with their one-line descriptions (parsed from this file).
lithelp() {
  awk '
    /^# / { buf = (buf ? buf " " : "") substr($0, 3); next }
    /^lit[a-zA-Z_]*\(\)/ {
      name = $1; sub(/\(\).*/, "", name)
      if (buf) printf "  %-10s %s\n", name, buf
      buf = ""; next
    }
    !/^#/ { buf = "" }
  ' "$_litellm_zsh"
}

# Pass-through to the litellm CLI.
lit() { litellm "$@"; }

# Start the proxy in the foreground. Pass `--model <name>` or `--config <path>`.
litserve() { ( _litellm_env; litellm --port "$_litellm_port" "$@" ); }

# Start the proxy in the background, logging to /tmp/litellm.log.
litstart() {
  if curl -fsS -m 1 "http://localhost:$_litellm_port/health/liveliness" >/dev/null 2>&1; then
    echo "litellm already running on :$_litellm_port"
    return 0
  fi
  ( _litellm_env; exec litellm --port "$_litellm_port" "$@" ) </dev/null >"$_litellm_log" 2>&1 &
  local pid=$!
  disown 2>/dev/null
  echo "starting litellm (pid $pid), logs: $_litellm_log"
  local i
  for i in {1..120}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      echo "litellm exited during startup — see $_litellm_log" >&2
      return 1
    fi
    if curl -fsS -m 1 "http://localhost:$_litellm_port/health/liveliness" >/dev/null 2>&1; then
      echo "litellm: up on :$_litellm_port (after ${i}s)"
      return 0
    fi
    sleep 1
  done
  echo "litellm: not ready after 120s (still starting? check $_litellm_log)" >&2
  return 1
}

# Stop the background proxy started by litstart.
litstop() {
  if pkill -f 'litellm --port'; then
    echo "stopped litellm"
  else
    echo "no litellm proxy running"
  fi
}

# Stop the proxy (if running) and start it again. Args forwarded to litstart.
litrestart() {
  litstop
  local i
  for i in {1..10}; do
    pgrep -f 'litellm --port' >/dev/null 2>&1 || break
    sleep 0.2
  done
  litstart "$@"
}

# Check whether the proxy is reachable.
litping() {
  if curl -fsS -m 2 "http://localhost:$_litellm_port/health/liveliness" >/dev/null; then
    echo "litellm: up"
  else
    echo "litellm: down"
    return 1
  fi
}

# Tail the background proxy log.
litlog() {
  if [[ ! -f $_litellm_log ]]; then
    echo "no log at $_litellm_log (run litstart first)" >&2
    return 1
  fi
  tail -f "$_litellm_log"
}

# Health-check configured models (requires running proxy).
lithealth() {
  local out
  out=$(curl -fsS -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-sk-1234}" \
    "http://localhost:$_litellm_port/health") || return $?
  jq . <<< "$out"
}

# List models served by the running proxy.
litmodels() {
  local out
  out=$(curl -fsS -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-sk-1234}" \
    "http://localhost:$_litellm_port/v1/models") || return $?
  jq . <<< "$out"
}

# Quick chat completion against the local proxy. Usage: litchat <model> <prompt...>
litchat() {
  if (( $# < 2 )) || [[ -z $1 ]]; then
    echo "usage: litchat <model> <prompt...>" >&2
    return 1
  fi
  local model=$1; shift
  local out
  out=$(curl -fsS "http://localhost:$_litellm_port/v1/chat/completions" \
    -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-sk-1234}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg m "$model" --arg p "$*" \
      '{model:$m, messages:[{role:"user", content:$p}]}')") || return $?
  jq -r '.choices[0].message.content' <<< "$out"
}

# Generate a random master key and write it to ~/.litellm_master_key (chmod
# 600). Restart the proxy to apply.
litsetkey() {
  local key="sk-$(openssl rand -hex 24)"
  # umask in a subshell so it does not stick to the interactive shell; chmod
  # also tightens a pre-existing file.
  ( umask 077; printf "%s" "$key" > "$HOME/.litellm_master_key" ) \
    && chmod 600 "$HOME/.litellm_master_key" || return 1
  export LITELLM_MASTER_KEY="$key"
  echo "saved ~/.litellm_master_key — restart proxy: litrestart"
}

# Set / change the admin UI password. Prompts (no echo) and writes
# ~/.litellm_ui_password (chmod 600). Restart the proxy to apply.
litsetpw() {
  local pw1 pw2
  printf "New UI password: " >&2; read -rs pw1; echo >&2
  printf "Confirm:         " >&2; read -rs pw2; echo >&2
  if [[ -z "$pw1" || "$pw1" != "$pw2" ]]; then
    echo "passwords empty or don't match" >&2
    return 1
  fi
  ( umask 077; printf "%s" "$pw1" > "$HOME/.litellm_ui_password" ) \
    && chmod 600 "$HOME/.litellm_ui_password" || return 1
  export UI_PASSWORD="$pw1"
  echo "saved ~/.litellm_ui_password — restart proxy: litstop && litstart"
}

# Open the proxy admin UI in the browser.
litui() { open "http://localhost:$_litellm_port/ui"; }

# Open the LiteLLM docs.
litdocs() { open "https://docs.litellm.ai/"; }
