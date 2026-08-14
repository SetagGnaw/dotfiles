function freedisk() {
  local header=$(df -h / | head -1)
  local before=$(df -h / | tail -1)

  # Homebrew
  echo "\n--- Homebrew ---"
  if command -v brew &>/dev/null; then
    brew cleanup -s 2>/dev/null || true && echo "brew: cleaned"
  fi

  # pip
  echo "\n--- pip ---"
  if command -v pip3 &>/dev/null; then
    pip3 cache purge 2>/dev/null || true && echo "pip: cleaned"
  fi

  # uv
  echo "\n--- uv ---"
  if command -v uv &>/dev/null; then
    uv cache prune --ci 2>/dev/null || true && echo "uv: pruned"
  fi

  # Python __pycache__ under home (top-level projects)
  echo "\n--- Python __pycache__ ---"
  find "$HOME" -maxdepth 5 -type d -name "__pycache__" 2>/dev/null | while read d; do
    rm -rf "$d" 2>/dev/null
  done && echo "Python __pycache__: cleared"

  # npm
  echo "\n--- npm ---"
  if command -v npm &>/dev/null; then
    npm cache clean --force 2>/dev/null || true && echo "npm: cleaned"
  fi

  # # npkill (interactive node_modules cleaner)
  # echo "\n--- npkill ---"
  # if command -v npx &>/dev/null; then
  #   npx npkill
  # fi

  # # macOS system caches (user-level only, no sudo needed)
  # echo "\n--- User caches ---"
  # rm -rf ~/Library/Caches/* 2>/dev/null || true && echo "~/Library/Caches: cleared"

  # # iCloud
  # echo "\n--- iCloud ---"
  # find ~/Library/Mobile\ Documents/com~apple~CloudDocs/ -type f -exec brctl evict {} + 2>/dev/null || true && echo "iCloud: evicted"

  # # Mail downloads
  # echo "\n--- Mail downloads ---"
  # rm -rf ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads/*(N) 2>/dev/null || true && echo "Mail downloads: cleared"

  # # Trash
  # echo "\n--- Trash ---"
  # find ~/.Trash -mindepth 1 -delete 2>/dev/null || true && echo "Trash: emptied"

  # Docker (if running)
  echo "\n--- Docker ---"
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    docker system prune -f 2>/dev/null || true && echo "docker: pruned"
    docker system prune -a --volumes
  fi

  # gem (user-level only, skip system Ruby)
  echo "\n--- gem ---"
  if command -v gem &>/dev/null; then
    gem cleanup --user-install 2>/dev/null || true && echo "gem: cleaned"
  fi

  # cargo
  echo "\n--- cargo ---"
  if command -v cargo &>/dev/null; then
    cargo cache --autoclean 2>/dev/null || true && echo "cargo: cleaned" \
      || { rm -rf ~/.cargo/registry/cache 2>/dev/null || true && echo "cargo registry cache: cleared"; }
  fi

  # go
  echo "\n--- go ---"
  if command -v go &>/dev/null; then
    go clean -cache 2>/dev/null || true && echo "go build cache: cleaned"
    go clean -testcache 2>/dev/null || true && echo "go test cache: cleaned"
    go clean -modcache 2>/dev/null || true && echo "go module cache: cleaned"
    go clean -fuzzcache 2>/dev/null || true && echo "go fuzz cache: cleaned"
  fi

  # git: gc all repos under home (top-level only to avoid deep recursion)
  echo "\n--- git ---"
  find "$HOME" -maxdepth 4 -name ".git" -type d 2>/dev/null | while read gitdir; do
    repo=$(dirname "$gitdir")
    git -C "$repo" gc --auto --quiet 2>/dev/null && echo "git gc: $repo"
  done

  # Xcode derived data
  echo "\n--- Xcode DerivedData ---"
  if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
    rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true && echo "Xcode DerivedData: cleared"
  fi

  local after=$(df -h / | tail -1)
  echo "\n=== Disk Usage ==="
  echo "        $header"
  echo "Before: $before"
  echo "After:  $after"
}


