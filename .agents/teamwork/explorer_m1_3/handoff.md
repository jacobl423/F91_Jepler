# Handoff Report: EmulatorSession Asset Management, Persistence & Backwards Compatibility

## 1. Observation

### 1.1 Existing Session Implementation & Architecture
- **Target File**: `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`
- **Class Attributes**: `EmulatorSession` is declared at line 30 as:
  ```swift
  @MainActor
  public final class EmulatorSession: ObservableObject
  ```
- **Existing Asset & URL Properties** (Lines 121–127):
  ```swift
  // Configuration & File Overrides
  @Published public var customRenodePath: String? = nil
  @Published public var customWorkspaceURL: URL? = nil
  @Published public var customRescURL: URL? = nil
  @Published public var customPCBURL: URL? = nil
  @Published public var customAppBinURL: URL? = nil
  @Published public var customBootloaderURL: URL? = nil
  ```
- **Existing Board & UI Layout Properties** (Lines 36–43):
  ```swift
  @Published public var selectedViewMode: ViewMode = .split
  @Published public var watchPanelHeight: CGFloat = 340
  @Published public var terminalPanelHeight: CGFloat = 280
  @Published public var pressedKeys: Set<String> = []
  @Published public var pcbBoard: KiCadBoard = KiCadBoard()
  @Published public var comparisonPCBURL: URL? = nil
  @Published public var pcbDiffResult: PCBBoardDiffResult? = nil
  ```
- **Existing Default Loader** (Lines 189–205):
  ```swift
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
  ```
- **Existing Start Session File Resolution** (Lines 360–370):
  ```swift
  guard let appBinURL = customAppBinURL ?? ResourceLoader.url(forResource: "app.signed", withExtension: "bin") else {
      self.errorMessage = "Missing firmware app.signed.bin"
      self.statusMessage = "Missing Firmware"
      return
  }
  let bootloaderURL = customBootloaderURL ?? ResourceLoader.url(forResource: "mcuboot", withExtension: "elf")
  let ssd1306CsURL = ResourceLoader.url(forResource: "F91SSD1306", withExtension: "cs")
  let pcbURL = customPCBURL ?? ResourceLoader.url(forResource: "f91_jepler", withExtension: "kicad_pcb")
  ```

### 1.2 References Across Other Views
- `Software/macOS_App/F91JeplerEmulator/Views/HardwareSetupView.swift`:
  - Line 141 & 143: `selectedURL: session.customAppBinURL, onSelect: { url in session.customAppBinURL = url }`
  - Line 149 & 151: `selectedURL: session.customBootloaderURL, onSelect: { url in session.customBootloaderURL = url }`
  - Line 157 & 159: `selectedURL: session.customPCBURL, onSelect: { url in session.customPCBURL = url }`
  - Lines 204–207: Reset button sets `customRescURL = nil`, `customPCBURL = nil`, `customAppBinURL = nil`, `customBootloaderURL = nil`, followed by `session.loadEmbeddedDefaults()`.
- `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift`:
  - Lines 103–115: Drag-and-drop handler assigns `session.customPCBURL`, `session.customAppBinURL`, `session.customBootloaderURL`, `session.customRescURL` and immediately calls `session.startSession()`.
  - Line 22: `switch session.selectedViewMode` dynamically renders child workbench views.
- `Software/macOS_App/F91JeplerEmulator/Views/ToolbarControlsView.swift`:
  - Line 21: `Picker("Mode", selection: $session.selectedViewMode)` binds directly to `selectedViewMode`.

### 1.3 Target Requirements from PROJECT.md & DISPATCH.md
1. Add `@Published public var assets: [SessionAssetKind: SessionAsset] = [:]`.
2. Add `@Published public var isSidebarVisible: Bool = true` and `@Published public var sidebarWidth: CGFloat = 280`.
3. Support `UserDefaults` persistence with keys:
   - `jepler.custom.pcb.path`
   - `jepler.custom.appBin.path`
   - `jepler.custom.bootloader.path`
   - `jepler.custom.resc.path`
   - `jepler.sidebar.isVisible`
   - `jepler.sidebar.width`
   - `jepler.viewMode`
