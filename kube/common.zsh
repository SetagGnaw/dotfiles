# ─────────────────────────────────────────────────────────────────────────────
# Shared helpers for fuzzy kubectl functions
# Sourced before .zsh_kube_fuzzy.sh and .zsh_kube_neat.sh (sort order: c < f < n)
# ─────────────────────────────────────────────────────────────────────────────

# Consistent fzf style
_kf_fzf() {
  /opt/homebrew/bin/fzf --ansi --no-preview \
      --height=40% \
      --layout=reverse \
      --border=rounded \
      --prompt="  " \
      --pointer="▶" \
      "$@"
}

# Resolve kubectl namespace flag from arg
_kf_ns() {
  case "$1" in
    -A|--all-namespaces) echo "-A" ;;
    "")
      local ns
      ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
      echo "-n ${ns:-default}"
      ;;
    *) echo "-n $1" ;;
  esac
}

# Prompt for output file; print content to file or stdout
# Usage: _kf_save_or_print <content-producing-command...>
# e.g.:  _kf_save_or_print kubectl get pod foo -o yaml | kubectl neat
_kf_save() {
  local outfile
  echo -n "Save to file [output.yaml]: " > /dev/tty; read outfile < /dev/tty
  outfile="${outfile:-output.yaml}"
  if [[ "$outfile" == "-" ]]; then
    cat
  else
    cat > "$outfile"
    echo "Saved to $outfile" > /dev/tty
  fi
}

# Fuzzy image picker — shows locally available Docker images as suggestions
# User can filter/select a local image or type a custom one (e.g. registry path)
# Returns the selected or typed image via stdout
_kf_pick_image() {
  local images
  images=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
    | grep -v '<none>' | sort -u)
  # --print-query: always print the query on line 1, selected item on line 2
  # tail -1 gives the selection if chosen, or the typed query if no match selected
  echo "$images" \
    | _kf_fzf --print-query --header="Image: select local Docker image or type custom" \
    | tail -1
}

# Confirm prompt defaulting to yes — returns 1 only if user types n/N
_kf_confirm() {
  local prompt="${1:-Run?}"
  local reply
  read -k1 "reply?$prompt [Y/n] " < /dev/tty
  [[ "$reply" != $'\n' ]] && echo > /dev/tty
  [[ "$reply" =~ ^[Nn]$ ]] && return 1
  return 0
}

# Extract name (and ns-flag) from a selected line
# Sets $KF_NAME and $KF_NS (scoped to caller via local in each func)
_kf_parse_selection() {
  local selection="$1" ns_flag="$2"
  if [[ "$ns_flag" == "-A" ]]; then
    KF_NAME=$(echo "$selection" | awk '{print $2}')
    KF_NS="-n $(echo "$selection" | awk '{print $1}')"
  else
    KF_NAME=$(echo "$selection" | awk '{print $1}')
    KF_NS="$ns_flag"
  fi
}
