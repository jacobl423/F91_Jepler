# macOS Companion & Emulator App ("Jepler Dev") Build & Architecture Survey Report

## 1. Observation

### 1.1 Environment & Toolchain
- **Host OS**: macOS 26.6.2 (Darwin 25G83, Apple Silicon arm64).
- **Swift Compiler**: Apple Swift version 6.4 (`swiftlang-6.4.0.34.1 clang-2100.3.34.1`), `swift-driver version: 1.168.6`, target `arm64-apple-macosx26.0`.
- **Command Line Tools Path**: `/Library/Developer/CommandLineTools`.
- **App Bundle ID & Version**: `com.jepler.f91-emulator`, version `1.0.0` (from `F91JeplerEmulator/Resources/Info.plist:9-24`).
- **Minimum macOS Deployment Target**: `macOS 13.0` (`platforms: [.macOS(.v13)]` in `Package.swift:14-16`, `LSMinimumSystemVersion 13.0` in `Info.plist:25-26`).

### 1.2 Package.swift & Build System Configuration
`Software/macOS_App/Package.swift` verbatim configuration:
```swift
// swift-tools-version:5.9
import PackageDescription
import Foundation

var swiftSettings: [SwiftSetting] = []
let xcodePluginDir = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins"
if FileManager.default.fileExists(atPath: xcodePluginDir) {
    swiftSettings.append(.unsafeFlags(["-plugin-path", xcodePluginDir]))
}

let package = Package(
    name: "F91JeplerEmulator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "F91JeplerEmulator", targets: ["F91JeplerEmulator"])
    ],
    targets: [
        .executableTarget(
            name: "F91JeplerEmulator",
            path: "F91JeplerEmulator",
            exclude: [
                "F91JeplerEmulator.entitlements",
                "Resources/Info.plist",
                "Resources/AppIcon.icns"
            ],
            resources: [
                .copy("Resources/Embedded")
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageVersions: [.v5]
)
```
- **Dependencies**: 0 external packages (pure native Apple SDK: SwiftUI, AppKit, Foundation, Combine, UniformTypeIdentifiers, CoreGraphics).
- **Language Mode**: Swift 5 (`swiftLanguageVersions: [.v5]`).
- **Target Type**: Single `.executableTarget` named `F91JeplerEmulator`.
- **Resources**: Copies `Resources/Embedded` directory containing embedded firmware, PCB layout, Renode script, display driver C# model, and watch asset.
- **Excluded Files**: `F91JeplerEmulator.entitlements`, `Resources/Info.plist`, `Resources/AppIcon.icns`.

### 1.3 Build Status (`swift build`)
Command executed:
```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App && swift build
```
Result:
- **Exit Code**: `0`
- **Output**:
  ```
  Building for debugging...
  [Planning deferred tasks]
  ...
  /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/Package.swift: F91JeplerEmulator-product: ld: warning: search path '/Library/Developer/CommandLineTools/Developer/usr/lib' not found
  /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/Package.swift: F91JeplerEmulator-product: ld: warning: search path '/Library/Developer/CommandLineTools/Developer/Library/Frameworks' not found
  Build complete! (28.86 sec)
  ```
- **Note**: A previous build error in `PCBValidator.swift:504` (`binary operator '/' cannot be applied to operands of type 'Int' and 'Double'`) has already been resolved in source (`let viaDensity = Double(viaCount) / max(0.1, boardAreaCm2)`). The current build compiles cleanly with zero compilation errors.

### 1.4 Test Suite Status (`swift test`)
Command executed:
```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App && swift test
```
Result:
- **Exit Code**: `1`
- **Output**:
  ```
  error: no tests found; create a target in the 'Tests' directory
  ```
- **Finding**: There is no `.testTarget` defined in `Package.swift`, and no `Tests/` directory exists under `Software/macOS_App`.
- **In-App Testing**: The application implements automated integration and fuzzing test runners inside the GUI:
  - `F91JeplerEmulator/Views/AutomatedTestRunnerView.swift`
  - `F91JeplerEmulator/Models/AutomatedTestModels.swift`
  - Runs 6-stage boot sanity checks against Renode/Zephyr/MCUboot log patterns, and button sequence state fuzzing.

