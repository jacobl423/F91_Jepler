import SwiftUI
import AppKit

final class PCBHUDState: ObservableObject {
    @Published var cursorBoardPos: Point2D = Point2D(x: 0, y: 0)
}

public struct PCBCanvasView: View {
    @ObservedObject var session: EmulatorSession
    
    // Geometry & HUD Cache
    @StateObject private var hudState = PCBHUDState()
    @State private var geometryCache = PCBGeometryCache()
    
    // Zoom and Pan
    @State private var canvasSize: CGSize = .zero
    @State private var zoomScale: CGFloat = 12.0
    @State private var panOffset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero
    
    // Layer Visibility
    @State private var showFCu: Bool = true
    @State private var showBCu: Bool = true
    @State private var showEdgeCuts: Bool = true
    @State private var showSilk: Bool = true
    @State private var showDrawings: Bool = true
    
    // Grid Options
    @State private var showGrid: Bool = true
    @State private var gridUnitMm: Bool = true // true = mm, false = mil
    
    // Interactive Measuring Ruler
    @State private var isRulerMode: Bool = false
    @State private var rulerStartBoard: Point2D? = nil
    @State private var rulerCurrentBoard: Point2D? = nil
    
    // Hovering & Interaction
    @State private var hoveredFootprintRef: String? = nil
    @State private var hoveredPadId: String? = nil
    
    // Callback for selecting a component
    public var onSelectFootprint: ((Footprint) -> Void)? = nil
    
