# Handoff Report: Milestone 2 — Toolbar Controls, Header Toggles, Keyboard Shortcuts & State Persistence

## Executive Summary
This report delivers the comprehensive architectural analysis and complete production-ready Swift code specifications for Milestone 2 toolbar controls, header bar toggle buttons, keyboard shortcuts, and state persistence in the Jepler Dev macOS application. It establishes zero-conflict keyboard shortcuts (`⌘0` and `⌥⌘S`), resolves a critical event-swallowing bug in `KeyboardMonitor.swift` that conflicted with view shortcuts (`⌘1`..`⌘3`), introduces native `.navigation` toolbar and `AppTopBarView` visual toggle controls, and verifies dual-key `UserDefaults` persistence for `jepler.sidebar.visible` (with fallback to `jepler.sidebar.isVisible`).

---

## 1. Observation

### 1.1 Existing Window Toolbar & Commands Structure
- **Target File**: `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift` (lines 120–126):
  ```swift
  .toolbar {
      ToolbarItem(placement: .primaryAction) {
          Button(action: { session.showSetupSheet = true }) {
              Label("Configure Workbench", systemImage: "gearshape")
          }
      }
  }
  ```
  *Finding*: Currently, `ContentView` only defines a single `.primaryAction` toolbar item for "Configure Workbench" (`gearshape`). There is no `.navigation` toolbar item and no dedicated window toolbar button for toggling the sidebar.

- **Target File**: `Software/macOS_App/F91JeplerEmulator/App.swift` (lines 1–14):
  ```swift
  import SwiftUI

  @main
  struct F91JeplerEmulatorApp: App {
      var body: some Scene {
          WindowGroup("Jepler Dev") {
              ContentView()
                  .frame(minWidth: 860, minHeight: 620)
          }
          .windowStyle(.titleBar)
          .windowToolbarStyle(.unified)
      }
  }
  ```
  *Finding*: `App.swift` uses a standard `.unified` window toolbar style without custom commands (`.commands { ... }`). No menu bar commands or global key equivalents are currently attached at the app scene level.

### 1.2 Existing Header Bar Structure (`AppTopBarView`)
- **Target File**: `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift` (lines 223–250):
  ```swift
  public struct AppTopBarView: View {
      @ObservedObject var session: EmulatorSession
      
      public init(session: EmulatorSession) {
          self.session = session
      }
      
      public var body: some View {
          HStack(spacing: 10) {
              // App Branding & Machine Status
              HStack(spacing: 8) {
                  Text("Jepler Dev")
                      .font(.system(size: 13, weight: .bold, design: .rounded))
                      .foregroundColor(.primary)
                  
                  HStack(spacing: 5) {
                      Circle()
                          .fill(session.isRunning ? Color.green : Color.red)
                          .frame(width: 7, height: 7)
                      Text(session.statusMessage)
                          .font(.system(size: 10, weight: .medium, design: .monospaced))
                          .foregroundColor(.secondary)
                          .lineLimit(1)
                  }
              }
              .padding(.leading, 12)
  ```
  *Finding*: The top header bar begins immediately with `Text("Jepler Dev")` and status indicator dots. There is no icon button to collapse or expand the project sidebar, and no visual active/highlight state.

### 1.3 Critical Hotkey Conflict in `KeyboardMonitor.swift`
- **Target File**: `Software/macOS_App/F91JeplerEmulator/Utils/KeyboardMonitor.swift` (lines 39–53, 93–113):
  ```swift
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
  ...
  private func keyFrom(event: NSEvent) -> String? {
      // macOS Key codes:
      // 18 = '1', 83 = Numpad 1
      // 19 = '2', 84 = Numpad 2
      // 20 = '3', 85 = Numpad 3
      switch event.keyCode {
      case 18, 83: // 1
          return "1"
      case 19, 84: // 2
          return "2"
      case 20, 85: // 3
          return "3"
      default:
          if let chars = event.charactersIgnoringModifiers {
              if chars == "1" { return "1" }
              if chars == "2" { return "2" }
              if chars == "3" { return "3" }
          }
          return nil
      }
  }
  ```
  *Critical Observation*: `keyFrom(event:)` inspects `event.keyCode` directly (`18`, `19`, `20`) **without verifying `event.modifierFlags`**.
  - When the user presses `⌘1`, `⌘2`, or `⌘3` (for switching view modes or any standard macOS command), `event.keyCode` matches `18`, `19`, or `20`.
  - `KeyboardMonitor` erroneously treats `⌘1`/`⌘2`/`⌘3` as watch hardware button presses (Light, Mode, Toggle) and executes `return nil`.
  - Returning `nil` **swallows the event completely from the AppKit responder chain**, preventing SwiftUI `.keyboardShortcut` modifiers from ever receiving the event!

