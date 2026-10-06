# Handoff Report: UI Layout & Collapsible Left Sidebar Investigation

## 1. Observation

### 1.1 Project Structure & Build Configuration
- **File**: `Software/macOS_App/Package.swift`
  - Targets macOS 13.0+ (`.macOS(.v13)`).
  - Swift tools version: `5.9` with `swiftLanguageVersions: [.v5]`.
  - Executable target `F91JeplerEmulator` bundling embedded resources in `Resources/Embedded`.
  - Verification command: `swift build` inside `Software/macOS_App` executed with **exit code 0** (completed in 4.08 seconds, clean build).

### 1.2 Window Hierarchy & App Lifecycle
- **File**: `Software/macOS_App/F91JeplerEmulator/App.swift` (Lines 4–13)
  ```swift
  @main
  struct F91JeplerEmulatorApp: App {
      var body: some Scene {
          WindowGroup("Jepler Dev") {
              ContentView()
                  .frame(minWidth: 860, minHeight: 620)
          }
          .windowStyle(.titleBar)
          .windowToolbarStyle(.unified)
      }
  }
  ```
  - Unified window toolbar style is enabled, minimum window size is 860 × 620 pt.

### 1.3 Main Screen Layout & Split View Structure
- **File**: `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift` (Lines 12–78)
  - Layout hierarchy:
    ```
    ContentView (VStack, spacing: 0)
    ├── AppTopBarView (in-app header with branding, status, Start/Stop/Reboot, horizontal tab scroll, hotkeys, gear icon)
    ├── Divider
    ├── HSplitView (2-pane split)
    │   ├── Left Panel: Dynamic Workbench (VStack, minWidth: 300, idealWidth: 540)
    │   │   └── switch session.selectedViewMode:
    │   │       ├── .watch  -> CasioWatchFrameView
    │   │       ├── .canvas -> OLEDCanvasView
    │   │       ├── .gatt   -> GATTTestInjectorView
    │   │       ├── .test   -> AutomatedTestRunnerView
    │   │       ├── .pcb    -> KiCadPcbView
    │   │       ├── .gdb    -> GDBInspectorView
    │   │       └── .split  -> ResizableVSplitView (CasioWatchFrameView + GATTTestInjectorView)
    │   └── Right Panel: Monospaced UART Terminal (VStack, minWidth: 260, idealWidth: 520)
    │       └── TerminalView(session: session)
    └── Error / Warning Banner (session.errorMessage)
    ```
  - **No Left Sidebar currently exists**: The primary screen is strictly divided into two panes: Workbench (left) and Terminal (right).

### 1.4 Current Asset Loading, Drop Handling & Modal Sheets
- **File**: `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift` (Lines 79–129)
  - A window-wide `.overlay` (lines 79–96) activates whenever `session.isTargetedForDrop` is true, drawing an 80% opacity banner reading *"Drop KiCad PCB or Firmware file to test"* over the entire window.
  - The `.onDrop(of: [.fileURL])` handler (lines 97–119) detects `.kicad_pcb`, `.bin`, `.hex`, `.elf`, and `.resc`, setting `session.custom*URL` and triggering `session.startSession()`.
  - Manual asset inspection and selection currently requires opening a modal sheet:
    ```swift
    .toolbar {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { session.showSetupSheet = true }) {
                Label("Configure Workbench", systemImage: "gearshape")
            }
        }
    }
    .sheet(isPresented: $session.showSetupSheet) {
        HardwareSetupView(session: session)
    }
    ```
- **File**: `Software/macOS_App/F91JeplerEmulator/Views/HardwareSetupView.swift` (Lines 31–162, 200–220)
  - Modal sheet contains file pickers (`FilePickerRow`) for:
    1. Renode Executable Path (`customRenodePath`)
    2. Zephyr / Project Root Directory (`customWorkspaceURL`)
    3. Renode Simulation Script (`customRescURL`)
    4. Application Firmware Binary (`customAppBinURL`)
    5. MCUboot Bootloader Binary (`customBootloaderURL`)
    6. KiCad PCB Layout File (`customPCBURL`)
  - User must click "Apply & Restart Emulation" or "Done" to dismiss sheet.

