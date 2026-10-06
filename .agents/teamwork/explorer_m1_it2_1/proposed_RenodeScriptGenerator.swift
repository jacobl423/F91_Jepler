import Foundation

public struct RenodeScriptGenerator {
    
    public enum BinaryFormat: String, Sendable, CaseIterable {
        case elf
        case hex
        case binary
    }
    
    public typealias Format = BinaryFormat
    
    /// Detects the binary format from file magic bytes if available, falling back to file extension.
    public static func detectFormat(path: String) -> BinaryFormat {
        // Try reading header bytes first for highest fidelity
        if let fileHandle = FileHandle(forReadingAtPath: path) {
            defer { try? fileHandle.close() }
            if let headerData = try? fileHandle.read(upToCount: 16), !headerData.isEmpty {
                // ELF magic: 0x7F, 'E', 'L', 'F' (0x7F 0x45 0x4C 0x46)
                if headerData.count >= 4 &&
                    headerData[0] == 0x7F &&
                    headerData[1] == 0x45 &&
                    headerData[2] == 0x4C &&
                    headerData[3] == 0x46 {
                    return .elf
                }
                
                // Intel HEX: starts with ASCII ':' (0x3A) and followed by hexadecimal characters
                if headerData.count >= 11 && headerData[0] == 0x3A {
                    let hexChars = Set("0123456789ABCDEFabcdef".utf8)
                    if headerData[1..<min(headerData.count, 11)].allSatisfy({ hexChars.contains($0) }) {
                        return .hex
                    }
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
