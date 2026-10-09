import AppKit
import XCTest
@testable import F91JeplerEmulator

final class WindowFrameTests: XCTestCase {
    @MainActor
    func testRestoresAndSavesFrameWithAnExistingSwiftUIAutosaveName() {
        _ = NSApplication.shared
        let name = NSWindow.FrameAutosaveName("WindowFrameTests-\(UUID().uuidString)")
        defer { NSWindow.removeFrame(usingName: name) }
        let frame = NSRect(x: 100, y: 120, width: 1000, height: 700)
        let source = NSWindow(contentRect: frame, styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        source.setFrame(frame, display: false)
        source.saveFrame(usingName: name)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 860, height: 620),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        let priorName = NSWindow.FrameAutosaveName("SwiftUI-\(UUID().uuidString)")
        defer { NSWindow.removeFrame(usingName: priorName) }
        window.setFrameAutosaveName(priorName)
        let probe = WindowStateRestorer.WindowProbe()
        probe.frameName = name
        window.contentView = probe
        NotificationCenter.default.post(name: NSWindow.didBecomeKeyNotification, object: window)
        XCTAssertEqual(window.frame, frame)
        XCTAssertEqual(window.frameAutosaveName, name)
        let resized = NSRect(x: 140, y: 160, width: 1100, height: 740)
        window.setFrame(resized, display: false)
        NotificationCenter.default.post(name: NSWindow.didResizeNotification, object: window)
        XCTAssertTrue(source.setFrameUsingName(name, force: true))
        XCTAssertEqual(source.frame, resized)
    }
}