### 1.5 State Persistence Investigation
- Ripgrep pattern searches for `@AppStorage`, `UserDefaults`, and `SceneStorage` across all files in `Software/macOS_App`:
  - Result: **0 matches**.
  - All configuration (`customPCBURL`, `customAppBinURL`, `customBootloaderURL`, `customRescURL`, `customRenodePath`, `customWorkspaceURL`, `selectedViewMode`) is held in `@Published` in-memory properties in `EmulatorSession`.
  - Upon quitting and relaunching the application, all user selections and overrides are lost, reverting back to embedded resources in `Resources/Embedded`.

### 1.6 Keyboard Shortcuts & Key Monitoring
- **File**: `Software/macOS_App/F91JeplerEmulator/Utils/KeyboardMonitor.swift` (Lines 39–114)
  - Uses `NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp])`.
  - Ignores key events when first responder is `NSTextView`, `NSTextField`, or `NSText`.
  - Intercepts key codes: `18`/`83` ('1', Light), `19`/`84` ('2', Mode), `20`/`85` ('3', Toggle).
  - Crucially: Command key combinations (`event.modifierFlags.contains(.command)`) and other keys (such as `0` or `s`) are **not swallowed** by `KeyboardMonitor`, allowing standard SwiftUI `.keyboardShortcut` bindings (e.g. `Cmd+0` and `Opt+Cmd+S`) to function cleanly.

### 1.7 Fluid Resizing Characteristics of Existing Views
- **`CasioWatchFrameView.swift`**: Uses `GeometryReader` calculating a dynamic `scale = max(0.4, min(geo.size.width / 660, geo.size.height / 380, 1.25))` with responsive push buttons.
- **`OLEDCanvasView.swift`**: Uses integer nearest-neighbor pixel drawing scaled to aspect ratio `96.0 / 39.0`, resizing smoothly.
- **`KiCadPcbView.swift`**: Uses internal `HSplitView` for 2D/3D canvas and component inspector.
- **`TerminalView.swift`**: Uses `ConsoleTerminalTextView` (`NSViewRepresentable` wrapping `NSScrollView` and `NSTextView` with `widthTracksTextView = true`), adjusting horizontally and vertically without text clipping.

---

## 2. Logic Chain

```
[Observation 1.3: Main layout is 2-pane HSplitView] + [Observation 1.4: Modal sheet required to inspect or manage assets]
  └──> Step 1: Users currently have no persistent view of loaded PCB, firmware, and script assets; swapping assets requires either dragging onto a window-blocking overlay or entering a modal configuration sheet.
[Observation 1.1: macOS 13+ target] + [Observation 1.3: HSplitView natively manages horizontal split dividers]
  └──> Step 2: HSplitView can host 3 panes: (1) Collapsible Left Sidebar, (2) Central Workbench, and (3) Right Terminal.
[Observation 1.3: Dynamic switch view in Workbench] + [Observation 1.7: All workbench views and terminal fluidly resize]
  └──> Step 3: When the left sidebar is expanded or collapsed via withAnimation, HSplitView dynamically adjusts the width distribution. Workbench and Terminal naturally absorb the remaining space without layout clipping or breaking aspect ratios.
[Observation 1.4: ContentView global onDrop blocks entire screen] + [Requirement R1: Dedicated visual dropzones]
  └──> Step 4: Individual asset cards in the sidebar (PCB, App Firmware, Bootloader, Renode Script) with dedicated .onDrop handlers, UTType.fileURL validation, and hover visual feedback provide targeted drag-and-drop. The window-wide drop overlay can be replaced by subtle dropzone highlights.
[Observation 1.5: Zero persistence currently in EmulatorSession] + [Requirement R3: State persistence across sessions]
  └──> Step 5: EmulatorSession can bind properties to UserDefaults (isSidebarVisible, selectedViewMode, customPCBURL, customAppBinURL, customBootloaderURL, customRescURL, customRenodePath, customWorkspaceURL). On initialization, valid file paths are automatically restored, preserving project setup across app launches.
[Observation 1.6: KeyboardMonitor passes command modifiers] + [Requirement R3: Toolbar toggle & keyboard shortcuts]
  └──> Step 6: Binding Cmd+0 and Opt+Cmd+S via SwiftUI .keyboardShortcut, paired with a ToolbarItem(placement: .navigation) toggle and an in-app top bar toggle button, allows instant collapsing without intercepting watch simulation hotkeys (1/2/3).
[Observation 1.4 & 1.7: KiCadToolService & ResourceLoader provide URL inspection] + [Requirement R2: Quick management without modal sheets]
  └──> Step 7: Adding quick action buttons directly onto each sidebar card (Browse..., Reload/Restart, Reveal in Finder, Revert to Default) and displaying live file metadata (size, mod date, component count, status) eliminates the need for modal sheets for everyday development workflows.
```

