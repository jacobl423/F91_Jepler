# Dynamic Renode Binary Loading Specification

## 1. `RenodeScriptGenerator.swift`

Enhance `generateResc` to dynamically emit `LoadELF`, `LoadHEX`, or `LoadBinary` based on file extension:

```swift
import Foundation

public struct RenodeScriptGenerator {
    public static func generateResc(
        appBinPath: String,
        bootloaderPath: String?,
        uartPort: UInt16,
        uartLogPath: String,
        ssd1306CsPath: String?
    ) -> String {
        var script = """
        using sysbus
        $app_bin?=@\(appBinPath)
        """
        
        if let bl = bootloaderPath, !bl.isEmpty, FileManager.default.fileExists(atPath: bl) {
            script += "\n$mcuboot_bin?=@\(bl)"
        }
        
        script += """
        \n$name?="nRF52840"
        mach create $name
        machine LoadPlatformDescription @platforms/cpus/nrf52840.repl
        """
        
        if let cs = ssd1306CsPath, FileManager.default.fileExists(atPath: cs) {
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
        
        // Dynamic bootloader loader
        if let bl = bootloaderPath, !bl.isEmpty, FileManager.default.fileExists(atPath: bl) {
            let blExt = (bl as NSString).pathExtension.lowercased()
            if blExt == "hex" {
                script += "\n    sysbus LoadHEX $mcuboot_bin"
            } else if blExt == "bin" {
                script += "\n    sysbus LoadBinary $mcuboot_bin 0x00000"
            } else {
                script += "\n    sysbus LoadELF $mcuboot_bin"
            }
        }
        
        // Dynamic application firmware loader
        let appExt = (appBinPath as NSString).pathExtension.lowercased()
        if appExt == "elf" {
            script += "\n    sysbus LoadELF $app_bin"
        } else if appExt == "hex" {
            script += "\n    sysbus LoadHEX $app_bin"
        } else {
            script += "\n    sysbus LoadBinary $app_bin 0x0c000"
        }
        
        script += """
        \n\"\"\"
        
        runMacro $reset
        """
        
        return script
    }
}
```

## 2. `RenodeProcessManager.swift`

Preserve original file extensions when staging files in temporary execution directory:

```swift
// Staging application firmware:
let appExt = appBinURL.pathExtension.isEmpty ? "bin" : appBinURL.pathExtension
let localAppBin = tempDir.appendingPathComponent("app.\(appExt)")
try? FileManager.default.removeItem(at: localAppBin)
try? FileManager.default.copyItem(at: appBinURL, to: localAppBin)

// Staging bootloader:
var localBootloader: URL? = nil
if let bl = bootloaderURL {
    let blExt = bl.pathExtension.isEmpty ? "elf" : bl.pathExtension
    let dest = tempDir.appendingPathComponent("mcuboot.\(blExt)")
    try? FileManager.default.removeItem(at: dest)
    if (try? FileManager.default.copyItem(at: bl, to: dest)) != nil || FileManager.default.fileExists(atPath: dest.path) {
        localBootloader = dest
    } else if FileManager.default.fileExists(atPath: bl.path) {
        localBootloader = bl
    }
}
```
