# zstyle ':completion:*' menu select
# zstyle ':completion:*' menu interactive
# zstyle ':completion:*' menu search

LISTMAX=9999                            # never ask "see all N possibilities?"
zstyle ':completion:*:default' list-prompt '%SAt %p: TAB for more%s'

# Hide plugin-internal helpers from command completion.
# Names starting with `-` confuse argv parsing if invoked, which can crash the
# completion widget; filter them out at the source.
zstyle ':completion:*:-command-:*' ignored-patterns '-ftb-*' '+autocomplete:*' '_*'
zstyle ':completion:*:functions' ignored-patterns '-ftb-*' '+autocomplete:*' '_*'

# comment out
# autoload -Uz compinit; compinit

# use fzf
source <(fzf --zsh)
# fzf --zsh ends with "bindkey '^I' fzf-completion", which clobbers fzf-tab.
# Restore fzf-tab's Tab binding.
bindkey '^I' fzf-tab-complete

# see completion.md for setup instructions and debugging tips
