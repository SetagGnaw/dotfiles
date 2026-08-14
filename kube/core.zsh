export KUBE_EDITOR='code --wait'

_k() {
  # kubectl auth can-i <verb> <resource> — not covered by upstream completion
  if [[ ${words[2]} == auth && ${words[3]} == can-i ]]; then
    case $CURRENT in
      4) compadd get list watch create update patch delete deletecollection use bind escalate impersonate '*' ;;
      5)
        local cache_file="${ZSH_CACHE_DIR:-$HOME/.oh-my-zsh/cache}/kubectl_api_resources"
        if [[ ! -f "$cache_file" || $(( $(date +%s) - $(stat -f %m "$cache_file") )) -gt 300 ]]; then
          kubectl api-resources --no-headers 2>/dev/null | awk '{print $1}' > "$cache_file"
        fi
        compadd ${(f)"$(<$cache_file)"}
        ;;
    esac
    return
  fi
  words[1]=kubectl
  _kubectl
}

# Force _kubectl fpath file to load no (it re-runs "compdef _kubectl kubectl" on first call,
# which would silently clobber our override below). Loading it eagerly prevents that.
autoload +X _kubectl 2>/dev/null
compdef _k k kubectl


# dry-run shorthand
# zsh:  dr=(--dry-run=client -o yaml); k run pod --image=nginx "${dr[@]}"
# bash: export dr="--dry-run=client -o yaml"; k run pod --image=nginx $dr
dr=(--dry-run=client -o yaml)

# force-delete shorthand
# zsh:  k delete pod my-pod "${no[@]}"
# bash: export no="--force --grace-period=0"; k delete pod my-pod $no
no=(--force --grace-period=0)


function kdr() { kubectl "$@" --dry-run=client -o yaml; }
function _kdr() { words[1]=kubectl; _kubectl; }
compdef _kdr kdr

# resources
kar() { if [[ -n "$1" ]]; then kubectl api-resources | grep -i "$@"; else kubectl api-resources; fi }

# rbac
alias kwho='kubectl auth whoami'

# kubectx
alias kctx='kubectx'
compdef kctx=kubectx

#kubens
alias kns='kubens'
compdef kns=kubens

# krew
: << EOF
  # plugins
  https://krew.sigs.k8s.io/plugins/

  krew <TAB>
  krew install ctx
  # at end
  krew upgrade
EOF
function krew() { kubectl krew "$@"; }
_krew() {
  local cmds=(install list upgrade uninstall search info update version help)
  compadd $cmds
}
compdef _krew krew
