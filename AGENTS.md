# Repository Guidelines

## Project Structure & Module Organization

This repository manages local shell, editor, and Zellij configuration.

- `.zshrc` is the main entry point. It configures Oh My Zsh and paths, and sources each `*.zsh` snippet via an explicit ordered list (no globbing).
- Core shell snippets sit at the repo root: `navigation.zsh`, `shortcuts.zsh`, `config.zsh`, `history.zsh`, `completion.zsh`, `chrome.zsh`, `git.zsh`, `github.zsh`, `transfer.zsh`, `build-tools.zsh`, `huggingface.zsh`, `zellij.zsh`.
- `history.zsh` owns everything history-related: HISTFILE/sizes/options, the hooks that persist only commands that ran and exited 0 (`zshaddhistory` + `preexec` + `precmd`, `print -Sr` then `fc -AI`), the `history-list-*` / `history-prune-*` helpers, and the `^R`/`^S` fallback search keys. It must be sourced before `completion.zsh`, whose `fzf --zsh` rebinds `^R`; never add an explicit `fc -R "$HISTFILE"` (interactive zsh reads it itself after the rc files, so that double-loads history).
- `genai/` groups AI CLI helpers and local model servers, one file per tool: `gemini.zsh`, `codex.zsh`, `cursor.zsh`, `claude.zsh`, `skills.zsh` (Claude Code skill management), `agent-browser.zsh`, `litellm.zsh`, and `ollama.zsh`.
- `infra/` groups infrastructure tooling (`docker.zsh`, `packer.zsh`, `prom.zsh`, `terraform.zsh`).
- `cloud/` groups cloud SDKs (`aws.zsh`, `gcp.zsh`, `oci.zsh`).
- `languages/` groups language toolchains (`python.zsh`, `java.zsh`, `javascript.zsh`).
- `kube/` groups Kubernetes helpers. `common.zsh` defines `_kf_*` fzf helpers and must be sourced before `fuzzy.zsh` / `neat.zsh` / `argocd.zsh`; the order is enforced by `.zshrc`. `argocd.zsh` provides the `af*` fuzzy ArgoCD helpers and reuses `_kf_fzf` / `_kf_confirm` / `_kf_save`.
- `system/` groups maintenance tools (`free-disk.zsh`, `free-resources.zsh`, `automation.zsh`).
- `.scripts/` holds standalone executables (`zc`, `zo`, ...) invoked by absolute path from `zellij.zsh`, plus `ai-cli-update`, run daily by launchd (`com.gateswang.ai-cli-update`, helpers in `system/automation.zsh`).
- `zellij/` contains `config.kdl` and reusable layouts.
- `path.txt`, `fpath.txt`, and `docs/` document installed shell/editor dependencies.

There is no application source tree or test suite in this repo.

## Build, Test, and Development Commands

- `zsh -n .zshrc zellij.zsh` checks zsh syntax without loading the config.
- `zellij setup --check` validates Zellij configuration paths and setup.
- `exec zsh` reloads the current shell after config changes.

Avoid running destructive helpers during validation. For example, `ze` kills all Zellij sessions.

## Coding Style & Naming Conventions

Use zsh-compatible shell syntax. Prefer small functions over aliases when arguments should be forwarded, for example `zc() { command ... "$@"; }`. Use two-space indentation inside shell functions, quote variable expansions unless zsh array semantics require otherwise, and use `command` when bypassing aliases or functions.

Keep helper names short but clear. Existing Zellij helpers use `z`, `za`, `zl`, `ze`, `zj`, and `zc`. KDL files use four-space indentation and descriptive pane/layout names.

## Testing Guidelines

There are no automated tests or coverage requirements. Validate changes with syntax checks and inspect `git diff` before finishing. For shell helpers, test non-destructive commands first, such as `zl` or `zellij list-sessions --short --no-formatting`.

## Commit & Pull Request Guidelines

Recent commits use concise, imperative, sentence-case messages, such as `Update zellij jobs launcher behavior` and `Add Codex workspace shortcuts`. Follow that style.

Pull requests should explain the user-facing behavior change, list validation commands run, and call out any machine-specific paths or prerequisites. Keep unrelated config churn out of the same PR.

## Security & Configuration Tips

Do not commit tokens, credentials, private kubeconfigs, or local secrets. This repo intentionally contains absolute paths for one workstation; update them carefully and document any new path assumptions.