### 1.5 File Tree & Codebase Inventory
Total tracked files under `Software/macOS_App` (excluding `.build` and `build`):
```
Software/macOS_App/
├── Package.swift
├── build.log
├── scripts/
│   ├── build_app.sh              # Universal 2 binary & .app packager script
│   └── archive_app.sh            # Release distribution zip packaging script
└── F91JeplerEmulator/
    ├── App.swift                 # @main entry point, WindowGroup("Jepler Dev")
    ├── F91JeplerEmulator.entitlements # Sandbox, network client, user-selected read
    ├── Engine/                   # Core business logic, parsers, process & socket services
    │   ├── DisplayStreamStore.swift    # SSD1306 framebuffer, PPM polling, CGImage rendering
    │   ├── GPIOPinAuditor.swift        # KiCad vs Renode button pin auditor
    │   ├── KiCadParser.swift           # Async/sync S-expression parser for .kicad_pcb
    │   ├── KiCadToolService.swift      # KiCad CLI (DRC, 3D render, Gerber export) & App launcher
    │   ├── PCBDiffEngine.swift         # Structural comparison of PCB revisions
    │   ├── PCBFileWatcher.swift        # DispatchSource filesystem event watcher with debounce
    │   ├── PCBGeometryCache.swift      # Geometry cache for canvas renderer
    │   ├── PCBValidator.swift          # Manufacturing design rule checks & DRC
    │   ├── RenodeProcessManager.swift  # Child process manager for Renode executable
    │   ├── RenodeScriptGenerator.swift # Dynamic .resc generation from active binaries
    │   ├── RenodeSocketClient.swift    # Renode monitor TCP telnet client
    │   ├── RenodeUartSocketClient.swift# UART stream client over socket
    │   ├── ResourceLoader.swift        # Bundle & workspace fallback file locator
    │   └── TerminalLogStore.swift      # Log ring-buffer, ANSI parsing, category filter, search
    ├── Models/                   # Data structures, state models, view models
    │   ├── AutomatedTestModels.swift   # Boot check steps, sequence presets, test status
    │   ├── CPUInspectorModel.swift     # GDB/Renode registers (PC, SP), memory dump state
    │   ├── EmulatorSession.swift       # Central @MainActor ObservableObject coordinating state
    │   ├── GATTModels.swift            # BLE GATT services, notifications, sync packets
    │   ├── OLEDTheme.swift             # SSD1306 color themes (monochrome, amber, cyan, matrix)
    │   ├── PCBGeometry.swift           # Board layout models (tracks, vias, footprints, nets)
    │   └── PCBValidationResult.swift   # Validation violations & DRC check models
    ├── Utils/                    # Utility helpers
    │   ├── AnsiParser.swift            # ANSI escape sequence parser for terminal views
    │   └── KeyboardMonitor.swift       # Global NSEvent monitor for watch buttons '1', '2', '3'
    ├── Views/                    # SwiftUI views and UI panels
    │   ├── AutomatedTestRunnerView.swift # Automated boot check & fuzzing runner UI
    │   ├── CasioWatchFrameView.swift     # Realistic Casio watch chassis with embedded OLED
    │   ├── ContentView.swift             # Root window view, top bar, HSplitView, drop handler
    │   ├── GATTTestInjectorView.swift    # GATT packet injector UI (notification, clock, battery)
    │   ├── GDBInspectorView.swift        # CPU register & memory viewer UI
    │   ├── HardwareSetupView.swift       # Modal sheet for paths and binary settings
    │   ├── KiCadDRCView.swift            # KiCad DRC report viewer UI
    │   ├── KiCadPcbView.swift            # KiCad PCB workbench container
    │   ├── OLEDCanvasView.swift          # Standalone OLED display canvas with zoom & grid
    │   ├── PCB3DRenderView.swift         # 3D PCB render viewer UI
    │   ├── PCBCanvasView.swift           # Interactive 2D vector canvas for PCB traces/pads
    │   ├── PCBComparisonView.swift       # PCB diff revision comparator UI
    │   ├── PCBComponentInspectorPanel.swift # Footprint & netlist inspector panel
    │   ├── PCBDiffView.swift             # Board change diff panel
    │   ├── PCBSchematicExportPanel.swift # Schematic & netlist export panel
    │   ├── PCBValidationPanel.swift      # Design rule validation checklist panel
    │   ├── TerminalView.swift            # UART & Renode monitor dual-tab terminal view
    │   ├── ToolbarControlsView.swift     # Legacy/alternative toolbar view
    │   └── WatchFaceView.swift           # Digital watch face preview
    └── Resources/
        ├── AppIcon.icns
        ├── Info.plist
        └── Embedded/
            ├── F91SSD1306.cs             # C# Renode emulation plugin for SSD1306 OLED
            ├── app.signed.bin            # 142 KB signed Zephyr application binary
            ├── f91_jepler.kicad_pcb      # 132 KB KiCad PCB board file
            ├── f91_jepler.resc           # 1.2 KB Renode emulation script
            ├── jepler-icon.png           # 1.7 MB Casio watch face background image
            └── mcuboot.elf               # 1.4 MB MCUboot bootloader ELF binary
```

