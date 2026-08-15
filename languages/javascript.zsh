# bun
export BUN_INSTALL="$HOME/Library/Application Support/reflex/bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"

# Put the default node on $path directly, then load nvm with --no-use.
# A plain `. nvm.sh` runs nvm_auto -> `nvm use`, which costs ~1s of version
# resolution and filesystem checks on every shell start. Resolving the default
# alias to a bin dir with one glob does the same job for free.
# `nvm` itself still works normally; `nvm use <v>` overrides this.
if [[ -r "$NVM_DIR/alias/default" ]]; then
  _nvm_alias=$(<"$NVM_DIR/alias/default")
  # (N) no-match-is-empty, (/) dirs only, (n) numeric sort so v24.18.0 sorts
  # after v24.9.0, [-1] = highest patch when the alias names only a major,
  # e.g. "24" -> v24.18.0. Symbolic aliases (node, lts/*) are not resolved
  # here and fall through to nvm / path.txt.
  _nvm_bin=("$NVM_DIR/versions/node/v${_nvm_alias#v}"*/bin(N/n[-1]))
  (( $#_nvm_bin )) && path=("${_nvm_bin[1]}" $path)
  unset _nvm_alias _nvm_bin
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
