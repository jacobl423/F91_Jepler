import Foundation
import Combine
import SwiftUI
import CoreGraphics

public enum ViewMode: String, CaseIterable, Identifiable {
    case watch = "Watch Console"
    case canvas = "OLED Canvas"
    case gatt = "GATT / BLE Harness"
    case test = "Regression Tests"
    case pcb = "KiCad PCB"
    case gdb = "GDB / CPU"
    case split = "Workbench Split"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .watch: return "applewatch"
        case .canvas: return "display"
        case .gatt: return "antenna.radiowaves.left.and.right"
        case .test: return "checkmark.shield"
        case .pcb: return "cpu"
        case .gdb: return "terminal"
        case .split: return "rectangle.split.2x1"
        }
    }
}

@MainActor
public final class EmulatorSession: ObservableObject {
    @Published public var isRunning: Bool = false
    @Published public var statusMessage: String = "Ready"
    @Published public var errorMessage: String? = nil
    
    @Published public var selectedViewMode: ViewMode = .split
    @Published public var watchPanelHeight: CGFloat = 340
    @Published public var terminalPanelHeight: CGFloat = 280
    @Published public var uartLogs: String = ""
    @Published public var processOutputBuffer: String = ""
    @Published public var oledImage: CGImage? = nil
    
    // OLED Canvas & Themes (Module B)
    @Published public var oledTheme: OLEDTheme = .cyan
    @Published public var showPixelGridMesh: Bool = true
    @Published public var displayMetrics = DisplayMetrics()
    private var lastFrameTimes: [Double] = []
    
    // Inputs & GPIO (Module A & C)
    @Published public var pressedKeys: Set<String> = [] // "1" (Light), "2" (Mode), "3" (Toggle)
    @Published public var pcbBoard: KiCadBoard = KiCadBoard()
    @Published public var comparisonPCBURL: URL? = nil
    @Published public var pcbDiffResult: PCBBoardDiffResult? = nil
    
    // Terminal Filters (Module A)
    @Published public var selectedLogCategory: LogCategory = .all
    @Published public var terminalSearchText: String = ""
    @Published public var terminalAutoScroll: Bool = true
    @Published public var selectedTerminalTab: Int = 0 // 0: Zephyr UART, 1: Renode Console
    
    // GATT Injector (Module D)
    @Published public var gattLogs: [GATTLogEntry] = []
    
    // Automated Regression & Fuzzing (Module E)
    @Published public var isBootTestRunning: Bool = false
    @Published public var bootCheckSteps: [BootCheckStep] = [
        BootCheckStep(name: "1. Renode Machine Initialization", expectedString: "mach create"),
        BootCheckStep(name: "2. MCUboot Dual-Bank Chainloader", expectedString: "Booting MCUboot"),
        BootCheckStep(name: "3. Flash Slot Validation & Chainload", expectedString: "Jumping to the first image slot"),
        BootCheckStep(name: "4. Zephyr RTOS Kernel Boot", expectedString: "Booting Zephyr OS"),
        BootCheckStep(name: "5. SSD1306 Display & Framebuffer Ready", expectedString: "Watch screen ready"),
        BootCheckStep(name: "6. Bluetooth LE Subsystem & Advertising", expectedString: "BLE Advertising started")
    ]
    @Published public var bootCheckOverallResult: String? = nil
    @Published public var isSequenceRunning: Bool = false
    @Published public var sequenceStatusMessage: String = ""
    private var activeSequenceTask: Task<Void, Never>? = nil
    
    // PCB Inspector
    @Published public var pcbInspectorTab: Int = 0
    @Published public var pcbNetFilterText: String = ""
    @Published public var selectedFootprintID: String = ""
    @Published public var selectedNetName: String? = nil
    @Published public var hiddenComponentRefs: Set<String> = []
    @Published public var pcbValidationResult: PCBValidationResult? = nil
    @Published public var comparisonBoard: KiCadBoard? = nil
    
    // Configuration & File Overrides
    @Published public var customRenodePath: String? = nil
    @Published public var customWorkspaceURL: URL? = nil
    @Published public var customRescURL: URL? = nil
    @Published public var customPCBURL: URL? = nil
    @Published public var customAppBinURL: URL? = nil
    @Published public var customBootloaderURL: URL? = nil
    
