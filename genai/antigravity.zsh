# agy CLI helpers.

# Primary passthrough wrapper.
agy() { command agy "$@"; }

# Backward-compatible alias from the earlier placeholder name.
agv() { agy "$@"; }

# Continue the most recent conversation.
agyc() { command agy --continue "$@"; }

# Resume a previous conversation by ID.
agyr() { command agy --conversation "$@"; }

# Run a single prompt non-interactively.
agyp() { command agy --print "$@"; }

# Run an initial prompt interactively and continue the session.
agyi() { command agy --prompt-interactive "$@"; }

# Add one or more directories to the workspace.
agyadd() { command agy --add-dir "$@"; }

# Manage and inspect models.
agym() { command agy models "$@"; }

# Update the CLI.
agyu() { command agy update "$@"; }

# Install or inspect environment setup.
agyinstall() { command agy install "$@"; }

# Plugin management.
agypg() { command agy plugin "$@"; }
agypgs() { command agy plugins "$@"; }

# Changelog and release notes.
agylog() { command agy changelog "$@"; }

agyconfig() {
  code ~/Config/.vscode/antigravity.code-workspace
}

# Start agy in a zellij session rooted in the Config repo (~/Config),
# leaving $PWD unchanged. Args are forwarded to zy (e.g. `agyconf 2` for 2 panes).
agyconf() { (cd "$HOME/Config" && zy "$@"); }
# Same as agyconf but without zellij: run agy directly in ~/Config.
agyconfp() { (cd "$HOME/Config" && agy "$@"); }

# Run agy with auto-approved permissions.
agyd() { command agy --dangerously-skip-permissions "$@"; }
