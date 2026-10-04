import SwiftUI
import AppKit

public struct TerminalView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    var activeRawLogText: String {
        session.selectedTerminalTab == 0 ? session.uartLogs : session.processOutputBuffer
    }
    
    var filteredLogLines: [String] {
        let lines = activeRawLogText.components(separatedBy: .newlines)
        return lines.filter { line in
            let matchesCategory = session.selectedLogCategory.matches(line: line)
            guard matchesCategory else { return false }
            
            if session.terminalSearchText.isEmpty {
                return true
            } else {
                return line.localizedCaseInsensitiveContains(session.terminalSearchText)
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header: Source Picker, Category Chips, Search, Actions
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Picker(selection: $session.selectedTerminalTab, label: Text("")) {
                        Text("Zephyr UART").tag(0)
                        Text("Renode Monitor").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    
                    // Search bar
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search terminal output...", text: $session.terminalSearchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                        if !session.terminalSearchText.isEmpty {
                            Button(action: { session.terminalSearchText = "" }) {
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
                    
                    Toggle("Auto-scroll", isOn: $session.terminalAutoScroll)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 10))
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(filteredLogLines.joined(separator: "\n"), forType: .string)
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
                        if session.selectedTerminalTab == 0 {
                            session.uartLogs = ""
                        } else {
                            session.processOutputBuffer = ""
                        }
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
                        Button(action: { session.selectedLogCategory = cat }) {
                            Text(cat.rawValue)
                                .font(.system(size: 9.5, weight: session.selectedLogCategory == cat ? .bold : .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(session.selectedLogCategory == cat ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(session.selectedLogCategory == cat ? .white : .primary)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Text("\(filteredLogLines.count) lines")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Console Terminal View with ANSI Color Rendering
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if filteredLogLines.isEmpty {
                            Text(session.selectedTerminalTab == 0 ? "Waiting for Zephyr UART stream / MCUboot..." : "Waiting for Renode console stream...")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(10)
                        } else {
                            ForEach(0..<filteredLogLines.count, id: \.self) { idx in
                                let line = filteredLogLines[idx]
                                Text(AnsiParser.parseToAttributedString(text: line))
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
                .onChange(of: filteredLogLines.count) { _ in
                    if session.terminalAutoScroll {
                        proxy.scrollTo("terminalBottomID", anchor: .bottom)
                    }
                }
                .onChange(of: session.selectedTerminalTab) { _ in
                    if session.terminalAutoScroll {
                        proxy.scrollTo("terminalBottomID", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private func exportLogs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = []
        savePanel.nameFieldStringValue = "f91_jepler_\(session.selectedTerminalTab == 0 ? "uart" : "renode")_log.txt"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let clean = AnsiParser.stripAnsi(from: filteredLogLines.joined(separator: "\n"))
            try? clean.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
