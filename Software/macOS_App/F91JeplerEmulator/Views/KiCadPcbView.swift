import SwiftUI
import AppKit
import CoreGraphics

public struct KiCadPcbView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar & Tab Switcher
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .foregroundColor(.accentColor)
                        Text("KICAD PCB DRAFT INSPECTOR")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(session.pcbBoard.filename)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { exportReport() }) {
                        Label("Export Report", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
                }
                
                Picker("Inspector View", selection: $session.pcbInspectorTab) {
                    Text("2D Layout").tag(0)
                    Text("Diagnostics (\(session.pcbBoard.diagnostics.count))").tag(1)
                    Text("Nets & Components").tag(2)
                    Text("Visual PCB Diff").tag(3)
                }
                .pickerStyle(.segmented)
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            if session.pcbInspectorTab == 0 {
                // Tab 0: 2D PCB Vector Layout Canvas
                VStack(spacing: 4) {
                GeometryReader { geo in
                    let board = session.pcbBoard
                    let availableWidth = max(10, geo.size.width - 24)
                    let availableHeight = max(10, geo.size.height - 24)
                    let scaleX = availableWidth / CGFloat(board.widthMm)
                    let scaleY = availableHeight / CGFloat(board.heightMm)
                    let scale = min(scaleX, scaleY)
                    
                    ZStack {
                        Color(red: 0.05, green: 0.12, blue: 0.08) // Dark green solder mask
                            .cornerRadius(10)
                        
                        Canvas { ctx, size in
                            let offsetX = (size.width - CGFloat(board.widthMm) * scale) / 2.0
                            let offsetY = (size.height - CGFloat(board.heightMm) * scale) / 2.0
                            
                            func toCanvas(_ pt: Point2D) -> CGPoint {
                                CGPoint(
                                    x: offsetX + CGFloat(pt.x - board.minX) * scale,
                                    y: offsetY + CGFloat(pt.y - board.minY) * scale
                                )
                            }
                            
                            // Draw Edge.Cuts Board Outline
                            var path = Path()
                            for seg in board.edgeSegments {
                                if case .line(let start, let end) = seg {
                                    path.move(to: toCanvas(start))
                                    path.addLine(to: toCanvas(end))
                                }
                            }
                            ctx.stroke(path, with: .color(Color(red: 0.85, green: 0.75, blue: 0.3)), lineWidth: 2)
                            
                            // Draw Footprints & Pads
                            for fp in board.footprints {
                                let pos = toCanvas(fp.position)
                                
                                // Draw component body
                                let isSelected = !session.selectedFootprintID.isEmpty && session.selectedFootprintID == fp.reference
                                let rect = CGRect(x: pos.x - 8, y: pos.y - 8, width: 16, height: 16)
                                ctx.stroke(Path(rect), with: .color(isSelected ? .yellow : .white.opacity(0.6)), lineWidth: isSelected ? 2 : 1)
                                
                                // Draw Reference Label
                                ctx.draw(
                                    Text(fp.reference)
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(isSelected ? .yellow : .white.opacity(0.8)),
                                    at: CGPoint(x: pos.x, y: pos.y - 12)
                                )
                                
                                // Draw Pads
                                for pad in fp.pads {
                                    let padPos = toCanvas(pad.position)
                                    let isHighlighted = isPadActive(pad: pad)
                                    
                                    let padSize = CGSize(width: max(4, CGFloat(pad.size.x) * scale), height: max(4, CGFloat(pad.size.y) * scale))
                                    let padRect = CGRect(x: padPos.x - padSize.width/2, y: padPos.y - padSize.height/2, width: padSize.width, height: padSize.height)
                                    
                                    let padColor = isHighlighted ? Color.green : Color(red: 0.85, green: 0.65, blue: 0.25)
                                    ctx.fill(Path(padRect), with: .color(padColor))
                                    
                                    if isHighlighted {
                                        ctx.stroke(Path(padRect.insetBy(dx: -2, dy: -2)), with: .color(.green), lineWidth: 2)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Active Pin Status Bar
                HStack(spacing: 16) {
                    PinStatusBadge(pin: session.pcbBoard.buttonAPin, name: "Button A", isPressed: session.pressedKeys.contains("1"))
                    PinStatusBadge(pin: session.pcbBoard.buttonBPin, name: "Button B", isPressed: session.pressedKeys.contains("2"))
                    PinStatusBadge(pin: session.pcbBoard.buttonCPin, name: "Button C", isPressed: session.pressedKeys.contains("3"))
                }
                .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if session.pcbInspectorTab == 1 {
                // Tab 1: Hardware Diagnostics & Fit Verification List
                List {
                    Section(header: Text("HARDWARE DESIGN CHECKS & VERIFICATION").font(.system(size: 10, weight: .bold, design: .monospaced))) {
                        ForEach(session.pcbBoard.diagnostics) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: item.isOk ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(item.isOk ? .green : .orange)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.system(size: 12, weight: .bold))
                                    Text(item.detail)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.inset)
                
            } else if session.pcbInspectorTab == 2 {
                // Tab 2: Footprints & Netlist Inventory
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Filter nets & component references...", text: $session.pcbNetFilterText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal)
                    
                    List {
                        Section(header: Text("COMPONENTS (\(session.pcbBoard.footprints.count))").font(.system(size: 10, weight: .bold, design: .monospaced))) {
                            ForEach(filteredFootprints) { fp in
                                HStack {
                                    Text(fp.reference)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .frame(width: 60, alignment: .leading)
                                    Text(fp.value)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(fp.pads.count) pads")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    session.selectedFootprintID = fp.reference
                                    session.pcbInspectorTab = 0
                                }
                            }
                        }
                        
                        Section(header: Text("NETLIST (\(session.pcbBoard.nets.count))").font(.system(size: 10, weight: .bold, design: .monospaced))) {
                            ForEach(filteredNets, id: \.key) { key, name in
                                HStack {
                                    Text("Net \(key)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 60, alignment: .leading)
                                    Text(name)
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            } else {
                // Tab 3: Visual PCB Revision Diffing
                PCBDiffView(session: session)
            }
        }
    }
    
    private var filteredFootprints: [Footprint] {
        if session.pcbNetFilterText.isEmpty { return session.pcbBoard.footprints }
        return session.pcbBoard.footprints.filter {
            $0.reference.localizedCaseInsensitiveContains(session.pcbNetFilterText) ||
            $0.value.localizedCaseInsensitiveContains(session.pcbNetFilterText)
        }
    }
    
    private var filteredNets: [(key: Int, value: String)] {
        let sorted = session.pcbBoard.nets.sorted { $0.key < $1.key }
        if session.pcbNetFilterText.isEmpty { return sorted }
        return sorted.filter { $0.value.localizedCaseInsensitiveContains(session.pcbNetFilterText) }
    }
    
    private func isPadActive(pad: Pad) -> Bool {
        let name = pad.netName.uppercased()
        if session.pressedKeys.contains("1") && (name.contains("P0.11") || name.contains("BUTTON_A")) { return true }
        if session.pressedKeys.contains("2") && (name.contains("P0.12") || name.contains("BUTTON_B")) { return true }
        if session.pressedKeys.contains("3") && (name.contains("P0.24") || name.contains("BUTTON_C")) { return true }
        return false
    }
    
    private func exportReport() {
        var report = "# F-91 Jepler KiCad PCB Draft Inspection Report\n"
        report += "File: \(session.pcbBoard.filename)\n"
        report += "Date: \(Date().formatted())\n\n"
        report += "## Board Dimensions\n"
        report += "- Width: \(String(format: "%.2f", session.pcbBoard.widthMm)) mm\n"
        report += "- Height: \(String(format: "%.2f", session.pcbBoard.heightMm)) mm\n\n"
        report += "## Hardware Design Checks\n"
        for item in session.pcbBoard.diagnostics {
            report += "- [\(item.isOk ? "PASS" : "WARN")] \(item.title): \(item.detail)\n"
        }
        report += "\n## Components (\(session.pcbBoard.footprints.count))\n"
        for fp in session.pcbBoard.footprints {
            report += "- \(fp.reference) (\(fp.value)) at (\(String(format: "%.1f", fp.position.x)), \(String(format: "%.1f", fp.position.y)))\n"
        }
        
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "PCB_Inspection_Report_\(session.pcbBoard.filename.replacingOccurrences(of: ".kicad_pcb", with: "")).md"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? report.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

struct PinStatusBadge: View {
    let pin: String
    let name: String
    let isPressed: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isPressed ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 8, height: 8)
            Text("\(name): \(pin)")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(isPressed ? .green : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isPressed ? Color.green.opacity(0.15) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isPressed ? Color.green.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

