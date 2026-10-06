# Asset & Session Architecture Handoff Report

## Executive Summary
This report presents an exhaustive architectural analysis of data models, session state, asset loaders, and Renode emulator integration in `Software/macOS_App` ("Jepler Dev"). It addresses Requirements R1 and R2 of the latest user request (dated 2026-10-05T19:52:40Z): replacing the disruptive modal configuration sheets and whole-window drop overlays with an intuitive, collapsible left sidebar featuring dedicated visual dropzones, live metadata extraction, quick asset management actions, and non-modal drag-and-drop UTTypes.

---

## 1. Observation

### 1.1 Current Session Modeling & Storage
In `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`:
- **Asset path properties** (lines 121–126):
  ```swift
  @Published public var customRenodePath: String? = nil
  @Published public var customWorkspaceURL: URL? = nil
  @Published public var customRescURL: URL? = nil
  @Published public var customPCBURL: URL? = nil
  @Published public var customAppBinURL: URL? = nil
  @Published public var customBootloaderURL: URL? = nil
  ```
- **Modal sheet flag** (line 128):
  ```swift
  @Published public var showSetupSheet: Bool = false
  ```
- **Global drop target flag** (line 129):
  ```swift
  @Published public var isTargetedForDrop: Bool = false
  ```
- **Active PCB State** (lines 40, 133–146):
  ```swift
  @Published public var pcbBoard: KiCadBoard = KiCadBoard()
  @Published public var activePCBURL: URL? = nil
  @Published public var isPCBWatcherActive: Bool = false
  public let pcbFileWatcher = PCBFileWatcher()
  ```
- **Zero persistence**: Grep search across `Software/macOS_App` for `UserDefaults`, `@AppStorage`, and `SceneStorage` returned **0 matches**. All configuration resets to bundled defaults when the app is restarted.

### 1.2 Embedded Resource Fallbacks
In `Software/macOS_App/F91JeplerEmulator/Engine/ResourceLoader.swift` (lines 18–63):
- `ResourceLoader.url(forResource:withExtension:)` resolves files using a 5-step fallback:
  1. Bundle subdirectory `Resources/Embedded`
  2. Bundle subdirectory `Embedded`
  3. Main bundle root
  4. Bundle resource path
  5. Current working directory relative paths (`Hardware/KiCad/drafts/f91_jepler/`, `build/renode-app/`, `bin/`, `Firmware/renode/`, `Software/macOS_App/F91JeplerEmulator/Resources/Embedded/`)
- Default embedded assets in `Software/macOS_App/F91JeplerEmulator/Resources/Embedded`:
  - `app.signed.bin` (145,184 bytes) — Application firmware binary
  - `mcuboot.elf` (1,479,928 bytes) — Bootloader ELF binary
  - `f91_jepler.kicad_pcb` (135,107 bytes) — KiCad 7/8 PCB layout
  - `f91_jepler.resc` (1,262 bytes) — Renode simulation script
  - `F91SSD1306.cs` (7,277 bytes) — Custom C# SSD1306 display model for Renode

### 1.3 Asset Verification & Header Inspections
Direct binary inspections on embedded assets reveal:
- **`app.signed.bin`**:
  - Command: `xxd -l 32 app.signed.bin`
  - Output: `00000000: 3db8 f396 0000 0000 0002 0000 d033 0200 ...`
  - Header magic: `0x3D 0xB8 0xF3 0x96` (Little-endian `0x96F3B83D`), confirming standard MCUboot image header (`IMAGE_MAGIC`).
  - Image size field: `0x000233D0` = 144,336 bytes.
- **`mcuboot.elf`**:
  - Command: `xxd -l 32 mcuboot.elf`
  - Output: `00000000: 7f45 4c46 0101 0100 0000 0000 0000 0000  .ELF...`
  - Header: `0x7F 'E' 'L' 'F'`, 32-bit (`0x01`), Little-endian (`0x01`).
  - Machine architecture at offset 0x12: `0x0028` (`EM_ARM`), target entry point `0x00001D09` (ARM Thumb mode).
- **`f91_jepler.kicad_pcb`**:
  - S-expression text file with `(kicad_pcb (version 20221018) (generator pcbnew) ...)`.
  - Parsed by `KiCadParser`: extracts 42 footprints, 13 nets, 258 tracks, edge segments conforming to Casio F-91 case dimensions (26.0 × 25.0 mm).
