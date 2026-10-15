#!/bin/bash
# Stop and remove battery-menubar, and restore the battery item to "hidden".
set -uo pipefail

LABEL="local.battery-menubar"
BIN="$HOME/.local/bin/battery-menubar"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST" "$BIN" /tmp/battery-menubar.log

# Restore to "Don't Show in Menu Bar". Re-enable it in
# System Settings > Control Center > Battery if you want it always visible.
defaults -currentHost write com.apple.controlcenter Battery -int 25
echo "battery-menubar removed."
