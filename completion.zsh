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

export HISTSIZE=10000 #set history size
export SAVEHIST=10000 #save history after logout
export HISTFILE=~/.zhistory #history file
setopt INC_APPEND_HISTORY #append into history file
setopt HIST_IGNORE_DUPS #save only one command if 2 common are same and consistent
setopt EXTENDED_HISTORY #add timestamp for each entry
# Don't import other panes' commands live. Up-arrow still shows everything
# loaded at startup, but commands typed in other terminals after this pane
# starts won't bleed into our up-arrow history.
unsetopt SHARE_HISTORY

# Do not `fc -R "$HISTFILE"` here: an interactive zsh reads $HISTFILE itself
# once all rc files have run (so setting HISTFILE after oh-my-zsh.sh is fine),
# and an explicit read on top of that loads every entry twice, which showed
# up as duplicated Up-arrow history. (`zsh -i -c ...` never auto-reads, which
# is why a probe run that way looks like the auto-load is broken.)

# sed -i '' '/kind/d' ~/.zhistory && exec zsh

# comment out
# autoload -Uz compinit; compinit

bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# bindkey '^R' .history-incremental-search-backward
# bindkey '^S' .history-incremental-search-forward

# bindkey '^R' .history-search-backward
# bindkey '^S' .history-search-forward

# use fzf
source <(fzf --zsh)
# fzf --zsh ends with "bindkey '^I' fzf-completion", which clobbers fzf-tab.
# Restore fzf-tab's Tab binding.
bindkey '^I' fzf-tab-complete

# see completion.md for setup instructions and debugging tips
