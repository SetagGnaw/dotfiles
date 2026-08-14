# Gemini CLI helpers.

# Start gemini in YOLO mode (auto-approve all actions)
gyolo() { gemini -y --skip-trust "$@"; }
alias gy="gyolo"
# Use gemini to stage all changes and create a commit with an AI-generated message
gyc() { gemini -y --skip-trust -p "stage all changes with git add -A and create a single git commit with a concise, imperative, sentence-case message describing the change. do not push. $*" && git push; }
gconfig() {
  code ~/Config/.vscode/gemini.code-workspace
}
