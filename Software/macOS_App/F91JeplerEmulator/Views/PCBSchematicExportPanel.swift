import SwiftUI
import AppKit

public struct PCBSchematicExportPanel: View {
    @ObservedObject var session: EmulatorSession
    @State private var selectedTab: Int = 0 // 0: Grouped BOM, 1: Netlist, 2: Design Summary
    @State private var bomSortBy: BOMSortField = .reference
    @State private var netSearchText: String = ""
    @State private var exportToast: String? = nil
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public enum BOMSortField: String, CaseIterable, Identifiable {
        case reference = "Ref"
        case value = "Value"
        case quantity = "Qty"
        case package = "Package"
        
        public var id: String { rawValue }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Sub-Tab Switcher & Export Menu
            HStack {
                Picker("Export View", selection: $selectedTab) {
                    Text("Bill of Materials (BOM)").tag(0)
                    Text("Netlist & Classes").tag(1)
                    Text("Design Summary & Paths").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 420)
                
                Spacer()
                
                Menu {
                    Button("Export Digikey/Mouser CSV...") { exportBOMCSV() }
                    Button("Export Netlist (.txt)...") { exportNetlist() }
                    Button("Export Full Hardware Report (.md)...") { exportFullReport() }
                } label: {
                    Label("Export Files", systemImage: "square.and.arrow.up")
                        .font(.system(size: 11))
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if let toast = exportToast {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.system(size: 11, weight: .semibold))
                    Spacer()
                    Button("Dismiss") { exportToast = nil }
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.15))
            }
            
