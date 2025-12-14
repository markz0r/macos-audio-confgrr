# macos-audio-confgrr
CLI helper for macOS that keeps a preferred audio output device selected and sets its nominal sample rate. You can run it once (e.g. at login) or on a cadence driven by a JSON configuration file and `launchd`.

## Overview
- Chooses an output device by exact name or substring and makes it the default system and output device.
- Locks the device to a fixed sample rate or the highest rate it reports via CoreAudio.
- Retries with a configurable wait so USB DACs and display audio devices that appear late still get configured.
- Ships helper scripts and LaunchAgent templates to automate setup.

## Requirements
- macOS with CoreAudio (tested on macOS Tahoe).
- Xcode Command Line Tools or a full Xcode install for Swift compilation.

## Installation

### Homebrew

```bash
brew tap markz0r/homebrew-tools
brew install markz0r/homebrew-tools/macos-audio-confgrr
```

### Build

```bash
git clone https://github.com/markz0r/macos-audio-confgrr.git
cd macos-audio-confgrr
make install                 # builds with xcrun swiftc and installs to /opt/homebrew/bin by default
make install-config          # optional: copies the sample config into ~/Library/Application Support/macos-audio-confgrr/config/
```

Override the prefix when installing if you are on Intel Homebrew or want a custom path, for example `make PREFIX=/usr/local install`.

## Using a JSON config
The binary understands a JSON document with the following shape:

```json
{
  "check_frequency_seconds": 3600,
  "fallback_to_current": true,
  "devices": [
    { "name": "JDS Labs Element IV", "rate": "max" },
    { "name": "Dell U3225QE", "rate": 48000 }
  ]
}
```

- `check_frequency_seconds` (optional) controls the interval used by the LaunchAgent helper (default 3600 seconds).
- `fallback_to_current` (optional) keeps the current default output selected when none of the configured devices are present.
- `devices` is ordered by priority. The first configured device whose name appears in the active output devices wins.
  - `rate` accepts `"max"` or a numeric Hz value such as `96000`.

Run the binary once using the config:

```bash
macos-audio-confgrr --config ~/Library/Application\ Support/macos-audio-confgrr/config/macos-audio-confgrr-settings.json
```

Only want to know the suggested interval without touching audio state?

```bash
macos-audio-confgrr --config path/to/config.json --print-interval
```

## launchd helpers
- `scripts/run-from-config.sh` runs the binary once with the default config path. It exits with a non-zero status if the config file is missing.
- `scripts/apply-config-launchd.sh` regenerates `~/Library/LaunchAgents/one.mwc.macos-audio-confgrr.config.plist` using the interval reported by the config and reloads it with `launchctl`.

Both scripts honour a `BIN_PATH` override. Logs from the LaunchAgent land in `~/Library/Logs/macos-audio-confgrr.config.log`.

## Legacy CLI flags
Without `--config` the tool behaves like the original one-shot helper. Useful options:

- `--device <name>`: target device name (exact match first, then substring match).
- `--max`: choose the highest available sample rate.
- `--rate <hz>`: fixed sample rate in Hz when `--max` is not supplied.
- `--current`: operate on the current default output device instead of resolving by name.
- `--tries <count>` and `--wait <seconds>`: retry behaviour (defaults are 3 tries and 1 second wait).
- `--print-rates`: list all advertised nominal sample rate ranges to stderr.

Example: retry for up to 60 attempts (two minutes) until a display audio device appears and pin it to 48 kHz.

```bash
macos-audio-confgrr --device "Dell U3225QE" --rate 48000 --tries 60 --wait 2
```

## LaunchAgent templates
- `launchd/one.mwc.macos-audio-confgrr.login.plist`: run once at login and exit.
- `launchd/one.mwc.macos-audio-confgrr.config.plist`: schedule recurring runs driven by the JSON config interval.

Use `make plist-install-login` or `make plist-install-config` to copy and load the plists under `~/Library/LaunchAgents/`.

## Development
- `make build` writes the optimized binary to `./.build/macos-audio-confgrr`.
- Homebrew packaging lives in `https://github.com/markz0r/homebrew-tools/Formula/macos-audio-confgrr.rb` (update version and checksum when cutting releases).
- The Swift entry point is `Sources/main.swift`; scripts and samples live under `scripts/`, `launchd/`, and `config/`.

## License
[GPL-3.0](LICENSE)
