# ZSH Plugins

## Oh My Zsh — install first
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Installed — run once to set up

### Autosuggestions
Fish-style command suggestions as you type.
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH/plugins/zsh-autosuggestions
```

### Syntax Highlighting
Highlights valid/invalid commands in real time.
```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH/plugins/zsh-syntax-highlighting
```

### Autocomplete
Real-time completion menu as you type.
```bash
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH/plugins/zsh-autocomplete
```

### fzf-tab
Replaces zsh's default completion menu with fzf.
```bash
git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
```

### kubectl-aliases
Large set of kubectl shorthand aliases (now sourced directly, not as a plugin).
```bash
chmod 755 ~/.oh-my-zsh/custom/plugins
git clone https://github.com/ahmetb/kubectl-aliases.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/kubectl-aliases
# omz looks for a file ending in .plugin.zsh inside each plugins=() folder
echo 'source "${0:A:h}/.kubectl_aliases"' > ~/.oh-my-zsh/custom/plugins/kubectl-aliases/kubectl-aliases.plugin.zsh
# to update
cd ~/.oh-my-zsh/custom/plugins/kubectl-aliases && git pull
```

---

## Interested In (not yet installed)

| Plugin | Description |
|--------|-------------|
| [wd](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/wd) | Warp directory — bookmark and jump to dirs |
| [web-search](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/web-search) | Search the web from the terminal |
| [tmux](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/tmux) | tmux aliases and auto-start |
| [terraform](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/terraform) | Terraform aliases and completion |
| [salt](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/salt) | SaltStack completion |
| [python](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/python) | Python aliases |
| [npm](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/npm) | npm aliases and completion |
| [nodenv](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/nodenv) | nodenv init and completion |
