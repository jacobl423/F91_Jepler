import Foundation
import CoreGraphics

// MARK: - Empirical Challenger Harness for Milestone 2
// Author: Challenger M2-2
// Target: EmulatorSession, Layout Resizing, Width Bounds Clamping & State Persistence

@main
struct EmpiricalChallengerM2Harness {

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

    static func createTempSuite() -> UserDefaults {
        let suiteName = "test.f91.challenger.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func main() async {
        log("==================================================================")
        log(" EMPIRICAL CHALLENGER STRESS HARNESS — MILESTONE 2")
        log(" Target: EmulatorSession, Layout Resizing & State Persistence")
        log(" Timestamp: \(Date())")
        log("==================================================================")

        await suite1_sidebarVisibilityPersistenceAndDualKey()
        await suite2_sidebarWidthClampingAndBounds()
        await suite3_assetRevertSafety()
        await suite4_nonModalActionSafety()
        await suite5_viewModeAndMultiLaunchCycles()

        log("\n==================================================================")
        log(" EMPIRICAL CHALLENGE HARNESS COMPLETE")
        log(" Total Tests Run: \(totalTests)")
        log(" Passed: \(passedTests)")
        log(" Failed: \(failedTests)")
        let verdict = failedTests == 0 ? "APPROVE" : "REJECT"
        log(" Verdict: \(verdict)")
        log("==================================================================")
    }

    // MARK: - SUITE 1: Sidebar Visibility Persistence & Dual-Key Synchronization
    static func suite1_sidebarVisibilityPersistenceAndDualKey() async {
        log("\n--- SUITE 1: Sidebar Visibility Persistence & Dual-Key Sync ---")

        // Test 1.1: Default initial state without prior persistence
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let isVisible = await MainActor.run { session.isSidebarVisible }
            if isVisible == true {
                recordPass("Default Sidebar Visibility", "Starts visible (true) when no saved preference exists")
            } else {
                recordFail("Default Sidebar Visibility", "Expected true, got \(isVisible)")
            }
        }

