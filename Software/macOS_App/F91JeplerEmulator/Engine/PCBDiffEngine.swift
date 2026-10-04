import Foundation

public enum PCBDiffType: Equatable {
    case added
    case removed
    case modified(details: String)
    case unchanged
}

public struct PCBComponentDiff: Identifiable, Equatable {
    public var id: String { reference }
    public let reference: String
    public let diffType: PCBDiffType
    public let baseFootprint: Footprint?
    public let draftFootprint: Footprint?
}

public struct PCBBoardDiffResult: Equatable {
    public let baseFilename: String
    public let draftFilename: String
    public let componentDiffs: [PCBComponentDiff]
    public let widthDiffMm: Double
    public let heightDiffMm: Double
    
    public var addedCount: Int {
        componentDiffs.filter { $0.diffType == .added }.count
    }
    
    public var removedCount: Int {
        componentDiffs.filter { $0.diffType == .removed }.count
    }
    
    public var modifiedCount: Int {
        componentDiffs.filter { if case .modified = $0.diffType { return true }; return false }.count
    }
}

public struct PCBDiffEngine {
    public static func compare(base: KiCadBoard, draft: KiCadBoard) -> PCBBoardDiffResult {
        var diffs: [PCBComponentDiff] = []
        
        let baseDict = Dictionary(uniqueKeysWithValues: base.footprints.map { ($0.reference, $0) })
        let draftDict = Dictionary(uniqueKeysWithValues: draft.footprints.map { ($0.reference, $0) })
        
        let allRefs = Array(Set(baseDict.keys).union(draftDict.keys)).sorted()
        
        for ref in allRefs {
            let bFp = baseDict[ref]
            let dFp = draftDict[ref]
            
            if let b = bFp, let d = dFp {
                var changes: [String] = []
                if b.value != d.value { changes.append("Value: \(b.value) → \(d.value)") }
                if abs(b.position.x - d.position.x) > 0.01 || abs(b.position.y - d.position.y) > 0.01 {
                    changes.append(String(format: "Pos: (%.1f, %.1f) → (%.1f, %.1f)", b.position.x, b.position.y, d.position.x, d.position.y))
                }
                if b.pads.count != d.pads.count { changes.append("Pads: \(b.pads.count) → \(d.pads.count)") }
                
                if changes.isEmpty {
                    diffs.append(PCBComponentDiff(reference: ref, diffType: .unchanged, baseFootprint: b, draftFootprint: d))
                } else {
                    diffs.append(PCBComponentDiff(reference: ref, diffType: .modified(details: changes.joined(separator: ", ")), baseFootprint: b, draftFootprint: d))
                }
            } else if let d = dFp {
                diffs.append(PCBComponentDiff(reference: ref, diffType: .added, baseFootprint: nil, draftFootprint: d))
            } else if let b = bFp {
                diffs.append(PCBComponentDiff(reference: ref, diffType: .removed, baseFootprint: b, draftFootprint: nil))
            }
        }
        
        return PCBBoardDiffResult(
            baseFilename: base.filename,
            draftFilename: draft.filename,
            componentDiffs: diffs,
            widthDiffMm: draft.widthMm - base.widthMm,
            heightDiffMm: draft.heightMm - base.heightMm
        )
    }
}
