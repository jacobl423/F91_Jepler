import Foundation
import AppKit

public enum KiCadAppType: String, CaseIterable, Identifiable {
    case pcbEditor = "PCB Editor"
    case schematicEditor = "Schematic Editor"
    case kicadProject = "KiCad Project"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .pcbEditor: return "square.grid.3x3"
        case .schematicEditor: return "point.filled.topleft.down.curvedto.point.bottomright.up"
        case .kicadProject: return "folder.badge.gearshape"
        }
    }
}

public struct KiCadDRCItem: Identifiable, Equatable {
    public let id = UUID()
    public let description: String
    public let xMm: Double?
    public let yMm: Double?
    public let uuid: String?
}

public struct KiCadDRCViolation: Identifiable, Equatable {
    public let id = UUID()
    public let type: String
    public let severity: String // "error", "warning"
    public let description: String
    public let items: [KiCadDRCItem]
    
    public var primaryPosition: (x: Double, y: Double)? {
        for it in items {
            if let x = it.xMm, let y = it.yMm {
                return (x, y)
            }
        }
        return nil
    }
}

public enum ValidationConfidence: String, Codable {
    case pass
    case fail
    case inconclusive
    case advisory
}

public struct KiCadDRCReport: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp: Date
    public let sourceFile: String
    public let sourceSHA256: String
    public let toolVersion: String
    public let exitCode: Int32
    public let violations: [KiCadDRCViolation]
    public let unconnected: [KiCadDRCViolation]
    public let schemaIsKnown: Bool
    
    public var errorCount: Int {
        violations.filter { $0.severity == "error" }.count
    }
    public var warningCount: Int {
        violations.filter { $0.severity == "warning" }.count
    }
    public var unconnectedCount: Int {
        unconnected.count
    }
    public var isClean: Bool {
        exitCode == 0 && errorCount == 0 && unconnectedCount == 0
    }
    public var confidence: ValidationConfidence { exitCode == 0 ? (isClean ? .pass : .fail) : .inconclusive }
}

public final class KiCadToolService {
    public static let shared = KiCadToolService()
    
    private init() {}
    
    // MARK: - Executable & App Discovery
    
