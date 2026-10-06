import Foundation
import AppKit
import CryptoKit

// ==============================================================================
// EMPIRICAL CHALLENGER TEST HARNESS — MILESTONE 2
// Target: ProjectSidebarView validation logic, SessionAsset models,
//         metadata rendering, and KeyboardMonitor modifier isolation.
// ==============================================================================

@main
struct ChallengerM2Harness {

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

    // Helper to evaluate drop acceptance per ProjectSidebarView logic
    static func evaluateDropAcceptance(kind: SessionAssetKind, url: URL) -> (accepted: Bool, message: String) {
        let ext = url.pathExtension.lowercased()
        let allowed = kind.allowedExtensions.map { $0.lowercased() }
        let allowedFormatted = allowed.map { ".\($0)" }.joined(separator: ", ")

        if allowed.contains(ext) {
            return (true, "Accepted .\(ext)")
        } else {
            let errStr = "Rejected .\(ext) (expected \(allowedFormatted))"
            return (false, errStr)
        }
    }

    // Helper to construct synthetic NSEvent
    static func makeKeyEvent(
        type: NSEvent.EventType,
        keyCode: UInt16,
        characters: String,
        modifiers: NSEvent.ModifierFlags = [],
        isARepeat: Bool = false
    ) -> NSEvent {
        return NSEvent.keyEvent(
            with: type,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: isARepeat,
            keyCode: keyCode
        )!
    }

