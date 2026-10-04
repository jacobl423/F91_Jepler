import Foundation
import SwiftUI

public enum LogCategory: String, CaseIterable, Identifiable {
    case all = "All Logs"
    case boot = "Boot / Chainload"
    case gatt = "GATT / BLE"
    case i2c = "I2C / Display"
    case buttons = "GPIO Buttons"
    case errors = "Errors & Warnings"
    
    public var id: String { rawValue }
    
    public func matches(line: String) -> Bool {
        let lower = line.lowercased()
        switch self {
        case .all:
            return true
        case .boot:
            return lower.contains("mcuboot") || lower.contains("zephyr os") ||
                   lower.contains("booting") || lower.contains("chainload") ||
                   lower.contains("image slot") || lower.contains("starting bootloader") ||
                   lower.contains("mach create")
        case .gatt:
            return lower.contains("ble") || lower.contains("bluetooth") ||
                   lower.contains("gatt") || lower.contains("adv") ||
                   lower.contains("notification") || lower.contains("clock time") ||
                   lower.contains("incoming")
        case .i2c:
            return lower.contains("display") || lower.contains("i2c") ||
                   lower.contains("twi") || lower.contains("ssd1306") ||
                   lower.contains("framebuffer") || lower.contains("pixel")
        case .buttons:
            return lower.contains("button") || lower.contains("ongpio") ||
                   lower.contains("pressed") || lower.contains("released") ||
                   lower.contains("gpioporta")
        case .errors:
            return lower.contains("err") || lower.contains("fail") ||
                   lower.contains("error") || lower.contains("fault") ||
                   lower.contains("warning") || lower.contains("unhandled")
        }
    }
}

public struct AnsiParser {
    public static func stripAnsi(from text: String) -> String {
        let pattern = "\\x1B\\[[0-9;]*[a-zA-Z]"
        return text.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
    
    public static func parseToAttributedString(text: String) -> AttributedString {
        var result = AttributedString()
        
        let pattern = "\\x1B\\[([0-9;]*)m"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return AttributedString(text)
        }
        
        let nsString = text as NSString
        var currentIndex = 0
        var currentColor: Color = Color(red: 0.88, green: 0.92, blue: 0.88)
        var isBold = false
        
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.range.location > currentIndex {
                let chunkRange = NSRange(location: currentIndex, length: match.range.location - currentIndex)
                let chunkStr = nsString.substring(with: chunkRange)
                var attributedChunk = AttributedString(chunkStr)
                attributedChunk.foregroundColor = currentColor
                if isBold {
                    attributedChunk.inlinePresentationIntent = .stronglyEmphasized
                }
                result.append(attributedChunk)
            }
            
            let codeRange = match.range(at: 1)
            let codes = nsString.substring(with: codeRange).components(separatedBy: ";")
            
            for code in codes {
                switch code {
                case "0", "":
                    currentColor = Color(red: 0.88, green: 0.92, blue: 0.88)
                    isBold = false
                case "1":
                    isBold = true
                case "30":
                    currentColor = .gray
                case "31": // Red (Error)
                    currentColor = Color(red: 1.0, green: 0.35, blue: 0.35)
                case "32": // Green (Info / Success)
                    currentColor = Color(red: 0.35, green: 0.95, blue: 0.45)
                case "33": // Yellow (Warning)
                    currentColor = Color(red: 1.0, green: 0.85, blue: 0.3)
                case "34": // Blue (Debug)
                    currentColor = Color(red: 0.45, green: 0.75, blue: 1.0)
                case "35": // Magenta
                    currentColor = Color(red: 0.95, green: 0.5, blue: 0.95)
                case "36": // Cyan
                    currentColor = Color(red: 0.35, green: 0.9, blue: 0.95)
                case "37": // White
                    currentColor = Color(white: 0.95)
                default:
                    break
                }
            }
            
            currentIndex = match.range.location + match.range.length
        }
        
        if currentIndex < nsString.length {
            let trailingStr = nsString.substring(from: currentIndex)
            var attributedChunk = AttributedString(trailingStr)
            attributedChunk.foregroundColor = currentColor
            if isBold {
                attributedChunk.inlinePresentationIntent = .stronglyEmphasized
            }
            result.append(attributedChunk)
        }
        
        return result
    }
}
