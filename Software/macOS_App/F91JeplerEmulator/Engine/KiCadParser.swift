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
        
        // Step 1: Extract Nets
        for item in items {
            if case .list(let exprs) = item, exprs.count >= 3, exprs[0].stringValue == "net" {
                if let idStr = exprs[1].stringValue, let id = Int(idStr), let name = exprs[2].stringValue {
                    board.nets[id] = name
                    
                    // Check net names for pin auto-detection
                    let upper = name.uppercased()
                    if upper.contains("P0.11") || upper.contains("BUTTON_A") || upper.contains("KEY1") {
                        board.buttonAPin = "P0.11"
                    }
                    if upper.contains("P0.12") || upper.contains("BUTTON_B") || upper.contains("KEY2") {
                        board.buttonBPin = "P0.12"
                    }
                    if upper.contains("P0.24") || upper.contains("BUTTON_C") || upper.contains("KEY3") {
                        board.buttonCPin = "P0.24"
                    }
                }
            }
        }
        
        // Step 2: Extract Edge.Cuts & Footprints
        for item in items {
            guard case .list(let exprs) = item, !exprs.isEmpty else { continue }
            let keyword = exprs[0].stringValue ?? ""
            
            if keyword == "gr_line" {
                var layer = ""
                var start: Point2D?
                var end: Point2D?
                
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
                }
                
                if layer == "Edge.Cuts", let s = start, let e = end {
                    board.edgeSegments.append(.line(start: s, end: e))
                    minX = min(minX, min(s.x, e.x))
                    maxX = max(maxX, max(s.x, e.x))
                    minY = min(minY, min(s.y, e.y))
                    maxY = max(maxY, max(s.y, e.y))
                }
            } else if keyword == "footprint" && exprs.count >= 2 {
                let fpName = exprs[1].stringValue ?? ""
                var ref = ""
                var val = ""
                var posX = 0.0
                var posY = 0.0
                var rot = 0.0
                var pads: [Pad] = []
                
                for node in exprs.dropFirst(2) {
                    guard case .list(let sub) = node, !sub.isEmpty else { continue }
                    let key = sub[0].stringValue ?? ""
                    
                    if key == "at" && sub.count >= 3 {
                        posX = Double(sub[1].stringValue ?? "") ?? 0.0
                        posY = Double(sub[2].stringValue ?? "") ?? 0.0
                        if sub.count >= 4 { rot = Double(sub[3].stringValue ?? "") ?? 0.0 }
                    } else if key == "property" && sub.count >= 3 {
                        let propName = sub[1].stringValue ?? ""
                        if propName == "Reference" { ref = sub[2].stringValue ?? "" }
                        if propName == "Value" { val = sub[2].stringValue ?? "" }
                    } else if key == "pad" && sub.count >= 3 {
                        let padNum = sub[1].stringValue ?? ""
                        var netId = 0
                        var padX = posX
                        var padY = posY
                        var padW = 1.0
                        var padH = 1.0
                        
                        for pSub in sub.dropFirst(3) {
                            guard case .list(let pList) = pSub, !pList.isEmpty else { continue }
                            let pKey = pList[0].stringValue ?? ""
                            if pKey == "net" && pList.count >= 2 {
                                netId = Int(pList[1].stringValue ?? "") ?? 0
                            } else if pKey == "at" && pList.count >= 3 {
                                let relX = Double(pList[1].stringValue ?? "") ?? 0.0
                                let relY = Double(pList[2].stringValue ?? "") ?? 0.0
                                padX = posX + relX
                                padY = posY + relY
                            } else if pKey == "size" && pList.count >= 3 {
                                padW = Double(pList[1].stringValue ?? "") ?? 1.0
                                padH = Double(pList[2].stringValue ?? "") ?? 1.0
                            }
                        }
                        
                        let netName = board.nets[netId] ?? ""
                        pads.append(Pad(number: padNum, netId: netId, netName: netName, position: Point2D(x: padX, y: padY), size: Point2D(x: padW, y: padH)))
                    }
                }
                
                let fp = Footprint(reference: ref.isEmpty ? fpName : ref, value: val, layer: "F.Cu", position: Point2D(x: posX, y: posY), rotation: rot, pads: pads)
                board.footprints.append(fp)
                
                minX = min(minX, posX)
                maxX = max(maxX, posX)
                minY = min(minY, posY)
                maxY = max(maxY, posY)
            }
        }
        
        if minX.isFinite && maxX.isFinite && minY.isFinite && maxY.isFinite {
            board.minX = minX - 1.0
            board.maxX = maxX + 1.0
            board.minY = minY - 1.0
            board.maxY = maxY + 1.0
        }
        
        return board
    }
}
