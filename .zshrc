# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export OS_ACTIVITY_DT_MODE=disable
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# omz plugin info <plugin_name>

plugins=(
  git
  brew
  aws
  ansible
  aliases
  zsh-syntax-highlighting
  zsh-autosuggestions
  fzf-tab
  uv
  task
  terraform
  helm
  argocd
  dirhistory
  vscode
  docker
)

ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
# Dedupe both. fpath especially: oh-my-zsh fingerprints the completion dump
# with "#omz fpath: $fpath" and deletes the dump whenever that line changes
# (oh-my-zsh.sh). Without -U, the prepends below re-add every entry on each
# start, so the fingerprint never matches and compinit rescans thousands of
# completion files every time (~4s).
typeset -U path fpath
# Un-export FPATH. `brew shellenv` in .zprofile exports it, which leaks the
# accumulated list into child shells (zellij pane -> VS Code terminal -> ...),
# where it grows again on every nesting level.
typeset +x FPATH
path=(${(f)"$(<$HOME/Config/path.txt)"} $path)
fpath=(${(f)"$(<$HOME/Config/fpath.txt)"} $fpath)
# test_fpath=(${(f)"$(<fpath.txt)"})
# print -l $test_fpath
# echo "${#test_fpath[@]} entries"
# print -l $fpath
# Break zellij env inheritance into grandchild shells (e.g. VS Code / Cursor
# terminals launched from a zellij pane). Otherwise ZELLIJ and ZJ_HIDE_PROMPT
# survive across the process boundary and confuse zellij-specific hooks below.
if [[ ${TERM_PROGRAM:-} == "vscode" && -n ${ZELLIJ:-} ]]; then
  unset ZELLIJ ZELLIJ_PANE_ID ZELLIJ_SESSION_NAME ZJ_HIDE_PROMPT
fi

source $ZSH/oh-my-zsh.sh

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

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Source modular shell config. Order matters where files define helpers
# consumed by later files (navigation -> python; kube/common -> kube/fuzzy,neat).
config_dir="/Users/gateswang/Config"

# Core shell behavior
source "$config_dir/navigation.zsh"
source "$config_dir/shortcuts.zsh"
source "$config_dir/config.zsh"
source "$config_dir/completion.zsh"
source "$config_dir/chrome.zsh"

# Languages
source "$config_dir/languages/java.zsh"
source "$config_dir/languages/javascript.zsh"

# Cloud SDKs
source "$config_dir/cloud/aws.zsh"
source "$config_dir/cloud/gcp.zsh"
source "$config_dir/cloud/oci.zsh"

# Source control
source "$config_dir/git.zsh"
source "$config_dir/github.zsh"
source "$config_dir/transfer.zsh"

# Kubernetes (common.zsh must precede fuzzy/neat/argocd)
source "$config_dir/kube/common.zsh"
source "$config_dir/kube/core.zsh"
source "$config_dir/kube/aliases.zsh"
source "$config_dir/kube/kind.zsh"
source "$config_dir/kube/alloc.zsh"
source "$config_dir/kube/debug.zsh"
source "$config_dir/kube/fuzzy.zsh"
source "$config_dir/kube/neat.zsh"
source "$config_dir/kube/argocd.zsh"

# Infra
source "$config_dir/infra/docker.zsh"
source "$config_dir/infra/prom.zsh"
source "$config_dir/infra/terraform.zsh"
source "$config_dir/infra/packer.zsh"

# System maintenance
source "$config_dir/system/free-disk.zsh"
source "$config_dir/system/free-resources.zsh"
source "$config_dir/system/automation.zsh"

# Build tools
source "$config_dir/build-tools.zsh"

# AI CLIs
source "$config_dir/genai/gemini.zsh"
source "$config_dir/genai/codex.zsh"
source "$config_dir/genai/antigravity.zsh"
source "$config_dir/genai/openclaw.zsh"
source "$config_dir/genai/cursor.zsh"
source "$config_dir/genai/claude.zsh"
source "$config_dir/genai/skills.zsh"
source "$config_dir/genai/agent-browser.zsh"

# AI model servers / gateways
source "$config_dir/huggingface.zsh"
source "$config_dir/genai/litellm.zsh"
source "$config_dir/genai/ollama.zsh"

# Multiplexer
source "$config_dir/zellij.zsh"

# cursor (launcher only — don't prepend bin dir, it shadows VS Code's `code`).
# Also strip it from $path in case a parent process (e.g. VS Code launched
# from a Cursor terminal) injected it into the inherited PATH.
alias cursor='/Applications/Cursor.app/Contents/Resources/app/bin/cursor'
path=(${path:#/Applications/Cursor.app/Contents/Resources/app/bin})

. "$HOME/.moon/bin/env"
export PATH="$HOME/.moon/bin:$PATH"
eval "$(direnv hook zsh)"

# Blank the prompt only inside a "real" zellij pane (TTY connected to the
# zellij server), not in grandchild shells launched from one (e.g. VS Code /
# Cursor terminals that inherit ZELLIJ + ZJ_HIDE_PROMPT through their parent
# process env).
if [[ -n ${ZELLIJ:-} && -n ${ZJ_HIDE_PROMPT:-} && ${TERM_PROGRAM:-} != "vscode" ]]; then
  PROMPT=''
  RPROMPT=''
  PROMPT2=''
  RPROMPT2=''
  PROMPT3=''
  PROMPT4=''
  SPROMPT=''
fi


# Added by Antigravity CLI installer
export PATH="/Users/gateswang/.local/bin:$PATH"

# OpenClaw Completion
[ -f "/Users/gateswang/.openclaw/completions/openclaw.zsh" ] && source "/Users/gateswang/.openclaw/completions/openclaw.zsh"
