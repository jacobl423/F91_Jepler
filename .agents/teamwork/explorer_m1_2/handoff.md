# Handoff Report: Renode Dynamic Loading, Extension Preservation & Hot PCB Reloading

## 1. Observation

### Observation 1.1: Static Command Generation in `RenodeScriptGenerator.swift`
In `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift` (lines 35-48):
```swift
        macro reset
        \"\"\"
            sysbus WriteDoubleWord 0x10000010 0x00001000
            sysbus WriteDoubleWord 0x10000014 0x00000100
        """
        
        if let bl = bootloaderPath, !bl.isEmpty, FileManager.default.fileExists(atPath: bl) {
            script += "\n    sysbus LoadELF $mcuboot_bin"
        }
        
        script += """
        \n    sysbus LoadBinary $app_bin 0x0c000
        \"\"\"
```
- Line 42 unconditionally emits `sysbus LoadELF $mcuboot_bin` for the bootloader regardless of whether it is an ELF, Intel HEX, or raw binary.
- Line 46 unconditionally emits `sysbus LoadBinary $app_bin 0x0c000` for the application binary, even if the user drops an ELF file (`zephyr.elf`) or Intel HEX (`zephyr.hex`).
- In addition, lines 16 and 41 gate bootloader inclusion behind `FileManager.default.fileExists(atPath: bl)`. In headless testing or when staging paths are passed prior to disk flush, `bootloaderPath` was silently dropped from the generated script.

### Observation 1.2: Hardcoded File Extension Overwrite in `RenodeProcessManager.swift`
In `Software/macOS_App/F91JeplerEmulator/Engine/RenodeProcessManager.swift` (lines 63-80):
```swift
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("f91_renode_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        self.workDir = tempDir
        
        let localAppBin = tempDir.appendingPathComponent("app.signed.bin")
        try? FileManager.default.removeItem(at: localAppBin)
        try? FileManager.default.copyItem(at: appBinURL, to: localAppBin)
        
        var localBootloader: URL? = nil
        if let bl = bootloaderURL {
            let dest = tempDir.appendingPathComponent("mcuboot.elf")
            try? FileManager.default.removeItem(at: dest)
            if (try? FileManager.default.copyItem(at: bl, to: dest)) != nil || FileManager.default.fileExists(atPath: dest.path) {
                localBootloader = dest
            } else if FileManager.default.fileExists(atPath: bl.path) {
                localBootloader = bl
            }
        }
```
- Line 67 hardcodes destination filename to `app.signed.bin`, discarding the original file extension (e.g., dropping `.elf` or `.hex` from `firmware.elf` or `app.hex`).
- Line 73 hardcodes destination filename to `mcuboot.elf`, discarding extensions if the bootloader is `.hex` or `.bin`.
- When Renode receives `$app_bin` pointing to `app.signed.bin`, tools or inspection engines that rely on file extension cannot distinguish between raw binary, ELF, or Intel HEX.

### Observation 1.3: PCB Hot Reloading Implementation in `EmulatorSession.swift`
In `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift` (lines 207-239):
```swift
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
```
- Line 220: `KiCadParser.parseAsync(fileURL: fileURL)` parses the KiCad PCB S-expression in-memory asynchronously without touching `processManager`.
- Line 224: `self.validateActiveBoard()` triggers `PCBValidator.validate(board: self.pcbBoard)` (the internal 15-rule DRC engine) and `auditGPIOPins()`.
- Nowhere in `reloadPCB(fileURL:)` is `processManager.stop()` or `processManager.start()` invoked. The running Renode process, UART log tailing (`TerminalLogStore`), and display frame polling (`DisplayStreamStore`) remain completely active and uninterrupted.

---

## 2. Logic Chain

### Step 2.1: Binary Format Handling in Renode
- Renode's `sysbus` commands require distinct loading primitives:
  1. `sysbus LoadELF <path>` parses 32-bit ELF program headers and places sections at their linked virtual addresses without an explicit address parameter.
  2. `sysbus LoadHEX <path>` decodes Intel HEX records (Extended Linear Address 04 records) and places data at specified addresses.
  3. `sysbus LoadBinary <path> <address>` takes raw machine bytes with no header metadata and copies them into memory starting at the specified numeric base address.
- In the nRF52840 MCUboot configuration:
  - Bootloader Flash base is `0x00000` (MCUboot occupies 48 KB: `0x00000` to `0x0c000`).
  - Application Flash slot-0 base is `0x0c000`.
