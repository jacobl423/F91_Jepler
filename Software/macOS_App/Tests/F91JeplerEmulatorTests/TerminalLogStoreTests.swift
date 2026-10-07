import XCTest
@testable import F91JeplerEmulator

final class TerminalLogStoreTests: XCTestCase {
    @MainActor
    func testSplitUARTRecordsRemainIntact() {
        let store = TerminalLogStore()
        var records: [String] = []
        store.onUartLine = { records.append($0) }
        store.appendUart(text: "[TEST] ACK 7 pi")
        store.flushPendingBuffers()
        XCTAssertTrue(store.filteredLines.isEmpty)
        store.appendUart(text: "ng OK\r\nWatch screen ready\r\n")
        store.flushPendingBuffers()
        XCTAssertEqual(records, ["[TEST] ACK 7 ping OK", "Watch screen ready"])
        XCTAssertEqual(store.filteredLines.count, 2)
    }

    @MainActor
    func testHistoryIsBoundedAndHiddenSourceDoesNotRebuildVisibleLog() {
        let store = TerminalLogStore(maximumLines: 3)
        store.appendUart(text: "one\ntwo\nthree\nfour\n")
        store.flushPendingBuffers()
        XCTAssertEqual(store.filteredLines.map(\.raw), ["two", "three", "four"])
        XCTAssertEqual(store.discardedLineCount, 1)
        let revision = store.logRevision
        store.appendRenodeConsole(text: "monitor message\n")
        store.flushPendingBuffers()
        XCTAssertEqual(store.logRevision, revision)
        store.selectedTab = 1
        XCTAssertEqual(store.filteredText, "monitor message")
    }

    @MainActor
    func testRadioWarningsAreGroupedButErrorsRemainVisible() {
        let store = TerminalLogStore()
        store.selectedTab = 1
        store.appendRenodeConsole(text: (0..<100).map {
            "[\($0)] [WARNING] radio: Unhandled read from offset 0x114\n"
        }.joined() + "[ERROR] startup failed\n[ERROR] startup failed\n")
        store.flushPendingBuffers()
        XCTAssertEqual(store.groupedRadioWarnings, 99)
        XCTAssertEqual(store.filteredLines.count, 3)
        XCTAssertEqual(store.filteredLines.filter { $0.raw.contains("[ERROR]") }.count, 2)
    }
}
