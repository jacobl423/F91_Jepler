import XCTest
@testable import F91JeplerEmulator

final class OnboardingAndPinAuditTests: XCTestCase {
    func testPinAuditExplainsMissingFirmwareBinding() {
        let result = GPIOPinAuditor.audit(board: KiCadBoard(), expectedPins: [:])
        let button = try! XCTUnwrap(result.entries.first(where: { $0.signalName == "Button A · Light" }))
        XCTAssertEqual(button.expectedPin, "Unknown (firmware)")
        XCTAssertTrue(button.repairGuidance?.contains("Build & Run") == true)
    }

    func testPinAuditExplainsMissingPCBConnectionWhenFirmwarePinExists() {
        let result = GPIOPinAuditor.audit(board: KiCadBoard(), expectedPins: ["buttonA": "P0.11"])
        let button = try! XCTUnwrap(result.entries.first(where: { $0.signalName == "Button A · Light" }))
        XCTAssertEqual(button.expectedPin, "P0.11")
        XCTAssertEqual(button.detectedPin, "Unknown (PCB)")
        XCTAssertTrue(button.repairGuidance?.contains("switch-to-U1") == true)
    }

    func testPCBViewportFitsWithinInsetAndRejectsInvalidGeometry() {
        let zoom = try! XCTUnwrap(PCBViewportLayout.fittedZoom(
            boardWidthMm: 100, boardHeightMm: 50, canvasSize: CGSize(width: 500, height: 400)
        ))
        XCTAssertEqual(zoom, 4.28, accuracy: 0.001)
        XCTAssertNil(PCBViewportLayout.fittedZoom(
            boardWidthMm: .nan, boardHeightMm: 50, canvasSize: CGSize(width: 500, height: 400)
        ))
    }

    func testPCBViewportZoomPreservesPointUnderCursorAndSupportsZoomingOutBelowTwo() {
        let point = CGPoint(x: 300, y: 200)
        let canvasSize = CGSize(width: 800, height: 600)
        let panOffset = CGSize(width: 40, height: -20)
        let initialScale: CGFloat = 0.5
        let initialBoardPoint = CGPoint(
            x: (point.x - canvasSize.width / 2 - panOffset.width) / initialScale,
            y: (point.y - canvasSize.height / 2 - panOffset.height) / initialScale
        )

        let zoomed = try! XCTUnwrap(PCBViewportLayout.zoomed(
            scale: initialScale,
            factor: 0.8,
            around: point,
            canvasSize: canvasSize,
            panOffset: panOffset
        ))
        let resultingBoardPoint = CGPoint(
            x: (point.x - canvasSize.width / 2 - zoomed.panOffset.width) / zoomed.scale,
            y: (point.y - canvasSize.height / 2 - zoomed.panOffset.height) / zoomed.scale
        )

        XCTAssertEqual(zoomed.scale, 0.4, accuracy: 0.001)
        XCTAssertEqual(resultingBoardPoint.x, initialBoardPoint.x, accuracy: 0.001)
        XCTAssertEqual(resultingBoardPoint.y, initialBoardPoint.y, accuracy: 0.001)
    }

    func testPCBViewportZoomClampsToSupportedRange() {
        let zoomed = try! XCTUnwrap(PCBViewportLayout.zoomed(
            scale: 0.5,
            factor: 0.01,
            around: CGPoint(x: 100, y: 100),
            canvasSize: CGSize(width: 300, height: 300),
            panOffset: .zero
        ))

        XCTAssertEqual(zoomed.scale, PCBViewportLayout.minimumZoom)
    }

    func testPCBLabelsAppearAtProgressiveZoomOrSelection() {
        XCTAssertFalse(PCBViewportLayout.showsFootprintLabel(zoom: 4, isCritical: false, isSelected: false, isHovered: false))
        XCTAssertTrue(PCBViewportLayout.showsFootprintLabel(zoom: 6, isCritical: true, isSelected: false, isHovered: false))
        XCTAssertTrue(PCBViewportLayout.showsFootprintLabel(zoom: 4, isCritical: false, isSelected: true, isHovered: false))
        XCTAssertTrue(PCBViewportLayout.showsFootprintLabel(zoom: 10, isCritical: false, isSelected: false, isHovered: false))
    }
}