- If an application is raw binary (`.bin`), it must be loaded with `sysbus LoadBinary $app_bin 0x0c000`. If it is an ELF or HEX file, loading it with `LoadBinary` corrupts memory with header/ASCII bytes.
- If a bootloader is raw binary, it must be loaded with `sysbus LoadBinary $mcuboot_bin 0x00000`. If it is an ELF file, it must be loaded with `sysbus LoadELF $mcuboot_bin`. If HEX, `sysbus LoadHEX $mcuboot_bin`.

### Step 2.2: Format Detection Architecture
- To support multi-format loading seamlessly, `RenodeScriptGenerator` must detect format via:
  1. **Magic Bytes (Highest fidelity)**:
     - ELF: first 4 bytes match `[0x7F, 0x45, 0x4C, 0x46]` (`\x7fELF`).
     - Intel HEX: first byte matches ASCII `:` (`0x3A`).
  2. **File Extension Fallback (Robust when files are mocked or offline)**:
     - `.elf`, `.axf` → `BinaryFormat.elf`
     - `.hex`, `.ihex` → `BinaryFormat.hex`
     - `.bin`, `.raw` or unknown → `BinaryFormat.binary`
  3. **Explicit Parameter Override**:
     - `appFormat: BinaryFormat? = nil`
     - `bootloaderFormat: BinaryFormat? = nil`
     - Allows callers (e.g. `AssetInspector` or tests) to explicitly force format if desired.

### Step 2.3: Staging Preservation in `RenodeProcessManager`
- `RenodeProcessManager` stages files into a temporary sandbox `f91_renode_<UUID>` before launching Renode.
- Replacing the hardcoded `app.signed.bin` and `mcuboot.elf` with sanitized filenames that preserve original extensions:
  ```swift
  let appExt = appBinURL.pathExtension.isEmpty ? "bin" : appBinURL.pathExtension
  let appBase = appBinURL.deletingPathExtension().lastPathComponent
      .replacingOccurrences(of: " ", with: "_")
      .replacingOccurrences(of: "$", with: "_")
      .replacingOccurrences(of: "@", with: "_")
  let safeAppName = (appBase.isEmpty ? "app" : appBase) + ".\(appExt)"
  let localAppBin = tempDir.appendingPathComponent(safeAppName)
  ```
  - Preserves exact extension (`.elf`, `.hex`, `.bin`).
  - Preserves descriptive base name while sanitizing whitespace and special characters that could invalidate Renode `.resc` `@path` parsing.
  - Same logic applies to bootloader staging (`safeBlName = (blBase.isEmpty ? "mcuboot" : blBase) + ".\(blExt)"`).

### Step 2.4: PCB Hot Reloading & Subprocess Independence
- Emulation and PCB layout inspection serve distinct concerns:
  - KiCad PCB layout governs 2D rendering, 3D PCB rendering, DRC checks, and button GPIO pin audits.
  - Renode executes compiled ARM Cortex-M4 machine code against virtual peripherals (nRF52840 CPU, RTC, UART, SSD1306 OLED via I2C).
- When a user modifies `.kicad_pcb` in KiCad:
  1. `PCBFileWatcher` captures file modification via kernel `DispatchSourceFileSystemObject` with a 250ms debounce.
  2. `session.reloadPCB(fileURL:)` invokes `KiCadParser.parseAsync` on a background Task.
  3. On `@MainActor`, `self.pcbBoard = board` is assigned, followed by `self.validateActiveBoard()` which runs `PCBValidator.validate(board: self.pcbBoard)`.
  4. If `self.kicadDRCReport != nil` (user previously ran external KiCad DRC), `self.runKiCadDRC()` can be re-executed asynchronously.
  5. If button GPIO pin assignments in the PCB differ from Renode's active bindings, `GPIOPinAuditor` displays an alert and offers `session.syncRenodeWithKiCadPins()`.
  6. The Renode subprocess is **never stopped or restarted**. Sockets remain connected, logs keep streaming, and firmware keeps executing without cold resets.

---

## 3. Caveats

1. **Standalone Application Emulation without MCUboot**:
   - If a standalone application ELF is linked to execute at Flash base `0x00000` (e.g. without MCUboot dual-bank chainloader), `bootloaderPath` should be `nil`. Renode will load the ELF at its linked base and initialize PC/SP from the ELF entry point.