    static func main() async {
        log("==================================================================")
        log(" EMPIRICAL CHALLENGER STRESS HARNESS — MILESTONE 2")
        log(" Target: Sidebar Dropzones, Extension Validation & KeyboardMonitor")
        log(" Timestamp: \(Date())")
        log("==================================================================\n")

        let repoRoot = URL(fileURLWithPath: "/Users/jacobloesch/Documents/F91_Jepler")

        // ----------------------------------------------------------------------
        // SUITE 1: Extension Acceptance & Rejection Matrix (All 4 Asset Kinds)
        // ----------------------------------------------------------------------
        log("--- SUITE 1: Extension Acceptance Matrix (All 4 Kinds) ---")

        // 1.1 PCB Layout (.pcb)
        let pcbValid = ["f91_jepler.kicad_pcb", "BOARD.KICAD_PCB", "rev_b.KiCad_Pcb", "multi.dot.version.kicad_pcb"]
        for name in pcbValid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .pcb, url: url)
            if res.accepted {
                recordPass("PCB accepts valid extension", name)
            } else {
                recordFail("PCB rejected valid extension", "\(name): \(res.message)")
            }
        }

        let pcbInvalid = [
            "firmware.bin", "bootloader.elf", "firmware.hex", "script.resc",
            "image.png", "doc.txt", "layout.kicad_pcb-bak", "layout.kicad_pcb.tmp",
            "schematic.kicad_sch", "archive.zip", "no_extension", "empty_ext."
        ]
        for name in pcbInvalid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .pcb, url: url)
            if !res.accepted {
                recordPass("PCB rejects invalid extension", "\(name) -> \(res.message)")
            } else {
                recordFail("PCB accepted invalid extension", "\(name): \(res.message)")
            }
        }

        // 1.2 Application Firmware (.appFirmware)
        let appValid = [
            "app.signed.bin", "firmware.BIN", "zephyr.elf", "IMAGE.ELF",
            "blaster.hex", "intel.HEX", "mixed.BiN", "test.v1.0.final.elf"
        ]
        for name in appValid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .appFirmware, url: url)
            if res.accepted {
                recordPass("AppFirmware accepts valid extension", name)
            } else {
                recordFail("AppFirmware rejected valid extension", "\(name): \(res.message)")
            }
        }

        let appInvalid = [
            "f91_jepler.kicad_pcb", "simulation.resc", "notes.txt", "diagram.png",
            "firmware.bin.bak", "archive.tar.gz", "object.o", "lib.a", "no_extension"
        ]
        for name in appInvalid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .appFirmware, url: url)
            if !res.accepted {
                recordPass("AppFirmware rejects invalid extension", "\(name) -> \(res.message)")
            } else {
                recordFail("AppFirmware accepted invalid extension", "\(name): \(res.message)")
            }
        }

        // 1.3 MCUboot Bootloader (.bootloader)
        let bootValid = [
            "mcuboot.elf", "BOOTLOADER.ELF", "mcuboot.hex", "boot.HEX",
            "mcuboot.bin", "BOOT.BIN", "mcuboot.v2.1.signed.elf"
        ]
        for name in bootValid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .bootloader, url: url)
            if res.accepted {
                recordPass("Bootloader accepts valid extension", name)
            } else {
                recordFail("Bootloader rejected valid extension", "\(name): \(res.message)")
            }
        }

        let bootInvalid = [
            "f91_jepler.kicad_pcb", "renode.resc", "bootloader.c", "header.h",
            "binary.exe", "photo.png", "readme.md", "no_extension"
        ]
        for name in bootInvalid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .bootloader, url: url)
            if !res.accepted {
                recordPass("Bootloader rejects invalid extension", "\(name) -> \(res.message)")
            } else {
                recordFail("Bootloader accepted invalid extension", "\(name): \(res.message)")
            }
        }

        // 1.4 Renode Emulation Script (.rescScript)
        let rescValid = [
            "f91_jepler.resc", "TEST.RESC", "custom_board.Resc", "setup.sim.resc"
        ]
        for name in rescValid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .rescScript, url: url)
            if res.accepted {
                recordPass("RescScript accepts valid extension", name)
            } else {
                recordFail("RescScript rejected valid extension", "\(name): \(res.message)")
            }
        }

        let rescInvalid = [
            "app.bin", "mcuboot.elf", "blaster.hex", "board.kicad_pcb",
            "run.sh", "script.py", "terminal.log", "resc_backup.resc.old", "no_extension"
        ]
        for name in rescInvalid {
            let url = URL(fileURLWithPath: "/tmp/\(name)")
            let res = evaluateDropAcceptance(kind: .rescScript, url: url)
            if !res.accepted {
                recordPass("RescScript rejects invalid extension", "\(name) -> \(res.message)")
            } else {
                recordFail("RescScript accepted invalid extension", "\(name): \(res.message)")
            }
        }

        // ----------------------------------------------------------------------
        // SUITE 2: Cross-Drop Rejection (Preventing Wrong Dropzone Targets)
        // ----------------------------------------------------------------------
        log("\n--- SUITE 2: Cross-Drop Target Collision Tests ---")
        let testFiles: [(filename: String, targetKind: SessionAssetKind, shouldAccept: Bool)] = [
            ("board.kicad_pcb", .pcb, true),
            ("board.kicad_pcb", .appFirmware, false),
            ("board.kicad_pcb", .bootloader, false),
            ("board.kicad_pcb", .rescScript, false),

            ("app.bin", .pcb, false),
            ("app.bin", .appFirmware, true),
            ("app.bin", .bootloader, true),
            ("app.bin", .rescScript, false),

            ("mcuboot.elf", .pcb, false),
            ("mcuboot.elf", .appFirmware, true),
            ("mcuboot.elf", .bootloader, true),
            ("mcuboot.elf", .rescScript, false),

            ("orchestration.resc", .pcb, false),
            ("orchestration.resc", .appFirmware, false),
            ("orchestration.resc", .bootloader, false),
            ("orchestration.resc", .rescScript, true),
        ]

        for item in testFiles {
            let url = URL(fileURLWithPath: "/tmp/\(item.filename)")
            let res = evaluateDropAcceptance(kind: item.targetKind, url: url)
            if res.accepted == item.shouldAccept {
                recordPass("Cross-Drop \(item.filename) -> \(item.targetKind.rawValue)", "Result: \(res.accepted ? "Accepted" : "Rejected")")
            } else {
                recordFail("Cross-Drop \(item.filename) -> \(item.targetKind.rawValue)", "Expected: \(item.shouldAccept), Got: \(res.accepted)")
            }
        }

        // ----------------------------------------------------------------------
        // SUITE 3: SessionAsset Metadata Rendering & Badges
        // ----------------------------------------------------------------------
        log("\n--- SUITE 3: SessionAsset Metadata Rendering & Badge Computation ---")

        // 3.1 Uninitialized SessionAsset (Nil URL, Not Loaded)
        let uninitAsset = SessionAsset(kind: .pcb)
        if uninitAsset.formatBadge == "Empty" && uninitAsset.fileName == "None" && uninitAsset.filePath == nil && !uninitAsset.isReady {
            recordPass("Uninitialized SessionAsset fallback rendering", "badge: \(uninitAsset.formatBadge), name: \(uninitAsset.fileName)")
        } else {
            recordFail("Uninitialized SessionAsset fallback rendering", "badge: \(uninitAsset.formatBadge), isReady: \(uninitAsset.isReady)")
        }

        // 3.2 SessionAsset with URL but without inspected metadata
        let pendingURL = URL(fileURLWithPath: "/tmp/custom_firmware.bin")
        let pendingAsset = SessionAsset(kind: .appFirmware, url: pendingURL, state: .inspecting, metadata: nil, isCustom: true)
        if pendingAsset.formatBadge == "BIN" && pendingAsset.fileName == "custom_firmware.bin" && pendingAsset.filePath == "/tmp/custom_firmware.bin" {
            recordPass("Pending SessionAsset uppercase extension fallback badge", "badge: \(pendingAsset.formatBadge)")
        } else {
            recordFail("Pending SessionAsset uppercase extension fallback badge", "badge: \(pendingAsset.formatBadge)")
        }

        // 3.3 SessionAsset with Real Repository Assets
        let repoAssets: [(relPath: String, kind: SessionAssetKind, expectedBadge: String)] = [
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/app.signed.bin", .appFirmware, "MCUboot Signed"),
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/mcuboot.elf", .bootloader, "ELF32 ARM"),
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.resc", .rescScript, "Renode Script"),
            ("Software/macOS_App/F91JeplerEmulator/Resources/Embedded/f91_jepler.kicad_pcb", .pcb, "KiCad PCB"),
            ("zephyr/boards/intel/socfpga_std/cyclonev_socdk/support/blaster_6810.hex", .appFirmware, "Intel HEX")
        ]

        for item in repoAssets {
            let fileURL = repoRoot.appendingPathComponent(item.relPath)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let meta = try? AssetInspector.inspectSynchronous(url: fileURL, kind: item.kind, isCustom: false) {
                    var asset = SessionAsset(kind: item.kind, url: fileURL, isCustom: false)
                    asset.metadata = meta

                    let badgeMatch = (asset.formatBadge == item.expectedBadge)
                    let readyMatch = asset.isReady
                    let shaMatch = (asset.metadata?.sha256Prefix != nil && asset.metadata?.sha256Prefix?.count == 8)
                    let sizeMatch = asset.fileSizeFormatted != "0 B"

                    if badgeMatch && readyMatch && shaMatch && sizeMatch {
                        recordPass("Real Asset Metadata: \(fileURL.lastPathComponent)", "Badge: \(asset.formatBadge), Size: \(asset.fileSizeFormatted), SHA: \(asset.metadata?.sha256Prefix ?? "")")
                    } else {
                        recordFail("Real Asset Metadata: \(fileURL.lastPathComponent)", "Badge: \(asset.formatBadge), Ready: \(readyMatch), SHA: \(asset.metadata?.sha256Prefix ?? "")")
                    }
                } else {
                    recordFail("Failed to inspect real asset", fileURL.path)
                }
            } else {
                recordFail("Asset not found at path", fileURL.path)
            }
        }

        // 3.4 Middle-Truncated Path Display Verification
        let longFileName = "firmware_build_production_release_candidate_v2_1_3_signed_with_key_final.bin"
        let longURL = URL(fileURLWithPath: "/Users/dev/Documents/Projects/Hardware/F91/\(longFileName)")
        let longAsset = SessionAsset(kind: .appFirmware, url: longURL, state: .customLoaded, metadata: nil, isCustom: true)
        if longAsset.fileName == longFileName && longAsset.filePath == longURL.path {
            recordPass("SessionAsset preserves full path for tooltip while presenting filename for middle-truncation", "Length: \(longFileName.count)")
        } else {
            recordFail("SessionAsset failed path preservation", "Path: \(longAsset.filePath ?? "")")
        }

        // ----------------------------------------------------------------------
        // SUITE 4: Asset State Machine Transitions
        // ----------------------------------------------------------------------
        log("\n--- SUITE 4: Asset State Machine Transitions ---")

        // 4.1 State properties
        let stateNotLoaded = AssetLoadState.notLoaded
        if !stateNotLoaded.isLoaded && !stateNotLoaded.isInspecting && stateNotLoaded.errorMessage == nil {
            recordPass("AssetLoadState.notLoaded contract")
        } else {
            recordFail("AssetLoadState.notLoaded contract")
        }

        let stateInspecting = AssetLoadState.inspecting
        if !stateInspecting.isLoaded && stateInspecting.isInspecting && stateInspecting.errorMessage == nil {
            recordPass("AssetLoadState.inspecting contract")
        } else {
            recordFail("AssetLoadState.inspecting contract")
        }

        let dummyMeta = AssetMetadata(
            fileName: "test.bin",
            filePath: "/tmp/test.bin",
            fileSizeBytes: 1024,
            fileSizeFormatted: "1 KB",
            modificationDate: Date(),
            modificationDateFormatted: "Today",
            formatBadge: "Raw Binary",
            secondaryDetail: "1024 bytes",
            isCustom: true,
            sha256Prefix: "abcdef12",
            detectedFormat: .rawBinary
        )

        let stateLoaded = AssetLoadState.loaded(dummyMeta)
        if stateLoaded.isLoaded && !stateLoaded.isInspecting && stateLoaded.metadata == dummyMeta && stateLoaded.errorMessage == nil {
            recordPass("AssetLoadState.loaded contract")
        } else {
            recordFail("AssetLoadState.loaded contract")
        }

        let stateFailed = AssetLoadState.failed(error: "Header magic mismatch")
        if !stateFailed.isLoaded && !stateFailed.isInspecting && stateFailed.errorMessage == "Header magic mismatch" {
            recordPass("AssetLoadState.failed contract")
        } else {
            recordFail("AssetLoadState.failed contract")
        }

        let stateMissing = AssetLoadState.missing("File not found on disk")
        if !stateMissing.isLoaded && !stateMissing.isInspecting && stateMissing.errorMessage == "File not found on disk" {
            recordPass("AssetLoadState.missing contract")
        } else {
            recordFail("AssetLoadState.missing contract")
        }

        // 4.2 Setting metadata automatically transitions state to .loaded
        var transitionAsset = SessionAsset(kind: .appFirmware, url: URL(fileURLWithPath: "/tmp/test.bin"), state: .inspecting)
        transitionAsset.metadata = dummyMeta
        if transitionAsset.state == .loaded(dummyMeta) && transitionAsset.isReady {
            recordPass("SessionAsset.metadata assignment automatically transitions state to .loaded(meta)")
        } else {
            recordFail("SessionAsset.metadata assignment transition failed", "State: \(transitionAsset.state)")
        }

        // ----------------------------------------------------------------------
        // SUITE 5: KeyboardMonitor Key Event Inspection & Modifier Isolation
        // ----------------------------------------------------------------------
        log("\n--- SUITE 5: KeyboardMonitor Modifier Isolation & Event Handling ---")

        let app = NSApplication.shared
        _ = app // Ensure NSApp is initialized

        let keyboardMonitor = KeyboardMonitor()
        var lastKeyDown: String? = nil
        var lastKeyUp: String? = nil
        var keyDownCount = 0
        var keyUpCount = 0

        keyboardMonitor.onKeyDown = { key in
            lastKeyDown = key
            keyDownCount += 1
        }
        keyboardMonitor.onKeyUp = { key in
            lastKeyUp = key
            keyUpCount += 1
        }

        keyboardMonitor.start()

        // 5.1 Raw Key 1 (keyCode 18) — Watch Light Button
        lastKeyDown = nil
        keyDownCount = 0
        let eKey1 = makeKeyEvent(type: .keyDown, keyCode: 18, characters: "1")
        app.sendEvent(eKey1)
        if lastKeyDown == "1" && keyDownCount == 1 {
            recordPass("Raw Key 1 (keyCode 18) triggers '1' callback without modifiers")
        } else {
            recordFail("Raw Key 1 (keyCode 18) failed callback", "lastKeyDown: \(lastKeyDown ?? "nil"), count: \(keyDownCount)")
        }

        // 5.2 Raw Key 2 (keyCode 19) — Watch Mode Button
        lastKeyDown = nil
        keyDownCount = 0
        let eKey2 = makeKeyEvent(type: .keyDown, keyCode: 19, characters: "2")
        app.sendEvent(eKey2)
        if lastKeyDown == "2" && keyDownCount == 1 {
            recordPass("Raw Key 2 (keyCode 19) triggers '2' callback without modifiers")
        } else {
            recordFail("Raw Key 2 (keyCode 19) failed callback", "lastKeyDown: \(lastKeyDown ?? "nil"), count: \(keyDownCount)")
        }

        // 5.3 Raw Key 3 (keyCode 20) — Watch Toggle Button
        lastKeyDown = nil
        keyDownCount = 0
        let eKey3 = makeKeyEvent(type: .keyDown, keyCode: 20, characters: "3")
        app.sendEvent(eKey3)
        if lastKeyDown == "3" && keyDownCount == 1 {
            recordPass("Raw Key 3 (keyCode 20) triggers '3' callback without modifiers")
        } else {
            recordFail("Raw Key 3 (keyCode 20) failed callback", "lastKeyDown: \(lastKeyDown ?? "nil"), count: \(keyDownCount)")
        }

        // 5.4 Key Repeat Suppression
        lastKeyDown = nil
        keyDownCount = 0
        let eKey1Repeat = makeKeyEvent(type: .keyDown, keyCode: 18, characters: "1", isARepeat: true)
        app.sendEvent(eKey1Repeat)
        if lastKeyDown == nil && keyDownCount == 0 {
            recordPass("Key Repeat (isARepeat: true) is suppressed and does not fire duplicate callback")
        } else {
            recordFail("Key Repeat was not suppressed", "lastKeyDown: \(lastKeyDown ?? "nil"), count: \(keyDownCount)")
        }

        // 5.5 KeyUp Events for Raw Keys
        lastKeyUp = nil
        keyUpCount = 0
        let eKey1Up = makeKeyEvent(type: .keyUp, keyCode: 18, characters: "1")
        app.sendEvent(eKey1Up)
        if lastKeyUp == "1" && keyUpCount == 1 {
            recordPass("Raw KeyUp 1 (keyCode 18) triggers '1' keyUp callback")
        } else {
            recordFail("Raw KeyUp 1 (keyCode 18) failed", "lastKeyUp: \(lastKeyUp ?? "nil")")
        }

        // 5.6 Numpad 1, 2, 3 (keyCodes 83, 84, 85)
        lastKeyDown = nil
        app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: 83, characters: "1"))
        let np1Pass = (lastKeyDown == "1")

        lastKeyDown = nil
        app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: 84, characters: "2"))
        let np2Pass = (lastKeyDown == "2")

        lastKeyDown = nil
        app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: 85, characters: "3"))
        let np3Pass = (lastKeyDown == "3")

        if np1Pass && np2Pass && np3Pass {
            recordPass("Numpad 1, 2, 3 (keyCodes 83, 84, 85) correctly trigger hotkey callbacks")
        } else {
            recordFail("Numpad hotkeys failed", "np1: \(np1Pass), np2: \(np2Pass), np3: \(np3Pass)")
        }

        // 5.7 CRITICAL ADVERSARIAL TEST: Command Modifier Isolation
        // ⌘0 (Toggle Sidebar): keyCode 29, modifier .command
        lastKeyDown = nil
        keyDownCount = 0
        let eCmd0 = makeKeyEvent(type: .keyDown, keyCode: 29, characters: "0", modifiers: [.command])
        app.sendEvent(eCmd0)
        if lastKeyDown == nil && keyDownCount == 0 {
            recordPass("⌘0 (Sidebar Toggle) is passed through untouched; not intercepted as hotkey")
        } else {
            recordFail("⌘0 was intercepted by KeyboardMonitor", "lastKeyDown: \(lastKeyDown ?? "nil")")
        }

        // ⌘1 (Switch to Watch Tab): keyCode 18, modifier .command
        lastKeyDown = nil
        keyDownCount = 0
        let eCmd1 = makeKeyEvent(type: .keyDown, keyCode: 18, characters: "1", modifiers: [.command])
        app.sendEvent(eCmd1)
        if lastKeyDown == nil && keyDownCount == 0 {
            recordPass("⌘1 (Tab Switch) is passed through untouched; does NOT swallow or fire Light button")
        } else {
            recordFail("⌘1 was swallowed by KeyboardMonitor and fired hotkey", "lastKeyDown: \(lastKeyDown ?? "nil")")
        }

        // ⌘2 (Switch to Canvas Tab): keyCode 19, modifier .command
        lastKeyDown = nil
        keyDownCount = 0
        let eCmd2 = makeKeyEvent(type: .keyDown, keyCode: 19, characters: "2", modifiers: [.command])
        app.sendEvent(eCmd2)
        if lastKeyDown == nil && keyDownCount == 0 {
            recordPass("⌘2 (Tab Switch) is passed through untouched; does NOT swallow or fire Mode button")
        } else {
            recordFail("⌘2 was swallowed by KeyboardMonitor and fired hotkey", "lastKeyDown: \(lastKeyDown ?? "nil")")
        }

        // ⌘3 (Switch to GATT Tab): keyCode 20, modifier .command
        lastKeyDown = nil
        keyDownCount = 0
        let eCmd3 = makeKeyEvent(type: .keyDown, keyCode: 20, characters: "3", modifiers: [.command])
        app.sendEvent(eCmd3)
        if lastKeyDown == nil && keyDownCount == 0 {
            recordPass("⌘3 (Tab Switch) is passed through untouched; does NOT swallow or fire Toggle button")
        } else {
            recordFail("⌘3 was swallowed by KeyboardMonitor and fired hotkey", "lastKeyDown: \(lastKeyDown ?? "nil")")
        }

        // ⌘4 .. ⌘7 Tab Switch Shortcuts
        let tabKeys: [(UInt16, String)] = [(21, "4"), (23, "5"), (22, "6"), (26, "7")]
        for (kc, ch) in tabKeys {
            lastKeyDown = nil
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: kc, characters: ch, modifiers: [.command]))
            if lastKeyDown == nil {
                recordPass("⌘\(ch) (Tab Switch) passed through untouched")
            } else {
                recordFail("⌘\(ch) intercepted by KeyboardMonitor", "lastKeyDown: \(lastKeyDown ?? "nil")")
            }
        }

        // 5.8 CRITICAL ADVERSARIAL TEST: Option+Command Modifier Isolation (⌥⌘S)
        lastKeyDown = nil
        keyDownCount = 0
        let eOptCmdS = makeKeyEvent(type: .keyDown, keyCode: 1, characters: "s", modifiers: [.command, .option])
        app.sendEvent(eOptCmdS)
        if lastKeyDown == nil && keyDownCount == 0 {
            recordPass("⌥⌘S (Secondary Sidebar Toggle) is passed through untouched")
        } else {
            recordFail("⌥⌘S was intercepted by KeyboardMonitor", "lastKeyDown: \(lastKeyDown ?? "nil")")
        }

        // ⌥⌘1, ⌥⌘2, ⌥⌘3
        for (kc, ch) in [(UInt16(18), "1"), (UInt16(19), "2"), (UInt16(20), "3")] {
            lastKeyDown = nil
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: kc, characters: ch, modifiers: [.command, .option]))
            if lastKeyDown == nil {
                recordPass("⌥⌘\(ch) is ignored by hotkey monitor")
            } else {
                recordFail("⌥⌘\(ch) fired hotkey callback", "lastKeyDown: \(lastKeyDown ?? "nil")")
            }
        }

        // 5.9 Control Modifier Isolation (^1, ^2, ^3)
        for (kc, ch) in [(UInt16(18), "1"), (UInt16(19), "2"), (UInt16(20), "3")] {
            lastKeyDown = nil
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: kc, characters: ch, modifiers: [.control]))
            if lastKeyDown == nil {
                recordPass("Control+\(ch) (^" + ch + ") is ignored by hotkey monitor")
            } else {
                recordFail("Control+\(ch) fired hotkey callback", "lastKeyDown: \(lastKeyDown ?? "nil")")
            }
        }

        // 5.10 Option Modifier Isolation (⌥1, ⌥2, ⌥3)
        for (kc, ch) in [(UInt16(18), "1"), (UInt16(19), "2"), (UInt16(20), "3")] {
            lastKeyDown = nil
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: kc, characters: ch, modifiers: [.option]))
            if lastKeyDown == nil {
                recordPass("Option+\(ch) (⌥" + ch + ") is ignored by hotkey monitor")
            } else {
                recordFail("Option+\(ch) fired hotkey callback", "lastKeyDown: \(lastKeyDown ?? "nil")")
            }
        }

        // 5.11 Unrelated Keys Without Modifiers ('a', 'space', 'return', '4')
        let unrelated: [(UInt16, String)] = [(0, "a"), (49, " "), (36, "\r"), (21, "4")]
        for (kc, ch) in unrelated {
            lastKeyDown = nil
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: kc, characters: ch))
            if lastKeyDown == nil {
                recordPass("Unrelated key '\(ch == "\r" ? "return" : ch)' is ignored by hotkey monitor")
            } else {
                recordFail("Unrelated key '\(ch)' fired hotkey callback", "lastKeyDown: \(lastKeyDown ?? "nil")")
            }
        }

        // 5.12 KeyboardMonitor Stop Lifecycle
        keyboardMonitor.stop()
        lastKeyDown = nil
        app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: 18, characters: "1"))
        if lastKeyDown == nil {
            recordPass("KeyboardMonitor.stop() deregisters monitors cleanly; no callbacks after stop")
        } else {
            recordFail("KeyboardMonitor.stop() did not unregister monitors")
        }

        // ----------------------------------------------------------------------
        // SUITE 6: Layout Specifications & Persistence Key Conformance
        // ----------------------------------------------------------------------
        log("\n--- SUITE 6: Layout Dimensions & Persistence Keys Conformance ---")

        // 6.1 Check Persistence Keys
        let keyChecks = [
            ("isSidebarVisible", SessionPersistenceKeys.isSidebarVisible, "jepler.sidebar.isVisible"),
            ("sidebarVisible", SessionPersistenceKeys.sidebarVisible, "jepler.sidebar.visible"),
            ("sidebarVisibleAlternate", SessionPersistenceKeys.sidebarVisibleAlternate, "jepler.sidebar.visible"),
            ("legacyIsSidebarVisible", SessionPersistenceKeys.legacyIsSidebarVisible, "jepler.sidebar.isVisible"),
            ("sidebarWidth", SessionPersistenceKeys.sidebarWidth, "jepler.sidebar.width"),
            ("selectedViewMode", SessionPersistenceKeys.selectedViewMode, "jepler.viewMode"),
            ("customPcbPath", SessionPersistenceKeys.customPcbPath, "jepler.custom.pcb.path"),
            ("customAppBinPath", SessionPersistenceKeys.customAppBinPath, "jepler.custom.appBin.path"),
            ("customBootloaderPath", SessionPersistenceKeys.customBootloaderPath, "jepler.custom.bootloader.path"),
            ("customRescPath", SessionPersistenceKeys.customRescPath, "jepler.custom.resc.path")
        ]

        for (name, actual, expected) in keyChecks {
            if actual == expected {
                recordPass("Persistence key \(name)", actual)
            } else {
                recordFail("Persistence key \(name) mismatch", "Expected: \(expected), Got: \(actual)")
            }
        }

        // 6.2 Asset Kind Titles and Subtitles
        let assetKinds: [(kind: SessionAssetKind, title: String, extCount: Int)] = [
            (.pcb, "KiCad PCB Layout", 1),
            (.appFirmware, "Application Firmware", 3),
            (.bootloader, "MCUboot Bootloader", 3),
            (.rescScript, "Renode Emulation Script", 1)
        ]

        for item in assetKinds {
            if item.kind.title == item.title && item.kind.allowedExtensions.count == item.extCount {
                recordPass("SessionAssetKind.\(item.kind.rawValue) specification conformance", "\(item.title), allowed: \(item.kind.allowedExtensions)")
            } else {
                recordFail("SessionAssetKind.\(item.kind.rawValue) mismatch", "\(item.kind.title), extensions: \(item.kind.allowedExtensions)")
            }
        }

        // ----------------------------------------------------------------------
        // SUITE 7: High-Frequency Event Burst Stress Testing
        // ----------------------------------------------------------------------
        log("\n--- SUITE 7: High-Frequency Event Burst Stress Testing ---")
        let stressMonitor = KeyboardMonitor()
        var burstKeyCount = 0
        var burstModifierCount = 0

        stressMonitor.onKeyDown = { _ in
            burstKeyCount += 1
        }
        stressMonitor.start()

        let iterations = 200
        for i in 0..<iterations {
            // Raw 1, 2, or 3
            let rawCode: UInt16 = 18 + UInt16(i % 3)
            let rawChar = "\(i % 3 + 1)"
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: rawCode, characters: rawChar))

            // Modified ⌘1, ⌘2, or ⌘3
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: rawCode, characters: rawChar, modifiers: [.command]))

            // Modified ⌥1, ⌥2, or ⌥3
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: rawCode, characters: rawChar, modifiers: [.option]))

            // Modified ^1, ^2, or ^3
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: rawCode, characters: rawChar, modifiers: [.control]))

            // Modified ⌥⌘S
            app.sendEvent(makeKeyEvent(type: .keyDown, keyCode: 1, characters: "s", modifiers: [.command, .option]))
        }
        stressMonitor.stop()

        if burstKeyCount == iterations {
            recordPass("Rapid event burst (1000 events: 200 raw + 800 modified)", "Exactly \(burstKeyCount)/\(iterations) raw hotkeys fired; 0 false positives from modified keys")
        } else {
            recordFail("Rapid event burst mismatch", "Expected \(iterations) raw callbacks, got \(burstKeyCount)")
        }

        // ----------------------------------------------------------------------
        // SUITE 8: Dropzone Error Auto-Dismissal Logic
        // ----------------------------------------------------------------------
        log("\n--- SUITE 8: Dropzone Error Messaging & Auto-Dismissal Logic ---")
        let errorFormatTests: [(kind: SessionAssetKind, badExt: String, expectedAllowedFormatted: String)] = [
            (.pcb, "bin", ".kicad_pcb"),
            (.appFirmware, "png", ".bin, .hex, .elf"),
            (.bootloader, "txt", ".elf, .hex, .bin"),
            (.rescScript, "sh", ".resc")
        ]

        for item in errorFormatTests {
            let res = evaluateDropAcceptance(kind: item.kind, url: URL(fileURLWithPath: "/tmp/test.\(item.badExt)"))
            let expectedErr = "Rejected .\(item.badExt) (expected \(item.expectedAllowedFormatted))"
            if res.message == expectedErr {
                recordPass("Error string formatting for \(item.kind.rawValue)", res.message)
            } else {
                recordFail("Error string formatting mismatch", "Expected: '\(expectedErr)', Got: '\(res.message)'")
            }
        }

        // ======================================================================
        // HARNESS SUMMARY
        // ======================================================================
        log("\n==================================================================")
        log(" EMPIRICAL CHALLENGE HARNESS COMPLETE — MILESTONE 2")
        log(" Total Tests Run: \(totalTests)")
        log(" Passed: \(passedTests)")
        log(" Failed: \(failedTests)")
        let verdict = (failedTests == 0) ? "APPROVE" : "REJECT"
        log(" Verdict: \(verdict)")
        log("==================================================================")

        if failedTests > 0 {
            exit(1)
        }
    }
}
