import Foundation
import CryptoKit

// MARK: - AssetInspectionError

public enum AssetInspectionError: LocalizedError, Equatable {
    case fileNotFound(String)
    case unreadableFile(String)
    case emptyFile(String)
    case corruptedHeader(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path): return "File not found at: \(path)"
        case .unreadableFile(let reason): return "Unable to read file: \(reason)"
        case .emptyFile(let path): return "File is empty: \(path)"
        case .corruptedHeader(let reason): return "Corrupted header: \(reason)"
        }
    }
}

// MARK: - AssetInspector

/// Thread-safe, non-blocking asynchronous metadata extractor and header inspector for firmware, PCB, and script assets.
public enum AssetInspector {

    private static let headerReadLimit = 8192 // 8 KB is ample for header magic without loading huge files into memory

    // MARK: - Public Async API

    /// Asynchronously inspects an asset file on a background cooperative thread without blocking `@MainActor`.
    public static func inspect(
        url: URL,
        kind: SessionAssetKind,
        isCustom: Bool
    ) async throws -> AssetMetadata {
        try await Task.detached(priority: .userInitiated) {
            try inspectSynchronous(url: url, kind: kind, isCustom: isCustom)
        }.value
    }

    /// Safe asynchronous inspection that returns optional metadata instead of throwing.
    public static func inspectSafe(
        url: URL,
        kind: SessionAssetKind,
        isCustom: Bool
    ) async -> AssetMetadata? {
        try? await inspect(url: url, kind: kind, isCustom: isCustom)
    }

    // MARK: - Synchronous Inspection (Worker Thread)

    /// Performs synchronous inspection. Can be called directly in deterministic unit tests.
    public static func inspectSynchronous(
        url: URL,
        kind: SessionAssetKind,
        isCustom: Bool
    ) throws -> AssetMetadata {
        let filePath = url.path
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw AssetInspectionError.fileNotFound(filePath)
        }

        // 1. File Attributes (Size & Modification Date)
        let attributes = try? FileManager.default.attributesOfItem(atPath: filePath)
        let fileSizeBytes = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let modificationDate = attributes?[.modificationDate] as? Date

        let sizeFormatted = ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
        let dateFormatted: String = {
            guard let date = modificationDate else { return "Unknown" }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }()

        if fileSizeBytes == 0 {
            return AssetMetadata(
                fileName: url.lastPathComponent,
                filePath: filePath,
                fileSizeBytes: 0,
                fileSizeFormatted: "0 B",
                modificationDate: modificationDate,
                modificationDateFormatted: dateFormatted,
                formatBadge: "Empty",
                secondaryDetail: "0 bytes",
                isCustom: isCustom,
                sha256: nil,
                isSHA256Complete: false,
                detectedFormat: .unknown
            )
        }