### 1.4 State Persistence Key Discrepancy
- **Target File**: `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift` (lines 5–13):
  ```swift
  public enum SessionPersistenceKeys {
      public static let customPcbPath = "jepler.custom.pcb.path"
      public static let customAppBinPath = "jepler.custom.appBin.path"
      public static let customBootloaderPath = "jepler.custom.bootloader.path"
      public static let customRescPath = "jepler.custom.resc.path"
      public static let isSidebarVisible = "jepler.sidebar.isVisible"
      public static let sidebarWidth = "jepler.sidebar.width"
      public static let selectedViewMode = "jepler.viewMode"
  }
  ```
- **Target File**: `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift` (lines 38–48, 234–240):
  ```swift
  @Published public var isSidebarVisible: Bool = true {
      didSet {
          userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.isSidebarVisible)
      }
  }
  ...
  // 1. Restore Sidebar Visibility
  if userDefaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) != nil {
      self.isSidebarVisible = userDefaults.bool(forKey: SessionPersistenceKeys.isSidebarVisible)
  } else {
      self.isSidebarVisible = true
  }
  ```
- **Dispatch Specification**:
  `"Verify state persistence with session.isSidebarVisible and UserDefaults key jepler.sidebar.visible."`
  *Observation*: In Milestone 1, `SessionPersistenceKeys.isSidebarVisible` was assigned string value `"jepler.sidebar.isVisible"`. The Milestone 2 dispatch specifically queries `"jepler.sidebar.visible"`. To ensure 100% test compatibility and backward compatibility with Milestone 1 state, both keys must be synchronized.

---

## 2. Logic Chain

### 2.1 Toolbar Placement & Visual Semantics
1. **From Observation 1.1**: The window toolbar currently only contains a single `.primaryAction` button. In macOS AppKit/SwiftUI design guidelines (macOS 13+), sidebar toggle controls belong in the leading `.navigation` position, immediately adjacent to the window traffic lights and sitting directly above the collapsible sidebar.
2. **SF Symbol Selection**: SF Symbol `"sidebar.leading"` is Apple's standard symbol for left-side navigation toggle buttons across macOS Ventura, Sonoma, and Sequoia.
3. **Animation Requirement**: Rapid snapping or un-animated layout jumps cause jarring visual stutter during split view recalculation. Wrapping all sidebar toggle actions in `.withAnimation(.easeInOut(duration: 0.2))` ensures smooth easing when expanding or collapsing.

### 2.2 Header Bar Toggle (`AppTopBarView`)
1. **From Observation 1.2**: Users focusing on workbench emulation frequently interact with `AppTopBarView` rather than looking at the window title bar.
2. **Visual Active State**: Providing a dedicated button before `Text("Jepler Dev")` gives immediate spatial context (it points directly to the sidebar beneath it).
3. **Highlight Styling**:
   - When the sidebar is visible (`session.isSidebarVisible == true`): Render with `Color.accentColor` icon, subtle accent tint background (`Color.accentColor.opacity(0.15)`), and rounded border overlay (`Color.accentColor.opacity(0.3)`).
   - When collapsed (`session.isSidebarVisible == false`): Render with secondary neutral styling (`Color(NSColor.controlBackgroundColor)`).

