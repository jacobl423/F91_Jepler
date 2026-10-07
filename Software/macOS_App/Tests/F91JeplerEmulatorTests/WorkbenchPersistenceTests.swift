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
}