---

## 3. Caveats

1. **Sandboxing and File Path Resolution**:
   - The app runs in development mode without strict App Sandbox container restrictions. Saving POSIX file path strings in `UserDefaults` (`url.path`) and verifying existence via `FileManager.default.fileExists(atPath:)` works reliably. If the app is later packaged with full App Sandbox entitlements for the Mac App Store, security-scoped bookmarks (`bookmarkData(options:includingResourceValuesForKeys:relativeTo:)`) would be necessary.
2. **Emulation Session Restart vs. Hot PCB Reloading**:
   - Modifying the **PCB Layout** (`.kicad_pcb`) can be hot-reloaded in-memory (`session.reloadPCB(fileURL:)`) without restarting the running Renode simulation process.
   - Modifying the **Application Binary** (`.bin`/`.hex`), **Bootloader** (`.elf`), or **Simulation Script** (`.resc`) requires re-invoking `session.startSession()`, which terminates the existing Renode process and launches a fresh instance with the updated binaries. Quick actions on firmware cards should explicitly denote this (e.g. "Reload & Restart Emulation").
3. **Window Width Ergonomics**:
   - While the sidebar collapses smoothly, when all three panels (Sidebar 280 pt, Workbench 540 pt, Terminal 480 pt) are open simultaneously, the ideal window width is ~1300 pt. The minimum window width of 860 pt in `App.swift` should be maintained so single-pane or collapsed modes work on smaller displays, while allowing full expansion.

---

## 4. Conclusion & Proposed Implementation Blueprint

### 4.1 Architecture Overview

```
Jepler Dev Window
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ AppTopBarView [ [Sidebar Toggle Button] "Jepler Dev" • Status | Start Stop Reboot | Tabs | Keys ]│
├────────────────────────────────┬────────────────────────────────┬────────────────────────────────┤
│ Collapsible Project Sidebar    │ Central Workbench (Switch Mode) │ UART / Renode Terminal         │
│ (minWidth: 230, ideal: 280)    │ (minWidth: 320, ideal: 540)    │ (minWidth: 260, ideal: 480)    │
│                                │                                │                                │
│ • Header & Collapse Button     │ • Casio Watch Frame (Scales)   │ • Zephyr UART / Renode Tab     │
│ • Global Drop Hint             │ • OLED Framebuffer (96×39)     │ • Search & Category Filter     │
│                                │ • GATT / BLE Injector          │ • Incremental ANSI Terminal    │
│ ┌────────────────────────────┐ │ • Automated Test Runner        │ • Renode Monitor Command Bar   │
│ │ Card 1: KiCad PCB (.pcb)   │ │ • KiCad PCB 2D/3D Inspector    │                                │
│ │ [Dropzone · Status · Size] │ │ • GDB / CPU Registers          │                                │
│ │ [Browse][Reload][Finder]   │ │                                │                                │
│ └────────────────────────────┘ │                                │                                │
│ ┌────────────────────────────┐ │                                │                                │
│ │ Card 2: App Binary (.bin)  │ │                                │                                │
│ │ [Dropzone · Status · Size] │ │                                │                                │
│ │ [Browse][Restart][Finder]  │ │                                │                                │
│ └────────────────────────────┘ │                                │                                │
│ ┌────────────────────────────┐ │                                │                                │
│ │ Card 3: Bootloader (.elf)  │ │                                │                                │
│ │ [Dropzone · Status · Size] │ │                                │                                │
│ │ [Browse][Reload][Finder]   │ │                                │                                │
│ └────────────────────────────┘ │                                │                                │
│ ┌────────────────────────────┐ │                                │                                │
│ │ Card 4: Renode Script (.resc)│                                │                                │
│ │ [Dropzone · Status · Size] │ │                                │                                │
│ │ [Browse][Restart][Finder]  │ │                                │                                │
│ └────────────────────────────┘ │                                │                                │
│ • Toolchain / Workspace Info   │                                │                                │
└────────────────────────────────┴────────────────────────────────┴────────────────────────────────┘
```

