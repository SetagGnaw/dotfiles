m(){
    make "$@"
}

j(){
    just "$@"
}
alias je='just --evaluate'

# alias jc='just --choose'
jc() {
    local pick recipe
    pick=$(just --list --unsorted 2>/dev/null | awk '
        /^Available recipes:/ { next }
        /^[ \t]*\[[^]]+\][ \t]*$/ { sub(/^[ \t]+/, ""); print; next }
        /^[ \t]+[a-zA-Z0-9_-]/   { sub(/^[ \t]+/, "  "); print }
    ' | fzf --height=70% --reverse --border --no-mouse --nth=1 \
        --prompt="just> " \
        --header="↑↓ pick · type to filter · ? preview · enter run · esc cancel" \
        --bind "?:toggle-preview" \
        --preview="just --show {1} 2>/dev/null | grep -v '^\['" \
        --preview-window=right:55%:wrap)
    [ -z "$pick" ] && return 1
    case "$pick" in \[*) return 1 ;; esac     # picked a group header — skip
    recipe=$(echo "$pick" | awk '{print $1}')
    local show args
    show=$(just --show "$recipe" 2>/dev/null)
    if echo "$show" | grep -qE '(\*ARGS|\+ARGS|[A-Z_]+\s*:=|[A-Z_]+\s*\?)'; then
      echo "$show"
      echo
      printf "args: "
      read -r args
    fi
    echo ">>> just $recipe $args"
    eval "just $recipe $args"
}
