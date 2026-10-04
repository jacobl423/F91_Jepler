import Foundation

public final class RenodeProcessManager {
    public private(set) var process: Process?
    public private(set) var port: UInt16 = 0
    public private(set) var workDir: URL?
    public private(set) var uartLogURL: URL?
    public private(set) var outputPipe = Pipe()
    public var onOutputReceived: ((String) -> Void)?
    
    public init() {}
    
    public static func findRenodeExecutable() -> String? {
        let defaultPath = "/Applications/Renode.app/Contents/MacOS/renode"
        if FileManager.default.fileExists(atPath: defaultPath) {
            return defaultPath
        }
        
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for dir in pathEnv.components(separatedBy: ":") {
            let candidate = (dir as NSString).appendingPathComponent("renode")
            if FileManager.default.fileExists(atPath: candidate) {
                return candidate
            }
        }
        
        return nil
    }
    
    public func start(
        appBinURL: URL,
        bootloaderURL: URL?,
        ssd1306CsURL: URL?,
        renodePath: String
    ) throws -> (port: UInt16, uartPort: UInt16) {
        stop()
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("f91_renode_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        self.workDir = tempDir
        
        let localAppBin = tempDir.appendingPathComponent("app.signed.bin")
        try? FileManager.default.copyItem(at: appBinURL, to: localAppBin)
        
        var localBootloader: URL? = nil
        if let bl = bootloaderURL {
            let dest = tempDir.appendingPathComponent("mcuboot.elf")
            if (try? FileManager.default.copyItem(at: bl, to: dest)) != nil {
                localBootloader = dest
            }
        }
        
        var localSSD1306: URL? = nil
        if let cs = ssd1306CsURL {
            let dest = tempDir.appendingPathComponent("F91SSD1306.cs")
            if (try? FileManager.default.copyItem(at: cs, to: dest)) != nil {
                localSSD1306 = dest
            }
        }
        
        let ports = findFreePorts(count: 2)
        let freePort = ports.count > 0 ? ports[0] : 1239
        let uartPort = ports.count > 1 ? ports[1] : 1240
        self.port = freePort
        
        let rescContent = RenodeScriptGenerator.generateResc(
            appBinPath: localAppBin.path,
            bootloaderPath: localBootloader?.path,
            uartPort: uartPort,
            ssd1306CsPath: localSSD1306?.path
        )
        
        let rescFile = tempDir.appendingPathComponent("session.resc")
        try rescContent.write(to: rescFile, atomically: true, encoding: .utf8)
        
        let configContent = "[general]\nhistory-path = \(tempDir.appendingPathComponent("history").path)\n"
        let configFile = tempDir.appendingPathComponent("renode.config")
        try configContent.write(to: configFile, atomically: true, encoding: .utf8)
        
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: renodePath)
        proc.currentDirectoryURL = tempDir
        proc.arguments = [
            "--disable-gui",
            "-P", String(freePort),
            "-p",
            "--config", configFile.path,
            rescFile.path
        ]
        
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        self.outputPipe = pipe
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                DispatchQueue.main.async {
                    self?.onOutputReceived?(str)
                }
            }
        }
        
        try proc.run()
        self.process = proc
        
        return (freePort, uartPort)
    }
    
    public func stop() {
        outputPipe.fileHandleForReading.readabilityHandler = nil
        if let proc = process, proc.isRunning {
            proc.terminate()
            proc.waitUntilExit()
        }
        process = nil
        
        if let dir = workDir {
            try? FileManager.default.removeItem(at: dir)
        }
        workDir = nil
        uartLogURL = nil
    }
    
    private func findFreePorts(count: Int) -> [UInt16] {
        var sockets: [Int32] = []
        var ports: [UInt16] = []
        
        for _ in 0..<count {
            let sock = socket(AF_INET, SOCK_STREAM, 0)
            if sock >= 0 {
                var addr = sockaddr_in()
                addr.sin_family = sa_family_t(AF_INET)
                addr.sin_addr.s_addr = inet_addr("127.0.0.1")
                addr.sin_port = 0
                
                var addrCopy = addr
                let bindRes = withUnsafePointer(to: &addrCopy) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                if bindRes == 0 {
                    var len = socklen_t(MemoryLayout<sockaddr_in>.size)
                    getsockname(sock, withUnsafeMutablePointer(to: &addrCopy) {
                        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 }
                    }, &len)
                    ports.append(UInt16(bigEndian: addrCopy.sin_port))
                    sockets.append(sock)
                } else {
                    close(sock)
                }
            }
        }
        for sock in sockets {
            close(sock)
        }
        return ports
    }
    
    deinit {
        stop()
    }
}