### 4.2 Detailed Component Plan

#### 1. New View: `Software/macOS_App/F91JeplerEmulator/Views/ProjectSidebarView.swift`
- **Header**:
  - Title: "WORKBENCH ASSETS" with project bundle badge.
  - Collapse icon button (`sidebar.leading` / chevron) to toggle visibility.
  - "Reset Defaults" action button to restore embedded assets.
- **Dedicated Asset Cards**:
  1. **PCB Layout Card**:
     - Targets `.kicad_pcb`.
     - Displays filename, origin tag (`[Embedded]` vs `[Custom]`), formatted size, modification date, footprints count (`session.pcbBoard.footprints.count`), nets count (`session.pcbBoard.nets.count`), and watcher status (`Watching` with green indicator).
     - Visual dropzone with `UTType.fileURL` drop target and clear hover border feedback.
     - Actions: Browse..., Reload, Reveal in Finder, Open in KiCad, Revert to Embedded.
  2. **Application Firmware Card**:
     - Targets `.bin`, `.hex`, `.elf`.
     - Displays filename, origin tag, formatted size, modification date, slot status (`Slot 0 Application`).
     - Actions: Browse..., Reload & Restart Emulation, Reveal in Finder, Revert to Embedded.
  3. **MCUboot Bootloader Card**:
     - Targets `.elf`.
     - Displays filename, origin tag, formatted size, modification date, status (`MCUboot Dual-Bank`).
     - Actions: Browse..., Reload, Reveal in Finder, Revert to Embedded.
  4. **Emulation Script Card**:
     - Targets `.resc`.
     - Displays filename, origin tag, formatted size, status (`Renode Simulation`).
     - Actions: Browse..., Reload & Restart, Reveal in Finder, Revert to Embedded.
  5. **Workspace & Toolchain Info Card**:
     - Displays Renode executable path status (green if found, red if missing) and Zephyr workspace path with quick folder picker.

#### 2. Model Updates: `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`
- **Persistence backing via `UserDefaults`**:
  - `isSidebarVisible: Bool` (persisted as `"jepler.sidebar.visible"`, defaults to `true`).
  - `selectedViewMode: ViewMode` (persisted as `"jepler.viewMode"`).
  - File paths:
    - `"jepler.asset.pcb"`
    - `"jepler.asset.appBin"`
    - `"jepler.asset.bootloader"`
    - `"jepler.asset.resc"`
    - `"jepler.asset.renodePath"`
    - `"jepler.asset.workspace"`
  - Restoration logic in `init()`: Checks each saved path with `FileManager.default.fileExists(atPath:)`; if valid, sets URL; if invalid, cleans up stale key and falls back to embedded defaults.
- **Helper methods**:
  - `effectivePCBURL`, `effectiveAppBinURL`, `effectiveBootloaderURL`, `effectiveRescURL`.
  - `AssetMetadata` extractor struct returning formatted size, modification date, existence, and custom status.
  - Quick action methods: `setPCB(url:)`, `revertPCBToDefault()`, `setAppBin(url:)`, `revertAppBinToDefault()`, `setBootloader(url:)`, `revertBootloaderToDefault()`, `setResc(url:)`, `revertRescToDefault()`, `resetAllAssetsToDefaults()`.

