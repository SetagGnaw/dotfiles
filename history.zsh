# Shell history: sizes and file, what gets saved (only commands that ran and
# exited 0), helpers to inspect/prune the file, and search keys.
# Sourced from .zshrc after oh-my-zsh (whose lib/history.zsh defaults these
# options override) and before completion.zsh, whose `fzf --zsh` must be the
# last thing to bind ^R.

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

# Keep failed commands out of both autosuggestions and persisted history.
#
# zshaddhistory runs once per command line, after history expansion and with
# every PS2 continuation line included. Returning 1 makes zsh keep the line
# only until the next line is entered (the same "linger" HIST_IGNORE_SPACE
# uses), so up-arrow can still recall a failed command to fix it, but nothing
# reaches HISTFILE or the permanent in-memory list. precmd then re-adds the
# line for real (print -S, split into words so Alt-. and !$ keep working)
# and appends it to HISTFILE if the command exited 0.
autoload -Uz add-zsh-hook
setopt HIST_IGNORE_SPACE
typeset -g  __history_pending_command=
typeset -g  __history_last_saved=
typeset -gi __history_line_executed=0
typeset -gi __history_initialized=0
typeset -g  __history_autosuggest_ignore_base=${ZSH_AUTOSUGGEST_HISTORY_IGNORE-}

