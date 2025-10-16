#!/usr/bin/env bash
set -euo pipefail

CFG="${1:-$HOME/Library/Application Support/macos-audio-confgrr/config/macos-audio-confgrr-settings.json}"
BIN="${BIN_PATH:-/usr/local/bin/macos-audio-confgrr}"
[ -x "$BIN" ] || BIN="/opt/homebrew/bin/macos-audio-confgrr"

if [ ! -f "$CFG" ]; then
  echo "Config file not found at '$CFG'." >&2
  exit 1
fi

exec "$BIN" --config "$CFG"