### 2.3 Keyboard Shortcut Collision Prevention
1. **From Observation 1.3**: `KeyboardMonitor` catches raw hardware keys `1`, `2`, `3` for Casio watch simulation. Because it failed to inspect modifier flags, it intercepted and swallowed `⌘1`, `⌘2`, `⌘3`.
2. **Resolution**: By filtering `event.modifierFlags.intersection([.command, .control, .option])`:
   - If modifier keys are held, `KeyboardMonitor` immediately returns `event` untouched.
   - Raw keys `1`, `2`, `3` remain 100% functional for watch button emulation.
   - Shortcut `⌘0` (Xcode/macOS Navigator standard) and `⌥⌘S` (macOS Sidebar standard) operate unimpeded.
   - View mode shortcuts `⌘1`..`⌘6` for the workbench tabs (`.watch`, `.canvas`, `.gatt`, `.test`, `.pcb`, `.gdb`) are completely unblocked.

### 2.4 State Persistence Strategy
1. **From Observation 1.4**: To satisfy both the dispatch requirement (`"jepler.sidebar.visible"`) and the existing Milestone 1 implementation (`"jepler.sidebar.isVisible"`):
   - `SessionPersistenceKeys.sidebarVisible` is set to `"jepler.sidebar.visible"`.
   - `SessionPersistenceKeys.legacySidebarVisible` is retained as `"jepler.sidebar.isVisible"`.
   - When `isSidebarVisible` changes, both keys are updated in `userDefaults`.
   - On initialization, `userDefaults` checks `"jepler.sidebar.visible"` first, falls back to `"jepler.sidebar.isVisible"`, and defaults to `true`.

---

## 3. Caveats

1. **No External Dependencies**: All controls and shortcuts rely strictly on native SwiftUI and AppKit APIs; no third-party libraries or keyboard monitoring extensions are introduced.
2. **Split View Frame Coordination**: While this handoff specifies the toolbar and header controls, the actual layout split view container is being integrated by Explorer M2-2 in `ContentView.swift`. The specifications here provide the clean toggle triggers and bindings needed by M2-2.
3. **Xcode / Full Screen Mode**: In macOS native full-screen mode, window toolbar items placed in `.navigation` remain visible in the auto-hiding toolbar overlay.

---

## 4. Conclusion & Production Code Specifications

Below are the exact, production-ready Swift code specifications ready for immediate application by the implementation worker.

### 4.1 Specification 1: `SessionPersistenceKeys` & `EmulatorSession.swift`

#### File: `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift`
Update `SessionPersistenceKeys` to alias and expose both key variants:
```swift
// MARK: - SessionPersistenceKeys

public enum SessionPersistenceKeys {
    public static let customPcbPath = "jepler.custom.pcb.path"
    public static let customAppBinPath = "jepler.custom.appBin.path"
    public static let customBootloaderPath = "jepler.custom.bootloader.path"
    public static let customRescPath = "jepler.custom.resc.path"
    public static let isSidebarVisible = "jepler.sidebar.visible"
    public static let legacyIsSidebarVisible = "jepler.sidebar.isVisible"
    public static let sidebarWidth = "jepler.sidebar.width"
    public static let selectedViewMode = "jepler.viewMode"
}
```

#### File: `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`
Ensure property observer and initialization sync both keys with default `true`:
```swift
    // MARK: - Project Sidebar & Layout State
    @Published public var isSidebarVisible: Bool = true {
        didSet {
            userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.isSidebarVisible)
            userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.legacyIsSidebarVisible)
        }
    }
```
And in `init(userDefaults: UserDefaults = .standard)`:
```swift
        // 1. Restore Sidebar Visibility
        if userDefaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) != nil {
            self.isSidebarVisible = userDefaults.bool(forKey: SessionPersistenceKeys.isSidebarVisible)
        } else if userDefaults.object(forKey: SessionPersistenceKeys.legacyIsSidebarVisible) != nil {
            self.isSidebarVisible = userDefaults.bool(forKey: SessionPersistenceKeys.legacyIsSidebarVisible)
        } else {
            self.isSidebarVisible = true
        }
```

---

