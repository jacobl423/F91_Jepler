import Foundation

public struct CPURegister: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let hexValue: String
    public let uintValue: UInt32
}

public struct MemoryWord: Identifiable, Equatable {
    public var id: UInt32 { address }
    public let address: UInt32
    public let hexString: String
    public let asciiString: String
}

@MainActor
public final class CPUInspectorModel: ObservableObject {
    @Published public var registers: [CPURegister] = []
    @Published public var pcAddress: UInt32 = 0x0C000
    @Published public var spAddress: UInt32 = 0x20008000
    @Published public var lrAddress: UInt32 = 0x00000000
    @Published public var isPaused: Bool = false
    @Published public var memoryWords: [MemoryWord] = []
    @Published public var targetMemoryAddressHex: String = "20000000"
    
    public init() {
        populateDefaultRegisters()
    }
    
    public func populateDefaultRegisters() {
        self.registers = [
            CPURegister(name: "R0", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R1", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R2", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R3", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R4", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R5", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R6", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R7", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R8", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R9", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R10", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R11", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "R12", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "SP (R13)", hexValue: "0x20008000", uintValue: 0x20008000),
            CPURegister(name: "LR (R14)", hexValue: "0x00000000", uintValue: 0),
            CPURegister(name: "PC (R15)", hexValue: "0x0000C000", uintValue: 0x0000C000),
            CPURegister(name: "xPSR", hexValue: "0x01000000", uintValue: 0x01000000)
        ]
    }
    
    public func updateRegister(name: String, value: UInt32) {
        let hex = String(format: "0x%08X", value)
        if let idx = registers.firstIndex(where: { $0.name.contains(name) }) {
            registers[idx] = CPURegister(name: registers[idx].name, hexValue: hex, uintValue: value)
        }
        if name == "PC" { pcAddress = value }
        if name == "SP" { spAddress = value }
        if name == "LR" { lrAddress = value }
    }
}
