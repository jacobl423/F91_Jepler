import Foundation
import CoreGraphics

public struct Point2D: Equatable, Hashable {
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

public enum PathElement: Equatable {
    case line(start: Point2D, end: Point2D)
    case arc(start: Point2D, mid: Point2D, end: Point2D)
    case circle(center: Point2D, radius: Double)
}

public struct Pad: Equatable, Identifiable {
    public var id: String { "\(number)_\(netId)" }
    public let number: String
    public let netId: Int
    public let netName: String
    public let position: Point2D
    public let size: Point2D
    
    public init(number: String, netId: Int, netName: String, position: Point2D, size: Point2D) {
        self.number = number
        self.netId = netId
        self.netName = netName
        self.position = position
        self.size = size
    }
}

public struct Footprint: Identifiable, Equatable {
    public var id: String { reference }
    public let reference: String
    public let value: String
    public let layer: String
    public let position: Point2D
    public let rotation: Double
    public let pads: [Pad]
    
    public init(reference: String, value: String, layer: String, position: Point2D, rotation: Double, pads: [Pad]) {
        self.reference = reference
        self.value = value
        self.layer = layer
        self.position = position
        self.rotation = rotation
        self.pads = pads
    }
}

public struct PCBDiagnosticItem: Identifiable, Equatable {
    public var id = UUID()
    public let title: String
    let detail: String
    public let isOk: Bool
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
