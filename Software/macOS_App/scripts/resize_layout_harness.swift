// Run with swiftc alongside Views/ResponsiveLayout.swift; no XCTest installation required.
import SwiftUI

@main
struct SplitPaneSizingTests {
    static func main() {
        let tests = SplitPaneSizingTests()
        tests.testReservesBottomPaneAndDivider()
        tests.testShortWindowsNeverOverflow()
        tests.testRestoresPreferredHeightAfterWindowGrows()
        tests.testDraggingStartsAtVisibleHeightAfterShrink()
        print("PASS: split sizing, 5,005 short-window cases, restoration, and drag baseline")
    }

    private func assertEqual(_ lhs: CGFloat, _ rhs: CGFloat) { precondition(lhs == rhs) }
    private func assertGreaterThanOrEqual(_ lhs: CGFloat, _ rhs: CGFloat) { precondition(lhs >= rhs) }
    private func assertLessThanOrEqual(_ lhs: CGFloat, _ rhs: CGFloat) { precondition(lhs <= rhs) }
    private func height(_ preferred: CGFloat, in available: CGFloat) -> CGFloat {
        SplitPaneSizing.topHeight(preferred: preferred, available: available,
                                  minimum: 200, maximum: 600)
    }

    func testReservesBottomPaneAndDivider() {
        assertEqual(height(600, in: 500), 333)
        assertEqual(height(900, in: 1000), 600)
        assertEqual(height(-100, in: 500), 200)
    }

    func testShortWindowsNeverOverflow() {
        for available in stride(from: CGFloat(0), through: 1000, by: 1) {
            for preferred: CGFloat in [-100, 0, 200, 400, 900] {
                let top = height(preferred, in: available)
                let usable = max(0, available - 7)
                assertGreaterThanOrEqual(top, 0)
                assertLessThanOrEqual(top, usable)
                assertGreaterThanOrEqual(usable - top, min(160, usable / 2))
            }
        }
    }

    func testRestoresPreferredHeightAfterWindowGrows() {
        let preferred: CGFloat = 480
        assertEqual(height(preferred, in: 400), 233)
        assertEqual(height(preferred, in: 900), preferred)
    }

    func testDraggingStartsAtVisibleHeightAfterShrink() {
        let visible = height(600, in: 500)
        assertEqual(height(visible - 20, in: 500), 313)
        assertEqual(height(visible - 40, in: 500), 293)
    }
}
