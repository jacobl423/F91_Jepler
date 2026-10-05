import Foundation

public enum SExpr: Equatable {
    case atom(String)
    case list([SExpr])
    
    public var stringValue: String? {
        if case .atom(let str) = self {
            return str.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        }
        return nil
    }
    
    public var listValue: [SExpr]? {
        if case .list(let items) = self { return items }
        return nil
    }
}

public final class KiCadParser {
    public static func parse(fileURL: URL) throws -> KiCadBoard {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        var board = parse(content: content)
        board.filename = fileURL.lastPathComponent
        return board
    }
    
    public static func parse(content: String) -> KiCadBoard {
        let tokens = tokenize(content)
        var index = 0
        guard let root = parseExpr(tokens: tokens, index: &index) else {
            return KiCadBoard()
        }
        return extractBoard(from: root)
    }
    
    private static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuote = false
        
        for char in text {
            if char == "\"" {
                inQuote.toggle()
                current.append(char)
            } else if inQuote {
                current.append(char)
            } else if char == "(" || char == ")" {
                if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    tokens.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                    current = ""
                }
                tokens.append(String(char))
            } else if char.isWhitespace {
                if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    tokens.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tokens.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return tokens
    }
    
    private static func parseExpr(tokens: [String], index: inout Int) -> SExpr? {
        guard index < tokens.count else { return nil }
        let token = tokens[index]
        
        if token == "(" {
            index += 1
            var elements: [SExpr] = []
            while index < tokens.count && tokens[index] != ")" {
                if let child = parseExpr(tokens: tokens, index: &index) {
                    elements.append(child)
                } else {
                    break
                }
            }
            if index < tokens.count && tokens[index] == ")" {
                index += 1
            }
            return .list(elements)
        } else if token == ")" {
            index += 1
            return nil
        } else {
            index += 1
            return .atom(token)
        }
    }
    
