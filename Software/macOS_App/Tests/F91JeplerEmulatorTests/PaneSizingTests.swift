import XCTest
@testable import F91JeplerEmulator

final class PaneSizingTests: XCTestCase {
    func testColumnsFitMinimumWindowAndPreserveCanvasDuringResize() {
        for width in stride(from: CGFloat(860), through: 2400, by: 20) {
            for left in [CGFloat(246), 396] {
                for right in [CGFloat(276), 1200] {
                    for visible in [false, true] {
                        let result = WorkbenchColumnSizing.widths(available: width, sidebar: left,
                            terminal: right, sidebarVisible: visible, terminalVisible: visible)
                        XCTAssertGreaterThanOrEqual(width - result.left - result.right - 40, 280)
                        XCTAssertLessThanOrEqual(result.left, 396)
                    }
                }
            }
        }
    }

    func testVerticalSplitReservesBottomPaneAtShortHeights() {
        for height in stride(from: CGFloat(100), through: 1000, by: 10) {
            let top = SplitPaneSizing.topHeight(preferred: 600, available: height, minimum: 200, maximum: 600)
            XCTAssertGreaterThanOrEqual(top, 0)
            XCTAssertGreaterThanOrEqual(height - 7 - top, min(160, (height - 7) / 2))
        }
    }
}
