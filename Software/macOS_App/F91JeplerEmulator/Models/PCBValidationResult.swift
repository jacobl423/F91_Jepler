import Foundation

public enum CheckSeverity: String, Codable, CaseIterable {
    case pass
    case warning
    case error
}

public struct ValidationCheck: Identifiable, Equatable, Codable {
    public let id: UUID
    public let category: String          // "Component", "Connectivity", "Design", "Values"
    public let title: String             // "MCU found"
    public let detail: String            // "nRF52840 at U1"
    public let severity: CheckSeverity   // .pass, .warning, .error
    public let relatedComponentRef: String? // "U1" for canvas highlighting
    public let suggestion: String?       // "Add 100nF bypass cap on pin X"
    public let autoFixable: Bool
    public let fixActionDescription: String?
    
    public init(
        id: UUID = UUID(),
        category: String,
        title: String,
        detail: String,
        severity: CheckSeverity,
        relatedComponentRef: String? = nil,
        suggestion: String? = nil,
        autoFixable: Bool = false,
        fixActionDescription: String? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.detail = detail
        self.severity = severity
        self.relatedComponentRef = relatedComponentRef
        self.suggestion = suggestion
        self.autoFixable = autoFixable
        self.fixActionDescription = fixActionDescription
    }
}

public struct BOMEntry: Identifiable, Equatable, Codable {
    public var id: String { "\(reference)_\(value)" }
    public let reference: String
    public let value: String
    public let package: String
    public let quantity: Int
    public let description: String
    public let datasheet: String
    public let mpn: String
    public let dnp: Bool
    
    public init(
        reference: String,
        value: String,
        package: String,
        quantity: Int = 1,
        description: String = "",
        datasheet: String = "",
        mpn: String = "",
        dnp: Bool = false
    ) {
        self.reference = reference
        self.value = value
        self.package = package
        self.quantity = quantity
        self.description = description
        self.datasheet = datasheet
        self.mpn = mpn
        self.dnp = dnp
    }
}

public struct GroupedBOMEntry: Identifiable, Equatable {
    public var id: String { "\(value)_\(package)" }
    public let value: String
    public let package: String
    public let references: [String]
    public var quantity: Int { references.count }
    public let description: String
    public let datasheet: String
    public let mpn: String
    public let dnp: Bool
    
    public var referencesString: String {
        references.sorted().joined(separator: ", ")
    }
}

public enum NetClass: String, Codable, CaseIterable {
    case power = "Power"
    case ground = "Ground"
    case highSpeed = "High-Speed"
    case signal = "Signal"
}

public struct NetDetail: Identifiable, Equatable {
    public var id: Int { netId }
    public let netId: Int
    public let name: String
    public let netClass: NetClass
    public let connectedPads: [(componentRef: String, padNumber: String)]
    
    public static func == (lhs: NetDetail, rhs: NetDetail) -> Bool {
        lhs.netId == rhs.netId && lhs.name == rhs.name && lhs.netClass == rhs.netClass &&
        lhs.connectedPads.count == rhs.connectedPads.count
    }
}

public struct PCBValidationResult: Equatable {
    public let sourceSHA256: String?
    public let confidence: ValidationConfidence
    public let checks: [ValidationCheck]
    public let componentBOM: [BOMEntry]
    public let overallScore: Double  // 0.0 - 1.0 (e.g. 0.95 -> 95%)
    public let isReadyForFabrication: Bool
    public let generatedAt: Date
    
    public init(
        checks: [ValidationCheck],
        componentBOM: [BOMEntry],
        overallScore: Double,
        isReadyForFabrication: Bool,
        sourceSHA256: String? = nil,
        confidence: ValidationConfidence = .advisory,
        generatedAt: Date = Date()
    ) {
        self.sourceSHA256 = sourceSHA256
        self.confidence = confidence
        self.checks = checks
        self.componentBOM = componentBOM
        self.overallScore = min(1.0, max(0.0, overallScore))
        self.isReadyForFabrication = isReadyForFabrication
        self.generatedAt = generatedAt
    }
    
    public var passCount: Int {
        checks.filter { $0.severity == .pass }.count
    }
    
    public var warningCount: Int {
        checks.filter { $0.severity == .warning }.count
    }
    
    public var errorCount: Int {
        checks.filter { $0.severity == .error }.count
    }
    
    public var autoFixableChecks: [ValidationCheck] {
        checks.filter { $0.autoFixable }
    }
    
    public var scorePercentage: Int {
        Int(overallScore * 100.0)
    }
    
    public var groupedBOM: [GroupedBOMEntry] {
        var dict: [String: (entry: BOMEntry, refs: [String])] = [:]
        for item in componentBOM {
            let key = "\(item.value.trimmingCharacters(in: .whitespaces))_\(item.package)"
            if var existing = dict[key] {
                existing.refs.append(item.reference)
                dict[key] = existing
            } else {
                dict[key] = (item, [item.reference])
            }
        }
        
        return dict.values.map { item in
            GroupedBOMEntry(
                value: item.entry.value,
                package: item.entry.package,
                references: item.refs,
                description: item.entry.description,
                datasheet: item.entry.datasheet,
                mpn: item.entry.mpn,
                dnp: item.entry.dnp
            )
        }.sorted { $0.value < $1.value }
    }
}
