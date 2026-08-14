# 1
Done. To activate (one-time):

```sh
ln -sf /Users/gateswang/Config/zellij/com.gateswang.zellij-bak-sweeper.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.gateswang.zellij-bak-sweeper.plist
```

How it works: launchd's `WatchPaths` uses kqueue to watch `zellij/`. When zellij creates `config.kdl.bak.N`, kqueue fires, the plist's `find ... -exec mv` runs once, the file lands in `backups/`. `RunAtLoad=true` sweeps anything sitting there on first load.

Net change vs my previous answer:
- `3-zsh_files/.zsh_zellij.sh` — precmd hook removed (reverted to original)
- `zellij/com.gateswang.zellij-bak-sweeper.plist` — new launchd agent
- `.gitignore` — unchanged from before (still ignores `zellij/config.kdl.bak*` and `zellij/backups/`)

To uninstall: `launchctl unload ~/Library/LaunchAgents/com.gateswang.zellij-bak-sweeper.plist && rm ~/Library/LaunchAgents/com.gateswang.zellij-bak-sweeper.plist`.

# 2
I verified the fix works correctly. In a fresh shell using a real tty (via `expect`), 4 Enter keys on an empty buffer produced zero new prompts — exactly the intended behavior.

The reason you're still seeing stacked prompts in that `viewjobs` pane is that **zsh widgets are bound at shell startup and persist for the life of the shell**. Any pane that was started *before* commit `fb13e1c` landed still has the old `__history_accept_line` (the one that called `.accept-line` on empty buffers). The widget can't retroactively update — the fix only applies to shells launched after it.

Two ways to verify and fix:

1. **Quick check** — in that pane run `print -- "${widgets[accept-line]}"`. If it says `user:_zsh_autosuggest_bound_1_accept-line` and `declare -f __history_accept_line | grep -c '.accept-line'` returns `1` (only the non-empty branch calls it), the fix is loaded. If `grep -c` returns `2`, the pane is running the pre-fix widget.
2. **Reload** — in the pane, run `exec zsh`. Or close & reopen the layout (`ze` then relaunch).

If after `exec zsh` you still see the issue, let me know and I'll dig further — but based on the pty test, the existing fix is correct.

# 3
Done. Cause: `zellij action rename-pane <name>` (no pane id) targets the *focused* pane. At `zj` startup, 10 panes spawn shells concurrently and each races to rename whichever pane is focused — the last write wins for that pane, leaving 9 with their layout-defined names and 1 mislabeled (here `findcompanies` got tagged `jobs-ai-shared`).

Fix at `3-zsh_files/.zsh_zellij.sh:44`: pass `-p "$ZELLIJ_PANE_ID"` so each shell renames its own pane.

To pick up: `ze` (kill all sessions) → `zj` again. Each pane title should now match its cwd.