### 4.2 Specification 2: `KeyboardMonitor.swift` (Conflict Resolution)

#### File: `Software/macOS_App/F91JeplerEmulator/Utils/KeyboardMonitor.swift`
Guard `keyDownMonitor` and `keyUpMonitor` against command/option/control modifiers so `⌘0`, `⌥⌘S`, and `⌘1`..`⌘6` are never swallowed:
```swift
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // If the user is typing in a text field or search box, do not intercept hotkeys
            if let responder = NSApp.keyWindow?.firstResponder,
               (responder is NSTextView || responder is NSTextField || responder is NSText) {
                return event
            }
            
            // Ignore keystrokes when Command, Control, or Option modifiers are active
            let activeModifiers = event.modifierFlags.intersection([.command, .control, .option])
            if !activeModifiers.isEmpty {
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
            
            let activeModifiers = event.modifierFlags.intersection([.command, .control, .option])
            if !activeModifiers.isEmpty {
                return event
            }
            
            if let key = self?.keyFrom(event: event) {
                self?.onKeyUp?(key)
                return nil
            }
            return event
        }
```

---

### 4.3 Specification 3: Dedicated Header Bar Toggle in `AppTopBarView`

#### File: `Software/macOS_App/F91JeplerEmulator/Views/AppTopBarView.swift` (or `ContentView.swift`)
Add the dedicated sidebar toggle icon button with visual active/highlight state to the leading section:
```swift
import SwiftUI

public struct AppTopBarView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            // MARK: - Leading Section: Sidebar Toggle & App Branding
            HStack(spacing: 8) {
                // Dedicated Sidebar Toggle Icon Button with Visual Active State
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        session.isSidebarVisible.toggle()
                    }
                }) {
                    Image(systemName: "sidebar.leading")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(session.isSidebarVisible ? .accentColor : .secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(session.isSidebarVisible ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(session.isSidebarVisible ? Color.accentColor.opacity(0.35) : Color.gray.opacity(0.2), lineWidth: 0.75)
                        )
                }
                .buttonStyle(.plain)
                .help("Toggle Project Sidebar (⌘0)")
                
                Text("Jepler Dev")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(session.isRunning ? Color.green : Color.red)
                        .frame(width: 7, height: 7)
                    Text(session.statusMessage)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 10)
            
            Divider().frame(height: 18)
            
            // MARK: - Simulation Controls (Start / Stop / Reboot)
            HStack(spacing: 6) {
                Button(action: {
                    if session.isRunning {
                        session.stopSession()
                    } else {
                        session.startSession()
                    }
                }) {
                    Label(session.isRunning ? "Stop" : "Start", systemImage: session.isRunning ? "square.fill" : "play.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(session.isRunning ? .red : .green)
                .controlSize(.small)
                
                Button(action: { session.rebootMachine() }) {
                    Label("Reboot", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!session.isRunning)
            }
            
            Divider().frame(height: 18)
            
            // MARK: - Resizable Horizontal Tab Bar (Workbench Modes)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(ViewMode.allCases.enumerated()), id: \.element.id) { index, mode in
                        Button(action: { session.selectedViewMode = mode }) {
                            HStack(spacing: 5) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(mode.rawValue)
                                    .font(.system(size: 11, weight: session.selectedViewMode == mode ? .bold : .medium))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                session.selectedViewMode == mode ?
                                    Color.accentColor :
                                    Color(NSColor.controlBackgroundColor)
                            )
                            .foregroundColor(
                                session.selectedViewMode == mode ?
                                    .white :
                                    .primary
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .help("Switch to \(mode.rawValue) (⌘\(index + 1))")
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity)
            
            Divider().frame(height: 18)
            
            // MARK: - Trailing Controls: Hardware Key Badges & Settings
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    KeyLegendBadge(key: "1", label: "Light")
                    KeyLegendBadge(key: "2", label: "Mode")
                    KeyLegendBadge(key: "3", label: "Toggle")
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                Button(action: { session.showSetupSheet = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Configure Workbench")
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
```

---

