unalias chr chri chrls chrp 2>/dev/null

_chrome_local_state="$HOME/Library/Application Support/Google/Chrome/Local State"

# Open URLs / files in Google Chrome. Forwards extra args after `--args`
# so flags like --new-window land on Chrome rather than `open`.
chr() {
  open -a "Google Chrome" "$@"
}

# Everything after `open --args` is handed to Chrome verbatim (open does not
# resolve it), and Chrome resolves relative paths against its own cwd, not
# ours. Absolutize any argument that names an existing path.
_chrome_abs_args() {
  local a
  reply=()
  for a in "$@"; do
    [[ -e $a ]] && a=${a:A}
    reply+=("$a")
  done
}

# Same, but in an incognito window.
chri() {
  local -a reply
  _chrome_abs_args "$@"
  open -na "Google Chrome" --args --incognito "${reply[@]}"
}

# List Chrome profiles as "<directory>\t<display name>".
chrls() {
  jq -r '.profile.info_cache | to_entries[] | "\(.key)\t\(.value.name // .value.shortcut_name // "?")"' \
    "$_chrome_local_state"
}

# Launch Chrome with a specific profile. With no args, fuzzy-picks from the
# available profiles; otherwise resolves the first arg by display name or
# directory (e.g. "Gates" or "Profile 2") and forwards the rest as URLs/files.
chrp() {
  local dir
  if (( $# == 0 )); then
    # Two columns: display name (sortable, primary key) then [directory].
    local pick
    pick=$(jq -r '
      .profile.info_cache | to_entries[]
      | "\(.value.name // .value.shortcut_name // "?")\t[\(.key)]"
    ' "$_chrome_local_state" \
      | column -t -s $'\t' \
      | fzf --ansi --no-preview --height=40% --layout=reverse \
            --border=rounded --prompt="  " --pointer="▶" \
            --header="Chrome profile") || return 130
    dir=${${pick##*\[}%\]}
  else
    local query=$1
    shift
    dir=$(jq -r --arg q "$query" '
      .profile.info_cache as $c
      | ($c | to_entries[] | select(.value.name == $q or .value.shortcut_name == $q) | .key) // empty
    ' "$_chrome_local_state")
    [[ -z $dir ]] && dir=$query
  fi
  local -a reply
  _chrome_abs_args "$@"
  open -na "Google Chrome" --args --profile-directory="$dir" "${reply[@]}"
}
