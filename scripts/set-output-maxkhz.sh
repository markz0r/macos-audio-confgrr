#!/usr/bin/env bash
set -euo pipefail

BIN="${BIN_PATH:-/usr/local/bin/macos-audio-confgrr}"
[ -x "$BIN" ] || BIN="/opt/homebrew/bin/macos-audio-confgrr"

TRIES="${TRIES:-60}"
WAIT="${WAIT:-2}"

exec "$BIN" --current --max --tries "$TRIES" --wait "$WAIT"
