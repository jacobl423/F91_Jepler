# Explorer Investigation & Handoff Report: Milestone 1 Iteration 2

- **Agent**: Explorer M1 Iteration 2 Agent 1 (String Bounds & Intel HEX Explorer)
- **Target File**: `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`
- **Secondary Target**: `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift`
- **Date**: 2026-10-05T20:42:00Z
- **Working Directory**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_1`

---

## 1. Observation

### Empirical Test Execution & Observed Failures
The empirical test suite located at `Software/macOS_App/scripts/empirical_challenger_harness.swift` was compiled and executed against the existing codebase:

```bash
swiftc -parse-as-library \
  Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift \
  Software/macOS_App/scripts/empirical_challenger_harness.swift \
  -o /tmp/run_empirical_challenger && /tmp/run_empirical_challenger
```

**Results**:
- Total Tests: **32**
- Passed: **28**
- Failed: **4** (Verdict: `REJECT (Vulnerabilities Detected)`)

The 4 failing tests were:
1. `Bug 1`: Truncated Type 04 Record (`:0000000400`)
2. `Bug 2`: Truncated Type 05 Record (`:0000000500`, length 11)
3. `Bug 3`: Incomplete Type 05 Record (`:040000050800`, length 13)
4. `Bug 4`: Multiline file with valid record followed by corrupt Type 04 line (`:020000040800F2\n:0000000400\n`)

### Verbatim Runtime Error Output
In all 4 cases, the process aborted abruptly with:
```
Swift/StringCharacterView.swift:158: Fatal error: String index is out of bounds
Trace/BPT trap: 5 (exit code 133 / 5)
```

### Exact Code In Question
In `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift:330-355`:

```swift
330:             guard line.starts(with: ":"), line.count >= 11 else { continue }
331:             let linePayload = line.dropFirst()
332:             guard linePayload.unicodeScalars.allSatisfy({ hexChars.contains($0) }) else { continue }
333: 
334:             let typeIndex = line.index(line.startIndex, offsetBy: 7)
335:             let typeEnd = line.index(typeIndex, offsetBy: 2)
336:             let typeStr = String(line[typeIndex..<typeEnd])
337:             guard let recordType = UInt8(typeStr, radix: 16), recordType <= 0x05 else { continue }
338: 
339:             recordCount += 1
340:             hasValidHex = true
341: 
342:             if recordType == 0x04 { // Extended Linear Address
343:                 let dataStart = line.index(line.startIndex, offsetBy: 9)
344:                 let dataEnd = line.index(dataStart, offsetBy: 4)
345:                 if dataEnd <= line.endIndex, let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
346:                     baseAddress = highWord << 16
347:                 }
348:             } else if recordType == 0x05 { // Start Linear Address (Entry Point)
349:                 let dataStart = line.index(line.startIndex, offsetBy: 9)
350:                 let dataEnd = line.index(dataStart, offsetBy: 8)
351:                 if dataEnd <= line.endIndex, let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
352:                     entryPoint = entry
353:                 }
354:             }
```

### Additional Observation: `RenodeScriptGenerator.swift`
In `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift:28-31`:
```swift
28:                 // Intel HEX: starts with ASCII ':' (0x3A)
29:                 if headerData.first == 0x3A {
30:                     return .hex
31:                 }
```
Any arbitrary text file or Renode `.resc` script that begins with `:` (e.g. `:name: F91_Jepler`) is prematurely classified as `.hex`, causing the script generator to emit `sysbus LoadHEX` instead of falling back to the file extension.

---

## 2. Logic Chain

1. **Underlying Swift String Mechanics**:
   - In Swift, calling `collection.index(_:offsetBy:)` asserts that the resulting index must not exceed `collection.endIndex`.
   - If `offsetBy` moves past `collection.endIndex`, Swift immediately fires an uncatchable `fatalError` ("String index is out of bounds"), terminating the process via `SIGTRAP 5`.
   - The subsequent conditional `if dataEnd <= line.endIndex` in lines 345 and 351 is dead code because the calculation on line 344 or 350 crashes before reaching the check.

2. **Analysis of Truncated Type 04 Record**:
   - Record type 04 is an Extended Linear Address record (`:02000004HHHHCC`).
   - Line 330 admits any line where `line.count >= 11`.
   - On a line with `count == 11` (such as `:0000000400`), `dataStart` is calculated as `line.startIndex + 9` (valid, since 9 < 11).
   - Line 344 then executes `line.index(dataStart, offsetBy: 4)`. This requires index `9 + 4 = 13`.
   - Because `line.count == 11`, `line.endIndex` is index 11. Index 13 is out of bounds, so Swift triggers a fatal runtime crash.

3. **Analysis of Truncated Type 05 Record**:
   - Record type 05 is a Start Linear Address record (`:04000005EEEEEEEECC`).
   - On a line with `count` between 11 and 16 (such as `:0000000500` [len 11] or `:040000050800` [len 13]), `dataStart` is index 9.
   - Line 350 executes `line.index(dataStart, offsetBy: 8)`. This requires index `9 + 8 = 17`.
   - Because `line.endIndex` is <= 16, index 17 is out of bounds, triggering the same fatal crash.

4. **Analysis of Denial-of-Service Startup Crash Loop**:
   - `EmulatorSession.swift:264-276` persists custom asset paths to `UserDefaults` (e.g. `"jepler.custom.appBin.path"`).
   - On application startup, `loadInitialAssets()` reads these paths and immediately kicks off asynchronous inspection via `inspectAssetAsync`.
   - Because `fatalError` terminates the entire process (and cannot be caught by `try?` or Swift structured concurrency error boundaries), the app crashes on launch in an infinite loop until `UserDefaults` is manually cleared.

5. **Design of Dual Defense-in-Depth Solution**:
   - **Layer 1: Explicit Line Length Guards**:
     - For Type 04: The payload starts at index 9 and requires 4 hex characters -> require `line.count >= 13`.
     - For Type 05: The payload starts at index 9 and requires 8 hex characters -> require `line.count >= 17`.
   - **Layer 2: Safe Bounds Navigation with `limitedBy: line.endIndex`**:
     - All `line.index(..., offsetBy: N)` calls must include `limitedBy: line.endIndex`.
     - When offset exceeds `line.endIndex`, `limitedBy:` returns `nil` instead of crashing.
     - Wrapping the calls in `guard let ... else { continue }` guarantees that truncated, corrupt, or adversarial lines are cleanly skipped.
   - **Layer 3: Record Type Parsing Bounds**:
     - For `typeIndex` (offset 7) and `typeEnd` (offset 9), also use `limitedBy: line.endIndex` to protect against any edge case where `line.count` could be altered.

---

## 3. Caveats

1. **Checksum Validation Scope**:
   - `AssetInspector` is a non-blocking UI metadata inspection engine reading up to 8 KB for instant display badging, not an authoritative hex flashing parser.
   - It validates that every character following `:` is a valid hexadecimal character (`[0-9A-Fa-f]`), and checks valid record types (`0x00...0x05`). It does not compute two's complement checksums across the entire file. This is intentional and optimal for UI responsiveness.
2. **Read-Only Scope**:
   - As an explorer agent, no project source code in `Software/macOS_App` has been directly modified.
   - Machine-applicable `.patch` files and proposed replacement files have been placed in this agent's folder for the worker agent to apply cleanly.

---

## 4. Conclusion

### Core Finding
The fatal runtime crash and persistent denial-of-service startup loop are 100% caused by unchecked `line.index(dataStart, offsetBy: 4)` (for record type 0x04) and `line.index(dataStart, offsetBy: 8)` (for record type 0x05) in `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift:343-354`.

### Proposed Drop-In Fix for `AssetInspector.swift`

Replace lines 334–354 in `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`:

```swift
<<<<<<< BEFORE (Lines 334-354)
            let typeIndex = line.index(line.startIndex, offsetBy: 7)
            let typeEnd = line.index(typeIndex, offsetBy: 2)
            let typeStr = String(line[typeIndex..<typeEnd])
            guard let recordType = UInt8(typeStr, radix: 16), recordType <= 0x05 else { continue }

            recordCount += 1
            hasValidHex = true

            if recordType == 0x04 { // Extended Linear Address
                let dataStart = line.index(line.startIndex, offsetBy: 9)
                let dataEnd = line.index(dataStart, offsetBy: 4)
                if dataEnd <= line.endIndex, let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
                    baseAddress = highWord << 16
                }
            } else if recordType == 0x05 { // Start Linear Address (Entry Point)
                let dataStart = line.index(line.startIndex, offsetBy: 9)
                let dataEnd = line.index(dataStart, offsetBy: 8)
                if dataEnd <= line.endIndex, let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
                    entryPoint = entry
                }
            }
