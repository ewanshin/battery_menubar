#!/bin/bash
# Remove BatteryMenubar: quits the app (which restores your original battery
# menu bar setting), removes its login item, deletes /Applications/BatteryMenubar.app,
# and cleans up the pre-1.0 LaunchAgent install if present.
set -uo pipefail

APP="/Applications/BatteryMenubar.app"
OLD_LABEL="local.battery-menubar"

# Login item (needs the binary; do this before deleting the app).
if [[ -x "$APP/Contents/MacOS/BatteryMenubar" ]]; then
    "$APP/Contents/MacOS/BatteryMenubar" --unregister-login-item 2>/dev/null || true
fi

# Quit the running app; applicationWillTerminate restores the original setting.
osascript -e 'tell application "BatteryMenubar" to quit' 2>/dev/null || true
rm -rf "$APP"

# Pre-1.0 LaunchAgent install.
launchctl bootout "gui/$(id -u)/$OLD_LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$OLD_LABEL.plist" "$HOME/.local/bin/battery-menubar" /tmp/battery-menubar.log

echo "BatteryMenubar removed."
