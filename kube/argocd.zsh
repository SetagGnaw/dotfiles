# ─────────────────────────────────────────────────────────────────────────────
# Fuzzy argocd: fzf-powered interactive app selection
# Requires: fzf, argocd, _kf_* helpers from common.zsh (source common.zsh first)
# ─────────────────────────────────────────────────────────────────────────────
#
#  COMMAND     ARGS          DESCRIPTION
#  ─────────────────────────────────────────────────────────────────────────
#  afc         [server]      fuzzy pick argocd context (server) and switch to it
#  afg         [app]         fuzzy pick app: get (resource tree, sync + health)
#  afd         [app]         fuzzy pick app: diff live cluster vs git
#  afs         [-p] [app]    fuzzy pick app: sync (confirm; -p also prunes)
#  afl         [app]         fuzzy pick app: stream logs (-f)
#  afh         [app]         fuzzy pick app: history, pick revision, rollback
#  afy         [app]         fuzzy pick app: rendered manifests, save or print
#  afrm        [app]         fuzzy pick app(s): delete (tab=multi, with confirm)
#
#  Every command takes an optional app name to skip the picker: afd my-app
# ─────────────────────────────────────────────────────────────────────────────

alias a='argocd'

# ── Helpers ──────────────────────────────────────────────────────────────────

# _af_app: pick an app via fzf, print its name
# Usage: _af_app <header> [extra fzf flags...]
# Column 1 of `argocd app list` is NAME, which is "name" or "ns/name" when the
# app lives outside the argocd namespace. Both forms are valid app refs, so pass
# column 1 through verbatim rather than splitting it.
_af_app() {
  local header="${1:-App: select}"
  shift
  local out
  out=$(argocd app list 2>/dev/null)
  if [[ -z "$out" ]]; then
    echo "No apps listed. Check 'argocd context' and 'argocd login <server>'." >&2
    return 1
  fi
  printf '%s\n' "$out" \
    | _kf_fzf --header-lines=1 --header="$header" "$@" \
    | awk '{print $1}'
}

# _af_resolve: use "$1" as the app name if given, else fall back to the picker
_af_resolve() {
  local given="$1" header="$2"
  if [[ -n "$given" ]]; then
    printf '%s\n' "$given"
  else
    _af_app "$header"
  fi
}

# ── Commands ─────────────────────────────────────────────────────────────────

# afc: switch argocd context (server), like kubectx for argocd
# Usage: afc [server]
afc() {
  if [[ -n "$1" ]]; then
    argocd context "$1"
    return
  fi
  local sel
  sel=$(argocd context 2>/dev/null \
    | _kf_fzf --header-lines=1 --header="Context: select argocd server") || return
  # Column 1 is "*" for the current context, so the name shifts one column over.
  local name
  name=$(printf '%s\n' "$sel" | awk '{print ($1 == "*") ? $2 : $1}')
  [[ -z "$name" ]] && return 1
  argocd context "$name"
}

# afg: get an app (resource tree, sync status, health)
# Usage: afg [app]
afg() {
  local app
  app=$(_af_resolve "$1" "Get: select app") || return
  [[ -z "$app" ]] && return 1
  argocd app get "$app"
}

# afd: diff live cluster against git desired state
# Usage: afd [app]
# Note: `argocd app diff` exits 1 when a diff exists. That is success, not
# failure, so do not chain it with &&.
afd() {
  local app
  app=$(_af_resolve "$1" "Diff: select app") || return
  [[ -z "$app" ]] && return 1
  argocd app diff "$app"
}

# afs: sync an app to its git desired state
# Usage: afs [-p] [app]     -p also prunes resources git no longer declares
afs() {
  local prune=0
  local -a passargs=()
  for arg in "$@"; do
    case "$arg" in
      -p|--prune) prune=1 ;;
      *)          passargs+=("$arg") ;;
    esac
  done

  local app
  app=$(_af_resolve "${passargs[1]}" "Sync: select app") || return
  [[ -z "$app" ]] && return 1

  local -a prune_flag=(); (( prune )) && prune_flag=(--prune)

  echo "\n$ argocd app sync $app ${prune_flag[*]}"
  (( prune )) && echo "  PRUNE: resources absent from git will be DELETED."
  _kf_confirm "Run?" || { echo "Aborted."; return 1; }
  argocd app sync "$app" "${prune_flag[@]}"
}

# afl: stream logs for an app's pods
# Usage: afl [app] [extra argocd app logs flags]
afl() {
  local app
  app=$(_af_resolve "$1" "Logs: select app") || return
  [[ -z "$app" ]] && return 1
  shift 2>/dev/null
  argocd app logs "$app" -f "$@"
}

# afh: show history, pick a revision, roll back to it
# Usage: afh [app]
afh() {
  local app
  app=$(_af_resolve "$1" "History: select app") || return
  [[ -z "$app" ]] && return 1

  local hist
  hist=$(argocd app history "$app" 2>/dev/null)
  if [[ -z "$hist" ]]; then
    echo "No history for $app." >&2
    return 1
  fi

  local sel
  sel=$(printf '%s\n' "$hist" \
    | _kf_fzf --header-lines=1 --header="Rollback: select revision of $app") || return

  # Column 1 of `argocd app history` is the revision ID.
  local id
  id=$(printf '%s\n' "$sel" | awk '{print $1}')
  [[ -z "$id" ]] && return 1

  echo "\n$ argocd app rollback $app $id"
  _kf_confirm "Roll back?" || { echo "Aborted."; return 1; }
  argocd app rollback "$app" "$id"
}

# afy: rendered manifests for an app, saved to file or printed
# Usage: afy [app]
afy() {
  local app
  app=$(_af_resolve "$1" "Manifests: select app") || return
  [[ -z "$app" ]] && return 1
  argocd app manifests "$app" | _kf_save
}

# afrm: delete app(s) with confirmation (multi-select)
# Usage: afrm [app]
afrm() {
  local -a apps
  if [[ -n "$1" ]]; then
    apps=("$1")
  else
    apps=(${(f)"$(_af_app 'DELETE: select app(s)  [tab=multi]' --multi)"}) || return
  fi
  (( ${#apps[@]} == 0 )) && return 1

  echo "About to delete ${#apps[@]} app(s):"
  printf '  %s\n' "${apps[@]}"
  _kf_confirm "Confirm delete?" || { echo "Aborted."; return 1; }

  local app
  for app in "${apps[@]}"; do
    argocd app delete "$app" -y
  done
}
