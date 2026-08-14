unalias z za 2>/dev/null
z() {
  command zellij "$@"
}
za() {
  command zellij attach "$@"
}
zl() {
  command zellij list-sessions "$@"
}
ze() {
  command zellij kill-all-sessions --yes "$@"
}

# jobs-projects layout
zj() {
  command zellij --layout jobs-projects "$@"
}

# claude layout
unalias zc 2>/dev/null
zc() {
  command /Users/gateswang/Config/.scripts/zc "$@"
}

# codex layout
unalias zo 2>/dev/null
zo() {
  command /Users/gateswang/Config/.scripts/zo "$@"
}

# antigravity layout
unalias zy 2>/dev/null
zy() {
  command /Users/gateswang/Config/.scripts/zy "$@"
}

# claude agents layout: agents stacked on the left, normal term on the right
unalias zag 2>/dev/null
zag() {
  command /Users/gateswang/Config/.scripts/zag "$@"
}

# claude stacked layout: claude on top, empty pane below
zs() {
  command zellij --layout claude-stack "$@"
}

# Attach top-level interactive shells to the default Zellij session.
# Opt-in: set ZELLIJ_AUTO=1 in your environment to enable.
if [[ -n ${ZELLIJ_AUTO:-} && -o interactive && -z ${ZELLIJ:-} && ${TERM_PROGRAM:-} != "vscode" ]] && command -v zellij >/dev/null 2>&1; then
  command zellij attach --create default
fi

# Keep the host terminal title (what VS Code shows on the tab) to just the
# zellij session name, e.g. "likable-ocelot".
#
# Zellij composes the host title (see its make_terminal_title) as
# "<session-name> | <pane-title>", and collapses to just "<session-name>" when
# the pane title is empty. The pane title is the pane's rename-pane name if set,
# otherwise the OSC title the shell emits. So to keep it empty inside zellij:
#   * DISABLE_AUTO_TITLE stops Oh My Zsh writing its "%n@%m:%~" OSC title into
#     the pane (that was the "gateswang@host:~/..." suffix in the tab).
#   * We deliberately do NOT rename the pane to the cwd: the pane name feeds the
#     same host title and would re-introduce a " | <cwd>" suffix.
# Only inside a real zellij pane; grandchild shells already unset ZELLIJ above,
# so plain VS Code terminals keep Oh My Zsh's normal titles.
if [[ -n ${ZELLIJ:-} ]]; then
  DISABLE_AUTO_TITLE=true
  # Clear any title a previous Oh My Zsh precmd already stored on this pane, so
  # the fix also applies to existing panes on `exec zsh` (not just new ones).
  [[ -o interactive ]] && printf '\033]0;\007'
fi
