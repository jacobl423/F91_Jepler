# Empirical Challenge Report & Handoff: Milestone 1

## Verdict: REJECT (Critical Vulnerabilities Found)

**Overall Risk Assessment**: **CRITICAL**

---

## 1. Observation

### Empirical Test Execution & Results
An automated empirical stress test suite was created and executed in `Software/macOS_App/scripts/empirical_challenger_harness.swift` using the Swift compiler (`swiftc -parse-as-library ...`).

Total tests run: **32**
- **Passed**: 28
- **Failed**: 4 (Process crashes via unhandled runtime fatal error)

### Valid Repository Assets (All Passed)
1. `Software/macOS_App/F91JeplerEmulator/Resources/Embedded/app.signed.bin`
   - Size: 145,184 bytes (145 KB)
   - Detected Badge: `"MCUboot Signed"`, Format: `.mcubootBinary`
   - Secondary Detail: `"v1.0.0+0 · 144 KB payload"`, SHA256: `133791ca`
2. `Software/macOS_App/F91JeplerEmulator/Resources/Embedded/mcuboot.elf`
   - Size: 1,479,928 bytes (1.5 MB)
   - Detected Badge: `"ELF32 ARM"`, Format: `.elfArmCortexM`
   - Secondary Detail: `"Cortex-M · Entry 0x1D09"`, SHA256: `039ce6b7`
3. `Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.resc`
   - Size: 1,262 bytes (1 KB)
   - Detected Badge: `"Renode Script"`, Format: `.renodeResc`
   - Secondary Detail: `"nRF52840 · 26 lines"`, SHA256: `64d6aa5f`
4. `Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.kicad_pcb`
   - Size: 135,107 bytes (135 KB)
   - Detected Badge: `"KiCad PCB"`, Format: `.kicadSExpr`
   - Secondary Detail: `"v20260206 · pcbnew · 0.8mm"`, SHA256: `863e8d68`
5. `zephyr/boards/intel/socfpga_std/cyclonev_socdk/support/blaster_6810.hex`
   - Size: 20,702 bytes (21 KB)
   - Detected Badge: `"Intel HEX"`, Format: `.intelHex`
   - Secondary Detail: `"Base 0x0000 · 117 recs"`, SHA256: `ede14255`

---

### Critical Defects Observed

#### Defect 1: Process Crash on Incomplete / Adversarial Intel HEX Records (Types 04 and 05)
- **File**: `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`
- **Lines**: 343–354
```swift
341:            if recordType == 0x04 { // Extended Linear Address
342:                let dataStart = line.index(line.startIndex, offsetBy: 9)
343:                let dataEnd = line.index(dataStart, offsetBy: 4)
344:                if dataEnd <= line.endIndex, let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
345:                    baseAddress = highWord << 16
346:                }
347:            } else if recordType == 0x05 { // Start Linear Address (Entry Point)
348:                let dataStart = line.index(line.startIndex, offsetBy: 9)
349:                let dataEnd = line.index(dataStart, offsetBy: 8)
350:                if dataEnd <= line.endIndex, let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
351:                    entryPoint = entry
352:                }
353:            }
```
- **Observed Behavior**:
  Line 329 only checks `guard line.starts(with: ":"), line.count >= 11 else { continue }`.
  - For Record Type 04 (Extended Linear Address), `line.index(dataStart, offsetBy: 4)` requires index `9 + 4 = 13`. If `line.count` is 11 or 12 (e.g. `:0000000400`), calling `line.index(dataStart, offsetBy: 4)` **immediately traps with SIGTRAP** before the check `if dataEnd <= line.endIndex` can ever execute.
  - For Record Type 05 (Start Linear Address), `line.index(dataStart, offsetBy: 8)` requires index `9 + 8 = 17`. If `line.count` is between 11 and 16 (e.g. `:0000000500` or `:040000050800`), calling `line.index(dataStart, offsetBy: 8)` **immediately traps with SIGTRAP**.
- **Verbatim Error Output**:
```
Swift/StringCharacterView.swift:158: Fatal error: String index is out of bounds
Trace/BPT trap: 5 (exit code 133 / 5)
```
- **Unhandled in Asynchronous & Safe Callers**:
  Even when using `AssetInspector.inspectSafe` (`try? await AssetInspector.inspect(...)`), the process crashes because a Swift `fatalError` cannot be caught by structured error handling and terminates the entire host application process.

#### Defect 2: Denial-of-Service Startup Crash Loop via Persistent State
- **File**: `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`
- **Lines**: 264–276, 320–341
- **Observed Behavior**:
  When a user selects or drops a malformed HEX/firmware file:
  1. `updateAsset(kind: .appFirmware, url:)` writes the file path to `UserDefaults.standard` under key `"jepler.custom.appBin.path"`.
  2. `inspectAssetAsync` invokes `AssetInspector.inspect`, triggering the SIGTRAP crash described in Defect 1.
  3. When the user relaunches the app, `EmulatorSession.init` reads the stored path from `UserDefaults`.
  4. Because `FileManager.default.fileExists(atPath:)` returns `true`, it immediately schedules `inspectAssetAsync(kind: kind, url: customURL, isCustom: true)`.
  5. The crash triggers again on the background cooperative pool, killing the app before the UI is rendered.
  6. The app is bricked in an infinite crash loop until `UserDefaults` is manually purged.

---

## 2. Logic Chain

1. **Premise 1**: The project specification and dispatch mandate robustness against adversarial inputs:
   *"Empirically stress-test AssetInspector.swift and SessionAsset.swift against repository binaries ... and adversarial inputs (0-byte files, corrupted headers, pseudo-hex lines, non-existent files). Verify no uncaught exceptions, hangs, or memory leaks occur."*