    public static func findKiCadCli() -> String? {
        let candidates = [
            "/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli",
            "/Applications/KiCad.app/Contents/MacOS/kicad-cli",
            "/opt/homebrew/bin/kicad-cli",
            "/usr/local/bin/kicad-cli"
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    public static func findKiCadApp(type: KiCadAppType) -> URL? {
        switch type {
        case .pcbEditor:
            let candidates = [
                "/Applications/KiCad/PCB Editor.app",
                "/Applications/KiCad/KiCad.app/Contents/Applications/pcbnew.app",
                "/Applications/KiCad.app/Contents/Applications/pcbnew.app"
            ]
            for p in candidates where FileManager.default.fileExists(atPath: p) {
                return URL(fileURLWithPath: p)
            }
        case .schematicEditor:
            let candidates = [
                "/Applications/KiCad/Schematic Editor.app",
                "/Applications/KiCad/KiCad.app/Contents/Applications/eeschema.app",
                "/Applications/KiCad.app/Contents/Applications/eeschema.app"
            ]
            for p in candidates where FileManager.default.fileExists(atPath: p) {
                return URL(fileURLWithPath: p)
            }
        case .kicadProject:
            let candidates = [
                "/Applications/KiCad/KiCad.app",
                "/Applications/KiCad.app"
            ]
            for p in candidates where FileManager.default.fileExists(atPath: p) {
                return URL(fileURLWithPath: p)
            }
        }
        return nil
    }
    
    // MARK: - Launching & Revealing
    
    @discardableResult
    public func openFileInKiCad(fileURL: URL, appType: KiCadAppType) -> Bool {
        if let appURL = Self.findKiCadApp(type: appType) {
            let conf = NSWorkspace.OpenConfiguration()
            conf.activates = true
            NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: conf) { _, error in
                if let err = error {
                    NSLog("Failed to open file in KiCad %@: %@", appType.rawValue, err.localizedDescription)
                }
            }
            return true
        } else {
            // Fallback to default application
            return NSWorkspace.shared.open(fileURL)
        }
    }
    
    public func revealInFinder(fileURL: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
    
    private func version(of cli: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cli)
        process.arguments = ["version"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard process.terminationStatus == 0, !output.isEmpty else {
            throw NSError(domain: "KiCadToolService", code: 11, userInfo: [NSLocalizedDescriptionKey: "Could not establish KiCad CLI version; validation result cannot be trusted."])
        }
        return output
    }

    // MARK: - 3D Raytrace Render
    
    public func render3D(pcbURL: URL, outputURL: URL, width: Int = 1000, height: Int = 1000) async throws -> NSImage {
        guard let cli = Self.findKiCadCli() else {
            throw NSError(domain: "KiCadToolService", code: 1, userInfo: [NSLocalizedDescriptionKey: "kicad-cli not found in /Applications/KiCad"])
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: cli)
        process.arguments = [
            "pcb", "render",
            "--output", outputURL.path,
            "--width", String(width),
            "--height", String(height),
            pcbURL.path
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0, FileManager.default.fileExists(atPath: outputURL.path) else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown render error"
            throw NSError(domain: "KiCadToolService", code: 2, userInfo: [NSLocalizedDescriptionKey: "KiCad render failed: \(output)"])
        }
        
        guard let image = NSImage(contentsOf: outputURL) else {
            throw NSError(domain: "KiCadToolService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to load rendered image"])
        }
        return image
    }
    
    // MARK: - DRC Runner
    
    public func runDRC(pcbURL: URL) async throws -> KiCadDRCReport {
        guard let cli = Self.findKiCadCli() else {
            throw NSError(domain: "KiCadToolService", code: 1, userInfo: [NSLocalizedDescriptionKey: "kicad-cli not found in /Applications/KiCad"])
        }
        
        let tempJson = FileManager.default.temporaryDirectory.appendingPathComponent("kicad_drc_\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempJson) }
        
        let inputDigest = try FirmwareBuildManifest.digest(pcbURL)
        let toolVersion = try version(of: cli)
        let snapshotURL = FileManager.default.temporaryDirectory.appendingPathComponent("kicad_drc_input_\(UUID().uuidString).kicad_pcb")
        try FileManager.default.copyItem(at: pcbURL, to: snapshotURL)
        defer { try? FileManager.default.removeItem(at: snapshotURL) }
        guard try FirmwareBuildManifest.digest(snapshotURL) == inputDigest else {
            throw NSError(domain: "KiCadToolService", code: 7, userInfo: [NSLocalizedDescriptionKey: "PCB changed while preparing the DRC snapshot; run again."])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cli)
        process.arguments = [
            "pcb", "drc",
            "--format", "json",
            "--output", tempJson.path,
            snapshotURL.path
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "No DRC output"
            throw NSError(domain: "KiCadToolService", code: 8, userInfo: [NSLocalizedDescriptionKey: "KiCad DRC exited \(process.terminationStatus): \(output)"])
        }
        guard try FirmwareBuildManifest.digest(snapshotURL) == inputDigest else {
            throw NSError(domain: "KiCadToolService", code: 9, userInfo: [NSLocalizedDescriptionKey: "PCB snapshot changed while KiCad DRC was running; result is inconclusive."])
        }
        guard FileManager.default.fileExists(atPath: tempJson.path),
              let data = try? Data(contentsOf: tempJson) else {
            let outData = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outData, encoding: .utf8) ?? "No DRC report generated"
            throw NSError(domain: "KiCadToolService", code: 4, userInfo: [NSLocalizedDescriptionKey: "DRC execution error: \(output)"])
        }
        
        let report = try parseDRCJson(data: data, sourceFile: pcbURL.lastPathComponent,
                                      sourceSHA256: inputDigest, toolVersion: toolVersion, exitCode: process.terminationStatus)
        guard report.schemaIsKnown else {
            throw NSError(domain: "KiCadToolService", code: 12, userInfo: [NSLocalizedDescriptionKey: "DRC JSON schema/version is unsupported; result is inconclusive."])
        }
        return report
    }
    
    private func parseDRCJson(data: Data, sourceFile: String, sourceSHA256: String,
                               toolVersion: String, exitCode: Int32) throws -> KiCadDRCReport {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "KiCadToolService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid DRC JSON"])
        }
        
        func parseViolations(list: [[String: Any]]) -> [KiCadDRCViolation] {
            return list.map { dict in
                let desc = dict["description"] as? String ?? "DRC violation"
                let severity = dict["severity"] as? String ?? "warning"
                let type = dict["type"] as? String ?? "violation"
                
                var items: [KiCadDRCItem] = []
                if let rawItems = dict["items"] as? [[String: Any]] {
                    for it in rawItems {
                        let itDesc = it["description"] as? String ?? ""
                        var xMm: Double? = nil
                        var yMm: Double? = nil
                        if let pos = it["pos"] as? [String: Any] {
                            xMm = pos["x"] as? Double
                            yMm = pos["y"] as? Double
                        }
                        let uuid = it["uuid"] as? String
                        items.append(KiCadDRCItem(description: itDesc, xMm: xMm, yMm: yMm, uuid: uuid))
                    }
                }
                return KiCadDRCViolation(type: type, severity: severity, description: desc, items: items)
            }
        }
        
        guard let rawViolations = root["violations"] as? [[String: Any]],
              let rawUnconnected = root["unconnected_items"] as? [[String: Any]] else {
            throw NSError(domain: "KiCadToolService", code: 10, userInfo: [NSLocalizedDescriptionKey: "DRC JSON lacks required violations or unconnected_items arrays; result is inconclusive."])
        }
        
        return KiCadDRCReport(
            timestamp: Date(),
            sourceFile: sourceFile,
            sourceSHA256: sourceSHA256,
            toolVersion: toolVersion,
            exitCode: exitCode,
            violations: parseViolations(list: rawViolations),
            unconnected: parseViolations(list: rawUnconnected),
            schemaIsKnown: root["violations"] is [[String: Any]] && root["unconnected_items"] is [[String: Any]]
        )
    }
    
    // MARK: - Gerber & Drill Manufacturing Export
    
    public func exportManufacturingZip(pcbURL: URL, destinationDir: URL? = nil) async throws -> URL {
        guard let cli = Self.findKiCadCli() else {
            throw NSError(domain: "KiCadToolService", code: 1, userInfo: [NSLocalizedDescriptionKey: "kicad-cli not found in /Applications/KiCad"])
        }
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("gerber_export_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // 1. Export Gerbers
        let gbrProcess = Process()
        gbrProcess.executableURL = URL(fileURLWithPath: cli)
        gbrProcess.arguments = ["pcb", "export", "gerbers", "-o", tempDir.path + "/", pcbURL.path]
        try gbrProcess.run()
        gbrProcess.waitUntilExit()
        
        // 2. Export Drills
        let drlProcess = Process()
        drlProcess.executableURL = URL(fileURLWithPath: cli)
        drlProcess.arguments = ["pcb", "export", "drill", "-o", tempDir.path + "/", pcbURL.path]
        try drlProcess.run()
        drlProcess.waitUntilExit()
        
        // 3. Zip files together
        let baseName = pcbURL.deletingPathExtension().lastPathComponent
        let outDir = destinationDir ?? pcbURL.deletingLastPathComponent()
        let zipURL = outDir.appendingPathComponent("\(baseName)_gerbers.zip")
        if FileManager.default.fileExists(atPath: zipURL.path) {
            try? FileManager.default.removeItem(at: zipURL)
        }
        
        let zipProcess = Process()
        zipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        zipProcess.currentDirectoryURL = tempDir
        zipProcess.arguments = ["-q", "-r", zipURL.path, "."]
        try zipProcess.run()
        zipProcess.waitUntilExit()
        
        guard FileManager.default.fileExists(atPath: zipURL.path) else {
            throw NSError(domain: "KiCadToolService", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to create Gerber zip file"])
        }
        
        return zipURL
    }
}
