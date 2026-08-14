#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Minimize Window
# @raycast.mode silent
# @raycast.packageName Window Management

osascript <<'EOF'
tell application "System Events"
  set frontApp to first application process whose frontmost is true
  try
    set value of attribute "AXMinimized" of front window of frontApp to true
  end try
end tell
EOF
