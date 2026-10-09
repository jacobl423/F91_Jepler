import SwiftUI
import AppKit

public struct PCBComponentInspectorPanel: View {
    @ObservedObject var session: EmulatorSession
    @State private var searchText: String = ""
    @State private var selectedGroup: ComponentCategory = .all
    @State private var copiedFeedback: String? = nil
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public enum ComponentCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case ics = "ICs"
        case crystals = "Crystals"
        case capacitors = "Capacitors"
        case inductors = "Inductors"
        case testPoints = "Test Points"
        case resistors = "Resistors"
        case other = "Other"
        
        public var id: String { rawValue }
    }
    
    public var body: some View {
        AdaptiveSplitView {
            // Left List: Component Browser by Type & Search
            VStack(spacing: 0) {
                // Search Field & Category Filter
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Filter components by ref, value, net...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    
                    // Category Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(ComponentCategory.allCases) { cat in
                                Button(action: { selectedGroup = cat }) {
                                    Text(cat.rawValue)
                                        .font(.system(size: 10, weight: selectedGroup == cat ? .bold : .regular))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(selectedGroup == cat ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(8)
                
                Divider()
                
                // Components List
                List(selection: $session.selectedFootprintID) {
                    ForEach(filteredComponents) { fp in
                        HStack {
                            // Visibility toggle eye icon
                            Button(action: { toggleVisibility(ref: fp.reference) }) {
                                Image(systemName: session.hiddenComponentRefs.contains(fp.reference) ? "eye.slash" : "eye")
                                    .font(.system(size: 10))
                                    .foregroundColor(session.hiddenComponentRefs.contains(fp.reference) ? .secondary : .primary)
                            }
                            .buttonStyle(.plain)
                            .help(session.hiddenComponentRefs.contains(fp.reference) ? "Show on canvas" : "Hide on canvas")
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(fp.reference)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(session.selectedFootprintID == fp.reference ? .accentColor : .primary)
                                    if fp.isCritical {
                                        Circle().fill(Color.cyan).frame(width: 5, height: 5)
                                    }
                                }
                                Text(fp.value)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(fp.pads.count)p")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color(white: 0.15).opacity(0.4))
                                .cornerRadius(3)
                        }
                        .contentShape(Rectangle())
                        .tag(fp.reference)
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: .infinity, minHeight: 80)
            
            // Right Details Inspector: Selected Component Deep-Dive
            if let selectedFp = session.pcbBoard.footprint(reference: session.selectedFootprintID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Header Card
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(selectedFp.reference)
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    if selectedFp.isCritical {
                                        Text("CRITICAL")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.cyan.opacity(0.2))
                                            .foregroundColor(.cyan)
                                            .cornerRadius(4)
                                    }
                                    if selectedFp.dnp {
                                        Text("DNP")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.2))
                                            .foregroundColor(.red)
                                            .cornerRadius(4)
                                    }
                                }
                                Text(selectedFp.value)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Quick Action Buttons
                            HStack(spacing: 8) {
                                Button(action: { copyToClipboard(text: selectedFp.reference, label: "Reference") }) {
                                    Label("Copy Ref", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button(action: { copyToClipboard(text: selectedFp.value, label: "Value") }) {
                                    Label("Copy Val", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        // Copied Alert Banner
                        if let feedback = copiedFeedback {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(feedback)
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(4)
                        }
                        
                        Divider()
                        
                        // Physical Placement Properties Grid
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PLACEMENT & GEOMETRY")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                                GridRow {
                                    Text("Package:").font(.system(size: 11)).foregroundColor(.secondary)
                                    Text(selectedFp.package.components(separatedBy: ":").last ?? selectedFp.package)
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                GridRow {
                                    Text("Position:").font(.system(size: 11)).foregroundColor(.secondary)
                                    Text(String(format: "X: %.2f mm, Y: %.2f mm", selectedFp.position.x, selectedFp.position.y))
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                GridRow {
                                    Text("Rotation:").font(.system(size: 11)).foregroundColor(.secondary)
                                    Text(String(format: "%.1f°", selectedFp.rotation))
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                GridRow {
                                    Text("Layer:").font(.system(size: 11)).foregroundColor(.secondary)
                                    Text(selectedFp.layer)
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                if !selectedFp.manufacturerPartNumber.isEmpty {
                                    GridRow {
                                        Text("MPN:").font(.system(size: 11)).foregroundColor(.secondary)
                                        Text(selectedFp.manufacturerPartNumber)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    }
                                }
                                if !selectedFp.datasheet.isEmpty, let url = URL(string: selectedFp.datasheet) {
                                    GridRow {
                                        Text("Datasheet:").font(.system(size: 11)).foregroundColor(.secondary)
                                        Button("Open Datasheet URL") {
                                            NSWorkspace.shared.open(url)
                                        }
                                        .buttonStyle(.link)
                                        .font(.system(size: 11))
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Pads & Netlist Assignment Table
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PIN NETLIST & CONNECTIVITY (\(selectedFp.pads.count) PADS)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Highlight Traces") {
                                    if let firstPadNet = selectedFp.pads.first?.netName, !firstPadNet.isEmpty {
                                        session.selectedNetName = firstPadNet
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            
                            VStack(spacing: 4) {
                                ForEach(selectedFp.pads) { pad in
                                    HStack(spacing: 8) {
                                        Text(pad.number)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .frame(width: 32, alignment: .leading)
                                        
                                        let isUnconnected = pad.netId == 0 || pad.netName.isEmpty || pad.netName.contains("unconnected")
                                        
                                        Text(isUnconnected ? "NC (Unconnected)" : pad.netName)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(isUnconnected ? .red : (session.selectedNetName == pad.netName ? .cyan : .primary))
                                        
                                        Spacer()
                                        
                                        if !isUnconnected {
                                            Button(action: { session.selectedNetName = pad.netName }) {
                                                Image(systemName: "point.3.connected.trianglepath.dotted")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(session.selectedNetName == pad.netName ? .cyan : .secondary)
                                            }
                                            .buttonStyle(.plain)
                                            .help("Highlight net '\(pad.netName)' across PCB")
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Other Components Connected via Same Nets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CONNECTED NEIGHBORS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            let connectedNeighbors = findConnectedNeighbors(for: selectedFp)
                            if connectedNeighbors.isEmpty {
                                Text("No other components sharing nets found.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(connectedNeighbors, id: \.reference) { neighbor in
                                    HStack {
                                        Text(neighbor.reference)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.accentColor)
                                            .frame(width: 60, alignment: .leading)
                                        Text(neighbor.value)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(neighbor.sharedNet)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                                    .cornerRadius(4)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        session.selectedFootprintID = neighbor.reference
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("Select a component to inspect")
                        .font(.system(size: 13, weight: .medium))
                    Text("Click any component footprint on the 2D canvas or select from the list.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Filtering & Helpers
    
    private var filteredComponents: [Footprint] {
        let board = session.pcbBoard
        return board.footprints.filter { fp in
            // Category filter
            if selectedGroup != .all {
                let ref = fp.reference.uppercased()
                let val = fp.value.uppercased()
                switch selectedGroup {
                case .all: break
                case .ics:
                    if !ref.hasPrefix("U") && !val.contains("NRF52840") { return false }
                case .crystals:
                    if !ref.hasPrefix("X") && !ref.hasPrefix("Y") { return false }
                case .capacitors:
                    if !ref.hasPrefix("C") { return false }
                case .inductors:
                    if !ref.hasPrefix("L") { return false }
                case .testPoints:
                    if !ref.hasPrefix("TP") { return false }
                case .resistors:
                    if !ref.hasPrefix("R") { return false }
                case .other:
                    if ref.hasPrefix("U") || ref.hasPrefix("X") || ref.hasPrefix("Y") ||
                       ref.hasPrefix("C") || ref.hasPrefix("L") || ref.hasPrefix("TP") || ref.hasPrefix("R") {
                        return false
                    }
                }
            }
            
            // Search text
            if !searchText.isEmpty {
                let term = searchText.lowercased()
                let matchRef = fp.reference.lowercased().contains(term)
                let matchVal = fp.value.lowercased().contains(term)
                let matchNet = fp.pads.contains { $0.netName.lowercased().contains(term) }
                return matchRef || matchVal || matchNet
            }
            
            return true
        }
    }
    
    private func toggleVisibility(ref: String) {
        if session.hiddenComponentRefs.contains(ref) {
            session.hiddenComponentRefs.remove(ref)
        } else {
            session.hiddenComponentRefs.insert(ref)
        }
    }
    
    private func copyToClipboard(text: String, label: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        self.copiedFeedback = "\(label) copied to clipboard"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.copiedFeedback = nil
        }
    }
    
    private struct ConnectedNeighbor {
        let reference: String
        let value: String
        let sharedNet: String
    }
    
    private func findConnectedNeighbors(for target: Footprint) -> [ConnectedNeighbor] {
        let targetNets = Set(target.pads.map { $0.netName.trimmingCharacters(in: CharacterSet(charactersIn: "/ ")) })
            .filter { !$0.isEmpty && !$0.contains("unconnected") && $0 != "GND" }
        
        var neighbors: [ConnectedNeighbor] = []
        for other in session.pcbBoard.footprints where other.reference != target.reference {
            for pad in other.pads {
                let clean = pad.netName.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
                if targetNets.contains(clean) {
                    neighbors.append(ConnectedNeighbor(reference: other.reference, value: other.value, sharedNet: clean))
                    break
                }
            }
        }
        return neighbors
    }
}
