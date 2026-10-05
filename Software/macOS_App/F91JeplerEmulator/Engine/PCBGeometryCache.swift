import Foundation
import SwiftUI
import CoreGraphics

public final class PCBGeometryCache {
    public private(set) var boardCenterMm: Point2D = Point2D(x: 0, y: 0)
    
    public private(set) var topCopperTracksPath = Path()
    public private(set) var bottomCopperTracksPath = Path()
    public private(set) var edgeCutsPath = Path()
    public private(set) var viasPath = Path()
    public private(set) var viasDrillPath = Path()
    public private(set) var topZonesPath = Path()
    public private(set) var bottomZonesPath = Path()
    public private(set) var silkscreenPath = Path()
    public private(set) var userDrawingsPath = Path()
    
    // Spatial index for fast O(1) footprint hit-testing: (reference, center, radiusSquared)
    private var footprintHitIndex: [(reference: String, center: Point2D, radiusSq: Double)] = []
    
    public init() {}
    
    public func rebuild(board: KiCadBoard) {
        let centerMm = Point2D(
            x: (board.minX + board.maxX) / 2.0,
            y: (board.minY + board.maxY) / 2.0
        )
        self.boardCenterMm = centerMm
        
        func toBoardRelative(_ pt: Point2D) -> CGPoint {
            CGPoint(x: pt.x - centerMm.x, y: pt.y - centerMm.y)
        }
        
        // 1. Edge Cuts
        var edgePath = Path()
        for seg in board.edgeSegments {
            switch seg {
            case .line(let start, let end):
                edgePath.move(to: toBoardRelative(start))
                edgePath.addLine(to: toBoardRelative(end))
            case .arc(let start, let mid, let end):
                let s = toBoardRelative(start)
                let m = toBoardRelative(mid)
                let e = toBoardRelative(end)
                edgePath.move(to: s)
                edgePath.addQuadCurve(to: e, control: m)
            case .circle(let center, let radius):
                let c = toBoardRelative(center)
                edgePath.addEllipse(in: CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2))
            }
        }
        self.edgeCutsPath = edgePath
        
        // 2. Copper Tracks
        var fCuTracks = Path()
        var bCuTracks = Path()
        for track in board.tracks {
            let s = toBoardRelative(track.start)
            let e = toBoardRelative(track.end)
            if track.layer.contains("F.Cu") {
                fCuTracks.move(to: s)
                fCuTracks.addLine(to: e)
            } else if track.layer.contains("B.Cu") {
                bCuTracks.move(to: s)
                bCuTracks.addLine(to: e)
            }
        }
        self.topCopperTracksPath = fCuTracks
        self.bottomCopperTracksPath = bCuTracks
        
        // 3. Vias
        var viaP = Path()
        var drillP = Path()
        for via in board.vias {
            let c = toBoardRelative(via.position)
            let r = via.size / 2.0
            let dr = via.drill / 2.0
            viaP.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            drillP.addEllipse(in: CGRect(x: c.x - dr, y: c.y - dr, width: dr * 2, height: dr * 2))
        }
        self.viasPath = viaP
        self.viasDrillPath = drillP
        
        // 4. Copper Zones
        var topZ = Path()
        var botZ = Path()
        for zone in board.zones {
            guard zone.polygon.count >= 3 else { continue }
            var zPath = Path()
            zPath.move(to: toBoardRelative(zone.polygon[0]))
            for pt in zone.polygon.dropFirst() {
                zPath.addLine(to: toBoardRelative(pt))
            }
            zPath.closeSubpath()
            
            if zone.layer.contains("F.Cu") {
                topZ.addPath(zPath)
            } else if zone.layer.contains("B.Cu") {
                botZ.addPath(zPath)
            }
        }
        self.topZonesPath = topZ
        self.bottomZonesPath = botZ
        
        // 5. Silkscreen and Drawings
        var silk = Path()
        var drawings = Path()
        for dwg in board.drawings {
            guard dwg.layer != "Edge.Cuts" else { continue }
            let isSilk = dwg.layer.contains("Silk")
            
            var targetP = Path()
            switch dwg.shape {
            case .line(let s, let e):
                targetP.move(to: toBoardRelative(s))
                targetP.addLine(to: toBoardRelative(e))
            case .arc(let s, let m, let e):
                targetP.move(to: toBoardRelative(s))
                targetP.addQuadCurve(to: toBoardRelative(e), control: toBoardRelative(m))
            case .circle(let c, let r):
                let relC = toBoardRelative(c)
                targetP.addEllipse(in: CGRect(x: relC.x - r, y: relC.y - r, width: r * 2, height: r * 2))
            case .rect(let s, let e):
                let relS = toBoardRelative(s)
                let relE = toBoardRelative(e)
                let rect = CGRect(
                    x: min(relS.x, relE.x),
                    y: min(relS.y, relE.y),
                    width: abs(relE.x - relS.x),
                    height: abs(relE.y - relS.y)
                )
                targetP.addRect(rect)
            case .text:
                break
            }
            
            if isSilk {
                silk.addPath(targetP)
            } else {
                drawings.addPath(targetP)
            }
        }
        self.silkscreenPath = silk
        self.userDrawingsPath = drawings
        
        // 6. Build Footprint Spatial Index
        var index: [(String, Point2D, Double)] = []
        for fp in board.footprints {
            index.append((fp.reference, fp.position, 4.0)) // 2.0mm radius -> 4.0mm^2
        }
        self.footprintHitIndex = index
    }
    
    public func findFootprint(at boardPt: Point2D) -> String? {
        for entry in footprintHitIndex {
            let dx = boardPt.x - entry.center.x
            let dy = boardPt.y - entry.center.y
            if (dx * dx + dy * dy) < entry.radiusSq {
                return entry.reference
            }
        }
        return nil
    }
}
