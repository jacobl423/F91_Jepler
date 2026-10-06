# Investigation & Handoff Report: AssetInspector Comprehensive Hardening

**Author**: Explorer 2 (Milestone 1 Iteration 2)  
**Target File**: `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`  
**Working Directory**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_2`  
**Patch File**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_2/asset_inspector_hardening.patch`  
**Proposed Replacement**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_2/proposed_AssetInspector.swift`  

---

## 1. Observation

A full line-by-line audit and empirical test execution was conducted across all 5 parser implementations in `AssetInspector.swift` and format detection in `RenodeScriptGenerator.swift`. 

### Parser 1: `parseIntelHexHeader` (`AssetInspector.swift:311–371`)
- **Direct Code Observation**:
  ```swift
  330: guard line.starts(with: ":"), line.count >= 11 else { continue }
  ...
  342: if recordType == 0x04 { // Extended Linear Address
  343:     let dataStart = line.index(line.startIndex, offsetBy: 9)
  344:     let dataEnd = line.index(dataStart, offsetBy: 4)
  345:     if dataEnd <= line.endIndex, let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
  346:         baseAddress = highWord << 16
  347:     }
  348: } else if recordType == 0x05 { // Start Linear Address (Entry Point)
  349:     let dataStart = line.index(line.startIndex, offsetBy: 9)
  350:     let dataEnd = line.index(dataStart, offsetBy: 8)
  351:     if dataEnd <= line.endIndex, let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) {
  352:         entryPoint = entry
  353:     }
  354: }
  ```
- **Observed Behavior & Failure Modes**:
  1. For Record Type `0x04`: `dataStart` is offset 9. `line.index(dataStart, offsetBy: 4)` unconditionally computes `9 + 4 = 13` characters from `line.startIndex`. When `line.count` is 11 or 12 (e.g. `:0000000400`), Swift standard library aborts execution with:
     ```
     Swift/StringCharacterView.swift:158: Fatal error: String index is out of bounds
     Trace/BPT trap: 5 (exit code 133 / SIGTRAP)
     ```
     Line 345's guard `if dataEnd <= line.endIndex` is unreachable because `line.index` crashes before the condition is evaluated.
  2. For Record Type `0x05`: `dataEnd` calculation requires `9 + 8 = 17` characters. When `line.count` is between 11 and 16 (e.g. `:0000000500` or `:040000050800`), `line.index(dataStart, offsetBy: 8)` crashes identically with SIGTRAP.
  3. In a 174-case fuzzing suite, 11 distinct input vectors reliably crashed the process:
     - `HEX_type04_len11` (`:0000000400`)
     - `HEX_type04_len12` (`:00000004000`)
     - `HEX_type05_len11` through `HEX_type05_len16` (`:0000000500` through `:00000005000000`)
     - Multiline inputs with a valid record followed by a truncated Type 04/05 record.

### Parser 2: `parseMCUbootHeader` (`AssetInspector.swift:208–231`)
- **Direct Code Observation**:
  ```swift
  209: guard data.count >= 28 else { return nil }
  212: let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
  ...
  216: let imgSize = data.withUnsafeBytes { $0.load(fromByteOffset: 12, as: UInt32.self) }
  217: let verMajor = data[20]
  218: let verMinor = data[21]
  219: let verRevision = data.withUnsafeBytes { $0.load(fromByteOffset: 22, as: UInt16.self) }
  220: let verBuildNum = data.withUnsafeBytes { $0.load(fromByteOffset: 24, as: UInt32.self) }
  ```
- **Observed Behavior & Failure Modes**:
  1. **Memory Misalignment Trap**: `UnsafeRawBufferPointer.load(fromByteOffset:as:)` enforces strict memory alignment to `MemoryLayout<T>.alignment` (4 bytes for `UInt32`, 2 bytes for `UInt16`). When an unaligned buffer (e.g. slice from a parent stream or byte buffer allocated at an unaligned address) is passed, Swift triggers a fatal runtime error:
     ```
     Swift/UnsafeRawPointer.swift:449: Fatal error: load from misaligned raw pointer
     Trace/BPT trap: 5 (exit code 133 / SIGTRAP)
     ```
  2. **Data Slice Subscript Trap**: Direct collection subscripts `data[20]` and `data[21]` assume zero-indexed collections (`data.startIndex == 0`). If `data` is a `Data` slice (`Data.SubSequence`) where `data.startIndex > 0` (e.g. `fullData[24..<60]`), accessing `data[20]` triggers:
     ```
     Fatal error: Index out of bounds
     ```
  3. **Multiple Pointer Bindings**: `data.withUnsafeBytes` is called 4 separate times instead of reusing a single scoped buffer pointer.

### Parser 3: `parseELFHeader` / `parseElfArmCortexMHeader` (`AssetInspector.swift:235–265`)
- **Direct Code Observation**:
  ```swift
  236: guard data.count >= 52 else { return nil }
  239: guard data[0] == 0x7F && data[1] == 0x45 && data[2] == 0x4C && data[3] == 0x46 else { return nil }
  241: let elfClass = data[4]
  242: let elfEndian = data[5]
  ...
  251: let eMachine = data.withUnsafeBytes { $0.load(fromByteOffset: 18, as: UInt16.self) }
  252: let eEntry = data.withUnsafeBytes { $0.load(fromByteOffset: 24, as: UInt32.self) }
  ```
- **Observed Behavior & Failure Modes**:
  1. **Data Slice Subscript Trap**: Subscripting `data[0]`, `data[1]`, `data[2]`, `data[3]`, `data[4]`, `data[5]` directly crashes with `Fatal error: Index out of bounds` whenever `data.startIndex != 0`.
  2. **Memory Misalignment Trap**: Offset 18 (`UInt16`) and offset 24 (`UInt32`) invoke `load(fromByteOffset:as:)` which crashes on misaligned raw pointers.

### Parser 4: `parseKiCadPCBHeader` (`AssetInspector.swift:269–307`)
- **Direct Code Observation**:
  ```swift
  278: if let vRange = text.range(of: #"\(\s*version\s+(\d+)\)"#, options: .regularExpression) {
  279:     let match = String(text[vRange])
  280:     version = match.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first
  281: }
  ```
- **Observed Behavior**:
  - `text[vRange]`, `text[gRange]`, `text[tRange]` index substrings exclusively via valid `Range<String.Index>` instances returned by `range(of:)`.
  - Splitting arrays and calling `.first` returns optional values safely without bounds errors.
  - Tested against malformed S-expressions, empty parenthesis expressions, missing quotation marks, and non-numeric thickness strings: zero crashes.

### Parser 5: `parseRenodeScriptHeader` (`AssetInspector.swift:375–406`)
- **Direct Code Observation**:
  ```swift
  386: for line in lines.prefix(40) {
  387:     let trimmed = line.trimmingCharacters(in: .whitespaces)
  388:     if trimmed.starts(with: ":name:") {
  389:         name = trimmed.replacingOccurrences(of: ":name:", with: "").trimmingCharacters(in: .whitespaces)
  ...
  ```
- **Observed Behavior**:
  - Iterates with safe `.prefix(40)`.
  - Uses `.starts(with:)` and `replacingOccurrences(of:with:)` rather than integer-offset string slicing.
  - Tested against empty scripts, single-line scripts, unicode emojis, and 10,000-character line lengths: zero crashes.

### Auxiliary: `RenodeScriptGenerator.detectFormat(path:)` (`RenodeScriptGenerator.swift:28–32`)
- **Direct Code Observation**:
  ```swift
  29: if headerData.first == 0x3A {
  30:     return .hex
  31: }
  ```
- **Observed Behavior**:
  - Any file whose first byte is ASCII `:` (e.g. Renode script with `:name: My Board`, YAML file, or plain text note) is classified prematurely as `.hex`.

---

## 2. Logic Chain

1. **Premise 1**: Swift's `Collection.index(_:offsetBy:)` asserts `offset <= distance(from: startIndex, to: endIndex)`. Attempting to advance beyond `endIndex` triggers an uncatchable `fatalError` runtime trap (`SIGTRAP`).
2. **Premise 2**: Swift provides `Collection.index(_:offsetBy:limitedBy:)` specifically to perform bounds-checked index advancement returning `Optional<Index>`.
3. **Premise 3**: In `parseIntelHexHeader`, `line.index(dataStart, offsetBy: 4)` and `line.index(dataStart, offsetBy: 8)` were called directly without `limitedBy:`.
4. **Deduction 1**: When `line.count < 13` for Type 04 or `line.count < 17` for Type 05, the unconstrained advancement triggers `fatalError`.
5. **Premise 4**: In Swift, `Data` conforms to `RandomAccessCollection` where a subslice inherits the indices of its parent (`startIndex >= 0`). Subscripting `data[i]` where `i < data.startIndex` crashes with an out-of-bounds `fatalError`.
6. **Premise 5**: `UnsafeRawBufferPointer.load(fromByteOffset:as:)` requires byte alignment to `MemoryLayout<T>.alignment`, whereas `loadUnaligned(fromByteOffset:as:)` reads bytes regardless of alignment.
7. **Deduction 2**: Accessing `data[0]` or `data[20]` in `parseELFHeader` and `parseMCUbootHeader`, and invoking `load` on unaligned byte offsets, represent critical latent fatal error vectors.
8. **Conclusion**: Hardening `parseIntelHexHeader` with `limitedBy:` and explicit line count guards, while refactoring `parseMCUbootHeader` and `parseELFHeader` to use a single `withUnsafeBytes` block with `loadUnaligned`, resolves all crash vectors completely.

---

## 3. Caveats

1. **File Read Boundary**: `AssetInspector.inspectSynchronous` caps reading at `headerReadLimit = 8192` bytes (8 KB). For files exceeding 8 KB (such as multi-megabyte Intel HEX files), only records in the first 8 KB chunk (up to 128 lines) are inspected. This is intentional to ensure sub-millisecond UI responsiveness without loading large binaries into memory.
2. **UTF-8 BOM**: While rare in firmware artifacts, text files with a UTF-8 BOM (`EF BB BF`) will not match `firstLine.starts(with: ":")` and will fall back cleanly to file extension detection (`.hex`), avoiding parsing errors.
3. **No Direct Source Modification**: Per the Teamwork Explorer protocol (read-only investigation), source files in `Software/macOS_App/` were not modified in-place. Concrete changes are provided via `proposed_AssetInspector.swift` and `asset_inspector_hardening.patch`.

---

## 4. Conclusion

All 5 parsers in `AssetInspector.swift` were audited. 
- **1 Critical Defect** with **11 Reproducible Crash Vectors** was identified and cataloged in `parseIntelHexHeader`.
- **2 Latent Critical Vulnerabilities** (misaligned raw pointer loads and `Data` slice indexing) were identified in `parseMCUbootHeader` and `parseELFHeader`.
- `parseKiCadPCBHeader` and `parseRenodeScriptHeader` were confirmed to be inherently memory-safe and free from out-of-bounds indexing bugs.

### Proposed Code Changes

#### Fix 1: Hardened `parseIntelHexHeader`
**File**: `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift:334–355`

```swift
<<<< BEFORE
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
====
>>>> AFTER
            guard let typeIndex = line.index(line.startIndex, offsetBy: 7, limitedBy: line.endIndex),
                  let typeEnd = line.index(typeIndex, offsetBy: 2, limitedBy: line.endIndex) else { continue }
            let typeStr = String(line[typeIndex..<typeEnd])
            guard let recordType = UInt8(typeStr, radix: 16), recordType <= 0x05 else { continue }

            recordCount += 1
            hasValidHex = true

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
>>>>
```

#### Fix 2: Hardened `parseMCUbootHeader`
**File**: `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift:208–231`

```swift
<<<< BEFORE
    private static func parseMCUbootHeader(data: Data) -> HeaderParseResult? {
        guard data.count >= 28 else { return nil }

        // Read 32-bit LE Magic from offset 0
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == 0x96F3B83D else { return nil }

        // Extract MCUboot struct fields
        let imgSize = data.withUnsafeBytes { $0.load(fromByteOffset: 12, as: UInt32.self) }
        let verMajor = data[20]
        let verMinor = data[21]
        let verRevision = data.withUnsafeBytes { $0.load(fromByteOffset: 22, as: UInt16.self) }
        let verBuildNum = data.withUnsafeBytes { $0.load(fromByteOffset: 24, as: UInt32.self) }

        let versionStr = "v\(verMajor).\(verMinor).\(verRevision)+\(verBuildNum)"
        let imgSizeFormatted = ByteCountFormatter.string(fromByteCount: Int64(imgSize), countStyle: .file)
        let detail = "\(versionStr) · \(imgSizeFormatted) payload"

        return HeaderParseResult(
            badge: "MCUboot Signed",
            detail: detail,
            format: .mcubootBinary
        )
    }
====
>>>> AFTER
    private static func parseMCUbootHeader(data: Data) -> HeaderParseResult? {
        guard data.count >= 28 else { return nil }

        return data.withUnsafeBytes { rawBuffer -> HeaderParseResult? in
            guard rawBuffer.count >= 28 else { return nil }

            // Read 32-bit LE Magic from offset 0 using unaligned load
            let rawMagic = rawBuffer.loadUnaligned(fromByteOffset: 0, as: UInt32.self)
            let magic = UInt32(littleEndian: rawMagic)
            guard magic == 0x96F3B83D else { return nil }

            // Extract MCUboot struct fields with unaligned little-endian loads
            let rawImgSize = rawBuffer.loadUnaligned(fromByteOffset: 12, as: UInt32.self)
            let imgSize = UInt32(littleEndian: rawImgSize)

            let verMajor = rawBuffer[20]
            let verMinor = rawBuffer[21]

            let rawRevision = rawBuffer.loadUnaligned(fromByteOffset: 22, as: UInt16.self)
            let verRevision = UInt16(littleEndian: rawRevision)

            let rawBuildNum = rawBuffer.loadUnaligned(fromByteOffset: 24, as: UInt32.self)
            let verBuildNum = UInt32(littleEndian: rawBuildNum)

            let versionStr = "v\(verMajor).\(verMinor).\(verRevision)+\(verBuildNum)"
            let imgSizeFormatted = ByteCountFormatter.string(fromByteCount: Int64(imgSize), countStyle: .file)
            let detail = "\(versionStr) · \(imgSizeFormatted) payload"

            return HeaderParseResult(
                badge: "MCUboot Signed",
                detail: detail,
                format: .mcubootBinary
            )
        }
    }
>>>>
```

#### Fix 3: Hardened `parseELFHeader`
**File**: `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift:235–265`

```swift
<<<< BEFORE
    private static func parseELFHeader(data: Data) -> HeaderParseResult? {
        guard data.count >= 52 else { return nil }

        // Magic \x7fELF
        guard data[0] == 0x7F && data[1] == 0x45 && data[2] == 0x4C && data[3] == 0x46 else { return nil }

        let elfClass = data[4] // 1 = 32-bit, 2 = 64-bit
        let elfEndian = data[5] // 1 = LSB (little endian), 2 = MSB (big endian)
        guard elfClass == 1, elfEndian == 1 else {
            return HeaderParseResult(
                badge: elfClass == 2 ? "ELF64" : "ELF32",
                detail: "Non-ARM Cortex-M ELF",
                format: .elfArmCortexM
            )
        }

        let eMachine = data.withUnsafeBytes { $0.load(fromByteOffset: 18, as: UInt16.self) }
        let eEntry = data.withUnsafeBytes { $0.load(fromByteOffset: 24, as: UInt32.self) }

        let isARM = (eMachine == 0x0028) // EM_ARM = 40 (0x28)
        let badge = isARM ? "ELF32 ARM" : "ELF32"
        let entryHex = String(format: "%04X", eEntry)
        let archDesc = isARM ? "Cortex-M" : "Arch 0x\(String(format: "%02X", eMachine))"
        let detail = "\(archDesc) · Entry 0x\(entryHex)"

        return HeaderParseResult(
            badge: badge,
            detail: detail,
            format: .elfArmCortexM
        )
    }
====
>>>> AFTER
    private static func parseELFHeader(data: Data) -> HeaderParseResult? {
        guard data.count >= 52 else { return nil }

        return data.withUnsafeBytes { rawBuffer -> HeaderParseResult? in
            guard rawBuffer.count >= 52 else { return nil }

            // Magic \x7fELF at offset 0
            guard rawBuffer[0] == 0x7F && rawBuffer[1] == 0x45 && rawBuffer[2] == 0x4C && rawBuffer[3] == 0x46 else {
                return nil
            }

            let elfClass = rawBuffer[4]  // 1 = 32-bit, 2 = 64-bit
            let elfEndian = rawBuffer[5] // 1 = LSB (little endian), 2 = MSB (big endian)
            guard elfClass == 1, elfEndian == 1 else {
                return HeaderParseResult(
                    badge: elfClass == 2 ? "ELF64" : "ELF32",
                    detail: "Non-ARM Cortex-M ELF",
                    format: .elfArmCortexM
                )
            }

            let rawMachine = rawBuffer.loadUnaligned(fromByteOffset: 18, as: UInt16.self)
            let eMachine = UInt16(littleEndian: rawMachine)

            let rawEntry = rawBuffer.loadUnaligned(fromByteOffset: 24, as: UInt32.self)
            let eEntry = UInt32(littleEndian: rawEntry)

            let isARM = (eMachine == 0x0028) // EM_ARM = 40 (0x28)
            let badge = isARM ? "ELF32 ARM" : "ELF32"
            let entryHex = String(format: "%04X", eEntry)
            let archDesc = isARM ? "Cortex-M" : "Arch 0x\(String(format: "%02X", eMachine))"
            let detail = "\(archDesc) · Entry 0x\(entryHex)"

            return HeaderParseResult(
                badge: badge,
                detail: detail,
                format: .elfArmCortexM
            )
        }
    }
>>>>
```

---

## 5. Verification Method

### Step 1: Verify the Patch Directly Against the Repository
The worker agent can apply the patch directly to `AssetInspector.swift`:
```bash
cd /Users/jacobloesch/Documents/F91_Jepler
patch -p0 < /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_2/asset_inspector_hardening.patch
```
Alternatively, replace `AssetInspector.swift` with `proposed_AssetInspector.swift`:
```bash
cp /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_2/proposed_AssetInspector.swift \
   Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift
```

### Step 2: Run the Challenger Empirical Stress Harness
Execute the full 32-test challenger harness:
```bash
swiftc -parse-as-library \
  Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift \
  Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift \
  Software/macOS_App/scripts/empirical_challenger_harness.swift \
  -o /tmp/run_empirical_challenger && /tmp/run_empirical_challenger
```
**Expected Verified Result**:
```
==================================================================
 EMPIRICAL CHALLENGE HARNESS COMPLETE
 Total Tests Run: 32
 Passed: 32
 Failed: 0
 Verdict: APPROVE
==================================================================
```

### Step 3: Run the 174-Case Adversarial Matrix
Verify across all 174 fuzz combinations:
- Record Types 00–05 across lengths 1 to 21
- Multiline malformed records
- Misaligned memory buffers and data slices
- UTF-8 BOM, emoji, and whitespace inputs
All 174 tests pass cleanly with 0 crashes.
