import Foundation

// MARK: - SessionAssetKind

/// Represents the functional category of an asset managed in the Jepler Dev emulator session.
public enum SessionAssetKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case pcb = "pcb"
    case appFirmware = "appFirmware"
    case bootloader = "bootloader"
    case rescScript = "rescScript"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .pcb: return "KiCad PCB Layout"
        case .appFirmware: return "Application Firmware"
        case .bootloader: return "MCUboot Bootloader"
        case .rescScript: return "Renode Emulation Script"
        }
    }

    public var subtitle: String {
        switch self {
        case .pcb: return ".kicad_pcb layout geometry"
        case .appFirmware: return ".bin, .hex, or .elf application"
        case .bootloader: return ".elf, .hex, or .bin chainloader"
        case .rescScript: return ".resc machine orchestration"
        }
    }

    public var iconName: String {
        switch self {
        case .pcb: return "cpu"
        case .appFirmware: return "doc.bin.fill"
        case .bootloader: return "lock.shield.fill"
        case .rescScript: return "doc.text.fill"
        }
    }

    public var allowedExtensions: [String] {
        switch self {
        case .pcb: return ["kicad_pcb"]
        case .appFirmware: return ["bin", "hex", "elf"]
        case .bootloader: return ["elf", "hex", "bin"]
        case .rescScript: return ["resc"]
        }
    }

    public var defaultResourceName: (name: String, ext: String) {
        switch self {
        case .pcb: return ("f91_jepler", "kicad_pcb")
        case .appFirmware: return ("app.signed", "bin")
        case .bootloader: return ("mcuboot", "elf")
        case .rescScript: return ("f91_jepler", "resc")
        }
    }

    public var userDefaultsKey: String {
        return "f91_asset_path_\(rawValue)"
    }
}

// MARK: - DetectedAssetFormat

/// Detected binary or structured text format identified by magic bytes or S-expressions.
public enum DetectedAssetFormat: String, Codable, Sendable {
    case mcubootBinary = "MCUboot Signed Binary"
    case elfArmCortexM = "ELF32 ARM Cortex-M"
    case intelHex = "Intel HEX"
    case kicadSExpr = "KiCad PCB S-Expression"
    case renodeResc = "Renode Script"
    case rawBinary = "Raw Binary"
    case unknown = "Unknown Format"
}

// MARK: - AssetMetadata

/// Immutable metadata extracted from an asset file.
public struct AssetMetadata: Identifiable, Equatable, Hashable, Codable, Sendable {
    public var id: String { filePath }

    public let fileName: String
    public let filePath: String
    public let fileSizeBytes: Int64
    public let fileSizeFormatted: String
    public let modificationDate: Date?
    public let modificationDateFormatted: String
    public let formatBadge: String
    public let secondaryDetail: String
    public let isCustom: Bool
    public let sha256Prefix: String?
    public let detectedFormat: DetectedAssetFormat

    public init(
        fileName: String,
        filePath: String,
        fileSizeBytes: Int64,
        fileSizeFormatted: String,
        modificationDate: Date?,
        modificationDateFormatted: String,
        formatBadge: String,
        secondaryDetail: String,
        isCustom: Bool,
        sha256Prefix: String? = nil,
        detectedFormat: DetectedAssetFormat = .unknown
    ) {
        self.fileName = fileName
        self.filePath = filePath
        self.fileSizeBytes = fileSizeBytes
        self.fileSizeFormatted = fileSizeFormatted
        self.modificationDate = modificationDate
        self.modificationDateFormatted = modificationDateFormatted
        self.formatBadge = formatBadge
        self.secondaryDetail = secondaryDetail
        self.isCustom = isCustom
        self.sha256Prefix = sha256Prefix
        self.detectedFormat = detectedFormat
    }
}

// MARK: - AssetLoadState

/// State machine for asset loading and background inspection.
public enum AssetLoadState: Equatable, Hashable, Sendable {
    case notLoaded
    case inspecting
    case loaded(AssetMetadata)
    case failed(error: String)

    public var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    public var isInspecting: Bool {
        if case .inspecting = self { return true }
        return false
    }

    public var metadata: AssetMetadata? {
        if case .loaded(let meta) = self { return meta }
        return nil
    }

    public var errorMessage: String? {
        if case .failed(let err) = self { return err }
        return nil
    }
}

// MARK: - SessionAsset

/// Represents a loaded or configured asset in the emulator session.
public struct SessionAsset: Identifiable, Equatable, Hashable, Sendable {
    public var id: SessionAssetKind { kind }
    public let kind: SessionAssetKind
    public var url: URL?
    public var state: AssetLoadState
    public var isCustom: Bool

    public init(
        kind: SessionAssetKind,
        url: URL? = nil,
        state: AssetLoadState = .notLoaded,
        isCustom: Bool = false
    ) {
        self.kind = kind
        self.url = url
        self.state = state
        self.isCustom = isCustom
    }

    // MARK: - Convenience Accessors

    public var metadata: AssetMetadata? {
        state.metadata
    }

    public var fileName: String {
        metadata?.fileName ?? url?.lastPathComponent ?? "None"
    }

    public var formatBadge: String {
        metadata?.formatBadge ?? (url != nil ? url!.pathExtension.uppercased() : "Empty")
    }

    public var secondaryDetail: String {
        metadata?.secondaryDetail ?? (isCustom ? "Custom asset" : "Default embedded")
    }

    public var fileSizeFormatted: String {
        metadata?.fileSizeFormatted ?? "0 B"
    }

    public var modificationDateFormatted: String {
        metadata?.modificationDateFormatted ?? "Unknown"
    }

    public var isReady: Bool {
        state.isLoaded && url != nil
    }
}
