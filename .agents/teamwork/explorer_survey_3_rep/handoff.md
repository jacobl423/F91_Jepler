# Handoff Report: macOS App Build & Architecture Survey

## 1. Observation

### 1.1 Build System & Package Configuration
- **Package Manifest Location**: `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/Package.swift`
- **Swift Tools Version**: `// swift-tools-version:5.9` (`Package.swift:1`)
- **Deployment Platform**: `.macOS(.v13)` (`Package.swift:15`)
- **Swift Language Mode**: `swiftLanguageVersions: [.v5]` (`Package.swift:35`)
- **Dependencies**: Zero external package dependencies (`dependencies: []`). Only Apple platform SDKs (`SwiftUI`, `AppKit`, `UniformTypeIdentifiers`, `Combine`, `CoreGraphics`, `Foundation`).
- **Product & Target**:
  - Executable Product: `F91JeplerEmulator` targeting target `F91JeplerEmulator` (`Package.swift:18`)
  - Target: `.executableTarget(name: "F91JeplerEmulator", path: "F91JeplerEmulator", ...)` (`Package.swift:21-34`)
  - Excludes: `["F91JeplerEmulator.entitlements", "Resources/Info.plist", "Resources/AppIcon.icns"]`
  - Resources: `[.copy("Resources/Embedded")]`
  - Compiler Flags: Dynamically detects Xcode host plugins directory `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins` and appends `.unsafeFlags(["-plugin-path", xcodePluginDir])` (`Package.swift:6-10`).
- **Compiler Toolchain**:
  - `swift --version`:
    ```
    swift-driver version: 1.168.6 Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)
    Target: arm64-apple-macosx26.0
    ```
- **Packaging Scripts**:
  - `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/scripts/build_app.sh`: Universal 2 build (`arm64-apple-macosx13.0` + `x86_64-apple-macosx13.0`) via `lipo`, outputs signed bundle `build/Jepler Dev.app`.
  - `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/scripts/archive_app.sh`: Invokes `build_app.sh` and creates `build/Jepler_Dev_Universal.zip`.

### 1.2 Current Build & Test Execution Results
- **Command**: `swift build` (in `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App`)
  - **Exit Code**: `0`
  - **Output**:
    ```
    Building for debugging...
    [3 / 7] F91JeplerEmulator-product
    [16 / 20] F91JeplerEmulator-product
    [17 / 20] F91JeplerEmulator-product
    Build complete! (3.15 sec)
    ```
  - **Result**: Zero compilation errors, zero warnings.
- **Command**: `swift test` (in `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App`)
  - **Exit Code**: `1`
  - **Verbatim Error**:
    ```
    Building for debugging...
    Build complete! (3.14 sec)
    error: no tests found; create a target in the 'Tests' directory
    ```
  - **Result**: No SPM `testTarget` or `Tests/` directory exists in `Package.swift`.
- **In-App Automated Testing**:
  - Automated tests are currently runtime-embedded:
    - `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Models/AutomatedTestModels.swift`
    - `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Views/AutomatedTestRunnerView.swift`
    - In-app test suite provides `session.runBootSanityCheck()` (validating Renode, MCUboot, flash slot, Zephyr kernel, SSD1306 framebuffer, BLE advertising) and automated button sequence fuzzing (`SequencePreset.defaultPresets`).

### 1.3 Complete Existing Codebase Inventory & File Hierarchy
The `Software/macOS_App` directory contains exactly the following source, resource, and tooling files (excluding `.build` and `build` artifacts):

