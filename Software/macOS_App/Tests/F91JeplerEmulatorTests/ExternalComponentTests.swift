import XCTest
@testable import F91JeplerEmulator

final class ExternalComponentTests: XCTestCase {
    @MainActor
    func testUnbookmarkedPathsAreNotRestoredForSandboxAccess() {
        let name = "ExternalComponentTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        for kind in SessionAssetKind.allCases {
            defaults.set("/tmp/previous-asset", forKey: kind.userDefaultsKey)
        }
        let session = EmulatorSession(userDefaults: defaults)
        XCTAssertTrue(session.assets.values.allSatisfy { $0.fileURL == nil })
        XCTAssertFalse(session.canStartSession)
        session.startSession()
        XCTAssertFalse(session.isSessionStarting)
        XCTAssertNotNil(session.errorMessage)
    }

    @MainActor
    func testMissingFilesAndClearedSelectionBlockStartup() throws {
        let name = "ExternalComponentTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let session = EmulatorSession(userDefaults: defaults)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for kind in [SessionAssetKind.pcb, .appFirmware, .bootloader] {
            let url = directory.appendingPathComponent("\(kind.rawValue).\(kind.allowedExtensions[0])")
            try Data([1]).write(to: url)
            session.assets[kind] = SessionAsset(kind: kind, url: url, state: .customLoaded, isCustom: true)
        }
        XCTAssertTrue(session.canStartSession)
        let firmware = try XCTUnwrap(session.assets[.appFirmware]?.fileURL)
        try FileManager.default.removeItem(at: firmware)
        XCTAssertFalse(session.canStartSession)
        try Data([1]).write(to: firmware)
        session.clearAsset(kind: .bootloader)
        XCTAssertNil(session.assets[.bootloader]?.fileURL)
        XCTAssertFalse(session.canStartSession)
    }
}
