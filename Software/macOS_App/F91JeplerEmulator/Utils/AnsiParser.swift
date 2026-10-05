import Foundation
import SwiftUI
import AppKit

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
    private static let stripRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\x1B\\[[0-9;]*[a-zA-Z]")
    }()
    
    private static let ansiRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\x1B\\[([0-9;]*)m")
    }()

    public static func stripAnsi(from text: String) -> String {
        guard text.contains("\u{1B}") else { return text }
        guard let regex = stripRegex else { return text }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
    }
    
    public static func parseToAttributedString(text: String) -> AttributedString {
        guard text.contains("\u{1B}") else {
            var plain = AttributedString(text)
            plain.foregroundColor = Color(red: 0.88, green: 0.92, blue: 0.88)
            return plain
        }
        
        guard let regex = ansiRegex else {
            var fallback = AttributedString(text)
            fallback.foregroundColor = Color(red: 0.88, green: 0.92, blue: 0.88)
            return fallback
        }
        
        var result = AttributedString()
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
    
    public static func parseToNSAttributedString(text: String) -> NSAttributedString {
        let baseFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let boldFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        let defaultColor = NSColor(red: 0.88, green: 0.92, blue: 0.88, alpha: 1.0)
        
        guard text.contains("\u{1B}") else {
            return NSAttributedString(
                string: text,
                attributes: [.font: baseFont, .foregroundColor: defaultColor]
            )
        }
        
        guard let regex = ansiRegex else {
            return NSAttributedString(
                string: text,
                attributes: [.font: baseFont, .foregroundColor: defaultColor]
            )
        }
        
        let result = NSMutableAttributedString()
        let nsString = text as NSString
        var currentIndex = 0
        var currentColor: NSColor = defaultColor
        var isBold = false
        
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.range.location > currentIndex {
                let chunkRange = NSRange(location: currentIndex, length: match.range.location - currentIndex)
                let chunkStr = nsString.substring(with: chunkRange)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: isBold ? boldFont : baseFont,
                    .foregroundColor: currentColor
                ]
                result.append(NSAttributedString(string: chunkStr, attributes: attrs))
            }
            
            let codeRange = match.range(at: 1)
            let codes = nsString.substring(with: codeRange).components(separatedBy: ";")
            
            for code in codes {
                switch code {
                case "0", "":
                    currentColor = defaultColor
                    isBold = false
                case "1":
                    isBold = true
                case "30":
                    currentColor = .gray
                case "31": // Red
                    currentColor = NSColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
                case "32": // Green
                    currentColor = NSColor(red: 0.35, green: 0.95, blue: 0.45, alpha: 1.0)
                case "33": // Yellow
                    currentColor = NSColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
                case "34": // Blue
                    currentColor = NSColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1.0)
                case "35": // Magenta
                    currentColor = NSColor(red: 0.95, green: 0.5, blue: 0.95, alpha: 1.0)
                case "36": // Cyan
                    currentColor = NSColor(red: 0.35, green: 0.9, blue: 0.95, alpha: 1.0)
                case "37": // White
                    currentColor = NSColor(white: 0.95, alpha: 1.0)
                default:
                    break
                }
            }
            
            currentIndex = match.range.location + match.range.length
        }
        
        if currentIndex < nsString.length {
            let trailingStr = nsString.substring(from: currentIndex)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: isBold ? boldFont : baseFont,
                .foregroundColor: currentColor
            ]
            result.append(NSAttributedString(string: trailingStr, attributes: attrs))
        }
        
        return result
    }
}
