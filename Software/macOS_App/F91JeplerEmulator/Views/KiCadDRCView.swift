import SwiftUI
import AppKit

public struct KiCadDRCView: View {
    @ObservedObject var session: EmulatorSession
    @State private var filterSeverity: String = "All"
    @State private var searchText: String = ""
    
    public var onZoomToPosition: ((Double, Double) -> Void)? = nil
    
    public init(session: EmulatorSession, onZoomToPosition: ((Double, Double) -> Void)? = nil) {
        self.session = session
        self.onZoomToPosition = onZoomToPosition
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header summary
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(session.kicadDRCReport?.isClean == true ? .green : .orange)
                    Text("KICAD DESIGN RULES CHECK (DRC)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                
                Spacer()
                
                if let report = session.kicadDRCReport {
                    HStack(spacing: 8) {
                        Badge(count: report.errorCount, label: "Errors", color: .red)
                        Badge(count: report.warningCount, label: "Warnings", color: .orange)
                        Badge(count: report.unconnectedCount, label: "Unconnected", color: .yellow)
                    }
                }
                
                Button(action: { session.runKiCadDRC() }) {
                    if session.isRunningDRC {
                        ProgressView().controlSize(.mini)
                    } else {
                        Label("Run KiCad DRC", systemImage: "play.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.system(size: 11))
                .disabled(session.isRunningDRC)
            }
            .padding(10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Filter Bar
            HStack(spacing: 8) {
                Picker("Severity", selection: $filterSeverity) {
                    Text("All").tag("All")
                    Text("Errors").tag("error")
                    Text("Warnings").tag("warning")
                    Text("Unconnected").tag("unconnected")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
                
                Spacer()
                
                TextField("Search rule or net...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // List of items
            if let report = session.kicadDRCReport {
                let items = filteredItems(report: report)
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 36))
                            .foregroundColor(.green)
                        Text("No DRC violations matching filter")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(items) { item in
                            DRCViolationRow(item: item) { pos in
                                onZoomToPosition?(pos.x, pos.y)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .listStyle(.inset)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No KiCad DRC Report Available")
                        .font(.system(size: 13, weight: .bold))
                    Text("Run KiCad DRC directly on 'f91_jepler.kicad_pcb' using kicad-cli")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Button("Run KiCad DRC Now") {
                        session.runKiCadDRC()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }
        }
    }
    
    private func filteredItems(report: KiCadDRCReport) -> [KiCadDRCViolation] {
        var all = report.violations + report.unconnected
        if filterSeverity != "All" {
            if filterSeverity == "unconnected" {
                all = report.unconnected
            } else {
                all = all.filter { $0.severity == filterSeverity }
            }
        }
        if !searchText.isEmpty {
            all = all.filter { $0.description.localizedCaseInsensitiveContains(searchText) || $0.type.localizedCaseInsensitiveContains(searchText) }
        }
        return all
    }
}

private struct Badge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Circle().fill(count > 0 ? color : Color.gray.opacity(0.4)).frame(width: 6, height: 6)
            Text("\(count) \(label)")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(count > 0 ? color : .secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.12))
        .cornerRadius(4)
    }
}

private struct DRCViolationRow: View {
    let item: KiCadDRCViolation
    let onZoom: ((x: Double, y: Double)) -> Void
    
    var severityColor: Color {
        switch item.severity.lowercased() {
        case "error": return .red
        case "warning": return .orange
        default: return .yellow
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(item.severity.uppercased())
                    .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(severityColor.opacity(0.18))
                    .cornerRadius(3)
                
                Text(item.type)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                
                Spacer()
                
                if let pos = item.primaryPosition {
                    Button(action: { onZoom(pos) }) {
                        Label(String(format: "Zoom: (%.1f, %.1f mm)", pos.x, pos.y), systemImage: "scope")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
            
            Text(item.description)
                .font(.system(size: 11))
                .foregroundColor(.primary)
            
            if !item.items.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(item.items.prefix(3)) { sub in
                        HStack(spacing: 4) {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(sub.description)
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(severityColor.opacity(0.3), lineWidth: 1))
    }
}