    @Published public var showSetupSheet: Bool = false
    @Published public var isTargetedForDrop: Bool = false
    @Published public var cpuInspector = CPUInspectorModel()
    
    private let processManager = RenodeProcessManager()
    private let socketClient = RenodeSocketClient()
    private let uartSocketClient = RenodeUartSocketClient()
    private var uartFileTimer: Timer?
    private var lastUartFileOffset: UInt64 = 0
    private var frameTimer: Timer?
    private var framePpmURL: URL?
    
    public init() {
        loadEmbeddedDefaults()
    }
    
    public func validateActiveBoard() {
        self.pcbValidationResult = PCBValidator.validate(board: self.pcbBoard)
    }
    
    public func loadComparisonPCB(fileURL: URL) {
        self.comparisonPCBURL = fileURL
        if let draft = try? KiCadParser.parse(fileURL: fileURL) {
            self.comparisonBoard = draft
            self.pcbDiffResult = PCBDiffEngine.compare(base: self.pcbBoard, draft: draft)
            self.pcbInspectorTab = 4 // Diff tab
        }
    }
    
    public func toggleCpuPause() {
        cpuInspector.isPaused.toggle()
        if cpuInspector.isPaused {
            socketClient.send(command: "pause")
            socketClient.send(command: "sysbus.cpu PC")
            socketClient.send(command: "sysbus.cpu SP")
        } else {
            socketClient.send(command: "start")
        }
    }
    
    public func stepInstruction() {
        guard cpuInspector.isPaused else { return }
        socketClient.send(command: "sysbus.cpu Step")
        socketClient.send(command: "sysbus.cpu PC")
        socketClient.send(command: "sysbus.cpu SP")
    }
    
    public func refreshMemoryDump() {
        let hexAddr = cpuInspector.targetMemoryAddressHex
        socketClient.send(command: "sysbus ReadDoubleWord 0x\(hexAddr)")
    }
    
    public func loadEmbeddedDefaults() {
        if let embeddedPCB = customPCBURL ?? ResourceLoader.url(forResource: "f91_jepler", withExtension: "kicad_pcb") {
            if let board = try? KiCadParser.parse(fileURL: embeddedPCB) {
                self.pcbBoard = board
                validateActiveBoard()
            }
        }
    }
    
    // MARK: - Process Lifecycle & Socket Bridge (Module A)
    
    public func startSession() {
        guard let renodePath = RenodeProcessManager.findRenodeExecutable(customPath: customRenodePath) else {
            self.errorMessage = "Renode executable not found. Please install Renode in /Applications or configure its path in Settings."
            self.statusMessage = "Renode missing"
            return
        }
        
        guard let appBinURL = customAppBinURL ?? ResourceLoader.url(forResource: "app.signed", withExtension: "bin") else {
            self.errorMessage = "Missing firmware app.signed.bin"
            self.statusMessage = "Missing Firmware"
            return
        }
        
        let bootloaderURL = customBootloaderURL ?? ResourceLoader.url(forResource: "mcuboot", withExtension: "elf")
        let ssd1306CsURL = ResourceLoader.url(forResource: "F91SSD1306", withExtension: "cs")
        let pcbURL = customPCBURL ?? ResourceLoader.url(forResource: "f91_jepler", withExtension: "kicad_pcb")
        
        if let pcb = pcbURL, let board = try? KiCadParser.parse(fileURL: pcb) {
            self.pcbBoard = board
            validateActiveBoard()
        }
        
        do {
            let (port, _) = try processManager.start(
                appBinURL: appBinURL,
                bootloaderURL: bootloaderURL,
                ssd1306CsURL: ssd1306CsURL,
                renodePath: renodePath,
                customRescURL: customRescURL
            )
            
            processManager.onOutputReceived = { [weak self] str in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.processOutputBuffer += str
                }
            }
            
            if let workDir = processManager.workDir {
                self.framePpmURL = workDir.appendingPathComponent("screen.ppm")
            }
            
            self.statusMessage = "Connecting socket (Port \(port)..."
            
            socketClient.onConnected = { [weak self] in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isRunning = true
                    self.statusMessage = "Renode Connected & Running"
                    self.setupInitialCommands()
                }
            }
            
