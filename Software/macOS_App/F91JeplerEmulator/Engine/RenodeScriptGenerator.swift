import Foundation

public struct RenodeScriptGenerator {
    public static func generateResc(
        appBinPath: String,
        bootloaderPath: String?,
        uartPort: UInt16,
        ssd1306CsPath: String?
    ) -> String {
        var script = """
        mach create
        machine LoadPlatformDescription @platforms/cpus/nrf52840.repl
        """
        
        if let cs = ssd1306CsPath, FileManager.default.fileExists(atPath: cs) {
            script += "\ninclude @\(cs)"
            script += "\nmachine LoadPlatformDescriptionFromString \"display: Video.F91SSD1306 @ twi0 0x3c { width: 96; height: 40 }\""
        }
        
        script += """
        \nmachine LoadPlatformDescriptionFromString "ficr: Memory.MappedMemory @ sysbus 0x10000000 { size: 0x1000 }"
        sysbus WriteDoubleWord 0x10000010 0x00001000
        sysbus WriteDoubleWord 0x10000014 0x00000100
        emulation CreateServerSocketTerminal \(uartPort) "uart_term" false
        connector Connect sysbus.uart0 uart_term
        machine StartGDBServer 3333
        """
        
        if let bl = bootloaderPath, !bl.isEmpty {
            script += "\nsysbus LoadELF @\(bl)"
        }
        
        script += """
        \nsysbus LoadBinary @\(appBinPath) 0xc000
        start
        """
        
        return script
    }
}
