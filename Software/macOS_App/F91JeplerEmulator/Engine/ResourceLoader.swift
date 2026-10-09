import Foundation
import AppKit

public enum ResourceLoader {
    private static let imageCache = NSCache<NSString, NSImage>()
    private static var urlCache = [String: URL]()
    private static let cacheLock = NSLock()

    public static func url(forResource name: String, withExtension ext: String) -> URL? {
        // Component files must come from explicit external selections.
        guard (name == "F91SSD1306" && ext == "cs") || (name == "jepler-icon" && ext == "png") else {
            return nil
        }
        let cacheKey = "\(name).\(ext)"
        cacheLock.lock()
        if let cached = urlCache[cacheKey] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()
        
        let foundURL: URL? = {

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
        
            #if SWIFT_PACKAGE
            if let url = Bundle.module.url(forResource: name, withExtension: ext) {
                return url
            }
            #endif

        // 5. FileSystem relative to current working directory (workspace dev mode)
        let cwdURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let repoCandidates = [
            cwdURL.appendingPathComponent("Hardware/KiCad/drafts/f91_jepler").appendingPathComponent("\(name).\(ext)"),
            cwdURL.appendingPathComponent("build/renode-app").appendingPathComponent("\(name).\(ext)"),
            cwdURL.appendingPathComponent("bin").appendingPathComponent("\(name).\(ext)"),
            cwdURL.appendingPathComponent("Firmware/renode").appendingPathComponent("\(name).\(ext)"),
            cwdURL.appendingPathComponent("Software/macOS_App/F91JeplerEmulator/Resources/Embedded").appendingPathComponent("\(name).\(ext)")
        ]
        for candidate in repoCandidates {
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
            return nil
        }()
        
        if let found = foundURL {
            cacheLock.lock()
            urlCache[cacheKey] = found
            cacheLock.unlock()
        }
        return foundURL
    }
    
    public static func image(named name: String) -> NSImage? {
        let key = name as NSString
        if let cached = imageCache.object(forKey: key) {
            return cached
        }
        if let url = url(forResource: name, withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            imageCache.setObject(img, forKey: key)
            return img
        }
        return nil
    }
}
