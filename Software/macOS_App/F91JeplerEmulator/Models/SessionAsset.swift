import Foundation

// MARK: - SessionPersistenceKeys

public enum SessionPersistenceKeys {
    public static let customPcbPath = "jepler.custom.pcb.path"
    public static let customAppBinPath = "jepler.custom.appBin.path"
    public static let customBootloaderPath = "jepler.custom.bootloader.path"
    public static let customRescPath = "jepler.custom.resc.path"
    public static let isSidebarVisible = "jepler.sidebar.isVisible"
    public static let sidebarVisible = "jepler.sidebar.visible"
    public static let sidebarVisibleAlternate = "jepler.sidebar.visible"
    public static let legacyIsSidebarVisible = "jepler.sidebar.isVisible"
    public static let sidebarWidth = "jepler.sidebar.width"
    public static let selectedViewMode = "jepler.viewMode"
}

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
        switch self {
        case .pcb: return SessionPersistenceKeys.customPcbPath
        case .appFirmware: return SessionPersistenceKeys.customAppBinPath
        case .bootloader: return SessionPersistenceKeys.customBootloaderPath
        case .rescScript: return SessionPersistenceKeys.customRescPath
        }
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
    case customLoaded
    case defaultEmbedded
    case missing(String)

    public var isLoaded: Bool {
        switch self {
        case .loaded, .customLoaded, .defaultEmbedded:
            return true
        default:
            return false
        }
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
        switch self {
        case .failed(let err): return err
        case .missing(let err): return err
        default: return nil
        }
    }
}

// MARK: - SessionAsset

/// Represents a loaded or configured asset in the emulator session.
public struct SessionAsset: Identifiable, Equatable, Hashable, Sendable {
    public var id: SessionAssetKind { kind }
    public let kind: SessionAssetKind
    public var url: URL?
    public var fileURL: URL? {
        get { url }
        set { url = newValue }
    }
    public var state: AssetLoadState
    public var metadata: AssetMetadata? {
        didSet {
            if let meta = metadata {
                state = .loaded(meta)
            }
        }
    }
    public var isCustom: Bool

    public init(
        kind: SessionAssetKind,
        url: URL? = nil,
        fileURL: URL? = nil,
        state: AssetLoadState = .notLoaded,
        metadata: AssetMetadata? = nil,
        isCustom: Bool = false
    ) {
        self.kind = kind
        self.url = url ?? fileURL
        self.metadata = metadata
        if let meta = metadata {
            self.state = .loaded(meta)
        } else {
            self.state = state
        }
        self.isCustom = isCustom
    }

    // MARK: - Convenience Accessors

    public var fileName: String {
        metadata?.fileName ?? url?.lastPathComponent ?? "None"
    }

    public var filePath: String? {
        metadata?.filePath ?? url?.path
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
        (state.isLoaded || metadata != nil) && url != nil
    }
}
