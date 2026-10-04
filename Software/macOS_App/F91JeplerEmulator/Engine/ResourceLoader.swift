import Foundation
import AppKit

public enum ResourceLoader {
    public static func url(forResource name: String, withExtension ext: String) -> URL? {
        // 1. Subdirectory "Resources/Embedded"
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Embedded") {
            return url
        }
        // 2. Subdirectory "Embedded"
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Embedded") {
            return url
        }
        // 3. Root bundle
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        // 4. FileSystem relative to main bundle resource path
        if let resourcePath = Bundle.main.resourcePath {
            let candidate1 = URL(fileURLWithPath: resourcePath).appendingPathComponent("Embedded").appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: candidate1.path) {
                return candidate1
            }
            let candidate2 = URL(fileURLWithPath: resourcePath).appendingPathComponent("Resources/Embedded").appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: candidate2.path) {
                return candidate2
            }
            let candidate3 = URL(fileURLWithPath: resourcePath).appendingPathComponent("\(name).\(ext)")
            if FileManager.default.fileExists(atPath: candidate3.path) {
                return candidate3
            }
        }
        return nil
    }
    
    public static func image(named name: String) -> NSImage? {
        if let url = url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }
}
