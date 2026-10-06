# Project: Jepler Dev macOS Companion & Emulator App UI Redesign

## Architecture
- **Framework**: SwiftUI + AppKit + Combine on macOS 13+ (Apple Swift 5/6 toolchain).
- **Core Pattern**: Observable MVVM with central `@MainActor` state coordinator (`EmulatorSession`).
- **Layout Architecture**: 3-pane fluid horizontal layout (`HSplitView`):
  1. **Leading Pane**: Collapsible `ProjectSidebarView` (minWidth: 230, idealWidth: 280, maxWidth: 380) with dedicated dropzone cards, live metadata badges, quick action menus, and toolchain info.
  2. **Center Pane**: Fluid Workbench with dynamic view mode switching (`CasioWatchFrameView`, `OLEDCanvasView`, `GATTTestInjectorView`, `AutomatedTestRunnerView`, `KiCadPcbView`, `GDBInspectorView`).
  3. **Trailing Pane**: UART Terminal & Renode Monitor (`TerminalView`) with ANSI log streams and command execution.
- **Data Flow**:
  - Drag-and-drop or file pickers update `SessionAsset` instances in `EmulatorSession`.
  - `AssetInspector` extracts file metadata (size, mod date, binary magic bytes / S-expr geometry) asynchronously.
  - Updates to PCB hot-reload geometry in-memory without resetting Renode.
  - Updates to firmware/scripts dynamically configure `RenodeScriptGenerator` (emitting appropriate `LoadELF`, `LoadHEX`, or `LoadBinary 0x0c000`) and restart the active emulation process.
  - All asset paths and UI state (sidebar visibility, width, active view mode) are persisted via `UserDefaults`.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Collapsible Project Sidebar | Expandable/collapsible sidebar residing directly in the primary window | M2 | R1, Survey |
| 2 | Dedicated PCB Dropzone | Visual dropzone for `.kicad_pcb` with hover feedback, board metrics, and DRC status | M2 | R1, Survey |
| 3 | Dedicated App Firmware Dropzone | Visual dropzone for application `.bin`, `.hex`, `.elf` with format badge | M2 | R1, Survey |
| 4 | Dedicated Bootloader Dropzone | Visual dropzone for MCUboot `.elf`, `.hex`, `.bin` with header inspection | M2 | R1, Survey |
| 5 | Dedicated Script Dropzone | Visual dropzone for `.resc` emulation scripts with line count & platform info | M2 | R1, Survey |
| 6 | Live Asset Metadata Engine | Non-blocking extraction of size, timestamp, format badges, and magic bytes | M1 | R2, Survey |
| 7 | Non-Modal Quick Actions | Browse/Replace (`NSOpenPanel`), Clear/Revert, Reload, Reveal in Finder (`NSWorkspace`) | M2 | R2, Survey |
| 8 | Direct Session Configuration Binding | Immediate live session updates without requiring modal configuration sheets | M1 | R2, Survey |
| 9 | Dynamic Renode Binary Loading | Dynamic `LoadELF`, `LoadHEX`, and `LoadBinary` in script generator preserving extensions | M1 | Survey |
| 10 | Hot In-Memory PCB Reloading | Hot reload `.kicad_pcb` without stopping or interrupting running Renode session | M1 | Survey |
| 11 | Fluid 3-Pane Layout Resizing | Main window split view resizing smoothly across sidebar, workbench, and terminal | M2 | R3, Survey |
| 12 | Toolbar Toggle Controls | Dedicated sidebar toggle button in window toolbar and `AppTopBarView` | M2 | R3, Survey |
| 13 | Keyboard Shortcuts | Standard `⌘0` and `⌥⌘S` shortcuts for sidebar toggle without hotkey conflicts | M2 | R3, Survey |
| 14 | State Persistence | Persistent storage of sidebar state, view mode, and asset paths via `UserDefaults` | M1 | R3, Survey |
| 15 | Non-Intrusive Drop UX | Removal of intrusive window-wide overlay in favor of localized card dropzones | M2 | R1, Survey |
| 16 | Automated Verification Suite | SPM test target and test suite verifying models, inspector, generator, and persistence | M3 | R5, Survey |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Asset Models, Metadata Engine & Session Integration | Implement `SessionAsset.swift`, `AssetInspector.swift`, dynamic binary loading in `RenodeScriptGenerator.swift`/`RenodeProcessManager.swift`, session configuration methods, and `UserDefaults` state persistence in `EmulatorSession.swift` | none | DONE |
| 2 | M2: Collapsible Sidebar UI & Main Window Integration | Implement `ProjectSidebarView.swift` with dedicated dropzones, hover states, quick action buttons, integrate into `ContentView.swift` 3-pane `HSplitView`, add toolbar toggle, `AppTopBarView` button, `⌘0`/`⌥⌘S` shortcuts, and remove intrusive overlay | M1 | PLANNED |
| 3 | M3: Automated Test Target & Verification Suite | Configure `.testTarget` in `Package.swift`, implement comprehensive unit tests in `Tests/F91JeplerEmulatorTests/` for models, inspector, header detection, script generator, and persistence | M1, M2 | PLANNED |
| 4 | M4: Final Integration & E2E Validation | Pass 100% of test suite and verification criteria, verify zero compile errors, verify smooth UI resizing and emulator session controls (Start, Stop, Reboot, key monitors) | M1, M2, M3 | PLANNED |