- **`f91_jepler.resc`**:
  - Renode simulation script declaring `$mcuboot_bin?=@bin/mcuboot.elf`, `$app_bin?=@bin/app.signed.bin`, machine creation (`mach create "nRF52840"`), inclusion of `F91SSD1306.cs`, and `macro reset`.

### 1.4 How Assets Are Supplied to Renode
In `Software/macOS_App/F91JeplerEmulator/Engine/RenodeProcessManager.swift` (lines 53–118) and `RenodeScriptGenerator.swift` (lines 4–53):
- `RenodeProcessManager.start(...)`:
  - Creates a temporary working directory: `f91_renode_<UUID>`.
  - Copies `appBinURL` to `tempDir/app.signed.bin` (line 67).
  - Copies `bootloaderURL` to `tempDir/mcuboot.elf` (line 73).
  - Copies `ssd1306CsURL` to `tempDir/F91SSD1306.cs` (line 84).
- `RenodeScriptGenerator.generateResc(...)`:
  - Lines 41–47:
    ```swift
    if let bl = bootloaderPath, !bl.isEmpty, FileManager.default.fileExists(atPath: bl) {
        script += "\n    sysbus LoadELF $mcuboot_bin"
    }
    script += """
    \n    sysbus LoadBinary $app_bin 0x0c000
    \"\"\"
    ```
- **Critical Flaw Observed**: The generator **hardcodes** `sysbus LoadBinary $app_bin 0x0c000` and `app.signed.bin`. If a developer provides an application `.elf` or `.hex` file, Renode cannot load it as a raw binary because ELF/HEX file headers would be written into flash at 0x0c000 rather than properly mapped.

### 1.5 Current UI Asset Workflow & Limitations
In `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift` and `HardwareSetupView.swift`:
- **Disruptive Modal Sheet**:
  - `HardwareSetupView` is invoked as a modal sheet (`.sheet(isPresented: $session.showSetupSheet)`).
  - Uses `FilePickerRow` with synchronous modal open panel (`panel.runModal() == .OK`) and unconfigured allowed content types (`panel.allowedContentTypes = []`).
  - Does not show file attributes, size, modification date, format validation, or load status.
  - Requires dismissing or clicking "Apply & Restart Emulation".
- **Disruptive Global Drop Overlay**:
  - `ContentView.swift` lines 79–119 attach an `.onDrop(of: [.fileURL])` to the entire window.
  - Hovering a file draws an opaque screen-covering overlay: *"Drop KiCad PCB or Firmware file to test"*.
  - When dropped, it immediately calls `session.startSession()`, terminating any running emulation regardless of file type.
  - Ambiguity: A `.elf` file dropped globally is always routed to `customBootloaderURL`, making it impossible to drop an application `.elf` via drag-and-drop.

---

## 2. Logic Chain