4. Provide startup path existence validation: if a persisted file path no longer exists on disk, scrub the key from `UserDefaults` and fallback to embedded default.
5. Provide quick action methods:
   - `updateAsset(kind: SessionAssetKind, url: URL)`
   - `revertAssetToDefault(kind: SessionAssetKind)`
   - `reloadAsset(kind: SessionAssetKind)`
   - `revealAssetInFinder(kind: SessionAssetKind)`
6. Retain full backwards compatibility with `customPCBURL`, `customAppBinURL`, `customBootloaderURL`, `customRescURL` and `loadEmbeddedDefaults()`.

---

## 2. Logic Chain

### Step 1: Centralized Asset State via `assets: [SessionAssetKind: SessionAsset]`
- **Observation Reference**: 1.1, 1.3
- **Reasoning**: Maintaining separate loosely-coupled properties (`customPCBURL`, `customAppBinURL`, etc.) with independent state leads to synchronization bugs when sidebar cards require live load states (`AssetLoadState`) and inspected metadata (`AssetMetadata`).
- **Design**: Introduce `@Published public var assets: [SessionAssetKind: SessionAsset] = [:]` as the single source of truth for all asset kinds (`.pcb`, `.appFirmware`, `.bootloader`, `.rescScript`).

### Step 2: Non-Breaking Backwards Compatibility via Computed Properties
- **Observation Reference**: 1.1, 1.2
- **Reasoning**: Existing views (`HardwareSetupView.swift`, `ContentView.swift`) read and write `customPCBURL`, `customAppBinURL`, `customBootloaderURL`, `customRescURL`. Rather than duplicating stored properties (which causes dual-state divergence), we make them computed properties with `{ get set }` backed directly by `assets[kind]`:
  - **Getter**: Returns `assets[kind]?.isCustom == true ? assets[kind]?.fileURL : nil`. If the asset is currently using the embedded default, the getter returns `nil`, matching previous behavior where `custom...URL` was `nil` until overridden.
  - **Setter**: When assigned a non-nil `URL`, it calls `updateAsset(kind: url:)`. When assigned `nil`, it calls `revertAssetToDefault(kind:)`.
  - **WritableKeyPath Compatibility**: In Swift, a `{ get set }` property on a reference type (`ObservableObject` class) possesses a `ReferenceWritableKeyPath`, preserving compatibility with SwiftUI bindings and direct mutations.

### Step 3: UserDefaults Key Namespace & Dependency Injection
- **Observation Reference**: 1.3
- **Reasoning**: Hardcoding string literals across multiple methods is error-prone. Defining `SessionPersistenceKeys` standardizes all keys.
- **Testability**: Injecting `userDefaults: UserDefaults = .standard` into `EmulatorSession.init(userDefaults:)` allows automated test suites in Milestone 3 to pass isolated test suites (`UserDefaults(suiteName: "TestPersistence")`) without modifying the user's live app settings.

### Step 4: Reactive Persistence via Property Observers (`didSet`)
- **Observation Reference**: 1.1, 1.3
- **Reasoning**: UI interactions (toggling sidebar visibility, dragging sidebar splitter, changing view mode) directly mutate `@Published` properties. By placing `didSet` observers on `isSidebarVisible`, `sidebarWidth`, and `selectedViewMode`:
  ```swift
  @Published public var isSidebarVisible: Bool = true {
      didSet { userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.isSidebarVisible) }
  }
  ```
  State is automatically persisted without requiring views to make auxiliary calls. During `init()`, Swift does not fire property observers, preventing redundant writes during restoration.

### Step 5: Startup Restoration & Missing File Graceful Degradation
- **Observation Reference**: 1.1, 1.3
- **Reasoning**: If a user previously selected a custom firmware or PCB located in a temporary directory or removable volume that no longer exists, blindly loading the path causes silent emulation crashes.
- **Algorithm**:
  1. Read persisted string from `userDefaults.string(forKey: kind.userDefaultsKey)`.
  2. Test `FileManager.default.fileExists(atPath: path)`.
  3. If true, load asset as `.customLoaded` with `isCustom: true`, and launch asynchronous `AssetInspector.inspect(...)`.
  4. If false or nil, scrub stale key via `userDefaults.removeObject(forKey: kind.userDefaultsKey)` and fallback to embedded default via `ResourceLoader.url(forResource:withExtension:)`. Set load state `.defaultEmbedded` with `isCustom: false`.
  5. For `.pcb`, if valid, initialize `activePCBURL`, parse in-memory asynchronously, run GPIO pin audit and DRC validation, and launch `pcbFileWatcher`.