2. **Premise 2**: In Swift standard library, `Collection.index(_:offsetBy:)` enforces a runtime precondition that the offset must not exceed `endIndex`. Unlike C pointer arithmetic where `ptr + 4 <= end` is valid, Swift's `index(_:offsetBy:)` triggers an unconditional `fatalError` when the index calculation falls outside `startIndex...endIndex`.
3. **Premise 3**: In `AssetInspector.swift:344` and `350`, `dataEnd` is calculated using `line.index(dataStart, offsetBy: 4)` and `line.index(dataStart, offsetBy: 8)` where `dataStart = line.index(line.startIndex, offsetBy: 9)`.
4. **Observation**: Lines with `count == 11` or `12` pass line 329's guard (`count >= 11`). When `recordType == 0x04` or `recordType == 0x05`, the offset requires 13 or 17 characters respectively. Because the code calls `index(_:offsetBy:)` directly without `limitedBy:`, Swift aborts execution.
5. **Observation**: A fatal error cannot be caught by `try?` or `do-catch`.
6. **Observation**: `EmulatorSession` persists asset paths to `UserDefaults` and re-inspects them on launch.
7. **Conclusion**: The implementation violates the requirement to handle adversarial pseudo-hex lines and corrupted headers gracefully. A malformed firmware file will crash the emulator process and brick subsequent launches. Therefore, Milestone 1 must be **REJECTED**.

---

## 3. Caveats

- Repository valid assets (`app.signed.bin`, `mcuboot.elf`, `f91_jepler.resc`, `f91_jepler.kicad_pcb`, `blaster_6810.hex`) passed all inspection tests cleanly.
- 0-byte files, non-existent files, permission-denied files, and directories are handled gracefully without crashing.
- KiCad PCB S-expression parsing and Renode script directive extraction showed no crashes under malformed input.
- High-concurrency testing (50 concurrent inspections) and large file streaming (10 MB) exhibited no deadlocks or memory exhaustion.
- The defect is isolated to `AssetInspector.swift:343-354` in `parseIntelHexHeader`. Fixing this bounds calculation will make the module robust.

---

## 4. Conclusion

**Verdict: REJECT**

Milestone 1 fails adversarial robustness criteria. While baseline repository files load successfully, `AssetInspector.swift` crashes catastrophically when encountering pseudo-hex records or truncated Intel HEX lines with record types 04 or 05, leading to an application crash and persistent launch loop.

### Required Remediations for Worker:
1. In `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`:
   Replace uncapped `line.index(dataStart, offsetBy: ...)` with `limitedBy: line.endIndex`:
   ```swift
   if recordType == 0x04 { // Extended Linear Address
       guard let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
             let dataEnd = line.index(dataStart, offsetBy: 4, limitedBy: line.endIndex),
             let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) else { continue }
       baseAddress = highWord << 16
   } else if recordType == 0x05 { // Start Linear Address (Entry Point)
       guard let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
             let dataEnd = line.index(dataStart, offsetBy: 8, limitedBy: line.endIndex),
             let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) else { continue }
       entryPoint = entry
   }
   ```
2. Or validate total line length before slicing:
   - For `recordType == 0x04`: `guard line.count >= 13 else { continue }`
   - For `recordType == 0x05`: `guard line.count >= 17 else { continue }`
3. In `RenodeScriptGenerator.detectFormat(path:)`:
   Harden the Intel HEX check beyond `headerData.first == 0x3A` so non-HEX files starting with `:` are not prematurely classified as HEX.

---

## 5. Verification Method

To independently reproduce the crash and verify the failure:

### Command Line Reproduction
Run the following script from the project root:

```bash
cd /Users/jacobloesch/Documents/F91_Jepler

cat << 'EOF' > /tmp/reproduce_m1_bug.swift
import Foundation

@main
struct BugVerifier {
    static func main() async {
        let corruptFile = "/tmp/adv_hex_bug.hex"
        try? ":0000000400\n".write(toFile: corruptFile, atomically: true, encoding: .utf8)
        print("Testing AssetInspector.inspect with :0000000400...")
        do {
            let meta = try await AssetInspector.inspect(
                url: URL(fileURLWithPath: corruptFile),
                kind: .appFirmware,
                isCustom: true
            )
            print("Result: \(meta.formatBadge)")
        } catch {
            print("Caught expected error: \(error)")
        }
    }
}
EOF

swiftc -parse-as-library \
  Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  /tmp/reproduce_m1_bug.swift \
  -o /tmp/run_reproduce_bug

/tmp/run_reproduce_bug
```

### Expected Result vs. Observed Result
- **Expected Result**: Should handle malformed record without crashing, falling back to file extension or returning unknown format / throwing `AssetInspectionError`.
- **Observed Result**:
  ```
  Testing AssetInspector.inspect with :0000000400...
  Swift/StringCharacterView.swift:158: Fatal error: String index is out of bounds
  Trace/BPT trap: 5
  ```
  Exit code 133 / SIGTRAP.

### Full Harness Execution
```bash
swiftc -parse-as-library \
  Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift \
  Software/macOS_App/scripts/empirical_challenger_harness.swift \
  -o /tmp/run_empirical_challenger && /tmp/run_empirical_challenger
```
- Expected after fix: 32 tests run, 32 passed, Verdict: APPROVE.
- Current status: 4 tests failed (Bug 1, Bug 2, Bug 3, Bug 4), Verdict: REJECT.