```
Software/macOS_App/
├── Package.swift
├── build.log
├── scripts/
│   ├── archive_app.sh
│   └── build_app.sh
└── F91JeplerEmulator/
    ├── App.swift
    ├── F91JeplerEmulator.entitlements
    ├── Engine/
    │   ├── DisplayStreamStore.swift
    │   ├── GPIOPinAuditor.swift
    │   ├── KiCadParser.swift
    │   ├── KiCadToolService.swift
    │   ├── PCBDiffEngine.swift
    │   ├── PCBFileWatcher.swift
    │   ├── PCBGeometryCache.swift
    │   ├── PCBValidator.swift
    │   ├── RenodeProcessManager.swift
    │   ├── RenodeScriptGenerator.swift
    │   ├── RenodeSocketClient.swift
    │   ├── RenodeUartSocketClient.swift
    │   ├── ResourceLoader.swift
    │   └── TerminalLogStore.swift
    ├── Models/
    │   ├── AutomatedTestModels.swift
    │   ├── CPUInspectorModel.swift
    │   ├── EmulatorSession.swift
    │   ├── GATTModels.swift
    │   ├── OLEDTheme.swift
    │   ├── PCBGeometry.swift
    │   └── PCBValidationResult.swift
    ├── Resources/
    │   ├── AppIcon.icns
    │   ├── Info.plist
    │   └── Embedded/
    │       ├── F91SSD1306.cs
    │       ├── app.signed.bin
    │       ├── f91_jepler.kicad_pcb
    │       ├── f91_jepler.resc
    │       ├── jepler-icon.png
    │       └── mcuboot.elf
    ├── Utils/
    │   ├── AnsiParser.swift
    │   └── KeyboardMonitor.swift
    └── Views/
        ├── AutomatedTestRunnerView.swift
        ├── CasioWatchFrameView.swift
        ├── ContentView.swift
        ├── GATTTestInjectorView.swift
        ├── GDBInspectorView.swift
        ├── HardwareSetupView.swift
        ├── KiCadDRCView.swift
        ├── KiCadPcbView.swift
        ├── OLEDCanvasView.swift
        ├── PCB3DRenderView.swift
        ├── PCBCanvasView.swift
        ├── PCBComparisonView.swift
        ├── PCBComponentInspectorPanel.swift
        ├── PCBDiffView.swift
        ├── PCBSchematicExportPanel.swift
        ├── PCBValidationPanel.swift
        ├── TerminalView.swift
        ├── ToolbarControlsView.swift
        └── WatchFaceView.swift
```

### 1.4 Architectural Conventions Observed
1. **Application Lifecycle**:
   - `App.swift:3-13`: `@main struct F91JeplerEmulatorApp: App` instantiates `WindowGroup("Jepler Dev")` containing `ContentView().frame(minWidth: 860, minHeight: 620)` with `.windowStyle(.titleBar)` and `.windowToolbarStyle(.unified)`.
2. **State & Concurrency Architecture**:
   - `EmulatorSession` (`Models/EmulatorSession.swift:30-31`) is marked `@MainActor public final class EmulatorSession: ObservableObject`.
   - Single source of truth instantiated in `ContentView.swift:6` via `@StateObject private var session = EmulatorSession()`.
   - High-volume terminal and display streams are handled via dedicated singleton stores: `TerminalLogStore.shared` and `DisplayStreamStore.shared`.
   - Background tasks, process execution (`Process`), and socket monitoring communicate back to the UI via `Task { @MainActor in ... }` or `DispatchQueue.main.async`.
3. **Current Layout & Screen Organization**:
   - `ContentView.swift:12-78` uses a vertical stack:
     - Top: `AppTopBarView` with branding, emulator running state circle, Start/Stop/Reboot buttons, horizontal scrollable tab bar for `ViewMode` selection, hotkey legend, and gear setup icon.
     - Center: `HSplitView` dividing:
       - Left: Dynamic Workbench Panel (`session.selectedViewMode`: Watch, Canvas, GATT, Test, PCB, GDB, or Split).
       - Right: `TerminalView` (monospaced UART and Renode monitor).
     - Bottom: Dismissible error banner.
   - Drag and drop: `ContentView.swift:97-119` has a full-window `.onDrop(of: [.fileURL], isTargeted: $session.isTargetedForDrop)` that handles `.kicad_pcb`, `.bin`, `.hex`, `.elf`, `.resc`.
   - Asset configuration: Currently performed either via drag-drop on the whole window or modal sheet `HardwareSetupView.swift` triggered by `.sheet(isPresented: $session.showSetupSheet)`.