```
[Obs 1.1: Loose URLs in EmulatorSession] + [Obs 1.3: Diverse asset formats (S-Expr, MCUboot, ELF, HEX, RESC)]
  └──> Step 1: Session assets require a strongly typed abstraction (`SessionAsset` / `ProjectAsset`) holding kind, source URL, load state, and rich metadata, replacing fragmented optional URL variables.

[Obs 1.4: Renode hardcodes LoadBinary 0x0c000 and app.signed.bin] + [Requirement R1: Support .bin, .hex, .elf]
  └──> Step 2: RenodeProcessManager must preserve original file extensions during staging (e.g. app_firmware.elf) and RenodeScriptGenerator must dynamically emit `sysbus LoadELF $app_bin`, `sysbus LoadHEX $app_bin`, or `sysbus LoadBinary $app_bin 0x0c000` based on file extension and header inspection.

[Obs 1.1 & 1.5: Dropping PCB forces startSession() restart] + [Obs 1.1: PCBFileWatcher already reloads boards live]
  └──> Step 3: Modifying a PCB layout does not require restarting the Renode emulator process. Ingesting a new `.kicad_pcb` should hot-reload the board in-memory, re-validate geometry and pins, and notify the user via toast. Only firmware binary and script changes require an emulation restart.

[Obs 1.5: Disruptive modal sheet & synchronous panel.runModal()] + [Requirement R2: Quick management without modal sheets]
  └──> Step 4: Asset inspection and manipulation should occur directly on the primary screen. Quick actions on each asset card (Browse/Replace via async `NSOpenPanel().begin`, Clear/Reset to default, Reload from disk, Reveal in Finder via `NSWorkspace.shared.activateFileViewerSelecting`) allow instantaneous updates with zero modal disruption.

[Obs 1.3: Inspectable headers (MCUboot magic 0x96f3b83d, ELF 0x7f454c46)] + [Requirement R2: Live asset metadata]
  └──> Step 5: A non-blocking `AssetInspector` service can asynchronously extract:
       - Universal: File size (formatted KB/MB), modification date, full path, load status.
       - PCB: Dimensions (mm), footprint count, trace count, DRC status, auto-detected button pins.
       - Firmware: Architecture (ARM Cortex-M), format (MCUboot signed vs raw binary vs ELF vs Intel HEX), entry point address.
       - Script: Target board/platform, line count, macro definitions.

[Obs 1.5: Window-wide drop overlay ambiguous for .elf] + [Requirement R1: Dedicated visual dropzones]
  └──> Step 6: Replacing the window-wide overlay with dedicated dropzones per asset card in the sidebar eliminates ambiguity. Dropping a .elf on the Bootloader card sets MCUboot; dropping on the Application card sets application firmware.

[Obs 1.1: Zero persistence] + [Requirement R3: State persistence]
  └──> Step 7: Persisting custom file paths and sidebar visibility in `UserDefaults` (`"jepler.custom.*"`) and restoring them on startup preserves project state across app relaunches while gracefully falling back to embedded defaults if a referenced file is deleted.
```

---

## 3. Caveats

1. **Renode Firmware Hot-Swapping**:
   - Renode does not support live hot-patching of executing Cortex-M CPU flash memory without a machine reset. Replacing firmware or scripts must invoke `session.startSession()` (or `session.rebootMachine()`), which tears down the Renode subprocess and launches the new build.
2. **App Sandboxing & Security Scopes**:
   - In development mode (`swift build` / Developer ID), standard POSIX file paths stored in `UserDefaults` work reliably. If the app is later converted to Mac App Store distribution with `com.apple.security.app-sandbox`, security-scoped bookmarks (`bookmarkData(options:includingResourceValuesForKeys:relativeTo:)`) will be required to retain file read permissions across relaunches.
3. **Intel HEX Linear Address Records**:
   - Intel HEX files (`.hex`) embed memory addresses within record type `04` (Extended Linear Address). If a user supplies a merged HEX file containing both MCUboot (0x00000) and application (0x0C000), loading it into sysbus is handled cleanly by `sysbus LoadHEX`, but the UI should note that the binary spans multiple memory banks.
4. **KiCad Large Board Parsing**:
   - While `f91_jepler.kicad_pcb` is ~135 KB and parses in <20 ms, complex multilayer boards could take longer. All parsing and header inspection must continue running asynchronously (`Task.detached`) to ensure 60 fps UI responsiveness.

---

## 4. Conclusion & Proposed Implementation Blueprint

### 4.1 Data Models (`SessionAsset.swift`)