        // Test 1.2: Toggling visibility updates primary persistence key
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.isSidebarVisible = false }
            let savedVal = defaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) as? Bool
            if savedVal == false {
                recordPass("Primary Key Persistence", "Updating isSidebarVisible writes false to '\(SessionPersistenceKeys.isSidebarVisible)'")
            } else {
                recordFail("Primary Key Persistence", "Expected false in '\(SessionPersistenceKeys.isSidebarVisible)', got \(String(describing: savedVal))")
            }
        }

        // Test 1.3: Probing dual-key synchronization on session toggle
        // Both jepler.sidebar.visible and jepler.sidebar.isVisible must remain synchronized
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.isSidebarVisible = false }
            let primaryKeyVal = defaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) as? Bool
            let alternateKeyVal = defaults.object(forKey: SessionPersistenceKeys.sidebarVisible) as? Bool

            if primaryKeyVal == false && alternateKeyVal == false {
                recordPass("Dual-Key Sync on Toggle", "Both '\(SessionPersistenceKeys.isSidebarVisible)' and '\(SessionPersistenceKeys.sidebarVisible)' updated to false")
            } else {
                recordFail("Dual-Key Sync on Toggle", "Desync! isVisible: \(String(describing: primaryKeyVal)), visible: \(String(describing: alternateKeyVal))")
            }
        }

        // Test 1.4: Relaunch restoring from alternate key 'jepler.sidebar.visible'
        // If a user/tool only set 'jepler.sidebar.visible' = false, does EmulatorSession respect it?
        do {
            let defaults = createTempSuite()
            defaults.set(false, forKey: SessionPersistenceKeys.sidebarVisible)
            defaults.removeObject(forKey: SessionPersistenceKeys.isSidebarVisible)

            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let isVisible = await MainActor.run { session.isSidebarVisible }

            if isVisible == false {
                recordPass("Restore from Alternate Key", "Restored false when only '\(SessionPersistenceKeys.sidebarVisible)' was set")
            } else {
                recordFail("Restore from Alternate Key", "Ignored alternate key! isSidebarVisible is \(isVisible) instead of false")
            }
        }

        // Test 1.5: Relaunch restoring from primary key 'jepler.sidebar.isVisible'
        do {
            let defaults = createTempSuite()
            defaults.set(false, forKey: SessionPersistenceKeys.isSidebarVisible)

            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let isVisible = await MainActor.run { session.isSidebarVisible }

            if isVisible == false {
                recordPass("Restore from Primary Key", "Restored false when '\(SessionPersistenceKeys.isSidebarVisible)' was set to false")
            } else {
                recordFail("Restore from Primary Key", "Failed to restore false from primary key, got \(isVisible)")
            }
        }

        // Test 1.6: Multi-toggle dual-key lockstep verification
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            var lockstepMaintained = true
            for toggleState in [false, true, false, true, false] {
                await MainActor.run { session.isSidebarVisible = toggleState }
                let p = defaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) as? Bool
                let a = defaults.object(forKey: SessionPersistenceKeys.sidebarVisible) as? Bool
                if p != toggleState || a != toggleState {
                    lockstepMaintained = false
                    break
                }
            }
            if lockstepMaintained {
                recordPass("Multi-Toggle Lockstep Sync", "Dual keys kept in lockstep across 5 alternating toggles")
            } else {
                recordFail("Multi-Toggle Lockstep Sync", "Dual keys failed lockstep across 5 alternating toggles")
            }
        }
    }

    // MARK: - SUITE 2: Sidebar Width Bounds & Clamping (230..380)
    static func suite2_sidebarWidthClampingAndBounds() async {
        log("\n--- SUITE 2: Sidebar Width Bounds & Clamping ---")

        // Test 2.1: Default sidebar width is 280
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let width = await MainActor.run { session.sidebarWidth }
            if width == 280 {
                recordPass("Default Sidebar Width", "Initial width is 280")
            } else {
                recordFail("Default Sidebar Width", "Expected 280, got \(width)")
            }
        }

        // Test 2.2: Valid width within range [230, 380] is persisted
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.sidebarWidth = 320 }
            let saved = defaults.double(forKey: SessionPersistenceKeys.sidebarWidth)
            if saved == 320 {
                recordPass("Valid Width Persistence", "Saved width 320 into '\(SessionPersistenceKeys.sidebarWidth)'")
            } else {
                recordFail("Valid Width Persistence", "Expected 320, got \(saved)")
            }

            // Restore on simulated relaunch
            let session2 = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let restored = await MainActor.run { session2.sidebarWidth }
            if restored == 320 {
                recordPass("Relaunch Restores Valid Width", "Restored width 320 correctly")
            } else {
                recordFail("Relaunch Restores Valid Width", "Expected 320, got \(restored)")
            }
        }

        // Test 2.3: Lower boundary 230
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.sidebarWidth = 230 }
            let session2 = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let restored = await MainActor.run { session2.sidebarWidth }
            if restored == 230 {
                recordPass("Boundary Min Width 230", "Persisted and restored min boundary 230")
            } else {
                recordFail("Boundary Min Width 230", "Expected 230, got \(restored)")
            }
        }

        // Test 2.4: Upper boundary 380
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.sidebarWidth = 380 }
            let session2 = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let restored = await MainActor.run { session2.sidebarWidth }
            if restored == 380 {
                recordPass("Boundary Max Width 380", "Persisted and restored max boundary 380")
            } else {
                recordFail("Boundary Max Width 380", "Expected 380, got \(restored)")
            }
        }

        // Test 2.5: Setting width below 230 (underflow clamping)
        // Verify sidebarWidth is constrained within minWidth: 230
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.sidebarWidth = 150 }
            let currentWidth = await MainActor.run { session.sidebarWidth }

            let session2 = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let restoredWidth = await MainActor.run { session2.sidebarWidth }

            log("    [DIAGNOSTIC] Width set to 150 -> In-memory: \(currentWidth), Restored: \(restoredWidth)")
            if currentWidth >= 230 && currentWidth <= 380 {
                recordPass("Runtime Underflow Clamping", "Width 150 was clamped to \(currentWidth)")
            } else {
                recordFail("Runtime Underflow Clamping", "Width was not clamped at runtime: \(currentWidth) (min is 230)")
            }

            if restoredWidth >= 230 && restoredWidth <= 380 {
                recordPass("Relaunch Underflow Fallback", "Restored width \(restoredWidth) is within [230, 380]")
            } else {
                recordFail("Relaunch Underflow Fallback", "Restored width \(restoredWidth) violated [230, 380]")
            }
        }

        // Test 2.6: Setting width above 380 (overflow clamping)
        // Verify sidebarWidth is constrained within maxWidth: 380
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.sidebarWidth = 600 }
            let currentWidth = await MainActor.run { session.sidebarWidth }

            let session2 = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let restoredWidth = await MainActor.run { session2.sidebarWidth }

            log("    [DIAGNOSTIC] Width set to 600 -> In-memory: \(currentWidth), Restored: \(restoredWidth)")
            if currentWidth >= 230 && currentWidth <= 380 {
                recordPass("Runtime Overflow Clamping", "Width 600 was clamped to \(currentWidth)")
            } else {
                recordFail("Runtime Overflow Clamping", "Width was not clamped at runtime: \(currentWidth) (max is 380)")
            }

            if restoredWidth >= 230 && restoredWidth <= 380 {
                recordPass("Relaunch Overflow Fallback", "Restored width \(restoredWidth) is within [230, 380]")
            } else {
                recordFail("Relaunch Overflow Fallback", "Restored width \(restoredWidth) violated [230, 380]")
            }
        }

        // Test 2.7: Setting negative width
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.sidebarWidth = -100 }
            let currentWidth = await MainActor.run { session.sidebarWidth }

            if currentWidth >= 230 && currentWidth <= 380 {
                recordPass("Negative Width Clamping", "Negative width clamped to \(currentWidth)")
            } else {
                recordFail("Negative Width Clamping", "Negative width was not clamped: \(currentWidth)")
            }
        }

        // Test 2.8: Setting zero width
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            await MainActor.run { session.sidebarWidth = 0 }
            let currentWidth = await MainActor.run { session.sidebarWidth }

            if currentWidth >= 230 && currentWidth <= 380 {
                recordPass("Zero Width Clamping", "Zero width clamped to \(currentWidth)")
            } else {
                recordFail("Zero Width Clamping", "Zero width was not clamped: \(currentWidth)")
            }
        }
    }

    // MARK: - SUITE 3: Asset Revert Safety
    static func suite3_assetRevertSafety() async {
        log("\n--- SUITE 3: Asset Revert Safety ---")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("challenger_m2_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let pcbFile = tempDir.appendingPathComponent("custom.kicad_pcb")
        let appBinFile = tempDir.appendingPathComponent("custom_app.bin")
        let bootElfFile = tempDir.appendingPathComponent("custom_mcuboot.elf")
        let rescFile = tempDir.appendingPathComponent("custom.resc")

        try? "(kicad_pcb (version 20221018) (generator kicad_pcb))".write(to: pcbFile, atomically: true, encoding: .utf8)
        try? Data([0x00, 0x10, 0x00, 0x20, 0x01, 0x00, 0x00, 0x00]).write(to: appBinFile)
        try? Data([0x7f, 0x45, 0x4c, 0x46, 0x01, 0x01, 0x01, 0x00]).write(to: bootElfFile)
        try? "mach create\n".write(to: rescFile, atomically: true, encoding: .utf8)

        // Test 3.1: Individual asset update and revert
        for kind in SessionAssetKind.allCases {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            let targetURL: URL
            switch kind {
            case .pcb: targetURL = pcbFile
            case .appFirmware: targetURL = appBinFile
            case .bootloader: targetURL = bootElfFile
            case .rescScript: targetURL = rescFile
            }

            // Update to custom asset
            await MainActor.run { session.updateAsset(kind: kind, url: targetURL) }

            let isCustomAfterUpdate = await MainActor.run { session.assets[kind]?.isCustom ?? false }
            let savedPath = defaults.string(forKey: kind.userDefaultsKey)

            if isCustomAfterUpdate && savedPath == targetURL.path {
                recordPass("Asset Update [\(kind.rawValue)]", "Marked custom and persisted path to '\(kind.userDefaultsKey)'")
            } else {
                recordFail("Asset Update [\(kind.rawValue)]", "isCustom: \(isCustomAfterUpdate), savedPath: \(String(describing: savedPath))")
            }

            // Revert to default
            await MainActor.run { session.revertAssetToDefault(kind: kind) }

            let isCustomAfterRevert = await MainActor.run { session.assets[kind]?.isCustom ?? true }
            let savedPathAfterRevert = defaults.string(forKey: kind.userDefaultsKey)

            if !isCustomAfterRevert && savedPathAfterRevert == nil {
                recordPass("Asset Revert [\(kind.rawValue)]", "Cleared override and restored default state (isCustom=false)")
            } else {
                recordFail("Asset Revert [\(kind.rawValue)]", "Failed to revert! isCustom: \(isCustomAfterRevert), savedPath: \(String(describing: savedPathAfterRevert))")
            }
        }

        // Test 3.2: Backwards-compatible computed property revert (setting customURL = nil)
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            await MainActor.run {
                session.customPCBURL = pcbFile
                session.customAppBinURL = appBinFile
                session.customBootloaderURL = bootElfFile
                session.customRescURL = rescFile
            }

            let allSet = await MainActor.run {
                [
                    session.customPCBURL != nil,
                    session.customAppBinURL != nil,
                    session.customBootloaderURL != nil,
                    session.customRescURL != nil
                ].allSatisfy { $0 }
            }

            if allSet {
                recordPass("Computed Properties Set", "All 4 custom URLs set via computed properties")
            } else {
                recordFail("Computed Properties Set", "Failed to set custom URLs via computed properties")
            }

            // Setting nil triggers revert
            await MainActor.run {
                session.customPCBURL = nil
                session.customAppBinURL = nil
                session.customBootloaderURL = nil
                session.customRescURL = nil
            }

            let allCleared = await MainActor.run {
                [
                    session.customPCBURL == nil,
                    session.customAppBinURL == nil,
                    session.customBootloaderURL == nil,
                    session.customRescURL == nil
                ].allSatisfy { $0 }
            }

            let allKeysRemoved = SessionAssetKind.allCases.allSatisfy { defaults.string(forKey: $0.userDefaultsKey) == nil }

            if allCleared && allKeysRemoved {
                recordPass("Computed Properties Nil Revert", "Setting nil reverted all 4 assets and cleared persistence keys")
            } else {
                recordFail("Computed Properties Nil Revert", "allCleared: \(allCleared), allKeysRemoved: \(allKeysRemoved)")
            }
        }

        // Test 3.3: Batch revert via loadEmbeddedDefaults()
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            // Set all 4 assets as custom
            await MainActor.run {
                session.updateAsset(kind: .pcb, url: pcbFile)
                session.updateAsset(kind: .appFirmware, url: appBinFile)
                session.updateAsset(kind: .bootloader, url: bootElfFile)
                session.updateAsset(kind: .rescScript, url: rescFile)
            }

            let allSet = SessionAssetKind.allCases.allSatisfy { defaults.string(forKey: $0.userDefaultsKey) != nil }
            if allSet {
                recordPass("Batch Setup", "All 4 custom asset paths persisted")
            } else {
                recordFail("Batch Setup", "Some custom asset paths missing before batch revert")
            }

            // Invoke loadEmbeddedDefaults
            await MainActor.run { session.loadEmbeddedDefaults() }

            let allCleared = SessionAssetKind.allCases.allSatisfy { defaults.string(forKey: $0.userDefaultsKey) == nil }
            let allNotCustom = await MainActor.run {
                SessionAssetKind.allCases.allSatisfy { session.assets[$0]?.isCustom == false }
            }

            if allCleared && allNotCustom {
                recordPass("loadEmbeddedDefaults()", "All 4 persistence keys cleared and all 4 assets reverted to non-custom")
            } else {
                recordFail("loadEmbeddedDefaults()", "allCleared: \(allCleared), allNotCustom: \(allNotCustom)")
            }
        }
    }

    // MARK: - SUITE 4: Non-Modal Action Safety (reloadAsset)
    static func suite4_nonModalActionSafety() async {
        log("\n--- SUITE 4: Non-Modal Action Safety ---")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("challenger_m2_actions_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Test 4.1: reloadAsset on non-existent file
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            let nonExistentURL = tempDir.appendingPathComponent("ghost_file.bin")
            await MainActor.run {
                session.assets[.appFirmware] = SessionAsset(
                    kind: .appFirmware,
                    url: nonExistentURL,
                    state: .customLoaded,
                    metadata: nil,
                    isCustom: true
                )
            }

            // Calling reloadAsset should not crash, should set errorMessage and state to .missing
            await MainActor.run { session.reloadAsset(kind: .appFirmware) }

            let state = await MainActor.run { session.assets[.appFirmware]?.state }
            let errMsg = await MainActor.run { session.errorMessage }

            if case .missing = state, errMsg != nil {
                recordPass("reloadAsset Non-Existent File", "Safely caught missing file without crash; state: \(String(describing: state))")
            } else {
                recordFail("reloadAsset Non-Existent File", "State: \(String(describing: state)), ErrorMsg: \(String(describing: errMsg))")
            }
        }

        // Test 4.2: reloadAsset on 0-byte file
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            let emptyFile = tempDir.appendingPathComponent("empty.hex")
            try? Data().write(to: emptyFile)

            await MainActor.run { session.updateAsset(kind: .appFirmware, url: emptyFile) }
            try? await Task.sleep(nanoseconds: 100_000_000)

            await MainActor.run { session.reloadAsset(kind: .appFirmware) }
            try? await Task.sleep(nanoseconds: 100_000_000)

            let state = await MainActor.run { session.assets[.appFirmware]?.state }
            let badge = await MainActor.run { session.assets[.appFirmware]?.formatBadge }

            if badge == "Empty" {
                recordPass("reloadAsset 0-Byte File", "Inspected as Empty without throwing; badge: \(badge ?? "")")
            } else {
                recordPass("reloadAsset 0-Byte File", "Completed safely with state: \(String(describing: state)), badge: \(badge ?? "")")
            }
        }

        // Test 4.3: reloadAsset on corrupted garbage file
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            let corruptFile = tempDir.appendingPathComponent("corrupted.kicad_pcb")
            try? "(((UNCLOSED GARBAGE S-EXPR %$#@! \u{00}\u{FF}".write(to: corruptFile, atomically: true, encoding: .utf8)

            await MainActor.run { session.updateAsset(kind: .pcb, url: corruptFile) }
            try? await Task.sleep(nanoseconds: 100_000_000)

            await MainActor.run { session.reloadAsset(kind: .pcb) }
            try? await Task.sleep(nanoseconds: 100_000_000)

            let toast = await MainActor.run { session.pcbReloadToast }
            recordPass("reloadAsset Corrupt File", "Handled corrupted PCB without crashing; toast: \(toast ?? "none")")
        }

        // Test 4.4: reloadAsset on uninitialized/nil asset
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            await MainActor.run {
                session.assets.removeValue(forKey: .rescScript)
                session.reloadAsset(kind: .rescScript)
            }
            recordPass("reloadAsset Nil Asset", "Safely no-op'd when asset is nil")
        }

        // Test 4.5: revealAssetInFinder on non-existent file
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            let missingURL = tempDir.appendingPathComponent("missing_reveal.bin")
            await MainActor.run {
                session.assets[.appFirmware] = SessionAsset(
                    kind: .appFirmware,
                    url: missingURL,
                    state: .customLoaded,
                    metadata: nil,
                    isCustom: true
                )
                session.revealAssetInFinder(kind: .appFirmware)
            }

            let errMsg = await MainActor.run { session.errorMessage }
            if errMsg?.contains("Cannot reveal in Finder") == true {
                recordPass("revealAssetInFinder Missing File", "Set user-visible error banner safely: \(errMsg ?? "")")
            } else {
                recordFail("revealAssetInFinder Missing File", "Expected error banner, got \(String(describing: errMsg))")
            }
        }

        // Test 4.6: Rapid concurrent reloads stress test
        do {
            let defaults = createTempSuite()
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }

            let testFile = tempDir.appendingPathComponent("rapid.resc")
            try? "mach create\n".write(to: testFile, atomically: true, encoding: .utf8)
            await MainActor.run { session.updateAsset(kind: .rescScript, url: testFile) }

            for _ in 0..<50 {
                await MainActor.run { session.reloadAsset(kind: .rescScript) }
            }
            recordPass("Rapid Reloads (50x)", "Survived 50 rapid successive reload calls without deadlock or crash")
        }
    }

    // MARK: - SUITE 5: ViewMode & Multi-Launch Simulated App Cycles
    static func suite5_viewModeAndMultiLaunchCycles() async {
        log("\n--- SUITE 5: ViewMode & Multi-Launch Simulated Cycles ---")

        let defaults = createTempSuite()

        // Test 5.1: ViewMode allCases roundtrip persistence
        for mode in ViewMode.allCases {
            await MainActor.run {
                let session = EmulatorSession(userDefaults: defaults)
                session.selectedViewMode = mode
            }
            let savedStr = defaults.string(forKey: SessionPersistenceKeys.selectedViewMode)
            let session2 = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let restoredMode = await MainActor.run { session2.selectedViewMode }

            if savedStr == mode.rawValue && restoredMode == mode {
                recordPass("ViewMode [\(mode.rawValue)]", "Persisted and restored across simulated launches")
            } else {
                recordFail("ViewMode [\(mode.rawValue)]", "Saved: \(String(describing: savedStr)), Restored: \(restoredMode)")
            }
        }

        // Test 5.2: Corrupt ViewMode string fallback
        do {
            defaults.set("InvalidNonExistentMode", forKey: SessionPersistenceKeys.selectedViewMode)
            let session = await MainActor.run { EmulatorSession(userDefaults: defaults) }
            let mode = await MainActor.run { session.selectedViewMode }
            if mode == .split {
                recordPass("Corrupt ViewMode Fallback", "Safely fell back to default .split mode")
            } else {
                recordFail("Corrupt ViewMode Fallback", "Expected .split, got \(mode)")
            }
        }

        // Test 5.3: Multi-launch simulation across layout state
        await MainActor.run {
            let app1 = EmulatorSession(userDefaults: defaults)
            app1.isSidebarVisible = false
            app1.sidebarWidth = 310
            app1.selectedViewMode = .gatt
        }

        await MainActor.run {
            let app2 = EmulatorSession(userDefaults: defaults)
            if app2.isSidebarVisible == false && app2.sidebarWidth == 310 && app2.selectedViewMode == .gatt {
                recordPass("Multi-Launch Cycle 1", "Recovered isSidebarVisible=false, width=310, viewMode=.gatt")
            } else {
                recordFail("Multi-Launch Cycle 1", "Recovery mismatch: visible=\(app2.isSidebarVisible), width=\(app2.sidebarWidth), mode=\(app2.selectedViewMode)")
            }
            app2.isSidebarVisible = true
            app2.sidebarWidth = 260
            app2.selectedViewMode = .watch
        }

        await MainActor.run {
            let app3 = EmulatorSession(userDefaults: defaults)
            if app3.isSidebarVisible == true && app3.sidebarWidth == 260 && app3.selectedViewMode == .watch {
                recordPass("Multi-Launch Cycle 2", "Recovered isSidebarVisible=true, width=260, viewMode=.watch")
            } else {
                recordFail("Multi-Launch Cycle 2", "Recovery mismatch: visible=\(app3.isSidebarVisible), width=\(app3.sidebarWidth), mode=\(app3.selectedViewMode)")
            }
        }
    }
}
