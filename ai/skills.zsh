# Claude Code skill management via `npx skills@latest`.

# Known sources for `sk` — add more `owner/repo` entries to grow the picker.
SK_SOURCES=(
  'mattpocock/skills'
)

# Add Claude Code skills via `npx skills@latest add`.
#   sk                -> fzf-pick a source (or type a custom one), then install
#   sk <owner/repo>   -> install from that source directly
sk() {
  local source
  if (( $# > 0 )); then
    source="$*"
  else
    source=$(
      printf '%s\n' "${SK_SOURCES[@]}" \
        | fzf --prompt='Skills source> ' \
              --height=40% --reverse \
              --print-query \
              --header='enter: install · type to add a custom owner/repo' \
        | tail -n1
    )
  fi
  [[ -z "$source" ]] && return 1
  echo "→ npx skills@latest add $source"
  npx skills@latest add "$source"
}

# List installed skills (project by default; -g for global, --json for JSON).
skl() { npx skills@latest list "$@"; }

# Interactive fuzzy search across known skill registries.
skf() { npx skills@latest find "$@"; }

# List available skills in a source repo without installing (default: mattpocock/skills).
skls() { npx skills@latest add "${1:-mattpocock/skills}" -l; }