### Step 6: Quick Action Semantics
- **Observation Reference**: 1.3
- **Methods**:
  - `updateAsset(kind:url:)`:
    1. Saves path to `userDefaults`.
    2. Instantiates/updates `SessionAsset` in `assets[kind]`.
    3. Triggers non-blocking `AssetInspector.inspect` task.
    4. For `.pcb`: re-parses KiCad geometry via `reloadPCB(fileURL: url)` without restarting Renode, points `pcbFileWatcher` to new file, emits toast.
    5. For `.appFirmware`, `.bootloader`, `.rescScript`: if session is running, restarts Renode session cleanly; otherwise updates status message.
  - `revertAssetToDefault(kind:)`:
    1. Removes key from `userDefaults`.
    2. Restores embedded default resource via `ResourceLoader`.
    3. Re-runs inspector for default asset.
    4. For `.pcb`: reloads default board in-memory without stopping Renode.
    5. For firmware/scripts: restarts Renode if running.
  - `reloadAsset(kind:)`:
    1. Checks disk existence. If missing, transitions asset state to `.missing(...)` and logs error.
    2. Re-inspects file metadata.
    3. For `.pcb`: reloads KiCad board in-memory and re-renders 3D if active.
    4. For firmware/scripts: restarts Renode session if running.
  - `revealAssetInFinder(kind:)`:
    1. Validates file existence on disk.
    2. Calls `NSWorkspace.shared.activateFileViewerSelecting([url])`.
    3. Deprecates/forwards existing `revealActivePCBinFinder()` to `revealAssetInFinder(kind: .pcb)`.

---

## 3. Caveats

1. **Asset Model Types**: The exact `SessionAsset` and `SessionAssetKind` type definitions are owned by Explorer M1_1 (`explorer_m1_1/handoff.md`). This session persistence design aligns precisely with the contract specified in `PROJECT.md` (`SessionAssetKind: .pcb, .appFirmware, .bootloader, .rescScript`).
2. **Renode Multi-Format Loading**: Dynamic loading of ELF, HEX, and raw binary in `RenodeScriptGenerator.swift` and `RenodeProcessManager.swift` is being detailed by Explorer M1_2 (`explorer_m1_2/handoff.md`). The quick actions designed here (`updateAsset`, `reloadAsset`) invoke `stopSession()` and `startSession()`, which will transparently consume Explorer M1_2's dynamic generator.
3. **App Sandbox & File Access**: If App Sandbox is enabled in the entitlements file, user-selected files via `NSOpenPanel` or drag-and-drop require security-scoped bookmarks for persistence across app restarts. In the current target (`F91JeplerEmulator.entitlements`), sandbox restrictions are disabled for emulator tooling, allowing standard file paths in `UserDefaults`.

---

## 4. Conclusion & Implementation Recommendation

### 4.1 Persistence Key Definition
Place this enum at the top of `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift` (or in a dedicated model file):

```swift
public enum SessionPersistenceKeys {
    public static let customPcbPath = "jepler.custom.pcb.path"
    public static let customAppBinPath = "jepler.custom.appBin.path"
    public static let customBootloaderPath = "jepler.custom.bootloader.path"
    public static let customRescPath = "jepler.custom.resc.path"
    public static let isSidebarVisible = "jepler.sidebar.isVisible"
    public static let sidebarWidth = "jepler.sidebar.width"
    public static let selectedViewMode = "jepler.viewMode"
}
```

### 4.2 Updated Properties in `EmulatorSession`
Replace the raw configuration properties in `EmulatorSession.swift`:

```swift
    // MARK: - Project Sidebar & Asset Management
    @Published public var assets: [SessionAssetKind: SessionAsset] = [:]
    
    @Published public var isSidebarVisible: Bool = true {
        didSet {
            userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.isSidebarVisible)
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
    
    private let userDefaults: UserDefaults

    // MARK: - Backwards-Compatible Asset Accessors
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
```

