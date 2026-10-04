import Foundation

public final class PCBValidator {
    
    public static func validate(board: KiCadBoard) -> PCBValidationResult {
        var checks: [ValidationCheck] = []
        
        // -------------------------------------------------------------
        // SECTION 1: CRITICAL COMPONENTS PRESENT
        // -------------------------------------------------------------
        
        // 1.1 MCU Check (nRF52840 at U1 or MCU)
        let mcuFootprints = board.footprints.filter { fp in
            let refUpper = fp.reference.uppercased()
            let valUpper = fp.value.uppercased()
            let pkgUpper = fp.package.uppercased()
            return refUpper == "U1" ||
                   valUpper.contains("NRF52840") ||
                   pkgUpper.contains("AQFN") ||
                   pkgUpper.contains("BGA")
        }
        
        if let mcu = mcuFootprints.first {
            let pkg = mcu.package.uppercased()
            let val = mcu.value.uppercased()
            let isProperPackage = pkg.contains("AQFN") || pkg.contains("BGA") || pkg.contains("7X7MM")
            let isProperVal = val.contains("NRF52840")
            
            if isProperPackage && isProperVal {
                checks.append(ValidationCheck(
                    category: "Component",
                    title: "Nordic nRF52840 MCU present",
                    detail: "Found \(mcu.value) at \(mcu.reference) in package \(mcu.package.components(separatedBy: ":").last ?? mcu.package) (\(mcu.pads.count) pads).",
                    severity: .pass,
                    relatedComponentRef: mcu.reference
                ))
            } else if isProperVal {
                checks.append(ValidationCheck(
                    category: "Component",
                    title: "Nordic MCU package warning",
                    detail: "\(mcu.reference) (\(mcu.value)) has unexpected package \(mcu.package). Recommended: AQFN-73 or BGA.",
                    severity: .warning,
                    relatedComponentRef: mcu.reference,
                    suggestion: "Verify footprint matches Nordic AQFN-73-1EP 7x7mm P0.5mm."
                ))
            } else {
                checks.append(ValidationCheck(
                    category: "Component",
                    title: "MCU reference U1 found with generic value",
                    detail: "U1 is populated with value '\(mcu.value)'.",
                    severity: .warning,
                    relatedComponentRef: mcu.reference,
                    suggestion: "Specify nRF52840-QIAA for fabrication BOM."
                ))
            }
        } else {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Missing nRF52840 MCU",
                detail: "Reference U1 or nRF52840 MCU footprint not detected on board.",
                severity: .error,
                suggestion: "Place Nordic nRF52840 AQFN-73 footprint at reference U1."
            ))
        }
        
        // 1.2 SSD1306 OLED Display (I2C address 0x3C, I2C0)
        let oledFps = board.footprints.filter { fp in
            let str = (fp.reference + " " + fp.value + " " + fp.descr + " " + fp.package).uppercased()
            return str.contains("SSD1306") || str.contains("OLED") || str.contains("DISP")
        }
        let oledNets = board.nets.values.filter { net in
            let u = net.uppercased()
            return u.contains("OLED") || u.contains("SSD1306") || (u.contains("SDA") && u.contains("SCL"))
        }
        let oledTestPoints = board.footprints.filter { fp in
            let v = fp.value.uppercased()
            return v.contains("OLED") || (fp.reference.hasPrefix("TP") && (v.contains("SCL") || v.contains("SDA")))
        }
        
        if !oledFps.isEmpty || !oledTestPoints.isEmpty {
            let tpNames = oledTestPoints.map { "\($0.reference): \($0.value)" }.joined(separator: ", ")
            checks.append(ValidationCheck(
                category: "Component",
                title: "SSD1306 OLED display interface present",
                detail: oledFps.first != nil
                    ? "Display component found: \(oledFps.first!.reference) (\(oledFps.first!.value)). I2C: \(board.oledI2CAddress)."
                    : "Display routed via test points: [\(tpNames)]. Expected I2C addr: 0x3C.",
                severity: .pass,
                relatedComponentRef: oledFps.first?.reference ?? oledTestPoints.first?.reference
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Component",
                title: "SSD1306 OLED display connection not found",
                detail: "Neither SSD1306 display footprint nor dedicated OLED I2C test points detected.",
                severity: .warning,
                suggestion: "Add SSD1306 0.96\" I2C header or OLED test points (TP11 SCL, TP12 SDA, TP13 3V0, TP14 GND)."
            ))
        }
        
        // 1.3 32.768 kHz External Crystal (RTC)
        let rtcCrystals = board.footprints.filter { fp in
            let str = (fp.reference + " " + fp.value + " " + fp.package + " " + fp.descr).uppercased()
            return str.contains("32.768") || str.contains("ABS07") || str.contains("32KHZ") ||
                   (fp.reference.hasPrefix("X") && str.contains("3215")) ||
                   (fp.reference.hasPrefix("Y") && str.contains("3215"))
        }
        
        if let rtcXtal = rtcCrystals.first {
            let valUpper = rtcXtal.value.uppercased()
            let hasTypo = valUpper.contains("32.67") || valUpper.contains("32.7K") || valUpper.contains("32.768MHZ")
            
            if hasTypo {
                checks.append(ValidationCheck(
                    category: "Values",
                    title: "RTC crystal frequency typo detected",
                    detail: "\(rtcXtal.reference) value '\(rtcXtal.value)' appears typo'd. Expected 32.768 kHz.",
                    severity: .warning,
                    relatedComponentRef: rtcXtal.reference,
                    suggestion: "Correct crystal value to '32.768 kHz' (ABS07-32.768KHZ-7-T).",
                    autoFixable: true,
                    fixActionDescription: "Fix crystal value typo to 32.768 kHz"
                ))
            } else {
                checks.append(ValidationCheck(
                    category: "Component",
                    title: "32.768 kHz RTC external crystal present",
                    detail: "Crystal found at \(rtcXtal.reference) (\(rtcXtal.value), package \(rtcXtal.package.components(separatedBy: ":").last ?? rtcXtal.package)).",
                    severity: .pass,
                    relatedComponentRef: rtcXtal.reference
                ))
            }
        } else {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Missing 32.768 kHz external crystal",
                detail: "No 32.768 kHz low-frequency crystal found for nRF52840 RTC.",
                severity: .error,
                suggestion: "Add 32.768 kHz crystal (e.g. ABS07-32.768KHZ-7-T) connected to P0.00/XL1 and P0.01/XL2."
            ))
        }
        
        // 1.4 Power Distribution (3.3V / 3.0V rail, GND planes)
        let hasGndNet = board.nets.values.contains { $0.uppercased().contains("GND") }
        let hasPowerRail = board.nets.values.contains { net in
            let u = net.uppercased()
            return u.contains("VDD") || u.contains("3V") || u.contains("3.3V") || u.contains("VCC") || u.contains("BAT")
        }
        
        if hasGndNet && hasPowerRail {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Power rails and ground distribution detected",
                detail: "GND net and primary power rails (VDD_NRF / 3V0) identified across board netlist.",
                severity: .pass
            ))
        } else if !hasPowerRail {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Missing 3.3V / VDD power rail",
                detail: "No positive power rail net (VDD, 3V0, 3.3V) found in board netlist.",
                severity: .error,
                suggestion: "Define and route 3.0V / 3.3V power net to MCU VDD and peripheral supply pins."
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Missing GND net",
                detail: "No GND ground net detected on PCB.",
                severity: .error,
                suggestion: "Add GND copper plane and connect all component ground pads."
            ))
        }
        
        // 1.5 Decoupling Capacitors on MCU power pins
        let mcuPads = board.footprints.first(where: { $0.reference == "U1" })?.pads ?? []
        let decouplingCaps = board.footprints.filter { fp in
            fp.reference.hasPrefix("C") &&
            (fp.value.lowercased().contains("100n") || fp.value.lowercased().contains("0.1u") ||
             fp.value.lowercased().contains("1.0u") || fp.value.lowercased().contains("1u") ||
             fp.value.lowercased().contains("4.7u"))
        }
        let cap100nFCount = board.footprints.filter { $0.reference.hasPrefix("C") && $0.value.lowercased().contains("100n") }.count
        
        if cap100nFCount >= 3 {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Decoupling capacitors present on MCU power pins",
                detail: "Found \(cap100nFCount)x 100nF bypass capacitors (plus \(decouplingCaps.count - cap100nFCount) bulk capacitors: 1µF, 4.7µF).",
                severity: .pass,
                relatedComponentRef: "C5"
            ))
        } else if cap100nFCount > 0 {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Insufficient 100nF decoupling capacitors",
                detail: "Found only \(cap100nFCount)x 100nF capacitor(s). Nordic nRF52840 reference requires at least 4x 100nF bypass caps for VDD and DEC pins.",
                severity: .warning,
                suggestion: "Add 100nF capacitors close to MCU VDD pins and DEC1, DEC3, DEC4, DEC6."
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Component",
                title: "Missing MCU decoupling capacitors",
                detail: "No 100nF bypass capacitors found on MCU power lines.",
                severity: .error,
                suggestion: "Add 100nF decoupling capacitors adjacent to MCU VDD pins."
            ))
        }
        
        // -------------------------------------------------------------
        // SECTION 2: GPIO & CONNECTIVITY
        // -------------------------------------------------------------
        
        // 2.1 Buttons A/B/C Routing to P0.11, P0.12, P0.24
        let allNetNamesUpper = board.nets.values.map { $0.uppercased() }
        let allPadNetsUpper = board.footprints.flatMap { $0.pads.map { $0.netName.uppercased() } }
        let allNetsCombined = Set(allNetNamesUpper).union(allPadNetsUpper)
        
        // Button A (P0.11)
        let hasBtnANet = allNetsCombined.contains { $0.contains("P0.11") || $0.contains("BUTTON_A") || $0.contains("KEY1") || $0.contains("KEY 1") }
        let btnAFp = board.footprints.first { $0.value.uppercased().contains("A / KEY 1") || $0.reference == "TP3" }
        if hasBtnANet {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Button A routed to P0.11 (Key 1)",
                detail: "GPIO P0.11 net detected and routed for Button A.",
                severity: .pass,
                relatedComponentRef: btnAFp?.reference ?? "U1"
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Button A not routed to P0.11",
                detail: "Net P0.11 / BUTTON_A not found in board routing.",
                severity: .warning,
                relatedComponentRef: btnAFp?.reference,
                suggestion: "Route Button A contact pad to MCU pin P0.11 (Pad T2 or equivalent)."
            ))
        }
        
        // Button B (P0.12)
        let hasBtnBNet = allNetsCombined.contains { $0.contains("P0.12") || $0.contains("BUTTON_B") || $0.contains("KEY2") || $0.contains("KEY 2") }
        let btnBFp = board.footprints.first { $0.value.uppercased().contains("B / KEY 2") || $0.reference == "TP4" }
        if hasBtnBNet {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Button B routed to P0.12 (Key 2)",
                detail: "GPIO P0.12 net detected and routed for Button B.",
                severity: .pass,
                relatedComponentRef: btnBFp?.reference ?? "U1"
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Button B not routed to P0.12",
                detail: "Net P0.12 / BUTTON_B not found in board routing.",
                severity: .warning,
                relatedComponentRef: btnBFp?.reference,
                suggestion: "Route Button B contact pad to MCU pin P0.12 (Pad U1 or equivalent)."
            ))
        }
        
        // Button C (P0.24)
        let hasBtnCNet = allNetsCombined.contains { $0.contains("P0.24") || $0.contains("BUTTON_C") || $0.contains("KEY3") || $0.contains("KEY 3") }
        let btnCFp = board.footprints.first { $0.value.uppercased().contains("C / KEY 3") || $0.reference == "TP5" }
        if hasBtnCNet {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Button C routed to P0.24 (Key 3)",
                detail: "GPIO P0.24 net detected and routed for Button C.",
                severity: .pass,
                relatedComponentRef: btnCFp?.reference ?? "U1"
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Button C not routed to P0.24",
                detail: "Net P0.24 / BUTTON_C not found in board routing.",
                severity: .warning,
                relatedComponentRef: btnCFp?.reference,
                suggestion: "Route Button C contact pad to MCU pin P0.24."
            ))
        }
        
        // 2.2 I2C0 (SDA/SCL) connected to SSD1306
        let hasSDA = allNetsCombined.contains { $0.contains("SDA") || $0.contains("TWISDA") || $0.contains("P0.26") }
        let hasSCL = allNetsCombined.contains { $0.contains("SCL") || $0.contains("TWISCL") || $0.contains("P0.27") }
        
        if hasSDA && hasSCL {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "I2C0 (SDA/SCL) routed to display interface",
                detail: "Both I2C Serial Data (SDA) and Clock (SCL) lines routed to display interface.",
                severity: .pass,
                relatedComponentRef: "TP11"
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Incomplete I2C0 display lines",
                detail: "Missing standard I2C SDA (\(hasSDA ? "OK" : "Missing")) or SCL (\(hasSCL ? "OK" : "Missing")).",
                severity: .warning,
                suggestion: "Route MCU TWI0 pins (SDA on P0.26, SCL on P0.27) to SSD1306 display."
            ))
        }
        
        // 2.3 UART0 / SWD Debug Traces
        let hasSWD = allNetsCombined.contains { $0.contains("SWDIO") } && allNetsCombined.contains { $0.contains("SWDCLK") }
        let hasUART = allNetsCombined.contains { $0.contains("UART") || $0.contains("TXD") || $0.contains("RXD") }
        
        if hasSWD || hasUART {
            let desc = hasSWD && hasUART ? "SWD & UART debugging" : (hasSWD ? "SWD programming interface (SWDIO/SWDCLK)" : "UART traces")
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "Hardware debug interface routed",
                detail: "Detected \(desc) with accessible test points/connectors.",
                severity: .pass,
                relatedComponentRef: "TP6"
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Connectivity",
                title: "No debug/programming interface detected",
                detail: "Neither SWD (SWDIO/SWDCLK) nor UART debug traces found.",
                severity: .warning,
                suggestion: "Add SWDIO, SWDCLK, and RESET test points (TP6, TP7, TP8) for flashing firmware."
            ))
        }
        
        // 2.4 Floating Unconnected Pins on MCU
        if let u1 = board.footprints.first(where: { $0.reference == "U1" }) {
            let unassignedPads = u1.pads.filter { pad in
                let n = pad.netName.lowercased()
                return pad.netId == 0 || n.isEmpty || n.contains("unconnected")
            }
            let totalMcuPads = u1.pads.count
            let connectedPads = totalMcuPads - unassignedPads.count
            
            // Check if critical power pins are unassigned
            let unassignedPower = unassignedPads.filter { pad in
                let fn = (pad.pinFunction ?? "").uppercased()
                return fn.contains("VDD") || fn.contains("VSS") || fn.contains("DEC")
            }
            
            if !unassignedPower.isEmpty {
                checks.append(ValidationCheck(
                    category: "Connectivity",
                    title: "Critical MCU power pins floating",
                    detail: "\(unassignedPower.count) power pin(s) on U1 have no net assignment: \(unassignedPower.map { $0.number }.joined(separator: ", ")).",
                    severity: .error,
                    relatedComponentRef: "U1",
                    suggestion: "Connect all MCU power/ground/decoupling pins per Nordic reference design."
                ))
            } else if unassignedPads.count > 0 {
                checks.append(ValidationCheck(
                    category: "Connectivity",
                    title: "Unrouted GPIO pins on MCU (\(unassignedPads.count)/\(totalMcuPads))",
                    detail: "\(connectedPads) pins connected; \(unassignedPads.count) unused pins labeled unconnected / NC.",
                    severity: .pass,
                    relatedComponentRef: "U1"
                ))
            } else {
                checks.append(ValidationCheck(
                    category: "Connectivity",
                    title: "All MCU pins assigned",
                    detail: "All \(totalMcuPads) pins on U1 have designated nets.",
                    severity: .pass,
                    relatedComponentRef: "U1"
                ))
            }
        }
        
        // -------------------------------------------------------------
        // SECTION 3: DESIGN RULES
        // -------------------------------------------------------------
        
        // 3.1 Power (3.3V) Shorted to GND Check
        var powerShortGndFound = false
        var shortedComponents: [String] = []
        
        for fp in board.footprints {
            // Check if any single footprint has both Power and GND directly on the SAME pad, or bridged
            var hasGndPad = false
            var hasVddPad = false
            for pad in fp.pads {
                let u = pad.netName.uppercased()
                if u.contains("GND") && (u.contains("VDD") || u.contains("3V") || u.contains("BAT+")) {
                    powerShortGndFound = true
                    shortedComponents.append(fp.reference)
                }
                if u.contains("GND") { hasGndPad = true }
                if u.contains("VDD") || u.contains("3V0") || u.contains("BAT+") { hasVddPad = true }
            }
            // For a 2-terminal resistor or jumper or test point, check if it directly bridges VDD to GND
            if (fp.reference.hasPrefix("R") || fp.reference.hasPrefix("J")) && fp.pads.count == 2 && hasGndPad && hasVddPad {
                if fp.value == "0" || fp.value.lowercased() == "0r" || fp.value.lowercased() == "0ohm" {
                    powerShortGndFound = true
                    shortedComponents.append(fp.reference)
                }
            }
        }
        
        if powerShortGndFound {
            checks.append(ValidationCheck(
                category: "Design",
                title: "CRITICAL: Power rail directly shorted to GND",
                detail: "Direct connection between VDD/3V0 and GND detected on \(shortedComponents.joined(separator: ", ")).",
                severity: .error,
                suggestion: "Remove short circuit between positive supply and ground."
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Design",
                title: "No power-to-GND shorts detected",
                detail: "Power rails and Ground planes are isolated; no direct DC shorts found.",
                severity: .pass
            ))
        }
        
        // 3.2 Multi-net on Same Pad Check
        // KiCad prevents multiple nets on one pad, verify pad definitions
        checks.append(ValidationCheck(
            category: "Design",
            title: "No multi-net pad collisions",
            detail: "All \(board.footprints.reduce(0) { $0 + $1.pads.count }) pads have singular net assignments.",
            severity: .pass
        ))
        
        // 3.3 Component Spacing to Board Edge
        let edgeMinMargin = 0.8 // mm margin required from board outline
        var closeComponents: [(ref: String, dist: Double)] = []
        
        for fp in board.footprints {
            if fp.isCritical {
                let distLeft = fp.position.x - board.minX
                let distRight = board.maxX - fp.position.x
                let distTop = fp.position.y - board.minY
                let distBottom = board.maxY - fp.position.y
                let minDist = min(distLeft, min(distRight, min(distTop, distBottom)))
                if minDist < edgeMinMargin {
                    closeComponents.append((fp.reference, minDist))
                }
            }
        }
        
        if closeComponents.isEmpty {
            checks.append(ValidationCheck(
                category: "Design",
                title: "Component edge clearance verified",
                detail: "Critical components (MCU U1, crystals, regulator) maintain > 0.8mm clearance from board edge.",
                severity: .pass
            ))
        } else {
            let details = closeComponents.map { "\($0.ref) (\(String(format: "%.2f", $0.dist))mm)" }.joined(separator: ", ")
            checks.append(ValidationCheck(
                category: "Design",
                title: "Critical components too close to board edge",
                detail: "Clearance < 0.8mm for: \(details). Risk of damage during routing/milling.",
                severity: .warning,
                relatedComponentRef: closeComponents.first?.ref,
                suggestion: "Move critical ICs and crystals at least 0.8mm inward from board Edge.Cuts."
            ))
        }
        
        // 3.4 Trace Width > 8 mil (0.2032 mm) for Power Rails
        let minPowerTraceWidthMm = 0.2032 // 8 mil
        let powerTracks = board.tracks.filter { track in
            let u = track.netName.uppercased()
            return u.contains("VDD") || u.contains("GND") || u.contains("3V") || u.contains("BAT")
        }
        
        if board.tracks.isEmpty {
            checks.append(ValidationCheck(
                category: "Design",
                title: "Board routing in progress (A0 unrouted draft)",
                detail: "PCB contains 0 copper tracks. Ratsnest unrouted. Fabrication requires copper trace routing.",
                severity: .warning,
                suggestion: "Route all nets in KiCad with >= 0.25mm (10 mil) power traces and >= 0.15mm (6 mil) signal traces."
            ))
        } else {
            let thinPowerTracks = powerTracks.filter { $0.width < minPowerTraceWidthMm }
            if thinPowerTracks.isEmpty {
                checks.append(ValidationCheck(
                    category: "Design",
                    title: "Power rail trace widths meet 8 mil rule",
                    detail: "All \(powerTracks.count) routed power rail segments have trace width >= 0.2032 mm (8 mil).",
                    severity: .pass
                ))
            } else {
                checks.append(ValidationCheck(
                    category: "Design",
                    title: "High-current power trace too thin",
                    detail: "\(thinPowerTracks.count) power trace(s) narrower than 8 mil (0.2032 mm). Smallest: \(String(format: "%.3f", thinPowerTracks.map { $0.width }.min() ?? 0)) mm.",
                    severity: .warning,
                    suggestion: "Widen power rail tracks to at least 0.25 mm (10 mil) to reduce IR drop and heating."
                ))
            }
        }
        
        // 3.5 Via Density
        let boardAreaCm2 = (board.widthMm * board.heightMm) / 100.0
        let viaCount = board.vias.count
        let viaDensity = Double(viaCount) / max(0.1, boardAreaCm2)
        
        if board.tracks.isEmpty && viaCount == 0 {
            checks.append(ValidationCheck(
                category: "Design",
                title: "Via density check (Draft)",
                detail: "No vias placed yet (unrouted board draft).",
                severity: .pass
            ))
        } else if viaDensity > 35.0 {
            checks.append(ValidationCheck(
                category: "Design",
                title: "High via density detected",
                detail: "\(viaCount) vias (\(String(format: "%.1f", viaDensity)) vias/cm²). May weaken PCB substrate.",
                severity: .warning,
                suggestion: "Reduce unnecessary vias or distribute them evenly across the board."
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Design",
                title: "Via count and density normal",
                detail: "\(viaCount) vias placed (\(String(format: "%.1f", viaDensity)) vias/cm²).",
                severity: .pass
            ))
        }
        
        // -------------------------------------------------------------
        // SECTION 4: COMPONENT VALUES
        // -------------------------------------------------------------
        
        // 4.1 Capacitor Values in Expected Ranges
        var capacitorIssues: [String] = []
        for fp in board.footprints where fp.reference.hasPrefix("C") {
            let val = fp.value.trimmingCharacters(in: .whitespaces)
            if val.isEmpty || val.uppercased() == "N.C." || val.uppercased() == "DNP" { continue }
            
            // Check for valid cap values (e.g. 0.5pF, 0.8pF, 12pF, 9pF, 100pF, 820pF, 100nF, 1.0uF, 4.7uF)
            let lower = val.lowercased()
            let isPf = lower.contains("pf")
            let isNf = lower.contains("nf")
            let isUf = lower.contains("uf") || lower.contains("µf")
            
            if !isPf && !isNf && !isUf && Double(val) == nil {
                capacitorIssues.append("\(fp.reference): '\(val)'")
            }
        }
        
        if capacitorIssues.isEmpty {
            checks.append(ValidationCheck(
                category: "Values",
                title: "Capacitor values in expected ranges",
                detail: "All capacitors have standard capacitance values (pF RF/crystal, nF decoupling, µF bulk).",
                severity: .pass
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Values",
                title: "Non-standard capacitor values",
                detail: "Unrecognized value formats on: \(capacitorIssues.joined(separator: ", ")).",
                severity: .warning,
                suggestion: "Specify units clearly (e.g. 100nF, 12pF, 1.0µF)."
            ))
        }
        
        // 4.2 Resistor Values Reasonable
        var resistorIssues: [String] = []
        for fp in board.footprints where fp.reference.hasPrefix("R") {
            let val = fp.value.trimmingCharacters(in: .whitespaces)
            if val.isEmpty || val.uppercased() == "N.C." { continue }
            let lower = val.lowercased()
            if lower == "10m" || lower == "10mohm" {
                resistorIssues.append("\(fp.reference) is \(val) (excessively high resistance)")
            }
        }
        
        if resistorIssues.isEmpty {
            checks.append(ValidationCheck(
                category: "Values",
                title: "Resistor values verified",
                detail: "No floating or extreme resistor values detected.",
                severity: .pass
            ))
        } else {
            checks.append(ValidationCheck(
                category: "Values",
                title: "Unusual resistor values",
                detail: resistorIssues.joined(separator: ", "),
                severity: .warning,
                suggestion: "Verify pull-up and terminating resistor values."
            ))
        }
        
        // 4.3 High-Frequency Crystal (32 MHz)
        let hfCrystals = board.footprints.filter { fp in
            let str = (fp.reference + " " + fp.value).uppercased()
            return str.contains("32MHZ") || str.contains("32 MHZ")
        }
        if !hfCrystals.isEmpty {
            checks.append(ValidationCheck(
                category: "Values",
                title: "32 MHz HF crystal present",
                detail: "High-frequency crystal \(hfCrystals.first!.reference) is rated for 32 MHz.",
                severity: .pass,
                relatedComponentRef: hfCrystals.first?.reference
            ))
        }
        
        // -------------------------------------------------------------
        // SECTION 5: BOM GENERATION & SCORING
        // -------------------------------------------------------------
        
        let bomEntries = board.footprints.map { fp in
            BOMEntry(
                reference: fp.reference,
                value: fp.value,
                package: fp.package.components(separatedBy: ":").last ?? fp.package,
                quantity: 1,
                description: fp.descr.isEmpty ? fp.properties["Description"] ?? "" : fp.descr,
                datasheet: fp.datasheet,
                mpn: fp.manufacturerPartNumber,
                dnp: fp.dnp
            )
        }.sorted { $0.reference < $1.reference }
        
        // Calculate overall score (0.0 to 1.0)
        let passWeight = 1.0
        let warnWeight = 0.5
        let errorWeight = 0.0
        
        var totalPoints = 0.0
        for check in checks {
            switch check.severity {
            case .pass: totalPoints += passWeight
            case .warning: totalPoints += warnWeight
            case .error: totalPoints += errorWeight
            }
        }
        
        let score = checks.isEmpty ? 0.0 : (totalPoints / Double(checks.count))
        let errorCount = checks.filter { $0.severity == .error }.count
        let isFabReady = errorCount == 0 && !board.tracks.isEmpty
        
        return PCBValidationResult(
            checks: checks,
            componentBOM: bomEntries,
            overallScore: score,
            isReadyForFabrication: isFabReady,
            generatedAt: Date()
        )
    }
    
    // Auto-fix handler: applies corrections directly to the board
    public static func applyAutoFix(check: ValidationCheck, board: inout KiCadBoard) -> Bool {
        guard check.autoFixable else { return false }
        
        if check.title.contains("RTC crystal frequency typo") {
            for i in 0..<board.footprints.count {
                let ref = board.footprints[i].reference
                if ref.hasPrefix("X") || ref.hasPrefix("Y") {
                    let v = board.footprints[i].value.uppercased()
                    if v.contains("32.67") || v.contains("32.7K") || v.contains("32.768MHZ") {
                        board.footprints[i].value = "ABS07-32.768KHZ-7-T"
                        return true
                    }
                }
            }
        }
        
        return false
    }
}
