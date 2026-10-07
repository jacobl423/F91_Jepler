import Foundation
import Combine
import SwiftUI
import CoreGraphics
import AppKit

public enum ViewMode: String, CaseIterable, Identifiable {
    case split = "Workbench Split"
    case watch = "Watch Console"
    case canvas = "OLED Canvas"
    case gatt = "Firmware Test Harness"
    case test = "Regression Tests"
    case pcb = "KiCad PCB"
    case gdb = "GDB / CPU"
    
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
    
    // MARK: - Project Sidebar & Layout State
    @Published public var isSidebarVisible: Bool = true {
        didSet {
            userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.isSidebarVisible)
        }
    }
    
    @Published public var isTerminalVisible: Bool = true {
        didSet {
            userDefaults.set(isTerminalVisible, forKey: SessionPersistenceKeys.isTerminalVisible)
        }
    }

    @Published public var sidebarWidth: CGFloat = 280 {
        didSet {
            userDefaults.set(Double(sidebarWidth), forKey: SessionPersistenceKeys.sidebarWidth)
        }
    }
    
    @Published public var selectedViewMode: ViewMode = .split {
        didSet {
            userDefaults.set(selectedViewMode.rawValue, forKey: SessionPersistenceKeys.selectedViewMode)
        }
    }
    
    @Published public var watchPanelHeight: CGFloat = 340
    @Published public var terminalPanelHeight: CGFloat = 280
    @Published public var pressedKeys: Set<String> = [] // "1" (Light), "2" (Mode), "3" (Toggle)
    @Published public var pcbBoard: KiCadBoard = KiCadBoard()
    @Published public var comparisonPCBURL: URL? = nil
    @Published public var pcbDiffResult: PCBBoardDiffResult? = nil
    
    // MARK: - Asset Management
    @Published public var assets: [SessionAssetKind: SessionAsset] = [:]
    
    // Configuration & File Overrides (Stored settings)
    @Published public var customRenodePath: String? = nil
    @Published public var customWorkspaceURL: URL? = nil
    
    // Backwards-Compatible Asset Computed Properties
    public var customPCBURL: URL? {
        get {
            guard let asset = assets[.pcb], asset.isCustom else { return nil }
            return asset.fileURL
        }
        set {
            if let newURL = newValue {
                updateAsset(kind: .pcb, url: newURL)
            } else {
                revertAssetToDefault(kind: .pcb)
            }
        }
    }
    
    public var customAppBinURL: URL? {
        get {
            guard let asset = assets[.appFirmware], asset.isCustom else { return nil }
            return asset.fileURL
        }
        set {
            if let newURL = newValue {
                updateAsset(kind: .appFirmware, url: newURL)
            } else {
                revertAssetToDefault(kind: .appFirmware)
            }
        }
    }
    
    public var customBootloaderURL: URL? {
        get {
            guard let asset = assets[.bootloader], asset.isCustom else { return nil }
            return asset.fileURL
        }
        set {
            if let newURL = newValue {
                updateAsset(kind: .bootloader, url: newURL)
            } else {
                revertAssetToDefault(kind: .bootloader)
            }
        }
    }
    
    public var customRescURL: URL? {
        get {
            guard let asset = assets[.rescScript], asset.isCustom else { return nil }
            return asset.fileURL
        }
        set {
            if let newURL = newValue {
                updateAsset(kind: .rescScript, url: newURL)
            } else {
                revertAssetToDefault(kind: .rescScript)
            }
        }
    }
    
    private let userDefaults: UserDefaults
    
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
    
    // MARK: - Initialization & State Persistence
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // 1. Restore Sidebar Visibility
        if userDefaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) != nil {
            self.isSidebarVisible = userDefaults.bool(forKey: SessionPersistenceKeys.isSidebarVisible)
        } else {
            self.isSidebarVisible = true
        }
        
        if userDefaults.object(forKey: SessionPersistenceKeys.isTerminalVisible) != nil {
            self.isTerminalVisible = userDefaults.bool(forKey: SessionPersistenceKeys.isTerminalVisible)
        }

        // 2. Restore Sidebar Width
        let savedWidth = CGFloat(userDefaults.double(forKey: SessionPersistenceKeys.sidebarWidth))
        if savedWidth >= 230 && savedWidth <= 380 {
            self.sidebarWidth = savedWidth
        } else {
            self.sidebarWidth = 280
        }
        
        // 3. Restore Selected View Mode
        if let savedModeRaw = userDefaults.string(forKey: SessionPersistenceKeys.selectedViewMode) {
            if let mode = ViewMode(rawValue: savedModeRaw) {
                self.selectedViewMode = mode
            } else if let mode = ViewMode.allCases.first(where: { "\($0)".lowercased() == savedModeRaw.lowercased() }) {
                self.selectedViewMode = mode
            }
        }
        
        // 4. Restore and Validate Assets
        loadInitialAssets()
    }
    
    private func loadInitialAssets() {
        for kind in SessionAssetKind.allCases {
            if let savedPath = userDefaults.string(forKey: kind.userDefaultsKey) {
                if FileManager.default.fileExists(atPath: savedPath) {
                    let customURL = URL(fileURLWithPath: savedPath)
                    let asset = SessionAsset(
                        kind: kind,
                        url: customURL,
                        state: .customLoaded,
                        metadata: nil,
                        isCustom: true
                    )
                    self.assets[kind] = asset
                    inspectStartupAssetAsync(kind: kind, url: customURL)
                } else {
                    // Stale path on disk: clean up and fall back to embedded default
                    userDefaults.removeObject(forKey: kind.userDefaultsKey)
                    loadDefaultAsset(kind: kind)
                }
            } else {
                loadDefaultAsset(kind: kind)
            }
        }
        
        // Initialize PCB board and watcher if available
        if let pcbAsset = assets[.pcb], let pcbURL = pcbAsset.fileURL {
            self.activePCBURL = pcbURL
            Task { [weak self] in
                if let board = try? await KiCadParser.parseAsync(fileURL: pcbURL) {
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
    
    private func loadDefaultAsset(kind: SessionAssetKind) {
        let (resourceName, resourceExt) = kind.defaultResourceName
        let defaultURL = ResourceLoader.url(forResource: resourceName, withExtension: resourceExt)
        let state: AssetLoadState = defaultURL != nil ? .defaultEmbedded : .missing("Default resource not found")
        let asset = SessionAsset(
            kind: kind,
            url: defaultURL,
            state: state,
            metadata: nil,
            isCustom: false
        )
        self.assets[kind] = asset
        if let url = defaultURL {
            inspectAssetAsync(kind: kind, url: url, isCustom: false)
        }
    }
    
    private func inspectStartupAssetAsync(kind: SessionAssetKind, url: URL) {
        Task { [weak self] in
            // Safe inspection: if file is corrupted, returns nil without throwing
            if let metadata = await AssetInspector.inspectSafe(url: url, kind: kind, isCustom: true) {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if var existing = self.assets[kind] {
                        existing.metadata = metadata
                        existing.state = .loaded(metadata)
                        self.assets[kind] = existing
                    }
                }
            } else {
                // Startup inspection failed: remove corrupted key from UserDefaults and revert to default asset
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.userDefaults.removeObject(forKey: kind.userDefaultsKey)
                    self.loadDefaultAsset(kind: kind)
                    if kind == .pcb {
                        if let defaultURL = self.assets[.pcb]?.fileURL {
                            self.activePCBURL = defaultURL
                            self.reloadPCB(fileURL: defaultURL)
                            self.startWatchingActivePCB()
                        }
                    }
                    self.errorMessage = "Failed to load custom \(kind.title); restored default"
                }
            }
        }
    }
    
    private func inspectAssetAsync(kind: SessionAssetKind, url: URL, isCustom: Bool) {
        Task { [weak self] in
            do {
                let metadata = try await AssetInspector.inspect(url: url, kind: kind, isCustom: isCustom)
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if var existing = self.assets[kind] {
                        existing.metadata = metadata
                        existing.state = .loaded(metadata)
                        self.assets[kind] = existing
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if isCustom {
                        self.userDefaults.removeObject(forKey: kind.userDefaultsKey)
                    }
                    if var existing = self.assets[kind] {
                        existing.state = .failed(error: error.localizedDescription)
                        self.assets[kind] = existing
                    }
                }
            }
        }
    }
    
    // MARK: - Asset Quick Actions
    
    public func updateAsset(kind: SessionAssetKind, url: URL) {
        userDefaults.set(url.path, forKey: kind.userDefaultsKey)
        
        let asset = SessionAsset(
            kind: kind,
            url: url,
            state: .customLoaded,
            metadata: nil,
            isCustom: true
        )
        self.assets[kind] = asset
        inspectAssetAsync(kind: kind, url: url, isCustom: true)
        
        switch kind {
        case .pcb:
            self.activePCBURL = url
            self.reloadPCB(fileURL: url)
            self.startWatchingActivePCB()
            self.pcbReloadToast = "Loaded custom PCB: \(url.lastPathComponent)"
        case .appFirmware, .bootloader, .rescScript:
            if isRunning {
                self.pcbReloadToast = "Updated \(kind.title); restarting emulation..."
                stopSession()
                startSession()
            } else {
                self.statusMessage = "Loaded \(url.lastPathComponent)"
            }
        }
    }
    
    public func revertAssetToDefault(kind: SessionAssetKind) {
        userDefaults.removeObject(forKey: kind.userDefaultsKey)
        loadDefaultAsset(kind: kind)
        
        guard let defaultURL = assets[kind]?.fileURL else { return }
        
        switch kind {
        case .pcb:
            self.activePCBURL = defaultURL
            self.reloadPCB(fileURL: defaultURL)
            self.startWatchingActivePCB()
            self.pcbReloadToast = "Reverted PCB to default"
        case .appFirmware, .bootloader, .rescScript:
            if isRunning {
                self.pcbReloadToast = "Reverted \(kind.title); restarting emulation..."
                stopSession()
                startSession()
            } else {
                self.statusMessage = "Reverted \(kind.title) to default"
            }
        }
    }
    
    public func reloadAsset(kind: SessionAssetKind) {
        guard let asset = assets[kind], let url = asset.fileURL else { return }
        guard FileManager.default.fileExists(atPath: url.path) else {
            self.errorMessage = "Asset file missing on disk: \(url.lastPathComponent)"
            var modified = asset
            modified.state = .missing("File missing on disk")
            self.assets[kind] = modified
            return
        }
        
        inspectAssetAsync(kind: kind, url: url, isCustom: asset.isCustom)
        
        switch kind {
        case .pcb:
            self.reloadPCB(fileURL: url)
            self.pcbReloadToast = "Reloaded \(url.lastPathComponent)"
        case .appFirmware, .bootloader, .rescScript:
            if isRunning {
                self.pcbReloadToast = "Reloaded \(url.lastPathComponent); restarting emulation..."
                stopSession()
                startSession()
            } else {
                self.pcbReloadToast = "Reloaded metadata for \(url.lastPathComponent)"
            }
        }
    }
    
    public func revealAssetInFinder(kind: SessionAssetKind) {
        guard let asset = assets[kind], let url = asset.fileURL else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            self.errorMessage = "Cannot reveal in Finder: file does not exist at \(url.path)"
        }
    }
    
    public func revealActivePCBinFinder() {
        revealAssetInFinder(kind: .pcb)
    }
    
    public func loadEmbeddedDefaults() {
        for kind in SessionAssetKind.allCases {
            revertAssetToDefault(kind: kind)
        }
    }
    
    // MARK: - KiCad Board Management & Live Watcher
    
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
    
    public func sendRenodeCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Log formatted user command into monitor view
        logStore.appendRenodeConsole(text: "\u{1B}[1;36m(monitor) > \(trimmed)\u{1B}[0m\n")
        socketClient.send(command: trimmed)
    }
    
    // MARK: - Process Lifecycle & Socket Bridge (Module A)
    
    public func startSession() {
        guard let renodePath = RenodeProcessManager.findRenodeExecutable(customPath: customRenodePath) else {
            self.errorMessage = "Renode executable not found. Please install Renode in /Applications or configure its path in Settings."
            self.statusMessage = "Renode missing"
            return
        }
        
        guard let appBinURL = assets[.appFirmware]?.fileURL ?? customAppBinURL ?? ResourceLoader.url(forResource: "app.signed", withExtension: "bin") else {
            self.errorMessage = "Missing firmware app.signed.bin"
            self.statusMessage = "Missing Firmware"
            return
        }
        
        let bootloaderURL = assets[.bootloader]?.fileURL ?? customBootloaderURL ?? ResourceLoader.url(forResource: "mcuboot", withExtension: "elf")
        let ssd1306CsURL = ResourceLoader.url(forResource: "F91SSD1306", withExtension: "cs")
        let pcbURL = assets[.pcb]?.fileURL ?? customPCBURL ?? ResourceLoader.url(forResource: "f91_jepler", withExtension: "kicad_pcb")
        let rescURL = (assets[.rescScript]?.isCustom == true ? assets[.rescScript]?.fileURL : nil) ?? customRescURL
        
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
                customRescURL: rescURL
            )
            
            processManager.onOutputReceived = { [weak self] str in
                Task { @MainActor [weak self] in
                    self?.logStore.appendRenodeConsole(text: str)
                }
            }
            
            processManager.onTerminated = { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isRunning else { return }
                    self.stopSession()
                    self.statusMessage = "Renode Exited (Code \(status))"
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
            
            socketClient.onOutputReceived = { [weak self] str in
                Task { @MainActor [weak self] in
                    self?.logStore.appendRenodeConsole(text: str)
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
        self.logStore.appendRenodeConsole(text: "[HOST] Machine cold reboot requested\n")
        socketClient.send(command: "mach")
        socketClient.send(command: "machine Reset")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 11 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 12 true")
        socketClient.send(command: "sysbus.gpioPortA OnGPIO 24 true")
        socketClient.send(command: "start")
    }
    
    // MARK: - GATT Test Injector & BLE Control Panel (Module D)
    
    private var nextHarnessID: UInt32 = 0
    private var injectionBusy = false
    @Published public var lastTestArtifactURL: URL?

    private func uartOffset() throws -> UInt64 {
        guard let url = processManager.uartLogURL else { throw HarnessError.failure("UART file unavailable") }
        return try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
    }

    private func uartEvidence(since offset: UInt64) throws -> String {
        guard let url = processManager.uartLogURL else { throw HarnessError.failure("UART file unavailable") }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        try file.seek(toOffset: offset)
        return String(decoding: try file.readToEnd() ?? Data(), as: UTF8.self)
    }

    private func harnessRequest(_ field: String, bytes: [UInt8] = [], simulatedMS: Int? = nil) async throws -> String {
        guard isRunning, socketClient.isConnected else { throw HarnessError.failure("Start Renode before using the harness") }
        try Task.checkCancellation()
        nextHarnessID &+= 1
        let id = nextHarnessID
        let offset = try uartOffset()
        let hex = bytes.isEmpty ? "-" : bytes.map { String(format: "%02x", $0) }.joined()
        // Only generated numeric IDs, fixed field names and hex bytes enter the monitor command.
        socketClient.send(command: "sysbus.uart0 WriteLine \"F91TEST \(id) \(field) \(hex)\"")
        if let milliseconds = simulatedMS {
            socketClient.send(command: String(format: "emulation RunFor \"%.3f\"", Double(milliseconds) / 1000))
        }
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            try Task.checkCancellation()
            guard isRunning else { throw HarnessError.failure("Session stopped") }
            let evidence = try uartEvidence(since: offset)
            if let result = FirmwareHarnessProtocol.acknowledgment(in: evidence, id: id, field: field) {
                if result == "OK" { return evidence }
                throw HarnessError.failure("Firmware rejected \(field): \(result)")
            }
            try await Task.sleep(nanoseconds: 40_000_000)
        }
        throw HarnessError.failure("No firmware ACK for \(field). Rebuild with CONFIG_F91_TEST_HARNESS=y; the loaded image may not support the bridge.")
    }

    private func inject(service: String, summary: String, hex: String, fields: [(String, [UInt8])]) {
        guard !injectionBusy, !isSequenceRunning, !isBootTestRunning else {
            gattLogs.insert(GATTLogEntry(service: service, summary: "Harness busy", hexData: hex, status: "Not sent"), at: 0)
            return
        }
        injectionBusy = true
        Task { @MainActor in
            defer { injectionBusy = false }
            var completed = 0
            do {
                for (field, bytes) in fields {
                    _ = try await harnessRequest(field, bytes: bytes)
                    completed += 1
                }
                gattLogs.insert(GATTLogEntry(service: service, summary: summary, hexData: hex, status: "Firmware ACK"), at: 0)
                logStore.appendRenodeConsole(text: "[HOST] UART harness: firmware acknowledged \(service)\n")
            } catch {
                let detail = "\(error.localizedDescription) (\(completed)/\(fields.count) fields applied; no rollback)"
                gattLogs.insert(GATTLogEntry(service: service, summary: detail, hexData: hex, status: "Failed"), at: 0)
                logStore.appendRenodeConsole(text: "[HOST] UART harness failed: \(detail)\n")
            }
        }
    }

    public func injectNotification(payload: NotificationPayload) {
        inject(service: "Notification handlers via UART", summary: "\(payload.title): \(payload.message)", hex: payload.hexSummary,
               fields: [("bar", payload.serializeNotificationBar()), ("call", payload.serializeIncomingCall()), ("text", payload.serializeIncomingText())])
    }

    public func injectClockSync(payload: ClockSyncPayload) {
        inject(service: "Clock handlers via UART", summary: "Epoch \(payload.timestamp), UTC offset \(payload.timezoneOffsetMinutes) minutes", hex: payload.hexSummary,
               fields: [("time", payload.serializeTime()), ("timezone", payload.serializeTimezone()), ("timemode", payload.serializeTimeMode()), ("dst", payload.serializeDST())])
    }

    public func injectBatteryUpdate(payload: BatteryMockPayload) {
        guard payload.voltageVolts.isFinite, (2.0...5.0).contains(payload.voltageVolts) else { return }
        let mv = UInt16((payload.voltageVolts * 1000).rounded())
        inject(service: "Battery test state via UART", summary: "\(mv) mV (test state only; no ADC or BAS validation)", hex: String(format: "%04X", mv),
               fields: [("battery", [UInt8(mv & 255), UInt8(mv >> 8)])])
    }

    private func saveFailure(_ detail: String, uart: String) {
        do {
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("F91Jepler/TestResults/\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try (detail + "\n\nUART evidence:\n" + uart + "\n\nMonitor:\n" + processOutputBuffer)
                .write(to: directory.appendingPathComponent("failure.txt"), atomically: true, encoding: .utf8)
            if let framePpmURL, FileManager.default.fileExists(atPath: framePpmURL.path) {
                try FileManager.default.copyItem(at: framePpmURL, to: directory.appendingPathComponent("screen.ppm"))
            }
            lastTestArtifactURL = directory
        } catch {
            logStore.appendRenodeConsole(text: "[HOST] Could not save test artifacts: \(error.localizedDescription)\n")
        }
    }

    public func runBootSanityCheck() {
        guard isRunning, !isBootTestRunning, !isSequenceRunning, !injectionBusy else { return }
        isBootTestRunning = true
        bootCheckOverallResult = nil
        lastTestArtifactURL = nil
        for i in bootCheckSteps.indices {
            bootCheckSteps[i].status = .pending
            bootCheckSteps[i].detail = ""
            bootCheckSteps[i].durationMs = 0
        }
        Task { @MainActor in
            defer { isBootTestRunning = false }
            var offset: UInt64 = 0
            do {
                // Reading the file boundary excludes buffered UI lines and every prior boot.
                offset = try uartOffset()
                rebootMachine()
                for i in bootCheckSteps.indices {
                    bootCheckSteps[i].status = .running
                    let started = Date()
                    let pattern = bootCheckSteps[i].expectedString
                    var matched = false
                    while Date().timeIntervalSince(started) < 8, isRunning {
                        if try uartEvidence(since: offset).contains(pattern) { matched = true; break }
                        try await Task.sleep(nanoseconds: 100_000_000)
                    }
                    bootCheckSteps[i].durationMs = Int(Date().timeIntervalSince(started) * 1000)
                    bootCheckSteps[i].status = matched ? .passed : .failed
                    bootCheckSteps[i].detail = matched ? "Fresh firmware output: \(pattern)" : "Missing fresh firmware output: \(pattern)"
                    if !matched { throw HarnessError.failure(bootCheckSteps[i].detail) }
                }
                bootCheckOverallResult = "PASS: Fresh boot milestones observed. OTA rollback and RF are not tested."
            } catch {
                bootCheckOverallResult = "FAILED: \(error.localizedDescription)"
                saveFailure(bootCheckOverallResult!, uart: (try? uartEvidence(since: offset)) ?? "Unavailable")
            }
        }
    }

    public func runSequence(preset: SequencePreset) {
        guard isRunning, !isBootTestRunning, !isSequenceRunning, !injectionBusy, !preset.steps.isEmpty else { return }
        isSequenceRunning = true
        lastTestArtifactURL = nil
        sequenceStatusMessage = "Running: \(preset.name)"
        activeSequenceTask = Task { @MainActor in
            let offset = (try? uartOffset()) ?? 0
            defer {
                for key in Array(pressedKeys) { buttonUp(key: key) }
                socketClient.send(command: "start")
                isSequenceRunning = false
                activeSequenceTask = nil
            }
            do {
                _ = try await harnessRequest("ping")
                socketClient.send(command: "pause")
                for (index, step) in preset.steps.enumerated() {
                    try Task.checkCancellation()
                    sequenceStatusMessage = "Step \(index + 1)/\(preset.steps.count): \(step.button.displayName)"
                    buttonDown(key: step.button.rawValue)
                    socketClient.send(command: String(format: "emulation RunFor \"%.3f\"", Double(max(1, step.holdDurationMs)) / 1000))
                    let held = try await harnessRequest("state", simulatedMS: 50)
                    let expected = 1 << ((Int(step.button.rawValue) ?? 1) - 1)
                    guard FirmwareHarnessProtocol.buttonMask(in: held) == expected else {
                        throw HarnessError.failure("Step \(index + 1): expected held button mask \(expected); firmware reported a different state")
                    }
                    buttonUp(key: step.button.rawValue)
                    socketClient.send(command: String(format: "emulation RunFor \"%.3f\"", Double(max(1, step.pauseAfterMs)) / 1000))
                    let released = try await harnessRequest("state", simulatedMS: 50)
                    guard FirmwareHarnessProtocol.buttonMask(in: released) == 0 else {
                        throw HarnessError.failure("Step \(index + 1): firmware did not observe all buttons released")
                    }
                }
                sequenceStatusMessage = "PASS: Every held/released GPIO state acknowledged by firmware."
            } catch is CancellationError {
                sequenceStatusMessage = "Cancelled; buttons released."
            } catch {
                sequenceStatusMessage = "FAILED: \(error.localizedDescription)"
                saveFailure(sequenceStatusMessage, uart: (try? uartEvidence(since: offset)) ?? "Unavailable")
            }
        }
    }

    public func cancelSequence() {
        activeSequenceTask?.cancel()
        for key in Array(pressedKeys) {
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
