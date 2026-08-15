# Codex CLI helpers.

cxre() {
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
}
# Start codex in full-auto mode
cxa() { codex --ask-for-approval never --sandbox danger-full-access "$@"; }
# Use codex to stage all changes and create a commit with an AI-generated message.
# Fire-and-forget: runs disowned in the background; tail the printed log path for progress.
cxc() {
  local log=/tmp/cxc-$(date +%Y%m%d-%H%M%S).log
  (
    codex exec --sandbox danger-full-access \
      "stage all changes with git add -A and create a single git commit with a concise, imperative, sentence-case message describing the change. do not push. $*" \
      && git log -1 --oneline \
      && git push
  ) >>"$log" 2>&1 &!
  print "cxc[$!] $log"
}
cxconfig() {
  code ~/Config/.vscode/codex.code-workspace
}

# Start codex in a zellij session rooted in the Config repo (~/Config),
# leaving $PWD unchanged. Args are forwarded to zo (e.g. `cxconf 2` for 2 panes).
cxconf() { (cd "$HOME/Config" && zo "$@"); }
# Same as cxconf but without zellij: run codex directly in ~/Config.
cxconfp() { (cd "$HOME/Config" && codex "$@"); }
