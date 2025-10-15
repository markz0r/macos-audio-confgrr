# MacOS Audio Configuration Tool

A simple, lightweight tool for managing macOS audio output device configuration and sample rates. Built with Swift and Core Audio APIs for reliable audio device management.

## Features

- **List Audio Devices**: Display all available audio devices with IDs and names
- **Show Default Device**: Get information about the current default output device  
- **Set Sample Rate**: Change the sample rate of the default output device
- **Launch Daemon**: Automatically configure audio settings at system startup
- **Shell Script Wrapper**: Convenient command-line interface for common operations
- **Homebrew Formula**: Easy installation via Homebrew package manager

## Installation

### Option 1: Build from Source

```bash
git clone https://github.com/markz0r/MacOS-Audio-Confgr.git
cd MacOS-Audio-Confgr
make build
make install
```

### Option 2: Using Homebrew (when formula is published)

```bash
brew install mac-audio-default
```

### Option 3: Manual Installation

```bash
# Build the project
make build

# Copy binary to system location
sudo cp mac-audio-default /usr/local/bin/
sudo cp scripts/set-output-khz.sh /usr/local/bin/set-output-khz
sudo chmod +x /usr/local/bin/mac-audio-default
sudo chmod +x /usr/local/bin/set-output-khz
```

## Usage

### Basic Commands

```bash
# List all available audio devices
mac-audio-default list

# Show current default output device
mac-audio-default default

# Set sample rate for default device (common rates: 44100, 48000, 96000)
mac-audio-default set-rate 48000
```

### Shell Script Wrapper

The included shell script provides a more convenient interface:

```bash
# Set output to 48kHz
set-output-khz 48000

# List all audio devices
set-output-khz --list

# Show current default device
set-output-khz --show

# Display help
set-output-khz --help
```

### Launch Daemon (Auto-Configuration)

To automatically set audio configuration at system startup:

```bash
# Install launch daemon (requires sudo)
make install-daemon

# Or manually install
sudo cp launchd/one.mwc.mac-audio-default.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/one.mwc.mac-audio-default.plist
```

The default configuration sets the sample rate to 48kHz. To customize:

1. Edit `/Library/LaunchDaemons/one.mwc.mac-audio-default.plist`
2. Change the sample rate in the `ProgramArguments` array
3. Reload: `sudo launchctl unload` then `sudo launchctl load`

## Development

### Building

```bash
make build        # Build the executable
make clean        # Remove build artifacts
make test         # Run basic functionality test
```

### Code Quality

```bash
make format       # Format Swift code (requires swiftformat)
make lint         # Lint Swift code (requires swiftlint)
```

### Makefile Targets

- `build`: Compile the Swift executable
- `install`: Install to system directories
- `install-daemon`: Install launch daemon
- `uninstall`: Remove installed files
- `test`: Basic functionality verification
- `list-devices`: Show available audio devices
- `show-default`: Display current default device

## Requirements

- macOS 10.12 (Sierra) or later
- Xcode command line tools (for building)
- Administrative privileges for system installation and launch daemon

## Project Structure

```
MacOS-Audio-Confgr/
├── Sources/
│   └── main.swift                          # Main Swift application
├── scripts/
│   └── set-output-khz.sh                   # Shell script wrapper  
├── launchd/
│   └── one.mwc.mac-audio-default.plist     # Launch daemon configuration
├── brew/
│   └── mac-audio-default.rb                # Homebrew formula
├── Makefile                                # Build and install automation
└── README.md                               # This file
```

## Common Sample Rates

- **44.1 kHz**: CD quality audio standard
- **48 kHz**: Professional audio/video standard (recommended)
- **88.2 kHz**: High-resolution audio (2x CD quality)
- **96 kHz**: High-resolution audio standard
- **176.4 kHz**: Ultra-high resolution (4x CD quality)
- **192 kHz**: Maximum high-resolution audio

## Troubleshooting

### Permission Issues
If you get permission errors, try:
```bash
sudo make install
```

### Audio Device Not Found
List available devices to find the correct one:
```bash
mac-audio-default list
```

### Launch Daemon Not Working
Check daemon status:
```bash
sudo launchctl list | grep mac-audio
sudo launchctl print system/one.mwc.mac-audio-default
```

View logs:
```bash
tail -f /var/log/mac-audio-default.log
tail -f /var/log/mac-audio-default-error.log
```

## License

This project is licensed under the GNU General Public License v3.0 or later. See [LICENSE](LICENSE) for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test`
5. Submit a pull request

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for similar problems
- Include system information and error logs