```swift
import Foundation
import UniformTypeIdentifiers

public enum SessionAssetKind: String, CaseIterable, Identifiable {
    case pcb = "KiCad PCB Layout"
    case appFirmware = "Application Firmware"
    case bootloader = "MCUboot Bootloader"
    case rescScript = "Renode Simulation Script"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .pcb: return "cpu"
        case .appFirmware: return "doc.bin"
        case .bootloader: return "lock.shield"
        case .rescScript: return "terminal"
        }
    }
    
    public var allowedExtensions: [String] {
        switch self {
        case .pcb: return ["kicad_pcb"]
        case .appFirmware: return ["bin", "hex", "elf"]
        case .bootloader: return ["elf", "hex", "bin"]
        case .rescScript: return ["resc"]
        }
    }
    
    public var allowedUTTypes: [UTType] {
        return allowedExtensions.compactMap { UTType(filenameExtension: $0) }
    }
}

public enum AssetLoadState: Equatable {
    case embeddedDefault
    case customActive
    case missing(path: String)
    case invalidFormat(reason: String)
    
    public var badgeTitle: String {
        switch self {
        case .embeddedDefault: return "Default (Embedded)"
        case .customActive: return "Custom (Active)"
        case .missing: return "File Missing"
        case .invalidFormat: return "Invalid Format"
        }
    }
}

public struct AssetMetadata: Equatable {
    public let fileName: String
    public let filePath: String
    public let fileSizeBytes: Int64
    public let fileSizeFormatted: String
    public let modificationDate: Date?
    public let modificationDateFormatted: String
    public let formatBadge: String          // e.g. "MCUboot Signed Bin", "ELF32 ARM", "KiCad 8 PCB"
    public let secondaryDetail: String        // e.g. "26.0 × 25.0 mm • 42 components" or "Entry: 0x00001D09"
    public let isCustom: Bool
    
    public static var empty: AssetMetadata {
        AssetMetadata(
            fileName: "None",
            filePath: "",
            fileSizeBytes: 0,
            fileSizeFormatted: "0 B",
            modificationDate: nil,
            modificationDateFormatted: "—",
            formatBadge: "Unassigned",
            secondaryDetail: "No file loaded",
            isCustom: false
        )
    }
}

public struct SessionAsset: Identifiable, Equatable {
    public var id: SessionAssetKind { kind }
    public let kind: SessionAssetKind
    public var currentURL: URL?
    public var state: AssetLoadState
    public var metadata: AssetMetadata
}
```

### 4.2 Metadata Extraction Engine (`AssetInspector.swift`)

```swift
import Foundation

public final class AssetInspector {
    public static func inspect(url: URL, kind: SessionAssetKind, isCustom: Bool) -> AssetMetadata {
        let fm = FileManager.default
        let path = url.path
        
        guard fm.fileExists(atPath: path),
              let attrs = try? fm.attributesOfItem(atPath: path) else {
            return AssetMetadata(
                fileName: url.lastPathComponent,
                filePath: path,
                fileSizeBytes: 0,
                fileSizeFormatted: "Missing",
                modificationDate: nil,
                modificationDateFormatted: "Not found on disk",
                formatBadge: "Missing",
                secondaryDetail: "File not accessible at path",
                isCustom: isCustom
            )
        }
        
        let sizeBytes = (attrs[.size] as? NSNumber)?.int64Value ?? 0
        let bcf = ByteCountFormatter()
        bcf.countStyle = .file
        let sizeFormatted = bcf.string(fromByteCount: sizeBytes)
        
        let modDate = attrs[.modificationDate] as? Date
        let dateFormatted: String = {
            guard let d = modDate else { return "Unknown" }
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .short
            return df.string(from: d)
        }()
        
        var formatBadge = url.pathExtension.uppercased()
        var secondaryDetail = ""
        
        switch kind {
        case .pcb:
            formatBadge = "KiCad S-Expr"
            if let str = try? String(contentsOf: url), str.contains("(kicad_pcb") {
                formatBadge = "KiCad PCB"
            }
            secondaryDetail = "\(sizeFormatted) • Ready for inspection"
            
        case .appFirmware, .bootloader:
            // Inspect magic bytes (first 32 bytes)
            if let handle = try? FileHandle(forReadingFrom: url) {
                defer { try? handle.close() }
                let header = handle.readData(ofLength: 32)
                if header.count >= 4 {
                    let bytes = [UInt8](header)
                    // ELF magic: 0x7F, 'E', 'L', 'F'
                    if bytes[0] == 0x7F && bytes[1] == 0x45 && bytes[2] == 0x4C && bytes[3] == 0x46 {
                        let isArm = header.count >= 20 && bytes[18] == 0x28 && bytes[19] == 0x00
                        formatBadge = isArm ? "ELF32 ARM (Executable)" : "ELF Executable"
                        if header.count >= 28 {
                            let entry = UInt32(bytes[24]) | (UInt32(bytes[25]) << 8) | (UInt32(bytes[26]) << 16) | (UInt32(bytes[27]) << 24)
                            secondaryDetail = String(format: "Entry: 0x%08X • Cortex-M", entry)
                        }
                    // MCUboot Image Magic: 0x96F3B83D (3d b8 f3 96)
                    } else if bytes[0] == 0x3D && bytes[1] == 0xB8 && bytes[2] == 0xF3 && bytes[3] == 0x96 {
                        formatBadge = "MCUboot Signed Bin"
                        if header.count >= 16 {
                            let imgSize = UInt32(bytes[12]) | (UInt32(bytes[13]) << 8) | (UInt32(bytes[14]) << 16) | (UInt32(bytes[15]) << 24)
                            secondaryDetail = String(format: "Slot 0 (0x0C000) • Header: %d KB", imgSize / 1024)
                        }
                    // Intel HEX: starts with ':' (0x3A)
                    } else if bytes[0] == 0x3A {
                        formatBadge = "Intel HEX"
                        secondaryDetail = "Record-based flash layout"
                    } else {
                        formatBadge = "Raw Binary"
                        secondaryDetail = "Slot: 0x0C000"
                    }
                }
            }
            
        case .rescScript:
            formatBadge = "Renode Script"
            if let lines = try? String(contentsOf: url).components(separatedBy: .newlines) {
                secondaryDetail = "\(lines.count) lines • nRF52840 Platform"
            }
        }
        
        return AssetMetadata(
            fileName: url.lastPathComponent,
            filePath: path,
            fileSizeBytes: sizeBytes,
            fileSizeFormatted: sizeFormatted,
            modificationDate: modDate,
            modificationDateFormatted: dateFormatted,
            formatBadge: formatBadge,
            secondaryDetail: secondaryDetail,
            isCustom: isCustom
        )
    }
}
```

