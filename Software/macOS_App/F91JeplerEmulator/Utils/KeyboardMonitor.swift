import Foundation
import AppKit

public final class KeyboardMonitor {
    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?
    private var mouseDownMonitor: Any?
    
    public var onKeyDown: ((String) -> Void)?
    public var onKeyUp: ((String) -> Void)?
    public var onBlur: (() -> Void)?
    
    public init() {}
    
    public func start() {
        stop()
        
        // Defocus text input fields when clicking outside
        mouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            if let window = NSApp.keyWindow, let responder = window.firstResponder {
                if responder is NSTextView || responder is NSTextField || responder is NSText {
                    if let contentView = window.contentView {
                        let hit = contentView.hitTest(event.locationInWindow)
                        if !(hit is NSTextView || hit is NSTextField || hit is NSText) {
                            DispatchQueue.main.async {
                                window.makeFirstResponder(nil)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            window.makeFirstResponder(nil)
                        }
                    }
                }
            }
            return event
        }
        
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // If the user is typing in a text field or search box, do not intercept hotkeys
            if let responder = NSApp.keyWindow?.firstResponder,
               (responder is NSTextView || responder is NSTextField || responder is NSText) {
                return event
            }
            
            if let key = self?.keyFrom(event: event) {
                if !event.isARepeat {
                    self?.onKeyDown?(key)
                }
                return nil // Swallow hotkey event (1/2/3) so system beep doesn't sound
            }
            return event
        }
        
        keyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            if let responder = NSApp.keyWindow?.firstResponder,
               (responder is NSTextView || responder is NSTextField || responder is NSText) {
                return event
            }
            
            if let key = self?.keyFrom(event: event) {
                self?.onKeyUp?(key)
                return nil
            }
            return event
        }
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onBlur?()
        }
    }
    
    public func stop() {
        if let monitor = mouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            mouseDownMonitor = nil
        }
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
        }
        if let monitor = keyUpMonitor {
            NSEvent.removeMonitor(monitor)
            keyUpMonitor = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    private func keyFrom(event: NSEvent) -> String? {
        // macOS Key codes:
        // 18 = '1', 83 = Numpad 1, 37 = 'L'
        // 19 = '2', 84 = Numpad 2, 46 = 'M'
        // 20 = '3', 85 = Numpad 3, 0 = 'A', 49 = Space
        switch event.keyCode {
        case 18, 83, 37: // 1 or L (Light / Button A)
            return "1"
        case 19, 84, 46: // 2 or M (Mode / Button B)
            return "2"
        case 20, 85, 0, 49: // 3 or A or Space (Alarm/Toggle / Button C)
            return "3"
        default:
            if let chars = event.charactersIgnoringModifiers?.lowercased() {
                if chars == "1" || chars == "l" { return "1" }
                if chars == "2" || chars == "m" { return "2" }
                if chars == "3" || chars == "a" || chars == " " { return "3" }
            }
            return nil
        }
    }
    
    deinit {
        stop()
    }
}