        // 2. Read Header Bytes (First 8KB)
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw AssetInspectionError.unreadableFile("Failed to open file handle at \(filePath)")
        }
        defer { try? fileHandle.close() }

        guard let headerData = try? fileHandle.read(upToCount: headerReadLimit), !headerData.isEmpty else {
            throw AssetInspectionError.emptyFile(filePath)
        }

        // 3. Compute the full-file SHA-256; trust decisions must not rely on a prefix/sample.
        let sha256 = computeSHA256(fileHandle: fileHandle, initialData: headerData, totalSize: fileSizeBytes)
        guard let sha256 else { throw AssetInspectionError.unreadableFile("Could not hash all bytes of \(filePath)") }

        // 4. Inspect Header Magic & Identify Format
        let detection = parseHeader(data: headerData, url: url, kind: kind, fileSizeBytes: fileSizeBytes)

        return AssetMetadata(
            fileName: url.lastPathComponent,
            filePath: filePath,
            fileSizeBytes: fileSizeBytes,
            fileSizeFormatted: sizeFormatted,
            modificationDate: modificationDate,
            modificationDateFormatted: dateFormatted,
            formatBadge: detection.badge,
            secondaryDetail: detection.detail,
            isCustom: isCustom,
            sha256: sha256,
            isSHA256Complete: true,
            detectedFormat: detection.format
        )
    }

    // MARK: - Header Parsers

    private struct HeaderParseResult {
        let badge: String
        let detail: String
        let format: DetectedAssetFormat
    }

    private static func parseHeader(
        data: Data,
        url: URL,
        kind: SessionAssetKind,
        fileSizeBytes: Int64
    ) -> HeaderParseResult {
        // Priority 1: MCUboot Image Magic (0x96F3B83D at offset 0)
        if let mcuboot = parseMCUbootHeader(data: data) {
            return mcuboot
        }

        // Priority 2: ELF32 ARM Cortex-M Header (\x7FELF at offset 0)
        if let elf = parseELFHeader(data: data) {
            return elf
        }

        // Priority 3: KiCad PCB S-Expression (starts with "(kicad_pcb")
        if let kicad = parseKiCadPCBHeader(data: data) {
            return kicad
        }

        // Priority 4: Renode Emulation Script (.resc)
        if let resc = parseRenodeScriptHeader(data: data, url: url) {
            return resc
        }

        // Priority 5: Intel HEX (starts with ":", strict colon hex records)
        if let ihex = parseIntelHexHeader(data: data) {
            return ihex
        }

        // Fallback: Raw binary or extension-based detection
        let ext = url.pathExtension.lowercased()
        let sizeFormatted = ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
        if ext == "bin" {
            return HeaderParseResult(
                badge: "Raw Binary",
                detail: "Base 0x0c000 · \(sizeFormatted)",
                format: .rawBinary
            )
        } else if ext == "hex" {
            return HeaderParseResult(
                badge: "Intel HEX",
                detail: "\(sizeFormatted)",
                format: .intelHex
            )
        } else if ext == "elf" {
            return HeaderParseResult(
                badge: "ELF Binary",
                detail: "\(sizeFormatted)",
                format: .elfArmCortexM
            )
        } else if ext == "kicad_pcb" {
            return HeaderParseResult(
                badge: "KiCad PCB",
                detail: "\(sizeFormatted)",
                format: .kicadSExpr
            )
        } else if ext == "resc" {
            return HeaderParseResult(
                badge: "Renode Script",
                detail: "\(sizeFormatted)",
                format: .renodeResc
            )
        }

        return HeaderParseResult(
            badge: ext.uppercased().isEmpty ? "Unknown" : ext.uppercased(),
            detail: sizeFormatted,
            format: .unknown
        )
    }

    // MARK: - 1. MCUboot Image Header (0x96F3B83D)

    private static func parseMCUbootHeader(data: Data) -> HeaderParseResult? {
        guard data.count >= 28 else { return nil }

        return data.withUnsafeBytes { rawBuffer -> HeaderParseResult? in
            guard rawBuffer.count >= 28 else { return nil }

            // Read 32-bit LE Magic from offset 0 using unaligned load
            let rawMagic = rawBuffer.loadUnaligned(fromByteOffset: 0, as: UInt32.self)
            let magic = UInt32(littleEndian: rawMagic)
            guard magic == 0x96F3B83D else { return nil }

            // Extract MCUboot struct fields with unaligned little-endian loads
            let rawImgSize = rawBuffer.loadUnaligned(fromByteOffset: 12, as: UInt32.self)
            let imgSize = UInt32(littleEndian: rawImgSize)

            let verMajor = rawBuffer[20]
            let verMinor = rawBuffer[21]

            let rawRevision = rawBuffer.loadUnaligned(fromByteOffset: 22, as: UInt16.self)
            let verRevision = UInt16(littleEndian: rawRevision)

            let rawBuildNum = rawBuffer.loadUnaligned(fromByteOffset: 24, as: UInt32.self)
            let verBuildNum = UInt32(littleEndian: rawBuildNum)

            let versionStr = "v\(verMajor).\(verMinor).\(verRevision)+\(verBuildNum)"
            let imgSizeFormatted = ByteCountFormatter.string(fromByteCount: Int64(imgSize), countStyle: .file)
            let detail = "\(versionStr) · \(imgSizeFormatted) payload"

            return HeaderParseResult(
                badge: "MCUboot Signed",
                detail: detail,
                format: .mcubootBinary
            )
        }
    }

    // MARK: - 2. ELF32 ARM Cortex-M Header (\x7FELF)

    private static func parseELFHeader(data: Data) -> HeaderParseResult? {
        guard data.count >= 52 else { return nil }

        return data.withUnsafeBytes { rawBuffer -> HeaderParseResult? in
            guard rawBuffer.count >= 52 else { return nil }

            // Magic \x7fELF at offset 0
            guard rawBuffer[0] == 0x7F && rawBuffer[1] == 0x45 && rawBuffer[2] == 0x4C && rawBuffer[3] == 0x46 else {
                return nil
            }

            let elfClass = rawBuffer[4]  // 1 = 32-bit, 2 = 64-bit
            let elfEndian = rawBuffer[5] // 1 = LSB (little endian), 2 = MSB (big endian)
            guard elfClass == 1, elfEndian == 1 else {
                return HeaderParseResult(
                    badge: elfClass == 2 ? "ELF64" : "ELF32",
                    detail: "Non-ARM Cortex-M ELF",
                    format: .elfArmCortexM
                )
            }

            let rawMachine = rawBuffer.loadUnaligned(fromByteOffset: 18, as: UInt16.self)
            let eMachine = UInt16(littleEndian: rawMachine)

            let rawEntry = rawBuffer.loadUnaligned(fromByteOffset: 24, as: UInt32.self)
            let eEntry = UInt32(littleEndian: rawEntry)

            let isARM = (eMachine == 0x0028) // EM_ARM = 40 (0x28)
            let badge = isARM ? "ELF32 ARM" : "ELF32"
            let entryHex = String(format: "%04X", eEntry)
            let archDesc = isARM ? "Cortex-M" : "Arch 0x\(String(format: "%02X", eMachine))"
            let detail = "\(archDesc) · Entry 0x\(entryHex)"

            return HeaderParseResult(
                badge: badge,
                detail: detail,
                format: .elfArmCortexM
            )
        }
    }

    // MARK: - 3. KiCad PCB S-Expression ((kicad_pcb ...))

    private static func parseKiCadPCBHeader(data: Data) -> HeaderParseResult? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        guard text.contains("(kicad_pcb") else { return nil }

        var version: String? = nil
        var generator: String? = nil
        var thickness: String? = nil

        // Extract version e.g. (version 20260206)
        if let vRange = text.range(of: #"\(\s*version\s+(\d+)\)"#, options: .regularExpression) {
            let match = String(text[vRange])
            version = match.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.first
        }

        // Extract generator e.g. (generator "pcbnew")
        if let gRange = text.range(of: #"\(\s*generator\s+"([^"]+)"\)"#, options: .regularExpression) {
            let match = String(text[gRange])
            generator = match.components(separatedBy: "\"").dropFirst().first
        }

        // Extract thickness e.g. (thickness 0.8)
        if let tRange = text.range(of: #"\(\s*thickness\s+([0-9.]+)\)"#, options: .regularExpression) {
            let match = String(text[tRange])
            let parts = match.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).filter { !$0.isEmpty }
            if let thickStr = parts.first, Double(thickStr) != nil {
                thickness = thickStr
            }
        }

        var details: [String] = []
        if let ver = version { details.append("v\(ver)") }
        if let gen = generator { details.append(gen) }
        if let thk = thickness { details.append("\(thk)mm") }
        let detail = details.isEmpty ? "KiCad Layout S-expr" : details.joined(separator: " · ")

        return HeaderParseResult(
            badge: "KiCad PCB",
            detail: detail,
            format: .kicadSExpr
        )
    }

    // MARK: - 4. Intel HEX Records (:LLAAAATT[DD...]CC)

    private static func parseIntelHexHeader(data: Data) -> HeaderParseResult? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.starts(with: "#") && !$0.starts(with: ";") }

        guard let firstLine = lines.first, firstLine.starts(with: ":"), firstLine.count >= 11 else { return nil }

        // An Intel HEX line consists of ':' followed EXCLUSIVELY by hex digits
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        let payload = firstLine.dropFirst()
        guard payload.unicodeScalars.allSatisfy({ hexChars.contains($0) }) else { return nil }

        var recordCount = 0
        var baseAddress: UInt32 = 0
        var entryPoint: UInt32? = nil
        var hasValidHex = false

        for line in lines.prefix(128) {
            guard line.starts(with: ":"), line.count >= 11 else { continue }
            let linePayload = line.dropFirst()
            guard linePayload.unicodeScalars.allSatisfy({ hexChars.contains($0) }) else { continue }

            guard let typeIndex = line.index(line.startIndex, offsetBy: 7, limitedBy: line.endIndex),
                  let typeEnd = line.index(typeIndex, offsetBy: 2, limitedBy: line.endIndex) else { continue }
            let typeStr = String(line[typeIndex..<typeEnd])
            guard let recordType = UInt8(typeStr, radix: 16), recordType <= 0x05 else { continue }

            recordCount += 1
            hasValidHex = true

            if recordType == 0x04 { // Extended Linear Address
                guard line.count >= 13,
                      let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
                      let dataEnd = line.index(dataStart, offsetBy: 4, limitedBy: line.endIndex),
                      let highWord = UInt32(String(line[dataStart..<dataEnd]), radix: 16) else { continue }
                baseAddress = highWord << 16
            } else if recordType == 0x05 { // Start Linear Address (Entry Point)
                guard line.count >= 17,
                      let dataStart = line.index(line.startIndex, offsetBy: 9, limitedBy: line.endIndex),
                      let dataEnd = line.index(dataStart, offsetBy: 8, limitedBy: line.endIndex),
                      let entry = UInt32(String(line[dataStart..<dataEnd]), radix: 16) else { continue }
                entryPoint = entry
            }
        }

        guard hasValidHex else { return nil }

        var detail = "Base 0x\(String(format: "%04X", baseAddress))"
        if let ep = entryPoint {
            detail += " · Entry 0x\(String(format: "%04X", ep))"
        } else {
            detail += " · \(lines.count) recs"
        }

        return HeaderParseResult(
            badge: "Intel HEX",
            detail: detail,
            format: .intelHex
        )
    }

    // MARK: - 5. Renode Emulation Script (.resc)

    private static func parseRenodeScriptHeader(data: Data, url: URL) -> HeaderParseResult? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let isRescExtension = url.pathExtension.lowercased() == "resc"
        let hasKeywords = text.contains("using sysbus") || text.contains("mach create") || text.contains("machine LoadPlatformDescription") || text.contains(":name:")

        guard isRescExtension || hasKeywords else { return nil }

        var name: String? = nil
        var platform: String? = nil
        let lines = text.components(separatedBy: .newlines)

        for line in lines.prefix(40) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.starts(with: ":name:") {
                name = trimmed.replacingOccurrences(of: ":name:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.starts(with: "mach create") {
                platform = trimmed.replacingOccurrences(of: "mach create", with: "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "$name", with: "nRF52840")
            }
        }

        let lineCount = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        var detailParts: [String] = []
        if let plat = platform, !plat.isEmpty { detailParts.append(plat) }
        else if let title = name, !title.isEmpty { detailParts.append(title) }
        detailParts.append("\(lineCount) lines")

        return HeaderParseResult(
            badge: "Renode Script",
            detail: detailParts.joined(separator: " · "),
            format: .renodeResc
        )
    }

    // MARK: - SHA256 Prefix Computation

    private static func computeSHA256(fileHandle: FileHandle, initialData: Data, totalSize: Int64) -> String? {
        var hasher = SHA256()
        hasher.update(data: initialData)
        var bytesRead = Int64(initialData.count)

        while bytesRead < totalSize {
            let chunkSize = min(1024 * 1024, Int(totalSize - bytesRead))
            guard let chunk = try? fileHandle.read(upToCount: chunkSize), !chunk.isEmpty else { return nil }
            hasher.update(data: chunk)
            bytesRead += Int64(chunk.count)
        }

        guard bytesRead == totalSize else { return nil }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