### 4.3 Renode Binary Staging & Command Generator Update

To eliminate the hardcoded `.bin` and `LoadBinary` bug, update `RenodeScriptGenerator.swift` and `RenodeProcessManager.swift`:

```swift
// In RenodeScriptGenerator.swift:
public static func generateResc(
    appBinPath: String,
    bootloaderPath: String?,
    uartPort: UInt16,
    uartLogPath: String,
    ssd1306CsPath: String?
) -> String {
    // ... setup machine ...
    
    // Reset macro:
    // 1. Bootloader command
    if let bl = bootloaderPath, !bl.isEmpty, FileManager.default.fileExists(atPath: bl) {
        if bl.lowercased().hasSuffix(".hex") {
            script += "\n    sysbus LoadHEX $mcuboot_bin"
        } else if bl.lowercased().hasSuffix(".bin") {
            script += "\n    sysbus LoadBinary $mcuboot_bin 0x00000"
        } else {
            script += "\n    sysbus LoadELF $mcuboot_bin"
        }
    }
    
    // 2. Application binary command based on format
    let appLower = appBinPath.lowercased()
    if appLower.hasSuffix(".elf") {
        script += "\n    sysbus LoadELF $app_bin"
    } else if appLower.hasSuffix(".hex") {
        script += "\n    sysbus LoadHEX $app_bin"
    } else {
        script += "\n    sysbus LoadBinary $app_bin 0x0c000"
    }
    
    // ...
}
```

### 4.4 Quick Actions Specification

Each asset card in the sidebar implements four non-modal quick actions:
1. **Browse / Replace**:
   - Invokes `NSOpenPanel` asynchronously:
     ```swift
     let panel = NSOpenPanel()
     panel.allowsMultipleSelection = false
     panel.canChooseDirectories = false
     panel.canChooseFiles = true
     panel.allowedContentTypes = kind.allowedUTTypes
     panel.begin { response in
         guard response == .OK, let url = panel.url else { return }
         Task { @MainActor in
             session.updateAsset(kind: kind, url: url)
         }
     }
     ```
2. **Clear / Revert to Embedded Default**:
   - Clears `custom*URL = nil`.
   - Reverts state to bundled resource.
   - Refreshes card metadata.
   - For PCB: re-parses default board and re-runs DRC.
   - For Firmware/Script: prompts 1-click reload of Renode.
3. **Reload**:
   - For PCB: executes `session.reloadPCB(fileURL: activePCBURL)` (hot in-memory re-parse without stopping Renode).
   - For Firmware/Script: reads file attributes, checks disk timestamp, and re-launches Renode (`session.startSession()`).