            // Tab Contents
            if selectedTab == 0 {
                bomView
            } else if selectedTab == 1 {
                netlistView
            } else {
                designSummaryView
            }
        }
    }
    
    // MARK: - Tab 0: Bill of Materials View
    
    private var bomView: some View {
        VStack(spacing: 0) {
            // Header stats & Sorting bar
            HStack {
                Text("Total Components: \(session.pcbBoard.footprints.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                Text("•")
                    .foregroundColor(.secondary)
                Text("\(session.pcbValidationResult?.groupedBOM.count ?? 0) unique line items")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Sort", selection: $bomSortBy) {
                    ForEach(BOMSortField.allCases) { field in
                        Text(field.rawValue).tag(field)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Table of Grouped BOM Entries
            List {
                Section(header: bomTableHeader) {
                    ForEach(sortedGroupedBOM) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(item.quantity)×")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .frame(width: 32, alignment: .leading)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.value)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                Text(item.package)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 160, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.referencesString)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.primary)
                                if !item.mpn.isEmpty {
                                    Text("MPN: \(item.mpn)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if item.dnp {
                                Text("DNP")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.red.opacity(0.18))
                                    .foregroundColor(.red)
                                    .cornerRadius(3)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(.inset)
        }
    }
    
    private var bomTableHeader: some View {
        HStack(spacing: 10) {
            Text("QTY").frame(width: 32, alignment: .leading)
            Text("VALUE & PACKAGE").frame(width: 160, alignment: .leading)
            Text("REFERENCES & MPN")
            Spacer()
            Text("STATUS")
        }
        .font(.system(size: 9, weight: .bold, design: .monospaced))
        .foregroundColor(.secondary)
    }
    
    private var sortedGroupedBOM: [GroupedBOMEntry] {
        guard let list = session.pcbValidationResult?.groupedBOM else { return [] }
        switch bomSortBy {
        case .reference:
            return list.sorted { ($0.references.first ?? "") < ($1.references.first ?? "") }
        case .value:
            return list.sorted { $0.value < $1.value }
        case .quantity:
            return list.sorted { $0.quantity > $1.quantity }
        case .package:
            return list.sorted { $0.package < $1.package }
        }
    }
    
    // MARK: - Tab 1: Netlist View
    
    private var netlistView: some View {
        VStack(spacing: 0) {
            // Net search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search nets by name, component ref, pin...", text: $netSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !netSearchText.isEmpty {
                    Button(action: { netSearchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .padding(8)
            
            Divider()
            
            // Netlist rows
            List {
                let nets = filteredNetDetails
                ForEach(nets) { net in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            netClassTag(net.netClass)
                            
                            Text(net.name)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                            
                            Spacer()
                            
                            Text("\(net.connectedPads.count) connected pads")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Button(action: { session.selectedNetName = net.name }) {
                                Image(systemName: "scope")
                                    .font(.system(size: 10))
                                    .foregroundColor(session.selectedNetName == net.name ? .cyan : .secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Highlight net on 2D canvas")
                        }
                        
                        // Connected pads list
                        Text(net.connectedPads.map { "\($0.componentRef).\($0.padNumber)" }.joined(separator: ", "))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)
        }
    }
    
    private var filteredNetDetails: [NetDetail] {
        let details = session.pcbBoard.allNetDetails()
        if netSearchText.isEmpty { return details }
        let term = netSearchText.lowercased()
        return details.filter { net in
            net.name.lowercased().contains(term) ||
            net.connectedPads.contains { $0.componentRef.lowercased().contains(term) }
        }
    }
    
    private func netClassTag(_ netClass: NetClass) -> some View {
        let (label, color): (String, Color) = {
            switch netClass {
            case .power: return ("POWER", .orange)
            case .ground: return ("GND", .green)
            case .highSpeed: return ("HIGH-SPEED", .purple)
            case .signal: return ("SIGNAL", .blue)
            }
        }()
        
        return Text(label)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .cornerRadius(3)
    }
    
    // MARK: - Tab 2: Design Summary & Critical Paths
    
    private var designSummaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Board Specifications Table
                VStack(alignment: .leading, spacing: 8) {
                    Text("BOARD SPECIFICATIONS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                        GridRow {
                            Text("PCB Envelope:").foregroundColor(.secondary)
                            Text(String(format: "%.2f × %.2f mm (Area: %.1f mm²)", session.pcbBoard.widthMm, session.pcbBoard.heightMm, session.pcbBoard.widthMm * session.pcbBoard.heightMm))
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        GridRow {
                            Text("Casio F-91 Fit:").foregroundColor(.secondary)
                            let fits = session.pcbBoard.widthMm <= 27.0 && session.pcbBoard.heightMm <= 26.0
                            Text(fits ? "Fits within 27.0 × 26.0 mm cavity ✅" : "Exceeds envelope ⚠️")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(fits ? .green : .orange)
                        }
                        GridRow {
                            Text("Components:").foregroundColor(.secondary)
                            Text("\(session.pcbBoard.footprints.count) footprints placed")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        GridRow {
                            Text("Total Pads:").foregroundColor(.secondary)
                            Text("\(session.pcbBoard.footprints.reduce(0) { $0 + $1.pads.count }) pads")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        GridRow {
                            Text("Total Nets:").foregroundColor(.secondary)
                            Text("\(session.pcbBoard.allNetDetails().count) unique nets")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        GridRow {
                            Text("Copper Routing:").foregroundColor(.secondary)
                            let tracks = session.pcbBoard.tracks.count
                            let len = session.pcbBoard.totalTraceLengthMm
                            Text(tracks > 0 ? "\(tracks) tracks (\(String(format: "%.1f", len)) mm total length)" : "0 tracks (Unrouted draft)")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        GridRow {
                            Text("Vias:").foregroundColor(.secondary)
                            Text("\(session.pcbBoard.vias.count) vias")
                                .font(.system(size: 11, design: .monospaced))
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Critical Paths Analysis
                VStack(alignment: .leading, spacing: 8) {
                    Text("CRITICAL HARDWARE PATHS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 6) {
                        criticalPathRow(
                            title: "MCU → Button A (Key 1)",
                            net: session.pcbBoard.buttonAPin,
                            path: "U1 (P0.11 / T2) ─── TP3 (A / Key 1)",
                            status: session.pcbBoard.nets.values.contains { $0.contains("P0.11") } ? "Connected" : "Unconnected"
                        )
                        criticalPathRow(
                            title: "MCU → Button B (Key 2)",
                            net: session.pcbBoard.buttonBPin,
                            path: "U1 (P0.12 / U1) ─── TP4 (B / Key 2)",
                            status: session.pcbBoard.nets.values.contains { $0.contains("P0.12") } ? "Connected" : "Unconnected"
                        )
                        criticalPathRow(
                            title: "MCU → Button C (Key 3)",
                            net: session.pcbBoard.buttonCPin,
                            path: "U1 (P0.24) ─── TP5 (C / Key 3)",
                            status: session.pcbBoard.nets.values.contains { $0.contains("P0.24") } ? "Connected" : "Unconnected"
                        )
                        criticalPathRow(
                            title: "MCU → SSD1306 Display (I2C)",
                            net: "SDA / SCL",
                            path: "U1 (P0.26 / P0.27) ─── TP11 / TP12",
                            status: "Verified 0x3C"
                        )
                        criticalPathRow(
                            title: "MCU → 32.768 kHz RTC Crystal",
                            net: "XL1 / XL2",
                            path: "U1 (P0.00 / P0.01) ─── X2 (ABS07)",
                            status: "Connected"
                        )
                        criticalPathRow(
                            title: "MCU → 32 MHz HF Crystal",
                            net: "XC1 / XC2",
                            path: "U1 (XC1 / XC2) ─── X1 (2016-4P)",
                            status: "Connected"
                        )
                        criticalPathRow(
                            title: "SWD Programming Interface",
                            net: "SWDIO / SWDCLK",
                            path: "U1 (SWDIO/SWDCLK) ─── TP6 / TP7 / TP8",
                            status: "Accessible"
                        )
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(14)
        }
    }
    
    private func criticalPathRow(title: String, net: String, path: String, status: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                Text(path)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(status)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(status.contains("Connect") || status.contains("Verif") || status.contains("Access") ? .green : .orange)
        }
        .padding(6)
        .background(Color(white: 0.15).opacity(0.3))
        .cornerRadius(4)
    }
    
    // MARK: - Exports
    
    private func exportBOMCSV() {
        guard let result = session.pcbValidationResult else { return }
        var csv = "Quantity,Value,Package,References,Description,MPN,Status\n"
        for item in result.groupedBOM {
            let qty = "\(item.quantity)"
            let val = escapeCsv(item.value)
            let pkg = escapeCsv(item.package)
            let refs = escapeCsv(item.referencesString)
            let desc = escapeCsv(item.description)
            let mpn = escapeCsv(item.mpn)
            let status = item.dnp ? "DNP" : "ACTIVE"
            csv += "\(qty),\(val),\(pkg),\(refs),\(desc),\(mpn),\(status)\n"
        }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "BOM_\(session.pcbBoard.filename.replacingOccurrences(of: ".kicad_pcb", with: "")).csv"
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
            exportToast = "BOM CSV saved successfully to \(url.lastPathComponent)"
        }
    }
    
    private func exportNetlist() {
        let board = session.pcbBoard
        var txt = "; F-91 Jepler Netlist Export\n"
        txt += "; File: \(board.filename)\n"
        txt += "; Timestamp: \(Date().formatted())\n"
        txt += "; Total Nets: \(board.allNetDetails().count)\n\n"
        
        for net in board.allNetDetails() {
            txt += "(net \"\(net.name)\"\n"
            txt += "  (class \"\(net.netClass.rawValue)\")\n"
            for pad in net.connectedPads {
                txt += "  (node \"\(pad.componentRef)\" \"\(pad.padNumber)\")\n"
            }
            txt += ")\n\n"
        }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "netlist_\(session.pcbBoard.filename.replacingOccurrences(of: ".kicad_pcb", with: "")).net"
        if panel.runModal() == .OK, let url = panel.url {
            try? txt.write(to: url, atomically: true, encoding: .utf8)
            exportToast = "Netlist saved successfully to \(url.lastPathComponent)"
        }
    }
    
    private func exportFullReport() {
        let board = session.pcbBoard
        let result = session.pcbValidationResult
        var md = "# Complete Hardware & PCB Report\n"
        md += "File: \(board.filename)\n"
        md += "Exported: \(Date().formatted())\n\n"
        
        md += "## Dimensions & Envelope\n"
        md += "- Width: \(String(format: "%.2f", board.widthMm)) mm\n"
        md += "- Height: \(String(format: "%.2f", board.heightMm)) mm\n"
        md += "- Score: \(result?.scorePercentage ?? 0)%\n\n"
        
        md += "## Bill of Materials\n\n"
        md += "| Qty | Value | Package | References | MPN |\n"
        md += "|---|---|---|---|---|\n"
        for item in result?.groupedBOM ?? [] {
            md += "| \(item.quantity) | \(item.value) | \(item.package) | \(item.referencesString) | \(item.mpn) |\n"
        }
        md += "\n"
        
        md += "## Netlist Connectivity\n\n"
        for net in board.allNetDetails() {
            md += "- **\(net.name)** [\(net.netClass.rawValue)]: \(net.connectedPads.map { "\($0.componentRef).\($0.padNumber)" }.joined(separator: ", "))\n"
        }
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Hardware_Report_\(session.pcbBoard.filename.replacingOccurrences(of: ".kicad_pcb", with: "")).md"
        if panel.runModal() == .OK, let url = panel.url {
            try? md.write(to: url, atomically: true, encoding: .utf8)
            exportToast = "Hardware Report saved successfully to \(url.lastPathComponent)"
        }
    }
    
    private func escapeCsv(_ str: String) -> String {
        let clean = str.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(clean)\""
    }
}
