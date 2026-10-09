import SwiftUI
import AppKit

/// Remember the native window frame, and let macOS render its unified glass toolbar.
struct WindowStateRestorer: NSViewRepresentable {
    final class WindowProbe: NSView {
        var frameName = NSWindow.FrameAutosaveName("JeplerWorkbench")
        private weak var observedWindow: NSWindow?
        private var observers: [NSObjectProtocol] = []
        private var didRestore = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window, observedWindow !== window else { return }
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
            observedWindow = window
            didRestore = false
            window.titleVisibility = .hidden
            window.titlebarSeparatorStyle = .none
            // SwiftUI may already assign an autosave name. Always use our stable name.
            // Restore after the initial SwiftUI layout rather than during attachment.
            observers.append(NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main
            ) { [weak self] _ in self?.restoreFrame() })
            for event in [NSWindow.didMoveNotification, NSWindow.didResizeNotification,
                          NSWindow.willCloseNotification] {
                observers.append(NotificationCenter.default.addObserver(
                    forName: event, object: window, queue: .main
                ) { [weak self] _ in
                    guard let self, self.didRestore, let window = self.observedWindow,
                          !window.styleMask.contains(.fullScreen), !window.isMiniaturized else { return }
                    window.saveFrame(usingName: self.frameName)
                })
            }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.observedWindow?.isVisible == true else { return }
                self.restoreFrame()
            }
        }

        private func restoreFrame() {
            guard !didRestore, let window = observedWindow else { return }
            window.setFrameUsingName(frameName, force: true)
            window.setFrameAutosaveName(frameName)
            didRestore = true
        }

        deinit {
            observers.forEach(NotificationCenter.default.removeObserver)
        }
    }
    func makeNSView(context: Context) -> NSView { WindowProbe() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

/// Dedicated resize gutters keep the grab targets clear of pane content.
struct WorkbenchSplitView<Leading: View, Center: View, Trailing: View>: View {
    @ObservedObject var session: EmulatorSession
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var center: () -> Center
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        GeometryReader { geometry in
            let available = max(0, geometry.size.width - 40 - 280)
            let leftMinimum: CGFloat = session.isSidebarVisible ? 246 : 60
            let rightMinimum: CGFloat = session.isTerminalVisible ? 276 : 60
            let widths = WorkbenchColumnSizing.widths(
                available: geometry.size.width, sidebar: session.sidebarWidth,
                terminal: session.terminalWidth, sidebarVisible: session.isSidebarVisible,
                terminalVisible: session.isTerminalVisible)
            let left = widths.left
            let right = widths.right
            HStack(spacing: 0) {
                leading().frame(width: left).clipped()
                PaneResizeHandle(width: $session.sidebarWidth, displayedWidth: left,
                                 minimum: leftMinimum, maximum: min(396, available - right), direction: 1)
                    .disabled(!session.isSidebarVisible)
                    .opacity(session.isSidebarVisible ? 1 : 0)
                center().frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                PaneResizeHandle(width: $session.terminalWidth, displayedWidth: right,
                                 minimum: rightMinimum, maximum: available - left, direction: -1)
                    .disabled(!session.isTerminalVisible)
                    .opacity(session.isTerminalVisible ? 1 : 0)
                trailing().frame(width: right).clipped()
            }
            .coordinateSpace(name: "workbenchColumns")
        }
    }
}

private struct PaneResizeHandle: View {
    @Binding var width: CGFloat
    var displayedWidth: CGFloat
    var minimum: CGFloat
    var maximum: CGFloat
    var direction: CGFloat
    @State private var startWidth: CGFloat?
    @State private var hovering = false

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.primary.opacity(hovering || startWidth != nil ? 0.08 : 0))
            .overlay {
                Capsule()
                    .fill(Color.secondary.opacity(hovering || startWidth != nil ? 0.85 : 0.45))
                    .frame(width: 4, height: 44)
                    .allowsHitTesting(false)
            }
            .frame(width: 20)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { inside in
                guard inside != hovering else { return }
                hovering = inside
                if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
            }
            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .named("workbenchColumns"))
                .onChanged { value in
                    if startWidth == nil { startWidth = displayedWidth }
                    width = min(max(minimum, maximum), max(minimum, startWidth! + direction * value.translation.width))
                }
                .onEnded { _ in startWidth = nil })
            .help(direction > 0 ? "Drag to resize the Project pane" : "Drag to resize the Terminal pane")
            .accessibilityLabel(direction > 0 ? "Resize Project pane" : "Resize Terminal pane")
            .accessibilityAdjustableAction { adjustment in
                let delta: CGFloat = adjustment == .increment ? 20 : -20
                width = min(max(minimum, maximum), max(minimum, displayedWidth + delta))
            }
            .onDisappear {
                if hovering { NSCursor.pop(); hovering = false }
            }
    }
}
