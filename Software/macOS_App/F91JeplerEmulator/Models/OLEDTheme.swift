import Foundation
import SwiftUI

public enum OLEDTheme: String, CaseIterable, Identifiable {
    case white = "BuyDisplay 0.83\" White OLED (ER-OLED0.83-1)"
    case cyan = "Retro Cyan OLED"
    case amber = "Amber OLED"
    case green = "Classic Green LCD"
    
    public var id: String { rawValue }
    
    public var litColor: Color {
        switch self {
        case .white: return Color(red: 0.96, green: 0.98, blue: 1.0)
        case .cyan: return Color(red: 0.0, green: 0.9, blue: 1.0)
        case .amber: return Color(red: 1.0, green: 0.72, blue: 0.0)
        case .green: return Color(red: 0.22, green: 1.0, blue: 0.22)
        }
    }
    
    public var unlitColor: Color {
        switch self {
        case .white: return Color(red: 0.015, green: 0.015, blue: 0.02)
        case .cyan: return Color(red: 0.02, green: 0.05, blue: 0.08)
        case .amber: return Color(red: 0.08, green: 0.04, blue: 0.01)
        case .green: return Color(red: 0.04, green: 0.09, blue: 0.04)
        }
    }
    
    public var glowColor: Color {
        switch self {
        case .white: return Color.white.opacity(0.2)
        default: return litColor.opacity(0.35)
        }
    }
    
    public var bezelBorderColor: Color {
        switch self {
        case .white: return Color(white: 0.22)
        case .cyan: return Color(red: 0.1, green: 0.25, blue: 0.35)
        case .amber: return Color(red: 0.35, green: 0.22, blue: 0.08)
        case .green: return Color(red: 0.15, green: 0.3, blue: 0.15)
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