=======
>>>>>>> AFTER (Proposed Replacement)
            guard let typeIndex = line.index(line.startIndex, offsetBy: 7, limitedBy: line.endIndex),
                  let typeEnd = line.index(typeIndex, offsetBy: 2, limitedBy: line.endIndex) else {
                continue
            }
            let typeStr = String(line[typeIndex..<typeEnd])
            guard let recordType = UInt8(typeStr, radix: 16), recordType <= 0x05 else { continue }

            recordCount += 1
            hasValidHex = true

            if recordType == 0x04 { // Extended Linear Address
                guard line.count >= 13,
                      let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
                      let dataEnd = line.index(dataStart, offsetBy: 4, limitedBy: line.endIndex) else {
                    continue
                }
                if let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
                    baseAddress = highWord << 16
                }
            } else if recordType == 0x05 { // Start Linear Address (Entry Point)
                guard line.count >= 17,
                      let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
                      let dataEnd = line.index(dataStart, offsetBy: 8, limitedBy: line.endIndex) else {
                    continue
                }
                if let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
                    entryPoint = entry
                }
            }
>>>>>>>
```

### Recommended Companion Hardening for `RenodeScriptGenerator.swift`

In `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift:28-31`:

```swift
<<<<<<< BEFORE
                // Intel HEX: starts with ASCII ':' (0x3A)
                if headerData.first == 0x3A {
                    return .hex
                }