### 1.6 Current UI & Asset Handling Implementation
- **Current Layout in `ContentView.swift:12-61`**:
  - Vertical layout with `AppTopBarView` at top, followed by `Divider()`.
  - Main area uses an `HSplitView`:
    - Pane 1 (left): Dynamic workbench view displaying one of the `ViewMode` cases (`.watch`, `.canvas`, `.gatt`, `.test`, `.pcb`, `.gdb`, `.split`).
    - Pane 2 (right): `TerminalView(session: session)` (UART & Renode logs).
- **Current Asset Uploading**:
  - Window-level `.onDrop(of: [.fileURL], isTargeted: $session.isTargetedForDrop)` in `ContentView.swift:97-119`. Drops update `session.customPCBURL`, `session.customAppBinURL`, `session.customBootloaderURL`, or `session.customRescURL`, and trigger `session.startSession()`.
  - Modal sheet `HardwareSetupView(session: session)` (triggered via toolbar gear icon) uses `NSOpenPanel` to pick paths.
  - No visual left sidebar exists on the primary screen.

---

## 2. Logic Chain

### 2.1 Feasibility of Collapsible Left Sidebar (R1, R3)
1. **Observation**: `ContentView.swift:19` uses `HSplitView` to divide the workbench and the terminal.
2. **Reasoning**:
   - `HSplitView` is a SwiftUI wrapper around AppKit's `NSSplitView`. It natively supports 3 panes (Sidebar, Workbench, Terminal).
   - Alternatively, an outer container `HStack(spacing: 0)` with an animated `if session.isSidebarVisible { ProjectSidebarView ... Divider() }` followed by `HSplitView { Workbench; Terminal }` provides more predictable animation transitions (`.move(edge: .leading).combined(with: .opacity)`) when collapsing/expanding, preventing the AppKit `NSSplitView` from resetting pane divider positions or jumping during view removal.
   - Resizing of the sidebar can either be handled directly by `HSplitView` (with `.frame(minWidth: 220, idealWidth: 260, maxWidth: 380)`) or via a lightweight draggable splitter bar (identical to the pattern already implemented in `ResizableVSplitView` in `ContentView.swift:157-221`).
3. **Conclusion**: An outer container or 3-pane `HSplitView` can be seamlessly introduced into `ContentView.swift`.

### 2.2 Live Asset Metadata & Quick Management (R2)
1. **Observation**: Currently, `EmulatorSession.swift:120-126` maintains:
   - `customPCBURL: URL?`
   - `customAppBinURL: URL?`
   - `customBootloaderURL: URL?`
   - `customRescURL: URL?`
   - `activePCBURL: URL?`
   Default fallbacks are resolved through `ResourceLoader.url(forResource:withExtension:)`.
