import XCTest
@testable import F91JeplerEmulator

final class WorkbenchPersistenceTests: XCTestCase {
    @MainActor
    func testOLEDColorSurvivesStoreRecreationAndInvalidValueFallsBack() {
        let name = "WorkbenchPersistenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = DisplayStreamStore(userDefaults: defaults)
        store.oledTheme = .amber
        XCTAssertEqual(DisplayStreamStore(userDefaults: defaults).oledTheme, .amber)
        defaults.set("removed-theme", forKey: "workbench.oledTheme")
        XCTAssertEqual(DisplayStreamStore(userDefaults: defaults).oledTheme, .white)
    }

    @MainActor
    func testPaneSizesSurviveSessionRecreation() {
        let name = "WorkbenchPersistenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let session = EmulatorSession(userDefaults: defaults)
        session.sidebarWidth = 390
        session.terminalWidth = 425
        session.watchPanelHeight = 475
        let restored = EmulatorSession(userDefaults: defaults)
        XCTAssertEqual(restored.sidebarWidth, 390)
        XCTAssertEqual(restored.terminalWidth, 425)
        XCTAssertEqual(restored.watchPanelHeight, 475)
    }

    @MainActor
    func testExternalAssetSelectionsSurviveSessionRecreationAndCanBeCleared() throws {
        let name = "WorkbenchPersistenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let session = EmulatorSession(userDefaults: defaults)
        let selectedURLs: [SessionAssetKind: URL] = [
            .pcb: directory.appendingPathComponent("board.kicad_pcb"),
            .appFirmware: directory.appendingPathComponent("app.bin"),
            .bootloader: directory.appendingPathComponent("bootloader.elf")
        ]
        for (kind, url) in selectedURLs {
            try Data([1, 2, 3]).write(to: url)
            session.updateAsset(kind: kind, url: url)
        }

        let restored = EmulatorSession(userDefaults: defaults)
        for (kind, url) in selectedURLs {
            XCTAssertEqual(
                restored.assets[kind]?.fileURL?.resolvingSymlinksInPath(),
                url.resolvingSymlinksInPath()
            )
            XCTAssertTrue(restored.assets[kind]?.isCustom == true)
            XCTAssertNotNil(defaults.data(forKey: kind.bookmarkUserDefaultsKey!))
        }

        restored.clearAssetSelections()
        for kind in selectedURLs.keys {
            XCTAssertNil(defaults.data(forKey: kind.bookmarkUserDefaultsKey!))
            XCTAssertNil(restored.assets[kind]?.fileURL)
        }
        session.clearAssetSelections()
    }
}
