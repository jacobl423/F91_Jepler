import Foundation

public struct RenodeScriptGenerator {
    
    public enum BinaryFormat: String, Sendable, CaseIterable {
        case elf
        case hex
        case binary
    }
    
    public typealias Format = BinaryFormat
    
    private static func isValidIntelHexRecord(_ line: String) -> Bool {
        guard line.starts(with: ":"), line.count >= 11 else { return false }
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        let payload = line.dropFirst()
        guard payload.unicodeScalars.allSatisfy({ hexChars.contains($0) }) else { return false }
        
        guard let llStart = line.index(line.startIndex, offsetBy: 1, limitedBy: line.endIndex),
              let llEnd = line.index(llStart, offsetBy: 2, limitedBy: line.endIndex),
              let byteCount = UInt8(String(line[llStart..<llEnd]), radix: 16) else { return false }
        
        guard let ttStart = line.index(line.startIndex, offsetBy: 7, limitedBy: line.endIndex),
              let ttEnd = line.index(ttStart, offsetBy: 2, limitedBy: line.endIndex),
              let recordType = UInt8(String(line[ttStart..<ttEnd]), radix: 16), recordType <= 0x05 else { return false }
        
        // Type-specific byte count validations
        if recordType == 0x01 && byteCount != 0 { return false } // EOF
        if (recordType == 0x02 || recordType == 0x04) && byteCount != 2 { return false } // Ext Segment / Linear Addr
        if (recordType == 0x03 || recordType == 0x05) && byteCount != 4 { return false } // Start Segment / Linear Addr
        
        let expectedLength = 11 + 2 * Int(byteCount)
        guard line.count == expectedLength else { return false }
        
        // Verify Intel HEX checksum (sum of all bytes mod 256 == 0)
        var sum: UInt32 = 0
        var currentIndex = line.index(after: line.startIndex)
        while currentIndex < line.endIndex {
            guard let nextIndex = line.index(currentIndex, offsetBy: 2, limitedBy: line.endIndex) else { return false }
            guard let byteVal = UInt8(String(line[currentIndex..<nextIndex]), radix: 16) else { return false }
            sum += UInt32(byteVal)
            currentIndex = nextIndex
        }
        return sum % 256 == 0
    }

    private static func isIntelHexHeader(_ data: Data) -> Bool {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return false
        }
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.starts(with: "#") && !$0.starts(with: ";") }
        guard let firstLine = lines.first else { return false }
        return isValidIntelHexRecord(firstLine)
    }

    /// Detects the binary format from file magic bytes if available, falling back to file extension.
    public static func detectFormat(path: String) -> BinaryFormat {
        // Try reading header bytes first for highest fidelity
        if let fileHandle = FileHandle(forReadingAtPath: path) {
            defer { try? fileHandle.close() }
            if let headerData = try? fileHandle.read(upToCount: 1024), !headerData.isEmpty {
                // ELF magic: 0x7F, 'E', 'L', 'F' (0x7F 0x45 0x4C 0x46)
                if headerData.count >= 4 &&
                    headerData[0] == 0x7F &&
                    headerData[1] == 0x45 &&
                    headerData[2] == 0x4C &&
                    headerData[3] == 0x46 {
                    return .elf
                }
                
                // Intel HEX: hardened structure and checksum check
                if isIntelHexHeader(headerData) {
                    return .hex
                }
            }
        }
        
        // Fallback to file extension
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "elf", "axf":
            return .elf
        case "hex", "ihex":
            return .hex
        default:
            return .binary
        }
    }
    
    /// Emits the appropriate sysbus load command for the specified binary format.
    public static func formatLoadCommand(
        variable: String,
        format: BinaryFormat,
        loadAddress: UInt32
    ) -> String {
        switch format {
        case .elf:
            return "sysbus LoadELF \(variable)"
        case .hex:
            return "sysbus LoadHEX \(variable)"
        case .binary:
            let addr = String(format: "0x%05x", loadAddress)
            return "sysbus LoadBinary \(variable) \(addr)"
        }
    }
    
    public static func generateResc(
        appBinPath: String,
        bootloaderPath: String? = nil,
        uartPort: UInt16 = 1240,
        uartLogPath: String,
        ssd1306CsPath: String? = nil,
        appFormat: BinaryFormat? = nil,
        bootloaderFormat: BinaryFormat? = nil,
        appLoadAddress: UInt32 = 0x0c000,
        bootloaderLoadAddress: UInt32 = 0x00000
    ) -> String {
        var script = """
        using sysbus
        $app_bin?=@\(appBinPath)
        """
        
        if let bl = bootloaderPath, !bl.isEmpty {
            script += "\n$mcuboot_bin?=@\(bl)"
        }
        
        script += """
        \n$name?="nRF52840"
        mach create $name
        machine LoadPlatformDescription @platforms/cpus/nrf52840.repl
        """
        
        if let cs = ssd1306CsPath, !cs.isEmpty, FileManager.default.fileExists(atPath: cs) {
            script += "\ninclude @\(cs)"
            script += "\nmachine LoadPlatformDescriptionFromString \"display: Video.F91SSD1306 @ twi0 0x3c { width: 96; height: 39 }\""
        }
        
        script += """
        \nmachine LoadPlatformDescriptionFromString "ficr: Memory.MappedMemory @ sysbus 0x10000000 { size: 0x1000 }"
        sysbus.uart0 CreateFileBackend @\(uartLogPath) true
        
        macro reset
        \"\"\"
            sysbus WriteDoubleWord 0x10000010 0x00001000
            sysbus WriteDoubleWord 0x10000014 0x00000100
        """
        
        // Dynamically emit bootloader load command
        if let bl = bootloaderPath, !bl.isEmpty {
            let blFmt = bootloaderFormat ?? detectFormat(path: bl)
            let blCmd = formatLoadCommand(
                variable: "$mcuboot_bin",
                format: blFmt,
                loadAddress: bootloaderLoadAddress
            )
            script += "\n    \(blCmd)"
        }
        
        // Dynamically emit application load command
        let appFmt = appFormat ?? detectFormat(path: appBinPath)
        let appCmd = formatLoadCommand(
            variable: "$app_bin",
            format: appFmt,
            loadAddress: appLoadAddress
        )
        script += "\n    \(appCmd)"
        
        script += """
        \n\"\"\"
        
        runMacro $reset
        """
        
        return script
    }
}
