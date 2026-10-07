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

    func testPCBLabelsAppearAtProgressiveZoomOrSelection() {
        XCTAssertFalse(PCBViewportLayout.showsFootprintLabel(zoom: 4, isCritical: false, isSelected: false, isHovered: false))
        XCTAssertTrue(PCBViewportLayout.showsFootprintLabel(zoom: 6, isCritical: true, isSelected: false, isHovered: false))
        XCTAssertTrue(PCBViewportLayout.showsFootprintLabel(zoom: 4, isCritical: false, isSelected: true, isHovered: false))
        XCTAssertTrue(PCBViewportLayout.showsFootprintLabel(zoom: 10, isCritical: false, isSelected: false, isHovered: false))
    }
}
