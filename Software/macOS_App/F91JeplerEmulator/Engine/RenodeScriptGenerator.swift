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
        
        if let bl = bootloaderPath, !bl.isEmpty, FileManager.default.fileExists(atPath: bl) {
            script += "\n    sysbus LoadELF $mcuboot_bin"
        }
        
        script += """
        \n    sysbus LoadBinary $app_bin 0x0c000
        \"\"\"
        
        runMacro $reset
        """
        
        return script
    }
}
