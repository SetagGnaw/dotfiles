CONFIGPATH="$HOME/Config"
ZSHPATH="$HOME/.zshrc"

# # Auto-reload zshrc when config files change
# RC_AUTO_RELOAD=true
# _rc_mtime() { stat -f %m "$CONFIGPATH"/**/.*.sh(DN) 2>/dev/null | sort -rn | head -1; }
# _RC_LAST_MTIME=$(_rc_mtime)
# _rc_auto_reload() {
#   [[ "$RC_AUTO_RELOAD" == true ]] || return
#   local cur=$(_rc_mtime)
#   if [[ "$cur" != "$_RC_LAST_MTIME" ]]; then
#     _RC_LAST_MTIME=$cur
#     unset _comp_setup
#     source "$ZSHPATH" && echo "sourced .zshrc (config changed)"
#   fi
# }
# autoload -Uz add-zsh-hook
# add-zsh-hook precmd _rc_auto_reload

function rc(){
  code -n "$CONFIGPATH"
}

function rz(){
  unset _comp_setup
  source $ZSHPATH && echo "sourced .zshrc at $ZSHPATH"
}

function rccache(){
  local cache="${ZSH_CACHE_DIR:-$HOME/.oh-my-zsh/cache}"
  rm -f "$cache/completions/_kubectl"
  rm -f ~/.zcompdump*
  echo "cleared zsh completion cache at $cache/completions/"
}

_fn_tagged_lines(){
  local -A tags
  local -a groups=(
    "rc:       rc rz rccache fns als"
    "shell:    printpath"
    "nav:      mkcd mkcd.. qcd"
    "aws:      prof freetier"
    "github:   ghauth ghdelete ghinit ghcreate"
    "git:      gra gc gca gall gch gchb gcot gcoo gs gl gl1 glr gpl grst gr grt grth"
    "terraform:tfa tfaa tfd tfi tfout tfp"
    "k8s:      kdebug kdr kfcan kfcm kfcr kfd kfe kfg kfl kfla kfrm kfrun kfsec klarm kn knd kneat knp knsvc krew kva"
  )
  for entry in $groups; do
    local cat=${entry%%:*}
    for fn in ${=entry#*:}; do tags[$fn]=$cat; done
  done
  print -l ${(ok)functions} | grep -v '^_' | while read fn; do
    echo "${fn}=${tags[$fn]:-function}"
  done
}

function fns(){
  (( $+commands[python3] )) || { echo "[error] No python executable detected"; return; }
  _fn_tagged_lines | python3 "/Users/gateswang/.oh-my-zsh/plugins/aliases/cheatsheet.py" "$@"
}

function als(){
  (( $+commands[python3] )) || { echo "[error] No python executable detected"; return; }
  { alias; _fn_tagged_lines; } | python3 "/Users/gateswang/.oh-my-zsh/plugins/aliases/cheatsheet.py" "$@";
}
