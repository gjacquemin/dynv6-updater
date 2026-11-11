#!/bin/bash
set -euo pipefail
SERVICE='com.dynv6.updater'
TARGET="$HOME/Library/LaunchAgents/$SERVICE.plist"
launchctl bootout "gui/$(id -u)" "$TARGET" 2>/dev/null || true
rm -f "$TARGET"
echo 'LaunchAgent supprimé. Journaux conservés dans ~/Library/Logs/dynv6/.'
