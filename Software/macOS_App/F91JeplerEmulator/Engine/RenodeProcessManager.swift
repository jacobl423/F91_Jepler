import Foundation
import AppKit

public final class RenodeProcessManager {
    public private(set) var process: Process?
    public private(set) var port: UInt16 = 0
    public private(set) var workDir: URL?
    public private(set) var uartLogURL: URL?
    public private(set) var outputPipe = Pipe()
    public var onOutputReceived: ((String) -> Void)?
    public var onTerminated: ((Int32) -> Void)?
    
    public init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }
    }
    
    public static func findRenodeExecutable(customPath: String? = nil) -> String? {
        if let custom = customPath, !custom.isEmpty, FileManager.default.fileExists(atPath: custom) {
            return custom
        }
        
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
    
    public static func cleanupStaleRenodeProcesses() {
        // Gracefully kill previous hanging renode processes
        let killProc = Process()
        killProc.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        killProc.arguments = ["-9", "-f", "renode.*f91"]
        try? killProc.run()
        killProc.waitUntilExit()
    }
    
    public func start(
        appBinURL: URL,
        bootloaderURL: URL?,
        ssd1306CsURL: URL?,
        renodePath: String,
        customRescURL: URL? = nil
    ) throws -> (port: UInt16, uartPort: UInt16) {
        stop()
        Self.cleanupStaleRenodeProcesses()
        
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("f91_renode_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        self.workDir = tempDir
        
        let localAppBin = tempDir.appendingPathComponent("app.signed.bin")
        try? FileManager.default.removeItem(at: localAppBin)
        try? FileManager.default.copyItem(at: appBinURL, to: localAppBin)
        
        var localBootloader: URL? = nil
        if let bl = bootloaderURL {
            let dest = tempDir.appendingPathComponent("mcuboot.elf")
            try? FileManager.default.removeItem(at: dest)
            if (try? FileManager.default.copyItem(at: bl, to: dest)) != nil || FileManager.default.fileExists(atPath: dest.path) {
                localBootloader = dest
            } else if FileManager.default.fileExists(atPath: bl.path) {
                localBootloader = bl
            }
        }
        
        var localSSD1306: URL? = nil
        if let cs = ssd1306CsURL {
            let dest = tempDir.appendingPathComponent("F91SSD1306.cs")
            try? FileManager.default.removeItem(at: dest)
            if (try? FileManager.default.copyItem(at: cs, to: dest)) != nil || FileManager.default.fileExists(atPath: dest.path) {
                localSSD1306 = dest
            } else if FileManager.default.fileExists(atPath: cs.path) {
                localSSD1306 = cs
            }
        }
        
        let ports = findFreePorts(count: 2)
        let freePort = ports.count > 0 ? ports[0] : 1239
        let uartPort = ports.count > 1 ? ports[1] : 1240
        self.port = freePort
        
        let uartLogFile = tempDir.appendingPathComponent("uart.log")
        self.uartLogURL = uartLogFile
        
        let rescFile = tempDir.appendingPathComponent("session.resc")
        if let customResc = customRescURL, FileManager.default.fileExists(atPath: customResc.path) {
            let customContent = try String(contentsOf: customResc, encoding: .utf8)
            var patched = customContent
            // Replace relative paths with absolute/copied paths if needed
            patched = "$mcuboot_bin?=@\(localBootloader?.path ?? "")\n$app_bin?=@\(localAppBin.path)\n" + patched
            patched += "\nsysbus.uart0 CreateFileBackend @\(uartLogFile.path) true\n"
            try patched.write(to: rescFile, atomically: true, encoding: .utf8)
        } else {
            let rescContent = RenodeScriptGenerator.generateResc(
                appBinPath: localAppBin.path,
                bootloaderPath: localBootloader?.path,
                uartPort: uartPort,
                uartLogPath: uartLogFile.path,
                ssd1306CsPath: localSSD1306?.path
            )
            try rescContent.write(to: rescFile, atomically: true, encoding: .utf8)
        }
        
        let configContent = """
        [general]
        history-path = \(tempDir.appendingPathComponent("history").path)

        [tlib]
        translation-cache-size = 134217728

        """
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
        
        let coalesceQueue = DispatchQueue(label: "org.jepler.outputcoalesce", qos: .utility)
        var coalesceBuffer = ""
        var flushTimerScheduled = false
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            guard let str = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else { return }
            
            coalesceQueue.async {
                coalesceBuffer += str
                if coalesceBuffer.count > 2048 {
                    let toFlush = coalesceBuffer
                    coalesceBuffer = ""
                    DispatchQueue.main.async {
                        self?.onOutputReceived?(toFlush)
                    }
                } else if !flushTimerScheduled {
                    flushTimerScheduled = true
                    coalesceQueue.asyncAfter(deadline: .now() + .milliseconds(40)) {
                        let toFlush = coalesceBuffer
                        coalesceBuffer = ""
                        flushTimerScheduled = false
                        if !toFlush.isEmpty {
                            DispatchQueue.main.async {
                                self?.onOutputReceived?(toFlush)
                            }
                        }
                    }
                }
            }
        }
        
        proc.terminationHandler = { [weak self] p in
            DispatchQueue.main.async {
                self?.onTerminated?(p.terminationStatus)
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
            
            // Wait up to 1.0 second, then force kill
            let startTime = Date()
            while proc.isRunning && Date().timeIntervalSince(startTime) < 1.0 {
                usleep(50000)
            }
            if proc.isRunning {
                kill(proc.processIdentifier, SIGKILL)
            }
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