### 4.4 Specification 4: Window Toolbar Item & Dual Keyboard Shortcuts (`ContentView.swift`)

#### File: `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift`
Update `.toolbar` and attach keyboard shortcut listeners:
```swift
        .toolbar {
            // Dedicated Sidebar Toggle Button in Leading Navigation Placement
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        session.isSidebarVisible.toggle()
                    }
                }) {
                    Label("Toggle Project Sidebar", systemImage: "sidebar.leading")
                }
                .keyboardShortcut("0", modifiers: .command)
                .help("Toggle Project Sidebar (⌘0)")
            }
            
            // Workbench Configuration Sheet
            ToolbarItem(placement: .primaryAction) {
                Button(action: { session.showSetupSheet = true }) {
                    Label("Configure Workbench", systemImage: "gearshape")
                }
            }
        }
        // Secondary Keyboard Shortcut: ⌥⌘S
        .background(
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    session.isSidebarVisible.toggle()
                }
            }) {
                EmptyView()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
            .hidden()
        )
```

#### Optional Scene-Level Menu Commands in `App.swift`:
If application menu commands are desired at the scene level:
```swift
@main
struct F91JeplerEmulatorApp: App {
    var body: some Scene {
        WindowGroup("Jepler Dev") {
            ContentView()
                .frame(minWidth: 860, minHeight: 620)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
        }
    }
}
```

---

## 5. Verification Method

### 5.1 Compilation Verification
Run clean build in `Software/macOS_App`:
```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App && swift build
```
*Expected Result*: Build completes with exit code 0.

### 5.2 Persistence & Key Unit Test Specification
Verify `session.isSidebarVisible` persistence against both keys:
```swift
import XCTest
@testable import F91JeplerEmulator

@MainActor
final class SidebarPersistenceTests: XCTestCase {
    var testDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.jepler.test.sidebar.\(UUID().uuidString)")!
    }
    
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: testDefaults.description)
        super.tearDown()
    }
    
    func testSidebarDefaultsToVisibleTrue() {
        let session = EmulatorSession(userDefaults: testDefaults)
        XCTAssertTrue(session.isSidebarVisible, "Sidebar should default to visible true when no saved preference exists")
    }
    
    func testSidebarPersistenceToggling() {
        let session = EmulatorSession(userDefaults: testDefaults)
        session.isSidebarVisible = false
        
        // Assert both keys are written
        XCTAssertFalse(testDefaults.bool(forKey: "jepler.sidebar.visible"))
        XCTAssertFalse(testDefaults.bool(forKey: "jepler.sidebar.isVisible"))
        
        // Assert new session restores false
        let restoredSession = EmulatorSession(userDefaults: testDefaults)
        XCTAssertFalse(restoredSession.isSidebarVisible)
        
        // Toggle back to true
        restoredSession.isSidebarVisible = true
        XCTAssertTrue(testDefaults.bool(forKey: "jepler.sidebar.visible"))
        XCTAssertTrue(testDefaults.bool(forKey: "jepler.sidebar.isVisible"))
    }
    
    func testBackwardCompatibilityWithLegacyKey() {
        // Pre-populate legacy key only
        testDefaults.set(false, forKey: "jepler.sidebar.isVisible")
        let session = EmulatorSession(userDefaults: testDefaults)
        XCTAssertFalse(session.isSidebarVisible, "Should restore false from legacy jepler.sidebar.isVisible key")
    }
}
```

### 5.3 Shortcut Conflict Manual Verification
1. Launch application via `swift run`.
2. Press `⌘0`: Verify sidebar smoothly animates collapsed; press `⌘0` again: verify sidebar expands.
3. Press `⌥⌘S`: Verify secondary shortcut toggles sidebar visibility with identical animation.
4. Press `1`, `2`, `3` with no modifiers: Verify Casio watch buttons Light/Mode/Toggle register in session.
5. Press `⌘1`, `⌘2`, `⌘3`: Verify watch buttons do NOT trigger and system does not beep; view mode switches cleanly.
6. Quit and relaunch application: Verify sidebar collapsed/expanded state persists accurately across restarts.