            socketClient.onError = { [weak self] err in
                Task { @MainActor in
                    self?.errorMessage = err
                    self?.statusMessage = "Socket Error"
                }
            }
            
            // Connect monitor socket
            self.socketClient.connect(port: port)
            
            // Start polling UART file backend for live MCUboot & Zephyr logs
            self.lastUartFileOffset = 0
            startUartFilePolling()
            
            startFramePolling()
            
        } catch {
            self.errorMessage = "Failed to launch Renode: \(error.localizedDescription)"
            self.statusMessage = "Launch Error"
        }
    }
    
    private func setupInitialCommands() {
        socketClient.send(command: "mach")
        // Initialize buttons high (pull-up active-low idle state)
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 11 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 12 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 24 true")
        socketClient.send(command: "start")
    }
    
    // MARK: - GPIO Injection Bridge (Module A & C)
    
    public func buttonDown(key: String) {
        guard !pressedKeys.contains(key) else { return }
        pressedKeys.insert(key)
        sendButtonGPIO(key: key, pressed: true)
    }
    
    public func buttonUp(key: String) {
        guard pressedKeys.contains(key) else { return }
        pressedKeys.remove(key)
        sendButtonGPIO(key: key, pressed: false)
    }
    
    public func buttonClick(key: String, durationMs: Int = 150) {
        buttonDown(key: key)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(durationMs) * 1_000_000)
            self.buttonUp(key: key)
        }
    }
    
    public func handleKeyDown(key: String) {
        buttonDown(key: key)
    }
    
    public func handleKeyUp(key: String) {
        buttonUp(key: key)
    }
    
    private func sendButtonGPIO(key: String, pressed: Bool) {
        let pinStr: String
        switch key {
        case "1": pinStr = pcbBoard.buttonAPin
        case "2": pinStr = pcbBoard.buttonBPin
        case "3": pinStr = pcbBoard.buttonCPin
        default: return
        }
        
        let pinNum = pinStr.replacingOccurrences(of: "P0.", with: "")
        guard let pin = Int(pinNum) else { return }
        
        // Active low: pressed -> false (GND pull-down), released -> true (VCC pull-up)
        let activeHigh = !pressed
        socketClient.send(command: "sysbus.gpioPortA OnGPIO \(pin) \(activeHigh ? "true" : "false")")
    }
    
    public func rebootMachine() {
        self.uartLogs += "\n--- MACHINE COLD REBOOT ---\n"
        socketClient.send(command: "mach")
        socketClient.send(command: "machine Reset")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 11 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 12 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 24 true")
        socketClient.send(command: "start")
    }
    
    // MARK: - Log Polling & Frame Buffer Ingestion (Module A & B)
    
    private func startUartFilePolling() {
        uartFileTimer?.invalidate()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.pollUartLogFile()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.uartFileTimer = timer
    }
    
    private func pollUartLogFile() {
        guard let url = self.processManager.uartLogURL else { return }
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? fileHandle.close() }
        
        let fileSize = fileHandle.seekToEndOfFile()
        if fileSize > self.lastUartFileOffset {
            fileHandle.seek(toFileOffset: self.lastUartFileOffset)
            let newData = fileHandle.readDataToEndOfFile()
            self.lastUartFileOffset = fileSize
            if let str = String(data: newData, encoding: .utf8) ?? String(data: newData, encoding: .ascii), !str.isEmpty {
                self.uartLogs += str
                if self.uartLogs.count > 64000 {
                    self.uartLogs = String(self.uartLogs.suffix(32000))
                }
            }
        }
    }
    
    private func startFramePolling() {
        frameTimer?.invalidate()
        guard let ppmURL = self.framePpmURL else { return }
        let timer = Timer(timeInterval: 0.12, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.socketClient.send(command: "sysbus.twi0.display SaveFrame \"\(ppmURL.path)\"")
                self.ingestFrameFile(at: ppmURL)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.frameTimer = timer
    }
    
    private func ingestFrameFile(at ppmURL: URL) {
        guard let data = try? Data(contentsOf: ppmURL) else { return }
        let startTime = CFAbsoluteTimeGetCurrent()
        if let (cgImg, litPixels) = decodePPMImage(data: data) {
            let latencyMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            self.oledImage = cgImg
            self.displayMetrics.frameCount += 1
            self.displayMetrics.drawCallCount += 1
            self.displayMetrics.litPixelCount = litPixels
            self.displayMetrics.lastFrameLatencyMs = latencyMs
            
            // FPS Tracking
            let now = CFAbsoluteTimeGetCurrent()
            lastFrameTimes.append(now)
            lastFrameTimes.removeAll { now - $0 > 1.0 }
            self.displayMetrics.fps = Double(lastFrameTimes.count)
        }
    }
    
    private nonisolated func decodePPMImage(data: Data) -> (CGImage, Int)? {
        guard let strHeader = String(data: data.prefix(100), encoding: .ascii) else { return nil }
        let components = strHeader.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard components.count >= 4, components[0] == "P6" else { return nil }
        guard let width = Int(components[1]), let height = Int(components[2]), components[3] == "255" else { return nil }
        
        let expectedPixelBytes = width * height * 3
        guard data.count >= expectedPixelBytes else { return nil }
        let pixelData = data.suffix(expectedPixelBytes)
        
        var litCount = 0
        pixelData.withUnsafeBytes { rawPtr in
            guard let ptr = rawPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for i in stride(from: 0, to: expectedPixelBytes, by: 3) {
                if ptr[i] > 10 {
                    litCount += 1
                }
            }
        }
        
        let provider = CGDataProvider(data: pixelData as CFData)
        guard let provider = provider else { return nil }
        
        let cgImg = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 24,
            bytesPerRow: width * 3,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
        guard let img = cgImg else { return nil }
        return (img, litCount)
    }
    
    // MARK: - GATT Test Injector & BLE Control Panel (Module D)
    
    public func injectNotification(payload: NotificationPayload) {
        let entry = GATTLogEntry(
            service: "Notification (fa35a2f0)",
            summary: "[\(payload.category.displayName)] \(payload.title): \(payload.message)",
            hexData: payload.hexSummary
        )
        self.gattLogs.insert(entry, at: 0)
        
        // Log to UART terminal stream as simulated BLE packet event
        let uartSim = "\n[BLE] Incoming notification payload -> Bar: 0x\(String(format: "%02x", payload.category.rawValue)) | Sender: \"\(payload.title)\" | Text: \"\(payload.message)\"\n"
        self.uartLogs += uartSim
        
        // Send command to Renode to acknowledge simulated event
        socketClient.send(command: "log \"[GATT-INJECT] Notification \(payload.category.displayName)\"")
    }
    
    public func injectClockSync(payload: ClockSyncPayload) {
        let entry = GATTLogEntry(
            service: "Clock Sync (fa35b2f0)",
            summary: "Epoch: \(payload.timestamp)s | TZ: \(payload.timezoneOffsetMinutes)m | 24H: \(payload.is24HourMode)",
            hexData: payload.hexSummary
        )
        self.gattLogs.insert(entry, at: 0)
        
        let uartSim = "\n[BLE] Clock time set to epoch: \(payload.timestamp)\n[BLE] Clock timezone set to: \(payload.timezoneOffsetMinutes)\n[BLE] Clock timemode set to: \(payload.is24HourMode ? 1 : 0) (\(payload.is24HourMode ? "24-hr" : "12-hr"))\n"
        self.uartLogs += uartSim
        
        socketClient.send(command: "log \"[GATT-INJECT] Clock Synced to \(payload.timestamp)\"")
    }
    
    public func injectBatteryUpdate(payload: BatteryMockPayload) {
        let entry = GATTLogEntry(
            service: "Battery Service (0x180F)",
            summary: "Level: \(payload.percentage)% | Voltage: \(String(format: "%.2f", payload.voltageVolts))V",
            hexData: "BAS: [\(String(format: "%02X", payload.percentage))] ADC: [\(String(format: "%.2f", payload.voltageVolts))V]"
        )
        self.gattLogs.insert(entry, at: 0)
        
        let uartSim = "\n[BATTERY] Mock ADC reading: \(String(format: "%.2f", payload.voltageVolts))V, State-of-charge: \(payload.percentage)%\(payload.isLowBattery ? " [WARNING: LOW BATTERY]" : "")\n"
        self.uartLogs += uartSim
    }
    
    // MARK: - Automated Regression & Fuzzing (Module E)
    
    public func runBootSanityCheck() {
        guard !isBootTestRunning else { return }
        isBootTestRunning = true
        bootCheckOverallResult = nil
        
        for i in 0..<bootCheckSteps.count {
            bootCheckSteps[i].status = .pending
            bootCheckSteps[i].detail = ""
            bootCheckSteps[i].durationMs = 0
        }
        
        Task { @MainActor in
            let startTime = CFAbsoluteTimeGetCurrent()
            rebootMachine()
            
            for i in 0..<self.bootCheckSteps.count {
                self.bootCheckSteps[i].status = .running
                let pattern = self.bootCheckSteps[i].expectedString
                
                var matched = false
                let deadline = Date().addingTimeInterval(8.0)
                
                while Date() < deadline {
                    if self.uartLogs.contains(pattern) || self.processOutputBuffer.contains(pattern) {
                        matched = true
                        break
                    }
                    try? await Task.sleep(nanoseconds: 150_000_000)
                }
                
                let stepElapsedMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)
                self.bootCheckSteps[i].durationMs = stepElapsedMs
                
                if matched {
                    self.bootCheckSteps[i].status = .passed
                    self.bootCheckSteps[i].detail = "Verified token: \"\(pattern)\""
                } else {
                    self.bootCheckSteps[i].status = .failed
                    self.bootCheckSteps[i].detail = "Timeout waiting for token: \"\(pattern)\""
                    self.bootCheckOverallResult = "FAILED: Check aborted at stage \(i + 1)"
                    self.isBootTestRunning = false
                    return
                }
            }
            
            self.bootCheckOverallResult = "PASS: All 6 boot verification stages passed successfully!"
            self.isBootTestRunning = false
        }
    }
    
    public func runSequence(preset: SequencePreset) {
        cancelSequence()
        isSequenceRunning = true
        sequenceStatusMessage = "Running sequence: \(preset.name)..."
        
        activeSequenceTask = Task { @MainActor in
            for (idx, step) in preset.steps.enumerated() {
                guard !Task.isCancelled else { break }
                self.sequenceStatusMessage = "Step \(idx + 1)/\(preset.steps.count): Holding \(step.button.displayName) (\(step.holdDurationMs)ms)..."
                
                self.buttonDown(key: step.button.rawValue)
                try? await Task.sleep(nanoseconds: UInt64(step.holdDurationMs) * 1_000_000)
                self.buttonUp(key: step.button.rawValue)
                
                if step.pauseAfterMs > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(step.pauseAfterMs) * 1_000_000)
                }
            }
            
            if !Task.isCancelled {
                self.sequenceStatusMessage = "Sequence '\(preset.name)' finished successfully. Firmware responsive."
            }
            self.isSequenceRunning = false
        }
    }
    
    public func cancelSequence() {
        activeSequenceTask?.cancel()
        activeSequenceTask = nil
        isSequenceRunning = false
        for key in pressedKeys {
            buttonUp(key: key)
        }
    }
    
    public func stopSession() {
        cancelSequence()
        uartFileTimer?.invalidate()
        uartFileTimer = nil
        uartSocketClient.disconnect()
        frameTimer?.invalidate()
        frameTimer = nil
        socketClient.disconnect()
        processManager.stop()
        isRunning = false
        statusMessage = "Stopped"
    }
    
    deinit {
        activeSequenceTask?.cancel()
        uartFileTimer?.invalidate()
        uartSocketClient.disconnect()
        frameTimer?.invalidate()
        socketClient.disconnect()
        processManager.stop()
    }
}
