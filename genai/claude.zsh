# Claude Code CLI helpers.

# Update claude
cup() { claude update; }
# Reinstall claude (npm global) — clears stale install dir that breaks npm rename
cre() {
  local root="$(npm root -g 2>/dev/null)/@anthropic-ai"
  [[ -d "$root" ]] && rm -rf "$root/claude-code" "$root/.claude-code-"*(N)
  npm install -g @anthropic-ai/claude-code "$@" && hash -r && claude --version
}
# MCP server management
cmcp() { claude mcp "$@"; }
# Plugin management
cplug() { claude plugin "$@"; }
# Background agents view
cag() { claude agents "$@"; }

c() { claude --dangerously-skip-permissions "$@"; }
# Start claude in a new git worktree
cwt() { claude --worktree "$@"; }

# Continue the most recent conversation
ccont() { claude --continue "$@"; }
# Resume a session by ID (or interactive picker)
cres() { claude --resume "$@"; }
# Fork the most recent conversation into a new session
cfork() { claude --continue --fork-session "$@"; }


# Preview helper for cdel
_cdel_preview() {
  local file="$1"
  local project=$(
    basename "$(dirname "$file")" | sed 's|-|/|g'
  )
  local date=$(
    jq -r 'select(.timestamp != null) | .timestamp' "$file" \
      2>/dev/null | head -1 | cut -c1-19 | tr 'T' ' '
  )
  echo "Project : $project"
  echo "Date    : $date"
  echo "---"
  jq -r '
    select(.type=="user" and .message.role=="user")
    | (.message.content | if type=="array" then .[0].text else . end)
    | select(. != null and . != "")
  ' "$file" 2>/dev/null | grep -v '^null$' | head -50
}

# Interactively delete sessions (tab = multi-select)
cdel() {
  local project_dir="$HOME/.claude/projects/$(
    pwd | sed 's|/|-|g'
  )"
  local selected
  selected=$(
    find "$project_dir" -name "*.jsonl" -print0 2>/dev/null \
      | xargs -0 ls -t \
      | awk '{print NR"\t"$0}' \
      | fzf --multi \
          --delimiter='\t' \
          --with-nth='1,2' \
          --prompt="Delete sessions> " \
          --preview "$(functions _cdel_preview); _cdel_preview {2}" \
          --preview-window=right:55%
  )
  [[ -z "$selected" ]] && return
  echo "$selected" | awk -F'\t' '{print $2}' | xargs rm
  echo "Deleted $(echo "$selected" | wc -l | tr -d ' ') session(s)"
}


# Start claude in a zellij session rooted in the Config repo (~/Config),
# leaving $PWD unchanged. Args are forwarded to zc (e.g. `ccfg 2` for 2 panes).
ccfg() { (cd "$HOME/Config" && zc "$@"); }
# Same as ccfg but without zellij: run claude directly in ~/Config.
ccfgp() { (cd "$HOME/Config" && claude "$@"); }

# Toggle bg-session worktree isolation (worktree.bgIsolation in settings.json).
# When ON, background sessions (claude --bg) are forced to isolate into a git
# worktree before editing files; OFF lets them edit the checkout in place.
#   wtguard           # show current state
#   wtguard off       # bg sessions edit in place
#   wtguard on        # bg sessions isolate into a worktree (harness default)
wtguard() {
  local s="$HOME/.claude/settings.json" tmp
  [[ -f "$s" ]] || { echo "no $s" >&2; return 1; }
  case "${1:-status}" in
    off)
      tmp=$(mktemp) && jq '.worktree.bgIsolation = "none"' "$s" >| "$tmp" && mv "$tmp" "$s" \
        && echo "bg-isolation -> off (none)  — bg sessions now edit in place"
      ;;
    on)
      # Drop the key to fall back to the harness default (isolate).
      tmp=$(mktemp) && jq 'del(.worktree.bgIsolation)' "$s" >| "$tmp" && mv "$tmp" "$s" \
        && echo "bg-isolation -> on (worktree)  — bg sessions isolate again"
      ;;
    status|"")
      if [[ "$(jq -r '.worktree.bgIsolation // "worktree"' "$s" 2>/dev/null)" == "none" ]]; then
        echo "bg-isolation: OFF (none) — bg sessions edit in place"
      else
        echo "bg-isolation: ON (worktree) — bg sessions isolate into a worktree"
      fi
      ;;
    *)
      echo "usage: wtguard [on|off|status]" >&2
      return 2
      ;;
  esac
}
