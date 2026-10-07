import Foundation

public enum PinAuditStatus: String, Equatable {
    case verified, mismatch, unknown
}

public struct PinAuditEntry: Identifiable, Equatable {
    public let id = UUID()
    public let signalName: String
    public let expectedPin: String
    public let detectedPin: String
    public let connectedNet: String
    public let status: PinAuditStatus
    public var isMatching: Bool { status == .verified }
}

public struct GPIOPinAuditResult: Equatable {
    public let timestamp: Date
    public let entries: [PinAuditEntry]
    public var hasMismatches: Bool { mismatchCount > 0 }
    public var hasUnknowns: Bool { unknownCount > 0 }
    public var mismatchCount: Int { entries.filter { $0.status == .mismatch }.count }
    public var unknownCount: Int { entries.filter { $0.status == .unknown }.count }
}

public final class GPIOPinAuditor {
    public static func audit(board: KiCadBoard, firmwareManifest: FirmwareBuildManifest? = nil) -> GPIOPinAuditResult {
        return audit(board: board, expectedPins: firmwareManifest?.expectedPins ?? [:])
    }

    /// Expected values must come from the loaded firmware build, never PCB defaults.
    public static func audit(board: KiCadBoard, expectedPins: [String: String]) -> GPIOPinAuditResult {
        let specifications: [(String, String, [String], [String])] = [
            ("buttonA", "Button A · Light", ["SWITCH1", "SW1", "S1", "SW_A", "BTN1", "BTN_LIGHT"], ["A/1", "LIGHT", "KEY1"]),
            ("buttonB", "Button B · Mode", ["SWITCH2", "SW2", "S2", "SW_B", "BTN2", "BTN_MODE"], ["B/2", "MODE", "KEY2"]),
            ("buttonC", "Button C · Alarm/Toggle", ["SWITCH3", "SW3", "S3", "SW_C", "BTN3", "BTN_ALARM", "BTN_TOGGLE"], ["C/3", "ALARM", "TOGGLE", "KEY3"])
        ]
        var entries = specifications.map { key, label, refs, labels in
            let detected = findNetAndMcuPin(board: board, switchRefs: refs, altLabels: labels)
            return entry(label, expectedPins[key], detected)
        }
        entries.append(entry("OLED I2C · SDA", expectedPins["sda"], findI2CPin(board: board, isSDA: true)))
        entries.append(entry("OLED I2C · SCL", expectedPins["scl"], findI2CPin(board: board, isSDA: false)))
        return GPIOPinAuditResult(timestamp: Date(), entries: entries)
    }

    private static func entry(_ name: String, _ expected: String?, _ detected: (netName: String?, pinName: String?)) -> PinAuditEntry {
        let expectedPin = expected.flatMap(normalizedPin)
        let actualPin = detected.pinName.flatMap(normalizedPin)
        let status: PinAuditStatus
        if let expectedPin, let actualPin { status = expectedPin == actualPin ? .verified : .mismatch }
        else { status = .unknown }
        return PinAuditEntry(signalName: name, expectedPin: expectedPin ?? "Unknown (firmware)",
                             detectedPin: actualPin ?? "Unknown (PCB)", connectedNet: detected.netName ?? "Unknown net", status: status)
    }

    private static func normalizedPin(_ value: String) -> String? {
        let pieces = value.uppercased().split(separator: ".")
        guard pieces.count == 2, ["P0", "P1"].contains(String(pieces[0])),
              let pin = Int(pieces[1]), (0...31).contains(pin) else { return nil }
        return String(format: "%@.%02d", String(pieces[0]), pin)
    }

    private static func findNetAndMcuPin(
        board: KiCadBoard,
        switchRefs: [String],
        altLabels: [String]
    ) -> (netName: String?, pinName: String?) {
        // Try finding matching switch footprint
        let swFootprint = board.footprints.first { fp in
            let ref = fp.reference.uppercased()
            let val = fp.value.uppercased()
            return switchRefs.contains(ref) || altLabels.contains(where: { ref.contains($0) || val.contains($0) })
        }
        
        var netName: String? = nil
        if let sw = swFootprint {
            for pad in sw.pads {
                let name = pad.netName.uppercased()
                if !name.isEmpty && !name.contains("GND") && !name.contains("VCC") && !name.contains("3V3") {
                    netName = pad.netName
                    break
                }
            }
        }
        
        guard let targetNet = netName else { return (nil, nil) }
        
        // Trace target net to MCU (U1)
        if let u1 = board.footprints.first(where: { $0.reference.uppercased() == "U1" }) {
            for pad in u1.pads {
                if pad.netName.caseInsensitiveCompare(targetNet) == .orderedSame {
                    let pinFunc = pad.pinFunction ?? ""
                    if normalizedPin(pinFunc) != nil {
                        return (targetNet, pinFunc.uppercased())
                    }
                }
            }
        }
        
        return (targetNet, nil)
    }
    
    private static func findI2CPin(board: KiCadBoard, isSDA: Bool) -> (netName: String?, pinName: String?) {
        let keyword = isSDA ? "SDA" : "SCL"
        for (_, net) in board.nets {
            let u = net.uppercased()
            if u.contains(keyword) {
                if let u1 = board.footprints.first(where: { $0.reference.uppercased() == "U1" }) {
                    for pad in u1.pads where pad.netName.caseInsensitiveCompare(net) == .orderedSame {
                        if let pinFunc = pad.pinFunction, normalizedPin(pinFunc) != nil {
                            return (net, pinFunc.uppercased())
                        }
                    }
                }
                return (net, nil)
            }
        }
        return (nil, nil)
    }
    
}
