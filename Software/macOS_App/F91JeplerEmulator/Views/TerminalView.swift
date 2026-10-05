import SwiftUI
import AppKit

@MainActor
public struct TerminalView: View {
    @ObservedObject var logStore: TerminalLogStore
    
    public init(session: EmulatorSession) {
        self.logStore = session.logStore
    }
    
    public init(logStore: TerminalLogStore) {
        self.logStore = logStore
    }
    
    public init() {
        self.logStore = .shared
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header: Source Picker, Category Chips, Search, Actions
            VStack(spacing: 6) {
                HStack(spacing: 10) {
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
                    
                    Spacer()
                    
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
                HStack(spacing: 6) {
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
                    
                    Spacer()
                    
                    Text("\(logStore.filteredLines.count) lines")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Console Terminal View with ANSI Color Rendering & Rock-Solid AppKit NSTextView
            ConsoleTerminalTextView(
                text: logStore.filteredText,
                placeholder: logStore.selectedTab == 0 ? "Waiting for Zephyr UART stream / MCUboot..." : "Waiting for Renode console stream...",
                autoScroll: logStore.autoScroll
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
    let text: String
    let placeholder: String
    let autoScroll: Bool
    
    public init(text: String, placeholder: String, autoScroll: Bool) {
        self.text = text
        self.placeholder = placeholder
        self.autoScroll = autoScroll
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
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        
        let displayText = text.isEmpty ? placeholder : text
        if context.coordinator.lastRenderedText != displayText {
            context.coordinator.lastRenderedText = displayText
            
            if text.isEmpty {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: NSColor.gray
                ]
                textView.textStorage?.setAttributedString(NSAttributedString(string: placeholder, attributes: attrs))
            } else {
                let attributed = AnsiParser.parseToNSAttributedString(text: displayText)
                textView.textStorage?.setAttributedString(attributed)
            }
            
            if autoScroll && !text.isEmpty {
                DispatchQueue.main.async {
                    textView.scrollToEndOfDocument(nil)
                }
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator {
        var textView: NSTextView?
        var lastRenderedText: String = ""
        public init() {}
    }
}
