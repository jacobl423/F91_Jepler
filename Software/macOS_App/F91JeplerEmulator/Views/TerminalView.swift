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
            
            // Console Terminal View with ANSI Color Rendering & Stable Identity
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if logStore.filteredLines.isEmpty {
                            Text(logStore.selectedTab == 0 ? "Waiting for Zephyr UART stream / MCUboot..." : "Waiting for Renode console stream...")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(10)
                        } else {
                            ForEach(logStore.filteredLines) { line in
                                Text(line.attributedText)
                                    .font(.system(size: 11, design: .monospaced))
                                    .lineSpacing(1.5)
                                    .textSelection(.enabled)
                            }
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("terminalBottomID")
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(10)
                }
                .background(Color(red: 0.05, green: 0.07, blue: 0.06))
                .onChange(of: logStore.filteredLines.count) { _ in
                    if logStore.autoScroll {
                        proxy.scrollTo("terminalBottomID", anchor: .bottom)
                    }
                }
                .onChange(of: logStore.selectedTab) { _ in
                    if logStore.autoScroll {
                        proxy.scrollTo("terminalBottomID", anchor: .bottom)
                    }
                }
            }
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
