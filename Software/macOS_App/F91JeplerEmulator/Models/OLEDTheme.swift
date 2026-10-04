import Foundation
import SwiftUI

public enum OLEDTheme: String, CaseIterable, Identifiable {
    case cyan = "Retro Cyan OLED"
    case amber = "Amber OLED"
    case green = "Classic Green LCD"
    case white = "Ice White OLED"
    
    public var id: String { rawValue }
    
    public var litColor: Color {
        switch self {
        case .cyan: return Color(red: 0.0, green: 0.9, blue: 1.0)
        case .amber: return Color(red: 1.0, green: 0.72, blue: 0.0)
        case .green: return Color(red: 0.22, green: 1.0, blue: 0.22)
        case .white: return Color(red: 0.92, green: 0.97, blue: 1.0)
        }
    }
    
    public var unlitColor: Color {
        switch self {
        case .cyan: return Color(red: 0.02, green: 0.05, blue: 0.08)
        case .amber: return Color(red: 0.08, green: 0.04, blue: 0.01)
        case .green: return Color(red: 0.04, green: 0.09, blue: 0.04)
        case .white: return Color(red: 0.03, green: 0.03, blue: 0.03)
        }
    }
    
    public var glowColor: Color {
        litColor.opacity(0.35)
    }
    
    public var bezelBorderColor: Color {
        switch self {
        case .cyan: return Color(red: 0.1, green: 0.25, blue: 0.35)
        case .amber: return Color(red: 0.35, green: 0.22, blue: 0.08)
        case .green: return Color(red: 0.15, green: 0.3, blue: 0.15)
        case .white: return Color(white: 0.25)
        }
    }
}

public struct DisplayMetrics {
    public var fps: Double = 0.0
    public var frameCount: UInt64 = 0
    public var drawCallCount: UInt64 = 0
    public var litPixelCount: Int = 0
    public var lastFrameLatencyMs: Double = 0.0
    
    public init() {}
}
