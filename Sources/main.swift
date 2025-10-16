import Foundation
import CoreAudio

// ===== CoreAudio helpers =====

@inline(__always) func caCheck(_ err: OSStatus, _ msg: String) throws {
    if err != noErr { throw NSError(domain: "CoreAudio", code: Int(err),
      userInfo: [NSLocalizedDescriptionKey: "\(msg) (OSStatus=\(err))"]) }
}

func allDevices() throws -> [AudioObjectID] {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    let sys = AudioObjectID(kAudioObjectSystemObject)
    var size: UInt32 = 0
    try caCheck(AudioObjectGetPropertyDataSize(sys, &addr, 0, nil, &size), "Get devices size")
    var ids = Array(repeating: AudioObjectID(), count: Int(size)/MemoryLayout<AudioObjectID>.size)
    try caCheck(AudioObjectGetPropertyData(sys, &addr, 0, nil, &size, &ids), "Get devices")
    return ids
}

func deviceName(_ id: AudioObjectID) -> String {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioObjectPropertyName,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var name = "" as CFString; var size = UInt32(MemoryLayout<CFString>.size)
    let status: OSStatus = withUnsafeMutablePointer(to: &name) { ptr in
        AudioObjectGetPropertyData(id, &addr, 0, nil, &size, ptr)
    }
    if status == noErr { return name as String }
    return ""
}

func isOutput(_ id: AudioObjectID) -> Bool {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreams,
                                          mScope: kAudioDevicePropertyScopeOutput,
                                          mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    return AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr && size > 0
}

func defaultOutputDeviceID() throws -> AudioObjectID {
    let sys = AudioObjectID(kAudioObjectSystemObject)
    var addr = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var dev = AudioObjectID(0)
    var size = UInt32(MemoryLayout<AudioObjectID>.size)
    try caCheck(AudioObjectGetPropertyData(sys, &addr, 0, nil, &size, &dev), "Get default output")
    return dev
}

func setDefaultOutputs(_ id: AudioObjectID) throws {
    let sys = AudioObjectID(kAudioObjectSystemObject)
    for sel in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDefaultSystemOutputDevice] {
        var addr = AudioObjectPropertyAddress(mSelector: sel,
                                              mScope: kAudioObjectPropertyScopeGlobal,
                                              mElement: kAudioObjectPropertyElementMain)
        var v = id; let size = UInt32(MemoryLayout<AudioObjectID>.size)
        try caCheck(AudioObjectSetPropertyData(sys, &addr, 0, nil, size, &v), "Set default output")
    }
}

func setRate(_ id: AudioObjectID, _ hz: Double) throws {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyNominalSampleRate,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var settable = DarwinBoolean(false)
    guard AudioObjectIsPropertySettable(id, &addr, &settable) == noErr, settable.boolValue else {
        throw NSError(domain: "CoreAudio", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Sample rate not settable"])
    }
    var r = Float64(hz); let size = UInt32(MemoryLayout<Float64>.size)
    try caCheck(AudioObjectSetPropertyData(id, &addr, 0, nil, size, &r), "Set sample rate")
}

struct RateRange { let min: Double; let max: Double }
func availableRateRanges(_ id: AudioObjectID) throws -> [RateRange] {
    var addr = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyAvailableNominalSampleRates,
                                          mScope: kAudioObjectPropertyScopeGlobal,
                                          mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    try caCheck(AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size), "Avail rate ranges size")
    let count = Int(size) / MemoryLayout<AudioValueRange>.size
    var ranges = Array(repeating: AudioValueRange(mMinimum: 0, mMaximum: 0), count: count)
    try caCheck(AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &ranges), "Avail rate ranges data")
    return ranges.map { RateRange(min: $0.mMinimum, max: $0.mMaximum) }
}
func maxAvailableRate(_ id: AudioObjectID) throws -> Double? {
    try availableRateRanges(id).map(\.max).max()
}

// ===== Config & CLI =====

struct ConfigDevice: Decodable {
    let name: String
    let rate: Rate
    enum Rate: Decodable {
        case max
        case fixed(Double)
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self), s.lowercased() == "max" { self = .max; return }
            if let n = try? c.decode(Double.self) { self = .fixed(n); return }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "rate must be \"max\" or number")
        }
    }
}

struct Config: Decodable {
    let check_frequency_seconds: Int?
    let fallback_to_current: Bool?
    let devices: [ConfigDevice]
}

struct Args {
    var configPath: String? = nil
    var printInterval: Bool = false
    // legacy flags still supported:
    var name: String = "JDS Labs Element IV"
    var rate: Double? = 192000.0
    var tries: Int = 3
    var wait: Double = 1.0
    var useCurrent: Bool = false
    var useMax: Bool = false
    var printRates: Bool = false

