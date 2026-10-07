import XCTest
@testable import F91JeplerEmulator

final class FirmwareHarnessProtocolTests: XCTestCase {
    func testAcknowledgementMatchesExactIDAndField() {
        let output = """
        [TEST] ACK 4 time OK
        [TEST] ACK 5 timezone OK
        """
        XCTAssertEqual(FirmwareHarnessProtocol.acknowledgment(in: output, id: 5, field: "timezone"), "OK")
        XCTAssertNil(FirmwareHarnessProtocol.acknowledgment(in: output, id: 4, field: "timezone"))
        XCTAssertNil(FirmwareHarnessProtocol.acknowledgment(in: output, id: 5, field: "time"))
    }

    func testOnlyExplicitErrorAckIsReturnedForMatchingRequest() {
        let output = "noise ACK 8 time OK\n[TEST] ACK 8 time ERR -90\n"
        XCTAssertEqual(FirmwareHarnessProtocol.acknowledgment(in: output, id: 8, field: "time"), "ERR -90")
        XCTAssertNil(FirmwareHarnessProtocol.acknowledgment(in: "[TEST] ACK 8 time MAYBE", id: 8, field: "time"))
    }

    func testStateMaskRequiresMatchingRequestIDAndValidMask() {
        let output = "[TEST] STATE 9 buttons=2 seconds=3\n"
        XCTAssertEqual(FirmwareHarnessProtocol.buttonMask(in: output, id: 9), 2)
        XCTAssertNil(FirmwareHarnessProtocol.buttonMask(in: output, id: 8))
        XCTAssertNil(FirmwareHarnessProtocol.buttonMask(in: "[TEST] STATE 9 buttons=9 seconds=3", id: 9))
        XCTAssertNil(FirmwareHarnessProtocol.buttonMask(in: "buttons=2", id: 9))
    }
}
