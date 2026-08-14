# Show top memory and CPU hogs
function hogs() {
  echo "=== Top 10 by MEM ==="
  ps -axo pid,rss,pcpu,command= | sort -k2 -rn | head -10 \
    | awk '{printf "%-8s %6.1f MB  %5s%%  ", $1, $2/1024, $3; for(i=4;i<=NF;i++){if($i~/^-/)break;printf "%s ",$i} print ""}'
  echo "\n=== Top 10 by CPU ==="
  ps -axo pid,pcpu,rss,command= | sort -k2 -rn | head -10 \
    | awk '{printf "%-8s %5s%%  %6.1f MB  ", $1, $2, $3/1024; for(i=4;i<=NF;i++){if($i~/^-/)break;printf "%s ",$i} print ""}'
  echo "\n=== Top 10 by THREADS ==="
  top -l 1 -stats pid,threads,mem,cpu,command -o threads -n 10 \
    | awk '/^PID/{flag=1;next} flag'
}

# Interactively kill processes (fzf multi-select). Arg: mem|cpu|threads (default mem)
function killhogs() {
  local mode="${1:-mem}"
  local list header
  case "$mode" in
    cpu)
      list=$(ps -axo pid,pcpu,rss,command= | sort -k2 -rn \
        | awk '{printf "%-8s %5s%%  %6.1f MB  ", $1, $2, $3/1024; for(i=4;i<=NF;i++)printf "%s ",$i; print ""}')
      header="Kill by CPU" ;;
    threads|thread|t)
      list=$(top -l 1 -stats pid,threads,mem,cpu,command -o threads -n 50 \
        | awk '/^PID/{flag=1;next} flag')
      header="Kill by THREADS" ;;
    *)
      list=$(ps -axo pid,rss,pcpu,command= | sort -k2 -rn \
        | awk '{printf "%-8s %6.1f MB  %5s%%  ", $1, $2/1024, $3; for(i=4;i<=NF;i++)printf "%s ",$i; print ""}')
      header="Kill by MEM" ;;
  esac
  local selected=$(echo "$list" \
    | fzf --multi --height=100% --layout=reverse --border \
        --header="$header  |  TAB select  |  ENTER kill  |  ESC quit" \
        --prompt="Search: " --marker="✓"
  )
  [[ -z "$selected" ]] && return
  local pids=($(echo "$selected" | awk '{print $1}'))
  echo "Killing: ${pids[*]}"
  echo "Confirm? (y/n)"
  read -r confirm
  [[ "$confirm" != "y" ]] && return
  for pid in "${pids[@]}"; do
    kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null
  done
}

# Free inactive memory and system caches
function freemem() {
  local before=$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage/{print $NF}')
  echo "Before: ${before:-?} free"

  # Purge inactive memory (needs sudo)
  echo "\n--- purge (inactive memory) ---"
  sudo purge && echo "purge: done"

  # Kill stale claude / tool shells
  if command -v czreap &>/dev/null; then
    echo "\n--- czreap ---"
    czreap
  fi

  # Restart WindowServer-adjacent leakers? Skip — too disruptive.
  # Clear DNS cache (minor, but cheap)
  echo "\n--- DNS cache ---"
  sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder 2>/dev/null \
    && echo "DNS: flushed"

  # Clear user font caches (safe)
  echo "\n--- font cache ---"
  atsutil databases -removeUser 2>/dev/null && echo "font cache: cleared"

  # Quick Look cache
  echo "\n--- QuickLook ---"
  qlmanage -r cache &>/dev/null && echo "QuickLook: reset"

  local after=$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage/{print $NF}')
  echo "\n=== Memory ==="
  echo "Before: ${before:-?} free"
  echo "After:  ${after:-?} free"
  vm_stat | head -6
}

# Kill heavy background apps I don't need while coding
function codemode() {
  local targets=(
    "Slack" "Discord" "Spotify" "zoom.us" "Microsoft Teams"
    "Docker Desktop" "Dropbox" "OneDrive" "Google Drive"
    "Notion" "Obsidian" "Figma" "Photos"
  )
  for app in "${targets[@]}"; do
    local pids=($(pgrep -f "$app" 2>/dev/null))
    if (( ${#pids[@]} )); then
      kill -9 "${pids[@]}" 2>/dev/null && echo "force quit: $app (${#pids[@]} pid(s))"
    fi
  done
  # Purge after quitting
  sudo purge && echo "purge: done"
}

# Uninstall unneeded VS Code extensions (fzf multi-select).
# Heavy/bloaty ones from vscode-extensions.md are pre-marked with ★.
function vscode_trim() {
  command -v code &>/dev/null || { echo "code CLI not on PATH"; return 1 }
  local heavy=(
    ms-vscode.cpptools ms-vscode.cpptools-extension-pack
    ms-vscode.cpptools-themes ms-vscode.cmake-tools
    ms-python.vscode-pylance
    golang.go
    dart-code.dart-code dart-code.flutter
    juanblanco.solidity tintinweb.vscode-vyper
    hashicorp.terraform hashicorp.hcl
    redhat.vscode-yaml redhat.vscode-xml
    google.geminicodeassist
    cweijan.dbclient-jdbc mongodb.mongodb-vscode cweijan.vscode-redis-client
    googlecloudtools.cloudcode
    docker.docker ms-kubernetes-tools.vscode-kubernetes-tools
    ms-toolsai.jupyter ms-toolsai.jupyter-renderers
    ms-toolsai.vscode-jupyter-cell-tags ms-toolsai.vscode-jupyter-slideshow
    ms-toolsai.jupyter-keymap
  )
  local installed=("${(f)$(code --list-extensions)}")
  local lines=()
  for ext in "${installed[@]}"; do
    if (( ${heavy[(Ie)$ext]} )); then
      lines+=("★ $ext")
    else
      lines+=("  $ext")
    fi
  done
  local sorted=$(printf '%s\n' "${lines[@]}" | sort)
  local selected=$(echo "$sorted" \
    | fzf --multi --height=100% --layout=reverse --border \
        --bind="space:toggle,ctrl-a:select-all,ctrl-d:deselect-all" \
        --header="Uninstall extensions  |  ★ = heavy  |  TAB/SPACE toggle  |  C-a all  |  C-d none  |  ENTER confirm" \
        --prompt="Search: " --marker="✓")
  [[ -z "$selected" ]] && return
  local exts=($(echo "$selected" | awk '{print $NF}'))
  echo "Uninstalling: ${exts[*]}"
  echo "Confirm? (y/n)"
  read -r confirm
  [[ "$confirm" != "y" ]] && return
  for ext in "${exts[@]}"; do
    code --uninstall-extension "$ext"
  done
}

# Show current resource usage summary
function resources() {
  echo "=== CPU ==="
  top -l 1 -n 0 | grep -E "^(CPU|Load)"
  echo "\n=== Memory ==="
  top -l 1 -n 0 | grep -E "^(PhysMem|VM)"
  echo "\n=== Swap ==="
  sysctl vm.swapusage | awk -F'= ' '{print $2}'
  echo "\n=== Disk ==="
  df -h / | tail -1
  echo "\n=== Process count ==="
  echo "$(ps -ax | wc -l | tr -d ' ') processes"
}
