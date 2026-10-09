import Foundation
import AppKit
import CryptoKit

public struct RenodeScriptReferenceEvidence: Codable, Equatable, Identifiable {
    public var id: String { "\(reference)|\(resolvedPath ?? "unresolved")" }
    public let reference: String
    public let resolvedPath: String?
    public let sha256: String?
    public let content: String?
}

public final class RenodeProcessManager {
    public private(set) var process: Process?
    public private(set) var port: UInt16 = 0
    public private(set) var workDir: URL?
    public private(set) var uartLogURL: URL?
    public private(set) var stagedAssetSHA256: [String: String] = [:]
    public private(set) var stagedAssetURLs: [String: URL] = [:]
    public private(set) var rescReferenceEvidence: [RenodeScriptReferenceEvidence] = []
    public private(set) var preLaunchEvidence: (() throws -> Void)?
    public private(set) var preLaunchRescSHA256: String?
    public private(set) var outputPipe = Pipe()
    public var onOutputReceived: ((String) -> Void)?
    public var onTerminated: ((Int32) -> Void)?

    public init() {
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.stop() }
    }

    public static var bundledRenodeExecutable: String? {
        #if arch(arm64)
        let architecture = "arm64"
        #else
        let architecture = "x86_64"
        #endif
        let path = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Renode/\(architecture)/renode").path
        return FileManager.default.isExecutableFile(atPath: path) ? path : nil
    }

    public static func findRenodeExecutable(customPath: String? = nil) -> String? {
        if let customPath, !customPath.isEmpty, FileManager.default.isExecutableFile(atPath: customPath) { return customPath }
        if let bundled = bundledRenodeExecutable { return bundled }
        let locations = ["/Applications/Renode.app/Contents/MacOS/renode",
                         NSHomeDirectory() + "/Applications/Renode.app/Contents/MacOS/renode",
                         "/opt/homebrew/bin/renode", "/usr/local/bin/renode"]
        for path in locations where FileManager.default.isExecutableFile(atPath: path) { return path }
        for directory in (ProcessInfo.processInfo.environment["PATH"] ?? "").components(separatedBy: ":") {
            let candidate = (directory as NSString).appendingPathComponent("renode")
            if FileManager.default.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    public func start(appBinURL: URL,
                      bootloaderURL: URL?,
                      ssd1306CsURL: URL?,
                      renodePath: String,
                      customRescURL: URL? = nil,
                      approvedRescSHA256: String? = nil,
                      approvedRescReferences: [RenodeScriptReferenceEvidence] = [],
                      expectedAppSHA256: String? = nil,
                      expectedBootloaderSHA256: String? = nil,
                      appFormat: RenodeScriptGenerator.BinaryFormat? = nil,
                      bootloaderFormat: RenodeScriptGenerator.BinaryFormat? = nil) throws -> (port: UInt16, uartPort: UInt16) {
        stop()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("f91_renode_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        workDir = tempDir

        let localApp = try stage(appBinURL, in: tempDir, fallbackName: "app", key: "app")
        guard expectedAppSHA256 == nil || stagedAssetSHA256["app"] == expectedAppSHA256 else {
            throw Self.error(1, "Staged app image does not match the verified build manifest.")
        }
        let localBootloader: URL?
        if let bootloaderURL {
            localBootloader = try stage(bootloaderURL, in: tempDir, fallbackName: "mcuboot", key: "mcuboot")
            guard expectedBootloaderSHA256 == nil || stagedAssetSHA256["mcuboot"] == expectedBootloaderSHA256 else {
                throw Self.error(2, "Staged MCUboot ELF does not match the verified build manifest.")
            }
        } else { localBootloader = nil }
        var localDisplay: URL?
        if let ssd1306CsURL { localDisplay = try stage(ssd1306CsURL, in: tempDir, fallbackName: "F91SSD1306", key: "displayModel") }

        let ports = findFreePorts(count: 2)
        let monitorPort = ports.first ?? 1239
        let uartPort = ports.count > 1 ? ports[1] : 1240
        port = monitorPort
        let uartLog = tempDir.appendingPathComponent("uart.log")
        uartLogURL = uartLog
        let scriptURL = tempDir.appendingPathComponent("session.resc")
        let isCustom = customRescURL != nil

        if let customRescURL {
            guard FileManager.default.fileExists(atPath: customRescURL.path), let approvedRescSHA256 else {
                throw Self.error(3, "A custom .resc script requires explicit approval and must still exist.")
            }
            let stagedDigest = try Self.stageReviewedScript(at: customRescURL, to: scriptURL, approvedSHA256: approvedRescSHA256)
            rescReferenceEvidence = try Self.referenceEvidence(in: String(contentsOf: scriptURL, encoding: .utf8), relativeTo: customRescURL.deletingLastPathComponent())
            guard stagedDigest == approvedRescSHA256, rescReferenceEvidence == approvedRescReferences else {
                throw Self.error(4, "The reviewed .resc script or its referenced resources changed. Review them again.")
            }
            stagedAssetSHA256["resc"] = stagedDigest
            stagedAssetURLs["resc"] = scriptURL
            let sourceDirectory = customRescURL.deletingLastPathComponent()
            let approvedEvidence = approvedRescReferences
            preLaunchRescSHA256 = approvedRescSHA256
            preLaunchEvidence = {
                guard try Self.sha256(scriptURL) == approvedRescSHA256,
                      try Self.referenceEvidence(in: String(contentsOf: scriptURL, encoding: .utf8), relativeTo: sourceDirectory) == approvedEvidence else {
                    throw Self.error(5, "The reviewed script changed immediately before Renode launch.")
                }
                for evidence in approvedEvidence {
                    guard let path = evidence.resolvedPath, let expected = evidence.sha256,
                          path != "Renode built-in resource (Renode installation)" else { continue }
                    guard try Self.sha256(URL(fileURLWithPath: path)) == expected else {
                        throw Self.error(6, "Referenced resource changed after approval: \(path)")
                    }
                }
            }
        } else {
            let script = RenodeScriptGenerator.generateResc(appBinPath: localApp.path,
                                                             bootloaderPath: localBootloader?.path,
                                                             uartPort: uartPort,
                                                             uartLogPath: uartLog.path,
                                                             ssd1306CsPath: localDisplay?.path,
                                                             appFormat: appFormat,
                                                             bootloaderFormat: bootloaderFormat)
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            stagedAssetSHA256["resc"] = try Self.sha256(scriptURL)
            stagedAssetURLs["resc"] = scriptURL
            preLaunchRescSHA256 = stagedAssetSHA256["resc"]
            preLaunchEvidence = nil
        }

        let configURL = tempDir.appendingPathComponent("renode.config")
        try """
        [general]
        history-path = \(tempDir.appendingPathComponent("history").path)

        [tlib]
        translation-cache-size = 134217728

        """.write(to: configURL, atomically: true, encoding: .utf8)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: renodePath)
        process.currentDirectoryURL = isCustom ? customRescURL?.deletingLastPathComponent() : tempDir
        process.arguments = ["--disable-gui", "-P", String(monitorPort), "-p", "--config", configURL.path, scriptURL.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        outputPipe = pipe
        installOutputReader(pipe)
        process.terminationHandler = { [weak self] terminated in
            DispatchQueue.main.async {
                guard let self, self.process === terminated else { return }
                self.onTerminated?(terminated.terminationStatus)
            }
        }

        try preLaunchEvidence?()
        try verifyStagedFirmware(appBinURL: appBinURL, bootloaderURL: bootloaderURL)
        for (key, url) in stagedAssetURLs {
            guard try Self.sha256(url) == stagedAssetSHA256[key] else { throw Self.error(7, "Staged \(key) changed immediately before launch.") }
        }
        try preLaunchEvidence?()
        try process.run()
        self.process = process
        return (monitorPort, uartPort)
    }

    private func verifyStagedFirmware(appBinURL: URL, bootloaderURL: URL?) throws {
        guard let stagedApp = stagedAssetURLs["app"],
              try Self.sha256(stagedApp) == stagedAssetSHA256["app"],
              try Self.sha256(appBinURL) == stagedAssetSHA256["app"] else {
            throw Self.error(8, "Selected or staged application changed before Renode launch.")
        }
        if let bootloaderURL {
            guard let stagedBootloader = stagedAssetURLs["mcuboot"],
                  try Self.sha256(stagedBootloader) == stagedAssetSHA256["mcuboot"],
                  try Self.sha256(bootloaderURL) == stagedAssetSHA256["mcuboot"] else {
                throw Self.error(9, "Selected or staged MCUboot changed before Renode launch.")
            }
        }
    }

    private func installOutputReader(_ pipe: Pipe) {
        let queue = DispatchQueue(label: "org.jepler.outputcoalesce", qos: .utility)
        var buffer = ""
        var timerScheduled = false
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { handle.readabilityHandler = nil; return }
            let text = String(decoding: data, as: UTF8.self)
            guard !text.isEmpty else { return }
            queue.async {
                buffer += text
                if buffer.count > 2048 {
                    let output = buffer
                    buffer = ""
                    DispatchQueue.main.async { self?.onOutputReceived?(output) }
                } else if !timerScheduled {
                    timerScheduled = true
                    queue.asyncAfter(deadline: .now() + .milliseconds(40)) {
                        let output = buffer
                        buffer = ""
                        timerScheduled = false
                        if !output.isEmpty { DispatchQueue.main.async { self?.onOutputReceived?(output) } }
                    }
                }
            }
        }
    }

    public func stop() {
        outputPipe.fileHandleForReading.readabilityHandler = nil
        if let process {
            self.process = nil
            if process.isRunning {
                process.terminate()
                DispatchQueue.global(qos: .utility).async {
                    let start = Date()
                    while process.isRunning && Date().timeIntervalSince(start) < 1 { usleep(30_000) }
                    if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                }
            }
        }
        if let workDir { DispatchQueue.global(qos: .utility).async { try? FileManager.default.removeItem(at: workDir) } }
        workDir = nil
        uartLogURL = nil
        stagedAssetSHA256.removeAll()
        stagedAssetURLs.removeAll()
        rescReferenceEvidence.removeAll()
        preLaunchEvidence = nil
        preLaunchRescSHA256 = nil
    }

    static func stageReviewedScript(at source: URL, to destination: URL, approvedSHA256: String) throws -> String {
        guard try Self.sha256(source) == approvedSHA256 else { throw Self.error(10, "Reviewed .resc changed after review.") }
        guard (try? String(contentsOf: source, encoding: .utf8)) != nil else { throw Self.error(11, "Reviewed .resc is not valid UTF-8 text.") }
        try FileManager.default.copyItem(at: source, to: destination)
        let digest = try Self.sha256(destination)
        guard digest == approvedSHA256 else { throw Self.error(12, "Staged .resc bytes differ from approved bytes.") }
        return digest
    }

    static func resourceReferences(in script: String) -> [String] {
        let chars = Array(script)
        var references: [String] = []
        var index = 0
        while index < chars.count {
            guard chars[index] == "@", index + 1 < chars.count else { index += 1; continue }
            var cursor = index + 1
            let quote = chars[cursor] == "\"" || chars[cursor] == "'" ? chars[cursor] : nil
            if quote != nil { cursor += 1 }
            let start = cursor
            while cursor < chars.count {
                if let quote { if chars[cursor] == quote { break } }
                else if chars[cursor].isWhitespace || "{}[](),;\"'".contains(chars[cursor]) { break }
                cursor += 1
            }
            if cursor > start {
                let value = String(chars[start..<cursor])
                if !references.contains(value) { references.append(value) }
                index = quote == nil ? max(index + 1, cursor) : min(cursor + 1, chars.count)
            } else { index = max(index + 1, cursor + 1) }
        }
        return references
    }

    static func referenceEvidence(in script: String, relativeTo directory: URL) throws -> [RenodeScriptReferenceEvidence] {
        var result: [RenodeScriptReferenceEvidence] = []
        var visited = Set<String>()
        func collect(_ source: String, directory: URL, isRoot: Bool = false) throws {
            for reference in resourceReferences(in: source) {
                guard !reference.contains("$") else { throw Self.error(13, "Dynamic .resc resource reference cannot be reviewed: \(reference)") }
                if reference.hasPrefix("platforms/") {
                    let item = RenodeScriptReferenceEvidence(reference: reference, resolvedPath: "Renode built-in resource (Renode installation)", sha256: nil, content: nil)
                    if !result.contains(item) { result.append(item) }
                    continue
                }
                if !isRoot, reference.hasPrefix("/") {
                    throw Self.error(14, "Nested script resource cannot be staged with an absolute reference: \(reference)")
                }
                let path = reference.hasPrefix("/") ? URL(fileURLWithPath: reference).standardizedFileURL : directory.appendingPathComponent(reference).standardizedFileURL
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                    throw Self.error(15, "Referenced resource cannot be resolved for review: \(reference)")
                }
                guard visited.insert(path.path).inserted else { continue }
                let digest = try sha256(path)
                let ext = path.pathExtension.lowercased()
                let textExtensions: Set<String> = ["resc", "cs", "repl", "txt", "json", "yaml", "yml", "xml", "conf", "overlay"]
                let content = textExtensions.contains(ext) ? try String(contentsOf: path, encoding: .utf8) : nil
                if !isRoot, ext == "resc", content == nil { throw Self.error(16, "Nested Renode script must be readable text: \(reference)") }
                result.append(RenodeScriptReferenceEvidence(reference: reference, resolvedPath: path.path, sha256: digest, content: content))
                if ext == "resc", let content { try collect(content, directory: path.deletingLastPathComponent()) }
            }
        }
        try collect(script, directory: directory, isRoot: true)
        return result
    }

    private func stage(_ source: URL, in directory: URL, fallbackName: String, key: String) throws -> URL {
        let ext = source.pathExtension.isEmpty ? "bin" : source.pathExtension
        let base = source.deletingPathExtension().lastPathComponent.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "$", with: "_").replacingOccurrences(of: "@", with: "_")
        let destination = directory.appendingPathComponent("\(base.isEmpty ? fallbackName : base).\(ext)")
        try FileManager.default.copyItem(at: source, to: destination)
        stagedAssetSHA256[key] = try Self.sha256(destination)
        stagedAssetURLs[key] = destination
        return destination
    }

    private static func sha256(_ url: URL) throws -> String {
        SHA256.hash(data: try Data(contentsOf: url, options: .mappedIfSafe)).map { String(format: "%02x", $0) }.joined()
    }

    private static func error(_ code: Int, _ message: String) -> NSError {
        NSError(domain: "RenodeProcessManager", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func findFreePorts(count: Int) -> [UInt16] {
        var sockets: [Int32] = []
        var ports: [UInt16] = []
        for _ in 0..<count {
            let fd = socket(AF_INET, SOCK_STREAM, 0)
            guard fd >= 0 else { continue }
            var address = sockaddr_in()
            address.sin_family = sa_family_t(AF_INET)
            address.sin_addr.s_addr = inet_addr("127.0.0.1")
            address.sin_port = 0
            var copy = address
            let bound = withUnsafePointer(to: &copy) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) } }
            if bound == 0 {
                var length = socklen_t(MemoryLayout<sockaddr_in>.size)
                getsockname(fd, withUnsafeMutablePointer(to: &copy) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 } }, &length)
                ports.append(UInt16(bigEndian: copy.sin_port))
                sockets.append(fd)
            } else { close(fd) }
        }
        for fd in sockets { close(fd) }
        return ports
    }

    deinit { stop() }
}
