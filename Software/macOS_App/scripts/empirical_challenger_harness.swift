import Foundation
import CryptoKit

// Test runner for Challenger M1_1
@main
struct ChallengerStressHarness {

    static var totalTests = 0
    static var passedTests = 0
    static var failedTests = 0
    static var testLog: [String] = []

    static func log(_ msg: String) {
        print(msg)
        testLog.append(msg)
    }

    static func recordPass(_ name: String, _ detail: String = "") {
        totalTests += 1
        passedTests += 1
        log("  [PASS] \(name)\(detail.isEmpty ? "" : " - " + detail)")
    }

    static func recordFail(_ name: String, _ detail: String = "") {
        totalTests += 1
        failedTests += 1
        log("  [FAIL] \(name)\(detail.isEmpty ? "" : " - " + detail)")
    }

    static func runSubprocessTest(name: String, testCode: String) -> (exitCode: Int32, output: String) {
        let tempSwift = "/tmp/challenger_sub_\(UUID().uuidString).swift"
        let tempBin = "/tmp/challenger_sub_\(UUID().uuidString).bin"

        let wrapped = """
        import Foundation
        import CryptoKit

        @main
        struct SubTestRunner {
            static func main() async {
                do {
                    \(testCode)
                } catch {
                    print("CAUGHT_ERROR: \\(error)")
                }
            }
        }
        """

        try? wrapped.write(toFile: tempSwift, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tempSwift) }

        let compileProcess = Process()
        compileProcess.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
        compileProcess.arguments = [
            "-parse-as-library",
            "Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift",
            "Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift",
            "Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift",
            tempSwift,
            "-o", tempBin
        ]
        compileProcess.currentDirectoryURL = URL(fileURLWithPath: "/Users/jacobloesch/Documents/F91_Jepler")
        let compilePipe = Pipe()
        compileProcess.standardError = compilePipe
        compileProcess.standardOutput = compilePipe
        try? compileProcess.run()
        compileProcess.waitUntilExit()

