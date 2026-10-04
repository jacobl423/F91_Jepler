import SwiftUI
import AppKit

public struct PCBComparisonView: View {
    @ObservedObject var session: EmulatorSession
    
    // Synchronized Zoom & Pan across both canvases
    @State private var syncZoom: CGFloat = 12.0
    @State private var syncPan: CGSize = .zero
    @State private var syncDragStart: CGSize = .zero
    
    // Highlighted Diff Reference
    @State private var focusedRef: String? = nil
    
    // View Options: Split side-by-side vs Overlaid
    @State private var displayMode: ComparisonDisplayMode = .sideBySide
    
    public init(session: EmulatorSession) {
        self.session = session
    }
    
    public enum ComparisonDisplayMode: String, CaseIterable, Identifiable {
        case sideBySide = "Side-by-Side Split"
        case overlay = "Unified Diff Overlay"
        
        public var id: String { rawValue }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar & File Controls
            headerBar
            
            Divider()
            
            if let diff = session.pcbDiffResult, let draft = session.comparisonBoard {
                VStack(spacing: 0) {
                    // Diff Statistics & Legend Bar
                    legendAndMetricsBar(diff: diff)
                    
                    Divider()
                    
                    // Main Comparison Area: Canvases on Top/Left, Change Log on Right
                    HSplitView {
                        // Canvases Area
                        VStack(spacing: 0) {
                            if displayMode == .sideBySide {
                                sideBySideCanvases(base: session.pcbBoard, draft: draft, diff: diff)
                            } else {
                                unifiedOverlayCanvas(base: session.pcbBoard, draft: draft, diff: diff)
                            }
                        }
                        .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Right Panel: Change Log Table
                        changeLogPanel(diff: diff)
                            .frame(minWidth: 260, idealWidth: 320, maxWidth: 450)
                    }
                }
            } else {
                emptyComparisonPlaceholder
            }
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("PCB REVISION COMPARISON")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                Text("Side-by-side synchronized visual diff of active board draft against baseline")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Picker("Display Mode", selection: $displayMode) {
                ForEach(ComparisonDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            
            Button("Load Draft B...") {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Legend & Metrics Bar
    
    private func legendAndMetricsBar(diff: PCBBoardDiffResult) -> some View {
        HStack(spacing: 12) {
            // Stats
            DiffChip(title: "Added", count: "+\(diff.addedCount)", color: .green)
            DiffChip(title: "Removed", count: "-\(diff.removedCount)", color: .red)
            DiffChip(title: "Modified", count: "~\(diff.modifiedCount)", color: .orange)
            
            Divider().frame(height: 14)
            
            // Legend
            HStack(spacing: 8) {
                legendItem(color: .green, label: "Added in Draft")
                legendItem(color: .red, label: "Removed from Base")
                legendItem(color: .orange, label: "Moved / Modified")
                legendItem(color: .gray.opacity(0.5), label: "Unchanged")
            }
            
            Spacer()
            
            // Synchronized Zoom Controls
            HStack(spacing: 4) {
                Button(action: { syncZoom = max(2.0, syncZoom * 0.8) }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                
                Button(action: { syncZoom = min(35.0, syncZoom * 1.25) }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                
                Button(action: {
                    syncZoom = 12.0
                    syncPan = .zero
                    syncDragStart = .zero
                }) {
                    Text("Sync Reset")
                        .font(.system(size: 10))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Side-by-Side Dual Synchronized Canvases
    
    private func sideBySideCanvases(base: KiCadBoard, draft: KiCadBoard, diff: PCBBoardDiffResult) -> some View {
        HSplitView {
            // Left Canvas: Baseline PCB
            VStack(spacing: 0) {
                HStack {
                    Text("BASELINE: \(base.filename)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    Spacer()
                    Text("\(base.footprints.count) components")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(6)
                .background(Color(white: 0.12))
                
                singleBoardCanvas(board: base, isDraft: false, diff: diff)
            }
            .frame(minWidth: 200)
            
            // Right Canvas: Draft PCB
            VStack(spacing: 0) {
                HStack {
                    Text("DRAFT: \(draft.filename)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.purple)
                    Spacer()
                    Text("\(draft.footprints.count) components")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(6)
                .background(Color(white: 0.12))
                
                singleBoardCanvas(board: draft, isDraft: true, diff: diff)
            }
            .frame(minWidth: 200)
        }
    }
    
    private func singleBoardCanvas(board: KiCadBoard, isDraft: Bool, diff: PCBBoardDiffResult) -> some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.04, green: 0.09, blue: 0.06)
                
                Canvas { ctx, size in
                    let centerOffset = CGPoint(
                        x: size.width / 2.0 + syncPan.width,
                        y: size.height / 2.0 + syncPan.height
                    )
                    let boardCenterMm = Point2D(
                        x: (board.minX + board.maxX) / 2.0,
                        y: (board.minY + board.maxY) / 2.0
                    )
                    
                    func toCanvas(_ pt: Point2D) -> CGPoint {
                        CGPoint(
                            x: centerOffset.x + CGFloat(pt.x - boardCenterMm.x) * syncZoom,
                            y: centerOffset.y + CGFloat(pt.y - boardCenterMm.y) * syncZoom
                        )
                    }
                    
                    // Board Outline
                    var outline = Path()
                    for seg in board.edgeSegments {
                        if case .line(let start, let end) = seg {
                            outline.move(to: toCanvas(start))
                            outline.addLine(to: toCanvas(end))
                        }
                    }
                    ctx.stroke(outline, with: .color(Color(red: 0.9, green: 0.8, blue: 0.3)), lineWidth: 1.5)
                    
                    // Footprints & Diff Highlighting
                    for fp in board.footprints {
                        let pos = toCanvas(fp.position)
                        let isFocused = focusedRef == fp.reference
                        
                        let itemDiff = diff.componentDiffs.first { $0.reference == fp.reference }
                        let diffType = itemDiff?.diffType ?? .unchanged
                        
                        let diffColor: Color = {
                            switch diffType {
                            case .added: return .green
                            case .removed: return .red
                            case .modified: return .orange
                            case .unchanged: return Color.gray.opacity(0.4)
                            }
                        }()
                        
                        let boxSize: CGFloat = max(10, 1.8 * syncZoom)
                        let rect = CGRect(x: pos.x - boxSize/2, y: pos.y - boxSize/2, width: boxSize, height: boxSize)
                        
                        // Focus Halo
                        if isFocused {
                            ctx.stroke(Path(roundedRect: rect.insetBy(dx: -3, dy: -3), cornerRadius: 4), with: .color(Color.yellow), lineWidth: 2.5)
                        }
                        
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(diffColor.opacity(0.3)))
                        ctx.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(diffColor), lineWidth: isFocused ? 2 : 1)
                        
                        // Reference Label
                        ctx.draw(
                            Text(fp.reference)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(isFocused ? .yellow : diffColor),
                            at: CGPoint(x: pos.x, y: pos.y - boxSize/2 - 6)
                        )
                    }
                }
            }
            // Shared synchronized pan gesture
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { val in
                        syncPan = CGSize(
                            width: syncDragStart.width + val.translation.width,
                            height: syncDragStart.height + val.translation.height
                        )
                    }
                    .onEnded { _ in
                        syncDragStart = syncPan
                    }
            )
        }
    }
    
    // MARK: - Unified Overlaid Canvas Mode
    
    private func unifiedOverlayCanvas(base: KiCadBoard, draft: KiCadBoard, diff: PCBBoardDiffResult) -> some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.03, green: 0.07, blue: 0.05)
                
                Canvas { ctx, size in
                    let centerOffset = CGPoint(
                        x: size.width / 2.0 + syncPan.width,
                        y: size.height / 2.0 + syncPan.height
                    )
                    let boardCenterMm = Point2D(
                        x: (base.minX + base.maxX) / 2.0,
                        y: (base.minY + base.maxY) / 2.0
                    )
                    
                    func toCanvas(_ pt: Point2D) -> CGPoint {
                        CGPoint(
                            x: centerOffset.x + CGFloat(pt.x - boardCenterMm.x) * syncZoom,
                            y: centerOffset.y + CGFloat(pt.y - boardCenterMm.y) * syncZoom
                        )
                    }
                    
                    // Draw Draft Edge Outline
                    var outline = Path()
                    for seg in draft.edgeSegments {
                        if case .line(let start, let end) = seg {
                            outline.move(to: toCanvas(start))
                            outline.addLine(to: toCanvas(end))
                        }
                    }
                    ctx.stroke(outline, with: .color(Color(red: 0.9, green: 0.8, blue: 0.3)), lineWidth: 1.5)
                    
                    // Draw Diff Items
                    for item in diff.componentDiffs {
                        let fp = item.draftFootprint ?? item.baseFootprint!
                        let pos = toCanvas(fp.position)
                        let isFocused = focusedRef == item.reference
                        
                        let color: Color = {
                            switch item.diffType {
                            case .added: return .green
                            case .removed: return .red
                            case .modified: return .orange
                            case .unchanged: return Color.gray.opacity(0.3)
                            }
                        }()
                        
                        let boxSize: CGFloat = max(10, 1.8 * syncZoom)
                        let rect = CGRect(x: pos.x - boxSize/2, y: pos.y - boxSize/2, width: boxSize, height: boxSize)
                        
                        if isFocused {
                            ctx.stroke(Path(roundedRect: rect.insetBy(dx: -4, dy: -4), cornerRadius: 4), with: .color(.yellow), lineWidth: 2.5)
                        }
                        
                        ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color.opacity(0.35)))
                        ctx.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(color), lineWidth: item.diffType == .unchanged ? 1 : 2)
                        
                        ctx.draw(
                            Text(fp.reference)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(color),
                            at: CGPoint(x: pos.x, y: pos.y - boxSize/2 - 6)
                        )
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { val in
                        syncPan = CGSize(
                            width: syncDragStart.width + val.translation.width,
                            height: syncDragStart.height + val.translation.height
                        )
                    }
                    .onEnded { _ in
                        syncDragStart = syncPan
                    }
            )
        }
    }
    
    // MARK: - Change Log Table
    
    private func changeLogPanel(diff: PCBBoardDiffResult) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("REVISION CHANGES (\(diff.componentDiffs.count))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Spacer()
                if let ref = focusedRef {
                    Button("Clear Focus") { focusedRef = nil }
                        .font(.system(size: 9))
                        .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            List(selection: $focusedRef) {
                ForEach(diff.componentDiffs) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.reference)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(focusedRef == item.reference ? .yellow : .primary)
                            .frame(width: 48, alignment: .leading)
                        
                        DiffBadge(diffType: item.diffType)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            if case .modified(let details) = item.diffType {
                                Text(details)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else if item.diffType == .added {
                                Text("New in draft (\(item.draftFootprint?.value ?? ""))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else if item.diffType == .removed {
                                Text("Deleted from baseline (\(item.baseFootprint?.value ?? ""))")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            } else {
                                Text(item.draftFootprint?.value ?? "")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
                    .tag(item.reference)
                    .onTapGesture {
                        focusedRef = item.reference
                    }
                }
            }
            .listStyle(.inset)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyComparisonPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.split.2x1")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No comparison PCB loaded")
                .font(.system(size: 14, weight: .bold))
            Text("Select a secondary KiCad PCB file (.kicad_pcb) to compare against active board.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Button("Choose Comparison PCB Draft...") {
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

// MARK: - Helpers

struct DiffChip: View {
    let title: String
    let count: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title + ":")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
            Text(count)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .cornerRadius(4)
    }
}

struct DiffBadge: View {
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
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .cornerRadius(3)
    }
}
