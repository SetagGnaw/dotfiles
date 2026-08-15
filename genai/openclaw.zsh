# OpenClaw CLI helpers.

# Primary passthrough wrapper.
oc() { command openclaw "$@"; }

# Open the local terminal UI (chat).
occ() { command openclaw chat "$@"; }

# Open the terminal UI connected to the Gateway.
oct() { command openclaw tui "$@"; }

# Run one agent turn through the Gateway.
oca() { command openclaw agent "$@"; }

# Send, read, and manage channel messages.
ocm() { command openclaw message "$@"; }

# Manage connected chat channels and accounts.
och() { command openclaw channels "$@"; }

# Show channel health and recent session recipients.
ocs() { command openclaw status "$@"; }

# Health checks and quick fixes (add --fix to repair).
ocdr() { command openclaw doctor "$@"; }

# Run, inspect, and query the Gateway.
ocg() { command openclaw gateway "$@"; }

# Manage the Gateway service (launchd/systemd).
ocd() { command openclaw daemon "$@"; }

# Open the Control UI with the current token.
ocdash() { command openclaw dashboard "$@"; }

# Interactive configuration (credentials, channels, gateway, agents).
occfg() { command openclaw configure "$@"; }

# Update OpenClaw and inspect update channel status.
ocu() { command openclaw update "$@"; }

# Uninstall the Gateway service and local data (CLI remains).
ocun() { command openclaw uninstall "$@"; }

occonfig() {
  code ~/Config/.vscode/openclaw.code-workspace
}
