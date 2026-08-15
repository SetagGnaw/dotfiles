# Packer has no oh-my-zsh plugin. It is built on mitchellh/cli, whose
# `packer -autocomplete-install` just appends the `complete` line below to
# ~/.zshrc. That file is a symlink into this repo, so register it here instead
# and keep the repo as the single source of truth.
if (( $+commands[packer] )); then
  autoload -Uz bashcompinit && bashcompinit
  complete -o nospace -C "$commands[packer]" packer

  p() { command packer "$@"; }
  complete -o nospace -C "$commands[packer]" p
fi
