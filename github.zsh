# Fuzzy-pick which GitHub account is active: switch between logged-in
# accounts or log in to a new one. Falls back to a plain 'gh auth login'
# when no accounts are logged in yet.
function ghauth(){
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: ghauth"
    echo ""
    echo "Fuzzy-select a logged-in GitHub account to make active, or pick"
    echo "the '[ log in to a new account ]' entry to run 'gh auth login'."
    return 0
  fi

  unset GITHUB_TOKEN

  local accounts
  accounts=$(gh auth status 2>/dev/null | awk '
    /Logged in to/ && match($0, /account [^ ]+/) {
      acct = substr($0, RSTART + 8, RLENGTH - 8)
      order[++n] = acct
    }
    /Active account: true/ && acct != "" { active[acct] = 1 }
    END {
      for (i = 1; i <= n; i++)
        printf "%s%s\n", order[i], (order[i] in active ? " (active)" : "")
    }
  ')

  if [[ -z "$accounts" ]]; then
    gh auth login
    return
  fi

  local new_entry="[ log in to a new account ]"
  local choice
  choice=$(printf '%s\n%s\n' "$accounts" "$new_entry" \
    | fzf --no-preview --height=60% --layout=reverse --border=rounded \
      --prompt="ghauth> " \
      --header="ENTER to switch the active GitHub account") || return 1

  if [[ "$choice" == "$new_entry" ]]; then
    gh auth login
    return
  fi

  gh auth switch --user "${choice%% *}"
}

function ghdelete(){
  gh auth refresh -h github.com -s delete_repo
  local repos=($(gh repo list --limit 100 --json nameWithOwner -q '.[].nameWithOwner'))
  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "No repositories found."
    return 1
  fi
  echo "Your repositories:"
  for i in {1..${#repos[@]}}; do
    echo "  $i) ${repos[$i]}"
  done
  echo ""
  read "choices?Select repos to delete (numbers separated by spaces): "
  local selected=()
  for choice in ${=choices}; do
    if [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#repos[@]} ]] 2>/dev/null; then
      selected+=("${repos[$choice]}")
    else
      echo "Skipping invalid selection: $choice"
    fi
  done
  if [[ ${#selected[@]} -eq 0 ]]; then
    echo "No valid repos selected."
    return 1
  fi
  echo ""
  echo "You are about to delete the following repos:"
  for repo in "${selected[@]}"; do
    echo "  - $repo"
  done
  echo ""
  read "confirm?Are you sure? (y/N): "
  if [[ "$confirm" == [yY] ]]; then
    for repo in "${selected[@]}"; do
      gh repo delete "$repo" --confirm
      echo "Deleted $repo."
    done
  else
    echo "Cancelled."
  fi
}

# Create a new private GitHub repo from cwd.
# If already a git repo, just creates the remote and pushes.
# If not, scaffolds README, .gitignore, LICENSE, inits the repo, then pushes.
function ghcreate(){
  if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: ghcreate <repo-name>"
    echo ""
    echo "Creates a new private GitHub repo from the current directory."
    echo "If not already a git repo, initializes one with README.md, .gitignore, and MIT LICENSE."
    return 0
  fi

  unset GITHUB_TOKEN
  gh auth login

  if git rev-parse --git-dir > /dev/null 2>&1; then
    # Already a git repo — just create it on GitHub
    gh repo create "$1" --private --source=. --remote=upstream
    git push --set-upstream upstream "$(git branch --show-current)"
  else
    local template_dir="$HOME/Config/templates"

    echo "# $1" > README.md
    cp "$template_dir/.gitignore" .gitignore
    sed -e "s/YEAR/$(date +%Y)/" -e "s/AUTHOR/$(git config user.name)/" "$template_dir/LICENSE" > LICENSE

    git init -b main
    git add -A
    git commit -m "initial commit"
    gh repo create "$1" --private --source=. --remote=upstream
    git push --set-upstream upstream main
  fi
}

# Open the current repo on GitHub in Chrome. Extra args are forwarded to
# `gh browse` (e.g. a file path, an issue number, or `--branch <name>`).
#
# The repo is resolved from your local remote (origin, then upstream, then
# the first remote) and passed to `gh browse -R`. Without this, when origin
# is a fork, `gh browse` resolves to the upstream parent and opens the wrong
# repo. Pass your own -R/--repo to override.
function ghop(){
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: ghop [gh-browse-args...]"
    echo ""
    echo "Opens your clone's GitHub page in Chrome (a fork opens your fork,"
    echo "not its upstream parent). Extra args are passed to 'gh browse',"
    echo "e.g. a file, an issue number, or --branch. Pass -R to override."
    return 0
  fi

  local remote nwo
  local repo_args=()
  if [[ "$*" != *-R* && "$*" != *--repo* ]]; then
    for remote in origin upstream; do
      git remote get-url "$remote" >/dev/null 2>&1 && break
      remote=
    done
    [[ -z "$remote" ]] && remote=$(git remote 2>/dev/null | head -1)
    if [[ -n "$remote" ]]; then
      nwo=$(git remote get-url "$remote" 2>/dev/null \
        | sed -E 's#^git@[^:]+:##; s#^https?://[^/]+/##; s#\.git$##')
      [[ -n "$nwo" ]] && repo_args=(-R "$nwo")
    fi
  fi

  local url
  url=$(gh browse --no-browser "${repo_args[@]}" "$@") || return 1
  chr "$url"
}

# gsync [-f|--force] — sync your fork with its upstream, then update local.
#
# Runs 'gh repo sync' on your fork's current branch (fast-forwarding it from
# the upstream parent on GitHub), then 'git pull' to bring the local branch
# up to date. Pass -f/--force to overwrite a diverged fork branch.
function gsync(){
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: gsync [-f|--force]"
    echo ""
    echo "Syncs your fork's current branch from its upstream parent via"
    echo "'gh repo sync', then runs 'git pull' to update the local clone."
    echo "Pass -f/--force to overwrite a fork branch that has diverged."
    return 0
  fi

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "gsync: not inside a git repository" >&2
    return 1
  }

  local force_args=()
  [[ "$1" == "-f" || "$1" == "--force" ]] && force_args=(--force)

  local branch nwo
  branch=$(git branch --show-current) || return 1
  if [[ -z "$branch" ]]; then
    echo "gsync: no current branch (detached HEAD?)" >&2
    return 1
  fi

  nwo=$(git remote get-url origin 2>/dev/null \
    | sed -E 's#^git@[^:]+:##; s#^https?://[^/]+/##; s#\.git$##')
  if [[ -z "$nwo" ]]; then
    echo "gsync: could not resolve 'origin' remote" >&2
    return 1
  fi

  echo "Syncing $nwo ($branch) from upstream..."
  gh repo sync "$nwo" --branch "$branch" "${force_args[@]}" || return 1

  echo "Pulling into local $branch..."
  git pull
}

# ghprs: list open PRs for your clone's repo and, when it is a fork, for
# its upstream parent too.
#
# Repos are resolved from the origin and upstream remotes; if origin is a
# fork whose parent is not a configured remote, the parent is looked up on
# GitHub. Extra args are forwarded to 'gh pr list' (e.g. --author @me,
# --state all).
function ghprs(){
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: ghprs [gh-pr-list-args...]"
    echo ""
    echo "Lists open PRs targeting your clone's repo and, when it is a"
    echo "fork, the upstream parent as well. Extra args are passed to"
    echo "'gh pr list', e.g. --author @me or --state all."
    return 0
  fi

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "ghprs: not inside a git repository" >&2
    return 1
  }

  local remote nwo parent
  local -a repos
  for remote in origin upstream; do
    nwo=$(git remote get-url "$remote" 2>/dev/null \
      | sed -E 's#^git@[^:]+:##; s#^https?://[^/]+/##; s#\.git$##')
    [[ -n "$nwo" ]] && (( ! ${repos[(Ie)$nwo]} )) && repos+=("$nwo")
  done

  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "ghprs: could not resolve a GitHub repo from the remotes" >&2
    return 1
  fi

  # A fork's parent may not be a configured remote: ask GitHub for it so
  # PRs targeting the parent are listed too.
  parent=$(gh repo view "${repos[1]}" --json parent \
    -q 'if .parent then .parent.owner.login + "/" + .parent.name else "" end' \
    2>/dev/null)
  [[ -n "$parent" ]] && (( ! ${repos[(Ie)$parent]} )) && repos+=("$parent")

  local repo
  for repo in "${repos[@]}"; do
    echo "== $repo =="
    gh pr list -R "$repo" "$@"
    echo ""
  done
}

# Fuzzy-multi-select from your GitHub repos (skipping ones already cloned,
# per ~/Config/.gh-cloned) and clone them into $PWD. Successful clones are
# recorded so future runs won't offer them again.
function ghclone(){
  local cloned_file="/Users/gateswang/Config/.gh-cloned"

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: ghclone"
    echo ""
    echo "Fuzzy-select (TAB for multiple) from your GitHub repos, skipping"
    echo "ones already recorded in $cloned_file, and clone each selection"
    echo "into the current directory."
    return 0
  fi

  local repos
  repos=$(gh repo list --limit 200 \
    --json nameWithOwner,description \
    -q '.[] | [.nameWithOwner, (.description // "")] | @tsv') || return 1

  if [[ -z "$repos" ]]; then
    echo "No repositories found."
    return 1
  fi

  if [[ -f "$cloned_file" ]]; then
    repos=$(awk -F'\t' -v tracked="$cloned_file" '
      BEGIN { while ((getline line < tracked) > 0) seen[line] = 1 }
      !($1 in seen)
    ' <<< "$repos")
  fi

  if [[ -z "$repos" ]]; then
    echo "Nothing to clone (everything is already in $cloned_file)."
    return 1
  fi

  local selected
  selected=$(echo "$repos" | fzf --multi --no-preview \
    --height=60% --layout=reverse --border=rounded \
    --prompt="ghclone> " \
    --header="TAB to select multiple repos, ENTER to clone" \
    --delimiter='\t' --with-nth=1,2 \
    | cut -f1)

  if [[ -z "$selected" ]]; then
    echo "No repos selected."
    return 1
  fi

  local repo
  while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    echo "Cloning $repo..."
    if gh repo clone "$repo"; then
      echo "$repo" >> "$cloned_file"
    fi
  done <<< "$selected"
}