### 4.3 Initializer & Asset Restoration
```swift
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // 1. Restore Sidebar Visibility
        if userDefaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) != nil {
            self.isSidebarVisible = userDefaults.bool(forKey: SessionPersistenceKeys.isSidebarVisible)
        } else {
            self.isSidebarVisible = true
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
                        fileURL: customURL,
                        state: .customLoaded,
                        metadata: nil,
                        isCustom: true
                    )
                    self.assets[kind] = asset
                    inspectAssetAsync(kind: kind, url: customURL, isCustom: true)
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
            fileURL: defaultURL,
            state: state,
            metadata: nil,
            isCustom: false
        )
        self.assets[kind] = asset
        if let url = defaultURL {
            inspectAssetAsync(kind: kind, url: url, isCustom: false)
        }
    }
    
    private func inspectAssetAsync(kind: SessionAssetKind, url: URL, isCustom: Bool) {
        Task { [weak self] in
            let metadata = await AssetInspector.inspect(url: url, kind: kind, isCustom: isCustom)
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if var existing = self.assets[kind] {
                    existing.metadata = metadata
                    self.assets[kind] = existing
                }
            }
        }
    }
```

### 4.4 Quick Action Methods Implementation
```swift
    // MARK: - Asset Quick Actions
    
    public func updateAsset(kind: SessionAssetKind, url: URL) {
        userDefaults.set(url.path, forKey: kind.userDefaultsKey)
        
        let asset = SessionAsset(
            kind: kind,
            fileURL: url,
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
                self.pcbReloadToast = "Updated \(kind.rawValue); restarting emulation..."
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
                self.pcbReloadToast = "Reverted \(kind.rawValue); restarting emulation..."
                stopSession()
                startSession()
            } else {
                self.statusMessage = "Reverted \(kind.rawValue) to default"
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
```

---

## 5. Verification Method

To independently verify this design:

### 5.1 Verification Commands
1. Run `swift build` in `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App`:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App && swift build
   ```
   Ensures zero compilation errors when models and session methods are introduced.

### 5.2 Unit Verification Test Cases (For M3 Implementation)
1. **Persistence Roundtrip**:
   - Instantiate `EmulatorSession(userDefaults: isolatedDefaults)`.
   - Mutate `isSidebarVisible = false`, `sidebarWidth = 320`, `selectedViewMode = .gatt`.
   - Assert `isolatedDefaults.bool(forKey: SessionPersistenceKeys.isSidebarVisible) == false`.
   - Assert `isolatedDefaults.double(forKey: SessionPersistenceKeys.sidebarWidth) == 320.0`.
   - Assert `isolatedDefaults.string(forKey: SessionPersistenceKeys.selectedViewMode) == ViewMode.gatt.rawValue`.
   - Instantiate new `session2 = EmulatorSession(userDefaults: isolatedDefaults)`.
   - Assert `session2.isSidebarVisible == false`.
   - Assert `session2.sidebarWidth == 320`.
   - Assert `session2.selectedViewMode == .gatt`.
2. **Missing File Fallback Test**:
   - Write `/nonexistent/path/custom.bin` to `isolatedDefaults` under `jepler.custom.appBin.path`.
   - Instantiate `EmulatorSession(userDefaults: isolatedDefaults)`.
   - Verify `session.assets[.appFirmware]?.isCustom == false`.
   - Verify `isolatedDefaults.string(forKey: "jepler.custom.appBin.path") == nil`.
3. **Backwards Compatibility Test**:
   - Call `session.customPCBURL = testURL`.
   - Verify `session.assets[.pcb]?.fileURL == testURL` and `session.assets[.pcb]?.isCustom == true`.
   - Call `session.customPCBURL = nil`.
   - Verify `session.assets[.pcb]?.isCustom == false` and `session.customPCBURL == nil`.
4. **Quick Action Methods**:
   - Call `session.updateAsset(kind: .appFirmware, url: testURL)`.
   - Verify `isolatedDefaults.string(forKey: "jepler.custom.appBin.path") == testURL.path`.
   - Call `session.revertAssetToDefault(kind: .appFirmware)`.
   - Verify `isolatedDefaults.string(forKey: "jepler.custom.appBin.path") == nil`.

### 5.3 Invalidation Conditions
- If `SessionAssetKind` enum cases differ from `.pcb`, `.appFirmware`, `.bootloader`, `.rescScript`.
- If `UserDefaults` key names differ from `jepler.custom.pcb.path`, `jepler.custom.appBin.path`, `jepler.custom.bootloader.path`, `jepler.custom.resc.path`, `jepler.sidebar.isVisible`, `jepler.sidebar.width`, `jepler.viewMode`.
- If modifying `customPCBURL` breaks existing bindings in `HardwareSetupView.swift` or `ContentView.swift`.
