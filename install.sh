#!/bin/bash
# Build battery-menubar and register it as a user LaunchAgent.
set -euo pipefail
cd "$(dirname "$0")"

LABEL="local.battery-menubar"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/battery-menubar"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

echo "==> Building"
mkdir -p "$BIN_DIR"
swiftc -O -o "$BIN" Sources/main.swift

echo "==> Installing LaunchAgent to $PLIST"
mkdir -p "$HOME/Library/LaunchAgents"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
sed "s|__BIN__|$BIN|" local.battery-menubar.plist > "$PLIST"
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "==> Done. Status:"
launchctl print "gui/$(id -u)/$LABEL" | grep -E '^\s*(state|pid) ='
echo "Log: /tmp/battery-menubar.log"
