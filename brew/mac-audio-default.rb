class MacAudioDefault < Formula
  desc "macOS audio configuration tool for setting default output device and sample rates"
  homepage "https://github.com/markz0r/MacOS-Audio-Confgr"
  url "https://github.com/markz0r/MacOS-Audio-Confgr/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "changeme" # This will need to be updated when creating a release
  license "GPL-3.0-or-later"
  
  depends_on :macos
  depends_on xcode: ["12.0", :build]

  def install
    system "make", "build"
    
    # Install the main binary
    bin.install "mac-audio-default"
    
    # Install the shell script wrapper
    bin.install "scripts/set-output-khz.sh" => "set-output-khz"
    
    # Install launch daemon plist to a Homebrew-appropriate location
    (prefix/"LaunchDaemons").install "launchd/one.mwc.mac-audio-default.plist"
  end

  def post_install
    puts ""
    puts "MacOS Audio Configuration Tool installed successfully!"
    puts ""
    puts "Usage:"
    puts "  mac-audio-default list                 # List audio devices"
    puts "  mac-audio-default default              # Show default device"
    puts "  mac-audio-default set-rate 48000       # Set sample rate to 48kHz"
    puts ""
    puts "Convenient wrapper script:"
    puts "  set-output-khz 48000                   # Set to 48kHz"
    puts "  set-output-khz -l                      # List devices"
    puts "  set-output-khz -s                      # Show default"
    puts ""
    puts "Launch Daemon (optional):"
    puts "To automatically set audio configuration at startup:"
    puts "  sudo cp #{prefix}/LaunchDaemons/one.mwc.mac-audio-default.plist /Library/LaunchDaemons/"
    puts "  sudo launchctl load /Library/LaunchDaemons/one.mwc.mac-audio-default.plist"
    puts ""
  end

  def caveats
    <<~EOS
      This tool requires macOS and uses Core Audio APIs.
      
      The launch daemon will automatically set the audio output to 48kHz
      at system startup. Modify the plist file to change the default rate:
      
      #{prefix}/LaunchDaemons/one.mwc.mac-audio-default.plist
      
      To unload the launch daemon:
        sudo launchctl unload /Library/LaunchDaemons/one.mwc.mac-audio-default.plist
        sudo rm /Library/LaunchDaemons/one.mwc.mac-audio-default.plist
    EOS
  end

  test do
    # Test that the binary was installed and shows help
    output = shell_output("#{bin}/mac-audio-default 2>&1", 1)
    assert_match "Usage:", output
    
    # Test the wrapper script
    output = shell_output("#{bin}/set-output-khz --help 2>&1")
    assert_match "Usage:", output
  end
end