    private static func extractBoard(from root: SExpr) -> KiCadBoard {
        var board = KiCadBoard()
        guard case .list(let items) = root else { return board }
        
        var minX = Double.infinity
        var maxX = -Double.infinity
        var minY = Double.infinity
        var maxY = -Double.infinity
        var nextNetId = 1
        var netNameToId: [String: Int] = [:]
        
        // Helper to get or register net ID for a net name
        func registerNet(name: String, preferredId: Int? = nil) -> (id: Int, name: String) {
            let cleanName = name.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if cleanName.isEmpty { return (0, "") }
            
            if let existingId = netNameToId[cleanName] {
                return (existingId, cleanName)
            }
            
            let id = preferredId ?? nextNetId
            if id >= nextNetId { nextNetId = id + 1 }
            
            netNameToId[cleanName] = id
            board.nets[id] = cleanName
            
            // Check net names for pin auto-detection
            let upper = cleanName.uppercased()
            if upper.contains("P0.11") || upper.contains("BUTTON_A") || upper.contains("KEY1") {
                board.buttonAPin = "P0.11"
            }
            if upper.contains("P0.12") || upper.contains("BUTTON_B") || upper.contains("KEY2") {
                board.buttonBPin = "P0.12"
            }
            if upper.contains("P0.24") || upper.contains("BUTTON_C") || upper.contains("KEY3") {
                board.buttonCPin = "P0.24"
            }
            
            return (id, cleanName)
        }
        
        // Step 1: Pre-populate explicit board nets (net <id> <name>)
        for item in items {
            if case .list(let exprs) = item, exprs.count >= 2, exprs[0].stringValue == "net" {
                if exprs.count >= 3, let idStr = exprs[1].stringValue, let id = Int(idStr), let name = exprs[2].stringValue {
                    _ = registerNet(name: name, preferredId: id)
                } else if let name = exprs[1].stringValue {
                    _ = registerNet(name: name)
                }
            }
        }
        
        // Step 2: Iterate over all board items
        for item in items {
            guard case .list(let exprs) = item, !exprs.isEmpty else { continue }
            let keyword = exprs[0].stringValue ?? ""
            
            switch keyword {
            case "segment":
                var start = Point2D(x: 0, y: 0)
                var end = Point2D(x: 0, y: 0)
                var width = 0.25
                var layer = "F.Cu"
                var netId = 0
                var netName = ""
                
                for node in exprs.dropFirst() {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    if key == "start" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            start = Point2D(x: x, y: y)
                        }
                    } else if key == "end" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            end = Point2D(x: x, y: y)
                        }
                    } else if key == "width" && sub.count >= 2 {
                        width = Double(sub[1].stringValue ?? "") ?? 0.25
                    } else if key == "layer" && sub.count >= 2 {
                        layer = sub[1].stringValue ?? "F.Cu"
                    } else if key == "net" && sub.count >= 2 {
                        if let id = Int(sub[1].stringValue ?? "") {
                            netId = id
                            netName = board.nets[id] ?? ""
                        } else if let name = sub[1].stringValue {
                            let reg = registerNet(name: name)
                            netId = reg.id
                            netName = reg.name
                        }
                    }
                }
                
                board.tracks.append(PCBTrack(start: start, end: end, width: width, layer: layer, netId: netId, netName: netName))
                
            case "via":
                var pos = Point2D(x: 0, y: 0)
                var size = 0.6
                var drill = 0.3
                var layers: [String] = ["F.Cu", "B.Cu"]
                var netId = 0
                var netName = ""
                
                for node in exprs.dropFirst() {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    if key == "at" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            pos = Point2D(x: x, y: y)
                        }
                    } else if key == "size" && sub.count >= 2 {
                        size = Double(sub[1].stringValue ?? "") ?? 0.6
                    } else if key == "drill" && sub.count >= 2 {
                        drill = Double(sub[1].stringValue ?? "") ?? 0.3
                    } else if key == "layers" {
                        layers = sub.dropFirst().compactMap { $0.stringValue }
                    } else if key == "net" && sub.count >= 2 {
                        if let id = Int(sub[1].stringValue ?? "") {
                            netId = id
                            netName = board.nets[id] ?? ""
                        } else if let name = sub[1].stringValue {
                            let reg = registerNet(name: name)
                            netId = reg.id
                            netName = reg.name
                        }
                    }
                }
                
                board.vias.append(PCBVia(position: pos, size: size, drill: drill, layers: layers, netId: netId, netName: netName))
                
            case "zone":
                var layer = "F.Cu"
                var netId = 0
                var netName = ""
                var polygon: [Point2D] = []
                
                for node in exprs.dropFirst() {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    if key == "layer" && sub.count >= 2 {
                        layer = sub[1].stringValue ?? "F.Cu"
                    } else if key == "net" && sub.count >= 2 {
                        if let id = Int(sub[1].stringValue ?? "") {
                            netId = id
                        } else if let name = sub[1].stringValue {
                            let reg = registerNet(name: name)
                            netId = reg.id
                            netName = reg.name
                        }
                    } else if key == "net_name" && sub.count >= 2 {
                        netName = sub[1].stringValue ?? ""
                        let reg = registerNet(name: netName, preferredId: netId > 0 ? netId : nil)
                        netId = reg.id
                    } else if key == "polygon" {
                        for polyNode in sub.dropFirst() {
                            guard case .list(let ptsList) = polyNode, !ptsList.isEmpty, ptsList[0].stringValue == "pts" else { continue }
                            for ptNode in ptsList.dropFirst() {
                                guard case .list(let xy) = ptNode, xy.count >= 3, xy[0].stringValue == "xy" else { continue }
                                if let x = Double(xy[1].stringValue ?? ""), let y = Double(xy[2].stringValue ?? "") {
                                    polygon.append(Point2D(x: x, y: y))
                                }
                            }
                        }
                    }
                }
                
                if !polygon.isEmpty {
                    board.zones.append(PCBZone(layer: layer, netId: netId, netName: netName, polygon: polygon))
                }
                
            case "gr_line":
                var layer = ""
                var start: Point2D?
                var end: Point2D?
                var strokeWidth = 0.15
                
                for node in exprs.dropFirst() {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    if key == "layer" && sub.count >= 2 { layer = sub[1].stringValue ?? "" }
                    if key == "start" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            start = Point2D(x: x, y: y)
                        }
                    }
                    if key == "end" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            end = Point2D(x: x, y: y)
                        }
                    }
                    if key == "stroke" {
                        for sSub in sub.dropFirst() {
                            if case .list(let sList) = sSub, sList.count >= 2, sList[0].stringValue == "width" {
                                strokeWidth = Double(sList[1].stringValue ?? "") ?? 0.15
                            }
                        }
                    } else if key == "width" && sub.count >= 2 {
                        strokeWidth = Double(sub[1].stringValue ?? "") ?? 0.15
                    }
                }
                
                if let s = start, let e = end {
                    board.drawings.append(PCBDrawing(shape: .line(start: s, end: e), layer: layer, strokeWidth: strokeWidth))
                    if layer == "Edge.Cuts" {
                        board.edgeSegments.append(.line(start: s, end: e))
                        minX = min(minX, min(s.x, e.x))
                        maxX = max(maxX, max(s.x, e.x))
                        minY = min(minY, min(s.y, e.y))
                        maxY = max(maxY, max(s.y, e.y))
                    }
                }
                
            case "gr_arc":
                var layer = ""
                var start: Point2D?
                var mid: Point2D?
                var end: Point2D?
                var strokeWidth = 0.15
                
                for node in exprs.dropFirst() {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    if key == "layer" && sub.count >= 2 { layer = sub[1].stringValue ?? "" }
                    if key == "start" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            start = Point2D(x: x, y: y)
                        }
                    }
                    if key == "mid" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            mid = Point2D(x: x, y: y)
                        }
                    }
                    if key == "end" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            end = Point2D(x: x, y: y)
                        }
                    }
                    if key == "stroke" {
                        for sSub in sub.dropFirst() {
                            if case .list(let sList) = sSub, sList.count >= 2, sList[0].stringValue == "width" {
                                strokeWidth = Double(sList[1].stringValue ?? "") ?? 0.15
                            }
                        }
                    }
                }
                
                if let s = start, let m = mid, let e = end {
                    board.drawings.append(PCBDrawing(shape: .arc(start: s, mid: m, end: e), layer: layer, strokeWidth: strokeWidth))
                    if layer == "Edge.Cuts" {
                        board.edgeSegments.append(.arc(start: s, mid: m, end: e))
                    }
                }
                
            case "gr_circle":
                var layer = ""
                var center: Point2D?
                var radius = 1.0
                var strokeWidth = 0.15
                
                for node in exprs.dropFirst() {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    if key == "layer" && sub.count >= 2 { layer = sub[1].stringValue ?? "" }
                    if key == "center" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            center = Point2D(x: x, y: y)
                        }
                    }
                    if key == "end" && sub.count >= 3, let c = center {
                        if let ex = Double(sub[1].stringValue ?? ""), let ey = Double(sub[2].stringValue ?? "") {
                            let endPt = Point2D(x: ex, y: ey)
                            radius = c.distance(to: endPt)
                        }
                    }
                    if key == "stroke" {
                        for sSub in sub.dropFirst() {
                            if case .list(let sList) = sSub, sList.count >= 2, sList[0].stringValue == "width" {
                                strokeWidth = Double(sList[1].stringValue ?? "") ?? 0.15
                            }
                        }
                    }
                }
                
                if let c = center {
                    board.drawings.append(PCBDrawing(shape: .circle(center: c, radius: radius), layer: layer, strokeWidth: strokeWidth))
                    if layer == "Edge.Cuts" {
                        board.edgeSegments.append(.circle(center: c, radius: radius))
                    }
                }
                
            case "gr_text":
                let textStr = exprs.count >= 2 ? (exprs[1].stringValue ?? "") : ""
                var pos = Point2D(x: 0, y: 0)
                var layer = "F.SilkS"
                var size = 1.0
                
                for node in exprs.dropFirst(2) {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    if key == "at" && sub.count >= 3 {
                        if let x = Double(sub[1].stringValue ?? ""), let y = Double(sub[2].stringValue ?? "") {
                            pos = Point2D(x: x, y: y)
                        }
                    } else if key == "layer" && sub.count >= 2 {
                        layer = sub[1].stringValue ?? "F.SilkS"
                    } else if key == "effects" {
                        for eSub in sub.dropFirst() {
                            if case .list(let eList) = eSub, eList.count >= 2, eList[0].stringValue == "font" {
                                for fSub in eList.dropFirst() {
                                    if case .list(let fList) = fSub, fList.count >= 2, fList[0].stringValue == "size" {
                                        size = Double(fList[1].stringValue ?? "") ?? 1.0
                                    }
                                }
                            }
                        }
                    }
                }
                
                board.drawings.append(PCBDrawing(shape: .text(text: textStr, position: pos, size: size), layer: layer))
                
            case "footprint":
                let fpPackageName = exprs.count >= 2 ? (exprs[1].stringValue ?? "") : ""
                var ref = ""
                var val = ""
                var posX = 0.0
                var posY = 0.0
                var rot = 0.0
                var layer = "F.Cu"
                var descr = ""
                var dnp = false
                var properties: [String: String] = [:]
                var pads: [Pad] = []
                
                for node in exprs.dropFirst(2) {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    
                    if key == "layer" && sub.count >= 2 {
                        layer = sub[1].stringValue ?? "F.Cu"
                    } else if key == "descr" && sub.count >= 2 {
                        descr = sub[1].stringValue ?? ""
                    } else if key == "attr" {
                        for a in sub.dropFirst() {
                            if a.stringValue?.lowercased() == "dnp" { dnp = true }
                        }
                    } else if key == "at" && sub.count >= 3 {
                        posX = Double(sub[1].stringValue ?? "") ?? 0.0
                        posY = Double(sub[2].stringValue ?? "") ?? 0.0
                        if sub.count >= 4 { rot = Double(sub[3].stringValue ?? "") ?? 0.0 }
                    } else if key == "property" && sub.count >= 3 {
                        let propName = sub[1].stringValue ?? ""
                        let propVal = sub[2].stringValue ?? ""
                        properties[propName] = propVal
                        if propName == "Reference" { ref = propVal }
                        if propName == "Value" { val = propVal }
                        if propName.lowercased() == "dnp" && (propVal.lowercased() == "yes" || propVal.lowercased() == "true") {
                            dnp = true
                        }
                    } else if key == "pad" && sub.count >= 3 {
                        let padNum = sub[1].stringValue ?? ""
                        let padShape = sub.count >= 4 ? (sub[3].stringValue ?? "rect") : "rect"
                        var padNetId = 0
                        var padNetName = ""
                        var padX = posX
                        var padY = posY
                        var padW = 1.0
                        var padH = 1.0
                        var padLayers: [String] = ["F.Cu"]
                        var pinFn: String? = nil
                        
                        for pSub in sub.dropFirst(3) {
                            guard case .list(let pList) = pSub, !pList.isEmpty else { continue }
                            let pKey = pList[0].stringValue ?? ""
                            
                            if pKey == "net" && pList.count >= 2 {
                                if pList.count >= 3, let nId = Int(pList[1].stringValue ?? ""), let nName = pList[2].stringValue {
                                    let reg = registerNet(name: nName, preferredId: nId)
                                    padNetId = reg.id
                                    padNetName = reg.name
                                } else if let nId = Int(pList[1].stringValue ?? "") {
                                    padNetId = nId
                                    padNetName = board.nets[nId] ?? ""
                                } else if let nName = pList[1].stringValue {
                                    let reg = registerNet(name: nName)
                                    padNetId = reg.id
                                    padNetName = reg.name
                                }
                            } else if pKey == "at" && pList.count >= 3 {
                                let relX = Double(pList[1].stringValue ?? "") ?? 0.0
                                let relY = Double(pList[2].stringValue ?? "") ?? 0.0
                                
                                // Apply component rotation (in degrees) to relative pad offset
                                let rad = rot * Double.pi / 180.0
                                let cosR = cos(rad)
                                let sinR = sin(rad)
                                let rotatedRelX = relX * cosR - relY * sinR
                                let rotatedRelY = relX * sinR + relY * cosR
                                
                                padX = posX + rotatedRelX
                                padY = posY + rotatedRelY
                            } else if pKey == "size" && pList.count >= 3 {
                                padW = Double(pList[1].stringValue ?? "") ?? 1.0
                                padH = Double(pList[2].stringValue ?? "") ?? 1.0
                            } else if pKey == "layers" {
                                padLayers = pList.dropFirst().compactMap { $0.stringValue }
                            } else if pKey == "pinfunction" && pList.count >= 2 {
                                pinFn = pList[1].stringValue
                            }
                        }
                        
                        pads.append(Pad(
                            number: padNum,
                            netId: padNetId,
                            netName: padNetName,
                            position: Point2D(x: padX, y: padY),
                            size: Point2D(x: padW, y: padH),
                            shape: padShape,
                            layers: padLayers,
                            pinFunction: pinFn
                        ))
                    }
                }
                
                let fpRef = ref.isEmpty ? fpPackageName : ref
                let fp = Footprint(
                    reference: fpRef,
                    value: val,
                    layer: layer,
                    position: Point2D(x: posX, y: posY),
                    rotation: rot,
                    pads: pads,
                    package: fpPackageName,
                    properties: properties,
                    dnp: dnp,
                    descr: descr
                )
                board.footprints.append(fp)
                
                minX = min(minX, posX)
                maxX = max(maxX, posX)
                minY = min(minY, posY)
                maxY = max(maxY, posY)
                
            default:
                break
            }
        }
        
        // Ensure valid board bounding box
        if board.edgeSegments.isEmpty {
            if minX.isFinite && maxX.isFinite && minY.isFinite && maxY.isFinite {
                board.minX = minX - 2.0
                board.maxX = maxX + 2.0
                board.minY = minY - 2.0
                board.maxY = maxY + 2.0
            } else {
                board.minX = 85.0
                board.maxX = 115.0
                board.minY = 85.0
                board.maxY = 115.0
            }
        } else {
            // Already computed during edgeSegments extraction
            board.minX = minX
            board.maxX = maxX
            board.minY = minY
            board.maxY = maxY
        }
        
        return board
    }
}