__history_capture_line() {
  emulate -L zsh -o extendedglob
  # $1 always ends with the terminating newline; pasted lines may carry more.
  __history_pending_command=${1%%[[:space:]]#}
  return 1
}

# preexec only runs when the line is really executed. It does not run when
# HIST_VERIFY (oh-my-zsh) merely reloads an expanded `!!` line into the
# buffer, in which case $? in precmd would be stale.
__history_mark_line_executed() {
  __history_line_executed=1
}

__history_save_successful_command() {
  local exit_code=$? cmd=$__history_pending_command
  local -i executed=__history_line_executed
  __history_pending_command=
  __history_line_executed=0

  # Seed the dedupe check with the last entry loaded from HISTFILE.
  if (( ! __history_initialized )); then
    __history_initialized=1
    __history_last_saved=${history[$((HISTCMD-1))]:-}
  fi

  # Nothing ran (empty line, Ctrl-C, HIST_VERIFY reload) or a leading space:
  # keep it out.
  [[ -n $cmd && $cmd != [[:space:]]* ]] && (( executed )) || return 0

  # A new line was entered, so the previous lingering entry is gone by now.
  ZSH_AUTOSUGGEST_HISTORY_IGNORE=$__history_autosuggest_ignore_base

  if (( exit_code != 0 )); then
    # The failed line still lingers in $history until the next command line;
    # hide exactly that text from zsh-autosuggestions in the meantime.
    ZSH_AUTOSUGGEST_HISTORY_IGNORE="${__history_autosuggest_ignore_base:+${__history_autosuggest_ignore_base}|}${(b)cmd}"
    return 0
  fi

  # print -S bypasses HIST_IGNORE_DUPS, so collapse consecutive repeats here.
  [[ $cmd == "$__history_last_saved" ]] && return 0
  __history_last_saved=$cmd

  # -S: one argument, split into words like a command line. -r: no escapes.
  print -Sr -- "$cmd"
  [[ -n ${HISTFILE:-} ]] && fc -AI "$HISTFILE"
  return 0
}

add-zsh-hook zshaddhistory __history_capture_line
add-zsh-hook preexec __history_mark_line_executed
add-zsh-hook precmd __history_save_successful_command

__history_entry_is_valid() {
  emulate -L zsh

  local command_text=${1##[[:space:]]#}
  local -a words
  local word

  words=(${(z)command_text}) || return 1

  for word in $words; do
    if [[ $word == [A-Za-z_][A-Za-z0-9_]*=* ]]; then
      continue
    fi

    case $word in
      ('{'|'('|'[['|'!')
        return 0
        ;;
    esac

    whence -w -- "$word" >/dev/null 2>&1
    return $?
  done

  return 0
}

history-list-invalid() {
  emulate -L zsh

  local histfile=${1:-${HISTFILE:-$HOME/.zhistory}}
  local entry=
  local line
  local command_text
  local entry_label
  integer invalid_count=0

  if [[ ! -f $histfile ]]; then
    print -u2 -- "history-list-invalid: history file not found: $histfile"
    return 1
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line == ': '*';'* ]]; then
      if [[ -n $entry ]]; then
        command_text=${entry#*;}
        if ! __history_entry_is_valid "$command_text"; then
          print -- "$command_text"
          (( invalid_count++ ))
        fi
      fi
      entry=$line
    else
      entry+=$'\n'"$line"
    fi
  done < "$histfile"

  if [[ -n $entry ]]; then
    command_text=${entry#*;}
    if ! __history_entry_is_valid "$command_text"; then
      print -- "$command_text"
      (( invalid_count++ ))
    fi
  fi

  if (( invalid_count == 1 )); then
    entry_label="entry"
  else
    entry_label="entries"
  fi

  print -- "Found $invalid_count invalid history $entry_label in $histfile"
}

history-prune-invalid() {
  emulate -L zsh

  local histfile=${1:-${HISTFILE:-$HOME/.zhistory}}
  local backup="${histfile}.bak.$(date +%Y%m%d%H%M%S)"
  local tmp="${histfile}.tmp.$$"
  local entry=
  local line
  local command_text
  local entry_label
  integer removed_count=0

  if [[ ! -f $histfile ]]; then
    print -u2 -- "history-prune-invalid: history file not found: $histfile"
    return 1
  fi

  command cp -p "$histfile" "$backup" || return 1

  {
    while IFS= read -r line || [[ -n $line ]]; do
      if [[ $line == ': '*';'* ]]; then
        if [[ -n $entry ]]; then
          command_text=${entry#*;}
          if __history_entry_is_valid "$command_text"; then
            print -r -- "$entry"
          else
            (( removed_count++ ))
          fi
        fi
        entry=$line
      else
        entry+=$'\n'"$line"
      fi
    done < "$histfile"

    if [[ -n $entry ]]; then
      command_text=${entry#*;}
      if __history_entry_is_valid "$command_text"; then
        print -r -- "$entry"
      else
        (( removed_count++ ))
      fi
    fi
  } >| "$tmp" || {
    command rm -f "$tmp"
    return 1
  }

  command mv "$tmp" "$histfile" || return 1

  if (( removed_count == 1 )); then
    entry_label="entry"
  else
    entry_label="entries"
  fi

  print -- "Removed $removed_count invalid history $entry_label from $histfile"
  print -- "Backup saved to $backup"
  print -- "Restart zsh with: exec zsh"
}

history-list-match() {
  emulate -L zsh

  local needle=$1
  local histfile=${2:-${HISTFILE:-$HOME/.zhistory}}
  local entry=
  local line
  local command_text
  integer match_count=0

  if [[ -z $needle ]]; then
    print -u2 -- "usage: history-list-match <substring> [history_file]"
    return 1
  fi

  if [[ ! -f $histfile ]]; then
    print -u2 -- "history-list-match: history file not found: $histfile"
    return 1
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line == ': '*';'* ]]; then
      if [[ -n $entry ]]; then
        command_text=${entry#*;}
        if [[ $command_text == *"$needle"* ]]; then
          print -- "$command_text"
          (( match_count++ ))
        fi
      fi
      entry=$line
    else
      entry+=$'\n'"$line"
    fi
  done < "$histfile"

  if [[ -n $entry ]]; then
    command_text=${entry#*;}
    if [[ $command_text == *"$needle"* ]]; then
      print -- "$command_text"
      (( match_count++ ))
    fi
  fi

  print -- "Found $match_count matching history entries in $histfile"
}

history-prune-match() {
  emulate -L zsh

  local needle=$1
  local histfile=${2:-${HISTFILE:-$HOME/.zhistory}}
  local backup="${histfile}.bak.$(date +%Y%m%d%H%M%S)"
  local tmp="${histfile}.tmp.$$"
  local entry=
  local line
  local command_text
  integer removed_count=0

  if [[ -z $needle ]]; then
    print -u2 -- "usage: history-prune-match <substring> [history_file]"
    return 1
  fi

  if [[ ! -f $histfile ]]; then
    print -u2 -- "history-prune-match: history file not found: $histfile"
    return 1
  fi

  command cp -p "$histfile" "$backup" || return 1

  {
    while IFS= read -r line || [[ -n $line ]]; do
      if [[ $line == ': '*';'* ]]; then
        if [[ -n $entry ]]; then
          command_text=${entry#*;}
          if [[ $command_text == *"$needle"* ]]; then
            (( removed_count++ ))
          else
            print -r -- "$entry"
          fi
        fi
        entry=$line
      else
        entry+=$'\n'"$line"
      fi
    done < "$histfile"

    if [[ -n $entry ]]; then
      command_text=${entry#*;}
      if [[ $command_text == *"$needle"* ]]; then
        (( removed_count++ ))
      else
        print -r -- "$entry"
      fi
    fi
  } >| "$tmp" || {
    command rm -f "$tmp"
    return 1
  }

  command mv "$tmp" "$histfile" || return 1

  print -- "Removed $removed_count matching history entries from $histfile"
  print -- "Backup saved to $backup"
  print -- "Restart zsh with: exec zsh"
}

# History search keys. These are the fallbacks; `fzf --zsh` in completion.zsh
# (sourced later) rebinds ^R to fzf-history-widget.
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward

# bindkey '^R' .history-incremental-search-backward
# bindkey '^S' .history-incremental-search-forward

# bindkey '^R' .history-search-backward
# bindkey '^S' .history-search-forward