4. **Hardware Key Monitoring**:
   - `KeyboardMonitor.swift:39-66`: Uses `NSEvent.addLocalMonitorForEvents(matching: .keyDown / .keyUp)` for watch button keys "1", "2", "3".
   - Explicitly bypasses hotkey interception when focus is inside text fields (`NSTextView`, `NSTextField`, `NSText`).
   - Does NOT intercept standard command-key modifier combinations (`⌘`).

---

## 2. Logic Chain

1. **Target Compatibility & API Surface**:
   - *Observation*: `Package.swift` targets macOS 13.0 (`.macOS(.v13)`).
   - *Inference*: Any SwiftUI macOS 13+ APIs are permitted. Specifically:
     - `NavigationSplitView` is supported (macOS 13+).
     - `HSplitView` is fully supported (AppKit bridging).
     - `UniformTypeIdentifiers` (`UTType.fileURL`) is fully supported.
     - `@AppStorage` for state persistence (`UserDefaults`) is available.
     - `NSOpenPanel` works cleanly for file selection.

2. **Integration of Collapsible Left Sidebar (R1, R2, R3)**:
   - *Observation*: The primary screen in `ContentView.swift:19-61` currently uses an `HSplitView` containing dynamic workbench (left) and terminal (right).
   - *Observation*: Requirement R1 and R3 mandate an expandable and collapsible project sidebar on the primary screen for PCB layouts, firmware binaries, and scripts, integrated with workbench and terminal, resizable, with toolbar toggle and keyboard shortcut.
   - *Inference*: The primary window layout should be upgraded to incorporate the collapsible sidebar alongside the workbench and terminal:
     - Option A (3-Pane `HSplitView`): `HSplitView { if isSidebarVisible { ProjectAssetSidebarView(session: session).frame(minWidth: 220, idealWidth: 260, maxWidth: 360) } ... Workbench ... Terminal ... }`.
     - Option B (Dedicated Collapsible Left Container + Inner `HSplitView`): A collapsible sidebar panel on the left (with animated transition, width constraint, and splitter divider) paired with the existing `HSplitView` for workbench and terminal.
     - Option C (`NavigationSplitView`): Sidebar in column 1, and the detail view hosts the `HSplitView(Workbench, Terminal)`.
     - *Evaluation*: Option A/B avoids disrupting existing sub-view frame constraints and maintains the exact custom layout of `AppTopBarView` and workbench/terminal split geometry.

3. **Asset Upload & Management Migration from Modal Sheet to Sidebar (R1, R2)**:
   - *Observation*: `HardwareSetupView.swift` previously contained `FilePickerRow` for Renode path, workspace root, custom `.resc`, `.bin`/`.hex`, `.elf`, and `.kicad_pcb`.
   - *Observation*: `EmulatorSession.swift` already has `@Published` properties: `customPCBURL`, `customAppBinURL`, `customBootloaderURL`, `customRescURL`, `customWorkspaceURL`, `customRenodePath`, `activePCBURL`, and methods `loadEmbeddedDefaults()`, `reloadPCB()`, `startSession()`.
   - *Inference*: A dedicated `ProjectAssetSidebarView` can directly bind to and display these session properties. It can provide:
     - Dedicated visual drop zones with hover highlighting (`.onDrop(of: [.fileURL])`).
     - File metadata inspection using `FileManager.default.attributesOfItem(atPath:)` (file size, modification date, path, default vs custom status).
     - In-line action controls: "Browse...", "Reveal in Finder" (`NSWorkspace.shared.activateFileViewerSelecting`), "Reload", "Clear / Use Default".
     - Eliminates the need for modal sheets for everyday asset testing.