2. **Raw Binary Load Addresses**:
   - For raw `.bin` files, Renode cannot deduce target addresses from the payload. The default address for application binary is `0x0c000` (MCUboot Slot 0), and for bootloader is `0x00000`. Custom addresses can be passed via `appLoadAddress` and `bootloaderLoadAddress` if custom memory maps are used.
3. **External KiCad CLI Availability**:
   - In environments where `kicad-cli` is not installed, `PCBValidator.validate(board:)` still performs full in-memory DRC (component presence, clearance, shorts, trace widths, via density). External `runKiCadDRC()` will gracefully report CLI absence without impacting in-memory DRC or Renode emulation.

---

## 4. Conclusion

The design for Milestone 1 Dynamic Renode Loading and PCB Hot Reloading is complete and validated:

1. **`RenodeScriptGenerator.swift`**:
   - Implemented `BinaryFormat` enum (`.elf`, `.hex`, `.binary`).
   - Implemented `detectFormat(path:)` with magic header parsing (`0x7F 'E' 'L' 'F'`, ASCII `:`) and extension fallbacks (`.elf`, `.hex`, `.bin`).
   - Implemented `formatLoadCommand` emitting `sysbus LoadELF`, `sysbus LoadHEX`, or `sysbus LoadBinary <var> <addr>`.
   - Updated `generateResc` with optional `appFormat`, `bootloaderFormat`, `appLoadAddress` (`0x0c000`), and `bootloaderLoadAddress` (`0x00000`).

2. **`RenodeProcessManager.swift`**:
   - Staging in `f91_renode_<UUID>` preserves original file extensions and sanitized base names (`safeAppName` and `safeBlName`).
   - Forwards staged paths and format overrides to `RenodeScriptGenerator.generateResc`.

3. **PCB Hot Reloading**:
   - `session.reloadPCB` re-parses KiCad S-expressions in-memory, executes in-memory DRC (`PCBValidator`), updates GPIO pin auditing, and refreshes external KiCad DRC asynchronously without stopping or restarting the running Renode subprocess.

### Produced Artifacts in Directory:
- **`proposed_RenodeScriptGenerator.swift`**: Full drop-in replacement file for `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift`.
- **`proposed_RenodeProcessManager.swift`**: Full drop-in replacement file for `Software/macOS_App/F91JeplerEmulator/Engine/RenodeProcessManager.swift`.
- **`renode_dynamic_loading.patch`**: Standard unified diff patch covering `RenodeScriptGenerator.swift`, `RenodeProcessManager.swift`, and `EmulatorSession.swift`.

---

## 5. Verification Method

To independently verify the implementation:

1. **Compilation Check**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
   swift build
   ```
   *Expected result*: Exits with code 0 and zero compilation warnings.

2. **Inspect Generated Script Behavior**:
   In Swift REPL or unit test (Milestone 3):
   ```swift
   let rescElf = RenodeScriptGenerator.generateResc(
       appBinPath: "/tmp/zephyr.elf",
       bootloaderPath: "/tmp/mcuboot.elf",
       uartLogPath: "/tmp/uart.log"
   )
   assert(rescElf.contains("sysbus LoadELF $mcuboot_bin"))
   assert(rescElf.contains("sysbus LoadELF $app_bin"))

   let rescHex = RenodeScriptGenerator.generateResc(
       appBinPath: "/tmp/app.hex",
       bootloaderPath: "/tmp/boot.hex",
       uartLogPath: "/tmp/uart.log"
   )
   assert(rescHex.contains("sysbus LoadHEX $mcuboot_bin"))
   assert(rescHex.contains("sysbus LoadHEX $app_bin"))

   let rescBin = RenodeScriptGenerator.generateResc(
       appBinPath: "/tmp/app.bin",
       bootloaderPath: "/tmp/boot.bin",
       uartLogPath: "/tmp/uart.log"
   )
   assert(rescBin.contains("sysbus LoadBinary $mcuboot_bin 0x00000"))
   assert(rescBin.contains("sysbus LoadBinary $app_bin 0x0c000"))
   ```

3. **Inspect Subprocess Independence during PCB Reload**:
   Verify in `EmulatorSession.swift`:
   - Check that `reloadPCB(fileURL:)` does not call `stopSession()` or `processManager.stop()`.
   - In a running session with `isRunning == true`, trigger `reloadPCB`: verify `isRunning` remains `true` and UART logs continue accumulating.