2. **Reasoning**:
   - Each asset has an active URL: either the custom user-selected URL or the default embedded resource in `Resources/Embedded`.
   - File metadata can be inspected via `FileManager.default.attributesOfItem(atPath:)` or `URLResourceValues`:
     - File size: `attributes[.size]` -> formatted with `ByteCountFormatter` (e.g., "142 KB").
     - Modification date: `attributes[.modificationDate]` -> formatted via `DateFormatter` or `RelativeDateTimeFormatter`.
     - File extension/type: `.kicad_pcb`, `.bin`, `.hex`, `.elf`, `.resc`.
     - Status: `.custom` ("Custom Override"), `.embedded` ("Default Embedded"), or `.missing` ("File Not Found").
   - Quick actions can be directly wired to existing session methods:
     - **Browse / Replace**: `NSOpenPanel` with allowed extensions or native `.fileImporter`.
     - **Clear**: Reset `customURL = nil` and reload default.
     - **Reload**: Call `session.reloadPCB(fileURL:)` for PCB, or restart Renode with `session.startSession()` for firmware/scripts.
     - **Reveal in Finder**: `NSWorkspace.shared.activateFileViewerSelecting([activeURL])`.
3. **Conclusion**: All backend plumbing already exists in `EmulatorSession` and `Engine`. A dedicated sidebar view can expose these without requiring modal sheets.

### 2.3 Drag-and-Drop Dropzones (R1, R2)
1. **Observation**: `ContentView.swift:97` uses `.onDrop(of: [.fileURL], isTargeted: ...)` with `provider.loadObject(ofClass: URL.self)`.
2. **Reasoning**:
   - In macOS 13+, `.onDrop(of: [.fileURL], isTargeted: ...)` is fully supported on individual subviews.
   - Dedicated dropzone cards can be rendered for each asset category:
     1. **PCB Layouts**: Accepts `.kicad_pcb`.
     2. **Firmware Binaries**:
        - Application Binary (`.bin`, `.hex`, `.elf`)
        - MCUboot Bootloader (`.elf`, `.bin`)
     3. **Emulation Scripts**: Accepts `.resc` (and optional companion scripts).
   - Each card can maintain its own `@State private var isTargeted: Bool` for clear hover highlights (accent border, subtle tint, animated icon).
   - On drop, the file extension is verified and immediately updates the appropriate session URL, re-triggering session start or PCB reload.
3. **Conclusion**: Dedicated, visual dropzones with hover states conform directly to R1 and Acceptance Criteria without impacting the global window drop handler.

### 2.4 State Persistence & Ergonomics (R3)
1. **Observation**: Currently, neither `@AppStorage` nor `UserDefaults` is used in `F91JeplerEmulator`. When the app restarts, any custom file paths are lost.
2. **Reasoning**:
   - `UserDefaults.standard` can persist:
     - `sidebarVisible: Bool` (default `true`)
     - `sidebarWidth: Double` (default `260.0`)
     - Asset file paths: `savedPcbPath`, `savedAppBinPath`, `savedBootloaderPath`, `savedRescPath`.
   - On initialization of `EmulatorSession`, persisted paths can be validated (`FileManager.default.fileExists`). If valid, they are restored; if deleted or moved, they gracefully fall back to embedded defaults.
   - Toolbar toggle button:
     - Standard `Image(systemName: "sidebar.left")` button in `AppTopBarView` and/or `.toolbar`.
     - Standard keyboard shortcut: `.keyboardShortcut("0", modifiers: [.command])` or `Command + B`.
3. **Conclusion**: Adding persistence via `UserDefaults` fulfills R3 with zero additional dependencies.

### 2.5 Test Suite Architecture & Testing Framework
1. **Observation**: `swift test` fails because there is no `Tests` target or directory in `Package.swift`.
2. **Reasoning**:
   - The project is built using SPM with `platforms: [.macOS(.v13)]` and `swiftLanguageVersions: [.v5]`.
   - In SPM, testing an `.executableTarget` directly via a `testTarget(dependencies: ["F91JeplerEmulator"])` is supported in Swift 5.4+ with `@testable import F91JeplerEmulator`.
   - Alternatively, a `Tests/F91JeplerEmulatorTests` suite can be added using `XCTest` (the standard Apple testing framework available on all macOS/Xcode setups).
   - Tests can cover:
     - `KiCadParser`: parsing board dimensions, footprints, vias.
     - `PCBValidator`: rule checks and via density.
     - `RenodeScriptGenerator`: correct `.resc` parameter injection.
     - `GATTModels`: serialization of epoch timestamps, timezone offsets, and battery levels.
     - Asset metadata and file extension routing.