## Interface Contracts
### `SessionAsset` ↔ `EmulatorSession`
- `SessionAssetKind`: `.pcb`, `.appFirmware`, `.bootloader`, `.rescScript`.
- `AssetMetadata`: `fileName: String`, `filePath: String`, `fileSizeBytes: Int64`, `fileSizeFormatted: String`, `modificationDate: Date?`, `modificationDateFormatted: String`, `formatBadge: String`, `secondaryDetail: String`, `isCustom: Bool`.
- `EmulatorSession`:
  - `isSidebarVisible: Bool`
  - `sidebarWidth: CGFloat`
  - `assets: [SessionAssetKind: SessionAsset]`
  - `updateAsset(kind: SessionAssetKind, url: URL)`
  - `revertAssetToDefault(kind: SessionAssetKind)`
  - `reloadAsset(kind: SessionAssetKind)`
  - `revealAssetInFinder(kind: SessionAssetKind)`

### `ProjectSidebarView` ↔ `ContentView`
- `ProjectSidebarView(session: EmulatorSession)`
- Layout frames: `minWidth: 230, idealWidth: 280, maxWidth: 380`
- Toggle action: `session.isSidebarVisible.toggle()` with animation `.easeInOut(duration: 0.2)`
- Shortcuts: `⌘0` (`keyboardShortcut("0", modifiers: .command)`), `⌥⌘S` (`keyboardShortcut("s", modifiers: [.command, .option])`).

## Code Layout
- `Software/macOS_App/Package.swift`: Package manifest and test target definition.
- `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift`: Asset models, enum kinds, metadata structs.
- `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`: Central state coordinator, persistence methods.
- `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`: Asynchronous metadata extractor and header inspector.
- `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift`: Dynamic `.resc` script generator for ELF, HEX, and raw binary.
- `Software/macOS_App/F91JeplerEmulator/Engine/RenodeProcessManager.swift`: Renode process runner supporting multi-format binaries.
- `Software/macOS_App/F91JeplerEmulator/Views/ProjectSidebarView.swift`: Collapsible left sidebar view, dedicated dropzone cards, quick action buttons.
- `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift`: Main window layout with 3-pane `HSplitView`, toolbar buttons, keyboard shortcuts.
- `Software/macOS_App/Tests/F91JeplerEmulatorTests/`: Automated unit and integration test suite.
