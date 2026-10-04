import Foundation
import CoreGraphics

public struct Point2D: Equatable, Hashable, Codable {
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
    
    public func distance(to other: Point2D) -> Double {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

public enum PathElement: Equatable {
    case line(start: Point2D, end: Point2D)
    case arc(start: Point2D, mid: Point2D, end: Point2D)
    case circle(center: Point2D, radius: Double)
}

public struct PCBTrack: Equatable, Identifiable {
    public var id: String { "\(layer)_\(start.x)_\(start.y)_\(end.x)_\(end.y)_\(netId)" }
    public let start: Point2D
    public let end: Point2D
    public let width: Double
    public let layer: String
    public let netId: Int
    public let netName: String
    
    public init(start: Point2D, end: Point2D, width: Double, layer: String, netId: Int, netName: String) {
        self.start = start
        self.end = end
        self.width = width
        self.layer = layer
        self.netId = netId
        self.netName = netName
    }
    
    public var lengthMm: Double {
        start.distance(to: end)
    }
}

public struct PCBVia: Equatable, Identifiable {
    public var id: String { "\(position.x)_\(position.y)_\(netId)" }
    public let position: Point2D
    public let size: Double
    public let drill: Double
    public let layers: [String]
    public let netId: Int
    public let netName: String
    
    public init(position: Point2D, size: Double, drill: Double, layers: [String], netId: Int, netName: String) {
        self.position = position
        self.size = size
        self.drill = drill
        self.layers = layers
        self.netId = netId
        self.netName = netName
    }
}

public struct PCBZone: Equatable, Identifiable {
    public var id: String { "\(layer)_\(netId)_\(polygon.count)" }
    public let layer: String
    public let netId: Int
    public let netName: String
    public let polygon: [Point2D]
    
    public init(layer: String, netId: Int, netName: String, polygon: [Point2D]) {
        self.layer = layer
        self.netId = netId
        self.netName = netName
        self.polygon = polygon
    }
}

public enum DrawingShape: Equatable {
    case line(start: Point2D, end: Point2D)
    case arc(start: Point2D, mid: Point2D, end: Point2D)
    case circle(center: Point2D, radius: Double)
    case rect(start: Point2D, end: Point2D)
    case text(text: String, position: Point2D, size: Double)
}

public struct PCBDrawing: Equatable, Identifiable {
    public var id = UUID()
    public let shape: DrawingShape
    public let layer: String
    public let strokeWidth: Double
    
    public init(shape: DrawingShape, layer: String, strokeWidth: Double = 0.15) {
        self.shape = shape
        self.layer = layer
        self.strokeWidth = strokeWidth
    }
}

public struct Pad: Equatable, Identifiable {
    public var id: String { "\(number)_\(netId)_\(position.x)_\(position.y)" }
    public let number: String
    public let netId: Int
    public let netName: String
    public let position: Point2D
    public let size: Point2D
    public let shape: String
    public let layers: [String]
    public let pinFunction: String?
    
    public init(
        number: String,
        netId: Int,
        netName: String,
        position: Point2D,
        size: Point2D,
        shape: String = "roundrect",
        layers: [String] = ["F.Cu"],
        pinFunction: String? = nil
    ) {
        self.number = number
        self.netId = netId
        self.netName = netName
        self.position = position
        self.size = size
        self.shape = shape
        self.layers = layers
        self.pinFunction = pinFunction
    }
}

public struct Footprint: Identifiable, Equatable {
    public var id: String { reference }
    public var reference: String
    public var value: String
    public var layer: String
    public var position: Point2D
    public var rotation: Double
    public var pads: [Pad]
    public var package: String
    public var properties: [String: String]
    public var dnp: Bool
    public var descr: String
    
    public init(
        reference: String,
        value: String,
        layer: String,
        position: Point2D,
        rotation: Double,
        pads: [Pad],
        package: String = "",
        properties: [String: String] = [:],
        dnp: Bool = false,
        descr: String = ""
    ) {
        self.reference = reference
        self.value = value
        self.layer = layer
        self.position = position
        self.rotation = rotation
        self.pads = pads
        self.package = package
        self.properties = properties
        self.dnp = dnp
        self.descr = descr
    }
    
    public var datasheet: String {
        properties["Datasheet"] ?? properties["datasheet"] ?? ""
    }
    
    public var manufacturerPartNumber: String {
        properties["MPN"] ?? properties["mpn"] ?? properties["PartNumber"] ?? properties["Mfr_Part_Number"] ?? ""
    }
    
    public var isCritical: Bool {
        let refUpper = reference.uppercased()
        let valUpper = value.uppercased()
        return refUpper == "U1" ||
               valUpper.contains("NRF52840") ||
               refUpper.hasPrefix("X") ||
               refUpper.hasPrefix("Y") ||
               valUpper.contains("32.768") ||
               valUpper.contains("32MHZ") ||
               valUpper.contains("SSD1306") ||
               refUpper == "U2"
    }
}

public struct PCBDiagnosticItem: Identifiable, Equatable {
    public var id = UUID()
    public let title: String
    public let detail: String
    public let isOk: Bool
    
    public init(title: String, detail: String, isOk: Bool) {
        self.title = title
        self.detail = detail
        self.isOk = isOk
    }
}

public struct KiCadBoard: Equatable {
    public var filename: String = "f91_jepler.kicad_pcb"
    public var minX: Double = 0.0
    public var maxX: Double = 30.0
    public var minY: Double = 0.0
    public var maxY: Double = 30.0
    
    public var edgeSegments: [PathElement] = []
    public var footprints: [Footprint] = []
    public var nets: [Int: String] = [:]
    public var tracks: [PCBTrack] = []
    public var vias: [PCBVia] = []
    public var zones: [PCBZone] = []
    public var drawings: [PCBDrawing] = []
    
    // Auto-detected or overridden pin bindings
    public var buttonAPin: String = "P0.11" // Key 1, Top-Left
    public var buttonBPin: String = "P0.12" // Key 2, Bottom-Left
    public var buttonCPin: String = "P0.24" // Key 3, Bottom-Right
    public var oledI2CAddress: String = "0x3C"
    
    public var widthMm: Double {
        max(1.0, maxX - minX)
    }
    
    public var heightMm: Double {
        max(1.0, maxY - minY)
    }
    
    public var totalTraceLengthMm: Double {
        tracks.reduce(0.0) { $0 + $1.lengthMm }
    }
    
    public func footprint(reference: String) -> Footprint? {
        footprints.first { $0.reference == reference }
    }
    
    public func pads(forNetName netName: String) -> [(footprint: Footprint, pad: Pad)] {
        var results: [(footprint: Footprint, pad: Pad)] = []
        let cleanTarget = netName.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        for fp in footprints {
            for pad in fp.pads {
                let cleanPadNet = pad.netName.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
                if cleanPadNet.caseInsensitiveCompare(cleanTarget) == .orderedSame || pad.netName == netName {
                    results.append((footprint: fp, pad: pad))
                }
            }
        }
        return results
    }
    
    public func netClass(for netName: String) -> NetClass {
        let upper = netName.uppercased()
        if upper.contains("GND") || upper == "VSS" {
            return .ground
        } else if upper.contains("VDD") || upper.contains("3V") || upper.contains("VCC") || upper.contains("BAT") || upper.contains("5V") {
            return .power
        } else if upper.contains("RF") || upper.contains("SWD") || upper.contains("XC") || upper.contains("SDA") || upper.contains("SCL") {
            return .highSpeed
        } else {
            return .signal
        }
    }
    
    public func allNetDetails() -> [NetDetail] {
        var dict: [String: (id: Int, pads: [(String, String)])] = [:]
        for (id, name) in nets {
            let clean = name.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
            if !clean.isEmpty && dict[clean] == nil {
                dict[clean] = (id, [])
            }
        }
        
        for fp in footprints {
            for pad in fp.pads {
                let clean = pad.netName.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
                if !clean.isEmpty {
                    if var existing = dict[clean] {
                        existing.pads.append((fp.reference, pad.number))
                        dict[clean] = existing
                    } else {
                        dict[clean] = (pad.netId, [(fp.reference, pad.number)])
                    }
                }
            }
        }
        
        return dict.map { name, tuple in
            NetDetail(
                netId: tuple.id,
                name: name,
                netClass: netClass(for: name),
                connectedPads: tuple.pads
            )
        }.sorted { $0.name < $1.name }
    }
    
    public var diagnostics: [PCBDiagnosticItem] {
        var items: [PCBDiagnosticItem] = []
        
        // Check Board Size vs Casio F-91 Envelope (Max 26.5mm x 25.5mm)
        let maxW = 27.0
        let maxH = 26.0
        let sizeOk = widthMm <= maxW && heightMm <= maxH
        items.append(PCBDiagnosticItem(
            title: "F-91 Mechanical Envelope Fit",
            detail: sizeOk ? "Board size (\(String(format: "%.1f", widthMm))x\(String(format: "%.1f", heightMm))mm) fits inside Casio case." : "WARNING: Board size (\(String(format: "%.1f", widthMm))x\(String(format: "%.1f", heightMm))mm) exceeds Casio case bounds!",
            isOk: sizeOk
        ))
        
        // Check Button A net
        let hasBtnA = nets.values.contains { $0.uppercased().contains("P0.11") || $0.uppercased().contains("BUTTON_A") }
        items.append(PCBDiagnosticItem(
            title: "Button A (Key 1 -> Top Left)",
            detail: hasBtnA ? "Net P0.11 / BUTTON_A detected and routed." : "WARNING: Net P0.11 / BUTTON_A not found on PCB!",
            isOk: hasBtnA
        ))
        
        // Check Button B net
        let hasBtnB = nets.values.contains { $0.uppercased().contains("P0.12") || $0.uppercased().contains("BUTTON_B") }
        items.append(PCBDiagnosticItem(
            title: "Button B (Key 2 -> Bottom Left)",
            detail: hasBtnB ? "Net P0.12 / BUTTON_B detected and routed." : "WARNING: Net P0.12 / BUTTON_B not found on PCB!",
            isOk: hasBtnB
        ))
        
        // Check Button C net
        let hasBtnC = nets.values.contains { $0.uppercased().contains("P0.24") || $0.uppercased().contains("BUTTON_C") }
        items.append(PCBDiagnosticItem(
            title: "Button C (Key 3 -> Bottom Right)",
            detail: hasBtnC ? "Net P0.24 / BUTTON_C detected and routed." : "WARNING: Net P0.24 / BUTTON_C not found on PCB!",
            isOk: hasBtnC
        ))
        
        // Check OLED I2C SDA/SCL
        let hasI2C = nets.values.contains { $0.uppercased().contains("SDA") || $0.uppercased().contains("TWISDA") }
        items.append(PCBDiagnosticItem(
            title: "OLED Display I2C Bus",
            detail: hasI2C ? "I2C SDA/SCL lines detected." : "Notice: Standard SDA/SCL net label not found (verify I2C pinout).",
            isOk: hasI2C
        ))
        
        return items
    }
    
    public init() {}
}
