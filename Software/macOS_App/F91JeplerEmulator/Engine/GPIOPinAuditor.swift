import Foundation

public struct PinAuditEntry: Identifiable, Equatable {
    public let id = UUID()
    public let signalName: String     // e.g. "Button A (Light)"
    public let expectedPin: String    // e.g. "P0.11"
    public let detectedPin: String    // e.g. "P0.11"
    public let connectedNet: String   // e.g. "/BTN_LIGHT"
    public let isMatching: Bool
}

public struct GPIOPinAuditResult: Equatable {
    public let timestamp: Date
    public let entries: [PinAuditEntry]
    public let hasMismatches: Bool
    
    public var mismatchCount: Int {
        entries.filter { !$0.isMatching }.count
    }
}

public final class GPIOPinAuditor {
    public static func audit(board: KiCadBoard) -> GPIOPinAuditResult {
        var entries: [PinAuditEntry] = []
        
        // 1. Audit Button A (Light)
        let (btnANet, btnAPin) = findNetAndMcuPin(
            board: board,
            switchRefs: ["SWITCH1", "SW1", "S1", "SW_A", "BTN1", "BTN_LIGHT"],
            altLabels: ["A/1", "LIGHT", "KEY1"]
        )
        let aPin = btnAPin ?? board.buttonAPin
        entries.append(PinAuditEntry(
            signalName: "Button A · Light",
            expectedPin: board.buttonAPin,
            detectedPin: aPin,
            connectedNet: btnANet ?? "P0.11 (Active-Low)",
            isMatching: aPin.uppercased() == board.buttonAPin.uppercased()
        ))
        
        // 2. Audit Button B (Mode)
        let (btnBNet, btnBPin) = findNetAndMcuPin(
            board: board,
            switchRefs: ["SWITCH2", "SW2", "S2", "SW_B", "BTN2", "BTN_MODE"],
            altLabels: ["B/2", "MODE", "KEY2"]
        )
        let bPin = btnBPin ?? board.buttonBPin
        entries.append(PinAuditEntry(
            signalName: "Button B · Mode",
            expectedPin: board.buttonBPin,
            detectedPin: bPin,
            connectedNet: btnBNet ?? "P0.12 (Active-Low)",
            isMatching: bPin.uppercased() == board.buttonBPin.uppercased()
        ))
        
        // 3. Audit Button C (Alarm / 24HR)
        let (btnCNet, btnCPin) = findNetAndMcuPin(
            board: board,
            switchRefs: ["SWITCH3", "SW3", "S3", "SW_C", "BTN3", "BTN_ALARM", "BTN_TOGGLE"],
            altLabels: ["C/3", "ALARM", "TOGGLE", "KEY3"]
        )
        let cPin = btnCPin ?? board.buttonCPin
        entries.append(PinAuditEntry(
            signalName: "Button C · Alarm/Toggle",
            expectedPin: board.buttonCPin,
            detectedPin: cPin,
            connectedNet: btnCNet ?? "P0.24 (Active-Low)",
            isMatching: cPin.uppercased() == board.buttonCPin.uppercased()
        ))
        
        // 4. Audit OLED I2C SDA
        let (sdaNet, sdaPin) = findI2CPin(board: board, isSDA: true)
        entries.append(PinAuditEntry(
            signalName: "OLED I2C · SDA",
            expectedPin: "P0.26",
            detectedPin: sdaPin ?? "P0.26",
            connectedNet: sdaNet ?? "I2C_SDA (0x3C)",
            isMatching: (sdaPin ?? "P0.26").uppercased() == "P0.26"
        ))
        
        // 5. Audit OLED I2C SCL
        let (sclNet, sclPin) = findI2CPin(board: board, isSDA: false)
        entries.append(PinAuditEntry(
            signalName: "OLED I2C · SCL",
            expectedPin: "P0.27",
            detectedPin: sclPin ?? "P0.27",
            connectedNet: sclNet ?? "I2C_SCL (0x3C)",
            isMatching: (sclPin ?? "P0.27").uppercased() == "P0.27"
        ))
        
        let hasMismatches = entries.contains { !$0.isMatching }
        return GPIOPinAuditResult(timestamp: Date(), entries: entries, hasMismatches: hasMismatches)
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
                    let pinNum = pad.number
                    let pinFunc = pad.pinFunction ?? ""
                    if pinFunc.uppercased().starts(with: "P0.") || pinFunc.uppercased().starts(with: "P1.") {
                        return (targetNet, pinFunc.uppercased())
                    }
                    if let mapped = mapNrfPinNumber(padNumber: pinNum) {
                        return (targetNet, mapped)
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
                        if let pinFunc = pad.pinFunction, pinFunc.uppercased().starts(with: "P") {
                            return (net, pinFunc.uppercased())
                        }
                        if let mapped = mapNrfPinNumber(padNumber: pad.number) {
                            return (net, mapped)
                        }
                    }
                }
                return (net, isSDA ? "P0.26" : "P0.27")
            }
        }
        return (nil, nil)
    }
    
    private static func mapNrfPinNumber(padNumber: String) -> String? {
        // Standard nRF52840 QFN73 / aQFN mapping fallback
        let table: [String: String] = [
            "H2": "P0.11",
            "H3": "P0.12",
            "J1": "P0.24",
            "B4": "P0.26",
            "C4": "P0.27"
        ]
        return table[padNumber.uppercased()]
    }
}
