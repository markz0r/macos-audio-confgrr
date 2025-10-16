#!/usr/bin/env bash
set -euo pipefail

CFG="${1:-$HOME/Library/Application Support/macos-audio-confgrr/config/macos-audio-confgrr-settings.json}"
LABEL="one.mwc.macos-audio-confgrr.config"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"

BIN="${BIN_PATH:-/usr/local/bin/macos-audio-confgrr}"
[ -x "$BIN" ] || BIN="/opt/homebrew/bin/macos-audio-confgrr"

if [ ! -f "$CFG" ]; then
  echo "Config file not found at '$CFG'." >&2
  echo "Create one (e.g. via 'make install-config') and try again." >&2
  exit 1
fi

INTERVAL="$("$BIN" --config "$CFG" --print-interval)"

mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string>
    <string>--config</string>
    <string>$CFG</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>$INTERVAL</integer>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/macos-audio-confgrr.config.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/macos-audio-confgrr.config.log</string>
</dict></plist>
EOF

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"
echo "Loaded $LABEL with StartInterval=$INTERVAL seconds."