=======
>>>>>>> AFTER
                // Intel HEX: starts with ASCII ':' (0x3A) and followed by hexadecimal characters
                if headerData.count >= 11 && headerData[0] == 0x3A {
                    let hexChars = Set("0123456789ABCDEFabcdef".utf8)
                    if headerData[1..<min(headerData.count, 11)].allSatisfy({ hexChars.contains($0) }) {
                        return .hex
                    }
                }
>>>>>>>
```

### Delivered Artifacts
The following artifacts are available in `.agents/teamwork/explorer_m1_it2_1/`:
1. `asset_inspector_bounds.patch`: Machine-applicable patch for `AssetInspector.swift`.
2. `renode_script_generator_hardening.patch`: Machine-applicable patch for `RenodeScriptGenerator.swift`.
3. `proposed_AssetInspector.swift`: Full drop-in replacement file for `AssetInspector.swift`.
4. `proposed_RenodeScriptGenerator.swift`: Full drop-in replacement file for `RenodeScriptGenerator.swift`.

---

## 5. Verification Method

### 1. Dry Run Patch Application
Verify that the patch applies cleanly to the repository:
```bash
patch --dry-run Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  .agents/teamwork/explorer_m1_it2_1/asset_inspector_bounds.patch
```
Expected output:
```
patching file 'Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift'
```
Exit code: `0`.

### 2. Apply Patch
```bash
patch Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  .agents/teamwork/explorer_m1_it2_1/asset_inspector_bounds.patch
```

### 3. Run Challenger Test Harness
Execute the full test harness:
```bash
swiftc -parse-as-library \
  Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift \
  Software/macOS_App/scripts/empirical_challenger_harness.swift \
  -o /tmp/run_empirical_challenger && /tmp/run_empirical_challenger
```

**Expected Outcome**:
```
==================================================================
 EMPIRICAL CHALLENGE HARNESS COMPLETE
 Total Tests Run: 32
 Passed: 32
 Failed: 0
 Verdict: APPROVE
==================================================================
```

### 4. Build Verification
Verify that the macOS App SPM package builds cleanly:
```bash
cd Software/macOS_App && swift build
```
Expected output:
```
Build complete! (0.24 sec)
```

### 5. Invalidation Conditions
- If any adversarial record such as `:0000000400` or `:0000000500` causes an exit code other than 0 or triggers `SIGTRAP`.
- If valid repository Intel HEX files (e.g. `zephyr/.../blaster_6810.hex`) fail to extract base address or line count.
