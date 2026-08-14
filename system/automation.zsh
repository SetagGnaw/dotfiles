# ── Break Reminder (managed by launchd: com.gateswang.break-reminder) ──
export _BR="uv run --no-project /Users/gateswang/Programming/repos/automation/break_reminder/break_reminder.py"
_BR_SVC="com.gateswang.break-reminder"
_BR_PLIST="$HOME/Library/LaunchAgents/${_BR_SVC}.plist"

alias brst="$_BR status"
alias brnot="$_BR notify"
function brs()    { launchctl bootstrap gui/$(id -u) "$_BR_PLIST" 2>/dev/null && echo "Break reminder started." || echo "Already loaded."; }
function brstop() { launchctl bootout gui/$(id -u)/$_BR_SVC 2>/dev/null && echo "Break reminder stopped." || echo "Not loaded."; }
function brr()   { brstop; sleep 1; brs; }
alias brre="brr"
function bradj()  { $=_BR adjust "$1" && brre; }     # bradj 45

# ── AI CLI auto-update (managed by launchd: com.gateswang.ai-cli-update) ──
# Updates claude, codex, and agy daily at 10:00 (and on login).
_AIUP_SVC="com.gateswang.ai-cli-update"
_AIUP_PLIST="$HOME/Library/LaunchAgents/${_AIUP_SVC}.plist"
_AIUP_LOG="$HOME/Library/Logs/ai-cli-update.log"

alias aiup="$HOME/Config/.scripts/ai-cli-update"     # update all AI CLIs now (foreground)
alias aiuplog="tail -n 60 $_AIUP_LOG"
function aiups()    { launchctl bootstrap gui/$(id -u) "$_AIUP_PLIST" 2>/dev/null && echo "AI CLI auto-update started." || echo "Already loaded."; }
function aiupstop() { launchctl bootout gui/$(id -u)/$_AIUP_SVC 2>/dev/null && echo "AI CLI auto-update stopped." || echo "Not loaded."; }
function aiupr()    { aiupstop; sleep 1; aiups; }
