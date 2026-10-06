# Investigation Report & Handoff: Format Detection Hardening & Startup Crash Loop Elimination

**Explorer**: Explorer M1 Iteration 2 Agent 3  
**Working Directory**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_3`  
**Date**: 2026-10-05T20:45:00Z  
**Target Milestone**: Milestone 1 Iteration 2  

---

## 1. Observation

### 1.1 `RenodeScriptGenerator.detectFormat` Premature Classification
- **File**: `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift`
- **Lines**: 14–33
```swift
14:     public static func detectFormat(path: String) -> BinaryFormat {
15:         // Try reading header bytes first for highest fidelity
16:         if let fileHandle = FileHandle(forReadingAtPath: path) {
17:             defer { try? fileHandle.close() }
18:             if let headerData = try? fileHandle.read(upToCount: 16), !headerData.isEmpty {
19:                 // ELF magic: 0x7F, 'E', 'L', 'F' (0x7F 0x45 0x4C 0x46)
20:                 if headerData.count >= 4 &&
21:                     headerData[0] == 0x7F &&
22:                     headerData[1] == 0x45 &&
23:                     headerData[2] == 0x4C &&
24:                     headerData[3] == 0x46 {
25:                     return .elf
26:                 }
27:                 
28:                 // Intel HEX: starts with ASCII ':' (0x3A)
29:                 if headerData.first == 0x3A {
30:                     return .hex
31:                 }
32:             }
33:         }
```
- **Direct Empirical Observation**:
  Testing `detectFormat` against non-HEX files whose first byte happens to be `:` (0x3A) revealed severe false positives:
  1. A Renode script (`.resc`) starting with directive `:name: nRF52840` is evaluated as `.hex`.
  2. A raw binary file (`.bin`) whose first byte is `0x3A` (ASCII `:`) is evaluated as `.hex`.
  3. A Markdown / documentation file starting with `::: tip` or `:emoji:` is evaluated as `.hex`.
  4. Conversely, valid Intel HEX files that begin with comment headers (such as `zephyr/boards/intel/socfpga_std/cyclonev_socdk/support/blaster_6810.hex` where lines 1–2 are `# blaster_6810.hex\n# Version = 1.39\n`) have `headerData.first == 0x23` (`#`). If such a file lacks a `.hex` extension, `detectFormat` fails to detect HEX magic and defaults to `.binary`.

### 1.2 `EmulatorSession.swift` Startup Lifecycle & Persistent Crash Loop
- **File**: `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`
- **Lines**: 262–285, 320–342, 346–358
```swift
262:     private func loadInitialAssets() {
263:         for kind in SessionAssetKind.allCases {
264:             if let savedPath = userDefaults.string(forKey: kind.userDefaultsKey) {
265:                 if FileManager.default.fileExists(atPath: savedPath) {
266:                     let customURL = URL(fileURLWithPath: savedPath)
267:                     let asset = SessionAsset(
268:                         kind: kind,
269:                         url: customURL,
270:                         state: .customLoaded,
271:                         metadata: nil,
272:                         isCustom: true
273:                     )
274:                     self.assets[kind] = asset
275:                     inspectAssetAsync(kind: kind, url: customURL, isCustom: true)
276:                 } else {
...
320:     private func inspectAssetAsync(kind: SessionAssetKind, url: URL, isCustom: Bool) {
321:         Task { [weak self] in
322:             do {
323:                 let metadata = try await AssetInspector.inspect(url: url, kind: kind, isCustom: isCustom)
324:                 await MainActor.run { [weak self] in
325:                     guard let self = self else { return }
326:                     if var existing = self.assets[kind] {
327:                         existing.metadata = metadata
328:                         existing.state = .loaded(metadata)
329:                         self.assets[kind] = existing
330:                     }
331:                 }
332:             } catch {
333:                 await MainActor.run { [weak self] in
334:                     guard let self = self else { return }
335:                     if var existing = self.assets[kind] {
336:                         existing.state = .failed(error: error.localizedDescription)
337:                         self.assets[kind] = existing
338:                     }
339:                 }
340:             }
341:         }
342:     }
```
- **Direct Empirical Observation**:
  1. `updateAsset(kind:url:)` (line 347) writes `url.path` to `userDefaults` immediately upon drop/selection before verification.
  2. During application launch, `loadInitialAssets()` reads `savedPath` from `userDefaults` and calls `inspectAssetAsync`.
  3. When an adversarial or truncated Intel HEX record (such as `:0000000400`) was present, `AssetInspector.inspect` crashed the process via unhandled `fatalError: String index is out of bounds` (exit code 5 / SIGTRAP). Because `UserDefaults` persistently retains the file path, every subsequent launch triggered the exact same crash on startup, creating an unbreakable Denial-of-Service crash loop.
  4. Even when errors are caught via `catch` in `inspectAssetAsync`, line 336 only sets `existing.state = .failed(...)`. `userDefaults` retains the corrupt path, `assets[kind]` retains the unverified URL, and `startSession()` attempts to invoke Renode with the broken file.

---

## 2. Logic Chain

1. **Premise 1**: Intel HEX record format specification dictates that each record starts with ASCII `:` (`0x3A`), followed by 2 hex digits (`LL`, byte count), 4 hex digits (`AAAA`, address), 2 hex digits (`TT`, record type), `2 * LL` hex digits (data), and 2 hex digits (two's complement checksum `CC`). The minimum length of any valid record is 11 ASCII characters (`:00000001FF\n`), all characters after `:` must be hexadecimal `[0-9A-Fa-f]`, `TT` must be in `0x00...0x05`, and the modulo-256 sum of all byte values must equal `0`.
2. **Observation from Premise 1**: Checking only `headerData.first == 0x3A` in `RenodeScriptGenerator.detectFormat` tests only 1 byte out of the required record structure. It matches any arbitrary file starting with `:`, including Renode scripts (`:name:`), Markdown (`::: tip`), and raw binaries starting with byte `0x3A`.
3. **Inference 1**: By expanding the inspection buffer to 1024 bytes, ignoring leading comment lines (`#` and `;`), and validating record length (`11 + 2 * LL`), character set (`[0-9A-Fa-f]`), record type (`0x00...0x05`), and two's complement checksum (`sum % 256 == 0`), non-HEX files are 100% distinguished from Intel HEX files, eliminating false classifications.
4. **Premise 2**: In `EmulatorSession.swift`, state persistence preserves asset paths across restarts. If a persisted path points to an invalid, corrupted, or unreadable asset:
   - If inspection traps (runtime fatal error), the process crashes on every launch.
   - If inspection fails, the broken file remains registered, causing downstream emulation startup failures.
5. **Inference 2**: Startup inspection must be isolated and defensive:
   - Use `AssetInspector.inspectSafe` or `do/catch` with structured fallback.
   - When startup inspection returns `nil` or throws:
     a. Immediately purge the invalid key from `UserDefaults`: `userDefaults.removeObject(forKey: kind.userDefaultsKey)`.
     b. Automatically fall back to the known-good embedded default asset: `loadDefaultAsset(kind: kind)`.
     c. Set a non-fatal `errorMessage` explaining the fallback.
   - This breaks any persistence loop and guarantees the host application always starts in a clean, working state.

---

## 3. Caveats

1. **Read-Only Explorer Scope**: In accordance with the Explorer archetype rules, no changes have been committed directly to the production source code. Concrete, ready-to-apply code patches are documented below for the implementer / worker.
2. **File Permissions**: If an asset file has no read permissions (`chmod 000`), `FileHandle` open fails and `detectFormat` falls back to file extension, which is appropriate.
3. **Large HEX Line Length**: Maximum Intel HEX line length with 255 data bytes is 521 characters. Reading 1024 bytes in `detectFormat` guarantees that any complete first record is captured even with comment headers.

---

## 4. Conclusion & Recommended Fix Strategy

### 4.1 Fix 1: Hardened Intel HEX Detection in `RenodeScriptGenerator.swift`

Add private helper functions `isValidIntelHexRecord` and `isIntelHexHeader`, and update `detectFormat`:

```swift
    private static func isValidIntelHexRecord(_ line: String) -> Bool {
        guard line.starts(with: ":"), line.count >= 11 else { return false }
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        let payload = line.dropFirst()
        guard payload.unicodeScalars.allSatisfy({ hexChars.contains($0) }) else { return false }
        
        let llStart = line.index(line.startIndex, offsetBy: 1)
        let llEnd = line.index(llStart, offsetBy: 2)
        guard let byteCount = UInt8(String(line[llStart..<llEnd]), radix: 16) else { return false }
        
        let ttStart = line.index(line.startIndex, offsetBy: 7)
        let ttEnd = line.index(ttStart, offsetBy: 2)
        guard let recordType = UInt8(String(line[ttStart..<ttEnd]), radix: 16), recordType <= 0x05 else { return false }
        
        // Type-specific byte count validations
        if recordType == 0x01 && byteCount != 0 { return false } // EOF
        if (recordType == 0x02 || recordType == 0x04) && byteCount != 2 { return false } // Ext Segment / Linear Addr
        if (recordType == 0x03 || recordType == 0x05) && byteCount != 4 { return false } // Start Segment / Linear Addr
        
        let expectedLength = 11 + 2 * Int(byteCount)
        guard line.count == expectedLength else { return false }
        
        // Verify Intel HEX checksum (sum of all bytes mod 256 == 0)
        var sum: UInt32 = 0
        var currentIndex = line.index(after: line.startIndex)
        while currentIndex < line.endIndex {
            guard let nextIndex = line.index(currentIndex, offsetBy: 2, limitedBy: line.endIndex) else { return false }
            guard let byteVal = UInt8(String(line[currentIndex..<nextIndex]), radix: 16) else { return false }
            sum += UInt32(byteVal)
            currentIndex = nextIndex
        }
        return sum % 256 == 0
    }

    private static func isIntelHexHeader(_ data: Data) -> Bool {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return false
        }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.starts(with: "#") && !$0.starts(with: ";") }
        guard let firstLine = lines.first else { return false }
        return isValidIntelHexRecord(firstLine)
    }

    public static func detectFormat(path: String) -> BinaryFormat {
        if let fileHandle = FileHandle(forReadingAtPath: path) {
            defer { try? fileHandle.close() }
            if let headerData = try? fileHandle.read(upToCount: 1024), !headerData.isEmpty {
                // ELF magic: 0x7F, 'E', 'L', 'F'
                if headerData.count >= 4 &&
                    headerData[0] == 0x7F &&
                    headerData[1] == 0x45 &&
                    headerData[2] == 0x4C &&
                    headerData[3] == 0x46 {
                    return .elf
                }
                
                // Intel HEX: hardened structure and checksum check
                if isIntelHexHeader(headerData) {
                    return .hex
                }
            }
        }
        
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "elf", "axf":
            return .elf
        case "hex", "ihex":
            return .hex
        default:
            return .binary
        }
    }
```

### 4.2 Fix 2: Bounds-Safe Indexing in `AssetInspector.swift`

In `AssetInspector.swift:parseIntelHexHeader`, replace unbounded `line.index` calculations:

```swift
            if recordType == 0x04 { // Extended Linear Address
                guard line.count >= 13,
                      let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
                      let dataEnd = line.index(dataStart, offsetBy: 4, limitedBy: line.endIndex),
                      let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) else { continue }
                baseAddress = highWord << 16
            } else if recordType == 0x05 { // Start Linear Address (Entry Point)
                guard line.count >= 17,
                      let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
                      let dataEnd = line.index(dataStart, offsetBy: 8, limitedBy: line.endIndex),
                      let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) else { continue }
                entryPoint = entry
            }
```

### 4.3 Fix 3: Startup Crash Loop Prevention in `EmulatorSession.swift`

1. In `loadInitialAssets()`: Replace direct call to `inspectAssetAsync` for custom paths with a dedicated safe startup inspection handler:
```swift
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
```

2. In `inspectAssetAsync`: If inspection fails for a custom asset during runtime, purge the corrupted path from `UserDefaults`:
```swift
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
```

---

## 5. Verification Method

### 5.1 Verification Commands
1. **Empirical Challenger Harness**:
```bash
swiftc -parse-as-library \
  Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift \
  Software/macOS_App/scripts/empirical_challenger_harness.swift \
  -o /tmp/run_empirical_challenger && /tmp/run_empirical_challenger
```
Expected Result: All 32 tests pass (0 failures, Verdict: APPROVE).

2. **Format Detection Test Suite**:
Verify with test script containing:
- Renode script `:name: F91_Jepler` -> evaluates to `.binary` (not `.hex`).
- Raw binary with first byte `0x3A` -> evaluates to `.binary` (not `.hex`).
- Intel HEX with comment `# ...` followed by `:...` -> evaluates to `.hex`.
- Truncated `:0000000400` -> rejected as valid HEX header.

3. **Startup Crash Loop Test**:
Set a bad path in `UserDefaults`:
```bash
defaults write com.jepler.emulator jepler.custom.appBin.path "/tmp/adv_hex_bug.hex"
```
Launch `EmulatorSession`:
- Verify no crash occurs.
- Verify `userDefaults` key `jepler.custom.appBin.path` is cleared.
- Verify `assets[.appFirmware]` automatically reloads default `app.signed.bin`.
- Verify subsequent launch opens cleanly with defaults.

4. **Project Build**:
```bash
cd Software/macOS_App && swift build
```
Expected Result: Build completes with zero errors.
