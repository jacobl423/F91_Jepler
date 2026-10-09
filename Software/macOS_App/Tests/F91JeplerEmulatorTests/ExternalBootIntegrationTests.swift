import XCTest
@testable import F91JeplerEmulator

final class ExternalBootIntegrationTests: XCTestCase {
    @MainActor
    func testExternalComponentsBootWithPackagedRenode() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let rootPath = environment["JEPLER_INTEGRATION_ROOT"] else {
            throw XCTSkip("Set JEPLER_INTEGRATION_ROOT to run the packaged Renode boot check.")
        }
        let root = URL(fileURLWithPath: rootPath)
        let name = "ExternalBootIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let session = EmulatorSession(userDefaults: defaults)
        defer { session.stopSession() }
        #if arch(arm64)
        let architecture = "arm64"
        #else
        let architecture = "x86_64"
        #endif
        session.customRenodePath = root.appendingPathComponent("Software/macOS_App/build/Jepler Dev.app/Contents/Resources/Renode/\(architecture)/renode").path
        let components = environment["JEPLER_INTEGRATION_COMPONENTS"].map { URL(fileURLWithPath: $0) }
        session.updateAsset(kind: .pcb, url: components?.appendingPathComponent("PCBs/f91_main_board_nf.kicad_pcb") ?? root.appendingPathComponent("Hardware/KiCad/f91_main_board_nf/f91_main_board_nf.kicad_pcb"))
        session.updateAsset(kind: .appFirmware, url: components?.appendingPathComponent("Firmwares/app.signed.bin") ?? root.appendingPathComponent("build/renode-app/app.signed.bin"))
        session.updateAsset(kind: .bootloader, url: components?.appendingPathComponent("Bootloaders/mcuboot.elf") ?? root.appendingPathComponent("build/renode-app/mcuboot.elf"))
        for _ in 0..<100 {
            if session.canStartSession { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertTrue(session.canStartSession, "External components did not become ready: \(session.assets)")
        session.startSession()
        for _ in 0..<300 {
            if session.isFirmwareReady && session.isBridgeReady { break }
            if session.errorMessage != nil { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertNil(session.errorMessage)
        XCTAssertTrue(session.isRunning, session.statusMessage)
        XCTAssertTrue(session.isFirmwareReady, session.uartLogs)
        XCTAssertTrue(session.isBridgeReady, session.uartLogs)
        guard session.isBridgeReady else { return }
        session.injectNotification(payload: NotificationPayload())
        for _ in 0..<150 {
            if !session.isHarnessBusy { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertTrue(session.notificationTestSucceeded, session.notificationTestStatus ?? "No notification result")
        session.clearAsset(kind: .bootloader)
        XCTAssertFalse(session.isRunning)
        XCTAssertFalse(session.canStartSession)
    }
}