#### 3. Main View Integration: `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift`
- Replace 2-pane `HSplitView` with 3-pane `HSplitView`:
  ```swift
  HSplitView {
      if session.isSidebarVisible {
          ProjectSidebarView(session: session)
              .frame(minWidth: 230, idealWidth: 280, maxWidth: 380)
              .transition(.asymmetric(
                  insertion: .move(edge: .leading).combined(with: .opacity),
                  removal: .move(edge: .leading).combined(with: .opacity)
              ))
      }
      
      // Central Workbench
      VStack(spacing: 0) {
          switch session.selectedViewMode { ... }
      }
      .frame(minWidth: 320, idealWidth: 540, maxWidth: .infinity, maxHeight: .infinity)
      
      // Right Terminal
      VStack(spacing: 0) {
          TerminalView(session: session)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
      .frame(minWidth: 260, idealWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
  }
  ```
- **Toolbar Toggle Buttons & Keyboard Shortcuts**:
  - Window toolbar:
    ```swift
    ToolbarItem(placement: .navigation) {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                session.isSidebarVisible.toggle()
            }
        }) {
            Label(session.isSidebarVisible ? "Hide Sidebar" : "Show Sidebar", systemImage: "sidebar.leading")
        }
        .keyboardShortcut("0", modifiers: .command)
        .help("Toggle Project & Asset Sidebar (⌘0 or ⌥⌘S)")
    }
    ```
  - Additional shortcut for standard macOS sidebar convention: `.keyboardShortcut("s", modifiers: [.command, .option])`.
  - In `AppTopBarView`: Prominent sidebar toggle icon button placed directly before "Jepler Dev" title with hover tooltip.
- **Dropzone Refinement**:
  - Move from full-screen blocking overlay to localized visual drop targets on each sidebar card, plus a non-intrusive fallback for drops on the window.

---

## 5. Verification Method

### 5.1 Independent Compilation Verification
Execute the project build command:
```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
swift build
```
- **Pass Criteria**: Zero errors, exit code 0.

### 5.2 Functional UI Verification Checklist
1. **Sidebar Visibility & Toggling**:
   - Launch app: Verify left sidebar appears expanded on primary screen by default.
   - Click toolbar sidebar button: Verify sidebar animates closed (`withAnimation`) and central workbench + terminal expand smoothly.
   - Press `Cmd+0`: Verify sidebar toggles open/closed.
   - Press `Opt+Cmd+S`: Verify sidebar toggles open/closed.
   - Click collapse button in sidebar header: Verify sidebar closes.
2. **Drag-and-Drop Dropzones**:
   - Drag `.kicad_pcb` file from Finder over PCB dropzone: Verify card highlights with green border and clear drop cursor.
   - Drop file: Verify filename, size, and components count immediately update without opening any sheet, and KiCad PCB view reloads geometry.
   - Drag `.bin`/`.hex` file over Application Firmware dropzone: Verify card highlights with blue border.
   - Drop file: Verify filename updates and simulation restarts with new binary.
   - Drag `.elf` file over Bootloader dropzone: Verify card highlights with purple border.
   - Drag `.resc` file over Script dropzone: Verify card highlights with amber border.
3. **Quick Management Actions**:
   - Click "Browse..." on any card: Verify `NSOpenPanel` opens with filtered file extensions.
   - Click "Reveal in Finder": Verify Finder opens with target file selected.
   - Click "Revert to Default": Verify custom path clears and embedded default resource is restored.
   - Click "Reset Defaults": Verify all cards reset to embedded resources.
4. **State Persistence**:
   - Collapse sidebar, select a custom file, and switch view mode tab to "KiCad PCB".
   - Quit app (`Cmd+Q`) and relaunch.
   - Verify sidebar remains collapsed, active tab remains "KiCad PCB", and selected custom file paths remain loaded.
5. **Session Controls & Keyboard Monitor**:
   - Verify Start, Stop, and Reboot buttons remain fully responsive.
   - Press keys `1`, `2`, and `3`: Verify watch push buttons depress tactilely and GPIOs trigger in Renode without conflict.

### 5.3 Invalidation Conditions
- Any compile-time regression in `swift build`.
- Any disruption to existing Renode socket or UART terminal telemetry streams.
- Any freeze or glitch when toggling the sidebar between open and collapsed states.