4. **Reveal in Finder**:
   - Calls `NSWorkspace.shared.activateFileViewerSelecting([currentURL])`.

### 4.5 Drag-and-Drop UTType Handling

To guarantee 100% compatibility across all macOS versions and Finder drag sources:
- Dropzones accept `[.fileURL]`.
- Hover handler (`isTargeted`) validates whether dragged file extensions conform to the card's `allowedExtensions`:
  ```swift
  .onDrop(of: [.fileURL], isTargeted: $isHovered) { providers in
      guard let provider = providers.first else { return false }
      _ = provider.loadObject(ofClass: URL.self) { url, _ in
          guard let url = url else { return }
          let ext = url.pathExtension.lowercased()
          guard kind.allowedExtensions.contains(ext) else { return }
          Task { @MainActor in
              session.updateAsset(kind: kind, url: url)
          }
      }
      return true
  }
  ```
- Visual feedback:
  - Default: Subtle 1pt border with dashed stroke, category icon, and extension badge list.
  - Hover / Targeted: 2pt solid `Color.accentColor` border, soft glowing background tint (`Color.accentColor.opacity(0.12)`), and label changing to *"Drop to load into session"*.

### 4.6 State Persistence Integration

In `EmulatorSession`:
```swift
private let defaults = UserDefaults.standard

public func restorePersistedState() {
    if let pcb = defaults.string(forKey: "jepler.custom.pcb.path"), FileManager.default.fileExists(atPath: pcb) {
        customPCBURL = URL(fileURLWithPath: pcb)
    }
    if let app = defaults.string(forKey: "jepler.custom.appBin.path"), FileManager.default.fileExists(atPath: app) {
        customAppBinURL = URL(fileURLWithPath: app)
    }
    if let bl = defaults.string(forKey: "jepler.custom.bootloader.path"), FileManager.default.fileExists(atPath: bl) {
        customBootloaderURL = URL(fileURLWithPath: bl)
    }
    if let resc = defaults.string(forKey: "jepler.custom.resc.path"), FileManager.default.fileExists(atPath: resc) {
        customRescURL = URL(fileURLWithPath: resc)
    }
    isSidebarVisible = defaults.object(forKey: "jepler.sidebar.isVisible") as? Bool ?? true
}

public func persistAssetPath(kind: SessionAssetKind, url: URL?) {
    let key: String
    switch kind {
    case .pcb: key = "jepler.custom.pcb.path"
    case .appFirmware: key = "jepler.custom.appBin.path"
    case .bootloader: key = "jepler.custom.bootloader.path"
    case .rescScript: key = "jepler.custom.resc.path"
    }
    defaults.set(url?.path, forKey: key)
}
```

---

## 5. Verification Method

### 5.1 Verification Commands
1. **Swift Build Verification**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   swift build
   ```
   *Expected result*: Compiles with exit code 0 and zero errors.

2. **Embedded Asset Verification**:
   ```bash
   ls -lh /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Resources/Embedded
   ```
   *Expected result*: `app.signed.bin` (~145KB), `mcuboot.elf` (~1.48MB), `f91_jepler.kicad_pcb` (~135KB), `f91_jepler.resc` (~1.26KB) are present and readable.

3. **Header Inspection Verification**:
   ```bash
   xxd -l 16 /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Resources/Embedded/app.signed.bin | grep -q "3db8 f396" && echo "MCUboot Magic OK"
   xxd -l 16 /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Resources/Embedded/mcuboot.elf | grep -q "7f45 4c46" && echo "ELF Magic OK"
   ```
   *Expected result*: Both return OK, validating the binary header inspection logic.

### 5.2 Functional Inspection Checklist
- [ ] Left sidebar is present on the primary window without modal sheets.
- [ ] Dedicated visual dropzones exist for PCB (`.kicad_pcb`), Application Firmware (`.bin`, `.hex`, `.elf`), Bootloader (`.elf`), and Scripts (`.resc`).
- [ ] Dropping a file onto a card provides hover feedback and updates metadata immediately.
- [ ] Dropping a PCB updates the board in-memory without resetting Renode.
- [ ] Quick actions ("Browse...", "Clear", "Reload", "Reveal in Finder") execute smoothly and non-modally.
- [ ] Quitting and relaunching the application preserves custom asset paths via `UserDefaults`.