3. **Conclusion**: Adding a test target to `Package.swift` and a `Tests/` directory will enable `swift test` to pass cleanly.

---

## 3. Caveats
1. **Renode Executable Availability**: Renode is not bundled with the repo. If Renode is not installed at `/Applications/Renode.app` or in `PATH`, emulation controls fail gracefully with an informative error message (`Renode executable not found`). This does not affect UI layout, PCB inspection, or unit tests.
2. **KiCad CLI Availability**: `kicad-cli` is optional for 3D rendering and DRC. When unavailable, `KiCadToolService` handles errors gracefully.
3. **App Sandbox & File Access**: `F91JeplerEmulator.entitlements` includes `com.apple.security.files.user-selected.read-only`. When files are chosen via `NSOpenPanel` or drag-and-drop, macOS grants sandbox read permissions. In debug builds via `swift run`, sandbox restrictions are not enforced unless codesigned into an app bundle.

---

## 4. Conclusion
1. **Build Health**: The existing macOS codebase compiles cleanly with `swift build` (0 compilation errors, exit code 0).
2. **Architecture**: Clean, modular SwiftUI + Combine architecture with separation of concerns across `Models`, `Engine`, `Views`, and `Utils`. Zero external SPM dependencies.
3. **Actionable Implementation Blueprint**:
   - **New View**: Create `ProjectSidebarView.swift` in `Views/` containing:
     - Header with "Project Assets", asset count badge, and collapse button.
     - Three categorized sections:
       1. PCB Layout (`.kicad_pcb`)
       2. Firmware Binaries (Application `.bin`/`.hex`/`.elf` and MCUboot `.elf`)
       3. Emulation Scripts (`.resc`)
     - Dedicated visual dropzone cards with hover feedback (`isTargeted`).
     - Asset cards displaying filename, status badge (Active/Embedded/Custom), file size, modification date, and quick actions (Browse, Clear, Reload, Reveal in Finder).
   - **Update `EmulatorSession.swift`**:
     - Add `@Published public var isSidebarVisible: Bool = true`.
     - Add `@Published public var sidebarWidth: CGFloat = 260`.
     - Add persistence helpers using `UserDefaults` to restore sidebar state and custom asset paths.
     - Add helper methods to clear/revert assets and fetch formatted metadata.
   - **Update `ContentView.swift`**:
     - Integrate `ProjectSidebarView` into the primary window layout to the left of the workbench.
     - Add sidebar toggle button to `AppTopBarView` and toolbar with keyboard shortcut `⌘0` / `⌘B`.
     - Ensure smooth split view resizing with min/max width constraints.
   - **Add Test Suite**:
     - Add `testTarget` to `Package.swift` and create unit tests in `Tests/F91JeplerEmulatorTests/` for parser, script generator, and asset metadata.

---

## 5. Verification Method

### 5.1 Verification Commands
1. **Verify Swift Compiler & OS**:
   ```bash
   swift --version
   sw_vers
   ```
2. **Verify Clean SPM Build**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   swift build
   ```
   *Expected output*: `Build complete!` with exit code `0`.
3. **Verify App Bundle Packaging**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   bash scripts/build_app.sh
   ```
   *Expected output*: Successfully generates and signs `build/Jepler Dev.app`.
4. **Verify Test Suite Status**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   swift test
   ```
   *Current output*: `error: no tests found; create a target in the 'Tests' directory`.

### 5.2 Key Files to Inspect
- `Software/macOS_App/Package.swift`: Target definitions and compiler settings.
- `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift`: Window layout, split view, and toolbar.
- `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`: State variables and asset path management.
- `Software/macOS_App/F91JeplerEmulator/Views/HardwareSetupView.swift`: Reference for existing file picker configurations.
