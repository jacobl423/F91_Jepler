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
    @Published public var isSessionStarting = false
    @Published public var notificationTestStatus: String? = nil
    @Published public var notificationTestSucceeded = false
    @Published public var isHarnessBusy = false
    @Published public private(set) var isFirmwareReady = false
    @Published public private(set) var isBridgeReady = false
    public var canSendTestRequest: Bool {
        isRunning && isBridgeReady && !isHarnessBusy && !isBootTestRunning && !isSequenceRunning
    }
    public var runtimeLabel: String {
        if isSessionStarting { return "Starting emulator…" }
        if isFirmwareReady && isRunning { return "Firmware ready" }
        return isRunning ? "Waiting for firmware…" : "Stopped"
    }
    private(set) var hasVerifiedFirmwareForAudit = false
    
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
    
    @Published public var terminalWidth: CGFloat = 360 {
        didSet { userDefaults.set(Double(terminalWidth), forKey: "workbench.terminalWidth") }
    }
    @Published public var watchPanelHeight: CGFloat = 340 {
        didSet { userDefaults.set(Double(watchPanelHeight), forKey: "workbench.watchPanelHeight") }
    }
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
                clearAsset(kind: .pcb)
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
                clearAsset(kind: .appFirmware)
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
                clearAsset(kind: .bootloader)
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
                clearAsset(kind: .rescScript)
            }
        }
    }
    
    private let userDefaults: UserDefaults
    private var securityScopedAssetURLs: [SessionAssetKind: URL] = [:]
    
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
    @Published public var pcbValidationSHA256: String? = nil
    @Published public var pcbValidationError: String? = nil
    @Published public var comparisonBoard: KiCadBoard? = nil
    
    @Published public var showSetupSheet: Bool = false
    @Published public var isTargetedForDrop: Bool = false
    @Published public var cpuInspector = CPUInspectorModel()
    
    // KiCad Tooling, 3D Render & Live Watcher
    @Published public var activePCBURL: URL? = nil
    @Published public var isPCBWatcherActive: Bool = false
    @Published public var isSyncingPCB: Bool = false
    @Published public var pcbRender3DImage: NSImage? = nil
    @Published public var isRendering3D: Bool = false
    @Published public var show3DRenderMode: Bool = false
    @Published public var kicadDRCReport: KiCadDRCReport? = nil
    @Published public var isRescReviewPresented = false
    @Published public var rescReviewText = ""
    @Published public var rescReviewSHA256: String? = nil
    @Published public var rescReviewReferenceEvidence: [RenodeScriptReferenceEvidence] = []
    @Published public var approvedRescSHA256: String? = nil
    @Published public var approvedRescReferences: [RenodeScriptReferenceEvidence] = []
    @Published public var activeRunID: UUID? = nil
    @Published public var activeRunManifestURL: URL? = nil
    @Published public var activeRunProvenance: [String: String] = [:]
    private var verifiedBuildManifest: FirmwareBuildManifest? = nil
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

        let terminal = userDefaults.double(forKey: "workbench.terminalWidth")
        if terminal.isFinite && terminal >= 276 { terminalWidth = terminal }
        let height = userDefaults.double(forKey: "workbench.watchPanelHeight")
        if height.isFinite && height >= 200 && height <= 600 { watchPanelHeight = height }

        // 2. Restore Sidebar Width
        let savedWidth = CGFloat(userDefaults.double(forKey: SessionPersistenceKeys.sidebarWidth))
        if savedWidth >= 246 && savedWidth <= 396 {
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
            assets[kind] = SessionAsset(kind: kind)
            guard let bookmarkKey = kind.bookmarkUserDefaultsKey,
                  let bookmark = userDefaults.data(forKey: bookmarkKey) else {
                userDefaults.removeObject(forKey: kind.userDefaultsKey)
                continue
            }

            let usesSecurityScope = kind.bookmarkUsesSecurityScopeKey.map {
                userDefaults.bool(forKey: $0)
            } ?? false
            do {
                var isStale = false
                let options: URL.BookmarkResolutionOptions = usesSecurityScope ? [.withSecurityScope] : []
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: options,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                if usesSecurityScope && url.startAccessingSecurityScopedResource() {
                    securityScopedAssetURLs[kind] = url
                }
                guard FileManager.default.isReadableFile(atPath: url.path),
                      kind.allowedExtensions.contains(url.pathExtension.lowercased()) else {
                    assets[kind] = SessionAsset(
                        kind: kind,
                        url: url,
                        state: .missing("File is unavailable or has an unsupported extension"),
                        isCustom: true
                    )
                    errorMessage = "Previously selected \(kind.title) is unavailable. Choose the file again to restore access."
                    continue
                }

                if isStale {
                    saveAssetBookmark(url, kind: kind, usesSecurityScope: usesSecurityScope)
                }
                installAsset(kind: kind, url: url)
            } catch {
                let path = userDefaults.string(forKey: kind.userDefaultsKey)
                if let path {
                    assets[kind] = SessionAsset(
                        kind: kind,
                        url: URL(fileURLWithPath: path),
                        state: .failed(error: error.localizedDescription),
                        isCustom: true
                    )
                }
                errorMessage = "Could not restore access to the previously selected \(kind.title). Choose the file again. \(error.localizedDescription)"
            }
        }
    }

    public var canStartSession: Bool {
        [SessionAssetKind.pcb, .appFirmware, .bootloader].allSatisfy { kind in
            guard let asset = assets[kind], asset.isCustom, asset.isReady,
                  let url = asset.fileURL else { return false }
            return FileManager.default.isReadableFile(atPath: url.path)
                && kind.allowedExtensions.contains(url.pathExtension.lowercased())
        }
    }

    private func inspectAssetAsync(kind: SessionAssetKind, url: URL, isCustom: Bool) {
        Task { [weak self] in
            do {
                let metadata = try await AssetInspector.inspect(url: url, kind: kind, isCustom: isCustom)
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if var existing = self.assets[kind], existing.fileURL == url {
                        existing.metadata = metadata
                        existing.state = .loaded(metadata)
                        self.assets[kind] = existing
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if var existing = self.assets[kind], existing.fileURL == url {
                        existing.state = .failed(error: error.localizedDescription)
                        self.assets[kind] = existing
                    }
                }
            }
        }
    }
    
    // MARK: - Asset Quick Actions
    
    public func updateAsset(kind: SessionAssetKind, url: URL) {
        if let previousURL = securityScopedAssetURLs.removeValue(forKey: kind) {
            previousURL.stopAccessingSecurityScopedResource()
        }
        let usesSecurityScope = url.startAccessingSecurityScopedResource()
        if usesSecurityScope {
            securityScopedAssetURLs[kind] = url
        }
        if kind.bookmarkUserDefaultsKey != nil {
            saveAssetBookmark(url, kind: kind, usesSecurityScope: usesSecurityScope)
        } else {
            userDefaults.set(url.path, forKey: kind.userDefaultsKey)
        }
        installAsset(kind: kind, url: url)
    }

    private func saveAssetBookmark(_ url: URL, kind: SessionAssetKind, usesSecurityScope: Bool) {
        guard let bookmarkKey = kind.bookmarkUserDefaultsKey else { return }
        userDefaults.set(url.path, forKey: kind.userDefaultsKey)
        do {
            let options: URL.BookmarkCreationOptions = usesSecurityScope ? [.withSecurityScope] : []
            let bookmark = try url.bookmarkData(
                options: options,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            userDefaults.set(bookmark, forKey: bookmarkKey)
            if let scopeKey = kind.bookmarkUsesSecurityScopeKey {
                userDefaults.set(usesSecurityScope, forKey: scopeKey)
            }
        } catch {
            userDefaults.removeObject(forKey: bookmarkKey)
            errorMessage = "Could not remember access to \(kind.title). It may need to be selected again next time. \(error.localizedDescription)"
        }
    }

    private func installAsset(kind: SessionAssetKind, url: URL) {
        let asset = SessionAsset(
            kind: kind,
            url: url,
            state: .inspecting,
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
        case .appFirmware, .bootloader:
            verifiedBuildManifest = nil
            hasVerifiedFirmwareForAudit = false
            auditGPIOPins()
            if isRunning {
                self.pcbReloadToast = "Updated \(kind.title); restarting emulation..."
                stopSession()
                startSession()
            } else {
                self.statusMessage = "Loaded \(url.lastPathComponent)"
            }
        case .rescScript:
            approvedRescSHA256 = nil
            approvedRescReferences = []
            reviewRescScript(url: url)
        }
    }
    
    public func clearAsset(kind: SessionAssetKind) {
        if isRunning || isSessionStarting { stopSession() }
        if let scopedURL = securityScopedAssetURLs.removeValue(forKey: kind) {
            scopedURL.stopAccessingSecurityScopedResource()
        }
        userDefaults.removeObject(forKey: kind.userDefaultsKey)
        if let bookmarkKey = kind.bookmarkUserDefaultsKey {
            userDefaults.removeObject(forKey: bookmarkKey)
        }
        if let scopeKey = kind.bookmarkUsesSecurityScopeKey {
            userDefaults.removeObject(forKey: scopeKey)
        }
        assets[kind] = SessionAsset(kind: kind)
        verifiedBuildManifest = nil
        hasVerifiedFirmwareForAudit = false
        if kind == .pcb {
            pcbFileWatcher.stopWatching()
            isPCBWatcherActive = false
            activePCBURL = nil
            pcbBoard = KiCadBoard()
            validateActiveBoard()
        }
        if kind == .rescScript {
            approvedRescSHA256 = nil
            approvedRescReferences = []
            isRescReviewPresented = false
            rescReviewSHA256 = nil
            rescReviewReferenceEvidence = []
            rescReviewText = ""
        }
        statusMessage = "Select external components before starting Renode."
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
        case .appFirmware, .bootloader:
            verifiedBuildManifest = nil
            hasVerifiedFirmwareForAudit = false
            auditGPIOPins()
            if isRunning {
                self.pcbReloadToast = "Reloaded \(url.lastPathComponent); restarting emulation..."
                stopSession()
                startSession()
            } else {
                self.pcbReloadToast = "Reloaded metadata for \(url.lastPathComponent)"
            }
        case .rescScript:
            approvedRescSHA256 = nil
            approvedRescReferences = []
            reviewRescScript(url: url)
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
    
    public func clearAssetSelections() {
        for kind in SessionAssetKind.allCases {
            clearAsset(kind: kind)
        }
    }
    
    // MARK: - KiCad Board Management & Live Watcher
    
    public func validateActiveBoard() {
        guard let pcbURL = activePCBURL else {
            pcbValidationResult = nil
            pcbValidationSHA256 = nil
            pcbValidationError = "No PCB file selected."
            auditGPIOPins()
            return
        }
        do {
            let digestBefore = try FirmwareBuildManifest.digest(pcbURL)
            guard let parsed = try? KiCadParser.parse(fileURL: pcbURL), parsed == pcbBoard else {
                pcbValidationResult = nil
                pcbValidationSHA256 = nil
                pcbValidationError = "Current editor model does not match the selected PCB file; reload before validation."
                auditGPIOPins()
                return
            }
            let heuristic = PCBValidator.validate(board: parsed)
            let digestAfter = try FirmwareBuildManifest.digest(pcbURL)
            guard digestBefore == digestAfter else {
                pcbValidationResult = nil
                pcbValidationSHA256 = nil
                pcbValidationError = "PCB changed during validation; result is inconclusive. Run again."
                auditGPIOPins()
                return
            }
            pcbValidationResult = PCBValidationResult(checks: heuristic.checks, componentBOM: heuristic.componentBOM,
                                                      overallScore: heuristic.overallScore,
                                                      isReadyForFabrication: heuristic.isReadyForFabrication,
                                                      sourceSHA256: digestAfter, confidence: .advisory,
                                                      generatedAt: heuristic.generatedAt)
            pcbValidationSHA256 = digestAfter
            pcbValidationError = nil
        } catch {
            pcbValidationResult = nil
            pcbValidationSHA256 = nil
            pcbValidationError = "Could not verify selected PCB bytes: \(error.localizedDescription)"
        }
        auditGPIOPins()
    }
    
    public func auditGPIOPins() {
        self.pinAuditResult = GPIOPinAuditor.audit(
            board: self.pcbBoard,
            firmwareManifest: hasVerifiedFirmwareForAudit ? verifiedBuildManifest : nil
        )
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
                if self.show3DRenderMode {
                    self.trigger3DRender()
                }
            }
        }
    }

    public func syncPCBFromKiCad() {
        guard let fileURL = activePCBURL else {
            errorMessage = "No PCB file selected to sync from KiCad."
            return
        }
        guard !isSyncingPCB else { return }
        isSyncingPCB = true

        Task { [weak self] in
            do {
                let board = try await KiCadParser.parseAsync(fileURL: fileURL)
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.pcbBoard = board
                    self.validateActiveBoard()
                    self.isSyncingPCB = false
                    if self.show3DRenderMode {
                        self.trigger3DRender()
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.isSyncingPCB = false
                    self.errorMessage = "Could not sync \(fileURL.lastPathComponent) from KiCad: \(error.localizedDescription)"
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
                let currentDigest = try FirmwareBuildManifest.digest(pcbURL)
                guard currentDigest == report.sourceSHA256 else {
                    self.kicadDRCReport = nil
                    throw HarnessError.failure("PCB changed after DRC; report not attached to current file. Run DRC again.")
                }
                self.kicadDRCReport = report
                self.isRunningDRC = false
                self.pcbReloadToast = "KiCad DRC \(report.confidence.rawValue): \(report.errorCount) errors, \(report.unconnectedCount) unconnected · SHA-256 \(report.sourceSHA256)"
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
    
    public func reviewRescScript(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            let digest = try FirmwareBuildManifest.digest(url)
            let references = try RenodeProcessManager.referenceEvidence(in: text, relativeTo: url.deletingLastPathComponent())
            rescReviewText = text
            rescReviewSHA256 = digest
            rescReviewReferenceEvidence = references
            isRescReviewPresented = true
        } catch {
            rescReviewSHA256 = nil
            rescReviewReferenceEvidence = []
            rescReviewText = ""
            errorMessage = "Unable to review Renode script: \(error.localizedDescription)"
        }
    }

    public func approveReviewedRescScript() {
        guard let url = assets[.rescScript]?.fileURL,
              let reviewed = rescReviewSHA256 else { return }
        do {
            guard try FirmwareBuildManifest.digest(url) == reviewed else {
                throw HarnessError.failure("Script changed after review. Inspect it again before running.")
            }
            let currentText = try String(contentsOf: url, encoding: .utf8)
            let currentReferences = try RenodeProcessManager.referenceEvidence(in: currentText, relativeTo: url.deletingLastPathComponent())
            guard currentText == rescReviewText, currentReferences == rescReviewReferenceEvidence else {
                throw HarnessError.failure("A referenced script resource changed after review. Review the script and resources again.")
            }
            approvedRescSHA256 = reviewed
            approvedRescReferences = currentReferences
            isRescReviewPresented = false
            startSession()
        } catch {
            errorMessage = error.localizedDescription
            approvedRescSHA256 = nil
        }
    }

    private static func discoverWorkspaceRoot() -> URL? {
        let starts = [URL(fileURLWithPath: FileManager.default.currentDirectoryPath), Bundle.main.bundleURL]
        for start in starts {
            var candidate = start
            for _ in 0..<12 {
                if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Firmware/renode/build-display.sh").path) {
                    return candidate.standardizedFileURL
                }
                let parent = candidate.deletingLastPathComponent()
                if parent == candidate { break }
                candidate = parent
            }
        }
        return nil
    }

    private static func verifyFirmware(image: URL, bootloader: URL) async -> FirmwareBuildManifest? {
        await Task.detached(priority: .userInitiated) {
            guard let manifest = try? FirmwareBuildManifest.load(for: image),
                  (try? manifest.verifyMCUboot(bootloader)) != nil,
                  (try? manifest.verifyConfig(relativeTo: image)) != nil,
                  (try? manifest.verifiedELF(relativeTo: image)) != nil else { return nil }
            return manifest
        }.value
    }

    private var startupTask: Task<Void, Never>?
    private var startupID: UUID?

    public func startSession() {
        guard startupTask == nil, !isSessionStarting, !isRunning else { return }
        guard canStartSession else {
            errorMessage = "Select a readable external PCB, application firmware, and MCUboot bootloader before starting Renode."
            statusMessage = "Component selection required"
            return
        }
        errorMessage = nil
        isFirmwareReady = false
        isBridgeReady = false
        notificationTestStatus = nil
        notificationTestSucceeded = false
        let id = UUID()
        startupID = id
        isSessionStarting = true
        statusMessage = "Checking firmware and starting Renode…"
        startupTask = Task { [weak self] in
            await self?.startSessionAfterVerification()
            if self?.startupID == id {
                self?.startupTask = nil
                self?.startupID = nil
                if self?.processManager.process == nil { self?.isSessionStarting = false }
            }
        }
    }

    private func startSessionAfterVerification() async {
        guard !Task.isCancelled else { return }
        guard let renodePath = RenodeProcessManager.findRenodeExecutable(customPath: customRenodePath) else {
            self.errorMessage = "Renode executable not found. Install Renode or choose its executable in Configure Workbench."
            self.statusMessage = "Renode missing"
            return
        }
        
        guard canStartSession,
              let appBinURL = assets[.appFirmware]?.fileURL,
              let selectedBootloader = assets[.bootloader]?.fileURL else { return }
        let bootloaderURL: URL? = selectedBootloader
        verifiedBuildManifest = await Self.verifyFirmware(image: appBinURL, bootloader: selectedBootloader)
        hasVerifiedFirmwareForAudit = verifiedBuildManifest != nil
        auditGPIOPins()
        guard !Task.isCancelled else { return }
        let ssd1306CsURL = ResourceLoader.url(forResource: "F91SSD1306", withExtension: "cs")
        let pcbURL = assets[.pcb]?.fileURL
        let rescURL = (assets[.rescScript]?.isCustom == true ? assets[.rescScript]?.fileURL : nil) ?? customRescURL
        if let rescURL, (assets[.rescScript]?.isCustom == true || customRescURL != nil) {
            guard let approvedRescSHA256,
                  (try? FirmwareBuildManifest.digest(rescURL)) == approvedRescSHA256,
                  (try? RenodeProcessManager.referenceEvidence(
                    in: String(contentsOf: rescURL, encoding: .utf8),
                    relativeTo: rescURL.deletingLastPathComponent()
                  )) == approvedRescReferences else {
                reviewRescScript(url: rescURL)
                statusMessage = "Review the custom Renode script before execution"
                return
            }
        }
        
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
                customRescURL: rescURL,
                approvedRescSHA256: approvedRescSHA256,
                approvedRescReferences: approvedRescReferences,
                expectedAppSHA256: verifiedBuildManifest?.imageSHA256,
                expectedBootloaderSHA256: verifiedBuildManifest?.mcubootSHA256
            )
            
            processManager.onOutputReceived = { [weak self] str in
                Task { @MainActor [weak self] in
                    self?.logStore.appendRenodeConsole(text: str)
                }
            }
            
            processManager.onTerminated = { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.stopSession()
                    self.statusMessage = "Renode Exited (Code \(status))"
                }
            }
            
            if let workDir = processManager.workDir {
                self.framePpmURL = workDir.appendingPathComponent("screen.ppm")
                activeRunID = UUID()
                activeRunProvenance = processManager.stagedAssetSHA256
                if let scriptDigest = processManager.preLaunchRescSHA256 {
                    activeRunProvenance["resc.executedSHA256"] = scriptDigest
                }
                if let pcbURL {
                    activeRunProvenance["pcb"] = try FirmwareBuildManifest.digest(pcbURL)
                }
                activeRunProvenance["app.sourcePath"] = appBinURL.path
                if let bootloaderURL { activeRunProvenance["mcuboot.sourcePath"] = bootloaderURL.path }
                if let rescURL { activeRunProvenance["resc.sourcePath"] = rescURL.path }
                activeRunProvenance["firmwarePairVerification"] = verifiedBuildManifest == nil ? "not verified as a matching build pair" : "verified against firmware-manifest.json"
                if let verifiedBuildManifest {
                    activeRunProvenance["firmware.sourceRevision"] = verifiedBuildManifest.sourceRevision
                    activeRunProvenance["firmware.sourceDirty"] = verifiedBuildManifest.sourceDirty ? "true" : "false"
                    activeRunProvenance["firmware.configSHA256"] = verifiedBuildManifest.configSHA256
                    activeRunProvenance["firmware.board"] = verifiedBuildManifest.board
                }
                activeRunProvenance["renodeExecutableSHA256"] = try FirmwareBuildManifest.digest(URL(fileURLWithPath: renodePath))
                guard let stagedApp = processManager.stagedAssetURLs["app"],
                      try FirmwareBuildManifest.digest(stagedApp) == activeRunProvenance["app"],
                      try FirmwareBuildManifest.digest(appBinURL) == activeRunProvenance["app"] else {
                    throw HarnessError.failure("Firmware changed while Renode was staging it; discarded this run.")
                }
                if let bootloaderURL {
                    guard let stagedBootloader = processManager.stagedAssetURLs["mcuboot"],
                          try FirmwareBuildManifest.digest(stagedBootloader) == activeRunProvenance["mcuboot"],
                          try FirmwareBuildManifest.digest(bootloaderURL) == activeRunProvenance["mcuboot"] else {
                        throw HarnessError.failure("MCUboot changed while Renode was staging it; discarded this run.")
                    }
                }
                if let expectedBootHash = verifiedBuildManifest?.mcubootSHA256 {
                    guard activeRunProvenance["mcuboot"] == expectedBootHash else {
                        throw HarnessError.failure("Staged MCUboot no longer matches the app firmware manifest.")
                    }
                }
                try processManager.preLaunchEvidence?()
                let referenceData = try JSONEncoder().encode(processManager.rescReferenceEvidence)
                let references = (try JSONSerialization.jsonObject(with: referenceData)) as? [[String: Any]] ?? []
                var record: [String: Any] = ["runID": activeRunID!.uuidString,
                                             "createdAt": ISO8601DateFormatter().string(from: Date()),
                                             "assets": activeRunProvenance,
                                             "rescReferences": references,
                                             "renodeExecutable": renodePath]
                if let manifest = verifiedBuildManifest {
                    record["firmwareManifest"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(manifest))
                }
                let evidenceDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("F91Jepler/RunEvidence/\(activeRunID!.uuidString)")
                try FileManager.default.createDirectory(at: evidenceDirectory, withIntermediateDirectories: true)
                for (key, stagedURL) in processManager.stagedAssetURLs {
                    let evidenceAssetURL = evidenceDirectory.appendingPathComponent(stagedURL.lastPathComponent)
                    try? FileManager.default.removeItem(at: evidenceAssetURL)
                    try FileManager.default.copyItem(at: stagedURL, to: evidenceAssetURL)
                    activeRunProvenance["evidencePath.\(key)"] = stagedURL.lastPathComponent
                }
                record["assets"] = activeRunProvenance
                record["stagedPaths"] = processManager.stagedAssetURLs.mapValues { $0.lastPathComponent }
                let data = try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys])
                try data.write(to: workDir.appendingPathComponent("run-manifest.json"), options: .atomic)
                let evidenceURL = evidenceDirectory.appendingPathComponent("run-manifest.json")
                try data.write(to: evidenceURL, options: .atomic)
                activeRunManifestURL = evidenceURL
            }
            
            self.statusMessage = "Firmware verified; connecting to Renode (port \(port))…"
            
            let connectingRunID = activeRunID
            socketClient.onConnected = { [weak self] in
                Task { @MainActor in
                    guard let self = self, self.activeRunID == connectingRunID,
                          self.processManager.process?.isRunning == true else { return }
                    self.isRunning = true
                    self.isSessionStarting = false
                    self.statusMessage = "Renode Connected & Running"
                    self.setupInitialCommands()
                    Task { @MainActor [weak self] in
                        try? await Task.sleep(nanoseconds: 15_000_000_000)
                        guard let self, self.activeRunID == connectingRunID, self.isRunning,
                              !self.isFirmwareReady else { return }
                        self.errorMessage = "Renode connected, but firmware startup was not observed. Check the UART log or rebuild the firmware."
                    }
                }
            }
            
            socketClient.onError = { [weak self] err in
                Task { @MainActor in
                    self?.stopSession()
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
            
            logStore.clear(tab: 0)
            logStore.onUartLine = { [weak self] line in
                guard let self else { return }
                if line == "Watch screen ready" {
                    self.isFirmwareReady = true
                    self.statusMessage = "Firmware ready"
                }
                if line == "[TEST] READY v1" { self.isBridgeReady = true }
            }
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
            stopSession()
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
        isFirmwareReady = false
        isBridgeReady = false
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
        socketClient.send(command: "sysbus.uart0 WriteChar 10")
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
        throw HarnessError.failure("No firmware ACK for \(field). Check the build output and rebuild with CONFIG_F91_TEST_BRIDGE=y; the image may not include the emulator-only UART test bridge.")
    }

    private func inject(service: String, summary: String, hex: String, fields: [(String, [UInt8])]) {
        guard isRunning else {
            let detail = "Start Renode before sending a test request."
            gattLogs.insert(GATTLogEntry(service: service, summary: detail, hexData: hex, status: "Not sent"), at: 0)
            if service == "Notification handlers via UART" {
                notificationTestSucceeded = false
                notificationTestStatus = detail
            }
            return
        }
        guard isBridgeReady else {
            notificationTestStatus = "The firmware test bridge is not ready. Wait for startup or rebuild the firmware."
            return
        }
        guard !injectionBusy, !isSequenceRunning, !isBootTestRunning else {
            let detail = "Test harness is busy; wait for the current request to finish."
            gattLogs.insert(GATTLogEntry(service: service, summary: detail, hexData: hex, status: "Not sent"), at: 0)
            if service == "Notification handlers via UART" {
                notificationTestSucceeded = false
                notificationTestStatus = detail
            }
            return
        }
        injectionBusy = true
        isHarnessBusy = true
        Task { @MainActor in
            defer {
                injectionBusy = false
                isHarnessBusy = false
            }
            var completed = 0
            do {
                for (field, bytes) in fields {
                    _ = try await harnessRequest(field, bytes: bytes)
                    completed += 1
                }
                gattLogs.insert(GATTLogEntry(service: service, summary: summary, hexData: hex, status: "Firmware ACK"), at: 0)
                if service == "Notification handlers via UART" {
                    notificationTestSucceeded = true
                    notificationTestStatus = "Firmware handlers acknowledged all fields via the UART mock. This does not test BLE/ATT or radio delivery."
                }
                logStore.appendRenodeConsole(text: "[HOST] UART harness: firmware acknowledged \(service)\n")
            } catch {
                let detail = "\(error.localizedDescription) (\(completed)/\(fields.count) fields applied; no rollback)"
                gattLogs.insert(GATTLogEntry(service: service, summary: detail, hexData: hex, status: "Failed"), at: 0)
                if service == "Notification handlers via UART" {
                    notificationTestSucceeded = false
                    notificationTestStatus = "Notification test failed: \(detail)"
                }
                logStore.appendRenodeConsole(text: "[HOST] UART harness failed: \(detail)\n")
            }
        }
    }

    public func injectNotification(payload: NotificationPayload) {
        notificationTestStatus = "Sending sample to firmware handlers over the emulator UART test bridge…"
        notificationTestSucceeded = false
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
        guard !isBootTestRunning, !isSequenceRunning, !injectionBusy else { return }
        guard isRunning else {
            bootCheckOverallResult = "Start Renode first. Use Build & Run, then retry this check."
            return
        }
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
                    guard FirmwareHarnessProtocol.buttonMask(in: held, id: nextHarnessID) == expected else {
                        throw HarnessError.failure("Step \(index + 1): expected held button mask \(expected); firmware reported a different state")
                    }
                    buttonUp(key: step.button.rawValue)
                    socketClient.send(command: String(format: "emulation RunFor \"%.3f\"", Double(max(1, step.pauseAfterMs)) / 1000))
                    let released = try await harnessRequest("state", simulatedMS: 50)
                    guard FirmwareHarnessProtocol.buttonMask(in: released, id: nextHarnessID) == 0 else {
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
        startupTask?.cancel()
        startupTask = nil
        startupID = nil
        isSessionStarting = false
        cancelSequence()
        if activeRunID != nil,
           let evidenceURL = activeRunManifestURL,
           let uartLogURL = processManager.uartLogURL,
           FileManager.default.fileExists(atPath: uartLogURL.path) {
            let evidenceDirectory = evidenceURL.deletingLastPathComponent()
            let evidenceLog = evidenceDirectory.appendingPathComponent("uart.log")
            try? FileManager.default.removeItem(at: evidenceLog)
            try? FileManager.default.copyItem(at: uartLogURL, to: evidenceLog)
            if var record = (try? Data(contentsOf: evidenceURL))
                .flatMap({ try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }) {
                if let runID = activeRunID { record["runID"] = runID.uuidString }
                record["finishedAt"] = ISO8601DateFormatter().string(from: Date())
                record["uartEvidence"] = "uart.log (captured when session stopped)"
                if let data = try? JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]) {
                    try? data.write(to: evidenceURL, options: .atomic)
                }
            }
        }
        logStore.onUartLine = nil
        isFirmwareReady = false
        isBridgeReady = false
        logStore.stopBackgroundUartTail()
        displayStore.stopPolling()
        uartSocketClient.disconnect()
        socketClient.disconnect()
        processManager.stop()
        activeRunID = nil
        activeRunManifestURL = nil
        activeRunProvenance = [:]
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
