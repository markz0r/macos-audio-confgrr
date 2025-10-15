import Foundation
import CoreAudio

func setDefaultOutputDevice() {
    var defaultOutputDeviceID: AudioDeviceID = 0
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
    
    let status = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        &propertySize,
        &defaultOutputDeviceID
    )
    
    guard status == noErr else {
        print("Error getting default output device: \(status)")
        return
    }
    
    print("Default output device ID: \(defaultOutputDeviceID)")
    
    // Get device name
    propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal
    
    var deviceName: CFString?
    propertySize = UInt32(MemoryLayout<CFString>.size)
    
    let nameStatus = AudioObjectGetPropertyData(
        defaultOutputDeviceID,
        &propertyAddress,
        0,
        nil,
        &propertySize,
        &deviceName
    )
    
    if nameStatus == noErr, let name = deviceName {
        print("Default output device: \(name)")
    }
}

func setSampleRate(deviceID: AudioDeviceID, sampleRate: Float64) {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyNominalSampleRate,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var rate = sampleRate
    let status = AudioObjectSetPropertyData(
        deviceID,
        &propertyAddress,
        0,
        nil,
        UInt32(MemoryLayout<Float64>.size),
        &rate
    )
    
    if status == noErr {
        print("Successfully set sample rate to \(sampleRate) Hz")
    } else {
        print("Error setting sample rate: \(status)")
    }
}

func listAudioDevices() {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var propertySize: UInt32 = 0
    var status = AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        &propertySize
    )
    
    guard status == noErr else {
        print("Error getting device list size: \(status)")
        return
    }
    
    let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
    var deviceIDs = Array<AudioDeviceID>(repeating: 0, count: deviceCount)
    
    status = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &propertyAddress,
        0,
        nil,
        &propertySize,
        &deviceIDs
    )
    
    guard status == noErr else {
        print("Error getting device list: \(status)")
        return
    }
    
    print("Available audio devices:")
    for deviceID in deviceIDs {
        var namePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceName: CFString?
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        
        let nameStatus = AudioObjectGetPropertyData(
            deviceID,
            &namePropertyAddress,
            0,
            nil,
            &nameSize,
            &deviceName
        )
        
        let name = (nameStatus == noErr && deviceName != nil) ? String(deviceName!) : "Unknown"
        print("  ID: \(deviceID), Name: \(name)")
    }
}

func main() {
    let arguments = CommandLine.arguments
    
    if arguments.count < 2 {
        print("Usage: mac-audio-default [list|set-rate <rate>|default]")
        print("  list: List all audio devices")
        print("  set-rate <rate>: Set sample rate for default device (e.g., 44100, 48000)")
        print("  default: Show current default output device")
        exit(1)
    }
    
    let command = arguments[1].lowercased()
    
    switch command {
    case "list":
        listAudioDevices()
    case "set-rate":
        if arguments.count < 3 {
            print("Error: Sample rate required")
            print("Usage: mac-audio-default set-rate <rate>")
            exit(1)
        }
        guard let rate = Double(arguments[2]) else {
            print("Error: Invalid sample rate")
            exit(1)
        }
        
        var defaultDeviceID: AudioDeviceID = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultDeviceID
        )
        
        if status == noErr {
            setSampleRate(deviceID: defaultDeviceID, sampleRate: rate)
        } else {
            print("Error getting default device: \(status)")
        }
    case "default":
        setDefaultOutputDevice()
    default:
        print("Unknown command: \(command)")
        exit(1)
    }
}

main()