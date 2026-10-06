import SwiftUI
import AppKit

@MainActor
public struct TerminalView: View {
    @ObservedObject var logStore: TerminalLogStore
    var session: EmulatorSession?
    
    @State private var monitorInputText: String = ""
    @State private var commandHistory: [String] = []
    @State private var historyIndex: Int = -1
    
    public init(session: EmulatorSession) {
        self.session = session
        self.logStore = session.logStore
    }
    
    public init(logStore: TerminalLogStore) {
        self.session = nil
        self.logStore = logStore
    }
    
    public init() {
        self.session = nil
        self.logStore = .shared
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header: Source Picker, Category Chips, Search, Actions
            VStack(spacing: 6) {
                WrappingToolbar(spacing: 8) {
                    Picker(selection: $logStore.selectedTab, label: Text("")) {
                        Text("Zephyr UART").tag(0)
                        Text("Renode Monitor").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    
                    // Search bar
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search terminal output...", text: $logStore.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                        if !logStore.searchText.isEmpty {
                            Button(action: { logStore.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .frame(width: 220)
                    
                    Toggle("Auto-scroll", isOn: $logStore.autoScroll)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 10))
                    
                    Button(action: {
                        let text = logStore.filteredLines.map(\.raw).joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    
                    Button(action: exportLogs) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                    
                    Button(action: {
                        logStore.clear(tab: logStore.selectedTab)
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                }
                
                // Category Filter Chips
                WrappingToolbar(spacing: 6) {
                    Text("Filter:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(LogCategory.allCases) { cat in
                        Button(action: { logStore.selectedCategory = cat }) {
                            Text(cat.rawValue)
                                .font(.system(size: 9.5, weight: logStore.selectedCategory == cat ? .bold : .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(logStore.selectedCategory == cat ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(logStore.selectedCategory == cat ? .white : .primary)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    
                    Text("\(logStore.filteredLines.count.formatted()) lines")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // High-Performance Incremental Console Terminal View with ANSI Color Pre-rendering
            ConsoleTerminalTextView(logStore: logStore)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Interactive Renode Monitor Command Bar (only visible when Renode Monitor is selected)
            if logStore.selectedTab == 1 {
                VStack(spacing: 5) {
                    Divider()
                    
                    // Quick Action Chips
                    WrappingToolbar(spacing: 6) {
                        Text("Quick Commands:")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        let quickCmds = ["start", "pause", "step", "mach", "sysbus.cpu PC", "help"]
                        ForEach(quickCmds, id: \.self) { cmd in
                            Button(action: {
                                session?.sendRenodeCommand(cmd)
                            }) {
                                Text(cmd)
                                    .font(.system(size: 9.5, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                    
                    // Command Prompt Input
                    HStack(spacing: 6) {
                        Text("(monitor) >")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        TextField("Enter Renode monitor command (e.g. sysbus.cpu PC, pause, start)...", text: $monitorInputText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .onSubmit {
                                sendCurrentCommand()
                            }
                        
                        Button(action: sendCurrentCommand) {
                            HStack(spacing: 3) {
                                Image(systemName: "return")
                                Text("Run")
                            }
                            .font(.system(size: 10, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(monitorInputText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
    
    private func sendCurrentCommand() {
        let cmd = monitorInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        
        commandHistory.append(cmd)
        historyIndex = commandHistory.count
        monitorInputText = ""
        
        session?.sendRenodeCommand(cmd)
    }
    
    private func exportLogs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = []
        savePanel.nameFieldStringValue = "f91_jepler_\(logStore.selectedTab == 0 ? "uart" : "renode")_log.txt"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let clean = AnsiParser.stripAnsi(from: logStore.filteredLines.map(\.raw).joined(separator: "\n"))
            try? clean.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

public struct ConsoleTerminalTextView: NSViewRepresentable {
    @ObservedObject var logStore: TerminalLogStore
    
    public init(logStore: TerminalLogStore) {
        self.logStore = logStore
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(red: 0.05, green: 0.07, blue: 0.06, alpha: 1.0)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = NSColor(red: 0.05, green: 0.07, blue: 0.06, alpha: 1.0)
        textView.textColor = NSColor(red: 0.88, green: 0.92, blue: 0.88, alpha: 1.0)
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.isRichText = true
        textView.importsGraphics = false
        textView.drawsBackground = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        
        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              let textStorage = textView.textStorage else { return }
        
        let currentTab = logStore.selectedTab
        let currentCategory = logStore.selectedCategory
        let currentSearch = logStore.searchText
        let currentRevision = logStore.logRevision
        let lines = logStore.filteredLines
        let autoScroll = logStore.autoScroll
        
        let fullResetNeeded = (context.coordinator.renderedTab != currentTab) ||
                              (context.coordinator.renderedCategory != currentCategory) ||
                              (context.coordinator.renderedSearchText != currentSearch) ||
                              (lines.isEmpty && context.coordinator.renderedLineCount > 0) ||
                              (lines.count < context.coordinator.renderedLineCount) ||
                              (context.coordinator.renderedRevision == -1)
        
        if fullResetNeeded {
            context.coordinator.renderedTab = currentTab
            context.coordinator.renderedCategory = currentCategory
            context.coordinator.renderedSearchText = currentSearch
            context.coordinator.renderedRevision = currentRevision
            context.coordinator.renderedLineCount = lines.count
            
            if lines.isEmpty {
                let placeholderText = (currentTab == 0) ? "Waiting for Zephyr UART stream / MCUboot..." : "Waiting for Renode console stream..."
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: NSColor.gray
                ]
                textStorage.beginEditing()
                textStorage.setAttributedString(NSAttributedString(string: placeholderText, attributes: attrs))
                textStorage.endEditing()
            } else {
                let defaultAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: NSColor(red: 0.88, green: 0.92, blue: 0.88, alpha: 1.0)
                ]
                let newline = NSAttributedString(string: "\n", attributes: defaultAttrs)
                let full = NSMutableAttributedString()
                for (idx, line) in lines.enumerated() {
                    full.append(line.attributed)
                    if idx < lines.count - 1 {
                        full.append(newline)
                    }
                }
                textStorage.beginEditing()
                textStorage.setAttributedString(full)
                textStorage.endEditing()
            }
            
            if autoScroll {
                DispatchQueue.main.async {
                    context.coordinator.scrollToBottom(nsView)
                }
            }
        } else if currentRevision != context.coordinator.renderedRevision {
            // Incremental fast-path: only append the new lines
            context.coordinator.renderedRevision = currentRevision
            let oldCount = context.coordinator.renderedLineCount
            let newCount = lines.count
            
            if newCount > oldCount {
                let appendedLines = lines[oldCount..<newCount]
                let defaultAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: NSColor(red: 0.88, green: 0.92, blue: 0.88, alpha: 1.0)
                ]
                let newline = NSAttributedString(string: "\n", attributes: defaultAttrs)
                let appendChunk = NSMutableAttributedString()
                
                if oldCount == 0 {
                    // Transitioning from empty placeholder
                    textStorage.beginEditing()
                    textStorage.setAttributedString(NSAttributedString(string: ""))
                    textStorage.endEditing()
                } else if textStorage.length > 0 {
                    appendChunk.append(newline)
                }
                
                for (idx, line) in appendedLines.enumerated() {
                    appendChunk.append(line.attributed)
                    if idx < appendedLines.count - 1 {
                        appendChunk.append(newline)
                    }
                }
                
                textStorage.beginEditing()
                textStorage.append(appendChunk)
                textStorage.endEditing()
                
                context.coordinator.renderedLineCount = newCount
                
                if autoScroll {
                    DispatchQueue.main.async {
                        context.coordinator.scrollToBottom(nsView)
                    }
                }
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator {
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var renderedLineCount: Int = 0
        var renderedTab: Int = -1
        var renderedCategory: LogCategory = .all
        var renderedSearchText: String = ""
        var renderedRevision: Int = -1
        
        public init() {}
        
        func scrollToBottom(_ scrollView: NSScrollView) {
            guard let documentView = scrollView.documentView else { return }
            let maxY = max(0, documentView.frame.height - scrollView.contentView.bounds.height)
            let targetPoint = NSPoint(x: 0, y: maxY)
            if abs(scrollView.contentView.bounds.origin.y - targetPoint.y) > 2.0 {
                scrollView.contentView.scroll(to: targetPoint)
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }
    }
}