    init() {
        let a = CommandLine.arguments
        var i = 0
        while i < a.count {
            switch a[i] {
            case "--config":       if i+1 < a.count { configPath = a[i+1]; i += 1 }
            case "--print-interval": printInterval = true
            case "--device":       if i+1 < a.count { name = a[i+1]; i += 1 }
            case "--rate":         if i+1 < a.count { rate = Double(a[i+1]); i += 1 }
            case "--tries":        if i+1 < a.count { tries = Int(a[i+1]) ?? tries; i += 1 }
            case "--wait":         if i+1 < a.count { wait = Double(a[i+1]) ?? wait; i += 1 }
            case "--current":      useCurrent = true
            case "--max":          useMax = true; rate = nil
            case "--print-rates":  printRates = true
            default: break
            }
            i += 1
        }
    }
}

func chooseDeviceByName(_ want: String) throws -> AudioObjectID? {
    let devs = try allDevices()
    return devs.first(where: { deviceName($0) == want && isOutput($0) })
        ?? devs.first(where: { deviceName($0).localizedCaseInsensitiveContains(want) && isOutput($0) })
}

func runLegacy(args: Args) -> Int32 {
    for attempt in 1...args.tries {
        do {
            let dev: AudioObjectID? = try {
                if args.useCurrent { return try defaultOutputDeviceID() }
                return try chooseDeviceByName(args.name)
            }()
            if let d = dev, isOutput(d) {
                if args.printRates, let ranges = try? availableRateRanges(d) {
                    fputs("Available rates for '\(deviceName(d))':\n", stderr)
                    for r in ranges.sorted(by: { $0.min < $1.min }) {
                        fputs(String(format: " - %.0f .. %.0f Hz\n", r.min, r.max), stderr)
                    }
                }
                try setDefaultOutputs(d)
                let chosen: Double
                if args.useMax, let mx = try maxAvailableRate(d) { chosen = mx }
                else { chosen = args.rate ?? 192000.0 }
                try setRate(d, chosen)
                print("✅ Set '\(deviceName(d))' @ \(Int(chosen)) Hz")
                return 0
            } else {
                fputs("Device not found yet (\(args.useCurrent ? "current default" : args.name)) attempt \(attempt)/\(args.tries)\n", stderr)
            }
        } catch { fputs("⚠️ \(error)\n", stderr) }
        Thread.sleep(forTimeInterval: args.wait)
    }
    fputs("❌ Failed.\n", stderr)
    return 1
}

func runFromConfig(path: String, printIntervalOnly: Bool) -> Int32 {
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path).standardizedFileURL)
        let cfg = try JSONDecoder().decode(Config.self, from: data)
        let interval = cfg.check_frequency_seconds ?? 3600
        if printIntervalOnly {
            print(interval)
            return 0
        }
        // Pick first present device by priority
        let all = try allDevices()
        let present: [(ConfigDevice, AudioObjectID)] = cfg.devices.compactMap { cd in
            if let match = all.first(where: { isOutput($0) && deviceName($0).localizedCaseInsensitiveContains(cd.name) }) {
                return (cd, match)
            }
            return nil
        }
        let target: (ConfigDevice, AudioObjectID)? = present.first
        if let (cd, dev) = target {
            try setDefaultOutputs(dev)
            let chosenRate: Double
            switch cd.rate {
            case .max:
                guard let mx = try maxAvailableRate(dev) else {
                    throw NSError(domain: "CoreAudio", code: -3, userInfo: [NSLocalizedDescriptionKey: "No available rates"])
                }
                chosenRate = mx
            case .fixed(let hz): chosenRate = hz
            }
            try setRate(dev, chosenRate)
            print("✅ From config: '\(deviceName(dev))' @ \(Int(chosenRate)) Hz")
            return 0
        } else if cfg.fallback_to_current == true {
            let dev = try defaultOutputDeviceID()
            guard isOutput(dev) else { throw NSError(domain: "CoreAudio", code: -4, userInfo: [NSLocalizedDescriptionKey: "Current default is not an output"]) }
            // Choose behaviour for fallback:
            // Option A (conservative): do not change rate; just ensure default is applied.
            // Option B (aggressive): set to max. Uncomment to enable B by default.
            // if let mx = try maxAvailableRate(dev) { try setRate(dev, mx) }
            try setDefaultOutputs(dev)
            print("ℹ️  Fallback to current default: '\(deviceName(dev))' (rate unchanged)")
            return 0
        } else {
            fputs("❌ No configured devices present, and no fallback.\n", stderr)
            return 1
        }
    } catch {
        fputs("⚠️ Config error: \(error)\n", stderr)
        return 2
    }
}

// ===== Entrypoint =====

let args = Args()
if let cfg = args.configPath {
    exit(runFromConfig(path: NSString(string: cfg).expandingTildeInPath, printIntervalOnly: args.printInterval))
} else {
    exit(runLegacy(args: args))
}
