# Completion Notes

## Debugging

- `which` only searches your path, might not understand functions
- `whence <command>` — best way to untangle if a command is a real program, an alias, or a function
- `whence -v <command>` — tells if binary, alias, builtin, or function
- `whence -f <command>` — prints code of function
- `whence -v _istioctl` — should return path to the completion function if found

## Plugin-managed completions

`argocd` and `helm` are oh-my-zsh plugins (see the `plugins=(...)` list in
`.zshrc`). Each regenerates its own completion into
`~/.oh-my-zsh/cache/completions/` on shell startup, so there is no manual step.
The `helm` plugin also defines aliases (`h`, `hin`, `hun`, `hse`, `hup`);
the `argocd` plugin defines none and is completion-only.

Why regenerating barely matters: these CLIs are cobra-based, and a cobra zsh
completion script does not embed the command tree. It shells out to
`<cli> __complete <words>` at runtime, so a completion file generated a year ago
still completes today's subcommands and flags correctly. The generated stub only
changes when the CLI bumps its cobra version, which is rare.

So a hand-generated `custom/completions/_<cli>` is not a staleness bug, but it is
redundant: `fpath.txt` orders `custom/completions` before `cache/completions`, so
the manual copy shadows the plugin's. Prefer one owner. If a plugin manages a
CLI, drop the `custom/completions/_<cli>` file.

## Brew-managed completions

`kubectx` and `kubens` (the binaries behind the `kctx` / `kns` aliases in
`kube/core.zsh`) come from the `kubectx` brew formula, which installs
`_kubectx` and `_kubens` into `/opt/homebrew/share/zsh/site-functions`. That
directory is already in `fpath`, so there is no manual step. The same one-owner
rule applies: do not also curl copies into `custom/completions`, since that
directory sorts earlier in `fpath` and would shadow the brew-managed files.

## Setup (run once)

```bash
mkdir -p ~/.oh-my-zsh/custom/completions

# for each cli WITHOUT an omz plugin
kind completion zsh > ~/.oh-my-zsh/custom/completions/_kind
kustomize completion zsh > ~/.oh-my-zsh/custom/completions/_kustomize
istioctl completion zsh > ~/.oh-my-zsh/custom/completions/_istioctl

# other
uv generate-shell-completion zsh > ~/.oh-my-zsh/custom/completions/_uv

# kubectx / kubens (kctx, kns): binaries and completions both come from brew
brew install kubectx

# reload
rz
```

