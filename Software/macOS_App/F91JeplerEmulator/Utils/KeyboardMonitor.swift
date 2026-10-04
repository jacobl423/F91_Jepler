import Foundation
import AppKit

public final class KeyboardMonitor {
    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?
    
    public var onKeyDown: ((String) -> Void)?
    public var onKeyUp: ((String) -> Void)?
    public var onBlur: (() -> Void)?
    
    public init() {}
    
    public func start() {
        stop()
        
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
        // 18 = '1', 19 = '2', 20 = '3'
        // 83 = Numpad 1, 84 = Numpad 2, 85 = Numpad 3
        switch event.keyCode {
        case 18, 83: return "1"
        case 19, 84: return "2"
        case 20, 85: return "3"
        default:
            if let chars = event.charactersIgnoringModifiers {
                if chars == "1" { return "1" }
                if chars == "2" { return "2" }
                if chars == "3" { return "3" }
            }
            return nil
        }
    }
    
    deinit {
        stop()
    }
}
