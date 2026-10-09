import XCTest
@testable import F91JeplerEmulator

final class ButtonReleaseTests: XCTestCase {
    @MainActor
    func testClickReleasesWhilePCBSelectionRemains() async throws {
        let session = EmulatorSession()
        session.selectedFootprintID = "Switch1"
        session.buttonClick(key: "1", durationMs: 20)
        XCTAssertTrue(session.pressedKeys.contains("1"))
        try await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertFalse(session.pressedKeys.contains("1"))
        XCTAssertEqual(session.selectedFootprintID, "Switch1")
    }

    @MainActor
    func testHoldReleaseDoesNotDependOnPCBSelection() {
        let session = EmulatorSession()
        session.selectedFootprintID = "Switch2"
        session.buttonDown(key: "2")
        XCTAssertTrue(session.pressedKeys.contains("2"))
        session.buttonUp(key: "2")
        XCTAssertFalse(session.pressedKeys.contains("2"))
        XCTAssertEqual(session.selectedFootprintID, "Switch2")
    }
}