4. **Testing Architecture & Gap Analysis (DISPATCH item 2)**:
   - *Observation*: `swift build` compiles cleanly, but `swift test` fails because `Package.swift` defines no test target.
   - *Observation*: The application includes sophisticated in-app automated tests (`AutomatedTestRunnerView.swift`, `session.runBootSanityCheck()`).
   - *Inference*: For command-line test automation (`swift test`):
     - If desired, a `testTarget(name: "F91JeplerEmulatorTests", dependencies: ["F91JeplerEmulator"])` can be added to `Package.swift` alongside a `Tests/` directory with XCTest cases for parser/geometry/state logic.
     - However, the primary emulator verification workflow designed by the team is the in-app interactive regression runner.

---

## 3. Caveats

1. **Renode Binary Dependency at Runtime**:
   - `RenodeProcessManager` expects Renode installed at `/Applications/Renode.app` or in `$PATH`.
   - The app compiles cleanly without Renode installed, and handles missing Renode gracefully via status banners (`session.errorMessage`).
2. **Swift 5 Language Mode in Swift 6 Compiler**:
   - The system compiler is Swift 6.4, but `Package.swift` explicitly sets `swiftLanguageVersions: [.v5]`.
   - Strict concurrency (`-strict-concurrency=complete`) is not currently enabled.
   - All UI-mutating code in new views and models must adhere to `@MainActor` to prevent concurrency warnings.
3. **No SPM Unit Test Target Configured**:
   - As observed, `swift test` exits with code 1 until a test target is introduced. This does not affect `swift build` or app bundle creation.

---

## 4. Conclusion

1. **Build System Health**:
   - `Software/macOS_App` is in excellent health: `swift build` succeeds with zero errors and zero warnings in ~3.15 seconds.
2. **Architecture Architecture & Conventions**:
   - Pure Swift / SwiftUI + AppKit architecture targeting macOS 13+ with zero third-party dependencies.
   - Central state coordinator: `EmulatorSession` (`@MainActor ObservableObject`).
   - Split view layout: `HSplitView` dividing Workbench and Terminal.
3. **Path Forward for Collapsible Sidebar Redesign**:
   - Add `ProjectAssetSidebarView.swift` under `F91JeplerEmulator/Views/`.
   - Add asset metadata helper model under `F91JeplerEmulator/Models/` (or within sidebar view).
   - In `ContentView.swift`:
     - Add persistent sidebar visibility state: `@AppStorage("isProjectSidebarVisible") private var isSidebarVisible: Bool = true`.
     - Add persistent sidebar width state: `@AppStorage("projectSidebarWidth") private var sidebarWidth: Double = 260.0`.
     - Add toolbar toggle button with icon `sidebar.left` and keyboard shortcut (`⌘0` or `⌘B`).
     - Embed the sidebar as the leftmost pane of the main screen split, allowing smooth resizing and fluid collapse.
     - Integrate dedicated drag-and-drop zones for `.kicad_pcb`, `.bin`/`.hex`, `.elf`, and `.resc`.
     - Display live metadata (file size, modification date, active status) with quick actions (browse, clear, reload, reveal in Finder).

---

## 5. Verification Method

To independently verify these findings, run the following commands in `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App`:

1. **Verify Swift Build**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   swift build
   ```
   *Expected Result*: Exits with code 0 (`Build complete!`).

2. **Verify Swift Test Status**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   swift test
   ```
   *Expected Result*: Exits with code 1: `error: no tests found; create a target in the 'Tests' directory`.

3. **Verify File Structure**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   find F91JeplerEmulator -type f | sort
   ```
   *Expected Result*: Exactly matches the 34 source/resource files enumerated in Section 1.3.

4. **Verify Universal App Bundle Script**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   bash scripts/build_app.sh
   ```
   *Expected Result*: Creates `build/Jepler Dev.app` signed with ad-hoc signature.
