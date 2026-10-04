import SwiftUI
import AppKit

public struct TerminalView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    var filteredLogs: String {
        if session.terminalSearchText.isEmpty {
            return session.uartLogs
        } else {
            return session.uartLogs
                .components(separatedBy: .newlines)
                .filter { $0.localizedCaseInsensitiveContains(session.terminalSearchText) }
                .joined(separator: "\n")
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header controls
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search UART logs...", text: $session.terminalSearchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
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
                    NSPasteboard.general.setString(session.uartLogs, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
                
                Button(action: { session.uartLogs = "" }) {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .font(.system(size: 11))
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Console Terminal Box
            ScrollViewReader { proxy in
                ScrollView([.vertical, .horizontal]) {
                    Text(filteredLogs.isEmpty ? "Waiting for MCUboot / UART output..." : filteredLogs)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(red: 0.85, green: 0.9, blue: 0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .id("bottomID")
                }
                .background(Color(red: 0.08, green: 0.1, blue: 0.09))
                .onChange(of: session.uartLogs) { _ in
                    if session.terminalAutoScroll {
                        proxy.scrollTo("bottomID", anchor: .bottom)
                    }
                }
            }
        }
    }
}