        guard compileProcess.terminationStatus == 0 else {
            let compOut = String(data: compilePipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return (-1, "Compilation failed: " + compOut)
        }
        defer { try? FileManager.default.removeItem(atPath: tempBin) }

        let runProcess = Process()
        runProcess.executableURL = URL(fileURLWithPath: tempBin)
        runProcess.currentDirectoryURL = URL(fileURLWithPath: "/Users/jacobloesch/Documents/F91_Jepler")
        let runPipe = Pipe()
        runProcess.standardOutput = runPipe
        runProcess.standardError = runPipe
        try? runProcess.run()
        runProcess.waitUntilExit()

        let runOut = String(data: runPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (runProcess.terminationStatus, runOut)
    }

    static func main() async {
        log("==================================================================")
        log(" EMPIRICAL CHALLENGER STRESS HARNESS — MILESTONE 1")
        log(" Target: AssetInspector.swift & SessionAsset.swift")
        log(" Timestamp: \(Date())")
        log("==================================================================\n")

        // ---------------------------------------------------------------
        // SUITE 1: Valid Repository Binaries
        // ---------------------------------------------------------------
        log("--- SUITE 1: Valid Repository Assets ---")
        let repoRoot = URL(fileURLWithPath: "/Users/jacobloesch/Documents/F91_Jepler")
        let repoTests: [(path: String, kind: SessionAssetKind, expBadge: String, expFormat: DetectedAssetFormat)] = [
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/app.signed.bin", .appFirmware, "MCUboot Signed", .mcubootBinary),
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/mcuboot.elf", .bootloader, "ELF32 ARM", .elfArmCortexM),
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.resc", .rescScript, "Renode Script", .renodeResc),
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.kicad_pcb", .pcb, "KiCad PCB", .kicadSExpr),
            ("zephyr/boards/intel/socfpga_std/cyclonev_socdk/support/blaster_6810.hex", .appFirmware, "Intel HEX", .intelHex)
        ]

        for t in repoTests {
            let u = repoRoot.appendingPathComponent(t.path)
            do {
                let m = try await AssetInspector.inspect(url: u, kind: t.kind, isCustom: false)
                if m.formatBadge == t.expBadge && m.detectedFormat == t.expFormat && m.sha256Prefix?.count == 8 {
                    recordPass("Valid Repo Asset: \(m.fileName)", "Badge: \(m.formatBadge), SHA256: \(m.sha256Prefix!)")
                } else {
                    recordFail("Valid Repo Asset: \(m.fileName)", "Badge=\(m.formatBadge) (exp \(t.expBadge)), Format=\(m.detectedFormat) (exp \(t.expFormat))")
                }
            } catch {
                recordFail("Valid Repo Asset: \(t.path)", "Threw unexpected error: \(error)")
            }
        }

        // ---------------------------------------------------------------
        // SUITE 2: 0-Byte Empty Files
        // ---------------------------------------------------------------
        log("\n--- SUITE 2: 0-Byte Empty Files ---")
        let emptyExts = ["bin", "hex", "elf", "resc", "kicad_pcb", "txt", ""]
        for ext in emptyExts {
            let f = "/tmp/challenger_empty_\(ext).\(ext)"
            FileManager.default.createFile(atPath: f, contents: Data())
            let u = URL(fileURLWithPath: f)
            do {
                let m = try await AssetInspector.inspect(url: u, kind: .appFirmware, isCustom: true)
                if m.fileSizeBytes == 0 && m.formatBadge == "Empty" && m.secondaryDetail == "0 bytes" && m.sha256Prefix == nil {
                    recordPass("Empty file .\(ext)", "Returns badge: Empty, size: 0 B")
                } else {
                    recordFail("Empty file .\(ext)", "Unexpected meta: badge=\(m.formatBadge), size=\(m.fileSizeBytes)")
                }
            } catch {
                recordFail("Empty file .\(ext)", "Threw error: \(error)")
            }
            try? FileManager.default.removeItem(atPath: f)
        }

        // ---------------------------------------------------------------
        // SUITE 3: Corrupted MCUboot Headers
        // ---------------------------------------------------------------
        log("\n--- SUITE 3: Corrupted MCUboot Headers ---")
        // 3.1 Truncated MCUboot header (< 28 bytes)
        let magicBytes: [UInt8] = [0x3D, 0xB8, 0xF3, 0x96] // 0x96F3B83D in LE
        let truncMcuPath = "/tmp/challenger_trunc_mcuboot.bin"
        try? Data(magicBytes + [0x00, 0x01, 0x02, 0x03]).write(to: URL(fileURLWithPath: truncMcuPath))
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: truncMcuPath), kind: .appFirmware, isCustom: true)
            // Should fall back gracefully to raw binary
            if m.formatBadge == "Raw Binary" && m.detectedFormat == .rawBinary {
                recordPass("Truncated MCUboot (8 bytes with magic)", "Gracefully fell back to Raw Binary")
            } else {
                recordFail("Truncated MCUboot (8 bytes with magic)", "Badge: \(m.formatBadge), Format: \(m.detectedFormat)")
            }
        } catch {
            recordFail("Truncated MCUboot (8 bytes with magic)", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: truncMcuPath)

        // 3.2 Invalid MCUboot magic
        let invalidMcuPath = "/tmp/challenger_bad_magic.bin"
        let badMagicData = Data([0x3E, 0xB8, 0xF3, 0x96] + Array(repeating: UInt8(0), count: 60))
        try? badMagicData.write(to: URL(fileURLWithPath: invalidMcuPath))
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: invalidMcuPath), kind: .appFirmware, isCustom: true)
            if m.formatBadge == "Raw Binary" && m.detectedFormat == .rawBinary {
                recordPass("Invalid MCUboot Magic", "Gracefully fell back to Raw Binary")
            } else {
                recordFail("Invalid MCUboot Magic", "Badge: \(m.formatBadge)")
            }
        } catch {
            recordFail("Invalid MCUboot Magic", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: invalidMcuPath)

        // 3.3 MCUboot header with huge imgSize (UInt32.max)
        let hugeImgMcuPath = "/tmp/challenger_huge_imgsize.bin"
        var hugeData = Data(magicBytes)
        hugeData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // load_addr
        hugeData.append(contentsOf: [0x20, 0x00]) // hdr_size = 32
        hugeData.append(contentsOf: [0x00, 0x00]) // protect_tlv_size
        hugeData.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF]) // img_size = 4GB - 1
        hugeData.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // flags
        hugeData.append(contentsOf: [0x02, 0x01, 0x03, 0x00, 0x04, 0x00, 0x00, 0x00]) // ver
        try? hugeData.write(to: URL(fileURLWithPath: hugeImgMcuPath))
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: hugeImgMcuPath), kind: .appFirmware, isCustom: true)
            if m.formatBadge == "MCUboot Signed" && m.secondaryDetail.contains("v2.1.3+4") {
                recordPass("MCUboot with max uint32 imgSize", "Parsed without overflow: \(m.secondaryDetail)")
            } else {
                recordFail("MCUboot with max uint32 imgSize", "Detail: \(m.secondaryDetail)")
            }
        } catch {
            recordFail("MCUboot with max uint32 imgSize", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: hugeImgMcuPath)

        // ---------------------------------------------------------------
        // SUITE 4: Corrupted ELF Headers
        // ---------------------------------------------------------------
        log("\n--- SUITE 4: Corrupted ELF Headers ---")
        // 4.1 Truncated ELF (< 52 bytes)
        let truncElfPath = "/tmp/challenger_trunc_elf.elf"
        try? Data([0x7F, 0x45, 0x4C, 0x46, 0x01, 0x01, 0x01]).write(to: URL(fileURLWithPath: truncElfPath))
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: truncElfPath), kind: .bootloader, isCustom: true)
            if m.formatBadge == "ELF Binary" {
                recordPass("Truncated ELF (7 bytes)", "Fell back to extension: ELF Binary")
            } else {
                recordFail("Truncated ELF (7 bytes)", "Badge: \(m.formatBadge)")
            }
        } catch {
            recordFail("Truncated ELF (7 bytes)", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: truncElfPath)

        // 4.2 ELF64 (elfClass = 2)
        let elf64Path = "/tmp/challenger_elf64.elf"
        var elf64Data = Data([0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01, 0x01])
        elf64Data.append(contentsOf: Array(repeating: UInt8(0), count: 64))
        try? elf64Data.write(to: URL(fileURLWithPath: elf64Path))
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: elf64Path), kind: .bootloader, isCustom: true)
            if m.formatBadge == "ELF64" && m.secondaryDetail.contains("Non-ARM Cortex-M ELF") {
                recordPass("ELF64 Header", "Badge: \(m.formatBadge), Detail: \(m.secondaryDetail)")
            } else {
                recordFail("ELF64 Header", "Badge: \(m.formatBadge), Detail: \(m.secondaryDetail)")
            }
        } catch {
            recordFail("ELF64 Header", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: elf64Path)

        // ---------------------------------------------------------------
        // SUITE 5: KiCad PCB & Renode Script Edge Cases
        // ---------------------------------------------------------------
        log("\n--- SUITE 5: KiCad PCB & Renode Script Edge Cases ---")
        // 5.1 KiCad PCB with incomplete S-expression
        let brokenPcbPath = "/tmp/challenger_broken.kicad_pcb"
        try? "(kicad_pcb (version ) (generator )".write(toFile: brokenPcbPath, atomically: true, encoding: .utf8)
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: brokenPcbPath), kind: .pcb, isCustom: true)
            if m.formatBadge == "KiCad PCB" && m.detectedFormat == .kicadSExpr {
                recordPass("Broken KiCad S-expr", "Handled gracefully: \(m.secondaryDetail)")
            } else {
                recordFail("Broken KiCad S-expr", "Badge: \(m.formatBadge)")
            }
        } catch {
            recordFail("Broken KiCad S-expr", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: brokenPcbPath)

        // 5.2 Renode Script with unicode / minimal directives
        let minRescPath = "/tmp/challenger_min.resc"
        try? ":name: My Test Board ⌚\nmach create $name\n".write(toFile: minRescPath, atomically: true, encoding: .utf8)
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: minRescPath), kind: .rescScript, isCustom: true)
            if m.formatBadge == "Renode Script" && m.detectedFormat == .renodeResc {
                recordPass("Minimal Renode Script", "Detail: \(m.secondaryDetail)")
            } else {
                recordFail("Minimal Renode Script", "Badge: \(m.formatBadge)")
            }
        } catch {
            recordFail("Minimal Renode Script", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: minRescPath)

        // ---------------------------------------------------------------
        // SUITE 6: ADVERSARIAL INTEL HEX & PSEUDO-HEX (CRASH PROBING)
        // ---------------------------------------------------------------
        log("\n--- SUITE 6: Adversarial Intel HEX & Pseudo-HEX (Crash Probing) ---")

        // 6.1 Test pseudo-hex with non-hex payload: ":not_a_hex_line_12345"
        let nonHexPath = "/tmp/challenger_non_hex.hex"
        try? ":not_a_hex_line_12345\n".write(toFile: nonHexPath, atomically: true, encoding: .utf8)
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: nonHexPath), kind: .appFirmware, isCustom: true)
            if m.formatBadge == "Intel HEX" && m.detectedFormat == .intelHex {
                recordPass("Pseudo-hex with non-hex payload", "Handled via extension fallback: \(m.formatBadge)")
            } else {
                recordFail("Pseudo-hex with non-hex payload", "Badge: \(m.formatBadge)")
            }
        } catch {
            recordFail("Pseudo-hex with non-hex payload", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: nonHexPath)

        // 6.2 Adversarial Intel HEX Crash Probe 1: Record Type 04 with length 11 (":0000000400")
        log("\nProbing Bug 1: Truncated Type 04 Record (':0000000400') via isolated subprocess...")
        let crash1Code = """
        let testPath = "/tmp/adv_hex_04.hex"
        try? ":0000000400\\n".write(toFile: testPath, atomically: true, encoding: .utf8)
        let _ = try await AssetInspector.inspect(url: URL(fileURLWithPath: testPath), kind: .appFirmware, isCustom: true)
        print("COMPLETED_UNEXPECTEDLY")
        """
        let res1 = runSubprocessTest(name: "Bug 1: Type 04 Out-of-Bounds", testCode: crash1Code)
        if res1.exitCode != 0 {
            recordFail("Bug 1 CONFIRMED: Truncated Type 04 record crashed process!",
                       "Exit code: \(res1.exitCode), Error output: \(res1.output.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            recordPass("Bug 1 not reproduced", "Process survived with code 0")
        }
        try? FileManager.default.removeItem(atPath: "/tmp/adv_hex_04.hex")

        // 6.3 Adversarial Intel HEX Crash Probe 2: Record Type 05 with length 11 (":0000000500")
        log("\nProbing Bug 2: Truncated Type 05 Record (':0000000500') via isolated subprocess...")
        let crash2Code = """
        let testPath = "/tmp/adv_hex_05.hex"
        try? ":0000000500\\n".write(toFile: testPath, atomically: true, encoding: .utf8)
        let _ = try await AssetInspector.inspect(url: URL(fileURLWithPath: testPath), kind: .appFirmware, isCustom: true)
        print("COMPLETED_UNEXPECTEDLY")
        """
        let res2 = runSubprocessTest(name: "Bug 2: Type 05 Out-of-Bounds (len 11)", testCode: crash2Code)
        if res2.exitCode != 0 {
            recordFail("Bug 2 CONFIRMED: Truncated Type 05 record (len 11) crashed process!",
                       "Exit code: \(res2.exitCode), Error output: \(res2.output.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            recordPass("Bug 2 not reproduced", "Process survived with code 0")
        }
        try? FileManager.default.removeItem(atPath: "/tmp/adv_hex_05.hex")

        // 6.4 Adversarial Intel HEX Crash Probe 3: Record Type 05 with length 13 (":040000050800")
        log("\nProbing Bug 3: Incomplete Entry Point Type 05 Record (':040000050800') via isolated subprocess...")
        let crash3Code = """
        let testPath = "/tmp/adv_hex_05_13.hex"
        try? ":040000050800\\n".write(toFile: testPath, atomically: true, encoding: .utf8)
        let _ = try await AssetInspector.inspect(url: URL(fileURLWithPath: testPath), kind: .appFirmware, isCustom: true)
        print("COMPLETED_UNEXPECTEDLY")
        """
        let res3 = runSubprocessTest(name: "Bug 3: Type 05 Out-of-Bounds (len 13)", testCode: crash3Code)
        if res3.exitCode != 0 {
            recordFail("Bug 3 CONFIRMED: Incomplete Type 05 record (len 13) crashed process!",
                       "Exit code: \(res3.exitCode), Error output: \(res3.output.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            recordPass("Bug 3 not reproduced", "Process survived with code 0")
        }
        try? FileManager.default.removeItem(atPath: "/tmp/adv_hex_05_13.hex")

        // 6.5 Adversarial Intel HEX Crash Probe 4: Multi-line file where corrupt line follows valid record
        log("\nProbing Bug 4: Valid record followed by corrupt Type 04 line...")
        let crash4Code = """
        let testPath = "/tmp/adv_hex_multiline.hex"
        let content = ":020000040800F2\\n:0000000400\\n"
        try? content.write(toFile: testPath, atomically: true, encoding: .utf8)
        let _ = try await AssetInspector.inspect(url: URL(fileURLWithPath: testPath), kind: .appFirmware, isCustom: true)
        print("COMPLETED_UNEXPECTEDLY")
        """
        let res4 = runSubprocessTest(name: "Bug 4: Multiline Type 04 Corruption", testCode: crash4Code)
        if res4.exitCode != 0 {
            recordFail("Bug 4 CONFIRMED: Multiline file with corrupt Type 04 line crashed process!",
                       "Exit code: \(res4.exitCode), Error output: \(res4.output.trimmingCharacters(in: .whitespacesAndNewlines))")
        } else {
            recordPass("Bug 4 not reproduced", "Process survived with code 0")
        }
        try? FileManager.default.removeItem(atPath: "/tmp/adv_hex_multiline.hex")

        // ---------------------------------------------------------------
        // SUITE 7: Filesystem & Path Stress Tests
        // ---------------------------------------------------------------
        log("\n--- SUITE 7: Filesystem & Path Stress Tests ---")
        // 7.1 Non-existent file
        let bogusURL = URL(fileURLWithPath: "/tmp/totally_bogus_\(UUID().uuidString).bin")
        do {
            let _ = try await AssetInspector.inspect(url: bogusURL, kind: .appFirmware, isCustom: true)
            recordFail("Non-existent file", "Did not throw!")
        } catch AssetInspectionError.fileNotFound {
            recordPass("Non-existent file", "Correctly threw AssetInspectionError.fileNotFound")
        } catch {
            recordFail("Non-existent file", "Threw wrong error: \(error)")
        }

        // 7.2 Directory path passed instead of file
        let dirURL = URL(fileURLWithPath: "/Users/jacobloesch/Documents/F91_Jepler")
        do {
            let _ = try await AssetInspector.inspect(url: dirURL, kind: .pcb, isCustom: true)
            recordFail("Directory path", "Did not throw!")
        } catch AssetInspectionError.unreadableFile {
            recordPass("Directory path", "Correctly threw AssetInspectionError.unreadableFile")
        } catch {
            recordFail("Directory path", "Threw wrong error: \(error)")
        }

        // 7.3 Unreadable file (chmod 000)
        let unreadablePath = "/tmp/challenger_unreadable.bin"
        try? "SECRET".write(toFile: unreadablePath, atomically: true, encoding: .utf8)
        let chmodProc = Process()
        chmodProc.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodProc.arguments = ["000", unreadablePath]
        try? chmodProc.run()
        chmodProc.waitUntilExit()

        do {
            let _ = try await AssetInspector.inspect(url: URL(fileURLWithPath: unreadablePath), kind: .appFirmware, isCustom: true)
            recordFail("chmod 000 file", "Did not throw unreadable!")
        } catch AssetInspectionError.unreadableFile {
            recordPass("chmod 000 file", "Correctly threw AssetInspectionError.unreadableFile")
        } catch {
            recordFail("chmod 000 file", "Threw other error: \(error)")
        }
        // Cleanup permissions
        let chmodFix = Process()
        chmodFix.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmodFix.arguments = ["644", unreadablePath]
        try? chmodFix.run()
        chmodFix.waitUntilExit()
        try? FileManager.default.removeItem(atPath: unreadablePath)

        // 7.4 Path with spaces, symbols, and unicode
        let complexDir = "/tmp/test space & unicode ⌚ #!$@/deep"
        try? FileManager.default.createDirectory(atPath: complexDir, withIntermediateDirectories: true)
        let complexFile = complexDir + "/test_file.bin"
        try? "VALID_CONTENT_HERE".write(toFile: complexFile, atomically: true, encoding: .utf8)
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: complexFile), kind: .appFirmware, isCustom: true)
            if m.fileSizeBytes == 18 && m.fileName == "test_file.bin" {
                recordPass("Complex directory path with unicode & spaces", "Parsed correctly")
            } else {
                recordFail("Complex directory path with unicode & spaces", "Meta: \(m)")
            }
        } catch {
            recordFail("Complex directory path with unicode & spaces", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: "/tmp/test space & unicode ⌚ #!$@")

        // ---------------------------------------------------------------
        // SUITE 8: High-Load & Concurrent Stress Testing
        // ---------------------------------------------------------------
        log("\n--- SUITE 8: High-Load & Concurrent Stress Testing ---")
        // 8.1 10 MB synthetic file throughput
        let largeFilePath = "/tmp/challenger_large_10mb.bin"
        let chunk1MB = Data(repeating: 0xAA, count: 1024 * 1024)
        var fileStream = try? FileHandle(forWritingTo: URL(fileURLWithPath: {
            FileManager.default.createFile(atPath: largeFilePath, contents: nil)
            return largeFilePath
        }()))
        for _ in 0..<10 {
            try? fileStream?.write(contentsOf: chunk1MB)
        }
        try? fileStream?.close()

        let t0 = Date()
        do {
            let m = try await AssetInspector.inspect(url: URL(fileURLWithPath: largeFilePath), kind: .appFirmware, isCustom: true)
            let dt = Date().timeIntervalSince(t0)
            if m.fileSizeBytes == 10 * 1024 * 1024 && m.sha256Prefix != nil {
                recordPass("10 MB file throughput", "Time: \(String(format: "%.3f", dt))s, SHA: \(m.sha256Prefix!)")
            } else {
                recordFail("10 MB file throughput", "Bad size or sha")
            }
        } catch {
            recordFail("10 MB file throughput", "Threw error: \(error)")
        }
        try? FileManager.default.removeItem(atPath: largeFilePath)

        // 8.2 50 Concurrent inspection tasks
        log("Running 50 concurrent AssetInspector.inspect operations...")
        let sampleURL = repoRoot.appendingPathComponent("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/app.signed.bin")
        let concurrentStart = Date()
        var concurrentSuccessCount = 0
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    if let meta = try? await AssetInspector.inspect(url: sampleURL, kind: .appFirmware, isCustom: false),
                       meta.formatBadge == "MCUboot Signed" {
                        return true
                    }
                    return false
                }
            }
            for await success in group {
                if success { concurrentSuccessCount += 1 }
            }
        }
        let concurrentDuration = Date().timeIntervalSince(concurrentStart)
        if concurrentSuccessCount == 50 {
            recordPass("50 Concurrent inspections", "All 50 succeeded in \(String(format: "%.3f", concurrentDuration))s without race condition")
        } else {
            recordFail("50 Concurrent inspections", "Only \(concurrentSuccessCount)/50 succeeded")
        }

        // ---------------------------------------------------------------
        // SUITE 9: SessionAsset Model State Machine
        // ---------------------------------------------------------------
        log("\n--- SUITE 9: SessionAsset Model State Machine ---")
        var asset = SessionAsset(kind: .appFirmware, url: nil, state: .notLoaded, metadata: nil, isCustom: false)
        if !asset.isReady && asset.fileName == "None" && asset.formatBadge == "Empty" {
            recordPass("SessionAsset uninitialized state", "isReady=false, formatBadge=Empty")
        } else {
            recordFail("SessionAsset uninitialized state", "Unexpected values")
        }

        let dummyMeta = AssetMetadata(
            fileName: "test.bin",
            filePath: "/tmp/test.bin",
            fileSizeBytes: 1024,
            fileSizeFormatted: "1 KB",
            modificationDate: Date(),
            modificationDateFormatted: "Today",
            formatBadge: "Raw Binary",
            secondaryDetail: "Custom",
            isCustom: true,
            sha256Prefix: "12345678",
            detectedFormat: .rawBinary
        )
        asset.url = URL(fileURLWithPath: "/tmp/test.bin")
        asset.metadata = dummyMeta
        if asset.isReady && asset.state == .loaded(dummyMeta) && asset.fileName == "test.bin" && asset.formatBadge == "Raw Binary" {
            recordPass("SessionAsset loaded state transition", "isReady=true, state=.loaded(meta)")
        } else {
            recordFail("SessionAsset loaded state transition", "State: \(asset.state)")
        }

        // ---------------------------------------------------------------
        // SUMMARY
        // ---------------------------------------------------------------
        log("\n==================================================================")
        log(" EMPIRICAL CHALLENGE HARNESS COMPLETE")
        log(" Total Tests Run: \(totalTests)")
        log(" Passed: \(passedTests)")
        log(" Failed: \(failedTests)")
        log(" Verdict: \(failedTests > 0 ? "REJECT (Vulnerabilities Detected)" : "APPROVE")")
        log("==================================================================")
    }
}
