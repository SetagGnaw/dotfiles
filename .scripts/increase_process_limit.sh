#!/bin/bash
# Increase macOS per-user process limit (kern.maxprocperuid: 2666->13330)
# Note: kern.maxproc=4000 is a kernel hard cap and cannot be increased.

# Apply immediately
sudo sysctl kern.maxprocperuid=13330

# Persist across reboots
sudo tee /Library/LaunchDaemons/limit.maxproc.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>limit.maxproc</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/sbin/sysctl</string>
        <string>kern.maxprocperuid=13330</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

echo "Done. kern.maxprocperuid set to 13330 and persisted."