# Usage: largefiles [min_size] [search_dir]
#   min_size: e.g. 500M, 1G (default: 500M)
#   search_dir: directory to search (default: ~)
function largefiles() {
  local min_size="${1:-500M}"
  local search_dir="${2:-$HOME}"
  echo "Searching for files >= $min_size in $search_dir ..."

  local selected
  selected=$(find "$search_dir" -type f -size "+${min_size}" -print0 2>/dev/null \
    | xargs -0 du -h 2>/dev/null \
    | sort -rh \
    | fzf \
        --multi \
        --height=100% \
        --layout=reverse \
        --border \
        --header="Files >= $min_size in $search_dir  |  TAB select  |  ENTER delete  |  ESC quit" \
        --prompt="Search: " \
        --marker="✓" \
        --preview="
          filepath=\$(echo {} | cut -f2-)
          echo '=== Info ==='; ls -lh \"\$filepath\" 2>/dev/null
          echo; echo '=== Path ==='; echo \"\$filepath\"
          echo; file \"\$filepath\" 2>/dev/null
        " \
        --preview-window=right:60%:wrap
  )

  [[ -z "$selected" ]] && return

  local -a files
  local line
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    files+=("${line#*$'\t'}")
  done <<< "$selected"

  printf '\nDeleting %d file(s):\n' "${#files[@]}"
  printf '  %s\n' "${files[@]}"
  printf 'Confirm? (y/n) '
  read -r confirm
  [[ "$confirm" != "y" ]] && return

  for f in "${files[@]}"; do
    echo "Deleting $f..."
    rm -rf "$f"
  done
}


# Usage: unused [days] — default 90 days
function unused(){
  local days="${1:-90}"
  local selected=$(find /usr/local/bin -type f -atime +${days} 2>/dev/null \
    | while read f; do
        local name=$(basename "$f")
        local atime=$(stat -f "%Sa" -t "%b %d %Y" "$f" 2>/dev/null)
        echo "$atime  $name  $f"
      done \
    | sort \
    | fzf \
        --multi \
        --height=100% \
        --layout=reverse \
        --border \
        --header="Binaries not used in ${days}+ days  |  TAB select  |  ENTER remove  |  ESC quit" \
        --prompt="Search: " \
        --marker="✓" \
        --preview="
          name=\$(echo {} | awk '{print \$(NF-1)}')
          echo '=== brew info ==='; brew info \$name 2>/dev/null || echo 'Not a brew package'
          echo; echo '=== man description ==='; man -f \$name 2>/dev/null || true
          echo; echo '=== which ==='; which \$name 2>/dev/null || true
        " \
        --preview-window=right:60%:wrap
  )

  [[ -z "$selected" ]] && return

  local files=($(echo "$selected" | awk '{print $NF}'))
  echo "\nRemoving: ${files[*]}"
  echo "Confirm? (y/n)"
  read -r confirm
  [[ "$confirm" != "y" ]] && return

  for f in "${files[@]}"; do
    echo "Removing $f..."
    sudo rm "$f"
  done
}


# Clear the macOS Apple Neural Engine bundle cache (mediaanalysisd).
# This cache is known to grow unbounded (often tens of GB) on Sonoma/Sequoia.
# Daemon auto-restarts and slowly rebuilds — to suppress regrowth, exclude
# Photos in System Settings → Spotlight / Siri & Spotlight privacy.
function killmediacache() {
  local cache=~/Library/Containers/com.apple.mediaanalysisd/Data/Library/Caches/com.apple.mediaanalysisd/com.apple.e5rt.e5bundlecache
  local before=$(du -sh "$cache" 2>/dev/null | awk '{print $1}')
  echo "ANE cache before: ${before:-not present}"
  killall mediaanalysisd 2>/dev/null && echo "mediaanalysisd: killed" || echo "mediaanalysisd: not running"
  sleep 1
  rm -rf "$cache" 2>/dev/null
  local after=$(du -sh "$cache" 2>/dev/null | awk '{print $1}')
  echo "ANE cache after:  ${after:-cleared}"
}


function brewunused(){
  echo "Scanning brew leaves by last access time..."

  local entries=()
  while read pkg; do
    local bin=$(brew --prefix $pkg 2>/dev/null)/bin
    if [ -d "$bin" ]; then
      local last=$(ls -ltu "$bin" 2>/dev/null | awk 'NR==2{print $6, $7, $8}')
      entries+=("$last  $pkg")
    fi
  done < <(brew leaves)

  local selected=$(printf '%s\n' "${entries[@]}" | sort | fzf \
    --multi \
    --height=100% \
    --layout=reverse \
    --border \
    --header="TAB to select/deselect  |  ENTER to uninstall  |  ESC to quit" \
    --prompt="Search: " \
    --marker="✓" \
    --preview="brew info {-1}" \
    --preview-window=right:60%:wrap
  )

  [[ -z "$selected" ]] && return

  local pkgs=($(echo "$selected" | awk '{print $NF}'))
  echo "\nUninstalling: ${pkgs[*]}"
  echo "Confirm? (y/n)"
  read -r confirm
  [[ "$confirm" != "y" ]] && return

  for pkg in "${pkgs[@]}"; do
    echo "Uninstalling $pkg..."
    brew uninstall "$pkg"
  done
}
