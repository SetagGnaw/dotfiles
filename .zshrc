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
# TERM_PROGRAM=vscode alone is not the signal: a zellij server started from a
# VS Code terminal hands it to every real pane too. A shell VS Code itself
# spawned has VSCODE_SHELL_INTEGRATION set (unexported, by its injected rc
# before it sources this file) or the editor's pty host ("Code Helper" /
# "Cursor Helper") as its parent process; a real pane's parent is the zellij
# server.
if [[ ${TERM_PROGRAM:-} == "vscode" && -n ${ZELLIJ:-} ]] \
   && { [[ -n ${VSCODE_SHELL_INTEGRATION:-} ]] \
        || [[ "$(ps -o comm= -p "$PPID" 2>/dev/null)" == *" Helper"* ]]; }; then
  unset ZELLIJ ZELLIJ_PANE_ID ZELLIJ_SESSION_NAME ZJ_HIDE_PROMPT
fi

source $ZSH/oh-my-zsh.sh

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
# consumed by later files (navigation -> python; kube/common -> kube/fuzzy,neat;
# history -> completion, whose `fzf --zsh` must be the last to bind ^R).
config_dir="/Users/gateswang/Config"

# Core shell behavior
source "$config_dir/navigation.zsh"
source "$config_dir/shortcuts.zsh"
source "$config_dir/config.zsh"
source "$config_dir/history.zsh"
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

# Blank the prompt only inside a "real" zellij pane. Grandchild shells
# launched from one (VS Code / Cursor terminals) already had ZELLIJ and
# ZJ_HIDE_PROMPT unset above, so no TERM_PROGRAM test is needed here (it
# would also exclude real panes of a zellij server started from VS Code).
if [[ -n ${ZELLIJ:-} && -n ${ZJ_HIDE_PROMPT:-} ]]; then
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
