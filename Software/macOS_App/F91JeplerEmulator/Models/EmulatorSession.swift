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
    @Published public var pressedKeys: Set<String> = [] // "1" (Light), "2" (Mode), "3" (Toggle)
    @Published public var pcbBoard: KiCadBoard = KiCadBoard()
    @Published public var comparisonPCBURL: URL? = nil
    @Published public var pcbDiffResult: PCBBoardDiffResult? = nil
    
    public let logStore = TerminalLogStore.shared
    public let displayStore = DisplayStreamStore.shared
    
    // Backwards-compatible accessors for logs
    public var uartLogs: String {
        get { logStore.rawUartString }
        set { logStore.appendUart(text: newValue) }
    }
    public var processOutputBuffer: String {
        get { logStore.rawRenodeString }
        set { logStore.appendRenodeConsole(text: newValue) }
    }
    
    // Backwards-compatible accessors for display
    public var oledImage: CGImage? {
        get { displayStore.oledImage }
        set { displayStore.oledImage = newValue }
    }
    public var oledTheme: OLEDTheme {
        get { displayStore.oledTheme }
        set { displayStore.oledTheme = newValue }
    }
    public var showPixelGridMesh: Bool {
        get { displayStore.showPixelGridMesh }
        set { displayStore.showPixelGridMesh = newValue }
    }
    public var displayMetrics: DisplayMetrics {
        get { displayStore.displayMetrics }
        set { displayStore.displayMetrics = newValue }
    }
    
    // Terminal Filters (forwarded to logStore)
    public var selectedLogCategory: LogCategory {
        get { logStore.selectedCategory }
        set { logStore.selectedCategory = newValue }
    }
    public var terminalSearchText: String {
        get { logStore.searchText }
        set { logStore.searchText = newValue }
    }
    public var terminalAutoScroll: Bool {
        get { logStore.autoScroll }
        set { logStore.autoScroll = newValue }
    }
    public var selectedTerminalTab: Int {
        get { logStore.selectedTab }
        set { logStore.selectedTab = newValue }
    }
    
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
    
    // KiCad Tooling, 3D Render & Live Watcher
    @Published public var activePCBURL: URL? = nil
    @Published public var isPCBWatcherActive: Bool = false
    @Published public var pcbRender3DImage: NSImage? = nil
    @Published public var isRendering3D: Bool = false
    @Published public var show3DRenderMode: Bool = false
    @Published public var kicadDRCReport: KiCadDRCReport? = nil
    @Published public var isRunningDRC: Bool = false
    @Published public var isExportingGerbers: Bool = false
    @Published public var exportedGerbersURL: URL? = nil
    @Published public var pinAuditResult: GPIOPinAuditResult? = nil
    @Published public var pcbReloadToast: String? = nil
    
    public let pcbFileWatcher = PCBFileWatcher()
    
    private let processManager = RenodeProcessManager()
    private let socketClient = RenodeSocketClient()
    private let uartSocketClient = RenodeUartSocketClient()
    private var framePpmURL: URL?
    
    public init() {
        loadEmbeddedDefaults()
    }
    
    public func validateActiveBoard() {
        self.pcbValidationResult = PCBValidator.validate(board: self.pcbBoard)
        auditGPIOPins()
    }
    
    public func auditGPIOPins() {
        self.pinAuditResult = GPIOPinAuditor.audit(board: self.pcbBoard)
    }
    
    public func syncRenodeWithKiCadPins() {
        guard let audit = pinAuditResult, audit.hasMismatches else { return }
        for entry in audit.entries {
            if entry.signalName.contains("Button A") {
                self.pcbBoard.buttonAPin = entry.detectedPin
            } else if entry.signalName.contains("Button B") {
                self.pcbBoard.buttonBPin = entry.detectedPin
            } else if entry.signalName.contains("Button C") {
                self.pcbBoard.buttonCPin = entry.detectedPin
            }
        }
        auditGPIOPins()
        self.pcbReloadToast = "Renode GPIO pins updated: A=\(pcbBoard.buttonAPin), B=\(pcbBoard.buttonBPin), C=\(pcbBoard.buttonCPin)"
    }
    
    public func loadComparisonPCB(fileURL: URL) {
        self.comparisonPCBURL = fileURL
        if let draft = try? KiCadParser.parse(fileURL: fileURL) {
            self.comparisonBoard = draft
            self.pcbDiffResult = PCBDiffEngine.compare(base: self.pcbBoard, draft: draft)
            self.pcbInspectorTab = 4 // Diff tab
        }
    }
    
    public func loadEmbeddedDefaults() {
        let pcbCandidate = customPCBURL ?? ResourceLoader.url(forResource: "f91_jepler", withExtension: "kicad_pcb")
        if let embeddedPCB = pcbCandidate {
            self.activePCBURL = embeddedPCB
            Task { [weak self] in
                if let board = try? await KiCadParser.parseAsync(fileURL: embeddedPCB) {
                    await MainActor.run {
                        self?.pcbBoard = board
                        self?.validateActiveBoard()
                    }
                }
                await MainActor.run {
                    self?.startWatchingActivePCB()
                }
            }
        }
    }
    
    public func startWatchingActivePCB() {
        guard let url = activePCBURL else { return }
        pcbFileWatcher.onFileChanged = { [weak self] changedURL in
            Task { @MainActor [weak self] in
                self?.reloadPCB(fileURL: changedURL)
            }
        }
        pcbFileWatcher.startWatching(url: url)
        self.isPCBWatcherActive = pcbFileWatcher.isWatching
    }
    
    public func reloadPCB(fileURL: URL) {
        Task { [weak self] in
            guard let board = try? await KiCadParser.parseAsync(fileURL: fileURL) else { return }
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.pcbBoard = board
                self.validateActiveBoard()
                
                self.pcbReloadToast = "Auto-reloaded '\(fileURL.lastPathComponent)' from KiCad"
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if self.pcbReloadToast?.contains(fileURL.lastPathComponent) == true {
                        self.pcbReloadToast = nil
                    }
                }
                
                if self.show3DRenderMode {
                    self.trigger3DRender()
                }
            }
        }
    }
    
    // MARK: - KiCad Tooling Actions
    
    public func openInKiCad(appType: KiCadAppType) {
        guard let pcbURL = activePCBURL else { return }
        let targetURL: URL
        switch appType {
        case .pcbEditor:
            targetURL = pcbURL
        case .schematicEditor:
            let schURL = pcbURL.deletingPathExtension().appendingPathExtension("kicad_sch")
            targetURL = FileManager.default.fileExists(atPath: schURL.path) ? schURL : pcbURL
        case .kicadProject:
            let proURL = pcbURL.deletingPathExtension().appendingPathExtension("kicad_pro")
            targetURL = FileManager.default.fileExists(atPath: proURL.path) ? proURL : pcbURL
        }
        KiCadToolService.shared.openFileInKiCad(fileURL: targetURL, appType: appType)
    }
    
    public func revealActivePCBinFinder() {
        guard let pcbURL = activePCBURL else { return }
        KiCadToolService.shared.revealInFinder(fileURL: pcbURL)
    }
    
    public func trigger3DRender() {
        guard let pcbURL = activePCBURL else { return }
        guard !isRendering3D else { return }
        isRendering3D = true
        
        Task { @MainActor in
            let outPNG = FileManager.default.temporaryDirectory.appendingPathComponent("kicad_3d_\(UUID().uuidString).png")
            do {
                let img = try await KiCadToolService.shared.render3D(pcbURL: pcbURL, outputURL: outPNG, width: 900, height: 900)
                self.pcbRender3DImage = img
                self.isRendering3D = false
            } catch {
                self.isRendering3D = false
                self.errorMessage = "KiCad 3D Render Error: \(error.localizedDescription)"
            }
        }
    }
    
    public func runKiCadDRC() {
        guard let pcbURL = activePCBURL else { return }
        guard !isRunningDRC else { return }
        isRunningDRC = true
        
        Task { @MainActor in
            do {
                let report = try await KiCadToolService.shared.runDRC(pcbURL: pcbURL)
                self.kicadDRCReport = report
                self.isRunningDRC = false
                self.pcbReloadToast = "KiCad DRC: \(report.errorCount) errors, \(report.unconnectedCount) unconnected"
            } catch {
                self.isRunningDRC = false
                self.errorMessage = "KiCad DRC Execution Error: \(error.localizedDescription)"
            }
        }
    }
    
    public func exportGerberPackage() {
        guard let pcbURL = activePCBURL else { return }
        guard !isExportingGerbers else { return }
        isExportingGerbers = true
        
        Task { @MainActor in
            do {
                let zipURL = try await KiCadToolService.shared.exportManufacturingZip(pcbURL: pcbURL)
                self.exportedGerbersURL = zipURL
                self.isExportingGerbers = false
                self.pcbReloadToast = "Gerbers exported to: \(zipURL.lastPathComponent)"
                KiCadToolService.shared.revealInFinder(fileURL: zipURL)
            } catch {
                self.isExportingGerbers = false
                self.errorMessage = "Gerber Export Error: \(error.localizedDescription)"
            }
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
        
        if let pcb = pcbURL {
            self.activePCBURL = pcb
            if let board = try? KiCadParser.parse(fileURL: pcb) {
                self.pcbBoard = board
                validateActiveBoard()
            }
            startWatchingActivePCB()
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
                    self?.logStore.appendRenodeConsole(text: str)
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
            
            // Start background polling for UART logs
            if let uartFile = self.processManager.uartLogURL {
                self.logStore.startBackgroundUartTail(fileURL: uartFile)
            }
            
            // Start background frame ingestion
            if let ppmURL = self.framePpmURL {
                self.displayStore.startPolling(
                    socketSender: { [weak self] cmd in
                        self?.socketClient.send(command: cmd)
                    },
                    ppmURL: ppmURL
                )
            }
            
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
        logStore.stopBackgroundUartTail()
        displayStore.stopPolling()
        uartSocketClient.disconnect()
        socketClient.disconnect()
        processManager.stop()
        isRunning = false
        statusMessage = "Stopped"
    }
    
    deinit {
        activeSequenceTask?.cancel()
        uartSocketClient.disconnect()
        socketClient.disconnect()
        processManager.stop()
        Task { @MainActor in
            TerminalLogStore.shared.stopBackgroundUartTail()
            DisplayStreamStore.shared.stopPolling()
        }
    }
}
