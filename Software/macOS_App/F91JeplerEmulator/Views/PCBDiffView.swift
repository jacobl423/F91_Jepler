import SwiftUI
import AppKit

public struct PCBDiffView: View {
    @ObservedObject var session: EmulatorSession
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // Header Bar & File Selectors
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("KICAD PCB REVISION VISUAL DIFFING")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Text("Compare active PCB draft against baseline revision")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Choose Draft B PCB...") {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = []
                    if panel.runModal() == .OK, let url = panel.url {
                        session.loadComparisonPCB(fileURL: url)
                    }
                }
                .buttonStyle(.bordered)
                .font(.system(size: 11))
            }
            .padding(.horizontal)
            
            Divider()
            
            if let diff = session.pcbDiffResult {
                // Diff Summary Chips Bar
                HStack(spacing: 16) {
                    DiffStatBadge(title: "Base File", text: diff.baseFilename, color: .blue)
                    DiffStatBadge(title: "Draft File", text: diff.draftFilename, color: .purple)
                    DiffStatBadge(title: "Added", text: "+\(diff.addedCount)", color: .green)
                    DiffStatBadge(title: "Removed", text: "-\(diff.removedCount)", color: .red)
                    DiffStatBadge(title: "Modified", text: "~\(diff.modifiedCount)", color: .orange)
                    Spacer()
                }
                .padding(.horizontal)
                
                HSplitView {
                    // Left Panel: 2D Visual Diff Overlay Canvas
                    GeometryReader { geo in
                        let board = session.pcbBoard
                        let scaleX = (geo.size.width - 40) / CGFloat(board.widthMm)
                        let scaleY = (geo.size.height - 40) / CGFloat(board.heightMm)
                        let scale = min(scaleX, scaleY)
                        
                        ZStack {
                            Color(red: 0.05, green: 0.08, blue: 0.12)
                                .cornerRadius(12)
                            
                            Canvas { ctx, size in
                                let offsetX = (size.width - CGFloat(board.widthMm) * scale) / 2.0
                                let offsetY = (size.height - CGFloat(board.heightMm) * scale) / 2.0
                                
                                func toCanvas(_ pt: Point2D) -> CGPoint {
                                    CGPoint(
                                        x: offsetX + CGFloat(pt.x - board.minX) * scale,
                                        y: offsetY + CGFloat(pt.y - board.minY) * scale
                                    )
                                }
                                
                                // Draw Board Edge
                                var path = Path()
                                for seg in board.edgeSegments {
                                    if case .line(let start, let end) = seg {
                                        path.move(to: toCanvas(start))
                                        path.addLine(to: toCanvas(end))
                                    }
                                }
                                ctx.stroke(path, with: .color(Color.white.opacity(0.4)), lineWidth: 1.5)
                                
                                // Draw Component Diffs
                                for item in diff.componentDiffs {
                                    let fp = item.draftFootprint ?? item.baseFootprint!
                                    let pos = toCanvas(fp.position)
                                    let rect = CGRect(x: pos.x - 10, y: pos.y - 10, width: 20, height: 20)
                                    
                                    let color: Color
                                    switch item.diffType {
                                    case .added: color = .green
                                    case .removed: color = .red
                                    case .modified: color = .orange
                                    case .unchanged: color = .gray.opacity(0.4)
                                    }
                                    
                                    ctx.stroke(Path(rect), with: .color(color), lineWidth: item.diffType == .unchanged ? 1 : 2)
                                    ctx.draw(
                                        Text(fp.reference)
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(color),
                                        at: CGPoint(x: pos.x, y: pos.y - 14)
                                    )
                                }
                            }
                        }
                    }
                    .frame(minWidth: 300)
                    
                    // Right Panel: Component & Netlist Change Table
                    List {
                        Section(header: Text("HARDWARE REVISION CHANGE LOG (\(diff.componentDiffs.count))").font(.system(size: 10, weight: .bold, design: .monospaced))) {
                            ForEach(diff.componentDiffs) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(item.reference)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .frame(width: 50, alignment: .leading)
                                    
                                    DiffTypeTag(diffType: item.diffType)
                                    
                                    if case .modified(let details) = item.diffType {
                                        Text(details)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    } else if item.diffType == .added {
                                        Text("New component in draft (\(item.draftFootprint?.value ?? ""))")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    } else if item.diffType == .removed {
                                        Text("Removed from baseline")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .listStyle(.inset)
                    .frame(minWidth: 260)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No comparison draft loaded")
                        .font(.system(size: 14, weight: .bold))
                    Text("Select a secondary `.kicad_pcb` file to view visual PCB revision layout diffs.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Button("Select Comparison PCB Draft...") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            session.loadComparisonPCB(fileURL: url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct DiffStatBadge: View {
    let title: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title + ":")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .cornerRadius(4)
    }
}

struct DiffTypeTag: View {
    let diffType: PCBDiffType
    
    var body: some View {
        let (label, color): (String, Color) = {
            switch diffType {
            case .added: return ("ADDED", .green)
            case .removed: return ("REMOVED", .red)
            case .modified: return ("MODIFIED", .orange)
            case .unchanged: return ("SAME", .gray)
            }
        }()
        
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(3)
    }
}
