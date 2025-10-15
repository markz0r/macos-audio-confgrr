# Makefile for MacOS Audio Configuration Tool

# Configuration
SWIFT_FILES = Sources/main.swift
TARGET = mac-audio-default
BUILD_DIR = .build
INSTALL_DIR = /usr/local/bin
SCRIPT_INSTALL_DIR = /usr/local/bin
LAUNCHD_DIR = /Library/LaunchDaemons
PLIST_FILE = launchd/one.mwc.mac-audio-default.plist
SCRIPT_FILE = scripts/set-output-khz.sh

# Swift compiler settings
SWIFT = swift
SWIFTC = swiftc
SWIFT_FLAGS = -O -framework CoreAudio -framework Foundation

# Default target
.PHONY: all
all: build

# Build the Swift executable
.PHONY: build
build: $(TARGET)

$(TARGET): $(SWIFT_FILES)
	@echo "Building $(TARGET)..."
	$(SWIFTC) $(SWIFT_FLAGS) -o $(TARGET) $(SWIFT_FILES)
	@echo "Build complete: $(TARGET)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(TARGET)
	rm -rf $(BUILD_DIR)
	@echo "Clean complete"

# Install the tool and scripts
.PHONY: install
install: build
	@echo "Installing $(TARGET) to $(INSTALL_DIR)..."
	sudo cp $(TARGET) $(INSTALL_DIR)/$(TARGET)
	sudo chmod +x $(INSTALL_DIR)/$(TARGET)
	@echo "Installing script to $(SCRIPT_INSTALL_DIR)..."
	sudo cp $(SCRIPT_FILE) $(SCRIPT_INSTALL_DIR)/set-output-khz
	sudo chmod +x $(SCRIPT_INSTALL_DIR)/set-output-khz
	@echo "Installation complete"

# Install launch daemon
.PHONY: install-daemon
install-daemon: install
	@echo "Installing launch daemon..."
	sudo cp $(PLIST_FILE) $(LAUNCHD_DIR)/
	sudo chmod 644 $(LAUNCHD_DIR)/$(notdir $(PLIST_FILE))
	sudo chown root:wheel $(LAUNCHD_DIR)/$(notdir $(PLIST_FILE))
	@echo "Launch daemon installed. To load: sudo launchctl load $(LAUNCHD_DIR)/$(notdir $(PLIST_FILE))"

# Uninstall the tool
.PHONY: uninstall
uninstall:
	@echo "Uninstalling $(TARGET)..."
	sudo rm -f $(INSTALL_DIR)/$(TARGET)
	sudo rm -f $(SCRIPT_INSTALL_DIR)/set-output-khz
	@echo "Uninstallation complete"

# Uninstall launch daemon
.PHONY: uninstall-daemon
uninstall-daemon:
	@echo "Uninstalling launch daemon..."
	-sudo launchctl unload $(LAUNCHD_DIR)/$(notdir $(PLIST_FILE)) 2>/dev/null
	sudo rm -f $(LAUNCHD_DIR)/$(notdir $(PLIST_FILE))
	@echo "Launch daemon uninstalled"

# Test the tool (basic functionality check)
.PHONY: test
test: build
	@echo "Testing $(TARGET)..."
	./$(TARGET) --help 2>/dev/null || ./$(TARGET) 2>&1 | head -5
	@echo "Test complete"

# Show available audio devices
.PHONY: list-devices
list-devices: build
	@echo "Listing available audio devices..."
	./$(TARGET) list

# Show current default device
.PHONY: show-default
show-default: build
	@echo "Current default audio device:"
	./$(TARGET) default

# Format Swift code (if swiftformat is available)
.PHONY: format
format:
	@if command -v swiftformat >/dev/null 2>&1; then \
		echo "Formatting Swift code..."; \
		swiftformat Sources/; \
	else \
		echo "swiftformat not found. Install with: brew install swiftformat"; \
	fi

# Lint Swift code (if swiftlint is available)
.PHONY: lint
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "Linting Swift code..."; \
		swiftlint Sources/; \
	else \
		echo "swiftlint not found. Install with: brew install swiftlint"; \
	fi

# Help target
.PHONY: help
help:
	@echo "MacOS Audio Configuration Tool - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build           Build the executable"
	@echo "  clean           Remove build artifacts"
	@echo "  install         Install the tool and scripts"
	@echo "  install-daemon  Install the launch daemon (requires install)"
	@echo "  uninstall       Remove the installed tool"
	@echo "  uninstall-daemon Remove the launch daemon"
	@echo "  test            Run basic functionality test"
	@echo "  list-devices    Show available audio devices"
	@echo "  show-default    Show current default device"
	@echo "  format          Format Swift code (requires swiftformat)"
	@echo "  lint            Lint Swift code (requires swiftlint)"
	@echo "  help            Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make build              # Build the tool"
	@echo "  make install            # Install to system"
	@echo "  make test               # Test basic functionality"
	@echo "  ./$(TARGET) set-rate 48000  # Set 48kHz sample rate"