    public init(session: EmulatorSession, onSelectFootprint: ((Footprint) -> Void)? = nil) {
        self.session = session
        self.onSelectFootprint = onSelectFootprint
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Canvas Toolbar
            canvasControlBar
            
            Divider()
            
            if session.show3DRenderMode {
                PCB3DRenderView(session: session)
            } else {
                // Interactive 2D Canvas Area
                GeometryReader { geo in
                let board = session.pcbBoard
                
                ZStack {
                    // Dark Green Solder Mask PCB Canvas
                    Color(red: 0.04, green: 0.11, blue: 0.07)
                        .ignoresSafeArea()
                    
                    Canvas { ctx, size in
                        let centerOffset = CGPoint(
                            x: size.width / 2.0 + panOffset.width,
                            y: size.height / 2.0 + panOffset.height
                        )
                        let boardCenterMm = Point2D(
                            x: (board.minX + board.maxX) / 2.0,
                            y: (board.minY + board.maxY) / 2.0
                        )
                        
                        func toCanvas(_ pt: Point2D) -> CGPoint {
                            CGPoint(
                                x: centerOffset.x + CGFloat(pt.x - boardCenterMm.x) * zoomScale,
                                y: centerOffset.y + CGFloat(pt.y - boardCenterMm.y) * zoomScale
                            )
                        }
                        
                        func toBoard(_ cgPt: CGPoint) -> Point2D {
                            Point2D(
                                x: boardCenterMm.x + Double(cgPt.x - centerOffset.x) / Double(zoomScale),
                                y: boardCenterMm.y + Double(cgPt.y - centerOffset.y) / Double(zoomScale)
                            )
                        }
                        
                        // Culling viewport: find visible board range
                        let visibleMin = toBoard(CGPoint(x: 0, y: 0))
                        let visibleMax = toBoard(CGPoint(x: size.width, y: size.height))
                        let viewMinX = min(visibleMin.x, visibleMax.x) - 2.0
                        let viewMaxX = max(visibleMin.x, visibleMax.x) + 2.0
                        let viewMinY = min(visibleMin.y, visibleMax.y) - 2.0
                        let viewMaxY = max(visibleMin.y, visibleMax.y) + 2.0
                        
                        // 1. Grid Overlay (mm or mil)
                        if showGrid && zoomScale > 3.0 {
                            drawGrid(ctx: ctx, size: size, centerOffset: centerOffset, boardCenterMm: boardCenterMm)
                        }
                        
                        let transform = CGAffineTransform(translationX: centerOffset.x, y: centerOffset.y)
                            .scaledBy(x: zoomScale, y: zoomScale)
                        
                        // 2. Copper Zones
                        if showBCu {
                            ctx.fill(geometryCache.bottomZonesPath.applying(transform), with: .color(Color(red: 0.15, green: 0.40, blue: 0.65).opacity(0.25)))
                        }
                        if showFCu {
                            ctx.fill(geometryCache.topZonesPath.applying(transform), with: .color(Color(red: 0.75, green: 0.45, blue: 0.15).opacity(0.25)))
                        }
                        
                        // 3. Copper Tracks
                        if showBCu {
                            ctx.stroke(geometryCache.bottomCopperTracksPath.applying(transform), with: .color(Color(red: 0.25, green: 0.55, blue: 0.85)), lineWidth: max(1.0, 0.25 * zoomScale))
                        }
                        if showFCu {
                            ctx.stroke(geometryCache.topCopperTracksPath.applying(transform), with: .color(Color(red: 0.85, green: 0.55, blue: 0.20)), lineWidth: max(1.0, 0.25 * zoomScale))
                        }
                        
                        // 4. Vias
                        ctx.fill(geometryCache.viasPath.applying(transform), with: .color(Color(red: 0.8, green: 0.7, blue: 0.3)))
                        ctx.fill(geometryCache.viasDrillPath.applying(transform), with: .color(Color(white: 0.08)))
                        
                        // 5. Board Outline (Edge.Cuts)
                        if showEdgeCuts {
                            ctx.stroke(geometryCache.edgeCutsPath.applying(transform), with: .color(Color(red: 0.95, green: 0.85, blue: 0.35)), lineWidth: max(1.5, 0.15 * zoomScale))
                        }
                        
                        // 6. User Drawings & Dimension Annotations
                        if showDrawings {
                            ctx.stroke(geometryCache.userDrawingsPath.applying(transform), with: .color(Color(white: 0.6)), lineWidth: max(1.0, 0.15 * zoomScale))
                        }
                        
                        // 7. Silkscreen Markings
                        if showSilk {
                            ctx.stroke(geometryCache.silkscreenPath.applying(transform), with: .color(Color.white.opacity(0.85)), lineWidth: max(1.0, 0.15 * zoomScale))
                        }
                        
                        // 8. Footprints & Pads (Culled for smooth 60 FPS)
                        for fp in board.footprints {
                            guard !session.hiddenComponentRefs.contains(fp.reference) else { continue }
                            if fp.position.x >= viewMinX && fp.position.x <= viewMaxX &&
                               fp.position.y >= viewMinY && fp.position.y <= viewMaxY {
                                drawFootprint(ctx: ctx, fp: fp, toCanvas: toCanvas)
                            }
                        }
                        
                        // 9. Measuring Ruler Line & Calipers
                        if let rStart = rulerStartBoard, let rCurrent = rulerCurrentBoard {
                            drawRuler(ctx: ctx, start: toCanvas(rStart), end: toCanvas(rCurrent), startBoard: rStart, endBoard: rCurrent)
                        }
                    }
                    
                    // Floating HUD: Coordinates, Selection & Net Info (Decoupled from Canvas)
                    PCBCoordinateHUD(hudState: hudState, session: session, zoomScale: zoomScale)
                }
                .contentShape(Rectangle())
                // Hover Tracking for Coordinates & Footprint detection
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        let centerOffset = CGPoint(
                            x: geo.size.width / 2.0 + panOffset.width,
                            y: geo.size.height / 2.0 + panOffset.height
                        )
                        let boardCenterMm = geometryCache.boardCenterMm
                        let boardPt = Point2D(
                            x: boardCenterMm.x + Double(location.x - centerOffset.x) / Double(zoomScale),
                            y: boardCenterMm.y + Double(location.y - centerOffset.y) / Double(zoomScale)
                        )
                        hudState.cursorBoardPos = boardPt
                        
                        let foundFp = geometryCache.findFootprint(at: boardPt)
                        if self.hoveredFootprintRef != foundFp {
                            self.hoveredFootprintRef = foundFp
                        }
                    case .ended:
                        if self.hoveredFootprintRef != nil {
                            self.hoveredFootprintRef = nil
                        }
                    }
                }
                // Drag Gesture (Pan or Ruler)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if isRulerMode {
                                let centerOffset = CGPoint(
                                    x: geo.size.width / 2.0 + panOffset.width,
                                    y: geo.size.height / 2.0 + panOffset.height
                                )
                                let boardCenterMm = Point2D(
                                    x: (board.minX + board.maxX) / 2.0,
                                    y: (board.minY + board.maxY) / 2.0
                                )
                                if rulerStartBoard == nil {
                                    rulerStartBoard = Point2D(
                                        x: boardCenterMm.x + Double(value.startLocation.x - centerOffset.x) / Double(zoomScale),
                                        y: boardCenterMm.y + Double(value.startLocation.y - centerOffset.y) / Double(zoomScale)
                                    )
                                }
                                rulerCurrentBoard = Point2D(
                                    x: boardCenterMm.x + Double(value.location.x - centerOffset.x) / Double(zoomScale),
                                    y: boardCenterMm.y + Double(value.location.y - centerOffset.y) / Double(zoomScale)
                                )
                            } else {
                                panOffset = CGSize(
                                    width: dragStartOffset.width + value.translation.width,
                                    height: dragStartOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            if !isRulerMode {
                                dragStartOffset = panOffset
                            }
                        }
                )
                // Tap Gestures (Single Click -> Select / Pad Net, Double Click -> Center)
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if let ref = hoveredFootprintRef, let fp = board.footprint(reference: ref) {
                                centerOnFootprint(fp: fp, in: geo.size)
                            } else {
                                fitToBoard(in: geo.size)
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 1)
                        .onEnded {
                            handleCanvasTap(at: hudState.cursorBoardPos)
                        }
                )
                // Context Menu on Right Click
                .contextMenu {
                    if let ref = hoveredFootprintRef, let fp = session.pcbBoard.footprint(reference: ref) {
                        Text(fp.reference + " — " + fp.value)
                            .font(.headline)
                        
                        Button("Inspect in Component Panel") {
                            session.selectedFootprintID = fp.reference
                            session.pcbInspectorTab = 2
                            onSelectFootprint?(fp)
                        }
                        
                        Button("Center View on \(fp.reference)") {
                            centerOnFootprint(fp: fp, in: geo.size)
                        }
                        
                        if !fp.datasheet.isEmpty, let url = URL(string: fp.datasheet) {
                            Button("View Datasheet") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        
                        Divider()
                        
                        Button("Copy Reference: \(fp.reference)") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(fp.reference, forType: .string)
                        }
                        
                        Button("Copy Value: \(fp.value)") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(fp.value, forType: .string)
                        }
                    } else {
                        Button("Fit to Board") {
                            fitToBoard(in: geo.size)
                        }
                        Button("Clear Ruler") {
                            rulerStartBoard = nil
                            rulerCurrentBoard = nil
                            isRulerMode = false
                        }
                    }
                }
                .onChange(of: geo.size) { canvasSize = $0 }
                .onAppear {
                    canvasSize = geo.size
                    fitToBoard(in: geo.size)
                    geometryCache.rebuild(board: session.pcbBoard)
                }
                .onChange(of: session.pcbBoard.footprints.count) { _ in
                    geometryCache.rebuild(board: session.pcbBoard)
                }
                .onChange(of: session.pcbBoard.tracks.count) { _ in
                    geometryCache.rebuild(board: session.pcbBoard)
                }
            }
            }
        }
    }
    
    // MARK: - Canvas Control Bar
    
    private var canvasControlBar: some View {
        ScrollView(.horizontal) {
        HStack(spacing: 8) {
            // 2D Vector / 3D Raytrace Render Toggle
            Picker("View Mode", selection: $session.show3DRenderMode) {
                Text("2D Vectors").tag(false)
                Text("3D Render").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 170)
            .onChange(of: session.show3DRenderMode) { is3D in
                if is3D && session.pcbRender3DImage == nil {
                    session.trigger3DRender()
                }
            }
            
            Divider().frame(height: 16)
            
            // Zoom Controls
            HStack(spacing: 4) {
                Button(action: { zoomScale = max(2.0, zoomScale * 0.8) }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .help("Zoom Out")
                
                Button(action: { zoomScale = min(40.0, zoomScale * 1.25) }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .help("Zoom In")
                
                Button(action: { fitToBoard(in: canvasSize) }) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .help("Fit to Board")
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            Divider().frame(height: 16)
            
            // Layer Selection Toggles
            HStack(spacing: 6) {
                LayerToggleBadge(title: "F.Cu", color: Color(red: 0.85, green: 0.55, blue: 0.20), isOn: $showFCu)
                LayerToggleBadge(title: "B.Cu", color: Color(red: 0.25, green: 0.55, blue: 0.85), isOn: $showBCu)
                LayerToggleBadge(title: "Edge", color: Color(red: 0.95, green: 0.85, blue: 0.35), isOn: $showEdgeCuts)
                LayerToggleBadge(title: "Silk", color: .white, isOn: $showSilk)
                LayerToggleBadge(title: "Draw", color: .gray, isOn: $showDrawings)
            }
            
            Divider().frame(height: 16)
            
            // Grid Toggle & Unit Selector
            HStack(spacing: 4) {
                Button(action: { showGrid.toggle() }) {
                    Image(systemName: showGrid ? "squareshape.split.2x2" : "square")
                        .foregroundColor(showGrid ? .accentColor : .secondary)
                }
                .buttonStyle(.borderless)
                .help("Toggle Alignment Grid")
                
                if showGrid {
                    Button(action: { gridUnitMm.toggle() }) {
                        Text(gridUnitMm ? "mm" : "mil")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .help("Toggle mm/mil Units")
                }
            }
            
            Divider().frame(height: 16)
            
            // Measurement Ruler Button
            Button(action: {
                isRulerMode.toggle()
                if !isRulerMode {
                    rulerStartBoard = nil
                    rulerCurrentBoard = nil
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "ruler")
                    Text("Ruler")
                        .font(.system(size: 10))
                }
            }
            .buttonStyle(.bordered)
            .tint(isRulerMode ? .accentColor : nil)
            .help("Click & drag between 2 points to measure distance")
            
            Spacer()
            
            // Active Buttons Status Tags
            HStack(spacing: 6) {
                ButtonTag(label: "A", pin: session.pcbBoard.buttonAPin, color: .cyan, isPressed: session.pressedKeys.contains("1"))
                ButtonTag(label: "B", pin: session.pcbBoard.buttonBPin, color: .yellow, isPressed: session.pressedKeys.contains("2"))
                ButtonTag(label: "C", pin: session.pcbBoard.buttonCPin, color: .purple, isPressed: session.pressedKeys.contains("3"))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(height: 40)
    }
    
    // MARK: - Drawing Helpers
    
    private func trackInBounds(_ track: PCBTrack, minX: Double, maxX: Double, minY: Double, maxY: Double) -> Bool {
        let tMinX = min(track.start.x, track.end.x)
        let tMaxX = max(track.start.x, track.end.x)
        let tMinY = min(track.start.y, track.end.y)
        let tMaxY = max(track.start.y, track.end.y)
        return !(tMaxX < minX || tMinX > maxX || tMaxY < minY || tMinY > maxY)
    }
    
    private func drawGrid(ctx: GraphicsContext, size: CGSize, centerOffset: CGPoint, boardCenterMm: Point2D) {
        let stepMm: Double = gridUnitMm ? (zoomScale > 15 ? 0.5 : 1.0) : (zoomScale > 15 ? 0.635 : 1.27) // 25 mil or 50 mil
        let stepPx = CGFloat(stepMm) * zoomScale
        
        var gridPath = Path()
        let startX = centerOffset.x.truncatingRemainder(dividingBy: stepPx)
        let startY = centerOffset.y.truncatingRemainder(dividingBy: stepPx)
        
        var x = startX
        while x < size.width {
            gridPath.move(to: CGPoint(x: x, y: 0))
            gridPath.addLine(to: CGPoint(x: x, y: size.height))
            x += stepPx
        }
        
        var y = startY
        while y < size.height {
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: size.width, y: y))
            y += stepPx
        }
        
        ctx.stroke(gridPath, with: .color(Color.white.opacity(0.04)), lineWidth: 1)
    }
    
    private func drawTrack(ctx: GraphicsContext, track: PCBTrack, toCanvas: (Point2D) -> CGPoint, color: Color) {
        let isNetHighlighted = session.selectedNetName != nil && track.netName.uppercased().contains(session.selectedNetName!.uppercased())
        let isHighCurrent = track.netName.uppercased().contains("VDD") || track.netName.uppercased().contains("GND") || track.netName.uppercased().contains("3V")
        
        var strokeWidth = CGFloat(track.width) * zoomScale
        strokeWidth = max(isHighCurrent ? 2.5 : 1.5, strokeWidth)
        
        let trackColor = isNetHighlighted ? Color.cyan : (isHighCurrent ? Color(red: 0.95, green: 0.65, blue: 0.25) : color)
        
        var p = Path()
        p.move(to: toCanvas(track.start))
        p.addLine(to: toCanvas(track.end))
        ctx.stroke(p, with: .color(trackColor), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
    }
    
    private func drawZone(ctx: GraphicsContext, zone: PCBZone, toCanvas: (Point2D) -> CGPoint, color: Color) {
        guard zone.polygon.count >= 3 else { return }
        var p = Path()
        p.move(to: toCanvas(zone.polygon[0]))
        for pt in zone.polygon.dropFirst() {
            p.addLine(to: toCanvas(pt))
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(color))
    }
    
    private func drawDrawing(ctx: GraphicsContext, drawing: PCBDrawing, toCanvas: (Point2D) -> CGPoint) {
        let color = drawing.layer.contains("Silk") ? Color.white.opacity(0.85) : Color(white: 0.55).opacity(0.6)
        let strokeW = max(1.0, CGFloat(drawing.strokeWidth) * zoomScale)
        
        switch drawing.shape {
        case .line(let start, let end):
            var p = Path()
            p.move(to: toCanvas(start))
            p.addLine(to: toCanvas(end))
            ctx.stroke(p, with: .color(color), lineWidth: strokeW)
        case .arc(let start, let mid, let end):
            var p = Path()
            p.move(to: toCanvas(start))
            p.addQuadCurve(to: toCanvas(end), control: toCanvas(mid))
            ctx.stroke(p, with: .color(color), lineWidth: strokeW)
        case .circle(let center, let radius):
            let c = toCanvas(center)
            let r = CGFloat(radius) * zoomScale
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(color), lineWidth: strokeW)
        case .rect(let start, let end):
            let s = toCanvas(start)
            let e = toCanvas(end)
            let rect = CGRect(x: min(s.x, e.x), y: min(s.y, e.y), width: abs(e.x - s.x), height: abs(e.y - s.y))
            ctx.stroke(Path(rect), with: .color(color), lineWidth: strokeW)
        case .text(let text, let position, let size):
            let pt = toCanvas(position)
            let fontSize = max(7, CGFloat(size) * zoomScale)
            ctx.draw(
                Text(text)
                    .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                    .foregroundColor(color),
                at: pt
            )
        }
    }
    
    private func drawFootprint(ctx: GraphicsContext, fp: Footprint, toCanvas: (Point2D) -> CGPoint) {
        let pos = toCanvas(fp.position)
        let isSelected = session.selectedFootprintID == fp.reference
        let isHovered = hoveredFootprintRef == fp.reference
        let isCritical = fp.isCritical
        
        // Component Outline Box
        let boxSize: CGFloat = max(10, 1.8 * zoomScale)
        let bodyRect = CGRect(x: pos.x - boxSize/2, y: pos.y - boxSize/2, width: boxSize, height: boxSize)
        
        // Special border for critical components (MCU, Crystals, Display)
        if isCritical {
            let haloRect = bodyRect.insetBy(dx: -4, dy: -4)
            ctx.stroke(Path(roundedRect: haloRect, cornerRadius: 4), with: .color(Color.cyan.opacity(0.4)), lineWidth: 1.5)
        }
        
        // Selected or Hovered halo
        if isSelected || isHovered {
            let selColor = isSelected ? Color.yellow : Color.white.opacity(0.8)
            ctx.stroke(Path(roundedRect: bodyRect.insetBy(dx: -2, dy: -2), cornerRadius: 3), with: .color(selColor), lineWidth: 2)
        }
        
        ctx.stroke(Path(bodyRect), with: .color(Color.white.opacity(0.45)), lineWidth: 1)
        
        // Reference Label
        let labelColor = isSelected ? Color.yellow : (isCritical ? Color.cyan : Color.white.opacity(0.85))
        ctx.draw(
            Text(fp.reference)
                .font(.system(size: max(7, min(11, 0.7 * zoomScale)), weight: .bold, design: .monospaced))
                .foregroundColor(labelColor),
            at: CGPoint(x: pos.x, y: pos.y - boxSize/2 - 6)
        )
        
        // Warning Badge Overlay if component has validation warnings
        if let check = session.pcbValidationResult?.checks.first(where: { $0.relatedComponentRef == fp.reference && $0.severity != .pass }) {
            let badgeIcon = check.severity == .error ? "❌" : "⚠️"
            ctx.draw(
                Text(badgeIcon).font(.system(size: 9)),
                at: CGPoint(x: pos.x + boxSize/2 + 4, y: pos.y - boxSize/2)
            )
        }
        
        // Draw Pads
        for pad in fp.pads {
            let padPos = toCanvas(pad.position)
            let padW = max(3.5, CGFloat(pad.size.x) * zoomScale)
            let padH = max(3.5, CGFloat(pad.size.y) * zoomScale)
            let padRect = CGRect(x: padPos.x - padW/2, y: padPos.y - padH/2, width: padW, height: padH)
            
            let isUnconnected = pad.netId == 0 || pad.netName.isEmpty || pad.netName.contains("unconnected")
            let isNetHighlighted = session.selectedNetName != nil && !session.selectedNetName!.isEmpty &&
                                  (pad.netName.caseInsensitiveCompare(session.selectedNetName!) == .orderedSame ||
                                   pad.netName.contains(session.selectedNetName!))
            
            // Distinct Button Pads
            let isButtonA = pad.netName.contains("P0.11") || pad.netName.contains("BUTTON_A") || fp.value.contains("A / key 1")
            let isButtonB = pad.netName.contains("P0.12") || pad.netName.contains("BUTTON_B") || fp.value.contains("B / key 2")
            let isButtonC = pad.netName.contains("P0.24") || pad.netName.contains("BUTTON_C") || fp.value.contains("C / key 3")
            
            let padColor: Color = {
                if isNetHighlighted { return Color.cyan }
                if isButtonA { return Color.cyan }
                if isButtonB { return Color.yellow }
                if isButtonC { return Color.purple }
                if isUnconnected { return Color(red: 0.9, green: 0.2, blue: 0.2) } // Unconnected in red
                return Color(red: 0.88, green: 0.72, blue: 0.32) // Shiny copper/gold pad
            }()
            
            ctx.fill(Path(roundedRect: padRect, cornerRadius: 1), with: .color(padColor))
            
            if isNetHighlighted || isButtonA || isButtonB || isButtonC {
                ctx.stroke(Path(roundedRect: padRect.insetBy(dx: -2, dy: -2), cornerRadius: 2), with: .color(padColor), lineWidth: 1.5)
            }
        }
    }
    
    private func drawRuler(ctx: GraphicsContext, start: CGPoint, end: CGPoint, startBoard: Point2D, endBoard: Point2D) {
        let distMm = startBoard.distance(to: endBoard)
        let distMil = distMm * 39.3701
        let dxMm = abs(endBoard.x - startBoard.x)
        let dyMm = abs(endBoard.y - startBoard.y)
        
        // Measurement Tape Line
        var p = Path()
        p.move(to: start)
        p.addLine(to: end)
        ctx.stroke(p, with: .color(Color.yellow), style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
        
        // Start and End Crosshairs / Calipers
        let sRect = CGRect(x: start.x - 3, y: start.y - 3, width: 6, height: 6)
        let eRect = CGRect(x: end.x - 3, y: end.y - 3, width: 6, height: 6)
        ctx.fill(Path(ellipseIn: sRect), with: .color(Color.yellow))
        ctx.fill(Path(ellipseIn: eRect), with: .color(Color.yellow))
        
        // Distance Measurement Tooltip
        let mid = CGPoint(x: (start.x + end.x) / 2.0, y: (start.y + end.y) / 2.0 - 12)
        let measureText = String(format: "%.2f mm (%.1f mil)\nΔX: %.2f  ΔY: %.2f", distMm, distMil, dxMm, dyMm)
        ctx.draw(
            Text(measureText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.black),
            at: mid
        )
    }
    
    // MARK: - Actions & Navigation
    
    private func handleCanvasTap(at boardPt: Point2D) {
        let board = session.pcbBoard
        
        // Check if user tapped a pad first (selects net!)
        for fp in board.footprints {
            for pad in fp.pads {
                if boardPt.distance(to: pad.position) < 0.8 {
                    if !pad.netName.isEmpty {
                        session.selectedNetName = pad.netName
                    }
                    session.selectedFootprintID = fp.reference
                    onSelectFootprint?(fp)
                    return
                }
            }
        }
        
        // If not a pad, check if user tapped a footprint body
        for fp in board.footprints {
            if boardPt.distance(to: fp.position) < 2.0 {
                session.selectedFootprintID = fp.reference
                onSelectFootprint?(fp)
                return
            }
        }
        
        // Clicked empty space -> clear selection
        session.selectedFootprintID = ""
        session.selectedNetName = nil
    }
    
    private func fitToBoard(in size: CGSize) {
        let board = session.pcbBoard
        let availW = max(20, size.width - 60)
        let availH = max(20, size.height - 60)
        let scaleX = availW / CGFloat(board.widthMm)
        let scaleY = availH / CGFloat(board.heightMm)
        self.zoomScale = max(3.0, min(scaleX, scaleY))
        self.panOffset = .zero
        self.dragStartOffset = .zero
    }
    
    private func centerOnFootprint(fp: Footprint, in size: CGSize) {
        let board = session.pcbBoard
        let boardCenterMm = Point2D(
            x: (board.minX + board.maxX) / 2.0,
            y: (board.minY + board.maxY) / 2.0
        )
        
        self.zoomScale = max(zoomScale, 20.0)
        self.panOffset = CGSize(
            width: -CGFloat(fp.position.x - boardCenterMm.x) * zoomScale,
            height: -CGFloat(fp.position.y - boardCenterMm.y) * zoomScale
        )
        self.dragStartOffset = self.panOffset
        self.session.selectedFootprintID = fp.reference
    }
}

// MARK: - Subcomponents

struct LayerToggleBadge: View {
    let title: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(isOn ? color : Color.gray.opacity(0.4))
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(.system(size: 10, weight: isOn ? .bold : .regular, design: .monospaced))
                    .foregroundColor(isOn ? .primary : .secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isOn ? color.opacity(0.15) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct ButtonTag: View {
    let label: String
    let pin: String
    let color: Color
    let isPressed: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isPressed ? Color.green : color)
                .frame(width: 6, height: 6)
            Text("\(label): \(pin)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(isPressed ? Color.green : .secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(isPressed ? Color.green.opacity(0.18) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isPressed ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

struct PCBCoordinateHUD: View {
    @ObservedObject var hudState: PCBHUDState
    @ObservedObject var session: EmulatorSession
    let zoomScale: CGFloat
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                // Coordinate Badge
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text(String(format: "X: %.2f mm  Y: %.2f mm", hudState.cursorBoardPos.x, hudState.cursorBoardPos.y))
                        .font(.system(size: 10, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(white: 0.12).opacity(0.85))
                .cornerRadius(6)
                
                // Selected Net Highlight Badge
                if let net = session.selectedNetName, !net.isEmpty {
                    HStack(spacing: 5) {
                        Circle().fill(Color.cyan).frame(width: 7, height: 7)
                        Text("Highlighted Net: \(net)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        Button(action: { session.selectedNetName = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.2))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                    .cornerRadius(6)
                }
                
                // Selected Component Badge
                if !session.selectedFootprintID.isEmpty, let fp = session.pcbBoard.footprint(reference: session.selectedFootprintID) {
                    HStack(spacing: 5) {
                        Circle().fill(Color.yellow).frame(width: 7, height: 7)
                        Text("\(fp.reference) (\(fp.value))")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.18))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.yellow.opacity(0.5), lineWidth: 1))
                    .cornerRadius(6)
                }
                
                Spacer()
                
                // Zoom Indicator
                Text("\(Int(zoomScale * 10))% zoom")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.12).opacity(0.85))
                    .cornerRadius(6)
            }
            .padding(10)
        }
    }
}

