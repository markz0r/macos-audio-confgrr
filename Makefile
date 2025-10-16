PREFIX ?= /opt/homebrew
BIN    ?= $(PREFIX)/bin
PROG   := macos-audio-confgrr

all: build

build:
	mkdir -p ./.build
	xcrun swiftc -O -o ./.build/$(PROG) Sources/main.swift

install: build
	mkdir -p $(BIN)
	install -m 0755 ./.build/$(PROG) $(BIN)/$(PROG)
	@echo "Installed $(BIN)/$(PROG)"

install-config:
	mkdir -p "$$HOME/Library/Application Support/macos-audio-confgrr/config"
	[ -f "$$HOME/Library/Application Support/macos-audio-confgrr/config/macos-audio-confgrr-settings.json" ] || \
		cp config/macos-audio-confgrr-settings.json "$$HOME/Library/Application Support/macos-audio-confgrr/config/"

plist-install-login:
	mkdir -p $$HOME/Library/LaunchAgents
	sed "s#/opt/homebrew/bin#$(BIN)#g" launchd/one.mwc.macos-audio-confgrr.login.plist \
	> $$HOME/Library/LaunchAgents/one.mwc.macos-audio-confgrr.login.plist
	launchctl unload $$HOME/Library/LaunchAgents/one.mwc.macos-audio-confgrr.login.plist 2>/dev/null || true
	launchctl load  $$HOME/Library/LaunchAgents/one.mwc.macos-audio-confgrr.login.plist

plist-install-config:
	scripts/apply-config-launchd.sh

uninstall:
	rm -f $(BIN)/$(PROG)
	launchctl unload $$HOME/Library/LaunchAgents/one.mwc.macos-audio-confgrr.login.plist 2>/dev/null || true
	launchctl unload $$HOME/Library/LaunchAgents/one.mwc.macos-audio-confgrr.config.plist 2>/dev/null || true
	rm -f $$HOME/Library/LaunchAgents/one.mwc.macos-audio-confgrr.login.plist
	rm -f $$HOME/Library/LaunchAgents/one.mwc.macos-audio-confgrr.config.plist
